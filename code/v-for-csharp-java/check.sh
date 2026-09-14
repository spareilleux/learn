#!/usr/bin/env bash
# V course: run every example and compare its output with expected/, check that every rejected snippet
# fails with the expected compiler message, and that every panic starts with the expected line.
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
set -uo pipefail
cd "$(dirname "$0")"
v version
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

# Formatting (the rejected snippets are left out: v fmt checks them too, and fails)
if v fmt -verify examples warnings panics l01-project > out/fmt.txt 2>&1; then
  echo "ok   fmt"
else
  cat out/fmt.txt
  echo "FAIL fmt"
  status=1
fi

# Examples, run from this folder: standard output and errors, so a new warning fails too
for f in examples/*.v; do
  name=$(basename "$f" .v)
  [ "$name" = l04_memory ] && continue
  v run "$f" > "out/$name.txt" 2>&1
  echo "exit $?" >> "out/$name.txt"
  compare "$name"
done

# Lesson 1: a project with a module, without and with arguments
{
  (cd l01-project && v run .)
  echo "exit $?"
  (cd l01-project && v run . ada grace)
  echo "exit $?"
} > out/l01_project.txt 2>&1
compare l01_project

# Programs that compile with a warning or a notice, run from their folder
for f in warnings/*.v; do
  name=$(basename "$f" .v)
  (cd warnings && v run "$name.v") > "out/$name.txt" 2>&1
  echo "exit $?" >> "out/$name.txt"
  compare "$name"
done

# Rejected snippets, compiled from their folder: a file, or a folder with v.mod
# A first line `// flags: …` gives compiler flags
for f in compile_fail/*.v compile_fail/*/; do
  name=$(basename "$f" .v)
  if [ -d "$f" ]; then
    (cd "$f" && v .) > "out/$name.txt" 2>&1
  else
    flags=$(head -1 "$f" | sed -n 's|^// flags: ||p')
    (cd compile_fail && v $flags "$name.v") > "out/$name.txt" 2>&1
  fi
  echo "exit $?" >> "out/$name.txt"
  compare "$name"
done

# Panics: only the first line and the exit code, the backtrace depends on the OS and the C compiler
for f in panics/*.v; do
  name=$(basename "$f" .v)
  v run "$f" > "out/$name.full.txt" 2>&1
  code=$?
  { head -1 "out/$name.full.txt"; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
done

# Lesson 4: resident memory under each memory mode, for information
for mode in "" "-gc none" "-autofree"; do
  echo "--- l04_memory ${mode:-(default)}"
  v $mode run examples/l04_memory.v || status=1
done
exit $status
