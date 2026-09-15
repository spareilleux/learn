#!/usr/bin/env bash
# Candle course: formatting, clippy and tests (with the compile_fail doctests), then every example's output
# compared with expected/. Examples whose output depends on the machine (NOCOMPARE) only have to exit with 0.
# UPDATE=1 writes the outputs to expected/ instead of comparing. JOBS sets cargo's -j (default 4).
set -uo pipefail
cd "$(dirname "$0")"
status=0
jobs=${JOBS:-4}
mkdir -p out expected
NOCOMPARE="l01_machine l03_bench"

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

cargo fmt --check || { echo "FAIL fmt"; status=1; }
cargo clippy --release -j "$jobs" --all-targets -- -D warnings || { echo "FAIL clippy"; status=1; }
cargo test --release -j "$jobs" || { echo "FAIL tests"; status=1; }

for f in course/examples/*.rs; do
  name=$(basename "$f" .rs)
  cargo run --release -j "$jobs" --quiet --example "$name" > "out/$name.txt" 2>&1
  code=$?
  echo "exit $code" >> "out/$name.txt"
  if [[ " $NOCOMPARE " == *" $name "* ]]; then
    cat "out/$name.txt"
    if [ $code -eq 0 ]; then echo "ran  $name"; else echo "FAIL $name (exit $code)"; status=1; fi
  else
    compare "$name"
  fi
done

exit $status
