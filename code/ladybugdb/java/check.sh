#!/usr/bin/env bash
# LadybugDB course, lessons 6 and 8: run the Java programs from code/ladybugdb and compare their output with the expected one,
# then share a database file between the Maven package (0.20.4) and the CLI (0.20.4)
set -euo pipefail
cd "$(dirname "$0")/.."
mvn -B -q -f java/pom.xml compile
run() { mvn -B -q -f java/pom.xml exec:java -Dexec.args="$*"; }
status=0
if run check | diff --strip-trailing-cr java/expected.txt -; then
  echo "ok   java"
else
  echo "FAIL java"; status=1
fi
rm -rf out/java && mkdir -p out/java
query="MATCH (p:Project) RETURN p.name;"
{
  run create out/java/ga.lbdb
  echo "-- the CLI, read-write"
  echo "$query" | lbug --no_progress_bar --no_stats --mode csv out/java/ga.lbdb
  run open out/java/ga.lbdb
} 2>&1 | grep -v '^Warning: failed to create directory' > out/java/files.txt
if diff --strip-trailing-cr java/expected-files.txt out/java/files.txt; then
  echo "ok   java/files"
else
  echo "FAIL java/files"; status=1
fi
# Lesson 8: transactions and concurrency; the lines starting with "# " depend on the OS or on timing
mvn -B -q -f java/pom.xml exec:java -Dexec.mainClass=graph.Transactions 2>&1 | grep -v '^Warning: failed to create directory' > out/java/transactions.txt || true
if grep -v '^# ' out/java/transactions.txt | diff --strip-trailing-cr java/expected-transactions.txt -; then
  echo "ok   java/transactions"
else
  echo "FAIL java/transactions"; status=1
fi
echo "== Transactions: what depends on the OS or on timing (not compared)"
grep '^# ' out/java/transactions.txt || true
echo "== A refused BEGIN (not compared: the JVM crashes on Linux and macOS)"
set +e
mvn -B -q -f java/pom.xml exec:java -Dexec.mainClass=graph.Transactions -Dexec.args=refused-begin 2>&1 | grep -v '^Warning: failed to create directory' | grep -E '^(first|second)|^#.*(fatal error|SIGSEGV|EXCEPTION_ACCESS_VIOLATION|liblbug_java)'
echo "exit code of mvn: ${PIPESTATUS[0]}"
set -e
echo "== Native library copies (not compared)"
run temp
run timings | sed -n '/Timings/,$p'
exit $status
