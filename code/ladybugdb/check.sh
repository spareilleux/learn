#!/usr/bin/env bash
# LadybugDB course: run every lesson script with the CLI in CSV mode and compare with the expected output
# The CLI exits with 0 even when a query fails: errors are part of the compared output
set -euo pipefail
cd "$(dirname "$0")"
lbug --version
mkdir -p out
# Extensions are downloaded once per machine; the scripts only LOAD them
echo "INSTALL json;" | lbug --no_progress_bar --no_stats --mode csv
# The algo and fts extensions load with the 0.19.1 CLI only, installed as lbug19: the scripts that say so in their header use it
if command -v lbug19 > /dev/null; then
  lbug19 --version
  printf 'INSTALL algo;\nINSTALL fts;\n' | lbug19 --no_progress_bar --no_stats --mode csv
  # Not compared: shows whether the extensions published for the current CLI load yet
  echo "--- algo and fts with $(lbug --version), for information"
  printf 'INSTALL algo;\nLOAD algo;\nINSTALL fts;\nLOAD fts;\n' | lbug --no_progress_bar --no_stats --mode csv 2>&1 || true
  echo "---"
fi
status=0
for script in cypher/*.cypher; do
  name=$(basename "$script" .cypher)
  cli=lbug
  if head -3 "$script" | grep -q 'lbug19'; then
    cli=lbug19
    if ! command -v lbug19 > /dev/null; then
      echo "skip $name: lbug19 not found"
      continue
    fi
  fi
  if $cli --no_progress_bar --no_stats --mode csv < "$script" | diff --strip-trailing-cr "cypher/expected/$name.csv" -; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
done
# Database files and processes (lesson 8): the lines starting with "# " depend on the OS and aren't compared
bash files/files.sh > out/files.txt 2>&1
if grep -v '^# ' out/files.txt | diff --strip-trailing-cr files/expected.txt -; then
  echo "ok   files"
else
  echo "FAIL files"
  status=1
fi
echo "--- files: what depends on the OS"
grep '^# ' out/files.txt || true
echo "---"
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
