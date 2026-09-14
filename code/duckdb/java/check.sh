#!/usr/bin/env bash
# DuckDB course, lessons 6 and 8: run the Java programs from code/duckdb and compare their output with the expected one
set -euo pipefail
cd "$(dirname "$0")/.."
mvn -B -q -f java/pom.xml compile
if mvn -B -q -f java/pom.xml exec:java -Dexec.args=check | diff --strip-trailing-cr java/expected.txt -; then
  echo "ok   java"
else
  echo "FAIL java"
  exit 1
fi
if mvn -B -q -f java/pom.xml exec:java -Dexec.mainClass=ci.Transactions | diff --strip-trailing-cr java/expected-transactions.txt -; then
  echo "ok   java transactions"
else
  echo "FAIL java transactions"
  exit 1
fi
mvn -B -q -f java/pom.xml exec:java -Dexec.args=timings
