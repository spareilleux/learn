---
title: "3. Queries: CTEs, windows, LATERAL, upserts and MERGE"
description: The SQL that PostgreSQL writes differently from T-SQL, on the course model — CTEs and WITH RECURSIVE with a cycle and the CYCLE clause, window functions and FILTER, LATERAL for CROSS APPLY, DISTINCT ON, RETURNING with old and new, INSERT … ON CONFLICT and MERGE with merge_action(); and what they find in this site's CI history and Guitar Alchemist's dependencies.
sidebar:
  order: 3
---

The lesson's script is [`sql/03-queries.sql`](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql), the exercises are in [`sql/03-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql), and `check.sh` compares their output with [`expected/03-queries.txt`](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/expected/03-queries.txt) and [`expected/03-exercises.txt`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/expected/03-exercises.txt). Both scripts start by loading the model of [lesson 2](../02-types/).

Joins, `GROUP BY` and subqueries are written the same way in both dialects, so this lesson skips them. It covers what a SQL Server developer writes differently, or can't write at all.

| T-SQL | PostgreSQL |
|---|---|
| `SELECT TOP (1) …` in a subquery, or `ROW_NUMBER()` and a filter | `DISTINCT ON (…)` |
| `CROSS APPLY`, `OUTER APPLY` | `CROSS JOIN LATERAL`, `LEFT JOIN LATERAL … ON true` |
| `OPTION (MAXRECURSION n)` | `statement_timeout`, `UNION`, the `CYCLE` clause |
| `SUM(CASE WHEN … THEN 1 END)` | `count(*) FILTER (WHERE …)` |
| `OUTPUT inserted.*, deleted.*` | `RETURNING new.*, old.*` |
| `MERGE … WITH (HOLDLOCK)` to insert or update | `INSERT … ON CONFLICT DO UPDATE` |
| `MERGE … OUTPUT $action` | `MERGE … RETURNING merge_action()` |

## CTEs

A common table expression names a query for the statement that follows, as in T-SQL ([lines 7-16](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L7-L16)):

```sql
WITH failed_runs AS (
    SELECT run_id, workflow_name FROM ci.runs WHERE conclusion = 'failure'
)
SELECT f.workflow_name, count(DISTINCT f.run_id) AS failed_runs,
       count(j.job_id) FILTER (WHERE j.conclusion = 'failure') AS failed_jobs
FROM failed_runs AS f
LEFT JOIN ci.jobs AS j USING (run_id)
GROUP BY f.workflow_name
ORDER BY failed_runs DESC, f.workflow_name
LIMIT 5;
```

```text
            workflow_name            | failed_runs | failed_jobs
-------------------------------------+-------------+-------------
 GHA 05: exercise checks             |           3 |           3
 Rust course examples                |           3 |           7
 Deploy to GitHub Pages              |           2 |           2
 GHA 03: triggers                    |           2 |           0
 GHA 04: data between steps and jobs |           1 |           1
(5 rows)
```

- `USING (run_id)` joins on the column of that name in both tables, and keeps a single `run_id` column in the result.
- [`FILTER (WHERE …)`](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-AGGREGATES) restricts one aggregate to some rows. T-SQL writes `COUNT(CASE WHEN j.conclusion = 'failure' THEN 1 END)`.
- `GHA 03: triggers` has two failed runs and no failed job: those two runs have no job at all in the snapshot.

Since PostgreSQL 12, a CTE referenced once and without side effects is inlined into the query, like a view; `WITH … AS MATERIALIZED` forces the older behaviour, computing it once ([`WITH` queries](https://www.postgresql.org/docs/18/queries-with.html)).

## Recursive CTEs

Guitar Alchemist's project references form a graph. `WITH RECURSIVE` walks it from `GaApi`: the first `SELECT` gives the direct references, and the second joins the rows found so far with the references of those projects, until a round finds nothing new ([lines 19-29](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L19-L29)):

```sql
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth
    FROM ga.project_refs
    WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.depth + 1
    FROM deps AS d
    JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) AS paths, count(DISTINCT to_path) AS projects, max(depth) AS longest_path
FROM deps;
```

```text
 paths | projects | longest_path
-------+----------+--------------
   435 |       20 |            7
(1 row)
```

`GaApi` depends on 20 projects, reached through 435 different paths: a diamond of dependencies counts once per path. The longest path is 7 references long.

The path itself can be carried along in an array. `DISTINCT ON` keeps the shortest chain to each project; it's explained below ([lines 32-49](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L32-L49)):

```sql
WITH RECURSIVE deps AS (
    SELECT to_path, ARRAY[split_part(to_path, '/', -1)] AS chain
    FROM ga.project_refs
    WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.chain || split_part(r.to_path, '/', -1)
    FROM deps AS d
    JOIN ga.project_refs AS r ON r.from_path = d.to_path
),
shortest AS (
    SELECT DISTINCT ON (to_path) to_path, chain
    FROM deps
    ORDER BY to_path, cardinality(chain), chain
)
SELECT cardinality(chain) AS depth, array_to_string(chain, ' > ') AS chain
FROM shortest
WHERE cardinality(chain) >= 3
ORDER BY chain;
```

```text
 depth |                                   chain
-------+----------------------------------------------------------------------------
     3 | GA.Business.AI.csproj > GA.Data.MongoDB.csproj > GA.Business.Assets.csproj
(1 row)
```

[`split_part`](https://www.postgresql.org/docs/18/functions-string.html) with a negative index counts from the end, since PostgreSQL 14: `-1` is the file name. Only one project is three references away, even at its shortest: the other 19 are one or two references from `GaApi`.

### A cycle

.NET project references can't form a cycle: MSBuild refuses to build one. Data can. The script adds the reference `GA.Core → GaApi`, and runs the first query again ([lines 52-60](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L52-L60)):

```sql
INSERT INTO ga.project_refs VALUES ('Common/GA.Core/GA.Core.csproj', 'Apps/ga-server/GaApi/GaApi.csproj');
SET statement_timeout = '3s';
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION
    SELECT r.to_path, d.depth + 1 FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) FROM deps;
RESET statement_timeout;
```

```text
INSERT 0 1
SET
ERROR:  canceling statement due to statement timeout
RESET
```

The query never ends: each round finds the same projects again, one level deeper, and `depth` makes every row new, so `UNION`, which removes duplicate rows, removes nothing. [`statement_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-STATEMENT-TIMEOUT) stops it after 3 seconds. SQL Server stops a recursive CTE after 100 levels by default, with an error that says the maximum recursion 100 has been exhausted, and [`MAXRECURSION`](https://learn.microsoft.com/sql/t-sql/queries/with-common-table-expression-transact-sql) changes the limit. PostgreSQL has no such limit: without a timeout, this query runs until someone cancels it or the server runs out of memory or disk.

Two ways out ([lines 62-76](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L62-L76)):

```sql
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.depth + 1 FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
) CYCLE to_path SET is_cycle USING path
SELECT count(*) AS paths, count(*) FILTER (WHERE is_cycle) AS cycles, max(depth) AS longest_path
FROM deps;

WITH RECURSIVE deps AS (
    SELECT to_path FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION
    SELECT r.to_path FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) AS projects FROM deps;
DELETE FROM ga.project_refs WHERE from_path = 'Common/GA.Core/GA.Core.csproj';
```

```text
 paths | cycles | longest_path
-------+--------+--------------
 15655 |   6982 |           13
(1 row)

 projects
----------
       21
(1 row)

DELETE 1
```

- The [`CYCLE` clause](https://www.postgresql.org/docs/18/queries-with.html#QUERIES-WITH-CYCLE), from the SQL standard and in PostgreSQL since version 14, keeps the list of visited `to_path` values in a column named `path`, and sets `is_cycle` to true on a row that reaches a project already on its path. That row is kept, and the recursion stops there. With the cycle, there are 15,655 paths instead of 435: every path through `GA.Core` now goes round once more.
- Without `depth`, a project found again is a duplicate row, `UNION` discards it, and the recursion stops when a round adds nothing. 21 projects: the 20 dependencies, and `GaApi` itself, reached through the cycle. T-SQL doesn't allow `UNION` in a recursive CTE, only `UNION ALL`.

The last statement removes the cycle.

## Window functions

Window functions exist in both dialects, with the same `OVER (PARTITION BY … ORDER BY …)`. The runs of the Rust course's workflow, in order ([lines 79-88](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L79-L88)):

```sql
SELECT run_id, started_at,
       updated_at - started_at AS took,
       lag(updated_at - started_at) OVER w AS previous_took,
       row_number() OVER w AS nth,
       count(*) FILTER (WHERE conclusion = 'failure') OVER w AS failures_so_far
FROM ci.runs
WHERE workflow_name = 'Rust course examples'
WINDOW w AS (PARTITION BY workflow_name ORDER BY started_at, run_id)
ORDER BY started_at, run_id
LIMIT 6;
```

```text
   run_id    |       started_at       |   took   | previous_took | nth | failures_so_far
-------------+------------------------+----------+---------------+-----+-----------------
 34768259924 | 2026-09-13 16:20:06+00 | 00:00:32 |               |   1 |               0
 34768314558 | 2026-09-13 16:21:09+00 | 00:00:20 | 00:00:32      |   2 |               0
 34769559799 | 2026-09-13 16:45:55+00 | 00:00:20 | 00:00:20      |   3 |               0
 34770934509 | 2026-09-13 17:13:25+00 | 00:00:33 | 00:00:20      |   4 |               0
 34772306529 | 2026-09-13 17:40:34+00 | 00:00:40 | 00:00:33      |   5 |               1
 34772373891 | 2026-09-13 17:41:56+00 | 00:00:31 | 00:00:40      |   6 |               2
(6 rows)
```

- The `WINDOW` clause names a window once for several functions. SQL Server has it since SQL Server 2022.
- `FILTER` works on an aggregate used as a window function too: `failures_so_far` is a running count of the failures.
- A window with `ORDER BY` and no frame runs from the start of the partition up to the current row, and its peers: rows with the same `ORDER BY` values. That's why `run_id` is in the `ORDER BY`: two runs started in the same second would otherwise be counted together.

A window function can also run over the result of a `GROUP BY` ([lines 91-95](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L91-L95)):

```sql
SELECT labels[1] AS os, count(*) AS jobs, sum(duration) AS total,
       round(100 * extract(epoch FROM sum(duration)) / sum(extract(epoch FROM sum(duration))) OVER (), 1) AS percent
FROM ci.jobs
GROUP BY labels[1]
ORDER BY total DESC;
```

```text
       os       | jobs |  total   | percent
----------------+------+----------+---------
 ubuntu-latest  |  246 | 01:27:52 |    50.0
 windows-latest |   35 | 00:56:25 |    32.1
 macos-latest   |   34 | 00:31:33 |    17.9
(3 rows)
```

`sum(duration)` is the aggregate of each group; `sum(…) OVER ()` sums those aggregates over the whole result. [`extract(epoch FROM …)`](https://www.postgresql.org/docs/18/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT) turns an interval into seconds. Windows jobs are 11% of the jobs and 32% of the CI time. The [window functions tutorial](https://www.postgresql.org/docs/18/tutorial-window.html) introduces them, and the [window function call syntax](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-WINDOW-FUNCTIONS) lists the frame options.

## LATERAL

A subquery in `FROM` normally can't see the other tables of the same `FROM`. With [`LATERAL`](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-LATERAL), it can, and it runs once per row on its left: SQL Server's `CROSS APPLY`. The first failed step of each failed run ([lines 98-117](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L98-L117)):

```sql
SELECT r.workflow_name, r.run_id, first_failure.job, first_failure.step
FROM ci.runs AS r
CROSS JOIN LATERAL (
    SELECT j.name AS job, s.name AS step
    FROM ci.jobs AS j
    JOIN ci.steps AS s USING (job_id)
    WHERE j.run_id = r.run_id AND s.conclusion = 'failure'
    ORDER BY s.started_at, j.job_id, s.number
    LIMIT 1
) AS first_failure
WHERE r.conclusion = 'failure'
ORDER BY r.workflow_name, r.run_id
LIMIT 6;

SELECT count(*) AS failed_runs,
       count(*) FILTER (WHERE NOT EXISTS (
           SELECT FROM ci.jobs AS j JOIN ci.steps AS s USING (job_id)
           WHERE j.run_id = r.run_id AND s.conclusion = 'failure')) AS without_failed_step
FROM ci.runs AS r
WHERE r.conclusion = 'failure';
```

```text
            workflow_name            |   run_id    |     job      |            step
-------------------------------------+-------------+--------------+-----------------------------
 Deploy to GitHub Pages              | 34845198191 | deploy       | Deploy to GitHub Pages
 GHA 04: data between steps and jobs | 34845384597 | produce      | Tests (fail on demand)
 GHA 04: exercise checks             | 34847078287 | produce      | Fail
 GHA 05: exercise checks             | 34847802892 | no-lock-file | Run actions/setup-dotnet@v6
 GHA 05: exercise checks             | 34848189352 | no-lock-file | Run actions/setup-dotnet@v6
 GHA 05: exercise checks             | 34848421802 | no-lock-file | Run actions/setup-dotnet@v6
(6 rows)

 failed_runs | without_failed_step
-------------+---------------------
          16 |                   3
(1 row)
```

`CROSS JOIN LATERAL` drops the rows on the left for which the subquery returns nothing, like `CROSS APPLY`; `LEFT JOIN LATERAL (…) ON true` keeps them, like `OUTER APPLY`, and exercise 3 uses it. Here, 3 of the 16 failed runs have no failed step, so they're missing from the first result: the two runs without jobs seen above, and a run of `Deploy to GitHub Pages` whose failed job has only successful steps in the snapshot.

`LIMIT 1` inside the subquery is the reason to use `LATERAL`: "the first … of each …" is hard to write as a plain join.

## DISTINCT ON

Package versions are text in `ga.package_refs`, as they are in a `.csproj`. The highest version of a package, with `max` ([lines 120-124](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L120-L124)):

```sql
SELECT package, max(version) AS text_max, count(DISTINCT version) AS versions
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.Hosting%'
GROUP BY package
ORDER BY package;
```

```text
                  package                  | text_max | versions
-------------------------------------------+----------+----------
 Microsoft.Extensions.Hosting              | 9.0.4    |        5
 Microsoft.Extensions.Hosting.Abstractions | 9.0.10   |        1
(2 rows)
```

`max` compares text character by character, and `'9'` is greater than `'1'`: the text maximum of `Microsoft.Extensions.Hosting` is 9.0.4, while Guitar Alchemist also references 10.0.5. The same package is referenced in five different versions across the solution.

A version compares correctly as an array of integers, and [`DISTINCT ON`](https://www.postgresql.org/docs/18/sql-select.html#SQL-DISTINCT) keeps the first row of each group in the `ORDER BY` order ([lines 127-141](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L127-L141)):

```sql
SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.%'
ORDER BY package, string_to_array(version, '.')::int[] DESC;

SELECT version, count(*) AS refs
FROM ga.package_refs
WHERE version !~ '^\d+(\.\d+)*$'
GROUP BY version
ORDER BY version;

SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.H%' AND version ~ '^\d+(\.\d+)*$'
ORDER BY package, string_to_array(version, '.')::int[] DESC;
```

```text
ERROR:  invalid input syntax for type integer: "0-preview"
         version         | refs
-------------------------+------
 0.*                     |    1
 0.1.0-preview.10        |    1
 0.22.0-preview.24378.1  |    1
 1.0.0-alpha0031         |    1
 1.0.0-beta.24164.1      |   12
 1.0.0-preview.251028.1  |    1
 1.27.0-alpha            |    2
 13.0.0-preview.24       |    2
 2.0.0-beta5.25277.114   |    2
 2.2.0-beta.1            |    5
 4.0.0-preview.24478.1   |    2
 8.*-*                   |    1
 9.4.0-preview.1.25207.5 |    4
(13 rows)

                  package                  | version
-------------------------------------------+---------
 Microsoft.Extensions.Hosting              | 10.0.5
 Microsoft.Extensions.Hosting.Abstractions | 9.0.10
 Microsoft.Extensions.Http                 | 10.0.0
 Microsoft.Extensions.Http.Polly           | 9.0.10
 Microsoft.Extensions.Http.Resilience      | 9.1.0
(5 rows)
```

1. The cast fails: a version such as `9.4.0-preview.1.25207.5` splits into `9`, `4`, `0-preview`, … and `0-preview` isn't an integer. One bad row fails the whole statement.
2. `!~` means "doesn't match the regular expression". 13 distinct versions aren't plain numbers: previews and betas, and two floating versions, `0.*` and `8.*-*`, which let NuGet pick a different package at each restore.
3. Filtered to numeric versions, `DISTINCT ON (package)` gives one row per package, the first in the order `package, version DESC`. Its expressions must start the `ORDER BY`.

T-SQL has no `DISTINCT ON`; the usual equivalent is `ROW_NUMBER() OVER (PARTITION BY package ORDER BY …)` in a subquery, filtered on `= 1`. The two-level sort, text for packages and arrays for versions, is also something T-SQL can't write without splitting the string into columns.

## RETURNING

`INSERT`, `UPDATE`, `DELETE` and `MERGE` can return the rows they changed, as T-SQL's `OUTPUT` does ([lines 144-154](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L144-L154)):

```sql
CREATE TABLE ga.pinned_versions (
    package    text PRIMARY KEY,
    version    text NOT NULL CHECK (version ~ '^\d+(\.\d+)*$'),
    pinned_at  timestamptz NOT NULL DEFAULT '2026-09-14 00:00:00+00'
);
INSERT INTO ga.pinned_versions (package, version)
SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package IN ('Microsoft.Extensions.Hosting', 'MongoDB.Driver')
ORDER BY package, string_to_array(version, '.')::int[] DESC
RETURNING package, version, pinned_at;
```

```text
CREATE TABLE
           package            | version |       pinned_at
------------------------------+---------+------------------------
 Microsoft.Extensions.Hosting | 10.0.5  | 2026-09-14 00:00:00+00
 MongoDB.Driver               | 3.5.0   | 2026-09-14 00:00:00+00
(2 rows)

INSERT 0 2
```

The statement returns the rows as a query does, and `psql` prints `INSERT 0 2` after them. `pinned_at` has a fixed default so that the output doesn't change from day to day; a real table would use `DEFAULT now()`. [`RETURNING`](https://www.postgresql.org/docs/18/dml-returning.html) is how a program gets back an identity or a `uuidv7()` generated by the server, in one round trip: lesson 4 uses it from C# and Java.

## INSERT … ON CONFLICT

"Insert, or update if it exists" is one statement ([lines 157-171](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L157-L171)):

```sql
INSERT INTO ga.pinned_versions (package, version, pinned_at)
VALUES ('MongoDB.Driver', '3.2.0', '2026-09-15 00:00:00+00'),
       ('Npgsql', '10.0.3', '2026-09-15 00:00:00+00')
ON CONFLICT (package) DO UPDATE
SET version = EXCLUDED.version, pinned_at = EXCLUDED.pinned_at
RETURNING package, old.version AS old_version, new.version AS new_version, old IS NULL AS inserted;

INSERT INTO ga.pinned_versions (package, version)
VALUES ('Dapper', '2.1.86'), ('Dapper', '2.1.72')
ON CONFLICT (package) DO UPDATE SET version = EXCLUDED.version;

INSERT INTO ga.pinned_versions (package, version)
VALUES ('Npgsql', '9.0.5')
ON CONFLICT (package) DO NOTHING
RETURNING package;
```

```text
    package     | old_version | new_version | inserted
----------------+-------------+-------------+----------
 MongoDB.Driver | 3.5.0       | 3.2.0       | f
 Npgsql         |             | 10.0.3      | t
(2 rows)

INSERT 0 2
ERROR:  ON CONFLICT DO UPDATE command cannot affect row a second time
HINT:  Ensure that no rows proposed for insertion within the same command have duplicate constrained values.
 package
---------
(0 rows)

INSERT 0 0
```

- [`ON CONFLICT (package) DO UPDATE`](https://www.postgresql.org/docs/18/sql-insert.html#SQL-ON-CONFLICT) needs a unique index or constraint on `package`, here the primary key. `EXCLUDED` is the row that was proposed for insertion.
- Since PostgreSQL 18, `RETURNING` can name `old` and `new`, like `deleted` and `inserted` in T-SQL's `OUTPUT`. For an inserted row, `old` is `NULL`, so `old IS NULL` tells an insert from an update.
- The second statement proposes `Dapper` twice, and fails: a row can't be updated twice by the same command, because the result would depend on the order of the `VALUES`. Deduplicate the input first.
- `DO NOTHING` skips the conflicting row, and `RETURNING` returns only the rows actually inserted: none here.

The documentation guarantees an atomic outcome for `ON CONFLICT DO UPDATE`, an insert or an update, even under high concurrency: if another transaction inserts the same `package` at the same time, the statement waits for it and then updates, instead of failing with a duplicate key. For the same upsert, [SQL Server's `MERGE` documentation](https://learn.microsoft.com/sql/t-sql/statements/merge-transact-sql) recommends the `HOLDLOCK` hint, a synonym for the serializable isolation level.

## MERGE

[`MERGE`](https://www.postgresql.org/docs/18/sql-merge.html) arrived in PostgreSQL 15; `WHEN NOT MATCHED BY SOURCE`, `RETURNING` and `merge_action()` in PostgreSQL 17. The script pins the highest numeric version of every package referenced by eight projects or more, updates what changed, and deletes the pins of packages that are no longer in the list ([lines 174-195](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L174-L195)):

```sql
WITH changes AS (
    MERGE INTO ga.pinned_versions AS t
    USING (
        SELECT package, (array_agg(version ORDER BY string_to_array(version, '.')::int[] DESC))[1] AS version
        FROM ga.package_refs
        WHERE version ~ '^\d+(\.\d+)*$'
        GROUP BY package
        HAVING count(*) >= 8
    ) AS s
    ON t.package = s.package
    WHEN MATCHED AND t.version <> s.version THEN
        UPDATE SET version = s.version, pinned_at = '2026-09-16 00:00:00+00'
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (package, version) VALUES (s.package, s.version)
    WHEN NOT MATCHED BY SOURCE THEN
        DELETE
    RETURNING merge_action() AS action, coalesce(new.package, old.package) AS package,
              old.version AS old_version, new.version AS new_version
)
SELECT * FROM changes ORDER BY action, package;

SELECT package, version, pinned_at FROM ga.pinned_versions ORDER BY package;
```

```text
 action |                  package                  | old_version | new_version
--------+-------------------------------------------+-------------+-------------
 DELETE | Npgsql                                    | 10.0.3      |
 INSERT | coverlet.collector                        |             | 6.0.4
 INSERT | JetBrains.Annotations                     |             | 2024.3.0
 INSERT | Microsoft.Extensions.DependencyInjection  |             | 10.0.2
 INSERT | Microsoft.Extensions.Logging              |             | 10.0.0
 INSERT | Microsoft.Extensions.Logging.Abstractions |             | 10.0.2
 INSERT | Microsoft.Extensions.Logging.Console      |             | 10.0.0
 INSERT | Microsoft.NET.Test.Sdk                    |             | 17.14.0
 INSERT | NUnit                                     |             | 4.3.2
 INSERT | NUnit3TestAdapter                         |             | 5.0.0
 INSERT | NUnit.Analyzers                           |             | 4.7.0
 INSERT | Spectre.Console                           |             | 0.51.1
 INSERT | Swashbuckle.AspNetCore                    |             | 7.0.0
 INSERT | System.Numerics.Tensors                   |             | 10.0.2
 UPDATE | MongoDB.Driver                            | 3.2.0       | 3.5.0
(15 rows)

                  package                  | version  |       pinned_at
-------------------------------------------+----------+------------------------
 coverlet.collector                        | 6.0.4    | 2026-09-14 00:00:00+00
 JetBrains.Annotations                     | 2024.3.0 | 2026-09-14 00:00:00+00
 Microsoft.Extensions.DependencyInjection  | 10.0.2   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Hosting              | 10.0.5   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Logging              | 10.0.0   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Logging.Abstractions | 10.0.2   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Logging.Console      | 10.0.0   | 2026-09-14 00:00:00+00
 Microsoft.NET.Test.Sdk                    | 17.14.0  | 2026-09-14 00:00:00+00
 MongoDB.Driver                            | 3.5.0    | 2026-09-16 00:00:00+00
 NUnit                                     | 4.3.2    | 2026-09-14 00:00:00+00
 NUnit3TestAdapter                         | 5.0.0    | 2026-09-14 00:00:00+00
 NUnit.Analyzers                           | 4.7.0    | 2026-09-14 00:00:00+00
 Spectre.Console                           | 0.51.1   | 2026-09-14 00:00:00+00
 Swashbuckle.AspNetCore                    | 7.0.0    | 2026-09-14 00:00:00+00
 System.Numerics.Tensors                   | 10.0.2   | 2026-09-14 00:00:00+00
(15 rows)
```

- `(array_agg(version ORDER BY …))[1]` is "the first value in this order" as an aggregate, another way of writing `DISTINCT ON`.
- `merge_action()` returns `INSERT`, `UPDATE` or `DELETE`, like `$action` in T-SQL. `coalesce(new.package, old.package)` is needed because `new` is `NULL` for a deleted row.
- A `MERGE` with `RETURNING` can be used in `WITH`, and the outer query sorts its rows: a statement's `RETURNING` order isn't guaranteed.
- `Npgsql` is deleted: no Guitar Alchemist project references it. `MongoDB.Driver`, 14 references, goes back from 3.2.0 to 3.5.0 with a new date. `Microsoft.Extensions.Hosting`, 12 references, matches with the same version 10.0.5: no `WHEN` clause applies, so its row stays as it was and isn't returned.

The PostgreSQL documentation recommends `INSERT … ON CONFLICT` over `MERGE` when concurrent inserts are possible: `MERGE` can fail with a unique violation where `ON CONFLICT` would update.

The final list is sorted by `package`, and `coverlet.collector` comes before `JetBrains.Annotations`, `NUnit3TestAdapter` before `NUnit.Analyzers`. The `learn` database uses the `en_US.utf8` [collation](https://www.postgresql.org/docs/18/collation.html) of the image's C library, which compares letters before case and punctuation. With the `C` collation, capital letters sort before lower case and `.` before digits. A result sorted on text depends on the database's collation: that's part of what "always `ORDER BY`" doesn't fix on its own.

## On Aurora

*To verify: nothing in this section ran on AWS.* Aurora PostgreSQL runs PostgreSQL's query engine, so every statement of this lesson is the same there, from `WITH RECURSIVE` to `MERGE … RETURNING` (PostgreSQL 17) and `old` and `new` in `RETURNING` (PostgreSQL 18, so Aurora PostgreSQL 18 only). What changes is **where a query runs**.

- An Aurora cluster has a writer instance and up to 15 Aurora Replicas, and several [endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html). The **cluster endpoint** connects to the writer, for `INSERT`, `MERGE` and DDL. The **reader endpoint** is for queries, and AWS writes that Aurora "automatically performs connection-balancing among all the Aurora Replicas": the balancing is per connection, not per query. A pool of connections opened on the reader endpoint stays on the replicas it reached.
- The replicas share the writer's storage volume, and AWS gives their lag as "usually much less than 100 milliseconds" in the [replication page](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html), growing with the write rate. A program that writes through the cluster endpoint and immediately reads through the reader endpoint can miss its own write: read your own writes on the writer.
- Reports such as the windows and `LATERAL` queries above are the kind of work to send to the reader endpoint, or to a custom endpoint for a group of larger replicas.

The replicas are read-only, and a write sent to one fails. In PostgreSQL, a server in recovery, as a standby is, starts every transaction read-only ([`xact.c`, lines 2122-2130](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/access/transam/xact.c#L2122-L2130)); a read-only transaction on the local server gives the same error ([lines 197-201](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L197-L201)):

```sql
-- A read-only transaction refuses writes, as every transaction on a standby does
BEGIN TRANSACTION READ ONLY;
SELECT count(*) AS pinned FROM ga.pinned_versions;
DELETE FROM ga.pinned_versions WHERE package = 'Npgsql';
ROLLBACK;
```

```text
BEGIN
 pinned
--------
     15
(1 row)

ERROR:  cannot execute DELETE in a read-only transaction
ROLLBACK
```

Whether an Aurora Replica reports exactly this message, SQLSTATE `25006`, is *to verify*.

Lesson 4 chooses between the writer and the readers from a connection string, and lesson 12 comes back to endpoints and failover.

## Key takeaways

- `WITH RECURSIVE` has no recursion limit in PostgreSQL: protect it with `UNION` without a depth column, the `CYCLE` clause, or `statement_timeout`.
- `FILTER (WHERE …)` restricts an aggregate, in `GROUP BY` and in windows.
- `LATERAL` is `CROSS APPLY`; `LEFT JOIN LATERAL … ON true` is `OUTER APPLY`.
- `DISTINCT ON` keeps the first row of each group in the `ORDER BY` order.
- Versions stored as text compare as text: `'9.0.4' > '10.0.5'`.
- `RETURNING old.*, new.*` replaces `OUTPUT deleted.*, inserted.*`; `INSERT … ON CONFLICT` is the concurrency-safe upsert, and `MERGE … RETURNING merge_action()` the general one.
- Sorting text depends on the collation; on Aurora, writes go to the cluster endpoint, and reads on replicas can lag.

## Exercises

The solutions are in [`sql/03-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql).

1. Guitar Alchemist gives each iconic chord its pitch classes and a guitar voicing: one fret per string, from low E to high E, `-1` for a string not played. In standard tuning, the open strings are the pitch classes `4 9 2 7 11 4`. Compute the pitch classes each voicing actually plays, and compare them with the declared ones.

<details>
<summary>Solution</summary>

From [`sql/03-exercises.sql`, lines 8-23](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql#L8-L23):

```sql
WITH played AS (
    SELECT c.name, array_agg(DISTINCT (t.open_string + f.fret) % 12 ORDER BY (t.open_string + f.fret) % 12) AS voicing_pcs
    FROM ga.iconic_chords AS c
    CROSS JOIN LATERAL unnest(c.guitar_voicing) WITH ORDINALITY AS f(fret, string)
    JOIN unnest('{4,9,2,7,11,4}'::int[]) WITH ORDINALITY AS t(open_string, string) USING (string)
    WHERE f.fret >= 0
    GROUP BY c.name
)
SELECT p.name,
       ARRAY(SELECT unnest(c.pitch_classes) ORDER BY 1) AS declared,
       p.voicing_pcs AS played,
       ARRAY(SELECT unnest(c.pitch_classes) EXCEPT SELECT unnest(p.voicing_pcs) ORDER BY 1) AS missing,
       ARRAY(SELECT unnest(p.voicing_pcs) EXCEPT SELECT unnest(c.pitch_classes) ORDER BY 1) AS extra
FROM played AS p
JOIN ga.iconic_chords AS c USING (name)
ORDER BY p.name;
```

```text
       name       |   declared   |   played    | missing |  extra
------------------+--------------+-------------+---------+---------
 Blackbird Chord  | {2,7,11}     | {1,2,4,7,9} | {11}    | {1,4,9}
 Cowboy Chord     | {2,7,11}     | {2,7,11}    | {}      | {}
 Hendrix Chord    | {2,4,7,8,11} | {2,4,7,8}   | {11}    | {}
 James Bond Chord | {3,4,7,11}   | {3,4,7,11}  | {}      | {}
 Mu Major Chord   | {0,2,7}      | {0,2,4,7}   | {}      | {4}
 Power Chord      | {2,7}        | {2,7}       | {}      | {}
(6 rows)
```

`unnest(…) WITH ORDINALITY` numbers the elements of an array, which joins each fret with its string. The fret plus the open string, modulo 12, is the pitch class played. `ARRAY(SELECT … EXCEPT SELECT …)` computes a set difference between two arrays.

Only six of the 17 chords have a voicing. Three are consistent. The other three are findings about Guitar Alchemist's data, in [`IconicChords.yaml`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Business.Config/IconicChords.yaml) at commit `32f143c`:

- The Blackbird voicing `{0,0,0,0,2,0}`, declared as G/B, plays the open strings and C♯ on the B string: E, A, D, G, C♯, E. It's missing B, and adds C♯, E and A.
- The Hendrix chord, E7♯9, declares B, its fifth, and the voicing `{0,7,6,7,8,0}` doesn't play it. Guitarists often leave the fifth out of that chord; the declared set and the voicing just disagree.
- The Mu Major voicing `{0,3,0,0,3,0}`, declared as `Cadd9(no3)`, plays the open E strings: E, the third that `no3` says is left out.

</details>

2. List every project that depends on `GA.Data.MongoDB`, directly or not, with its smallest distance. The project's path is `GA.Data.MongoDB/GA.Data.MongoDB.csproj`.

<details>
<summary>Solution</summary>

From [`sql/03-exercises.sql`, lines 26-38](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql#L26-L38):

```sql
WITH RECURSIVE dependents AS (
    SELECT from_path, 1 AS depth
    FROM ga.project_refs
    WHERE to_path = 'GA.Data.MongoDB/GA.Data.MongoDB.csproj'
    UNION
    SELECT r.from_path, d.depth + 1
    FROM dependents AS d
    JOIN ga.project_refs AS r ON r.to_path = d.from_path
)
SELECT min(depth) AS depth, from_path AS project
FROM dependents
GROUP BY from_path
ORDER BY depth, project;
```

```text
 depth |                                      project
-------+-----------------------------------------------------------------------------------
     1 | Apps/GaChatbotCli/GaChatbotCli.csproj
     1 | Apps/GaChatbot/GaChatbot.csproj
     1 | Apps/ga-server/GA.BSP.Service/GA.BSP.Service.csproj
     1 | Apps/ga-server/GA.DocumentProcessing.Service/GA.DocumentProcessing.Service.csproj
     1 | Common/GA.Business.AI/GA.Business.AI.csproj
     1 | Common/GA.Business.ML/GA.Business.ML.csproj
     1 | GaCLI/GaCLI.csproj
     2 | Apps/GaChatbot.Api/GaChatbot.Api.csproj
     2 | Apps/GaMemoryCli/GaMemoryCli.csproj
     2 | Apps/GaQaMcp/GaQaMcp.csproj
     2 | Apps/ga-server/GaApi/GaApi.csproj
     2 | Common/GA.Business.Core.Orchestration/GA.Business.Core.Orchestration.csproj
     2 | Common/GA.Business.Intelligence/GA.Business.Intelligence.csproj
     2 | Common/GA.Testing.Semantic/GA.Testing.Semantic.csproj
     2 | Demos/IntelligentAnalysis/IntelligentAnalysisDemo.csproj
     2 | Demos/Music Theory/FretboardVoicingsCLI/FretboardVoicingsCLI.csproj
     2 | GaMcpServer/GaMcpServer.csproj
     2 | GenerateNatData/GenerateNatData.csproj
     2 | Tests/Apps/GaChatbot.Tests/GaChatbot.Tests.csproj
     2 | Tests/Common/GA.Business.Core.Tests/GA.Business.Core.Tests.csproj
     2 | Tests/Common/GA.Business.ML.Tests/GA.Business.ML.Tests.csproj
     2 | Tools/GaStructureInvariance/GaStructureInvariance.csproj
     3 | AllProjects.AppHost/AllProjects.AppHost.csproj
     3 | Apps/ga-server/GA.Analytics.Service/GA.Analytics.Service.csproj
     3 | Apps/InteractiveTutorial/InteractiveTutorial.csproj
     3 | Demos/Performance/VectorSearchBenchmark/VectorSearchBenchmark.csproj
     3 | Tests/Apps/GaApi.Tests/GaApi.Tests.csproj
     3 | Tests/Apps/GaChatbot.Api.Tests/GaChatbot.Api.Tests.csproj
     3 | Tests/Apps/GaMcpServer.Tests/GaMcpServer.Tests.csproj
     3 | Tests/GaApi.Tests/GaApi.Tests.csproj
(30 rows)
```

The recursion goes the other way: from `to_path` to `from_path`. `UNION` stops it on the rows already found, and `min(depth)` keeps the shortest distance of a project reached through several paths. 30 projects depend on the MongoDB layer, a quarter of the solution. Two of them are named `GaApi.Tests.csproj`, one in `Tests/Apps/GaApi.Tests` and one in `Tests/GaApi.Tests`: grouping on the file name instead of the path would have merged them.

</details>

3. For each failed run, how long did the same workflow take to succeed again? Keep the failures that were never followed by a success in the snapshot, first.

<details>
<summary>Solution</summary>

From [`sql/03-exercises.sql`, lines 41-51](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql#L41-L51):

```sql
SELECT f.workflow_name, f.started_at AS failed_at, next_success.started_at - f.started_at AS time_to_green
FROM ci.runs AS f
LEFT JOIN LATERAL (
    SELECT s.started_at
    FROM ci.runs AS s
    WHERE s.workflow_name = f.workflow_name AND s.conclusion = 'success' AND s.started_at > f.started_at
    ORDER BY s.started_at
    LIMIT 1
) AS next_success ON true
WHERE f.conclusion = 'failure'
ORDER BY time_to_green DESC NULLS FIRST, f.workflow_name, f.started_at;
```

```text
            workflow_name            |       failed_at        | time_to_green
-------------------------------------+------------------------+---------------
 GHA 04: data between steps and jobs | 2026-09-14 12:47:40+00 |
 GHA 04: exercise checks             | 2026-09-14 13:05:23+00 |
 GHA 05: exercise checks             | 2026-09-14 13:12:27+00 |
 GHA 05: exercise checks             | 2026-09-14 13:16:06+00 |
 GHA 05: exercise checks             | 2026-09-14 13:18:20+00 |
 GHA 06: exercise checks             | 2026-09-14 13:24:13+00 |
 GHA 10: exercise checks             | 2026-09-14 13:53:12+00 |
 Rust course examples                | 2026-09-13 19:09:08+00 | 00:03:48
 Deploy to GitHub Pages              | 2026-09-14 13:36:16+00 | 00:03:46
 Rust course examples                | 2026-09-13 17:40:34+00 | 00:02:15
 GHA 09: exercise checks             | 2026-09-14 13:46:43+00 | 00:02:13
 GHA 03: triggers                    | 2026-09-14 12:45:24+00 | 00:02:05
 GHA 03: triggers                    | 2026-09-14 12:45:38+00 | 00:01:51
 GHA 10: custom actions              | 2026-09-14 13:53:04+00 | 00:01:03
 Deploy to GitHub Pages              | 2026-09-14 12:45:39+00 | 00:00:59
 Rust course examples                | 2026-09-13 17:41:56+00 | 00:00:53
(16 rows)
```

`LEFT JOIN LATERAL (…) ON true` keeps the failed runs for which the subquery finds no later success, with `NULL` columns: `OUTER APPLY`. `NULLS FIRST` puts them at the top of a descending sort, where PostgreSQL would put them anyway: `NULL` sorts as larger than any value, the opposite of SQL Server. Seven failures had no success afterwards in the snapshot, six of them in exercise-check workflows.

</details>

## Sources

- PostgreSQL 18 documentation: [`WITH` queries](https://www.postgresql.org/docs/18/queries-with.html), [aggregate expressions and `FILTER`](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-AGGREGATES), [window functions](https://www.postgresql.org/docs/18/tutorial-window.html) and [their reference](https://www.postgresql.org/docs/18/functions-window.html), [`LATERAL`](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-LATERAL), [`SELECT`](https://www.postgresql.org/docs/18/sql-select.html), [returning data from modified rows](https://www.postgresql.org/docs/18/dml-returning.html), [`INSERT`](https://www.postgresql.org/docs/18/sql-insert.html), [`MERGE`](https://www.postgresql.org/docs/18/sql-merge.html), [collation support](https://www.postgresql.org/docs/18/collation.html), [`statement_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-STATEMENT-TIMEOUT)
- PostgreSQL source at `REL_18_6`: [`xact.c`, lines 2122-2130](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/access/transam/xact.c#L2122-L2130)
- SQL Server: [`WITH` common table expression](https://learn.microsoft.com/sql/t-sql/queries/with-common-table-expression-transact-sql), [`FROM` and `APPLY`](https://learn.microsoft.com/sql/t-sql/queries/from-transact-sql), [`OUTPUT`](https://learn.microsoft.com/sql/t-sql/queries/output-clause-transact-sql), [`MERGE`](https://learn.microsoft.com/sql/t-sql/statements/merge-transact-sql)
- Amazon Aurora: [endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html), [replication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html)
- Guitar Alchemist at commit `32f143c`: [`IconicChords.yaml`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Business.Config/IconicChords.yaml)
