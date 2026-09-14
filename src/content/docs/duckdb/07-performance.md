---
title: 7. Performance
description: Reading a DuckDB query plan, projection and filter pushdown, Parquet row groups and why sorting matters, partition pruning, threads, the bytes a remote Parquet query downloads, memory limits and spilling to disk, and when DuckDB is the wrong tool.
sidebar:
  order: 7
---

In SQL Server, you read an [execution plan](https://learn.microsoft.com/sql/relational-databases/performance/execution-plans) to see why a query is slow, and a [columnstore index](https://learn.microsoft.com/sql/relational-databases/indexes/columnstore-indexes-overview) is what makes analytical scans fast. DuckDB stores everything in columns, and has plans too. This lesson reads them, then measures what they predict.

Two scripts:

- [`sql/07-performance.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/07-performance.sql) shows plans and Parquet metadata. Its output doesn't depend on the machine, so the CI compares it like the other lessons.
- [`timings/07-performance.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/timings/07-performance.sql) runs the same ideas on a bigger table with `.timer on`. The CI runs it on the three operating systems without comparing anything; the timings below come from its logs and from my machine, a 24-thread Windows 11 PC.

```bash
duckdb < timings/07-performance.sql
```

It writes about 1.5 GB into `out/`: a 1 GB CSV file and several Parquet files. Delete them afterwards.

## A bigger table

315 jobs are not enough to measure anything. The script repeats every step of every job, shifting the timestamps by one day per copy:

```sql
CREATE TABLE steps AS
SELECT j.id AS job_id, j.labels[1] AS os, s.number, s.name, s.conclusion,
       s.started_at + to_days(d.i) AS started_at, s.completed_at + to_days(d.i) AS completed_at
FROM jobs j, unnest(j.steps) AS t(s), range(500) AS d(i);
SELECT count(*) AS steps, min(started_at) AS first_step, max(started_at) AS last_step FROM steps;
```

```text
┌─────────┬─────────────────────┬─────────────────────┐
│  steps  │     first_step      │      last_step      │
│  int64  │      timestamp      │      timestamp      │
├─────────┼─────────────────────┼─────────────────────┤
│ 1102000 │ 2026-09-13 15:53:20 │ 2028-01-26 14:03:35 │
└─────────┴─────────────────────┴─────────────────────┘
```

`range(500)` is a table function that returns the numbers 0 to 499; the comma joins it to every step. The timings script uses `range(5000)`: 11,020,000 steps, created in 1.1 s on my machine and between 2.0 s (Ubuntu runner) and 4.0 s (Windows runner) in the CI.

## Reading a plan

[`EXPLAIN`](https://duckdb.org/docs/current/guides/meta/explain) shows the physical plan without running the query. Here, a query on the JSON file:

```sql
EXPLAIN SELECT conclusion, count(*) FROM 'data/jobs.json' GROUP BY ALL;
```

```text
┌─────────────────────────────┐
│┌───────────────────────────┐│
││       Physical Plan       ││
│└───────────────────────────┘│
└─────────────────────────────┘
┌───────────────────────────┐
│       HASH_GROUP_BY       │
│    ────────────────────   │
│         Groups: #0        │
│                           │
│        Aggregates:        │
│        count_star()       │
│                           │
│         ~199 rows         │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│         PROJECTION        │
│    ────────────────────   │
│         conclusion        │
│                           │
│         ~315 rows         │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│       READ_JSON_AUTO      │
│    ────────────────────   │
│         Function:         │
│       READ_JSON_AUTO      │
│                           │
│        Projections:       │
│         conclusion        │
│                           │
│         ~315 rows         │
└───────────────────────────┘
```

Read it from the bottom up, like a SQL Server plan read from right to left: the scan produces rows for the operator above it. The numbers with `~` are the optimizer's estimates; `#0` is the first column of the operator below. The estimate for the groups, 199, is far from the real four conclusions: it doesn't matter much here, but when a join is slow, a wrong estimate is the first thing to look for.

The line to notice is `Projections: conclusion`. The jobs have 11 fields, including the `steps` array; the reader only builds the one column the query uses. That is **projection pushdown**. With JSON, the reader still has to parse the whole text to find that field. With Parquet, it doesn't even read the other columns.

`EXPLAIN ANALYZE` runs the query and adds the real row counts and the time spent in each operator. The [profiling documentation](https://duckdb.org/docs/current/dev/profiling) lists the other outputs, such as JSON.

## Filter pushdown and row groups

The script writes the steps twice: `out/steps.parquet` in insertion order, `out/steps-sorted.parquet` sorted by start time.

```sql
COPY steps TO 'out/steps.parquet';
COPY (FROM steps ORDER BY started_at) TO 'out/steps-sorted.parquet';

EXPLAIN
SELECT name, avg(completed_at - started_at) AS took
FROM 'out/steps.parquet'
WHERE started_at < '2026-09-20'
GROUP BY ALL;
```

```text
┌─────────────┴─────────────┐
│        PARQUET_SCAN       │
│    ────────────────────   │
│         Function:         │
│        PARQUET_SCAN       │
│                           │
│        Projections:       │
│         started_at        │
│            name           │
│        completed_at       │
│                           │
│          Filters:         │
│ started_at<'2026-09-20 00 │
│     :00:00'::TIMESTAMP    │
│                           │
│       ~220,400 rows       │
└───────────────────────────┘
```

Three columns out of seven, and a `Filters:` section: the `WHERE` clause moved into the scan. That is **filter pushdown**, and on Parquet it does more than save a filter operator.

A [Parquet file](https://parquet.apache.org/docs/file-format/) is cut into **row groups**; DuckDB writes one every 122,880 rows. For each column of each row group, the footer of the file stores the minimum and the maximum value. Before reading a row group, the scan compares the filter with those statistics, and skips the row group if no row can match. [`parquet_metadata`](https://duckdb.org/docs/current/data/parquet/metadata) shows them:

```sql
SELECT replace(file_name, '\', '/') AS file, count(*) AS row_groups, sum(row_group_num_rows) AS rows,
       count(*) FILTER (stats_min::TIMESTAMP < '2026-09-20') AS row_groups_to_read
FROM parquet_metadata(['out/steps.parquet', 'out/steps-sorted.parquet'])
WHERE path_in_schema = 'started_at'
GROUP BY ALL
ORDER BY file;
```

```text
┌──────────────────────────┬────────────┬─────────┬────────────────────┐
│           file           │ row_groups │  rows   │ row_groups_to_read │
│         varchar          │   int64    │ int128  │       int64        │
├──────────────────────────┼────────────┼─────────┼────────────────────┤
│ out/steps-sorted.parquet │          9 │ 1102000 │                  1 │
│ out/steps.parquet        │          9 │ 1102000 │                  9 │
└──────────────────────────┴────────────┴─────────┴────────────────────┘
```

Same rows, same answer (13,895 steps for both files), but not the same work. In insertion order, every row group mixes steps from the whole period, so every minimum falls in the first week and no row group can be skipped. Sorted, only the first row group starts before 2026-09-20.

The plan is the same for both files: `EXPLAIN` shows that the filter reaches the scan, not how many row groups it will skip. The timings show it. One thread, one day in 2030, on the 11-million-row files:

| One day, one thread | My machine | Ubuntu runner | Windows runner | macOS runner |
|---|---|---|---|---|
| unsorted Parquet | 0.052 s | 0.061 s | 0.098 s | 0.059 s |
| sorted Parquet | 0.003 s | 0.003 s | 0.007 s | 0.007 s |

`EXPLAIN ANALYZE` on the sorted file confirms that the scan produced only the matching rows, from one file:

```text
┌─────────────┴─────────────┐
│         TABLE_SCAN        │
│    ────────────────────   │
│         Function:         │
│        PARQUET_SCAN       │
│                           │
│     Projections: name     │
│                           │
│          Filters:         │
│ started_at>='2030-01-01 00│
│   :00:00'::TIMESTAMP AND  │
│   started_at<='2030-01-02 │
│    00:00:00'::TIMESTAMP   │
│                           │
│    Total Files Read: 1    │
│                           │
│        Filename(s):       │
│    out/steps-big-sorted   │
│          .parquet         │
│                           │
│                           │
│                           │
│         2,204 rows        │
│           0.01s           │
└───────────────────────────┘
```

DuckDB's own tables work the same way: the [indexing guide](https://duckdb.org/docs/current/guides/performance/indexing) calls these per-row-group statistics *zonemaps*, and says that "the more ordered the data within a column, the more valuable the zonemap indexes will be". If a column is filtered often, sort by it when you write the file. Sorting also compresses better: the sorted 11-million-row file was 106 MB against 119 MB on my machine.

:::note[File sizes change between runs]
The Parquet writer uses several threads, and the sizes changed by a few hundred kilobytes between two runs on the same machine, and by a few megabytes between machines: the sorted file was 102 MB on the three runners. That's why the compared script shows row counts and statistics, never compressed sizes.
:::

## Partition pruning

Lesson 4 said that a filter on a partition column skips whole files. `EXPLAIN` shows it without running anything:

```sql
EXPLAIN SELECT count(*) FROM read_parquet('out/jobs-by-os/*/*.parquet') WHERE os = 'windows-latest';
```

```text
┌─────────────┴─────────────┐
│        READ_PARQUET       │
│    ────────────────────   │
│         Function:         │
│        READ_PARQUET       │
│                           │
│       File Filters:       │
│  (os = 'windows-latest')  │
│                           │
│    Scanning Files: 1/3    │
│                           │
│          ~34 rows         │
└───────────────────────────┘
```

`File Filters` are decided from the folder names alone: the other two files aren't opened. [Hive partitioning](https://duckdb.org/docs/current/data/partitioning/hive_partitioning) is to files what row group statistics are to rows.

## Table, Parquet or CSV

The same aggregate, the slowest step on average, on the 11 million steps stored three ways, with every thread:

```sql
SELECT os, name, avg(completed_at - started_at) AS took FROM steps GROUP BY ALL ORDER BY took DESC LIMIT 1;
```

| Source | My machine (24 threads) | Ubuntu (4) | Windows (4) | macOS (3) |
|---|---|---|---|---|
| `steps` table in memory | 0.042 s | 0.263 s | 0.420 s | 0.289 s |
| `out/steps-big.parquet`, 119 MB | 0.048 s | 0.237 s | 0.553 s | 0.415 s |
| `out/steps-big.csv`, 1.09 GB | 0.416 s | 1.676 s | 2.709 s | 2.403 s |
| filter on one week, Parquet | 0.009 s | 0.025 s | 0.034 s | 0.026 s |
| filter on one week, CSV | 0.383 s | 1.064 s | 1.698 s | 1.117 s |

Every query returned the same row: `Lesson 10 builds` on `windows-latest`, 2 min 24.75 s. Parquet is as fast as a table in memory, because DuckDB reads only three columns and decodes them in bulk. CSV is 5 to 9 times slower than Parquet on the aggregate: every value is text to parse, and there are no statistics, so the week filter reads the whole gigabyte. Writing took 0.41 s for Parquet and 0.50 s for CSV on my machine. If a CSV file is queried more than once, convert it first.

## Threads

DuckDB runs a query on as many threads as the machine has cores: the [`threads` setting](https://duckdb.org/docs/current/configuration/overview) defaults to the number of CPU cores. The runners showed 4, 4 and 3. The aggregate on the table, with `SET threads = 1`:

| Aggregate on the table | My machine | Ubuntu | Windows | macOS |
|---|---|---|---|---|
| all threads | 0.042 s | 0.263 s | 0.420 s | 0.289 s |
| `SET threads = 1` | 0.530 s | 0.632 s | 1.089 s | 1.120 s |

12.6 times faster with 24 threads, 2.4 to 3.9 times with 3 or 4. Scans and hash aggregates split well across threads. The other side: a DuckDB query in a web server takes every core by default, and several at once compete for them. Set `threads` when DuckDB shares the machine.

## A remote Parquet file

Lesson 4 read Parquet over HTTPS and claimed that DuckDB downloads only what it needs. The [HTTP log](https://duckdb.org/docs/current/operations_manual/logging/overview) proves it, on January 2024 of the [New York City taxi trips](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), a 49,961,641-byte file:

```sql
CALL enable_logging('HTTP', storage = 'memory');
SELECT count(*) FROM 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet';
SELECT count(*) AS requests, sum(response.headers['Content-Length']::BIGINT) AS bytes FROM duckdb_logs_parsed('HTTP') WHERE request.type = 'GET';
CALL truncate_duckdb_logs();
```

Enabling the log prints a warning in the CLI, because the log now also collects warnings:

```text
WARNING:
The logging settings have been changed so you may lose warnings printed in the CLI.
To continue printing warnings to the console, set storage='shell_log_storage'.
```

The script repeats the count for two other queries. The downloads were the same on my machine and on the three runners:

| Query | Result | `GET` requests | Bytes downloaded | Time, my machine |
|---|---|---|---|---|
| `count(*)` | 2,964,624 | 1 | 65,536 | 0.25 s |
| `avg(trip_distance)` | 3.6521691789583146 | 3 | 4,082,947 | 0.63 s |
| `SELECT * … LIMIT 1` | one trip | 1 | 17,612,330 | 1.64 s |

Every query starts with a `HEAD` request for the file size. The first one then downloads the end of the file, where the footer is, and needs nothing else: the row counts are in the footer. The average reads one column, the `LIMIT 1` reads every column of one row group. Exercise 3 matches these numbers with the metadata.

On a network, the column layout matters more than on a disk: `SELECT *` on a remote file is the expensive query, even with `LIMIT 1`.

## Memory and spilling to disk

By default, DuckDB may use 80% of the RAM (`memory_limit`). When a sort, a join, a `GROUP BY` or a window function needs more, the [tuning guide](https://duckdb.org/docs/current/guides/performance/how_to_tune_workloads) says that it spills to temporary files, in `temp_directory`: `.tmp` next to the process for an in-memory database, `<file>.tmp` next to a database file. The timings script sorts the 11 million steps from the Parquet file under two limits:

```sql
SET temp_directory = 'out/tmp';
SET memory_limit = '500MB';
COPY (FROM 'out/steps-big.parquet' ORDER BY started_at) TO 'out/steps-big-sorted-500mb.parquet';
SET memory_limit = '100MB';
SET threads = 1;
COPY (FROM 'out/steps-big.parquet' ORDER BY started_at) TO 'out/steps-big-sorted-100mb.parquet';
```

| Sort of 11 million rows | My machine | Ubuntu | Windows | macOS |
|---|---|---|---|---|
| 500 MB, all threads | 2.21 s | 2.91 s | 4.62 s | 4.92 s |
| 100 MB, one thread | 6.34 s | 6.96 s | 9.89 s | 7.94 s |

On my machine, the same sort took 1.37 s with 1 GB. With 100 MB and four threads, it failed:

```text
Out of Memory Error: failed to pin block of size 256.0 KiB (95.4 MiB/95.3 MiB used)

Possible solutions:
* Reducing the number of threads (SET threads=X)
* Disabling insertion-order preservation (SET preserve_insertion_order=false)
* Increasing the memory limit (SET memory_limit='...GB')
```

Threads work in parallel, each on its own part of the data, so fewer threads need less memory at the same time: that is the first suggestion, and it's why the script sets one thread. The failed `COPY` also left a file behind: 1.1 MB in one run; empty in another, where the next query failed with `File 'out/steps-big-sorted-100mb.parquet' too small to be a Parquet file`. Check that a `COPY` succeeded before using its file.

Two traps seen along the way. Lowering the limit below what is already used fails: in a session holding the 11-million-row table, `SET memory_limit = '10MB'` answered `Failed to change memory limit to 10000000: could not free up enough memory for the new limit`. And a table in an in-memory database counts in the limit too: after `SET memory_limit = '100MB'` in that session, queries failed with `failed to pin block`. That's why the script drops the table first.

## When DuckDB is the wrong tool

DuckDB is [designed for analytical queries](https://duckdb.org/why_duckdb): a few large scans, aggregates and joins. What this course measured, and what the documentation says, points to other tools for:

- **Many small transactions.** An `INSERT` per row took 0.07 to 0.4 ms in the CI of lessons 5 and 6, where the appender loaded a million rows in 0.2 to 0.5 s. An order-entry system belongs in SQL Server or PostgreSQL.
- **Several processes writing to the same database.** One process can read and write a database file; [several processes can only read it](https://duckdb.org/docs/current/connect/concurrency). Lesson 8 tries it.
- **A shared server for many users.** DuckDB lives inside your process; there is no server, no users and no permissions to manage.
- **A database file on a network share.** The [FAQ](https://duckdb.org/faq) strongly advises against read-write workloads on network-attached storage.

For reading files, a CI history, a data export or a notebook, it's the right size.

## Key takeaways

- `EXPLAIN` shows the plan; read it from the bottom up. `EXPLAIN ANALYZE` runs the query and adds real rows and times.
- `Projections:` in a scan is the list of columns actually read; `Filters:` is the part of the `WHERE` clause pushed into the scan.
- Parquet row groups carry min/max statistics per column. A filter skips row groups only if the data is ordered on that column: sort files by the column you filter on.
- Partition folders are skipped before any file is opened (`Scanning Files: 1/3`).
- Parquet is about as fast as an in-memory table, and 5 to 9 times faster than CSV for these queries.
- DuckDB uses every core by default; set `threads` when it shares a machine.
- A remote Parquet query downloads the footer and the column chunks it needs; `SELECT *` downloads whole row groups.
- With a memory limit, sorts, joins and aggregates spill to `temp_directory`; each thread needs memory, so reduce `threads` for small limits.

## Exercises

The solutions are in [`sql/07-exercises.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/07-exercises.sql); their timings are in the timings script.

1. Four ways to keep the steps of 2030-01-01, on the sorted file. Which ones can skip row groups? Does `EXPLAIN` tell you?

```sql
WHERE started_at >= '2030-01-01' AND started_at < '2030-01-02'
WHERE started_at::DATE = '2030-01-01'
WHERE date_trunc('day', started_at) = '2030-01-01'
WHERE strftime(started_at, '%Y-%m-%d') = '2030-01-01'
```

<details>
<summary>Solution</summary>

`EXPLAIN` shows a `Filters:` section in the scan for all four, so it doesn't answer. But what it shows differs. On the small file, with 2026-09-14, the cast and `date_trunc` were rewritten into a range:

```text
│          Filters:         │
│ started_at>='2026-09-14 00│
│   :00:00'::TIMESTAMP AND  │
│  started_at<'2026-09-15 00│
│     :00:00'::TIMESTAMP    │
```

The `strftime` filter stays an expression, which no min/max statistic can answer:

```text
│          Filters:         │
│ (strftime(started_at, '%Y-│
│  %m-%d') = '2026-09-14')  │
```

The timings agree. All four return 2,204 steps; with one thread, the range, the cast and `date_trunc` took 0.002 to 0.005 s on my machine and on the runners, while `strftime` took 0.467 s on my machine, and 0.60 s (Ubuntu), 0.96 s (macOS) and 1.12 s (Windows) in the CI, because it formats 11 million timestamps as text. In SQL Server, wrapping a column in a function makes the predicate non-sargable; DuckDB's optimizer undoes some of those wrappers, not all. Compare columns with values of their own type.

</details>

2. The steps are filtered by `os = 'windows-latest'`. How many of the 9 row groups must be read in `out/steps.parquet`, in `out/steps-sorted.parquet`, and in a file sorted by `os, started_at`?

<details>
<summary>Solution</summary>

Write the third file, then compare the filter with the `os` statistics:

```sql
COPY (FROM steps ORDER BY os, started_at) TO 'out/steps-by-os.parquet';
SELECT replace(file_name, '\', '/') AS file, count(*) AS row_groups,
       count(*) FILTER (stats_min <= 'windows-latest' AND stats_max >= 'windows-latest') AS row_groups_to_read
FROM parquet_metadata(['out/steps.parquet', 'out/steps-sorted.parquet', 'out/steps-by-os.parquet'])
WHERE path_in_schema = 'os'
GROUP BY ALL
ORDER BY file;
```

```text
┌──────────────────────────┬────────────┬────────────────────┐
│           file           │ row_groups │ row_groups_to_read │
│         varchar          │   int64    │       int64        │
├──────────────────────────┼────────────┼────────────────────┤
│ out/steps-by-os.parquet  │          9 │                  2 │
│ out/steps-sorted.parquet │          9 │                  9 │
│ out/steps.parquet        │          9 │                  9 │
└──────────────────────────┴────────────┴────────────────────┘
```

Sorting by time helps time filters and nothing else. A file can be sorted well for one column only, or for a leading column and, inside each value, the next one. For a column with a few values like `os`, partitioning (one folder per value) is another answer.

</details>

3. Explain the bytes downloaded by the three remote queries (65,536, then 4,082,947, then 17,612,330) with `parquet_metadata` on the same URL.

<details>
<summary>Solution</summary>

```sql
SELECT row_group_id, max(row_group_num_rows) AS rows, sum(total_compressed_size) AS all_columns,
       sum(total_compressed_size) FILTER (path_in_schema = 'trip_distance') AS trip_distance
FROM parquet_metadata('https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet')
GROUP BY ALL
ORDER BY row_group_id;
```

```text
┌──────────────┬─────────┬─────────────┬───────────────┐
│ row_group_id │  rows   │ all_columns │ trip_distance │
│    int64     │  int64  │   int128    │    int128     │
├──────────────┼─────────┼─────────────┼───────────────┤
│            0 │ 1048576 │    17611010 │       1441439 │
│            1 │ 1048576 │    17522229 │       1451920 │
│            2 │  867472 │    14817869 │       1189588 │
└──────────────┴─────────┴─────────────┴───────────────┘
```

- `count(*)`: 65,536 bytes is one range request of 64 KiB at the end of the file. The footer fits in it, and the row counts (1,048,576 + 1,048,576 + 867,472 = 2,964,624) are in the footer.
- `avg(trip_distance)`: 1,441,439 + 1,451,920 + 1,189,588 = 4,082,947, exactly the three `trip_distance` chunks, one request per row group. There was no request for the footer: it was already in DuckDB's cache of remote files (`enable_external_file_cache`, `true` by default), from the first query of the session.
- `SELECT * … LIMIT 1`: every column of row group 0, 17,611,010 bytes, plus 1,320 bytes. A range request covers contiguous bytes: from byte 4, where the first chunk starts after the `PAR1` magic number, to the end of the last chunk. In the metadata, `dictionary_page_offset` and `total_compressed_size` give that span, 17,612,330 bytes; the 1,320 bytes are the gaps between the chunks of the 19 columns.

</details>

## Sources

- [`EXPLAIN`](https://duckdb.org/docs/current/guides/meta/explain), [`EXPLAIN ANALYZE`](https://duckdb.org/docs/current/guides/meta/explain_analyze) and [profiling](https://duckdb.org/docs/current/dev/profiling)
- [Performance guide](https://duckdb.org/docs/current/guides/performance/overview): [file formats](https://duckdb.org/docs/current/guides/performance/file_formats), [indexing](https://duckdb.org/docs/current/guides/performance/indexing), [tuning workloads](https://duckdb.org/docs/current/guides/performance/how_to_tune_workloads)
- [Parquet metadata](https://duckdb.org/docs/current/data/parquet/metadata) and [Parquet tips](https://duckdb.org/docs/current/data/parquet/tips)
- [Apache Parquet file format](https://parquet.apache.org/docs/file-format/)
- [Configuration settings](https://duckdb.org/docs/current/configuration/overview): `threads`, `memory_limit`, `temp_directory`
- [Logging](https://duckdb.org/docs/current/operations_manual/logging/overview)
- [Hive partitioning](https://duckdb.org/docs/current/data/partitioning/hive_partitioning)
- [Concurrency](https://duckdb.org/docs/current/connect/concurrency), [Why DuckDB](https://duckdb.org/why_duckdb) and the [FAQ](https://duckdb.org/faq)
- [TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), New York City Taxi and Limousine Commission
