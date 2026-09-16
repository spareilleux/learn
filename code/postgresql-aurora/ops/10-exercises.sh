#!/usr/bin/env bash
# Lesson 10, exercises: replication lag in bytes, a quorum of standbys, and replicated generated columns.
# Three small clusters in the course container: node1 (port 5433) and its standbys node2 (5434) and node3 (5435),
# then node3 on its own as a logical subscriber. Run as the postgres user: bash check.sh ops
set -u
export PATH=/usr/lib/postgresql/18/bin:$PATH PGUSER=postgres
cd /tmp
rm -rf node1 node2 node3 ./*.log

say() { printf '\n-- %s\n' "$*"; }
start() { pg_ctl -D "$1" -l "$1.log" -o "-p $2 -c cluster_name=$1" -w start > /dev/null || exit 1; }
until_true() {
  for _ in $(seq 150); do
    [ "$(psql -X -Atq -p "$1" -d "$2" -c "$3" 2>/dev/null)" = t ] && return 0
    sleep 0.2
  done
  echo "timed out on port $1: $3"
}
sql() { local port=$1; shift; psql -X -p "$port" -d learn "$@" 2>&1; }

initdb -D node1 --auth=trust > /dev/null
printf 'shared_buffers = 32MB\nwal_level = logical\n' >> node1/postgresql.conf
start node1 5433
psql -X -q -p 5433 -c 'CREATE DATABASE learn'
sql 5433 -q -c 'CREATE TABLE notes (id int PRIMARY KEY, body text NOT NULL)'
for node in node2 node3; do
  pg_basebackup -p 5433 -D $node -R -X stream -c fast
done
start node2 5434
start node3 5435
until_true 5433 learn "SELECT count(*) = 2 FROM pg_stat_replication WHERE state = 'streaming'"

say "Exercise 1: node2 pauses its replay; the lag, in bytes of WAL, grows on node1's side, then goes back to 0"
sql 5434 -Atc 'SELECT pg_wal_replay_pause()' -o /dev/null
until_true 5434 learn "SELECT pg_get_wal_replay_pause_state() = 'paused'"
sql 5433 -q -c "INSERT INTO notes SELECT i, repeat('x', 100) FROM generate_series(1, 1000) AS i"
lag="SELECT application_name, pg_wal_lsn_diff(sent_lsn, replay_lsn) > 0 AS behind FROM pg_stat_replication ORDER BY 1"
until_true 5433 learn "SELECT bool_and(sent_lsn = pg_current_wal_lsn())
                         AND bool_and(replay_lsn = sent_lsn) FILTER (WHERE application_name = 'node3') FROM pg_stat_replication"
sql 5433 -c "$lag"
sql 5434 -Atc 'SELECT pg_wal_replay_resume()' -o /dev/null
until_true 5433 learn "SELECT bool_and(replay_lsn = sent_lsn) FROM pg_stat_replication"
sql 5433 -c "$lag"

say "Exercise 2: ANY 1 (node2, node3): a commit waits for one of the two, so it goes through with node2 stopped"
sql 5433 -qc "ALTER SYSTEM SET synchronous_standby_names = 'ANY 1 (node2, node3)'" -c 'SELECT pg_reload_conf()' -o /dev/null
until_true 5433 learn "SELECT count(*) = 2 FROM pg_stat_replication WHERE sync_state = 'quorum'"
sql 5433 -c "SELECT application_name, sync_state FROM pg_stat_replication ORDER BY 1"
pg_ctl -D node2 -m fast -w stop > /dev/null
sql 5433 -c "INSERT INTO notes VALUES (1001, 'one standby is enough')"
sql 5433 -qc "ALTER SYSTEM RESET synchronous_standby_names" -c 'SELECT pg_reload_conf()' -o /dev/null

say "Exercise 3: node3 becomes a primary of its own, and subscribes to a table with a stored generated column"
sql 5435 -Atc 'SELECT pg_promote()' -o /dev/null
sql 5433 -q -c "CREATE TABLE sizes (id int PRIMARY KEY, body text NOT NULL, length int GENERATED ALWAYS AS (length(body)) STORED)"
# On node3 the column is an ordinary one: it receives the values computed on node1
sql 5435 -q -c "CREATE TABLE sizes (id int PRIMARY KEY, body text NOT NULL, length int)"
sql 5433 -c "INSERT INTO sizes (id, body) VALUES (1, 'partition'), (2, 'replication')"
sql 5433 -c "CREATE PUBLICATION sizes_all FOR TABLE sizes WITH (publish_generated_columns = stored)"
sql 5435 -c "CREATE SUBSCRIPTION sizes_from_node1 CONNECTION 'port=5433 dbname=learn' PUBLICATION sizes_all"
until_true 5435 learn "SELECT count(*) = 2 FROM sizes"
sql 5435 -c "SELECT * FROM sizes ORDER BY id"

say "Clean-up"
sql 5435 -qc "DROP SUBSCRIPTION sizes_from_node1"
for node in node3 node1; do pg_ctl -D $node -m fast -w stop > /dev/null; done
rm -rf node1 node2 node3 ./*.log
echo "done"
