#!/usr/bin/env bash
# Machine learning course: formatting, clippy and tests, then every example's output compared with expected/.
# CROSSCHECK=1 also runs the numpy and scikit-learn check. UPDATE=1 writes the outputs to expected/ instead of comparing.
set -uo pipefail
cd "$(dirname "$0")"
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

cargo fmt --check || { echo "FAIL fmt"; status=1; }
cargo clippy --release --all-targets -- -D warnings || { echo "FAIL clippy"; status=1; }
cargo test --release || { echo "FAIL tests"; status=1; }

for f in examples/*.rs; do
  name=$(basename "$f" .rs)
  cargo run --release --quiet --example "$name" > "out/$name.txt" 2>&1
  echo "exit $?" >> "out/$name.txt"
  compare "$name"
done

if [ "${CROSSCHECK:-}" = 1 ]; then
  python crosscheck/crosscheck.py > out/crosscheck.txt 2>&1
  echo "exit $?" >> out/crosscheck.txt
  compare crosscheck
fi

exit $status
