#!/usr/bin/env bash
# Lesson 11: logical dumps, base and incremental backups, WAL archiving and a point-in-time recovery.
# Two small clusters in the course container, next to the course server: node1 (port 5433) and node2 (5434), restored from node1's backups.
# Run as the postgres user: bash check.sh ops, or docker exec -i -u postgres pg bash -s < ops/11-backup.sh
set -u
export PATH=/usr/lib/postgresql/18/bin:$PATH PGUSER=postgres
cd /tmp
rm -rf node1 node2 archive base incremental combined learn.dump ./*.log

say() { printf '\n-- %s\n' "$*"; }
until_true() {
  for _ in $(seq 150); do
    [ "$(psql -X -Atq -p "$1" -d "$2" -c "$3" 2>/dev/null)" = t ] && return 0
    sleep 0.2
  done
  echo "timed out on port $1: $3"
}
sql() { local port=$1; shift; psql -X -p "$port" -d learn "$@" 2>&1; }
counts="SELECT (SELECT count(*) FROM ci.runs) AS runs, (SELECT count(*) FROM ci.jobs) AS jobs, (SELECT count(*) FROM ci.steps) AS steps"

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

say "A logical dump in the custom format, its table of contents, and a restore with two parallel jobs"
pg_dump -p 5433 -d learn --format=custom --file=learn.dump
# Each line of the list starts with a dump ID and two object IDs, removed here
pg_restore --list learn.dump | grep ' TABLE DATA ' | sed -E 's/^[0-9]+; [0-9]+ [0-9]+ //'
psql -X -q -p 5433 -c 'CREATE DATABASE learn_copy'
pg_restore -p 5433 -d learn_copy --jobs=2 learn.dump
psql -X -p 5433 -d learn_copy -c "$counts"
# Roles belong to the cluster, not to a database: pg_dump leaves them out, pg_dumpall --globals-only writes them
pg_dumpall -p 5433 --globals-only | grep -E '^(CREATE|ALTER) ROLE reader'

say "A full base backup, with its manifest, then new work on node1"
pg_basebackup -p 5433 -D base -c fast
ls base/backup_manifest
psql -X -q -p 5433 -d learn -c "UPDATE ci.runs SET conclusion = 'failure' WHERE run_id = (SELECT min(run_id) FROM ci.runs)"

say "An incremental backup holds only the blocks changed since the manifest it is given"
pg_basebackup -p 5433 -D incremental -c fast --incremental=base/backup_manifest
du -sk --exclude=pg_wal base incremental | awk '{ size[$2] = $1 } END { print "without WAL, the incremental backup is", (size["incremental"] * 3 < size["base"] ? "less" : "more"), "than a third of the full one" }'
pg_combinebackup base incremental -o combined
pg_verifybackup combined

say "Later: a named restore point, then a mistake"
sql 5433 -c "SELECT pg_create_restore_point('before_truncate') IS NOT NULL AS restore_point"
sql 5433 -c "TRUNCATE ci.runs CASCADE"
wal=$(psql -X -Atq -p 5433 -c 'SELECT pg_walfile_name(pg_switch_wal())')
until_true 5433 postgres "SELECT last_archived_wal >= '$wal' FROM pg_stat_archiver"
sql 5433 -c "$counts"

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

say "Clean-up"
for node in node1 node2; do pg_ctl -D $node -m fast -w stop > /dev/null; done
rm -rf node1 node2 archive base incremental combined learn.dump ./*.log
echo "done"
