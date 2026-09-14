---
title: LadybugDB — Mission
description: Learn LadybugDB, the embedded graph database that continues Kuzu, by querying the links between this site's pages, its Git history and its CI runs with Cypher — from the command line, then from C# and Java.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every query in this course is in [`code/ladybugdb/cypher`](https://github.com/spareilleux/learn/tree/main/code/ladybugdb/cypher), next to its expected output. [`.github/workflows/ladybugdb-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ladybugdb-examples.yml) runs them all with the LadybugDB CLI on Linux, Windows and macOS and compares the results. The outputs in the lessons were captured with LadybugDB 0.20.4 in September 2026.
:::

## Why I'm learning this

The [DuckDB course](../duckdb/) answers questions about rows: how many runs, how long, which step. Other questions about this site are about connections. How many clicks from the home page to a lesson? Which files change together? Which commits did a failing workflow run on? In SQL, each of these is a chain of self-joins, or a recursive CTE whose depth I have to guess.

A graph database stores the connections themselves, and its query language describes paths directly. [LadybugDB](https://ladybugdb.com/) is one that runs inside your process, like DuckDB and SQLite: no server to install.

## Who this course is for

You know SQL: `SELECT`, `JOIN`, `GROUP BY`, maybe a recursive CTE. You write C# or Java. You don't need to know anything about graph databases or [Cypher](https://opencypher.org/).

## What LadybugDB is, in one table

| | SQL Server graph tables | Neo4j | LadybugDB |
|---|---|---|---|
| Runs | as a server | as a server | inside your process |
| Schema | tables created `AS NODE` and `AS EDGE` | optional: labels and properties appear when you write them | required: node tables and relationship tables, with typed columns |
| Query language | T-SQL with `MATCH` | Cypher | Cypher |
| Paths of any length | `SHORTEST_PATH` | variable-length patterns | variable-length patterns, shortest paths |
| From .NET | `Microsoft.Data.SqlClient` | Neo4j .NET driver | NuGet package `LadybugDB` |
| From Java | JDBC driver | Neo4j Java driver | Maven package `com.ladybugdb:lbug` |

Sources: [SQL Graph architecture](https://learn.microsoft.com/sql/relational-databases/graphs/sql-graph-architecture), [Neo4j Cypher manual](https://neo4j.com/docs/cypher-manual/current/introduction/), [differences between LadybugDB and Neo4j](https://docs.ladybugdb.com/cypher/difference/).

LadybugDB was [formerly known as Kuzu](https://github.com/LadybugDB/ladybug#readme). Kuzu's authors [have archived its repository](https://github.com/kuzudb/kuzu); LadybugDB continues the code base under the MIT license, with new names: the CLI is `lbug`, and the documentation names database files `.lbdb`.

## The data

[`code/ladybugdb/data/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/extract.py) reads this repository at commit [`cbcbb42`](https://github.com/spareilleux/learn/commit/cbcbb42) (2026-09-14) and writes six CSV files to [`code/ladybugdb/data`](https://github.com/spareilleux/learn/tree/main/code/ladybugdb/data):

- `pages.csv`: the 319 pages of the site (117 in English, 101 in French, 101 in Spanish), with their locale, course, title and number of lines;
- `links.csv`: the 712 links from one page of the site to another, found in Markdown links and `href` attributes outside code blocks;
- `external_links.csv`: the 3,712 links to 85 other sites;
- `commits.csv`, `parents.csv` and `changes.csv`: the 74 commits up to `cbcbb42`, the parent of each one, and the 1,019 file changes they made to 710 files.

Lesson 4 adds the 125 CI runs of [`code/duckdb/data/runs.json`](https://github.com/spareilleux/learn/blob/main/code/duckdb/data/runs.json), the snapshot the DuckDB course queries.

## By the end of this course, I will be able to

- model data as node tables and relationship tables, and query it with Cypher patterns;
- load CSV and JSON files, and find the rows that don't fit the schema;
- write variable-length paths and shortest paths, and know the path semantics they use;
- recognize LadybugDB's bugs and limits, and check a result another way;
- use LadybugDB from C# and from Java.

## Outline

| # | Lesson | If you know SQL |
|---|---|---|
| 1 | [A first graph: tables, `CREATE`, `MATCH`, `MERGE`](01-first-graph/) | `CREATE TABLE`, `INSERT`, `MERGE`, `JOIN` |
| 2 | [Loading files: `LOAD FROM`, `COPY`, warnings](02-loading/) | `OPENROWSET`, `BULK INSERT` |
| 3 | [Paths: variable length and shortest paths](03-paths/) | recursive CTEs |
| 4 | [Git history and CI runs as a graph](04-git-history/) | self-joins, junction tables |
| 5 | LadybugDB from C# (coming next) | ADO.NET |
| 6 | LadybugDB from Java (coming next) | JDBC |
| 7 | Graph algorithms and full-text search (coming next) | |
| 8 | Persistence, transactions and concurrency (coming next) | isolation, locks |
| — | [Journal](journal/) | |

## Resources

- [LadybugDB documentation](https://docs.ladybugdb.com/)
- [Cypher in LadybugDB](https://docs.ladybugdb.com/get-started/cypher-intro/)
- [LadybugDB CLI](https://docs.ladybugdb.com/client-apis/cli/)
- [LadybugDB source code](https://github.com/LadybugDB/ladybug), and the [release 0.20.4](https://github.com/LadybugDB/ladybug/releases/tag/v0.20.4) this course uses
- [openCypher](https://opencypher.org/): the open specification of Cypher
