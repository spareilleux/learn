#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo test

mkdir -p out
cargo run --quiet --example l01_layout > out/l01_layout.txt
diff -u expected/l01_layout.txt out/l01_layout.txt
echo "rust-advanced: formatting, clippy, tests and lesson 1 output passed"
