#!/usr/bin/env bash
# DuckDB course, lesson 8: a database file, the write-ahead log, transactions and two processes
# Run from code/duckdb: bash shell/08-persistence.sh (check.sh compares the output with shell/expected/08-persistence.txt)
set -uo pipefail
mkdir -p out
db=out/ci.duckdb
rm -f out/ci.duckdb out/ci.duckdb.wal out/ci-compact.duckdb out/ci-v150.duckdb out/*.ready out/release out/*.log

# The size of each file, or "absent"
files() {
  for f in "$@"; do
    if [ -f "$f" ]; then echo "$f: $(wc -c < "$f" | tr -d ' ') bytes"; else echo "$f: absent"; fi
  done
}

# The DuckDB CLI in CSV mode, errors included, followed by its exit code
run() {
  duckdb -csv "$@" 2>&1
  echo "exit code $?"
}

# For errors whose message depends on the operating system: the full message on stderr, the error type on stdout
run_os_error() {
  duckdb -csv "$@" > out/os-error.log 2>&1
  local code=$?
  cat out/os-error.log >&2
  head -n 1 out/os-error.log | cut -d : -f 1
  echo "exit code $code"
}

# A DuckDB process that keeps the database open until out/release exists
hold_open() {
  local name=$1
  shift
  {
    echo "COPY (SELECT 1) TO 'out/$name.ready';"
    while [ ! -f out/release ]; do sleep 0.1; done
    echo "SELECT '$name' AS process, count(*) AS runs FROM runs;"
  } | duckdb -csv "$@" > "out/$name.log" 2>&1 &
  while [ ! -f "out/$name.ready" ]; do sleep 0.1; done
}

section() {
  echo
  echo "== $1"
}

section "1. A database file"
run $db -c "CREATE TABLE runs AS FROM 'data/runs.json'; CREATE TABLE jobs AS FROM 'data/jobs.json';"
files $db $db.wal
run $db -c "SELECT database_size, block_size, total_blocks, used_blocks, free_blocks, wal_size FROM pragma_database_size();"
run -c "ATTACH '$db' AS ci; ATTACH 'out/ci-v150.duckdb' AS v150 (STORAGE_VERSION 'v1.5.0'); SELECT database_name, tags FROM duckdb_databases() WHERE NOT internal ORDER BY ALL;"

section "2. The write-ahead log"
run $db -c "PRAGMA disable_checkpoint_on_shutdown; CREATE TABLE steps AS SELECT j.id AS job_id, s.* FROM jobs j, unnest(j.steps) AS t(s);"
files $db $db.wal
run $db -c "SELECT count(*) AS steps FROM steps;"
files $db $db.wal

section "3. Free blocks"
run $db -c "SELECT total_blocks, used_blocks, free_blocks FROM pragma_database_size();"
run $db -c "DROP TABLE jobs; CHECKPOINT; SELECT total_blocks, used_blocks, free_blocks FROM pragma_database_size();"
run -c "ATTACH '$db' AS ci; ATTACH 'out/ci-compact.duckdb' AS compact; COPY FROM DATABASE ci TO compact;"
files $db out/ci-compact.duckdb

section "4. Transactions"
run $db <<'SQL'
BEGIN;
DELETE FROM runs;
SELECT count(*) AS runs_in_transaction FROM runs;
ROLLBACK;
SELECT count(*) AS runs_after_rollback FROM runs;
BEGIN;
CREATE TABLE counters (name VARCHAR PRIMARY KEY, n INTEGER);
INSERT INTO counters VALUES ('builds', 0);
INSERT INTO counters VALUES ('builds', 1);
SELECT count(*) FROM counters;
COMMIT;
SELECT count(*) FROM counters;
SQL

section "5. Constraints and upserts"
run $db <<'SQL'
CREATE TABLE counters (name VARCHAR PRIMARY KEY, n INTEGER);
INSERT INTO counters VALUES ('builds', 0), ('deploys', 0);
INSERT INTO counters VALUES ('builds', 5);
INSERT INTO counters VALUES ('builds', 5) ON CONFLICT DO UPDATE SET n = counters.n + excluded.n;
INSERT OR REPLACE INTO counters VALUES ('deploys', 2);
INSERT OR IGNORE INTO counters VALUES ('deploys', 99), ('tests', 1);
FROM counters ORDER BY name;
SQL

section "6. A writing process and a second process"
hold_open writer $db
run_os_error $db -c "SELECT count(*) FROM runs;"
run_os_error -readonly $db -c "SELECT count(*) FROM runs;"
touch out/release
wait
cat out/writer.log
rm -f out/release

section "7. Reading processes"
hold_open reader -readonly $db
run -readonly $db -c "SELECT 'second reader' AS process, count(*) AS runs FROM runs;"
run -readonly $db -c "INSERT INTO counters VALUES ('lint', 1);"
run_os_error $db -c "SELECT count(*) FROM runs;"
touch out/release
wait
cat out/reader.log
