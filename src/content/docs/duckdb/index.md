---
title: DuckDB — Mission
description: Learn DuckDB, the in-process analytical database, by querying the real CI history of this site — from the command line, then from C# and Java.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every query in this course is in [`code/duckdb/sql`](https://github.com/spareilleux/learn/tree/main/code/duckdb/sql), next to its expected output. [`.github/workflows/duckdb-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/duckdb-examples.yml) runs them all with the DuckDB CLI on Linux, Windows and macOS and compares the results. The outputs in the lessons were captured with DuckDB 1.5.5 in September 2026.
:::

## Why I'm learning this

Every question I ask about the CI of this site — which workflow fails most, how long the Windows jobs take, which step got slower — ends in a pile of JSON from `gh run list` and `gh api`. I read it with `jq`, or paste it into a spreadsheet. [DuckDB](https://duckdb.org/) promises to answer those questions with SQL, straight from the files, without a server to install.

## Who this course is for

You know SQL from [SQL Server](https://learn.microsoft.com/sql/sql-server/), [PostgreSQL](https://www.postgresql.org/docs/current/) or [SQLite](https://www.sqlite.org/): `SELECT`, `JOIN`, `GROUP BY`. You write C# or Java. You don't need to know anything about analytics or data engineering.

## What DuckDB is, in one table

| | SQL Server / PostgreSQL | SQLite | DuckDB |
|---|---|---|---|
| Runs | as a server | inside your process | inside your process |
| Built for | transactions (OLTP) | transactions, small apps | analytics (OLAP): scans, aggregates, joins over many rows |
| Storage | rows | rows | columns |
| Database | a server instance | one file | one file, or none: it also queries CSV, JSON and Parquet files directly |
| From .NET | `Microsoft.Data.SqlClient`, Npgsql | `Microsoft.Data.Sqlite` | DuckDB.NET (ADO.NET) |
| From Java | JDBC driver | JDBC driver | JDBC driver |

## The data

The course queries a snapshot of this repository's own GitHub Actions history, exported on 2026-09-14 into [`code/duckdb/data`](https://github.com/spareilleux/learn/tree/main/code/duckdb/data):

- `runs.json`: 125 workflow runs, from `gh run list --limit 1000 --json databaseId,workflowName,event,status,conclusion,createdAt,updatedAt,startedAt,headBranch,headSha,attempt`;
- `jobs.json`: the 315 jobs of those runs, with their steps, from the GitHub REST API.

They are the runs written by the [GitHub Actions course](../github-actions/): real failures, real timings, three operating systems.

## By the end of this course, I will be able to

- query CSV, JSON and Parquet files with SQL from the DuckDB CLI;
- use DuckDB's SQL extensions to write shorter analytical queries;
- flatten nested JSON with `STRUCT`, `LIST` and `unnest`;
- convert between formats and read many files at once;
- use DuckDB from C# and from Java;
- read a query plan and know when DuckDB is the wrong tool.

## Outline

| # | Lesson | If you know SQL Server |
|---|---|---|
| 1 | [First queries](01-first-queries/) | `sqlcmd`, `OPENROWSET`, `SELECT INTO` |
| 2 | [Friendly SQL: dates, windows, `QUALIFY`, `PIVOT`](02-friendly-sql/) | window functions, `PIVOT` |
| 3 | [Nested data: `STRUCT`, `LIST`, `unnest`](03-nested-data/) | `OPENJSON`, `CROSS APPLY` |
| 4 | [Files: CSV, Parquet, globs, remote files](04-files/) | `BULK INSERT`, external tables |
| 5 | DuckDB from C# | ADO.NET |
| 6 | DuckDB from Java | JDBC |
| 7 | Performance: plans and columnar storage | execution plans, columnstore indexes |
| 8 | Persistence, transactions and concurrency | isolation, locks |
| — | [Journal](journal/) | |

## Resources

- [DuckDB documentation](https://duckdb.org/docs/current/)
- [Why DuckDB](https://duckdb.org/why_duckdb)
- [DuckDB CLI](https://duckdb.org/docs/current/clients/cli/overview)
- [Friendly SQL](https://duckdb.org/docs/current/sql/dialect/friendly_sql): the extensions to standard SQL
- [DuckDB source code](https://github.com/duckdb/duckdb)
