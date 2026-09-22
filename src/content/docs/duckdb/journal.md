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

## QA

DuckDB 1.5.5, its .NET driver and its JDBC driver are somebody else's software. Two rows below lose data without saying so, which is why the Status column separates them from the rows that are documented behaviour a C# or Java habit walks into. Nothing here has been reported upstream.

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| DuckDB.NET fills a class from a `STRUCT` by property name | It ignores case but not underscores, so `StartedAt` silently keeps its default value while `Started_At` is filled | DuckDB.NET 1.5.5 | Silent, no exception. A positional record throws `MissingMethodException` instead | Reproduced, not reported [2026-09-14](#2026-09-14--surprises-while-writing-lessons-5-6) |
| A `TIMESTAMPTZ` survives a round trip through the driver | It comes back as a `DateTime` holding the UTC value with `Kind` `Unspecified`, so `ToUniversalTime` shifts it a second time. In Java it is an `OffsetDateTime` in the JVM's zone, whatever `SET TimeZone` said | DuckDB.NET 1.5.5, duckdb_jdbc 1.5.5.1 | Wrong values, silently, on both drivers | Reproduced, not reported [2026-09-14](#2026-09-14--surprises-while-writing-lessons-5-6) |
| A multi-statement string is atomic, as DuckDB's transactions page describes an implicit transaction | It is not: the first two rows stayed when the third statement failed, in the CLI and through JDBC | DuckDB 1.5.5 CLI and duckdb_jdbc | 2 of 3 rows kept, by `-c "a; b; c"` and by `statement.execute("a; b; c")`. `COMMIT` after an error prints no error and rolls back | Reproduced; documentation and behaviour disagree [2026-09-14](#2026-09-14--surprises-while-writing-lessons-7-8) |
| A failed query leaves the `Statement` usable | The statement is closed, so a loop that catches the error and carries on fails every statement after it | duckdb_jdbc 1.5.5.1 | `Statement was closed` | Reproduced, not reported [2026-09-14](#2026-09-14--surprises-while-writing-lessons-5-6) |
| The CSV sniffer reports a column it could not parse as asked | It silently reads `13/09/2026 15:53` as `VARCHAR`, and so does a wrong `timestampformat`; only an explicit type makes it fail | DuckDB 1.5.5 | Every later date comparison becomes a string comparison | Reproduced; the journal's own words: "This isn't an error" [2026-09-14](#2026-09-14--surprises-while-writing-lessons-1-4) |
| A glob over files with different shapes warns or fails | `FROM 'data/*.json'` merges runs and jobs into one table without a word | DuckDB 1.5.5 | 20 columns out of two unrelated shapes | Reproduced, not reported [2026-09-14](#2026-09-14--surprises-while-writing-lessons-1-4) |
| `approx_unique` in `SUMMARIZE` counts the distinct values | It over- and under-counts | DuckDB CLI 1.5.5 | 131 for 125 run ids, 17 for 21 workflow names | By design: HyperLogLog trades exactness for constant memory [2026-09-14](#2026-09-14--surprises-while-writing-lessons-1-4) |
| `labels[0]` is an error | It returns `NULL`, as does any index past the end | DuckDB 1.5.5 | No error | By design: lists start at 1. A C# or Java habit that fails silently [2026-09-14](#2026-09-14--surprises-while-writing-lessons-1-4) |
| The Parquet writer produces the same bytes for the same data | It does not — it writes with several threads | DuckDB 1.5.5 Parquet writer | 119,021,205 then 119,392,814 bytes locally for an 11-million-row file; 118,714,412 to 119,120,557 on the runners. On the first push the lesson-4 script failed on macOS alone: 8 column chunks differed by 1 to 6 bytes in `total_compressed_size` | Reproduced; a real CI failure, worked around by comparing `num_values` [2026-09-14](#2026-09-14--surprises-while-writing-lessons-7-8) |
| Equivalent date predicates get equivalent plans | `started_at::DATE = …` and `date_trunc('day', started_at) = …` are rewritten into a range that skips row groups; `strftime(started_at, …) = …` stays an expression and reads every row | DuckDB 1.5.5 optimizer | 0.47 s against 0.003 s on the sorted file | Reproduced; a genuinely missed rewrite [2026-09-14](#2026-09-14--surprises-while-writing-lessons-7-8) |
| A sort that does not fit in `memory_limit` spills to disk | It fails with 4 threads and succeeds with 1, and the failed `COPY` leaves a partial file behind | DuckDB 1.5.5 | 11 M rows at `memory_limit = '100MB'`; 6.3 to 9.9 s in the one-thread case | Reproduced, thread-count dependent [2026-09-14](#2026-09-14--surprises-while-writing-lessons-7-8) |
| A read-only process can open a file another process holds | A process holding the file blocks every other process, read-only ones included, with a different message on each OS | DuckDB 1.5.5 | Three OSes, three messages; Linux and macOS add a hint about `-readonly` that Windows does not | Reproduced; by design [2026-09-14](#2026-09-14--surprises-while-writing-lessons-7-8) |
| The JDBC jar and the .NET package carry what the platform needs | The jar is 85 MB with four native libraries and no Windows-on-Arm build | duckdb_jdbc 1.5.5.1, DuckDB.NET 1.5.5 | `DuckDB.NET.Data.Full` is 420 MB in the NuGet cache, 316 MB in `bin/Debug`, 69 MB published for `linux-x64` alone | Measured; the missing win-arm64 build is a real gap [2026-09-14](#2026-09-14--surprises-while-writing-lessons-5-6) |
| The one-line install script covers the three systems | `curl -fsSL https://install.duckdb.org | sh` does not support Windows | install.duckdb.org | The workflow downloads `duckdb_cli-windows-amd64.zip` instead | Reproduced [2026-09-14](#2026-09-14--installing-duckdb) |
| A JDBC batch is faster than single statements | It was not | duckdb_jdbc 1.5.5.1, in CI | 690 ms to 2.4 s for 10,000 rows, against the C# appender's 226 to 331 ms for 1,000,000 rows | Measured, cause not investigated [2026-09-14](#2026-09-14--surprises-while-writing-lessons-5-6) |

## Experiments

Four questions the course asked before it measured. None is a hypothesis the author invented and then tested — two rest on documentation read beforehand, one on a value read out of the file itself — and the table says so rather than dressing them up. The third is the one that came back refuted.

| Question | Hypothesis | Result | Verdict | Where |
|---|---|---|---|---|
| Can `EXPLAIN` plans be compared by the CI across three runners? | The journal asks the question and draws its conclusion from the answer; no prediction written | The output does not depend on the number of threads, and the estimates were the same on the three runners | Confirmed: plans are comparable | [2026-09-14](#2026-09-14--surprises-while-writing-lessons-7-8) |
| Can an older DuckDB read a file written by 1.5.5? | The file's own `storage_version=v1.0.0+` tag, read before the test | The 1.0.0 CLI read the default-written files. With `STORAGE_VERSION 'v1.5.0'` it refused them: `version number 68, can only read 64` | Confirmed, with its negative control | [2026-09-14](#2026-09-14--surprises-while-writing-lessons-7-8) |
| Is a multi-statement string atomic? | Yes — DuckDB's own transactions page describes an implicit transaction. An external documented prior, cited before the test | `-c "a; b; c"` and `statement.execute("a; b; c")` both kept the first two rows when the third failed | Refuted | [2026-09-14](#2026-09-14--surprises-while-writing-lessons-7-8) |
| Does the plan's prediction hold in wall-clock time? | The plan says `::DATE` and `date_trunc` skip row groups and `strftime` does not; lesson 7 reads the plans, then measures what they predict | 0.47 s against 0.003 s on the sorted file | Confirmed | [2026-09-14](#2026-09-14--surprises-while-writing-lessons-7-8) |

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
