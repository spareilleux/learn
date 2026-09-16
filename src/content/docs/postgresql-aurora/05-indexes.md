---
title: "5. Indexes and plans"
description: Reading EXPLAIN (ANALYZE, BUFFERS) in PostgreSQL 18 and choosing an index on a 440,800-row table — B-tree, multicolumn, partial, expression and covering indexes, index-only scans and the visibility map, GIN on arrays, BRIN and physical order, and extended statistics for correlated columns; compared with SQL Server's execution plans, filtered indexes and included columns.
sidebar:
  order: 5
---

The lesson's script is [`sql/05-indexes.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql), the exercises are in [`sql/05-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql), and `check.sh` compares their output with [`expected/05-indexes.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/05-indexes.txt) and [`expected/05-exercises.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/05-exercises.txt).

The CI snapshot is too small for indexes to matter: 2,204 steps fit in a few dozen pages, and reading them all is the fastest plan. The lesson builds a bigger table, `ci.step_history`, from [`sql/history.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/history.sql): every step of the snapshot, replayed on each of the 200 days up to 2026-09-14, in time order.

| SQL Server | PostgreSQL |
|---|---|
| actual execution plan, `SET STATISTICS IO ON` | `EXPLAIN (ANALYZE, BUFFERS)` |
| clustered index: the table itself, ordered by its key | a heap with no order; `CLUSTER` sorts it once |
| nonclustered index with `INCLUDE` | B-tree with `INCLUDE` |
| filtered index, `WHERE …` | partial index, `WHERE …` |
| index on a persisted computed column | index on an expression |
| full-text and XML indexes, JSON indexes (preview in SQL Server 2025) | GIN, GiST, SP-GiST |
| columnstore segment elimination | BRIN |
| multi-column statistics, `CREATE STATISTICS` | `CREATE STATISTICS (dependencies, ndistinct, mcv)` |

## Stable plans for a lesson

A plan has timings, costs and buffer counts that change from one run to the next, and `check.sh` compares outputs line by line. [`sql/explain.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/explain.sql) makes them repeatable ([lines 3-30](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/explain.sql#L3-L30)):

```sql
-- Plans and row counts that are the same at every run:
-- no parallel workers, whose share of the rows varies, and statistics computed from every row, not a sample
SET max_parallel_workers_per_gather = 0;
SET default_statistics_target = 1500;

-- EXPLAIN ANALYZE without what changes between runs: costs, timings, the planner's own buffer usage, and the split of
-- pages between shared buffers (hit) and disk (read), which depends on what earlier queries left in memory
CREATE FUNCTION pg_temp.plan(query text) RETURNS TABLE ("QUERY PLAN" text) LANGUAGE plpgsql AS $$
DECLARE
    line text;
    planning boolean := false;
    pages bigint;
BEGIN
    FOR line IN EXECUTE 'EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF) ' || query LOOP
        IF line = 'Planning:' THEN
            planning := true;
        ELSIF NOT (planning AND line LIKE ' %') THEN
            planning := false;
            IF line ~ 'Buffers: shared ' THEN
                pages := coalesce(substring(line FROM 'hit=(\d+)')::bigint, 0) + coalesce(substring(line FROM 'read=(\d+)')::bigint, 0);
                line := substring(line FROM '^\s*') || 'Buffers: shared hit+read=' || pages;
            END IF;
            "QUERY PLAN" := line;
            RETURN NEXT;
        END IF;
    END LOOP;
END
$$;
```

- [`max_parallel_workers_per_gather`](https://www.postgresql.org/docs/18/runtime-config-resource.html#GUC-MAX-PARALLEL-WORKERS-PER-GATHER) `= 0` turns off parallel query: with workers, each process's share of the rows changed at every run.
- [`default_statistics_target`](https://www.postgresql.org/docs/18/runtime-config-query.html#GUC-DEFAULT-STATISTICS-TARGET) `= 1500` makes `ANALYZE` sample 300 rows per unit of target, 450,000 rows, more than the table has: the statistics come from every row, and the estimates are the same at every run. With the default of 100, `ANALYZE` reads a random sample of 30,000 rows.
- `pg_temp.plan` runs [`EXPLAIN`](https://www.postgresql.org/docs/18/sql-explain.html) `(ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF)` and adds the pages found in memory (`hit`) and read from disk (`read`) into one number: how they split depends on what earlier queries left in the cache, the total doesn't.

`EXPLAIN ANALYZE` runs the query. Since PostgreSQL 18, it also reports `BUFFERS` without being asked, shows row counts with two decimals, which matter when a node runs many loops, and counts `Index Searches` for each index scan ([PostgreSQL 18 release notes](https://www.postgresql.org/docs/18/release-18.html)). In your own `psql`, `EXPLAIN (ANALYZE, BUFFERS)` shows the same plans with their costs and timings.

## The table

[Lines 8-11](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L8-L11):

```sql
-- The table: 2,204 steps replayed on 200 days
SELECT count(*) AS rows, pg_size_pretty(pg_relation_size('ci.step_history')) AS size,
       min(started_at)::date AS first_day, max(started_at)::date AS last_day
FROM ci.step_history;
```

```text
  rows  | size  | first_day  |  last_day
--------+-------+------------+------------
 440800 | 76 MB | 2026-02-26 | 2026-09-14
(1 row)
```

## A sequential scan

The day's failed steps, with no index ([lines 13-17](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L13-L17)):

```sql
-- One query, no index: every page of the table is read
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
```

```text
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=9667
   ->  Seq Scan on step_history (actual rows=15.00 loops=1)
         Filter: ((started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone) AND ((conclusion)::text = 'failure'::text))
         Rows Removed by Filter: 440785
         Buffers: shared hit+read=9667
(6 rows)
```

Read a plan from the most indented node up: each node feeds the one above it. `Seq Scan` read all 9,667 pages of the table, 8 kB each, kept 15 rows and discarded 440,785. `Buffers` is the number to watch in this lesson: on a real server, pages not in memory are disk reads.

## B-tree

A [B-tree](https://www.postgresql.org/docs/18/indexes-types.html#INDEXES-TYPES-BTREE) on `started_at`, and the same query ([lines 19-24](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L19-L24)):

```sql
-- A B-tree on started_at
CREATE INDEX step_history_started_at ON ci.step_history (started_at);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
```

```text
CREATE INDEX
                                         QUERY PLAN
--------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=47
   ->  Index Scan using step_history_started_at on step_history (actual rows=15.00 loops=1)
         Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Filter: ((conclusion)::text = 'failure'::text)
         Rows Removed by Filter: 1518
         Index Searches: 1
         Buffers: shared hit+read=47
(8 rows)
```

47 pages instead of 9,667. `Index Cond` is what the index finds: the 1,533 steps of September 14. `Filter` is checked on each row the index returned, in the table: 1,518 of them weren't failures.

The same index, from July 1st: a third of the table ([lines 26-30](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L26-L30)):

```sql
-- The same index, a range that covers a third of the table
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-07-01' AND conclusion = 'failure'
$$);
```

```text
                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=4396
   ->  Index Scan using step_history_started_at on step_history (actual rows=1665.00 loops=1)
         Index Cond: (started_at >= '2026-07-01 00:00:00+00'::timestamp with time zone)
         Filter: ((conclusion)::text = 'failure'::text)
         Rows Removed by Filter: 165168
         Index Searches: 1
         Buffers: shared hit+read=4396
(8 rows)
```

The planner still chose the index, and read 4,396 pages, less than half the table. It knows that rows with nearby `started_at` values are in nearby pages, because the table was filled in time order: the index scan reads the table's pages almost in sequence. On a table whose rows are in no particular order, a third of the rows would be spread over most pages, and a sequential scan would win. The [BRIN section](#brin) shows the statistic the planner uses.

SQL Server stores a table with a clustered index in the index's order. A PostgreSQL table is a heap: rows go where there is room, and [`CLUSTER`](https://www.postgresql.org/docs/18/sql-cluster.html) sorts it once, without keeping it sorted afterwards.

## Multicolumn indexes

The five latest failures, all days together ([lines 32-39](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L32-L39)):

```sql
-- The latest failures, all days: equality column first, then the sort column
CREATE INDEX step_history_conclusion_started_at ON ci.step_history (conclusion, started_at);
SELECT * FROM pg_temp.plan($$
    SELECT started_at, workflow_name, step_name FROM ci.step_history
    WHERE conclusion = 'failure'
    ORDER BY started_at DESC
    LIMIT 5
$$);
```

```text
CREATE INDEX
                                                  QUERY PLAN
---------------------------------------------------------------------------------------------------------------
 Limit (actual rows=5.00 loops=1)
   Buffers: shared hit+read=6
   ->  Index Scan Backward using step_history_conclusion_started_at on step_history (actual rows=5.00 loops=1)
         Index Cond: ((conclusion)::text = 'failure'::text)
         Index Searches: 1
         Buffers: shared hit+read=6
(6 rows)
```

The index on `(conclusion, started_at)` keeps the failures together, sorted by time: `Index Scan Backward` reads them from the latest, and `Limit` stops after five. Six pages, and no `Sort` node. The rule is the same as in SQL Server: columns compared with `=` first, then the column of the range or the sort ([multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html)).

## Partial indexes

A [partial index](https://www.postgresql.org/docs/18/indexes-partial.html) holds only the rows its `WHERE` accepts, like a filtered index in SQL Server ([lines 41-50](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L41-L50)):

```sql
-- A partial index holds only the rows its WHERE accepts
CREATE INDEX step_history_not_success ON ci.step_history (started_at) WHERE conclusion <> 'success';
SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index WHERE indrelid = 'ci.step_history'::regclass
ORDER BY pg_relation_size(indexrelid) DESC, 1;

SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE conclusion <> 'success' AND started_at >= '2026-09-01'
$$);
```

```text
CREATE INDEX
                 index                 |  size
---------------------------------------+---------
 ci.step_history_conclusion_started_at | 9792 kB
 ci.step_history_pkey                  | 9688 kB
 ci.step_history_started_at            | 7504 kB
 ci.step_history_not_success           | 368 kB
(4 rows)

                                             QUERY PLAN
----------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=6
   ->  Index Only Scan using step_history_not_success on step_history (actual rows=1527.00 loops=1)
         Index Cond: (started_at >= '2026-09-01 00:00:00+00'::timestamp with time zone)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=6
(7 rows)
```

- 368 kB, against 7.5 MB for the index on every row: 95% of the steps succeeded, and the index only has the 5% that were skipped, failed or cancelled.
- The query repeats the index's predicate, `conclusion <> 'success'`, so the planner knows every row it wants is in the index. A query with no condition on `conclusion` can't use it.
- `Index Only Scan`: the count needs no column from the table, and `Heap Fetches: 0` says it didn't visit the table at all. The [covering index section](#covering-indexes-and-index-only-scans) explains when it must.

## Indexes on expressions

An index on the day of `started_at` ([lines 52-58](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L52-L58)):

```sql
-- An index on an expression: the expression must be immutable
CREATE INDEX step_history_day ON ci.step_history ((started_at::date));
CREATE INDEX step_history_day ON ci.step_history (((started_at AT TIME ZONE 'UTC')::date));
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE (started_at AT TIME ZONE 'UTC')::date = '2026-09-14'
$$);
```

```text
ERROR:  functions in index expression must be marked IMMUTABLE
CREATE INDEX
                                           QUERY PLAN
------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=41
   ->  Bitmap Heap Scan on step_history (actual rows=1533.00 loops=1)
         Recheck Cond: (((started_at AT TIME ZONE 'UTC'::text))::date = '2026-09-14'::date)
         Heap Blocks: exact=37
         Buffers: shared hit+read=41
         ->  Bitmap Index Scan on step_history_day (actual rows=1533.00 loops=1)
               Index Cond: (((started_at AT TIME ZONE 'UTC'::text))::date = '2026-09-14'::date)
               Index Searches: 1
               Buffers: shared hit+read=4
(10 rows)
```

The first `CREATE INDEX` fails: the date of a `timestamptz` depends on the session's `TimeZone`, so the cast is `STABLE`, not `IMMUTABLE`, and an index can only store what never changes ([function volatility](https://www.postgresql.org/docs/18/xfunc-volatility.html)). `AT TIME ZONE 'UTC'` fixes the zone, and the second index works. SQL Server has the same rule for an index on a computed column, which must be deterministic.

The query must repeat the expression as the index writes it. The planner chose a `Bitmap Heap Scan`: the index gives the 1,533 rows' positions, sorted by page into a bitmap, and the table is read page by page, 37 pages.

## Covering indexes and index-only scans

`INCLUDE` adds columns to the leaf entries of a B-tree, as in SQL Server ([lines 60-72](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L60-L72)):

```sql
-- A covering index and index-only scans
CREATE INDEX step_history_step_name ON ci.step_history (step_name) INCLUDE (duration);
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
UPDATE ci.step_history SET duration = duration WHERE step_name = 'Compile-fail doctests' AND started_at >= '2026-09-01';
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
VACUUM ci.step_history;
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
```

```text
CREATE INDEX
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=70
   ->  Index Only Scan using step_history_step_name on step_history (actual rows=9200.00 loops=1)
         Index Cond: (step_name = 'Compile-fail doctests'::text)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=70
(7 rows)

UPDATE 622
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=426
   ->  Index Only Scan using step_history_step_name on step_history (actual rows=9200.00 loops=1)
         Index Cond: (step_name = 'Compile-fail doctests'::text)
         Heap Fetches: 1244
         Index Searches: 1
         Buffers: shared hit+read=426
(7 rows)

VACUUM
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=71
   ->  Index Only Scan using step_history_step_name on step_history (actual rows=9200.00 loops=1)
         Index Cond: (step_name = 'Compile-fail doctests'::text)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=71
(7 rows)
```

The index has every column the sum needs, but a PostgreSQL index doesn't know whether the transaction can see a row: that information is in the row's version, in the table ([lesson 6](../06-transactions/)). An [index-only scan](https://www.postgresql.org/docs/18/indexes-index-only-scans.html) skips the table for pages the [visibility map](https://www.postgresql.org/docs/18/storage-vm.html) marks as all-visible, which `VACUUM` sets.

1. After `VACUUM ANALYZE`, every page is all-visible: 70 pages of index, `Heap Fetches: 0`.
2. The `UPDATE` changes nothing, but writes a new version of 622 rows. Their pages are no longer all-visible, and the index now has 1,244 entries that point to them, one for the old version and one for the new: 1,244 fetches from the table, 426 pages.
3. `VACUUM` removes the old versions and their index entries, and marks the pages all-visible again: back to 71 pages.

On a table with constant updates, and an autovacuum that lags, an "index-only" scan reads the table anyway. A covering nonclustered index in SQL Server never goes back to the table for this; in PostgreSQL, the index doesn't hold what a transaction needs to know to see a row.

## GIN

[GIN](https://www.postgresql.org/docs/18/gin.html) indexes the elements of a value, here the labels of the runner, an array ([lines 74-81](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L74-L81)):

```sql
-- GIN on an array: which elements does a row contain?
CREATE INDEX step_history_labels ON ci.step_history USING gin (labels);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE labels @> '{macos-latest}' AND step_name = 'Toolchain'
$$);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE 'macos-latest' = ANY (labels) AND step_name = 'Toolchain'
$$);
```

```text
CREATE INDEX
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=3631
   ->  Bitmap Heap Scan on step_history (actual rows=4200.00 loops=1)
         Recheck Cond: ((step_name = 'Toolchain'::text) AND (labels @> '{macos-latest}'::text[]))
         Heap Blocks: exact=3532
         Buffers: shared hit+read=3631
         ->  BitmapAnd (actual rows=0.00 loops=1)
               Buffers: shared hit+read=99
               ->  Bitmap Index Scan on step_history_step_name (actual rows=13400.00 loops=1)
                     Index Cond: (step_name = 'Toolchain'::text)
                     Index Searches: 1
                     Buffers: shared hit+read=84
               ->  Bitmap Index Scan on step_history_labels (actual rows=80400.00 loops=1)
                     Index Cond: (labels @> '{macos-latest}'::text[])
                     Index Searches: 1
                     Buffers: shared hit+read=15
(16 rows)

                                       QUERY PLAN
----------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=5548
   ->  Bitmap Heap Scan on step_history (actual rows=4200.00 loops=1)
         Recheck Cond: (step_name = 'Toolchain'::text)
         Filter: ('macos-latest'::text = ANY (labels))
         Rows Removed by Filter: 9200
         Heap Blocks: exact=5464
         Buffers: shared hit+read=5548
         ->  Bitmap Index Scan on step_history_step_name (actual rows=13400.00 loops=1)
               Index Cond: (step_name = 'Toolchain'::text)
               Index Searches: 1
               Buffers: shared hit+read=84
(12 rows)
```

- `labels @> '{macos-latest}'`, "contains", uses the GIN index. The planner combined two indexes in a `BitmapAnd`: 13,400 `Toolchain` steps and 80,400 steps on macOS, 4,200 in both.
- `'macos-latest' = ANY (labels)` means the same, but no index operator matches it: the plan reads all the `Toolchain` steps and filters out 9,200.

An index serves the operators of its [operator class](https://www.postgresql.org/docs/18/indexes-opclass.html), not the meaning of a condition. Lesson 7 uses GIN for `jsonb` and text search. [GiST](https://www.postgresql.org/docs/18/gist.html), the other general-purpose index type, stores ranges, geometric shapes and other values that overlap or contain each other: it's the index behind the exclusion constraint on `ci.steps` in [lesson 2](../02-types/).

## BRIN

A [BRIN](https://www.postgresql.org/docs/18/brin.html) index stores, for each range of 128 pages, the smallest and largest value of the column ([lines 83-93](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L83-L93)):

```sql
-- BRIN: one summary per range of pages, useful when the column follows the physical order
DROP INDEX ci.step_history_started_at, ci.step_history_conclusion_started_at, ci.step_history_not_success;
CREATE INDEX step_history_started_at_brin ON ci.step_history USING brin (started_at);
SELECT pg_size_pretty(pg_relation_size('ci.step_history_started_at_brin')) AS brin_size;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
SELECT attname, round(correlation::numeric, 2) AS correlation
FROM pg_stats WHERE schemaname = 'ci' AND tablename = 'step_history' AND attname IN ('id', 'started_at', 'step_name')
ORDER BY attname;
```

```text
DROP INDEX
CREATE INDEX
 brin_size
-----------
 24 kB
(1 row)

                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=87
   ->  Bitmap Heap Scan on step_history (actual rows=15.00 loops=1)
         Recheck Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Rows Removed by Index Recheck: 2094
         Filter: ((conclusion)::text = 'failure'::text)
         Rows Removed by Filter: 1518
         Heap Blocks: lossy=82
         Buffers: shared hit+read=87
         ->  Bitmap Index Scan on step_history_started_at_brin (actual rows=820.00 loops=1)
               Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
               Index Searches: 1
               Buffers: shared hit+read=5
(13 rows)

  attname   | correlation
------------+-------------
 id         |        1.00
 started_at |        1.00
 step_name  |        0.06
(3 rows)
```

- 24 kB, where the B-tree on the same column took 7.5 MB.
- The index gives page ranges, not rows: `Heap Blocks: lossy=82`, and every row of those pages is checked again, `Rows Removed by Index Recheck: 2094`. 87 pages, against 47 with the B-tree.
- It only works because the table was filled in time order. [`pg_stats`](https://www.postgresql.org/docs/18/view-pg-stats.html)`.correlation` measures how well a column follows the physical order of the rows: 1.00 for `id` and `started_at`, 0.06 for `step_name`. Exercise 3 builds the same table in another order.

BRIN is for large tables that grow in the order of a column: logs, events, measurements. SQL Server's nearest idea is a columnstore index skipping row groups by their minimum and maximum.

## Statistics on correlated columns

The planner multiplies the selectivity of each condition, as if the columns were independent ([lines 95-106](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L95-L106)):

```sql
-- Statistics: two columns that depend on each other
SELECT * FROM pg_temp.estimate($$
    SELECT * FROM ci.step_history
    WHERE workflow_name = 'Java course examples' AND job_name = 'java-for-csharp (ubuntu-latest)'
$$);
CREATE STATISTICS step_history_workflow_job (dependencies) ON workflow_name, job_name FROM ci.step_history;
ANALYZE ci.step_history;
SELECT * FROM pg_temp.estimate($$
    SELECT * FROM ci.step_history
    WHERE workflow_name = 'Java course examples' AND job_name = 'java-for-csharp (ubuntu-latest)'
$$);
SELECT dependencies FROM pg_stats_ext WHERE statistics_name = 'step_history_workflow_job';
```

```text
 estimated | actual
-----------+--------
      2254 |  18200
(1 row)

CREATE STATISTICS
ANALYZE
 estimated | actual
-----------+--------
     17896 |  18200
(1 row)

               dependencies
------------------------------------------
 {"2 => 3": 0.010889, "3 => 2": 0.980944}
(1 row)
```

`pg_temp.estimate` puts the planner's row estimate next to the actual count. A job named `java-for-csharp (ubuntu-latest)` only runs in the `Java course examples` workflow, so the second condition removes nothing. The planner estimated 2,254 rows, eight times too few; a wrong estimate chooses a nested loop where a hash join was needed, or the wrong index.

[`CREATE STATISTICS … (dependencies)`](https://www.postgresql.org/docs/18/planner-stats.html#PLANNER-STATS-EXTENDED) measures how much one column determines another. Columns 2 and 3 are `workflow_name` and `job_name`: the job name determines the workflow for 98% of the rows, and the estimate becomes 17,896. `ndistinct` helps `GROUP BY` on several columns, `mcv` lists their most common combinations.

## On Aurora

*To verify: nothing in this section ran on AWS.* Aurora PostgreSQL uses PostgreSQL's planner and index types, so the plans of this lesson read the same there, and `EXPLAIN (ANALYZE, BUFFERS)` works as on any PostgreSQL. Three things change around them.

- **Plan stability.** [Query plan management](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.overview.html), the `apg_plan_mgmt` extension (version 3.0 on Aurora PostgreSQL 18.4), captures the plans of the statements an application runs. With [`apg_plan_mgmt.capture_plan_baselines`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Parameters.html) set to `manual` or `automatic`, "the optimizer sets the status of a managed statement's first captured plan to `approved`", and later ones to `unapproved` ([capturing plans](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.CapturePlans.html)). With `apg_plan_mgmt.use_plan_baselines` on, the optimizer chooses among the approved plans, and [`evolve_plan_baselines`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Maintenance.html) compares the others before they are approved. SQL Server's Query Store forces plans in the same spirit; community PostgreSQL has nothing built in. A wrong estimate like the one in the statistics section above is the kind of regression it guards against.
- **Monitoring.** Performance Insights has been replaced by [CloudWatch Database Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html): "AWS announced that the end-of-life date for Performance Insights was July 31, 2026, and has migrated Performance Insights users to Database Insights". The [Aurora User Guide's document history](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/WhatsNew.html) still gives November 30, 2025. Database Insights shows the load by wait event and SQL statement; execution plans and lock analysis are in its Advanced mode only. The wait event [`IO:DataFileRead`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.iodatafileread.html) is the `read` part of `Buffers`: "a connection waits on a backend process to read a required page from storage because the page isn't available in shared memory".
- **Memory.** [AWS writes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.Tuning-memory-parameters.html) that "the value for `shared_buffers` in the default parameter group is usually set to around 75% of the available memory". Community PostgreSQL ships with 128 MB, and its documentation suggests 25% of memory as a starting point on a dedicated server ([`shared_buffers`](https://www.postgresql.org/docs/18/runtime-config-resource.html#GUC-SHARED-BUFFERS)). The [parameter reference](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html) gives the formula `SUM(DBInstanceClassMemory/12038,-50003)`, in a table for Aurora PostgreSQL 14; the value for 18 is *to verify*. My reading, which I didn't find stated by AWS, is that Aurora's storage isn't read through the operating system's file cache, which community PostgreSQL counts on for the rest of the memory.

## Key takeaways

- `EXPLAIN (ANALYZE, BUFFERS)` runs the query; read it from the innermost node, and compare pages, not only times.
- A B-tree serves `=`, ranges and sorts; equality columns first in a multicolumn index.
- Partial indexes are small; expression indexes need `IMMUTABLE` expressions and the same expression in the query.
- Index-only scans depend on the visibility map, that is on `VACUUM`.
- GIN indexes the elements of arrays, `jsonb` and text; an index serves operators, not meanings.
- BRIN is tiny and only useful when the column follows the physical order.
- Correlated columns fool the planner; `CREATE STATISTICS` fixes the estimate.

## Exercises

The solutions are in [`sql/05-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql), after the same setup as the lesson.

1. Show the 20 latest failed steps of the `Rust course examples` workflow, with a plan that has no `Sort` node, and an index smaller than a megabyte.

<details>
<summary>Solution</summary>

From [lines 8-16](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql#L8-L16):

```sql
-- Exercise 1: the 20 latest failed steps of the Rust course's workflow, without a sort
CREATE INDEX step_history_failures ON ci.step_history (workflow_name, started_at) WHERE conclusion = 'failure';
SELECT * FROM pg_temp.plan($$
    SELECT started_at, job_name, step_name FROM ci.step_history
    WHERE conclusion = 'failure' AND workflow_name = 'Rust course examples'
    ORDER BY started_at DESC
    LIMIT 20
$$);
SELECT pg_size_pretty(pg_relation_size('ci.step_history_failures')) AS size;
```

```text
CREATE INDEX
                                            QUERY PLAN
---------------------------------------------------------------------------------------------------
 Limit (actual rows=20.00 loops=1)
   Buffers: shared hit+read=15
   ->  Index Scan Backward using step_history_failures on step_history (actual rows=20.00 loops=1)
         Index Cond: (workflow_name = 'Rust course examples'::text)
         Index Searches: 1
         Buffers: shared hit+read=15
(6 rows)

  size
--------
 232 kB
(1 row)
```

A partial index on `(workflow_name, started_at)`, for the failures only: 232 kB. The query's `conclusion = 'failure'` matches the predicate, so the plan doesn't even show it as a condition; `workflow_name` is the equality column, and `started_at` gives the order, read backward.

</details>

2. Count the steps of September 10, 2026, first with `date_trunc('day', started_at) = '2026-09-10'`, then with a range, both with a B-tree on `started_at`. Compare the plans.

<details>
<summary>Solution</summary>

From [lines 18-25](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql#L18-L25):

```sql
-- Exercise 2: one day of steps, written two ways
CREATE INDEX step_history_started_at ON ci.step_history (started_at);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE date_trunc('day', started_at) = '2026-09-10'
$$);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE started_at >= '2026-09-10' AND started_at < '2026-09-11'
$$);
```

```text
CREATE INDEX
                                                 QUERY PLAN
------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=935
   ->  Index Only Scan using step_history_started_at on step_history (actual rows=2204.00 loops=1)
         Filter: (date_trunc('day'::text, started_at) = '2026-09-10 00:00:00+00'::timestamp with time zone)
         Rows Removed by Filter: 438596
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=935
(8 rows)

                                                                           QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=8
   ->  Index Only Scan using step_history_started_at on step_history (actual rows=2204.00 loops=1)
         Index Cond: ((started_at >= '2026-09-10 00:00:00+00'::timestamp with time zone) AND (started_at < '2026-09-11 00:00:00+00'::timestamp with time zone))
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=8
(7 rows)
```

With `date_trunc`, the index is only a smaller copy of the column: the plan reads all of it, 935 pages, and filters 438,596 entries. `date_trunc` on a `timestamptz` depends on the session's time zone, so it couldn't be indexed either without `AT TIME ZONE`. The range on the column itself is an `Index Cond`: 8 pages. SQL Server calls the second form *sargable*; the rule is the same.

</details>

3. Copy `ci.step_history` into a table sorted by `step_name`, then `started_at`. Build a BRIN index on `started_at` and count the steps of September 14. What happened?

<details>
<summary>Solution</summary>

From [lines 27-35](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql#L27-L35):

```sql
-- Exercise 3: the same rows in another physical order, and a BRIN index on started_at
CREATE TABLE ci.step_history_by_name AS SELECT * FROM ci.step_history ORDER BY step_name, started_at;
CREATE INDEX step_history_by_name_brin ON ci.step_history_by_name USING brin (started_at);
VACUUM ANALYZE ci.step_history_by_name;
SELECT attname, round(correlation::numeric, 2) AS correlation
FROM pg_stats WHERE schemaname = 'ci' AND tablename = 'step_history_by_name' AND attname = 'started_at';
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history_by_name WHERE started_at >= '2026-09-14'
$$);
```

```text
SELECT 440800
CREATE INDEX
VACUUM
  attname   | correlation
------------+-------------
 started_at |        0.06
(1 row)

                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=4869
   ->  Bitmap Heap Scan on step_history_by_name (actual rows=1533.00 loops=1)
         Recheck Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Rows Removed by Index Recheck: 212661
         Heap Blocks: lossy=4864
         Buffers: shared hit+read=4869
         ->  Bitmap Index Scan on step_history_by_name_brin (actual rows=48640.00 loops=1)
               Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
               Index Searches: 1
               Buffers: shared hit+read=5
(11 rows)
```

The correlation of `started_at` falls to 0.06. A range of pages now holds the steps of one or a few names, over many days: half the ranges may contain September 14, so the index keeps 4,864 of the table's 9,667 pages, and the recheck discards 212,661 rows. A sequential scan would have done little more work. A BRIN index needs data that arrives in its column's order and stays there.

</details>

## Sources

- PostgreSQL 18 documentation: [`EXPLAIN`](https://www.postgresql.org/docs/18/sql-explain.html), [using `EXPLAIN`](https://www.postgresql.org/docs/18/using-explain.html), [index types](https://www.postgresql.org/docs/18/indexes-types.html), [multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html), [partial indexes](https://www.postgresql.org/docs/18/indexes-partial.html), [indexes on expressions](https://www.postgresql.org/docs/18/indexes-expressional.html), [index-only scans and covering indexes](https://www.postgresql.org/docs/18/indexes-index-only-scans.html), [operator classes](https://www.postgresql.org/docs/18/indexes-opclass.html), [GIN](https://www.postgresql.org/docs/18/gin.html), [GiST](https://www.postgresql.org/docs/18/gist.html), [BRIN](https://www.postgresql.org/docs/18/brin.html), [the visibility map](https://www.postgresql.org/docs/18/storage-vm.html), [statistics used by the planner](https://www.postgresql.org/docs/18/planner-stats.html), [`pg_stats`](https://www.postgresql.org/docs/18/view-pg-stats.html), [function volatility](https://www.postgresql.org/docs/18/xfunc-volatility.html), [`CLUSTER`](https://www.postgresql.org/docs/18/sql-cluster.html), [release notes](https://www.postgresql.org/docs/18/release-18.html)
- SQL Server: [filtered indexes](https://learn.microsoft.com/sql/relational-databases/indexes/create-filtered-indexes), [indexes with included columns](https://learn.microsoft.com/sql/relational-databases/indexes/create-indexes-with-included-columns), [columnstore indexes and rowgroup elimination](https://learn.microsoft.com/sql/relational-databases/indexes/columnstore-indexes-query-performance)
- Amazon Aurora: [query plan management](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.overview.html), [capturing plans](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.CapturePlans.html), [its parameters](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Parameters.html), [maintaining plans](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Maintenance.html), [CloudWatch Database Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html), [document history](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/WhatsNew.html), [`IO:DataFileRead`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.iodatafileread.html), [memory parameters](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.Tuning-memory-parameters.html), [parameter reference](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html), all read on 2026-09-16
