#!/usr/bin/env bash
# Lesson 11, exercises: restoring one table from a dump, and a recovery that stops just before a transaction.
# Two small clusters in the course container: node1 (port 5433) and node2 (5434). Run as the postgres user: bash check.sh ops
set -u
export PATH=/usr/lib/postgresql/18/bin:$PATH PGUSER=postgres
cd /tmp
rm -rf node1 node2 archive base learn.dump ./*.log

say() { printf '\n-- %s\n' "$*"; }
until_true() {
  for _ in $(seq 150); do
    [ "$(psql -X -Atq -p "$1" -d "$2" -c "$3" 2>/dev/null)" = t ] && return 0
    sleep 0.2
  done
  echo "timed out on port $1: $3"
}
sql() { local port=$1; shift; psql -X -p "$port" -d learn "$@" 2>&1; }

initdb -D node1 --auth=trust > /dev/null
mkdir archive
cat >> node1/postgresql.conf <<'EOF'
shared_buffers = 32MB
archive_mode = on
archive_command = 'test ! -f /tmp/archive/%f && cp %p /tmp/archive/%f'
EOF
pg_ctl -D node1 -l node1.log -o "-p 5433" -w start > /dev/null || exit 1
psql -X -q -p 5433 -c 'CREATE DATABASE learn'
psql -X -q -p 5433 -d learn -c '\o /dev/null' -c '\i /course/sql/schema.sql'

say "Exercise 1: the iconic chords are deleted by mistake; only that table's data comes back from the dump"
pg_dump -p 5433 -d learn --format=custom --file=learn.dump
sql 5433 -c "DELETE FROM ga.iconic_chords"
pg_restore -p 5433 -d learn --data-only --table=iconic_chords learn.dump
sql 5433 -c "SELECT count(*) AS chords FROM ga.iconic_chords"

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

say "Clean-up"
for node in node1 node2; do pg_ctl -D $node -m fast -w stop > /dev/null; done
rm -rf node1 node2 archive base learn.dump ./*.log
echo "done"
