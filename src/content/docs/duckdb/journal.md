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
- [ ] Lesson 5: DuckDB from C#
- [ ] Lesson 6: DuckDB from Java
- [ ] Lesson 7: performance
- [ ] Lesson 8: persistence, transactions and concurrency

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

## To verify

- Why step number 4 is missing from the jobs of `Deploy to GitHub Pages` (`withastro/action` step): an internal step of the composite action?
- The extension install path on Linux and macOS (`~/.duckdb/extensions/v1.5.5/<platform>/`), deduced from Windows.
- Range requests when reading Parquet over HTTPS (lesson 7).
- Partition pruning on `WHERE os = 'windows-latest'` (lesson 7).
