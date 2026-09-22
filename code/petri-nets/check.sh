#!/usr/bin/env bash
# Petri nets: build the library, run its unit tests, then run each lesson and compare its output
# with expected/. The PNML files in nets/ are regenerated and compared too, so a net, its picture
# and its analysis cannot drift apart.
# UPDATE=1 bash check.sh writes the outputs to expected/ and to nets/ instead of comparing them
# (review the diff before committing).
set -uo pipefail
cd "$(dirname "$0")"

dotnet build Examples -c Release -m:4 --nologo -v quiet "-clp:ErrorsOnly;NoSummary" || exit 1
dotnet test Tests -c Release -m:4 --nologo -v quiet || exit 1

status=0
mkdir -p out expected

compare() {
  local name=$1
  if [ "${UPDATE:-}" = 1 ]; then
    cp "out/$name.txt" "expected/$name.txt"
    echo "upd  $name"
  elif diff --strip-trailing-cr "expected/$name.txt" "out/$name.txt"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
}

run() {
  local lesson=$1
  dotnet run --project Examples -c Release --no-build -- "$lesson" < /dev/null > "out/$lesson.txt" 2>&1
  local code=$?
  if [ $code -ne 0 ]; then
    echo "FAIL $lesson exited with $code"
    cat "out/$lesson.txt"
    status=1
    return
  fi
  compare "$lesson"
}

run l1
run l2
run l3
run l4
run l5
run l6
run l7
run l8
run l9
run l10
run l11
run l14
run music
run chat

# The PNML files the lessons show, regenerated from the same net definitions
rm -rf out/nets
if [ "${UPDATE:-}" = 1 ]; then
  dotnet run --project Examples -c Release --no-build -- nets nets > /dev/null || exit 1
  echo "upd  nets"
else
  dotnet run --project Examples -c Release --no-build -- nets out/nets > /dev/null || exit 1
  if diff --strip-trailing-cr -r nets out/nets; then
    echo "ok   nets"
  else
    echo "FAIL nets"
    status=1
  fi
fi

exit $status
