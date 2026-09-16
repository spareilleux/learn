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
- [x] Lesson 9: partitioning
- [x] Lesson 10: replication, on three clusters inside the course container
- [x] Lesson 11: backups, point-in-time recovery and `pg_upgrade`
- [x] Lesson 12: Aurora, from the documentation, and a failover from C# and Java
- [x] Lesson 13: migrating from SQL Server, by hand, by program and with pgloader; DMS, Babelfish and costs from the documentation
- [x] The course is complete
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

## 2026-09-16 — Partitioning

- A primary key on `id` alone is refused on a table partitioned by `started_at`; with `(id, started_at)` it's accepted, and checked partition by partition.
- `DETACH PARTITION … CONCURRENTLY` isn't allowed while the table has a default partition, and a default partition that holds a row for October blocks creating October's partition.
- Hash partitioning on 64 job names gave one partition 2.1 times the rows of another.
- A procedure that printed a `regclass` after `DROP TABLE` printed the bare OID: the notice has to come before the drop.

## 2026-09-16 — Several servers in one container

- The course runs one container at a time. Lessons 10 and 11 start small clusters inside it with `initdb` and `pg_ctl`, on ports 5433 to 5436, with `shared_buffers = 32MB`; CI runs the same scripts inside its service container.
- A script rewritten on Windows through Python's text mode got CRLF line endings, and `bash -s` in the container failed on its first lines. Files written with `newline=''` keep LF.
- The image's clusters put their Unix socket in `/var/run/postgresql`, not `/tmp`: with `PGHOST=/tmp`, every `psql` failed, and each wait loop timed out after 30 seconds.
- `SET statement_timeout = '2s'` didn't end an `INSERT` waiting for a synchronous standby that was stopped: it waited ten minutes, until I cancelled it with `pg_cancel_backend`. The script now cancels the wait from another session; the warning says the transaction "has already committed locally".
- `pg_rewind` first failed with `could not open file "node1/pg_wal/000000010000000000000002"`: the old primary had recycled the segment it needed. `wal_keep_size = 128MB` keeps it.
- PostgreSQL 18's conflict statistics count the `insert_exists` conflict of a subscriber that had its own row; the apply worker retries until the row is deleted.

## 2026-09-16 — Backups and pg_upgrade

- `pg_upgrade --check` from a 17 cluster to a new 18 cluster stopped at "old cluster does not use data checksums but the new one does": `initdb` 18 enables checksums by default. `--no-data-checksums` on the new cluster fixes it.
- `pg_upgrade` 18 kept the six column statistics of `ci.runs`, not its extended statistics; `vacuumdb --analyze-only --missing-stats-only` rebuilt them.
- The upgrade needs PostgreSQL 17's binaries: `check.sh` installs `postgresql-17` from the apt repository the image already uses, so the old side's minor version isn't pinned. The outputs show the major version only.

## 2026-09-16 — A failover from the drivers

- `ops/12-cluster.sh` starts a primary and a standby in the course container, published on ports 5433 and 5434. The programs stop the primary through `COPY … TO PROGRAM 'pg_ctl … -W stop'` and promote the standby with `pg_promote()`.
- On the connection opened before the failure, pgjdbc reports `57P01`, "terminating connection due to administrator command", and Npgsql "Exception while reading from stream" on Windows through Docker Desktop, but a `PostgresException` with `57P01` in CI on Linux: the first CI run failed on that line. The C# program now prints the connection's `FullState`, `Broken` on both.
- Both drivers cache host states for 10 seconds by default, yet a write right after the promotion found the new primary in both. I haven't traced why in their source.

## 2026-09-16 — Aurora, lessons 9 to 12

- The maximum cluster volume: 256 TiB for Aurora PostgreSQL 15.13, 16.9, 17.5 and higher in the quotas page's version table, 128 TiB in the same page's quota table, 256 TiB without condition in the overview.
- The release calendar gives PostgreSQL 18 a "community release date" of February 26, 2026, the date of 18.3; PostgreSQL 18.0 came out on September 25, 2025.
- The major version upgrade page says optimizer statistics aren't transferred, while `pg_upgrade` 18 transfers most of them.
- Blue/green deployments and zero-ETL have no Aurora PostgreSQL 18 column in their version tables yet; RDS Proxy has one, from 18.3.
- The AWS Advanced .NET Data Provider Wrapper exists, 2.2.0 on GitHub, with an Npgsql dialect, but the Aurora User Guide's list of AWS drivers doesn't mention it.

## 2026-09-16 — Migrating from SQL Server

- The course is complete: 13 lessons. SQL Server 2025 CU9 started in a few seconds in its container and used about 450 MB at rest; CI runs it as a service container next to PostgreSQL.
- `sqlcmd` 18.6 (`mssql-tools18` in the image) dropped every result that followed an uncaught error in a script run with `-i`, when the error was the first statement of a batch that came after a batch with results; `-Q` with the same statements printed them. The scripts catch their errors with `TRY … CATCH`.
- `Microsoft.Data.SqlClient` 7.0.3 threw `Globalization Invariant Mode is not supported.` on `OpenAsync` in the course's C# project, which sets `InvariantGlobalization`. The migration program has its own project.
- Npgsql truncated `datetimeoffset(7)` ticks to microseconds (`.9999999` to `.999999`); pgloader rounded them (`10:06:00.9999999 -04:00` to `14:06:01`).
- pgloader, image built from `231ab86`, turned a `money` value of `0.0125` into `0.01`, without error or warning: it reads `money` with `convert(varchar(40), [col], 0)`, and style 0 keeps two decimals ([`mssql-schema.lisp`, lines 212-217](https://github.com/dimitri/pgloader/blob/231ab86778ca5ffd7de40878714760c8b4860cdf/src/sources/mssql/mssql-schema.lisp#L212-L217)). It also left out the `CHECK` constraint and turned `INCLUDE (Conclusion)` into a key column.
- SQL Server's `IDENT_CURRENT` was 6 with three rows: two failed inserts and a deleted row had used values.
- AWS documentation read the same day: DMS doesn't list SQL Server 2025 as a source; Babelfish's parameter table and collations page give two different default server collations, and the collations page still says PostgreSQL doesn't support `LIKE` on nondeterministic collations; the open-source Babelfish stops at PostgreSQL 17.7 and has no container image.
- Microsoft's SQL Server 2025 pricing web page refused scripted requests; the prices come from its PDF pricing sheet.

## To verify

- The Linux and macOS commands of lessons 1 and 4, on those systems.
- Every "On Aurora" section: `pg_read_file` and the `CONNECT` requirement for `rds_superuser`, `btree_gist` 1.6, the read-only error on a replica, TLS by default, IAM tokens with Npgsql's periodic password provider, RDS Proxy pinning with Npgsql's `DISCARD ALL` and with protocol-level prepared statements, and `pg_is_in_recovery()` on an Aurora Replica.
- Lessons 5 to 8 on Aurora: the `shared_buffers` default for Aurora PostgreSQL 18 and the reason it's larger, query plan management on 18.4, `hot_standby_feedback` holding back `VACUUM` on the writer, the `max_standby_streaming_delay` default, trusted extensions under `rds.allowed_extensions`, and pgvector 0.8.2's iterative scans.
- Lessons 9 to 12 on Aurora: pg_partman 5.4.3 on 18.4, logical replication after `rds.logical_replication`, statistics after a major upgrade to 18, blue/green deployments and zero-ETL on 18, Aurora Serverless ranges and auto-pause on 18, whether a pool's idle connections prevent auto-pause, RDS Proxy with cancel requests, and a failover's duration as seen from Npgsql and pgjdbc.
- Why Npgsql and pgjdbc found the promoted standby right away despite their 10-second host state caches.
- Lesson 13 on AWS: DMS with a SQL Server 2025 source, whether DMS validation reports `datetimeoffset(7)` values truncated to microseconds, Babelfish's default server collation and its handling of this lesson's seven behaviours, the prices of the AWS Price List published on 2026-09-11, and whether RDS bills a 2-vCPU SQL Server instance for 4 license vCPUs.
