#!/usr/bin/env bash
# DuckDB course: run every lesson script in CSV mode and compare with the expected output
set -euo pipefail
cd "$(dirname "$0")"
duckdb --version
mkdir -p out
status=0
for script in sql/*.sql; do
  name=$(basename "$script" .sql)
  if duckdb -csv < "$script" | diff --strip-trailing-cr "sql/expected/$name.csv" -; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
done
exit $status
