#!/usr/bin/env bash
# DuckDB course, lesson 8: exercise solutions
set -uo pipefail
mkdir -p out
db=out/exercises.duckdb
rm -f $db $db.wal

echo "== Exercise 1: three statements in one -c argument, the last one failing"
duckdb -csv $db -c "CREATE TABLE counters (name VARCHAR PRIMARY KEY, n INTEGER);"
duckdb -csv $db -c "INSERT INTO counters VALUES ('builds', 1); INSERT INTO counters VALUES ('tests', 1); INSERT INTO counters VALUES ('builds', 2);" 2>&1
echo "exit code $?"
duckdb -csv $db -c "SELECT count(*) AS rows FROM counters;"

echo "== Exercise 1: the same statements in an explicit transaction"
duckdb -csv $db -c "DELETE FROM counters;"
duckdb -csv $db -c "BEGIN; INSERT INTO counters VALUES ('builds', 1); INSERT INTO counters VALUES ('tests', 1); INSERT INTO counters VALUES ('builds', 2); COMMIT;" 2>&1
echo "exit code $?"
duckdb -csv $db -c "SELECT count(*) AS rows FROM counters;"
