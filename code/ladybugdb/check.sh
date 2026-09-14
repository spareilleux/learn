#!/usr/bin/env bash
# LadybugDB course: run every lesson script with the CLI in CSV mode and compare with the expected output
# The CLI exits with 0 even when a query fails: errors are part of the compared output
set -euo pipefail
cd "$(dirname "$0")"
lbug --version
mkdir -p out
# Extensions are downloaded once per machine; the scripts only LOAD them
echo "INSTALL json;" | lbug --no_progress_bar --no_stats --mode csv
status=0
for script in cypher/*.cypher; do
  name=$(basename "$script" .cypher)
  if lbug --no_progress_bar --no_stats --mode csv < "$script" | diff --strip-trailing-cr "cypher/expected/$name.csv" -; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
done
# SQL cross-checks, run with DuckDB when it's installed (the CI installs it)
if command -v duckdb > /dev/null; then
  duckdb --version
  for script in sql/*.sql; do
    name=$(basename "$script" .sql)
    if duckdb -csv < "$script" | diff --strip-trailing-cr "sql/expected/$name.csv" -; then
      echo "ok   sql/$name"
    else
      echo "FAIL sql/$name"; status=1
    fi
  done
else
  echo "skip sql/*.sql: duckdb not found"
fi
exit $status
