#!/usr/bin/env bash
# DuckDB course, lesson 5: run the C# program from code/duckdb and compare its output with the expected one
set -euo pipefail
cd "$(dirname "$0")/.."
dotnet build csharp/CiQueries -c Release --nologo -v quiet
if dotnet run --project csharp/CiQueries -c Release --no-build -- check | diff --strip-trailing-cr csharp/expected.txt -; then
  echo "ok   csharp"
else
  echo "FAIL csharp"
  exit 1
fi
dotnet run --project csharp/CiQueries -c Release --no-build -- timings
