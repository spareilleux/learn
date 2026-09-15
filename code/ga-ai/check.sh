#!/usr/bin/env bash
# GA's AI: fetch the pinned GA projects, build the course program and compare each lesson's
# output with the expected one. No network after the restore, no model, no API key.
set -euo pipefail
cd "$(dirname "$0")"
bash fetch-ga.sh
dotnet build GaAi -c Release -m:2 --nologo -v quiet
status=0
for lesson in l1 l2 l3 l4; do
  if dotnet run --project GaAi -c Release --no-build -- "$lesson" | diff --strip-trailing-cr "expected/$lesson.txt" -; then
    echo "ok   $lesson"
  else
    echo "FAIL $lesson"
    status=1
  fi
done
exit $status
