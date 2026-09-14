#!/usr/bin/env bash
# LadybugDB course, lesson 5: run the C# program from code/ladybugdb and compare its output with the expected one,
# then share a database file between the NuGet package (LadybugDB 0.19.1) and the CLI (0.20.4)
set -euo pipefail
cd "$(dirname "$0")/.."
dotnet build csharp/ProjectGraph -c Release --nologo -v quiet
run() { dotnet run --project csharp/ProjectGraph -c Release --no-build -- "$@"; }
status=0
if run check | diff --strip-trailing-cr csharp/expected.txt -; then
  echo "ok   csharp"
else
  echo "FAIL csharp"; status=1
fi
rm -rf out/net && mkdir -p out/net
query="MATCH (p:Project) RETURN p.name;"
{
  run create out/net/ga.lbdb
  echo "-- the CLI, read-only"
  echo "$query" | lbug --no_progress_bar --no_stats --mode csv --read_only out/net/ga.lbdb
  run open out/net/ga.lbdb
  echo "-- the CLI, read-write"
  echo "$query" | lbug --no_progress_bar --no_stats --mode csv out/net/ga.lbdb
  run open out/net/ga.lbdb
} > out/net/files.txt 2>&1
if diff --strip-trailing-cr csharp/expected-files.txt out/net/files.txt; then
  echo "ok   csharp/files"
else
  echo "FAIL csharp/files"; status=1
fi
run timings | sed -n '/Timings/,$p'
exit $status
