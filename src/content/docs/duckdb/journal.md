---
title: Journal
description: Dated progress notes — data, CI runs, surprises and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Data snapshot: 125 runs and 315 jobs of this repository
- [x] CI: every lesson's SQL compared with its expected output on three OSes
- [x] Lesson 1: first queries
- [x] Lesson 2: friendly SQL
- [x] Lesson 3: nested data
- [x] Lesson 4: files
- [x] Lesson 5: DuckDB from C#
- [x] Lesson 6: DuckDB from Java
- [x] Lesson 7: performance
- [x] Lesson 8: persistence, transactions and concurrency

## 2026-09-14 — The data

- `runs.json`: `gh run list --limit 1000 --json databaseId,workflowName,event,status,conclusion,createdAt,updatedAt,startedAt,headBranch,headSha,attempt`, exported around 14:04 UTC. 125 runs, the oldest from 2026-09-13 15:53.
- `jobs.json`: one call per run to `repos/spareilleux/learn/actions/runs/{id}/jobs?per_page=100`, keeping 11 fields of each job and 5 of each step. 315 jobs for 121 runs: 4 runs never had a job.
- The jobs endpoint returns the latest attempt only: 4 jobs for the run attempted three times, 12 with `?filter=all`. Noticed while writing lesson 3; the snapshot stays as it is.

## 2026-09-14 — Installing DuckDB

- Locally, `winget` had DuckDB 1.5.3 installed (`DuckDB.cli`), with 1.5.5 available. The course uses 1.5.5, unzipped from the GitHub release.
- CI on Linux and macOS: `curl -fsSL https://install.duckdb.org | sh` → `Successfully installed DuckDB 1.5.5 to /home/runner/.duckdb/cli/1.5.5/duckdb`. The script reads `DUCKDB_VERSION` from the environment, which the workflow sets, so the version is pinned.
- CI on Windows: the script doesn't support it; the workflow downloads `duckdb_cli-windows-amd64.zip` and adds the folder to `GITHUB_PATH`.
- `check.sh` runs each script with `duckdb -csv <` and diffs against `sql/expected/`. Each OS takes one to two seconds for all the scripts of lessons 1-4, the HTTPS query included.

## 2026-09-14 — Surprises while writing lessons 1-4

- `SUMMARIZE`'s `approx_unique` was 131 for 125 unique run ids, and 17 for 21 workflow names.
- The CLI uses the OS time zone for `TIMESTAMPTZ` display (`America/…` locally, UTC on runners): lesson 2's script sets `TimeZone` explicitly.
- `sum(INTERVAL)` doesn't exist, `avg(INTERVAL)` does.
- `labels[0]` returns `NULL` without an error.
- The lambda arrow `x -> …` prints a deprecation warning in 1.5.5; the lessons use `lambda x: …`.
- A skipped job has `runner_name` `NULL`; the deploy job rejected by the environment's branch policy has `''`.
- The CSV sniffer silently reads `13/09/2026 15:53` as `VARCHAR`, and so does a wrong `timestampformat`. Only an explicit type makes it fail.
- `FROM 'data/*.json'` merges the runs and the jobs into one 20-column table, without a warning.
- First push of the lesson 4 script: failed on `macos-latest` only. The Parquet `total_compressed_size` of 8 column chunks differed by 1 to 6 bytes from Linux and Windows. The script now compares `num_values` instead.
- `COPY` to an existing file overwrites it; `COPY … PARTITION_BY` to a non-empty folder fails without `OVERWRITE`.

## 2026-09-14 — Surprises while writing lessons 5-6

- `DuckDB.NET.Data.Full` 1.5.5 is 420 MB in the NuGet cache, 316 MB in `bin/Debug`, 69 MB once published for `linux-x64` only. The JDBC jar is 85 MB, with four native libraries and no Windows on Arm build.
- DuckDB.NET maps a `STRUCT` to a class by property name, ignoring case but not underscores: `StartedAt` silently stays at its default value, `Started_At` is filled. A positional record throws `MissingMethodException`.
- `TIMESTAMPTZ` comes back as a `DateTime` holding the UTC value with `Kind` `Unspecified`, so `ToUniversalTime` shifts it a second time. In Java, it's an `OffsetDateTime` in the JVM's default zone, whatever `SET TimeZone` says.
- `(long)` and `Convert.ToInt64` both throw on the `BigInteger` of a `HUGEINT`; `(long)(BigInteger)value` works.
- With JDBC, a `Statement` is closed after a failed query: a loop that catches the error and goes on fails every following statement with `Statement was closed`.
- JDK 25 prints four native access warnings when the driver loads, unless `--enable-native-access=ALL-UNNAMED`; Maven's launcher already passes it.
- Timings in the CI, not compared: the C# appender loaded 1,000,000 rows in 226 to 331 ms and 10,000 single `INSERT` statements took 1.3 to 3.9 s; in Java, a JDBC batch was no faster than single statements (690 ms to 2.4 s for 10,000 rows).
- Relative paths in SQL are relative to the process working directory, not to the project: both programs run from `code/duckdb`.

## 2026-09-14 — Surprises while writing lessons 7-8

- `EXPLAIN` output doesn't depend on the number of threads, and the estimates were the same on the three runners, so plans can be compared by the CI.
- The Parquet writer uses several threads, and the size of the same 11-million-row file changed between runs: 119,021,205 then 119,392,814 bytes locally, 118,714,412 to 119,120,557 bytes on the runners.
- The optimizer rewrites `started_at::DATE = …` and `date_trunc('day', started_at) = …` into a range that skips row groups; `strftime(started_at, …) = …` stays an expression and reads every row: 0.47 s against 0.003 s on the sorted file.
- The remote Parquet downloads were byte-for-byte identical on the four machines, and match the metadata exactly: the three `trip_distance` chunks for the average, row group 0 from byte 4 for `SELECT * … LIMIT 1`.
- A sort of 11 million rows under `memory_limit = '100MB'` fails with 4 threads and succeeds with 1 (6.3 to 9.9 s). The failed `COPY` left a partial file behind.
- `COMMIT` after an error in a transaction prints no error and rolls back, in the CLI and in JDBC. Multi-statement strings aren't atomic either: `-c "a; b; c"` and `statement.execute("a; b; c")` kept the first two rows when the third failed, while the transactions page describes an implicit transaction.
- A write conflict fails at the second `UPDATE`, a duplicate key between two transactions only at the second commit.
- A process holding a database file blocks every other process, read-only ones included, with a different message on each OS. Files written by DuckDB 1.5.5 are tagged `storage_version=v1.0.0+` and were read by the DuckDB 1.0.0 CLI; with `STORAGE_VERSION 'v1.5.0'`, 1.0.0 refused them (version number 68, can only read 64).
- The CI now also runs `timings/07-performance.sql` (not compared: 17 s on Ubuntu, 32 s on Windows, with a 1 GB CSV file) and `shell/08-*.sh`.

## To verify

- Why step number 4 is missing from the jobs of `Deploy to GitHub Pages` (`withastro/action` step): an internal step of the composite action?
- The extension install path on Linux and macOS (`~/.duckdb/extensions/v1.5.5/<platform>/`), deduced from Windows.
- The Linux and macOS commands to run the Java program without Maven (lesson 6).
- Write conflicts and read-only connections with DuckDB.NET (lesson 8): tested with JDBC only.
- Opening, writing and closing a database file from several processes under load (lesson 8, exercise 3).
- The Quack remote protocol and DuckLake, for several writing processes: mentioned, not tried.
