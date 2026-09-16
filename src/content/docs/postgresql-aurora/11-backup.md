---
title: "11. Backup, restore and upgrades"
description: Backups in PostgreSQL 18 for SQL Server developers — pg_dump's custom format and a parallel pg_restore, roles with pg_dumpall, base backups with manifests, incremental backups and pg_combinebackup, WAL archiving and a point-in-time recovery to a named restore point, then a major upgrade from 17 to 18 with pg_upgrade --swap and the statistics it keeps — and what Aurora does instead.
sidebar:
  order: 11
---

The lesson's scripts are [`ops/11-backup.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh) and [`ops/11-upgrade.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh), and the exercises are in [`ops/11-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh). As in [lesson 10](../10-replication/), they start small clusters inside the course container, and `check.sh ops` compares their output with the files of the same names in [`expected`](https://github.com/spareilleux/learn/tree/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected):

```bash
bash server.sh sh < ops/11-backup.sh
```

| SQL Server | PostgreSQL |
|---|---|
| `BACKUP DATABASE`, a `.bak` file | `pg_dump`, a logical dump of one database; `pg_basebackup`, a physical copy of the cluster |
| logins in `master` | roles, dumped by `pg_dumpall --globals-only` |
| differential backup | incremental backup (`pg_basebackup --incremental`), combined with `pg_combinebackup` |
| log backups | WAL archiving (`archive_command`) |
| `RESTORE … WITH STOPAT`, `STOPATMARK` | `recovery_target_time`, `recovery_target_name`, `recovery_target_xid` |
| `RESTORE VERIFYONLY` | `pg_verifybackup` |
| in-place upgrade by Setup | a new cluster, and `pg_upgrade` from the old one |

## Logical dumps

A cluster with the course schema, whose finished WAL segments are archived; the settings are explained further down ([lines 21-33](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L21-L33)):

```bash
say "node1: every finished WAL segment is copied to /tmp/archive, and the WAL summarizer runs for incremental backups"
initdb -D node1 --auth=trust > /dev/null
mkdir archive
cat >> node1/postgresql.conf <<'EOF'
shared_buffers = 32MB
archive_mode = on
archive_command = 'test ! -f /tmp/archive/%f && cp %p /tmp/archive/%f'
summarize_wal = on
EOF
pg_ctl -D node1 -l node1.log -o "-p 5433" -w start > /dev/null || exit 1
psql -X -q -p 5433 -c 'CREATE DATABASE learn' -c 'CREATE ROLE reader NOLOGIN'
psql -X -q -p 5433 -d learn -c '\o /dev/null' -c '\i /course/sql/schema.sql' -c 'GRANT USAGE ON SCHEMA ci TO reader'
sql 5433 -c "$counts"
```

```text

-- node1: every finished WAL segment is copied to /tmp/archive, and the WAL summarizer runs for incremental backups
 runs | jobs | steps
------+------+-------
  125 |  315 |  2204
(1 row)
```

[`pg_dump`](https://www.postgresql.org/docs/18/app-pgdump.html) writes one database as the SQL that recreates it, from a single snapshot, while other sessions keep working. Its *custom* format, `--format=custom`, is compressed and lets [`pg_restore`](https://www.postgresql.org/docs/18/app-pgrestore.html) choose what to restore and run in parallel ([lines 35-43](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L35-L43)):

```bash
say "A logical dump in the custom format, its table of contents, and a restore with two parallel jobs"
pg_dump -p 5433 -d learn --format=custom --file=learn.dump
# Each line of the list starts with a dump ID and two object IDs, removed here
pg_restore --list learn.dump | grep ' TABLE DATA ' | sed -E 's/^[0-9]+; [0-9]+ [0-9]+ //'
psql -X -q -p 5433 -c 'CREATE DATABASE learn_copy'
pg_restore -p 5433 -d learn_copy --jobs=2 learn.dump
psql -X -p 5433 -d learn_copy -c "$counts"
# Roles belong to the cluster, not to a database: pg_dump leaves them out, pg_dumpall --globals-only writes them
pg_dumpall -p 5433 --globals-only | grep -E '^(CREATE|ALTER) ROLE reader'
```

```text
-- A logical dump in the custom format, its table of contents, and a restore with two parallel jobs
TABLE DATA ci jobs postgres
TABLE DATA ci runs postgres
TABLE DATA ci steps postgres
TABLE DATA ga iconic_chords postgres
TABLE DATA ga package_refs postgres
TABLE DATA ga project_refs postgres
TABLE DATA ga projects postgres
 runs | jobs | steps
------+------+-------
  125 |  315 |  2204
(1 row)

CREATE ROLE reader;
ALTER ROLE reader WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
```

- `pg_restore --list` prints the dump's table of contents, one line per object. Saved to a file and edited, it can be passed back with `--use-list` to restore only some objects, in a chosen order.
- `--jobs=2` restores with two connections: the data of several tables, then their indexes, at the same time. It needs the custom or the directory format.
- A dump doesn't contain roles, which belong to the cluster: the `GRANT` to `reader` is in it, the role isn't. [`pg_dumpall --globals-only`](https://www.postgresql.org/docs/18/app-pg-dumpall.html) writes the roles and tablespaces.

A dump is a copy at one moment. What happened after it is lost, and restoring a large database means reloading all its data and rebuilding every index.

## Base backups and incremental backups

A physical backup copies the cluster's files, like a standby in lesson 10 without the replication. [`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html) writes a `backup_manifest` next to them, with a checksum per file. Since PostgreSQL 17, a later backup can copy only what changed since that manifest ([lines 45-54](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L45-L54)):

```bash
say "A full base backup, with its manifest, then new work on node1"
pg_basebackup -p 5433 -D base -c fast
ls base/backup_manifest
psql -X -q -p 5433 -d learn -c "UPDATE ci.runs SET conclusion = 'failure' WHERE run_id = (SELECT min(run_id) FROM ci.runs)"

say "An incremental backup holds only the blocks changed since the manifest it is given"
pg_basebackup -p 5433 -D incremental -c fast --incremental=base/backup_manifest
du -sk --exclude=pg_wal base incremental | awk '{ size[$2] = $1 } END { print "without WAL, the incremental backup is", (size["incremental"] * 3 < size["base"] ? "less" : "more"), "than a third of the full one" }'
pg_combinebackup base incremental -o combined
pg_verifybackup combined
```

```text
-- A full base backup, with its manifest, then new work on node1
base/backup_manifest

-- An incremental backup holds only the blocks changed since the manifest it is given
without WAL, the incremental backup is less than a third of the full one
backup successfully verified
```

- `--incremental` needs [`summarize_wal = on`](https://www.postgresql.org/docs/18/runtime-config-wal.html#GUC-SUMMARIZE-WAL) on the server: the WAL summarizer records which blocks each stretch of WAL changed.
- Without their WAL, the incremental backup is less than a third of the full one: only one `UPDATE` ran between the two.
- An incremental backup can't be started directly. [`pg_combinebackup`](https://www.postgresql.org/docs/18/app-pgcombinebackup.html) "is used to reconstruct a synthetic full backup from an incremental backup and the earlier backups upon which it depends".
- [`pg_verifybackup`](https://www.postgresql.org/docs/18/app-pgverifybackup.html) checks the result against its manifest, and that the WAL it needs can be parsed.

The documentation adds a warning: "PostgreSQL has no built-in mechanism to figure out which backups are still needed as a basis for restoring later incremental backups" ([continuous archiving](https://www.postgresql.org/docs/18/continuous-archiving.html#BACKUP-INCREMENTAL-BACKUP)). Deleting a full backup breaks every incremental one built on it.

## WAL archiving and point-in-time recovery

A base backup plus every WAL segment written since is enough to replay the cluster up to any moment: [point-in-time recovery](https://www.postgresql.org/docs/18/continuous-archiving.html). On `node1`, `archive_mode = on` and `archive_command` copy each finished segment to `/tmp/archive`. `%p` is the segment's path and `%f` its name; `test ! -f` refuses to overwrite an archived file, the documentation's own example. In production, the archive lives on another machine.

A named restore point, then a mistake ([lines 56-61](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L56-L61)):

```bash
say "Later: a named restore point, then a mistake"
sql 5433 -c "SELECT pg_create_restore_point('before_truncate') IS NOT NULL AS restore_point"
sql 5433 -c "TRUNCATE ci.runs CASCADE"
wal=$(psql -X -Atq -p 5433 -c 'SELECT pg_walfile_name(pg_switch_wal())')
until_true 5433 postgres "SELECT last_archived_wal >= '$wal' FROM pg_stat_archiver"
sql 5433 -c "$counts"
```

```text
-- Later: a named restore point, then a mistake
 restore_point
---------------
 t
(1 row)

NOTICE:  truncate cascades to table "jobs"
NOTICE:  truncate cascades to table "steps"
TRUNCATE TABLE
 runs | jobs | steps
------+------+-------
    0 |    0 |     0
(1 row)
```

- [`pg_create_restore_point`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-BACKUP) writes a name into the WAL, like a marked transaction for SQL Server's `STOPATMARK`.
- `TRUNCATE … CASCADE` empties the three CI tables.
- `pg_switch_wal()` ends the current segment, so that it's archived now instead of when it fills up; [`pg_stat_archiver`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-ARCHIVER-VIEW) tells when.

The recovery, on `node2`, from the combined backup ([lines 63-78](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L63-L78)):

```bash
say "Point-in-time recovery on node2: the combined backup, the archived WAL, and a target"
cp -r combined node2
chmod 700 node2
cat >> node2/postgresql.conf <<'EOF'
archive_mode = off
restore_command = 'cp /tmp/archive/%f %p'
recovery_target_name = 'before_truncate'
recovery_target_action = 'promote'
EOF
touch node2/recovery.signal
pg_ctl -D node2 -l node2.log -o "-p 5434" -w start > /dev/null || exit 1
until_true 5434 postgres "SELECT NOT pg_is_in_recovery()"
grep -o 'recovery stopping at restore point "[a-z_]*"' node2.log
sql 5434 -c "$counts"
sql 5434 -c "SELECT conclusion FROM ci.runs ORDER BY run_id LIMIT 1"
sql 5434 -c "SELECT substr(pg_walfile_name(pg_current_wal_lsn()), 1, 8) AS timeline"
```

```text
-- Point-in-time recovery on node2: the combined backup, the archived WAL, and a target
recovery stopping at restore point "before_truncate"
 runs | jobs | steps
------+------+-------
  125 |  315 |  2204
(1 row)

 conclusion
------------
 failure
(1 row)

 timeline
----------
 00000002
(1 row)
```

- `recovery.signal` starts the server in recovery. `restore_command` fetches archived segments, the reverse of `archive_command`.
- [`recovery_target_name`](https://www.postgresql.org/docs/18/runtime-config-wal.html#RUNTIME-CONFIG-WAL-RECOVERY-TARGET) stops the replay at the restore point; `recovery_target_time`, `recovery_target_xid` and `recovery_target_lsn` are the other targets. `recovery_target_action = 'promote'` opens the server for writes when it gets there.
- The three tables are back, with the `UPDATE` made between the two backups: `failure`. The recovered server continues on timeline 2, as after a promotion in lesson 10.
- `archive_mode = off` on `node2`: the copy mustn't write its segments into `node1`'s archive.

## A major upgrade with pg_upgrade

SQL Server's Setup upgrades an instance in place. PostgreSQL's major versions change the format of the system catalogs, so an upgrade creates a new cluster with the new version's `initdb`, and [`pg_upgrade`](https://www.postgresql.org/docs/18/pgupgrade.html) moves the databases into it: it dumps and restores the schema, and reuses the data files, whose format major versions rarely change. Minor releases, 18.5 to 18.6, only need the new binaries.

[`ops/11-upgrade.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh) needs PostgreSQL 17's binaries next to 18's. The image already uses the PostgreSQL project's [apt repository](https://wiki.postgresql.org/wiki/Apt), so `check.sh` installs them as root before running the script:

```bash
# Needs the PostgreSQL 17 binaries in the course container, installed first as root (check.sh does it):
#   docker exec pg sh -c 'apt-get update -qq && apt-get install -qq -y --no-install-recommends postgresql-17'
```

A PostgreSQL 17 cluster with the runs, their statistics, and extended statistics from [lesson 5](../05-indexes/) ([lines 14-36](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh#L14-L36)):

```bash
say "A PostgreSQL 17 cluster, with a table, its statistics, and extended statistics"
$old/initdb -D pg17 --auth=trust > /dev/null
$old/pg_ctl -D pg17 -l pg17.log -o "-p 5436" -w start > /dev/null || exit 1
psql -X -q -p 5436 -c 'CREATE DATABASE learn'
sql 5436 -q <<'EOF'
CREATE SCHEMA ci;
CREATE TABLE ci.runs (
    run_id bigint PRIMARY KEY, workflow_name text NOT NULL, event text NOT NULL, conclusion text,
    head_branch text NOT NULL, created_at timestamptz NOT NULL
);
INSERT INTO ci.runs
SELECT r."databaseId", r."workflowName", r.event, r.conclusion, r."headBranch", r."createdAt"
FROM jsonb_to_recordset(pg_read_file('/course/data/runs.json')::jsonb) AS r(
    "databaseId" bigint, "workflowName" text, event text, conclusion text, "headBranch" text, "createdAt" timestamptz);
CREATE STATISTICS ci.runs_workflow_event (dependencies) ON workflow_name, event FROM ci.runs;
ANALYZE ci.runs;
EOF
# The major version only: the minor one moves with the Debian packages
sql 5436 -c "SELECT current_setting('server_version_num')::int / 10000 AS version, current_setting('data_checksums') AS checksums"
statistics="SELECT (SELECT count(*) FROM pg_stats WHERE schemaname = 'ci') AS column_stats,
                   (SELECT count(*) FROM pg_stats_ext WHERE statistics_schemaname = 'ci') AS extended_stats"
sql 5436 -c "$statistics"
$old/pg_ctl -D pg17 -m fast -w stop > /dev/null
```

```text

-- A PostgreSQL 17 cluster, with a table, its statistics, and extended statistics
 version | checksums
---------+-----------
      17 | off
(1 row)

 column_stats | extended_stats
--------------+----------------
            6 |              1
(1 row)
```

The table is simpler than `schema.sql`'s, which uses a virtual generated column, new in 18. The script prints the major version only: the minor one follows the Debian packages.

A first attempt, with `--check`, which only runs the checks ([lines 38-42](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh#L38-L42)):

```bash
say "A new 18 cluster: initdb 18 turns data checksums on, 17 left them off"
$new/initdb -D pg18 --auth=trust > /dev/null
$new/pg_upgrade --old-bindir=$old --new-bindir=$new --old-datadir=pg17 --new-datadir=pg18 --check 2>&1 | grep -v '^$'
rm -rf pg18
$new/initdb -D pg18 --auth=trust --no-data-checksums > /dev/null
```

```text
-- A new 18 cluster: initdb 18 turns data checksums on, 17 left them off
Performing Consistency Checks
-----------------------------
Checking cluster versions                                     ok
old cluster does not use data checksums but the new one does
Failure, exiting
```

`initdb` 18 enables data checksums by default, and 17 didn't. The release notes point to the way out: "Checksums can be disabled with the new initdb option `--no-data-checksums`. pg_upgrade requires matching cluster checksum settings". The new cluster is created again without them.

The upgrade ([lines 44-51](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh#L44-L51)):

```bash
say "The upgrade: --swap moves the old data directory into the new cluster, so the 17 cluster can't be started again"
$new/pg_upgrade --old-bindir=$old --new-bindir=$new --old-datadir=pg17 --new-datadir=pg18 --swap 2>&1 | grep -v '^$'
$new/pg_ctl -D pg18 -l pg18.log -o "-p 5436" -w start > /dev/null || exit 1
sql 5436 -c "SELECT current_setting('server_version_num')::int / 10000 AS version, count(*) AS runs FROM ci.runs"
# Column statistics came across; extended statistics didn't
sql 5436 -c "$statistics"
$new/vacuumdb -p 5436 --all --analyze-only --missing-stats-only 2>&1
sql 5436 -c "$statistics"
```

```text
Performing Consistency Checks
-----------------------------
Checking cluster versions                                     ok
Checking database connection settings                         ok
Checking database user is the install user                    ok
Checking for prepared transactions                            ok
Checking for contrib/isn with bigint-passing mismatch         ok
Checking for valid logical replication slots                  ok
Checking for subscription state                               ok
Checking data type usage                                      ok
Checking for objects affected by Unicode update               ok
Checking for not-null constraint inconsistencies              ok
Creating dump of global objects                               ok
Creating dump of database schemas                             ok
Checking for presence of required libraries                   ok
Checking database user is the install user                    ok
Checking for prepared transactions                            ok
Checking for new cluster tablespace directories               ok
If pg_upgrade fails after this point, you must re-initdb the
new cluster before continuing.
Performing Upgrade
------------------
Setting locale and encoding for new cluster                   ok
Analyzing all rows in the new cluster                         ok
Freezing all rows in the new cluster                          ok
Deleting files from new pg_xact                               ok
Copying old pg_xact to new server                             ok
Setting oldest XID for new cluster                            ok
Setting next transaction ID and epoch for new cluster         ok
Deleting files from new pg_multixact/offsets                  ok
Copying old pg_multixact/offsets to new server                ok
Deleting files from new pg_multixact/members                  ok
Copying old pg_multixact/members to new server                ok
Setting next multixact ID and offset for new cluster          ok
Resetting WAL archives                                        ok
Setting frozenxid and minmxid counters in new cluster         ok
Restoring global objects in the new cluster                   ok
Restoring database schemas in the new cluster                 ok
Adding ".old" suffix to old "global/pg_control"               ok
Because "swap" mode was used, the old cluster can no longer be
safely started.
Swapping data directories                                     ok
Setting next OID for new cluster                              ok
Sync data directory to disk                                   ok
Creating script to delete old cluster                         ok
Checking for extension updates                                ok
Upgrade Complete
----------------
Some statistics are not transferred by pg_upgrade.
Once you start the new server, consider running these two commands:
    /usr/lib/postgresql/18/bin/vacuumdb --all --analyze-in-stages --missing-stats-only
    /usr/lib/postgresql/18/bin/vacuumdb --all --analyze-only
Running this script will delete the old cluster's data files:
    ./delete_old_cluster.sh
 version | runs
---------+------
      18 |  125
(1 row)

 column_stats | extended_stats
--------------+----------------
            6 |              0
(1 row)

vacuumdb: vacuuming database "learn"
vacuumdb: vacuuming database "postgres"
vacuumdb: vacuuming database "template1"
 column_stats | extended_stats
--------------+----------------
            6 |              1
(1 row)
```

- `pg_upgrade` checks, dumps the old schema, restores it into the new cluster, then brings over the transaction IDs and the data files.
- `--swap`, new in PostgreSQL 18, moves the old cluster's data directories into the new one instead of copying or linking files; the documentation says it "can outperform `--link`, `--clone`, `--copy`, and `--copy-file-range`, especially on clusters with many relations". The price is in the output: "the old cluster can no longer be safely started". Without a backup, there is no way back.
- Also new in 18, `pg_upgrade` "will transfer most optimizer statistics from the old cluster to the new cluster": the six column statistics are there, and the server can plan well from its first query. The extended statistics aren't.
- [`vacuumdb --analyze-only --missing-stats-only`](https://www.postgresql.org/docs/18/app-vacuumdb.html), another PostgreSQL 18 option, analyzes only what has no statistics, and brings the extended statistics back. `pg_upgrade`'s own advice is to run it with `--analyze-in-stages` first.

## On Aurora

*To verify: nothing in this section ran on AWS.* Aurora manages backups itself, and its restores create new clusters.

- **Continuous backups.** "Aurora automated backups are continuous and incremental, so you can quickly restore to any point within the backup retention period", which is "from 1–35 days", one day by default; "you can't disable automated backups on Aurora" ([backups](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Backups.html)). There is no `archive_command` to set: "Amazon Aurora uploads log records for DB clusters to Amazon S3 continuously" ([point-in-time recovery](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-pitr.html)).
- **Point-in-time recovery** creates a new DB cluster, as `node2` was a new cluster here. The latest restorable time "is typically within 5 minutes of the current time". Manual snapshots keep data beyond the retention period: "Aurora DB cluster snapshots don't expire".
- **No rewind for PostgreSQL.** Backtrack, which rewinds a cluster in place, is for Aurora MySQL only ([Backtrack](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html)).
- **Clones.** "Aurora uses a copy-on-write protocol to create a clone", which shares storage with its source until either changes it; "you can create up to 15 clones with copy-on-write protocol", in the same Region ([cloning](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Clone.html)). A clone is the cheap way to test a restore or an upgrade on real data.
- **Dumps and exports.** `pg_dump` and `pg_restore` work from a client machine; I found the AWS procedure only in the [RDS for PostgreSQL guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Procedural.Importing.EC2.html), not in Aurora's. The [`aws_s3`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/postgresql-s3-export.html) extension exports a query's result straight to S3 with `aws_s3.query_export_to_s3`.
- **Major upgrades use pg_upgrade.** "To safely upgrade the DB instances that make up your cluster, Aurora PostgreSQL uses the pg_upgrade utility" ([major version upgrades](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html)). Before it: "Drop logical replication slots. The upgrade process can't proceed if the Aurora PostgreSQL DB cluster is using any logical replication slots". Aurora takes a snapshot named with a `preupgrade` prefix.
- **Statistics: a contradiction to check.** The same page says "Optimizer statistics aren't transferred during a major version upgrade, so you need to regenerate all statistics", while `pg_upgrade` 18 transfers them, as this lesson showed. Whether an upgrade to Aurora PostgreSQL 18 keeps them isn't documented: run `ANALYZE` anyway.
- **Blue/green deployments** copy a cluster to a green environment kept in sync with logical replication, where the upgrade runs, then switch over; "the switchover typically takes under a minute with no data loss" ([overview](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-overview.html)). The limits are those of logical replication: "Data definition language (DDL) statements, such as CREATE TABLE and CREATE SCHEMA, aren't replicated from the blue environment to the green environment" ([considerations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html)). The [version table](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.BlueGreenDeployments.html) stops at Aurora PostgreSQL 17.
- **Minor versions** can be applied with zero-downtime patching (ZDP), where "application sessions are maintained except for those with dropped connections", with a throughput drop that "typically lasts only for a few seconds or at most, approximately one minute" ([minor upgrades](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MinorUpgrade.html)).

## Key takeaways

- `pg_dump` copies one database at one moment; roles come from `pg_dumpall --globals-only`.
- The custom format lets `pg_restore` pick objects and restore in parallel.
- Base backups have manifests; incremental backups need `summarize_wal`, the backups they depend on, and `pg_combinebackup`.
- WAL archiving plus a base backup gives point-in-time recovery, to a time, a named point, a transaction or an LSN.
- A major upgrade is a new cluster: checksums must match, `--swap` is fast and one-way, and 18 keeps most statistics.
- On Aurora, backups are continuous, restores and clones create new clusters, and upgrades still run `pg_upgrade`.

## Exercises

The solutions are in [`ops/11-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh), on a cluster like `node1` ([lines 19-28](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh#L19-L28)).

1. Someone deletes every row of `ga.iconic_chords`. Bring back that table's rows from a custom-format dump, without touching the other tables.

<details>
<summary>Solution</summary>

[Lines 30-34](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh#L30-L34):

```bash
say "Exercise 1: the iconic chords are deleted by mistake; only that table's data comes back from the dump"
pg_dump -p 5433 -d learn --format=custom --file=learn.dump
sql 5433 -c "DELETE FROM ga.iconic_chords"
pg_restore -p 5433 -d learn --data-only --table=iconic_chords learn.dump
sql 5433 -c "SELECT count(*) AS chords FROM ga.iconic_chords"
```

```text
-- Exercise 1: the iconic chords are deleted by mistake; only that table's data comes back from the dump
DELETE 17
 chords
--------
     17
(1 row)
```

`--table` selects the table and `--data-only` restores its rows into the existing table, without trying to create it again. The rows are those of the dump: whatever changed in that table after the dump is lost, which point-in-time recovery avoids.

</details>

2. After a base backup, an `UPDATE` marks the last run `cancelled`, then a transaction deletes every step. Recover a copy that has the `UPDATE` but not the `DELETE`, using the transaction's ID as the target.

<details>
<summary>Solution</summary>

[Lines 36-55](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh#L36-L55):

```bash
say "Exercise 2: a recovery that stops before the transaction of a DELETE, found by its ID"
pg_basebackup -p 5433 -D base -c fast
sql 5433 -q -c "UPDATE ci.runs SET conclusion = 'cancelled' WHERE run_id = (SELECT max(run_id) FROM ci.runs)"
xid=$(psql -X -Atq -p 5433 -d learn -c "BEGIN" -c "DELETE FROM ci.steps" -c "SELECT pg_current_xact_id()" -c "COMMIT" | sed -n 1p)
wal=$(psql -X -Atq -p 5433 -c 'SELECT pg_walfile_name(pg_switch_wal())')
until_true 5433 postgres "SELECT last_archived_wal >= '$wal' FROM pg_stat_archiver"
cp -r base node2
chmod 700 node2
cat >> node2/postgresql.conf <<EOF
archive_mode = off
restore_command = 'cp /tmp/archive/%f %p'
recovery_target_xid = '$xid'
recovery_target_inclusive = off
recovery_target_action = 'promote'
EOF
touch node2/recovery.signal
pg_ctl -D node2 -l node2.log -o "-p 5434" -w start > /dev/null || exit 1
until_true 5434 postgres "SELECT NOT pg_is_in_recovery()"
grep -o 'recovery stopping before commit of transaction' node2.log
sql 5434 -c "SELECT (SELECT count(*) FROM ci.steps) AS steps, (SELECT conclusion FROM ci.runs ORDER BY run_id DESC LIMIT 1) AS last_run"
```

```text
-- Exercise 2: a recovery that stops before the transaction of a DELETE, found by its ID
recovery stopping before commit of transaction
 steps | last_run
-------+-----------
  2204 | cancelled
(1 row)
```

[`pg_current_xact_id()`](https://www.postgresql.org/docs/18/functions-info.html#FUNCTIONS-PG-SNAPSHOT) gives the transaction's ID from inside it. `recovery_target_xid` stops at that transaction's commit, and `recovery_target_inclusive = off` stops just before it: the steps are there, and the run is `cancelled`. In practice, the ID of a bad transaction is rarely known; a time from the application's logs, with `recovery_target_time`, is the usual target.

</details>

## Sources

- PostgreSQL 18 documentation: [backup and restore](https://www.postgresql.org/docs/18/backup.html), [SQL dump](https://www.postgresql.org/docs/18/backup-dump.html), [continuous archiving and PITR](https://www.postgresql.org/docs/18/continuous-archiving.html), [`pg_dump`](https://www.postgresql.org/docs/18/app-pgdump.html), [`pg_restore`](https://www.postgresql.org/docs/18/app-pgrestore.html), [`pg_dumpall`](https://www.postgresql.org/docs/18/app-pg-dumpall.html), [`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html), [`pg_combinebackup`](https://www.postgresql.org/docs/18/app-pgcombinebackup.html), [`pg_verifybackup`](https://www.postgresql.org/docs/18/app-pgverifybackup.html), [WAL settings and recovery targets](https://www.postgresql.org/docs/18/runtime-config-wal.html), [backup control functions](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-BACKUP), [`pg_upgrade`](https://www.postgresql.org/docs/18/pgupgrade.html), [upgrading a cluster](https://www.postgresql.org/docs/18/upgrading.html), [`vacuumdb`](https://www.postgresql.org/docs/18/app-vacuumdb.html), [PostgreSQL 18 release notes](https://www.postgresql.org/docs/18/release-18.html), [PostgreSQL 17 release notes](https://www.postgresql.org/docs/17/release-17.html); the [apt repository](https://wiki.postgresql.org/wiki/Apt)
- SQL Server: [backup overview](https://learn.microsoft.com/sql/relational-databases/backup-restore/backup-overview-sql-server), [restoring to a point in time](https://learn.microsoft.com/sql/relational-databases/backup-restore/restore-a-sql-server-database-to-a-point-in-time-full-recovery-model), [choosing an upgrade method](https://learn.microsoft.com/sql/database-engine/install-windows/choose-a-database-engine-upgrade-method)
- AWS: [backups](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Backups.html), [point-in-time recovery](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-pitr.html), [Backtrack](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html), [cloning](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Clone.html), [importing with pg_dump on RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Procedural.Importing.EC2.html), [exporting to S3](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/postgresql-s3-export.html), [major version upgrades](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html), [minor version upgrades](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MinorUpgrade.html), [blue/green overview](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-overview.html), [considerations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html) and [versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.BlueGreenDeployments.html), all read on 2026-09-16
