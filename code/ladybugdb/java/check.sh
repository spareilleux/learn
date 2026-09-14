#!/usr/bin/env bash
# LadybugDB course, lesson 6: run the Java program from code/ladybugdb and compare its output with the expected one,
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
echo "== Native library copies (not compared)"
run temp
run timings | sed -n '/Timings/,$p'
exit $status
