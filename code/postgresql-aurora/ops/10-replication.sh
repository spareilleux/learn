#!/usr/bin/env bash
# Lesson 10: streaming replication, a synchronous standby, a failover with pg_rewind, and logical replication.
# Three small clusters in the course container, next to the course server: node1 (port 5433), node2 (5434), node3 (5435).
# Run as the postgres user: bash check.sh ops, or docker exec -i -u postgres pg bash -s < ops/10-replication.sh
set -u
export PATH=/usr/lib/postgresql/18/bin:$PATH PGUSER=postgres
cd /tmp
rm -rf node1 node2 node3 ./*.log insert.log

# say <text>: a heading in the output; lsn: hides WAL positions, which change from run to run
say() { printf '\n-- %s\n' "$*"; }
lsn() { sed -E 's#[0-9A-F]+/[0-9A-F]{1,8}#X/XXXXXXXX#g'; }
# start <node> <port>: the port and the name that standbys report go on the command line, so copied config files keep neither
start() { pg_ctl -D "$1" -l "$1.log" -o "-p $2 -c cluster_name=$1" -w start > /dev/null || exit 1; }
# until_true <port> <database> <query>: polls until the query returns true, for 30 seconds at most
until_true() {
  for _ in $(seq 150); do
    [ "$(psql -X -Atq -p "$1" -d "$2" -c "$3" 2>/dev/null)" = t ] && return 0
    sleep 0.2
  done
  echo "timed out on port $1: $3"
}
sql() { local port=$1; shift; psql -X -p "$port" -d learn "$@" 2>&1; }
# add_run <port> <run id> <workflow name> [psql options]: inserts a run of the main branch
add_run() {
  sql "$1" "${@:4}" -c "INSERT INTO ci.runs VALUES ($2, '$3', 'push', 'success', 'main', repeat('a', 40), 1,
                        '2026-09-16 12:00+00', '2026-09-16 12:00+00', '2026-09-16 12:00+00')"
}

say "node1: a new cluster, with enough WAL for logical decoding, and the course schema"
initdb -D node1 --auth=trust > /dev/null
cat >> node1/postgresql.conf <<'EOF'
shared_buffers = 32MB
wal_level = logical
# pg_rewind reads the WAL back to the last checkpoint both nodes share: keep a few segments instead of recycling them
wal_keep_size = 128MB
EOF
start node1 5433
psql -X -q -p 5433 -c 'CREATE DATABASE learn'
psql -X -q -p 5433 -d learn -c '\o /dev/null' -c '\i /course/sql/schema.sql'
sql 5433 -Atc 'SHOW data_checksums'

say "node2: a copy of node1 taken over a replication connection, with a slot and the settings of a standby (-R)"
pg_basebackup -p 5433 -D node2 -R -C -S node2 -X stream -c fast
ls node2/*.signal
grep -o "primary_slot_name = .*\|port=[0-9]*" node2/postgresql.auto.conf
start node2 5434
until_true 5433 learn "SELECT EXISTS (SELECT FROM pg_stat_replication WHERE application_name = 'node2' AND state = 'streaming')"
sql 5433 -c "SELECT application_name, state, sync_state FROM pg_stat_replication"
sql 5433 -c "SELECT slot_name, slot_type, active, wal_status FROM pg_replication_slots"

say "A write on node1 is replayed on node2, which answers read-only queries"
add_run 5433 1 'Replication test' -q
lsn=$(psql -X -Atq -p 5433 -c 'SELECT pg_current_wal_lsn()')
until_true 5434 learn "SELECT pg_last_wal_replay_lsn() >= '$lsn'"
sql 5434 -c "SELECT pg_is_in_recovery(), workflow_name FROM ci.runs WHERE run_id = 1"
sql 5434 -c "DELETE FROM ci.runs WHERE run_id = 1"

say "Synchronous replication: node1's commits now wait for node2 to confirm"
sql 5433 -qc "ALTER SYSTEM SET synchronous_standby_names = 'FIRST 1 (node2)'" -c 'SELECT pg_reload_conf()' -o /dev/null
until_true 5433 learn "SELECT EXISTS (SELECT FROM pg_stat_replication WHERE sync_state = 'sync')"
sql 5433 -c "SELECT application_name, sync_state FROM pg_stat_replication"
pg_ctl -D node2 -m fast -w stop > /dev/null
echo "node2 stopped"
# The commit is written locally, then waits for a standby that isn't there. statement_timeout doesn't cover that wait:
# another session cancels it, which ends the wait but not the commit
add_run 5433 2 'Committed locally' > insert.log &
until_true 5433 learn "SELECT EXISTS (SELECT FROM pg_stat_activity WHERE wait_event = 'SyncRep')"
sql 5433 -c "SELECT wait_event_type, wait_event, pg_cancel_backend(pid) FROM pg_stat_activity WHERE wait_event = 'SyncRep'"
wait
cat insert.log
sql 5433 -c "SELECT run_id, workflow_name FROM ci.runs WHERE run_id < 100 ORDER BY run_id"
sql 5433 -qc "ALTER SYSTEM RESET synchronous_standby_names" -c 'SELECT pg_reload_conf()' -o /dev/null

say "Asynchronous again, node2 still down: node1 commits a run that node2 will never receive"
add_run 5433 3 'Lost in the failover' -q
pg_ctl -D node1 -m fast -w stop > /dev/null
echo "node1 stopped"

say "Failover: node2 starts, is promoted, and becomes a primary on a new timeline"
start node2 5434
sql 5434 -c "SELECT pg_promote()"
sql 5434 -c "SELECT pg_is_in_recovery(), substr(pg_walfile_name(pg_current_wal_lsn()), 1, 8) AS timeline"
sql 5434 -c "SELECT run_id, workflow_name FROM ci.runs WHERE run_id < 100 ORDER BY run_id"
add_run 5434 4 'After the failover' -q

say "node1 can't simply follow node2: its WAL went further on the old timeline. pg_rewind takes it back."
pg_rewind -D node1 --source-server='port=5434 dbname=postgres' -R 2>&1 | lsn
sql 5434 -Atc "SELECT pg_create_physical_replication_slot('node1') IS NOT NULL" -o /dev/null
pg_ctl -D node1 -l node1.log -o "-p 5433 -c cluster_name=node1 -c primary_slot_name=node1" -w start > /dev/null
until_true 5434 learn "SELECT EXISTS (SELECT FROM pg_stat_replication WHERE application_name = 'node1' AND state = 'streaming')"
lsn=$(psql -X -Atq -p 5434 -c 'SELECT pg_current_wal_lsn()')
until_true 5433 learn "SELECT pg_last_wal_replay_lsn() >= '$lsn'"
sql 5433 -c "SELECT pg_is_in_recovery(), run_id, workflow_name FROM ci.runs WHERE run_id < 100 ORDER BY run_id"

say "Logical replication: node3, a separate cluster, subscribes to the runs table of node2"
initdb -D node3 --auth=trust > /dev/null
echo "shared_buffers = 32MB" >> node3/postgresql.conf
start node3 5435
psql -X -q -p 5435 -c 'CREATE DATABASE learn'
# Logical replication carries rows, not the schema: the table is created first
psql -X -q -p 5435 -d learn -c 'CREATE EXTENSION btree_gist'
pg_dump -p 5434 -d learn --schema-only --schema=ci | psql -X -q -p 5435 -d learn > /dev/null
sql 5434 -c "CREATE PUBLICATION runs_on_main FOR TABLE ci.runs WHERE (head_branch = 'main')"
sql 5435 -c "CREATE SUBSCRIPTION runs_from_node2 CONNECTION 'port=5434 dbname=learn' PUBLICATION runs_on_main"
until_true 5435 learn "SELECT count(*) = 0 FROM pg_subscription_rel WHERE srsubstate <> 'r'"
sql 5434 -c "SELECT head_branch = 'main' AS on_main, count(*) FROM ci.runs GROUP BY 1 ORDER BY 1"
sql 5435 -c "SELECT head_branch = 'main' AS on_main, count(*) FROM ci.runs GROUP BY 1 ORDER BY 1"

say "The subscriber is an ordinary primary: it accepts writes, which can conflict with replicated rows"
add_run 5435 5 'Written on node3'
add_run 5434 5 'Written on node2' -q
until_true 5435 learn "SELECT confl_insert_exists > 0 FROM pg_stat_subscription_stats WHERE subname = 'runs_from_node2'"
sql 5435 -c "SELECT subname, apply_error_count > 0 AS apply_errors, confl_insert_exists > 0 AS insert_conflicts FROM pg_stat_subscription_stats"
grep -o 'ERROR:  conflict detected on relation "ci.runs": conflict=insert_exists' node3.log | head -1
# Removing the subscriber's row lets the apply worker, which retries, go past the conflict
sql 5435 -qc "DELETE FROM ci.runs WHERE run_id = 5"
until_true 5435 learn "SELECT EXISTS (SELECT FROM ci.runs WHERE run_id = 5)"
sql 5435 -c "SELECT run_id, workflow_name FROM ci.runs WHERE run_id < 100 ORDER BY run_id"

say "Clean-up"
sql 5435 -qc "DROP SUBSCRIPTION runs_from_node2"
for node in node3 node1 node2; do pg_ctl -D $node -m fast -w stop > /dev/null; done
rm -rf node1 node2 node3 ./*.log insert.log
echo "done"
