---
title: "9. Partitioning and large tables"
description: Declarative partitioning in PostgreSQL 18 for SQL Server developers — range, list and hash partitions of the 440,800-row step history, primary keys that include the partition key, pruning at planning and at execution, partitioned indexes, retention with DETACH and DROP instead of DELETE, default partitions, ATTACH with a matching CHECK constraint, and pg_partman on Aurora.
sidebar:
  order: 9
---

The lesson's script is [`sql/09-partitioning.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql), and the exercises are in [`sql/09-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql). `check.sh` compares their output with [`expected/09-partitioning.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/09-partitioning.txt) and [`expected/09-exercises.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/09-exercises.txt). Both load `ci.step_history`, lesson 5's table of 440,800 steps over 200 days.

| SQL Server | PostgreSQL |
|---|---|
| partition function and partition scheme | `PARTITION BY RANGE`, `LIST` or `HASH` on the table, one table per partition |
| `RANGE LEFT` or `RANGE RIGHT` boundary values | `FOR VALUES FROM (…) TO (…)`: the lower bound included, the upper excluded |
| filegroups | tablespaces, rarely needed; each partition is its own set of files |
| aligned indexes | an index on the partitioned table, created on every partition |
| `ALTER TABLE … SWITCH PARTITION` | `ALTER TABLE … ATTACH PARTITION` and `DETACH PARTITION` |
| `$PARTITION.function(value)` | `tableoid::regclass`, the partition a row was read from |
| up to 15,000 partitions | no fixed limit; planning time and memory grow with the partitions a query keeps |

## A partitioned table

SQL Server partitions a table through two separate objects, a [partition function](https://learn.microsoft.com/sql/t-sql/statements/create-partition-function-transact-sql) and a scheme. PostgreSQL's [declarative partitioning](https://www.postgresql.org/docs/18/ddl-partitioning.html) puts the method and the key on the table, and each partition is a table of its own, with its bounds. The first attempt, with the same primary key as `ci.step_history` ([lines 8-18](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L8-L18)):

```sql
-- A partitioned table has no rows of its own: each row goes to the partition whose bounds contain its key
CREATE TABLE ci.step_log (
    id            bigint NOT NULL,
    workflow_name text NOT NULL,
    job_name      text NOT NULL,
    step_name     text NOT NULL,
    conclusion    ci.conclusion,
    started_at    timestamptz NOT NULL,
    duration      interval NOT NULL,
    PRIMARY KEY (id)
) PARTITION BY RANGE (started_at);
```

```text
ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "step_log" lacks column "started_at" which is part of the partition key.
```

There is no index across all partitions: each partition has its own, which can only check uniqueness among its own rows. The documentation's rule is that "the constraint's columns must include all of the partition key columns". Two rows with the same `id` in two different months would both be accepted, so PostgreSQL refuses the key. With `started_at` in it, the key is checked partition by partition and still holds for the whole table ([lines 20-46](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L20-L46)):

```sql
-- A primary key must include the partition key: each partition checks uniqueness on its own rows
CREATE TABLE ci.step_log (
    id            bigint NOT NULL,
    workflow_name text NOT NULL,
    job_name      text NOT NULL,
    step_name     text NOT NULL,
    conclusion    ci.conclusion,
    started_at    timestamptz NOT NULL,
    duration      interval NOT NULL,
    PRIMARY KEY (id, started_at)
) PARTITION BY RANGE (started_at);

-- One partition per month, February to September 2026, written by a query and run by \gexec
SELECT format('CREATE TABLE ci.step_log_%s PARTITION OF ci.step_log FOR VALUES FROM (%L) TO (%L)',
              to_char(m, 'YYYY_MM'), m, m + interval '1 month')
FROM generate_series(timestamptz '2026-02-01', '2026-09-01', interval '1 month') AS m
ORDER BY m
\gexec

INSERT INTO ci.step_log
SELECT id, workflow_name, job_name, step_name, conclusion, started_at, duration FROM ci.step_history;
VACUUM ANALYZE ci.step_log;

SELECT tableoid::regclass AS partition, count(*) AS rows, min(started_at)::date AS first_day, max(started_at)::date AS last_day
FROM ci.step_log
GROUP BY tableoid
ORDER BY first_day;
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 440800
VACUUM
      partition      | rows  | first_day  |  last_day
---------------------+-------+------------+------------
 ci.step_log_2026_02 |  5079 | 2026-02-26 | 2026-02-28
 ci.step_log_2026_03 | 68324 | 2026-03-01 | 2026-03-31
 ci.step_log_2026_04 | 66120 | 2026-04-01 | 2026-04-30
 ci.step_log_2026_05 | 68324 | 2026-05-01 | 2026-05-31
 ci.step_log_2026_06 | 66120 | 2026-06-01 | 2026-06-30
 ci.step_log_2026_07 | 68324 | 2026-07-01 | 2026-07-31
 ci.step_log_2026_08 | 68324 | 2026-08-01 | 2026-08-31
 ci.step_log_2026_09 | 30185 | 2026-09-01 | 2026-09-14
(8 rows)
```

- The query writes eight [`CREATE TABLE … PARTITION OF`](https://www.postgresql.org/docs/18/sql-createtable.html) statements, one per month, and `psql`'s [`\gexec`](https://www.postgresql.org/docs/18/app-psql.html#APP-PSQL-META-COMMAND-GEXEC) runs each row of the result as a statement: the nine `CREATE TABLE` lines are the table and its eight partitions.
- `FROM` includes its bound and `TO` excludes it, so `2026-03-01 00:00` belongs to March only.
- `tableoid::regclass` names the partition each row is stored in.
- February has only three days, since the history starts on February 26.

A row that falls outside every partition is refused ([lines 48-49](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L48-L49)):

```sql
-- A row outside every partition's bounds has nowhere to go
INSERT INTO ci.step_log VALUES (0, 'Deploy to GitHub Pages', 'deploy', 'Checkout', 'success', '2026-10-01 12:00+00', '2 seconds');
```

```text
ERROR:  no partition of relation "step_log" found for row
DETAIL:  Partition key of the failing row contains (started_at) = (2026-10-01 12:00:00+00).
```

## Partition pruning

With a condition on the partition key, the planner leaves out the partitions whose bounds can't match. `pg_temp.plan` is lesson 5's `EXPLAIN (ANALYZE, BUFFERS)` without costs and timings ([lines 51-58](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L51-L58)):

```sql
-- Partition pruning: a condition on the partition key leaves out the partitions that can't match
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_log WHERE started_at >= '2026-09-14'
$$);
-- Without a condition on the key, every partition is read
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_log WHERE step_name = 'Compile-fail doctests'
$$);
```

```text
                                                  QUERY PLAN
--------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=121
   ->  Index Only Scan using step_log_2026_09_pkey on step_log_2026_09 step_log (actual rows=1533.00 loops=1)
         Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=121
(7 rows)

                                    QUERY PLAN
-----------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=7453
   ->  Append (actual rows=9200.00 loops=1)
         Buffers: shared hit+read=7453
         ->  Seq Scan on step_log_2026_02 step_log_1 (actual rows=114.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 4965
               Buffers: shared hit+read=86
         ->  Seq Scan on step_log_2026_03 step_log_2 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_04 step_log_3 (actual rows=1380.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 64740
               Buffers: shared hit+read=1118
         ->  Seq Scan on step_log_2026_05 step_log_4 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_06 step_log_5 (actual rows=1380.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 64740
               Buffers: shared hit+read=1118
         ->  Seq Scan on step_log_2026_07 step_log_6 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_08 step_log_7 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_09 step_log_8 (actual rows=622.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 29563
               Buffers: shared hit+read=511
(36 rows)
```

- The first query reads one partition, September's, through its primary key index, whose second column is `started_at`: 121 pages.
- The second has no condition on `started_at`: an `Append` node reads all eight partitions, 7,453 pages. Partitioning doesn't speed up a query that doesn't filter on the key; an index on `step_name` would.

With a parameter, the value is unknown when the plan is built. A generic plan keeps every partition, and the executor removes the ones the value excludes when the query runs ([lines 60-65](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L60-L65)):

```sql
-- A parameter is only known at execution: the generic plan prunes then, and says how many partitions it skipped
PREPARE failures_since (timestamptz) AS
    SELECT count(*) FROM ci.step_log WHERE started_at >= $1 AND conclusion = 'failure';
SET plan_cache_mode = force_generic_plan;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF, BUFFERS OFF) EXECUTE failures_since('2026-09-01');
RESET plan_cache_mode;
```

```text
PREPARE
SET
                                      QUERY PLAN
---------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   ->  Append (actual rows=301.00 loops=1)
         Subplans Removed: 7
         ->  Seq Scan on step_log_2026_09 step_log_1 (actual rows=301.00 loops=1)
               Filter: ((started_at >= $1) AND ((conclusion)::text = 'failure'::text))
               Rows Removed by Filter: 29884
(6 rows)

RESET
```

`Subplans Removed: 7` is that pruning at execution. [`plan_cache_mode`](https://www.postgresql.org/docs/18/runtime-config-query.html#GUC-PLAN-CACHE-MODE) forces the generic plan, which a [prepared statement](https://www.postgresql.org/docs/18/sql-prepare.html) may switch to after its first five executions, whether it was prepared in SQL or by Npgsql and pgjdbc ([lesson 4](../04-csharp-java/)). [`enable_partition_pruning`](https://www.postgresql.org/docs/18/runtime-config-query.html#GUC-ENABLE-PARTITION-PRUNING), on by default, controls both kinds of pruning.

## Indexes and moving rows

An index created on the partitioned table is a *partitioned index*: PostgreSQL creates one index on each partition and attaches it to the parent ([lines 67-72](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L67-L72)):

```sql
-- An index created on the partitioned table is created on every partition, and on the partitions added later
CREATE INDEX step_log_step_name ON ci.step_log (step_name);
SELECT c.relname AS index, i.inhparent::regclass AS parent
FROM pg_inherits AS i JOIN pg_class AS c ON c.oid = i.inhrelid
WHERE i.inhparent = 'ci.step_log_step_name'::regclass
ORDER BY c.relname;
```

```text
CREATE INDEX
             index              |        parent
--------------------------------+-----------------------
 step_log_2026_02_step_name_idx | ci.step_log_step_name
 step_log_2026_03_step_name_idx | ci.step_log_step_name
 step_log_2026_04_step_name_idx | ci.step_log_step_name
 step_log_2026_05_step_name_idx | ci.step_log_step_name
 step_log_2026_06_step_name_idx | ci.step_log_step_name
 step_log_2026_07_step_name_idx | ci.step_log_step_name
 step_log_2026_08_step_name_idx | ci.step_log_step_name
 step_log_2026_09_step_name_idx | ci.step_log_step_name
(8 rows)
```

A partition created later gets its own copy of the index. Creating it on a large table locks the table; the documentation describes how to build each partition's index with `CONCURRENTLY` first, then create the parent's index `ON ONLY` the parent and attach them.

An `UPDATE` that changes the partition key moves the row: PostgreSQL deletes it from one partition and inserts it into the other ([lines 74-77](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L74-L77)):

```sql
-- An UPDATE of the partition key moves the row to another partition
UPDATE ci.step_log SET started_at = started_at - interval '1 month'
WHERE id = (SELECT min(id) FROM ci.step_log WHERE started_at >= '2026-09-01')
RETURNING tableoid::regclass AS now_in, started_at;
```

```text
       now_in        |       started_at
---------------------+------------------------
 ci.step_log_2026_08 | 2026-08-01 01:37:05+00
(1 row)

UPDATE 1
```

## Retention: detach, then drop

The usual reason for monthly partitions is to remove a month at once. A `DELETE` of February leaves as many dead row versions to vacuum as it removed rows, as in [lesson 6](../06-transactions/). Removing the partition takes a lock and deletes files ([lines 79-87](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L79-L87)):

```sql
-- Retention: removing a month with DELETE leaves dead rows to vacuum; dropping its partition removes a file
CREATE EXTENSION pgstattuple;
BEGIN;
DELETE FROM ci.step_log WHERE started_at < '2026-03-01';
SELECT pg_size_pretty(table_len) AS size, dead_tuple_count FROM pgstattuple('ci.step_log_2026_02');
ROLLBACK;
ALTER TABLE ci.step_log DETACH PARTITION ci.step_log_2026_02;
SELECT count(*) AS rows_left FROM ci.step_log;
DROP TABLE ci.step_log_2026_02;
```

```text
CREATE EXTENSION
BEGIN
DELETE 5079
  size  | dead_tuple_count
--------+------------------
 688 kB |             5079
(1 row)

ROLLBACK
ALTER TABLE
 rows_left
-----------
    435721
(1 row)

DROP TABLE
```

- [`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html) counts 5,079 dead tuples in February's 688 kB file, rolled back here.
- [`DETACH PARTITION`](https://www.postgresql.org/docs/18/sql-altertable.html) turns the partition into an ordinary table, which can be archived with `pg_dump` ([lesson 11](../11-backup/)) before `DROP TABLE`.
- `DETACH PARTITION … CONCURRENTLY` takes a weaker lock on the parent, but "cannot be run in a transaction block and is not allowed if the partitioned table contains a default partition".

## Default partitions, and attaching a loaded table

A [default partition](https://www.postgresql.org/docs/18/sql-createtable.html) receives the rows no other partition accepts: the October row refused above goes in. It then prevents creating the partition that row belongs to ([lines 89-93](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L89-L93)):

```sql
-- A default partition takes the rows no other partition accepts
CREATE TABLE ci.step_log_default PARTITION OF ci.step_log DEFAULT;
INSERT INTO ci.step_log VALUES (0, 'Deploy to GitHub Pages', 'deploy', 'Checkout', 'success', '2026-10-01 12:00+00', '2 seconds');
-- ... and then blocks a new partition that its rows belong to
CREATE TABLE ci.step_log_2026_10 PARTITION OF ci.step_log FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
```

```text
CREATE TABLE
INSERT 0 1
ERROR:  updated partition constraint for default partition "step_log_default" would be violated by some row
```

Adding a partition also scans the default partition, to check that none of its rows belong to the new one. A default partition is a safety net, which should stay empty.

The SQL Server habit of loading a staging table, then `SWITCH`ing it in, becomes `ATTACH PARTITION` ([lines 95-107](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L95-L107)):

```sql
-- Loading a month apart, then attaching it: a CHECK constraint with the same bounds saves the scan that validates them
DELETE FROM ci.step_log_default;
CREATE TABLE ci.step_log_2026_10 (LIKE ci.step_log INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
INSERT INTO ci.step_log_2026_10
SELECT id + 1000000, workflow_name, job_name, step_name, conclusion, started_at + interval '1 month', duration
FROM ci.step_log_2026_09;
ALTER TABLE ci.step_log_2026_10 ADD CONSTRAINT in_october
    CHECK (started_at >= '2026-10-01' AND started_at < '2026-11-01');
ALTER TABLE ci.step_log ATTACH PARTITION ci.step_log_2026_10 FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
SELECT relname AS partition, pg_get_expr(relpartbound, oid) AS bounds
FROM pg_class
WHERE oid IN (SELECT inhrelid FROM pg_inherits WHERE inhparent = 'ci.step_log'::regclass)
ORDER BY relname;
```

```text
DELETE 1
CREATE TABLE
INSERT 0 30184
ALTER TABLE
ALTER TABLE
    partition     |                                  bounds
------------------+--------------------------------------------------------------------------
 step_log_2026_03 | FOR VALUES FROM ('2026-03-01 00:00:00+00') TO ('2026-04-01 00:00:00+00')
 step_log_2026_04 | FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-05-01 00:00:00+00')
 step_log_2026_05 | FOR VALUES FROM ('2026-05-01 00:00:00+00') TO ('2026-06-01 00:00:00+00')
 step_log_2026_06 | FOR VALUES FROM ('2026-06-01 00:00:00+00') TO ('2026-07-01 00:00:00+00')
 step_log_2026_07 | FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00')
 step_log_2026_08 | FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00')
 step_log_2026_09 | FOR VALUES FROM ('2026-09-01 00:00:00+00') TO ('2026-10-01 00:00:00+00')
 step_log_2026_10 | FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00')
 step_log_default | DEFAULT
(9 rows)
```

- October is loaded in a table outside the partitioned table, a copy of September a month later, where it can be checked before anyone sees it.
- `ATTACH PARTITION` scans the table to check its bounds, holding an `ACCESS EXCLUSIVE` lock on it. The documentation recommends "creating a `CHECK` constraint matching the expected partition constraint on the table prior to attaching it": PostgreSQL then trusts the constraint and skips the scan. The constraint can be dropped afterwards.
- On the parent, `ATTACH PARTITION` takes a `SHARE UPDATE EXCLUSIVE` lock, weaker than the `ACCESS EXCLUSIVE` lock of `CREATE TABLE … PARTITION OF`.
- [`pg_get_expr(relpartbound, oid)`](https://www.postgresql.org/docs/18/functions-info.html) prints each partition's bounds, in UTC in this session.

## List and hash

[`PARTITION BY LIST`](https://www.postgresql.org/docs/18/ddl-partitioning.html) lists the values of each partition; `PARTITION BY HASH` spreads rows over a fixed number of partitions by the hash of the key ([lines 109-125](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L109-L125)):

```sql
-- List and hash partitioning
CREATE TABLE ci.step_outcomes (LIKE ci.step_log) PARTITION BY LIST (conclusion);
CREATE TABLE ci.step_outcomes_success PARTITION OF ci.step_outcomes FOR VALUES IN ('success');
CREATE TABLE ci.step_outcomes_other PARTITION OF ci.step_outcomes DEFAULT;
CREATE TABLE ci.step_buckets (LIKE ci.step_log) PARTITION BY HASH (job_name);
SELECT format('CREATE TABLE ci.step_buckets_%s PARTITION OF ci.step_buckets FOR VALUES WITH (MODULUS 4, REMAINDER %s)', r, r)
FROM generate_series(0, 3) AS r
ORDER BY r
\gexec
INSERT INTO ci.step_outcomes SELECT * FROM ci.step_log;
INSERT INTO ci.step_buckets SELECT * FROM ci.step_log;
SELECT tableoid::regclass AS partition, count(*) AS rows, count(DISTINCT job_name) AS jobs
FROM ci.step_outcomes GROUP BY tableoid
UNION ALL
SELECT tableoid::regclass, count(*), count(DISTINCT job_name)
FROM ci.step_buckets GROUP BY tableoid
ORDER BY 1;
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 465905
INSERT 0 465905
        partition         |  rows  | jobs
--------------------------+--------+------
 ci.step_outcomes_success | 441875 |   64
 ci.step_outcomes_other   |  24030 |   17
 ci.step_buckets_0        |  83288 |   18
 ci.step_buckets_1        | 113779 |   15
 ci.step_buckets_2        | 175176 |   13
 ci.step_buckets_3        |  93662 |   18
(6 rows)
```

- The `success` partition holds 95% of the rows: list partitioning follows the data, balanced or not.
- Hash partitioning of 64 distinct job names leaves one partition with twice the rows of another. A hash spreads *keys*, not rows: a few busy jobs weigh more than many rare ones. Hash partitions don't help pruning with ranges or retention; they split a table that has no natural range, for maintenance or parallel work.

## On Aurora

*To verify: nothing in this section ran on AWS.* Declarative partitioning is PostgreSQL's, and Aurora doesn't change it. What changes is the tooling around it.

- **pg_partman and pg_cron.** Partitions for next month have to exist before next month. [pg_partman](https://github.com/pgpartman/pg_partman) creates them ahead and drops old ones, and [pg_cron](https://github.com/citusdata/pg_cron) runs its maintenance on a schedule. The [extension table for Aurora PostgreSQL 18](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) lists pg_partman 5.4.3 on 18.4 (5.2.4 on 18.3) and pg_cron 1.6.7; AWS's [pg_partman page](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_Partitions.html) says it "is supported on Aurora PostgreSQL versions 12.6 and higher".
- **Limits.** I found no partition or table-count quota in [Aurora's quotas and limits](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html). The same page gives a maximum table size of 32 TiB for Aurora PostgreSQL, and recommends "table design best practices, such as partitioning of large tables": each partition is a table, so the limit applies per partition.
- **Blue/green deployments.** They replicate with logical replication ([lesson 11](../11-backup/#on-aurora)), and AWS's [considerations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html) state that "creating new partitions on partitioned tables isn't supported during blue/green deployments for Aurora", and that "the pg_partman extension must be disabled in the blue environment".
- **Zero-ETL to Redshift.** For [zero-ETL integrations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html), "the table partitions will be replicated to Amazon Redshift. However, the partitioned table itself isn't replicated".

## Key takeaways

- A partitioned table is a parent with no rows and one table per partition; `FROM` is inclusive, `TO` exclusive.
- Primary keys and unique constraints must include the partition key.
- Pruning needs a condition on the key; with parameters, it happens at execution (`Subplans Removed`).
- Indexes created on the parent are created on every partition, present and future.
- Retention is `DETACH` and `DROP`, not `DELETE`: no dead rows, no vacuum.
- A default partition catches strays, and makes adding partitions scan it.
- Load apart, add a matching `CHECK` constraint, then `ATTACH`: the SQL Server `SWITCH` pattern.
- Hash partitions spread keys, not rows.

## Exercises

The solutions are in [`sql/09-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql).

1. Partition a copy of `ci.runs` by workflow: one partition for `Deploy to GitHub Pages`, one for the three course example workflows, and a default partition. How many runs does each hold, and which partitions does a query for `Rust course examples` read?

<details>
<summary>Solution</summary>

[Lines 8-19](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql#L8-L19):

```sql
-- Exercise 1: runs partitioned by workflow, with its own partition for deployments and a default for the rest,
-- and a plan that reads only the partition for 'Rust course examples'
CREATE TABLE ci.runs_by_workflow (LIKE ci.runs) PARTITION BY LIST (workflow_name);
CREATE TABLE ci.runs_deploy PARTITION OF ci.runs_by_workflow FOR VALUES IN ('Deploy to GitHub Pages');
CREATE TABLE ci.runs_examples PARTITION OF ci.runs_by_workflow
    FOR VALUES IN ('Rust course examples', 'Java course examples', 'WSL containers examples');
CREATE TABLE ci.runs_other PARTITION OF ci.runs_by_workflow DEFAULT;
INSERT INTO ci.runs_by_workflow SELECT * FROM ci.runs;
SELECT tableoid::regclass AS partition, count(*) AS runs FROM ci.runs_by_workflow GROUP BY tableoid ORDER BY tableoid::regclass::text;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.runs_by_workflow WHERE workflow_name = 'Rust course examples'
$$);
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 125
    partition     | runs
------------------+------
 ci.runs_deploy   |   65
 ci.runs_examples |   27
 ci.runs_other    |   33
(3 rows)

                                  QUERY PLAN
------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=1
   ->  Seq Scan on runs_examples runs_by_workflow (actual rows=18.00 loops=1)
         Filter: (workflow_name = 'Rust course examples'::text)
         Rows Removed by Filter: 9
         Buffers: shared hit+read=1
(6 rows)
```

`LIKE ci.runs` copies the columns and their `NOT NULL` constraints, not the primary key. Pruning keeps `runs_examples`, the partition whose list contains the value; the default partition is left out too, since the value is in another partition's list.

</details>

2. Partition September's steps in two levels: by month, then, inside the month, by conclusion. Show the tree with [`pg_partition_tree`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-INFO-PARTITION), and the plan of a query for the failures since September 14.

<details>
<summary>Solution</summary>

[Lines 21-31](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql#L21-L31):

```sql
-- Exercise 2: two levels, months then conclusion, and the tree that pg_partition_tree returns
CREATE TABLE ci.step_months (LIKE ci.step_history) PARTITION BY RANGE (started_at);
CREATE TABLE ci.step_months_2026_09 PARTITION OF ci.step_months
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01') PARTITION BY LIST (conclusion);
CREATE TABLE ci.step_months_2026_09_success PARTITION OF ci.step_months_2026_09 FOR VALUES IN ('success');
CREATE TABLE ci.step_months_2026_09_other PARTITION OF ci.step_months_2026_09 DEFAULT;
INSERT INTO ci.step_months SELECT * FROM ci.step_history WHERE started_at >= '2026-09-01';
SELECT relid, parentrelid, isleaf, level FROM pg_partition_tree('ci.step_months') ORDER BY level, relid::text;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_months WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 30185
             relid              |      parentrelid       | isleaf | level
--------------------------------+------------------------+--------+-------
 ci.step_months                 |                        | f      |     0
 ci.step_months_2026_09         | ci.step_months         | f      |     1
 ci.step_months_2026_09_other   | ci.step_months_2026_09 | t      |     2
 ci.step_months_2026_09_success | ci.step_months_2026_09 | t      |     2
(4 rows)

                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=36
   ->  Seq Scan on step_months_2026_09_other step_months (actual rows=15.00 loops=1)
         Filter: ((started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone) AND ((conclusion)::text = 'failure'::text))
         Rows Removed by Filter: 1512
         Buffers: shared hit+read=36
(6 rows)
```

A partition declared with its own `PARTITION BY` is itself partitioned: level 1 has no rows either. Both conditions prune, one per level, and the query reads only the `other` partition of September.

</details>

3. Write a procedure that detaches and drops the monthly partitions of a table that end on or before a given date, and use it to keep June to September.

<details>
<summary>Solution</summary>

[Lines 33-63](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql#L33-L63):

```sql
-- Exercise 3: a procedure that detaches and drops the monthly partitions that end before a date
CREATE TABLE ci.step_log (LIKE ci.step_history) PARTITION BY RANGE (started_at);
SELECT format('CREATE TABLE ci.step_log_%s PARTITION OF ci.step_log FOR VALUES FROM (%L) TO (%L)',
              to_char(m, 'YYYY_MM'), m, m + interval '1 month')
FROM generate_series(timestamptz '2026-02-01', '2026-09-01', interval '1 month') AS m
ORDER BY m
\gexec

CREATE PROCEDURE ci.drop_partitions_before(parent regclass, cutoff timestamptz)
LANGUAGE plpgsql AS $$
DECLARE
    part regclass;
BEGIN
    FOR part IN
        SELECT c.oid::regclass
        FROM pg_inherits AS i JOIN pg_class AS c ON c.oid = i.inhrelid
        -- the upper bound, read back from the partition's definition: FOR VALUES FROM ('…') TO ('…')
        WHERE i.inhparent = parent
          AND substring(pg_get_expr(c.relpartbound, c.oid) FROM $re$TO \('([^']+)'\)$re$)::timestamptz <= cutoff
        ORDER BY c.relname
    LOOP
        -- the name first: once the table is dropped, its regclass prints as a bare OID
        RAISE NOTICE 'dropping %', part;
        EXECUTE format('ALTER TABLE %s DETACH PARTITION %s', parent, part);
        EXECUTE format('DROP TABLE %s', part);
    END LOOP;
END
$$;

CALL ci.drop_partitions_before('ci.step_log', '2026-06-01');
SELECT relid FROM pg_partition_tree('ci.step_log') WHERE isleaf ORDER BY relid::text;
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE PROCEDURE
NOTICE:  dropping ci.step_log_2026_02
NOTICE:  dropping ci.step_log_2026_03
NOTICE:  dropping ci.step_log_2026_04
NOTICE:  dropping ci.step_log_2026_05
CALL
        relid
---------------------
 ci.step_log_2026_06
 ci.step_log_2026_07
 ci.step_log_2026_08
 ci.step_log_2026_09
(4 rows)
```

The upper bound comes back from the catalog as text, read with a regular expression and cast to `timestamptz`. A `regclass` prints as a name while the table exists; after `DROP TABLE`, the same value prints as a number, which is why the notice comes first. This is the job pg_partman's retention settings do on a schedule.

</details>

## Sources

- PostgreSQL 18 documentation: [table partitioning](https://www.postgresql.org/docs/18/ddl-partitioning.html), [`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html), [`ALTER TABLE`](https://www.postgresql.org/docs/18/sql-altertable.html), [query planning settings](https://www.postgresql.org/docs/18/runtime-config-query.html), [`psql`](https://www.postgresql.org/docs/18/app-psql.html), [`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html), [system information functions](https://www.postgresql.org/docs/18/functions-info.html), [partitioning information functions](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-INFO-PARTITION), [PostgreSQL 18 release notes](https://www.postgresql.org/docs/18/release-18.html)
- SQL Server: [partitioned tables and indexes](https://learn.microsoft.com/sql/relational-databases/partitions/partitioned-tables-and-indexes), [`CREATE PARTITION FUNCTION`](https://learn.microsoft.com/sql/t-sql/statements/create-partition-function-transact-sql), [`ALTER TABLE … SWITCH`](https://learn.microsoft.com/sql/t-sql/statements/alter-table-transact-sql)
- AWS: [extension versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), [pg_partman on Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_Partitions.html), [quotas and limits](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html), [blue/green considerations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html), [zero-ETL integrations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html), all read on 2026-09-16
- [pg_partman](https://github.com/pgpartman/pg_partman), [pg_cron](https://github.com/citusdata/pg_cron)
