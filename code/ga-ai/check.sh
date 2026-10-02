#!/usr/bin/env bash
# GA's AI: fetch the pinned GA projects and, for lessons 16, 17 and 19, GA's main, build the
# course programs and compare each lesson's output with the expected one. No network after
# the restore, no model, no API key.
set -euo pipefail
cd "$(dirname "$0")"
bash fetch-ga.sh
dotnet build GaAi -c Release -m:2 --nologo -v quiet
status=0
for lesson in l1 l2 l3 l4 l5 l6 l7 l8 l9 l10 l11 l12 l13 l14 l15 l16 l17 l18 l19; do
  if dotnet run --project GaAi -c Release --no-build -- "$lesson" | diff --strip-trailing-cr "expected/$lesson.txt" -; then
    echo "ok   $lesson"
  else
    echo "FAIL $lesson"
    status=1
  fi
done
# The second half of lessons 16, 17 and 19 asks GA's main, in its own program
dotnet build GaMain -c Release -m:2 --nologo -v quiet
for lesson in l16 l17 l19; do
  if dotnet run --project GaMain -c Release --no-build -- "$lesson" | diff --strip-trailing-cr "expected/$lesson-main.txt" -; then
    echo "ok   $lesson (main)"
  else
    echo "FAIL $lesson (main)"
    status=1
  fi
done
exit $status
