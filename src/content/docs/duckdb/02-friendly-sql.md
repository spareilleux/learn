---
title: 2. Friendly SQL
description: Intervals and time zones, window functions with QUALIFY, PIVOT, and the shortcuts DuckDB adds to SQL — on the run history of this site.
sidebar:
  order: 2
---

Every query of this lesson is in [`sql/02-friendly-sql.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/02-friendly-sql.sql), run from `code/duckdb` like in [lesson 1](../01-first-queries/). The script starts by loading the runs into a table:

```sql
CREATE TABLE runs AS FROM 'data/runs.json';
```

## Durations: timestamps and intervals

Subtracting two `TIMESTAMP` values gives an [`INTERVAL`](https://duckdb.org/docs/current/sql/functions/interval), which `avg` and `max` accept:

```sql
SELECT workflowName, count(*) AS runs, avg(updatedAt - startedAt) AS avg_took, max(updatedAt - startedAt) AS max_took
FROM runs
GROUP BY ALL
HAVING runs >= 4
ORDER BY avg_took DESC;
```

```text
┌────────────────────────┬───────┬─────────────────┬──────────┐
│      workflowName      │ runs  │    avg_took     │ max_took │
│        varchar         │ int64 │    interval     │ interval │
├────────────────────────┼───────┼─────────────────┼──────────┤
│ Java course examples   │     7 │ 00:03:18.857148 │ 00:04:48 │
│ Rust course examples   │    18 │ 00:01:32.888904 │ 00:02:33 │
│ Deploy to GitHub Pages │    65 │ 00:00:47.230784 │ 00:02:29 │
│ GHA 03: triggers       │     5 │ 00:00:33.4      │ 00:01:25 │
│ GHA 07: security       │     4 │ 00:00:10.25     │ 00:00:11 │
└────────────────────────┴───────┴─────────────────┴──────────┘
```

`HAVING runs >= 4` uses the alias of the `SELECT`: DuckDB allows it in `WHERE`, `GROUP BY` and `HAVING`, where SQL Server makes you repeat `count(*)`. The Java examples take the longest, as the [Java course](../../java-for-csharp/) compiles and runs every lesson's code on three operating systems.

Two things the data doesn't tell you directly:

- `updatedAt` is the last time the run changed, and `startedAt` is the start of the **latest attempt**. The run of `GHA 09: debugging` that was re-run twice was created at 13:40:10 and started at 13:44:02: its duration only counts the third attempt. Lesson 3 uses the job timestamps instead.
- `sum` doesn't accept intervals, although `avg` does:

```text
Binder Error: No function matches the given name and argument types 'sum(INTERVAL)'. You might need to add explicit type casts.
	Candidate functions:
	sum(DECIMAL) -> DECIMAL
```

Convert to seconds first with `epoch(interval)` or `date_diff('second', startedAt, updatedAt)`, and back with `to_seconds(…)` if you want an interval again: `to_seconds(sum(epoch(updatedAt - startedAt)))` gives `00:51:10` for the 65 deployments of this site.

### Truncating: runs per hour

```sql
SELECT date_trunc('hour', createdAt) AS hour, count(*) AS runs
FROM runs
GROUP BY ALL
ORDER BY hour
LIMIT 5;
```

```text
┌─────────────────────┬───────┐
│        hour         │ runs  │
│      timestamp      │ int64 │
├─────────────────────┼───────┤
│ 2026-09-13 15:00:00 │     1 │
│ 2026-09-13 16:00:00 │    10 │
│ 2026-09-13 17:00:00 │    16 │
│ 2026-09-13 18:00:00 │     7 │
│ 2026-09-13 19:00:00 │     9 │
└─────────────────────┴───────┘
```

[`date_trunc`](https://duckdb.org/docs/current/sql/functions/timestamp) is `DATETRUNC` in SQL Server 2022. A cast to `DATE` (`createdAt::DATE`) truncates to the day; `hour(…)`, `dayofweek(…)` and the other [date parts](https://duckdb.org/docs/current/sql/functions/datepart) extract a number.

## Time zones

GitHub writes `2026-09-13T15:53:16Z`: UTC. DuckDB read it as a [`TIMESTAMP`](https://duckdb.org/docs/current/sql/data_types/timestamp), a date and time with no zone, like `datetime2` in SQL Server. `TIMESTAMP WITH TIME ZONE` (`TIMESTAMPTZ`) is an instant, like `DateTimeOffset` in C# or `Instant` in Java, **displayed in the session's time zone**. `AT TIME ZONE 'UTC'` says what zone a `TIMESTAMP` was in, and turns it into a `TIMESTAMPTZ`:

```sql
SET TimeZone = 'Europe/Paris';
SELECT createdAt, createdAt AT TIME ZONE 'UTC' AS created_utc, hour(createdAt AT TIME ZONE 'UTC') AS hour_in_paris
FROM runs
ORDER BY createdAt
LIMIT 1;
```

```text
┌─────────────────────┬──────────────────────────┬───────────────┐
│      createdAt      │       created_utc        │ hour_in_paris │
│      timestamp      │ timestamp with time zone │     int64     │
├─────────────────────┼──────────────────────────┼───────────────┤
│ 2026-09-13 15:53:16 │ 2026-09-13 17:53:16+02   │            17 │
└─────────────────────┴──────────────────────────┴───────────────┘
```

Without the `SET`, the CLI uses the operating system's time zone. That's why the script sets it: GitHub runners are in UTC, and the expected output would not match anywhere else. Any output that shows a `TIMESTAMPTZ` depends on a setting, not only on the data. Time zone support comes from the [ICU extension](https://duckdb.org/docs/current/core_extensions/icu), built into the CLI.

## Window functions

[Window functions](https://duckdb.org/docs/current/sql/functions/window_functions) work as in SQL Server and PostgreSQL. The `WINDOW` clause names a window once, for several functions:

```sql
SELECT createdAt, conclusion,
       lag(conclusion) OVER w AS previous,
       createdAt - lag(createdAt) OVER w AS since_previous
FROM runs
WHERE workflowName = 'Rust course examples'
WINDOW w AS (PARTITION BY workflowName ORDER BY createdAt)
ORDER BY createdAt
LIMIT 9;
```

```text
┌─────────────────────┬────────────┬──────────┬────────────────┐
│      createdAt      │ conclusion │ previous │ since_previous │
│      timestamp      │  varchar   │ varchar  │    interval    │
├─────────────────────┼────────────┼──────────┼────────────────┤
│ 2026-09-13 16:20:06 │ success    │ NULL     │ NULL           │
│ 2026-09-13 16:21:09 │ success    │ success  │ 00:01:03       │
│ 2026-09-13 16:45:55 │ success    │ success  │ 00:24:46       │
│ 2026-09-13 17:13:25 │ success    │ success  │ 00:27:30       │
│ 2026-09-13 17:40:34 │ failure    │ success  │ 00:27:09       │
│ 2026-09-13 17:41:56 │ failure    │ failure  │ 00:01:22       │
│ 2026-09-13 17:42:49 │ success    │ failure  │ 00:00:53       │
│ 2026-09-13 19:09:08 │ failure    │ success  │ 01:26:19       │
│ 2026-09-13 19:12:56 │ success    │ failure  │ 00:03:48       │
└─────────────────────┴────────────┴──────────┴────────────────┘
```

The story of the Rust course's CI is readable in the gaps: a failure at 17:40, a second one 82 seconds later, fixed 53 seconds after that. Lesson 3 finds out which step failed.

## `QUALIFY`: filtering on a window function

Which workflows are red right now, that is, whose **last** run didn't succeed? In SQL Server, a window function can't appear in `WHERE`, so this takes a subquery or a CTE. [`QUALIFY`](https://duckdb.org/docs/current/sql/query_syntax/qualify) is a `WHERE` evaluated after the window functions:

```sql
SELECT workflowName, conclusion, createdAt
FROM runs
QUALIFY row_number() OVER (PARTITION BY workflowName ORDER BY createdAt DESC) = 1
    AND conclusion <> 'success'
ORDER BY workflowName;
```

```text
┌─────────────────────────────────────┬─────────────────┬─────────────────────┐
│            workflowName             │   conclusion    │      createdAt      │
│               varchar               │     varchar     │      timestamp      │
├─────────────────────────────────────┼─────────────────┼─────────────────────┤
│ GHA 04: data between steps and jobs │ failure         │ 2026-09-14 12:47:40 │
│ GHA 04: exercise checks             │ failure         │ 2026-09-14 13:05:23 │
│ GHA 05: exercise checks             │ failure         │ 2026-09-14 13:18:20 │
│ GHA 06: exercise checks             │ failure         │ 2026-09-14 13:24:13 │
│ GHA 06: undeclared input            │ startup_failure │ 2026-09-14 13:24:30 │
│ GHA 09: debugging                   │ cancelled       │ 2026-09-14 13:40:10 │
│ GHA 10: exercise checks             │ failure         │ 2026-09-14 13:53:12 │
└─────────────────────────────────────┴─────────────────┴─────────────────────┘
```

The two conditions can't move to `WHERE`: `conclusion <> 'success'` in `WHERE` would remove the green runs **before** numbering, and every workflow with at least one failure would show up. All seven are exercises of the GitHub Actions course, red on purpose.

## `PIVOT`

[`PIVOT`](https://duckdb.org/docs/current/sql/statements/pivot) turns the values of a column into columns. Unlike [SQL Server's `PIVOT`](https://learn.microsoft.com/sql/t-sql/queries/from-using-pivot-and-unpivot), it doesn't need the list of values:

```sql
PIVOT (FROM runs WHERE workflowName IN ('Deploy to GitHub Pages', 'Rust course examples', 'Java course examples', 'GHA 03: triggers'))
ON conclusion
USING count(*)
GROUP BY workflowName
ORDER BY workflowName;
```

```text
┌────────────────────────┬───────────┬─────────┬─────────┐
│      workflowName      │ cancelled │ failure │ success │
│        varchar         │   int64   │  int64  │  int64  │
├────────────────────────┼───────────┼─────────┼─────────┤
│ Deploy to GitHub Pages │         0 │       2 │      63 │
│ GHA 03: triggers       │         2 │       2 │       1 │
│ Java course examples   │         0 │       0 │       7 │
│ Rust course examples   │         0 │       3 │      15 │
└────────────────────────┴───────────┴─────────┴─────────┘
```

- The columns are the values found in the data, so they change with the data: `startup_failure` exists in `runs`, but none of these four workflows had one, and the column isn't there. Code that reads a pivot by column name must expect that.
- Without `ORDER BY`, the order of the rows isn't defined. A first try of `PIVOT runs ON event USING count(*) GROUP BY conclusion` returned `success`, `cancelled`, `startup_failure`, `failure`, in no useful order. The course scripts always end with `ORDER BY`, or their output couldn't be compared.

## Shortcuts for columns

```sql
SELECT headSha[1:7] AS sha, min(COLUMNS('.*At'))
FROM runs
GROUP BY ALL
ORDER BY ALL
LIMIT 3;
```

```text
┌─────────┬─────────────────────┬─────────────────────┬─────────────────────┐
│   sha   │      createdAt      │      startedAt      │      updatedAt      │
│ varchar │      timestamp      │      timestamp      │      timestamp      │
├─────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ 04c8770 │ 2026-09-13 17:52:33 │ 2026-09-13 17:52:33 │ 2026-09-13 17:53:19 │
│ 1adf60f │ 2026-09-13 16:50:10 │ 2026-09-13 16:50:10 │ 2026-09-13 16:50:43 │
│ 1de721b │ 2026-09-14 12:46:38 │ 2026-09-14 12:46:38 │ 2026-09-14 12:47:29 │
└─────────┴─────────────────────┴─────────────────────┴─────────────────────┘
```

- `headSha[1:7]` slices a string, both ends included, counting from 1: the short commit hash.
- [`COLUMNS('.*At')`](https://duckdb.org/docs/current/sql/expressions/star) expands to every column whose name matches the regular expression, and `min(COLUMNS(…))` applies `min` to each: one aggregate written, three computed.
- `ORDER BY ALL` sorts by every column, left to right.
- `SELECT * EXCLUDE (headSha, status)` selects everything but some columns, and `SELECT * REPLACE (headSha[1:7] AS headSha)` changes one while keeping its place.

## Key takeaways

- Timestamps subtract into intervals; `avg` and `max` take intervals, `sum` doesn't: go through `epoch`.
- A `TIMESTAMP` has no zone; a `TIMESTAMPTZ` is displayed in the session's zone, so fix `TimeZone` in anything you compare.
- `QUALIFY` filters on window functions without a subquery.
- `PIVOT` finds its columns in the data; order the rows yourself.
- `GROUP BY ALL`, `ORDER BY ALL`, `COLUMNS`, `EXCLUDE` and aliases in `HAVING` remove repetition.

## Exercises

The solutions are in [`sql/02-exercises.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/02-exercises.sql), checked by CI.

1. For each UTC day, how many runs, and what percentage didn't succeed, to one decimal?

<details>
<summary>Solution</summary>

```sql
SELECT createdAt::DATE AS day, count(*) AS runs,
       round(100 * count(*) FILTER (conclusion <> 'success') / count(*), 1) AS not_green_pct
FROM runs
GROUP BY ALL
ORDER BY day;
```

```text
┌────────────┬───────┬───────────────┐
│    day     │ runs  │ not_green_pct │
│    date    │ int64 │    double     │
├────────────┼───────┼───────────────┤
│ 2026-09-13 │    43 │           7.0 │
│ 2026-09-14 │    82 │          22.0 │
└────────────┴───────┴───────────────┘
```

The second day is the one of the GitHub Actions course and its failing exercises. Note `100 * … / count(*)`: in DuckDB, `/` between two integers returns a `DOUBLE` (`7 / 2` is `3.5`), and `//` is the integer division. In SQL Server and in C#, the same expression would have truncated to `6` and `21`.

</details>

2. For each failed run, how long did its workflow stay red, that is, until the next successful run of the same workflow? List the failures that were never fixed first.

<details>
<summary>Solution</summary>

```sql
SELECT workflowName, createdAt AS failed_at,
       min(createdAt) FILTER (conclusion = 'success') OVER (
           PARTITION BY workflowName ORDER BY createdAt
           ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) - createdAt AS red_for
FROM runs
QUALIFY conclusion = 'failure'
ORDER BY red_for DESC NULLS FIRST, workflowName, failed_at;
```

```text
┌─────────────────────────────────────┬─────────────────────┬──────────┐
│            workflowName             │      failed_at      │ red_for  │
│               varchar               │      timestamp      │ interval │
├─────────────────────────────────────┼─────────────────────┼──────────┤
│ GHA 04: data between steps and jobs │ 2026-09-14 12:47:40 │ NULL     │
│ GHA 04: exercise checks             │ 2026-09-14 13:05:23 │ NULL     │
│ GHA 05: exercise checks             │ 2026-09-14 13:12:27 │ NULL     │
│ GHA 05: exercise checks             │ 2026-09-14 13:16:06 │ NULL     │
│ GHA 05: exercise checks             │ 2026-09-14 13:18:20 │ NULL     │
│ GHA 06: exercise checks             │ 2026-09-14 13:24:13 │ NULL     │
│ GHA 10: exercise checks             │ 2026-09-14 13:53:12 │ NULL     │
│ Rust course examples                │ 2026-09-13 19:09:08 │ 00:03:48 │
│ Deploy to GitHub Pages              │ 2026-09-14 13:36:16 │ 00:03:46 │
│ Rust course examples                │ 2026-09-13 17:40:34 │ 00:02:15 │
│ GHA 09: exercise checks             │ 2026-09-14 13:46:43 │ 00:02:13 │
│ GHA 03: triggers                    │ 2026-09-14 12:45:24 │ 00:02:05 │
│ GHA 03: triggers                    │ 2026-09-14 12:45:38 │ 00:01:51 │
│ GHA 10: custom actions              │ 2026-09-14 13:53:04 │ 00:01:03 │
│ Deploy to GitHub Pages              │ 2026-09-14 12:45:39 │ 00:00:59 │
│ Rust course examples                │ 2026-09-13 17:41:56 │ 00:00:53 │
└─────────────────────────────────────┴─────────────────────┴──────────┘
```

- The window frame starts at `1 FOLLOWING`, the run after the failure; `FILTER` inside a window aggregate keeps only the successes. `min(createdAt)` is then the next green run.
- The filter on failures has to be in `QUALIFY`: in `WHERE`, it would remove the successes before the window looks for them, and every `red_for` would be `NULL`.
- `NULLS FIRST` puts the never-fixed failures on top; DuckDB sorts `NULL` last by default, in both directions.

</details>

3. Rewrite the `QUALIFY` query of this lesson, the workflows whose last run isn't green, without any window function.

<details>
<summary>Solution</summary>

```sql
SELECT workflowName, arg_max(conclusion, createdAt) AS last_conclusion
FROM runs
GROUP BY ALL
HAVING last_conclusion <> 'success'
ORDER BY workflowName;
```

```text
┌─────────────────────────────────────┬─────────────────┐
│            workflowName             │ last_conclusion │
│               varchar               │     varchar     │
├─────────────────────────────────────┼─────────────────┤
│ GHA 04: data between steps and jobs │ failure         │
│ GHA 04: exercise checks             │ failure         │
│ GHA 05: exercise checks             │ failure         │
│ GHA 06: exercise checks             │ failure         │
│ GHA 06: undeclared input            │ startup_failure │
│ GHA 09: debugging                   │ cancelled       │
│ GHA 10: exercise checks             │ failure         │
└─────────────────────────────────────┴─────────────────┘
```

[`arg_max(value, key)`](https://duckdb.org/docs/current/sql/functions/aggregates) returns `value` from the row where `key` is largest: the conclusion of the most recent run. The same seven workflows. `QUALIFY` is the general tool, since it can return whole rows or the top 3; `arg_max` is shorter when one value per group is enough.

</details>

## Sources

- [Interval functions](https://duckdb.org/docs/current/sql/functions/interval), [timestamp functions](https://duckdb.org/docs/current/sql/functions/timestamp) and [date parts](https://duckdb.org/docs/current/sql/functions/datepart)
- [Timestamp types](https://duckdb.org/docs/current/sql/data_types/timestamp) and [time zones](https://duckdb.org/docs/current/sql/data_types/timezones)
- [Window functions](https://duckdb.org/docs/current/sql/functions/window_functions), [`WINDOW`](https://duckdb.org/docs/current/sql/query_syntax/window) and [`QUALIFY`](https://duckdb.org/docs/current/sql/query_syntax/qualify)
- [`PIVOT`](https://duckdb.org/docs/current/sql/statements/pivot)
- [Star expressions: `COLUMNS`, `EXCLUDE`, `REPLACE`](https://duckdb.org/docs/current/sql/expressions/star)
- [`ORDER BY`](https://duckdb.org/docs/current/sql/query_syntax/orderby) and [aggregate functions](https://duckdb.org/docs/current/sql/functions/aggregates)
