#!/usr/bin/env bash
# Music theory for Guitar Alchemist: fetch the pinned GA projects, build the course program
# and compare each lesson's output with the expected one
set -euo pipefail
cd "$(dirname "$0")"
bash fetch-ga.sh
dotnet build GaTheory -c Release -m:4 --nologo -v quiet
status=0
for lesson in l1 l2 l3 l4; do
  if dotnet run --project GaTheory -c Release --no-build -- "$lesson" | diff --strip-trailing-cr "expected/$lesson.txt" -; then
    echo "ok   $lesson"
  else
    echo "FAIL $lesson"
    status=1
  fi
done
exit $status
