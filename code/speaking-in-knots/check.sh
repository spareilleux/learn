#!/usr/bin/env bash
# Speaking in knots: runs the state-sum script against the values IX's tests assert, runs it on the braid words the
# lessons quote, runs the mutation check, and compares every output with expected/.
#   bash check.sh            everything
#   UPDATE=1 bash check.sh   writes the outputs to expected/ instead of comparing (review the diff before committing)
# PYTHON is the Python 3 executable (default: python3 if it runs, else python). Standard library only.
set -uo pipefail
cd "$(dirname "$0")"
export PYTHONUTF8=1 PYTHONDONTWRITEBYTECODE=1
if [ -z "${PYTHON:-}" ]; then
  if python3 -c "" 2>/dev/null; then PYTHON=python3; else PYTHON=python; fi
fi
"$PYTHON" --version
status=0
rm -rf out
mkdir -p out expected

# run <name> <command…>: runs the command, keeps its output and its exit code, and compares them with expected/
run() {
  local name=$1
  shift
  "$PYTHON" "$@" > "out/$name.txt" 2>&1
  echo "exit $?" >> "out/$name.txt"
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

run oracle jones_state_sum.py
run unknot-s1-s2 jones_state_sum.py "s1 s2"
run hopf jones_state_sum.py "s1^2"
run hopf-mirror jones_state_sum.py "s1^-2"
run trefoil jones_state_sum.py "s1^3"
run borromean jones_state_sum.py "s1 s2^-1" 3
run torus-3-3 jones_state_sum.py "s1 s2" 3
run plait-6 jones_state_sum.py "s1 s2^-1" 6
run mutants mutants.py
exit $status
