---
title: Journal
description: Dated progress notes — versions, what I tried, surprises, findings about Guitar Alchemist's data and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Mission and a 13-lesson outline
- [x] Code: SQL scripts run by `psql`, C# and Java programs, all compared with their expected output by `check.sh`
- [x] CI: [`postgresql-aurora-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/postgresql-aurora-examples.yml) runs everything against PostgreSQL on Linux and builds the programs on Windows and macOS; first run green on 2026-09-16
- [x] Lesson 1: a container, `psql`, databases, schemas and roles
- [x] Lesson 2: types and modeling
- [x] Lesson 3: CTEs, windows, `LATERAL`, upserts and `MERGE`
- [x] Lesson 4: PostgreSQL from C# and Java
- [x] Lesson 5: indexes and plans
- [x] Lesson 6: transactions and MVCC
- [x] Lesson 7: JSON and search
- [x] Lesson 8: functions, extensions and pgvector
- [ ] Lessons 9 to 13
- [ ] Anything on AWS: every Aurora section is still *to verify*

## 2026-09-15 — Versions

- [PostgreSQL's versioning page](https://www.postgresql.org/support/versioning/) lists 18.6 as the current minor release of PostgreSQL 18, supported until November 14, 2030. PostgreSQL 19 is in beta. The course pins the image tag `postgres:18.6-trixie` and records its digest in the mission page.
- The newest Aurora PostgreSQL release in AWS's release notes is 18.4.1, from August 21, 2026. Its extension table gives `btree_gist` 1.6; PostgreSQL 18.6 in the image offers 1.8.
- Clients: Npgsql 10.0.3 and its EF Core provider 10.0.3, which requires EF Core 10.0.4 or later; pgjdbc 42.7.13, HikariCP 7.1.0. `pgvector` is not in the official image: lesson 8 will need another image or a build.

## 2026-09-15 — Starting the server

- The first start of the image runs a temporary server to create the cluster, listening on the Unix socket only. `pg_isready` through the socket said "accepting connections" during that window, and the next command hit a server that was shutting down. `pg_isready -h 127.0.0.1` goes through TCP. `server.sh` and the CI service's health check use it.
- `psql` errors came out before the results of earlier statements in the saved outputs: `psql` buffers standard output, not standard error. `server.sh` runs `psql` under `stdbuf -o0`, inside the container, with both streams merged there.
- Every script runs with `TimeZone=UTC`, `DateStyle=ISO, MDY` and `lc_messages=C`, set in `PGOPTIONS`, and every query has an `ORDER BY`. `\conninfo` prints the server process ID, which changes at every run: the scripts don't use it.

## 2026-09-15 — Modeling the CI history

- A closed range `[started_at, completed_at]` for the steps made 2,798 pairs of steps of the same job overlap: GitHub's times are to the second, and a step starts the second the previous one ends. Half-open `[)` ranges fix that, but 857 of the 2,204 steps become empty ranges, which lose their bounds. The table keeps both timestamps and derives the range as a stored generated column.
- A `CHECK` whose error message included `now()` gave a different output at each run; the test rows use fixed dates.
- `WITH TIES` returned tied rows in a different order from one run to the next: an outer `ORDER BY` fixes the order.

## 2026-09-15 — Findings in Guitar Alchemist

Nothing here was reported to the project; these are notes, with the queries that reproduce them in the lessons.

- `GA.Knowledge.Service.csproj` references `GA.Business.Config.fsproj` twice, on lines 26 and 31, at commit `32f143c`. The primary key of `ga.project_refs` rejects the second one (lesson 2).
- `MusicalKnowledgeDbContext.cs` exists in three copies that differ only by their namespace, in `Common/GA.Data.EntityFramework/`, `Common/GA.Data.EntityFramework/Data/` and `Common/GA.Infrastructure/Persistence/EntityFramework/`. I found no `AddDbContext` or `UseSqlite` call for it at that commit, while services inject it.
- Its value converters store lists as joined strings and read them back with `StringSplitOptions.RemoveEmptyEntries`: an empty alternate name is lost. Three names saved, two read back (lesson 4).
- In `IconicChords.yaml`, three voicings don't play their declared pitch classes: Blackbird plays no B and adds C♯, E and A; the Hendrix voicing has no B; the Mu Major voicing, `Cadd9(no3)`, plays E (lesson 3, exercise 1).
- Package versions: `Microsoft.Extensions.Hosting` is referenced in 5 versions and `MongoDB.Driver` in 5; 16 packages have a text maximum that isn't their highest version; 13 distinct versions aren't plain numbers, including the floating `0.*` and `8.*-*` (lesson 3).
- Two projects are named `GaApi.Tests.csproj`, in `Tests/Apps/GaApi.Tests` and `Tests/GaApi.Tests`.

## 2026-09-15 — The drivers

- Npgsql: a `DateTime` with `Kind=Unspecified` didn't throw, as I expected, but was sent as `timestamp` and converted in the session's time zone: 82 runs or 59 depending on `Timezone`. A `DateTimeOffset` with an offset of −4 hours throws `ArgumentException`.
- `pg_prepared_statements` counted the counting query itself once it was prepared; a regular expression that doesn't match its own text fixed the count.
- EF Core builds a model once per context type: two configurations of the same entity in one context class, chosen by a constructor argument, gave the first model twice. One subclass per configuration.
- pgjdbc sends the JVM's time zone as the session's `TimeZone`, so `getString` on a `timestamptz` depended on the machine. `check.sh` runs Java with `-Duser.timezone=America/Toronto`.
- PowerShell 7.6 still splits `-Duser.timezone=Asia/Tokyo` at the dot: Java answered "Could not find or load main class .timezone=Asia.Tokyo". Quoted, it works.
- Npgsql refuses `Target Session Attributes=standby` with a single host: `NotSupportedException: Target Session Attributes other then Any is only supported with multiple hosts`. pgjdbc accepts `targetServerType=secondary` with one host and fails at connection time.
- One run of `l04-timings`: 478 `INSERT` commands in about a second, one `NpgsqlBatch` in 5 to 7 ms, a binary `COPY` in about 50 ms. Earlier runs the same day took up to 2.2 seconds for the `INSERT` loop.

## 2026-09-16 — Plans that give the same output at every run

- `EXPLAIN ANALYZE` on the 440,800-row step history gave different rows per node from one run to the next: parallel workers split the rows differently each time. `max_parallel_workers_per_gather = 0` for the lessons that show plans.
- The planner's estimates changed after each `ANALYZE`, which reads a random sample of 30,000 rows with the default statistics target. At 1,500, the sample is 450,000 rows, more than the table, and the estimates are exact and stable.
- The `Buffers` line split pages between `hit` and `read` depending on what the previous statements left in memory. The plan helper adds them into one number; the total didn't change across a container restart.
- PostgreSQL 18 prints `Buffers` without `BUFFERS`, row counts with two decimals, and `Index Searches`.
- `xmin` printed `-1` for the first row version: the transaction ID saved with `\gset` was taken after the `INSERT`. It is taken just before now.
- `pg_stat_user_tables` showed zero HOT updates right after the updates: statistics are sent at most once a second. `pg_stat_force_next_flush()` fixes the count.

## 2026-09-16 — Two sessions in one program

- A program can't wait for B's blocked statement to return. The C# and Java programs start it, and a third connection polls `pg_stat_activity` until B waits on a lock, with `pg_blocking_pids` naming A.
- In the deadlock example, either session could be the one cancelled, depending on which waited `deadlock_timeout` first. A has 10 seconds and B 100 ms: B always detects the cycle, and is cancelled.

## 2026-09-16 — JSON and search

- A stored generated `tsvector` whose configuration came from another generated column was refused: a generated column can't refer to another one. The configuration is a plain column, set by the `INSERT`.
- A trigram index on the 478 rows of `ga.package_refs` was never used, even with `enable_seqscan = off`: the primary key's index was cheaper. The example uses the 88,160 step names of the copied documents.
- On these documents, `jsonb_path_ops` came out slightly larger than `jsonb_ops`, 1,752 kB against 1,688 kB, the opposite of what the documentation says is usual.
- The phrase `"prepared statements"` matched `pg_prepared_statements` in this journal: the text search parser splits at underscores.

## 2026-09-16 — Functions and pgvector

- **Finding, Npgsql 10.0.3.** A single `CREATE FUNCTION … BEGIN ATOMIC SELECT …; END` in an `NpgsqlCommand` without parameters fails with `42601: syntax error at end of input`. Npgsql splits the command text at the semicolon inside the body, as it does for several statements. The same text works in an `NpgsqlBatch`, with the `Npgsql.EnableSqlRewriting` switch set to `false`, or in a command that has positional parameters. pgjdbc 42.7.13 detects `BEGIN ATOMIC` and doesn't split; a `BEGIN ATOMIC` function followed by another statement in one `execute` then fails as several commands in a prepared statement. Not reported to either project.
- The official image has no pgvector. The pgvector scripts run on `pgvector/pgvector:0.8.6-pg18-trixie`, one server at a time on port 5432; CI runs it as a second service, without a port.
- With `enable_seqscan = off`, a nearest-neighbour query filtered on triads returned no row at all, where ten were asked for: the HNSW scan returns 40 candidates, none of them a triad. `hnsw.iterative_scan = strict_order` returns the ten. I rebuilt the index five times: the 40 candidates' distances were the same each time.
- The interval-class vectors of the iconic chords show that the Elektra chord is the Petrushka chord transposed up a major third, and that the Foxy Lady chord is the inversion of the Joni Mitchell chord, whose transposition is the Debussy chord.

## 2026-09-16 — Aurora, from the documentation

- Aurora PostgreSQL 18.4 ships pgvector 0.8.2, where the course runs 0.8.6. `pageinspect` isn't in the Aurora PostgreSQL 18 extension table.
- AWS's pages disagree on Performance Insights' end of life: July 31, 2026 in the CloudWatch guide, November 30, 2025 in the Aurora User Guide's history. They also disagree on whether Database Insights defaults to Standard or Advanced mode.
- `max_standby_streaming_delay`: 30 seconds on the `Lock:Relation` page, 14,000 ms in the parameter table for Aurora PostgreSQL 14.

## To verify

- The Linux and macOS commands of lessons 1 and 4, on those systems.
- Every "On Aurora" section: `pg_read_file` and the `CONNECT` requirement for `rds_superuser`, `btree_gist` 1.6, the read-only error on a replica, TLS by default, IAM tokens with Npgsql's periodic password provider, RDS Proxy pinning with Npgsql's `DISCARD ALL` and with protocol-level prepared statements, and `pg_is_in_recovery()` on an Aurora Replica.
- Lessons 5 to 8 on Aurora: the `shared_buffers` default for Aurora PostgreSQL 18 and the reason it's larger, query plan management on 18.4, `hot_standby_feedback` holding back `VACUUM` on the writer, the `max_standby_streaming_delay` default, trusted extensions under `rds.allowed_extensions`, and pgvector 0.8.2's iterative scans.
