#!/usr/bin/env bash
# DuckDB course, lesson 6: run the Java program from code/duckdb and compare its output with the expected one
set -euo pipefail
cd "$(dirname "$0")/.."
mvn -B -q -f java/pom.xml compile
if mvn -B -q -f java/pom.xml exec:java -Dexec.args=check | diff --strip-trailing-cr java/expected.txt -; then
  echo "ok   java"
else
  echo "FAIL java"
  exit 1
fi
mvn -B -q -f java/pom.xml exec:java -Dexec.args=timings
