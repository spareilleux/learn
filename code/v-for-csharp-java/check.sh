#!/usr/bin/env bash
# V course: run every example and compare its output with expected/, check that every rejected snippet
# fails with the expected compiler message, and that every panic starts with the expected line.
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
set -uo pipefail
cd "$(dirname "$0")"
# V 0.5.2 sends a report to bugs.vlang.io when the C compiler fails (except in GitHub CI): not from this script
export V_C_ERROR_BUG_REPORT_DISABLED=1
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
if v fmt -verify examples warnings panics compiler_bugs l01-project l01-exercise l08-testing l08-failing > out/fmt.txt 2>&1; then
  echo "ok   fmt"
else
  cat out/fmt.txt
  echo "FAIL fmt"
  status=1
fi

# Examples, run from this folder: standard output and errors, so a new warning fails too
# The lines starting with "# " depend on the machine or on timing (lesson 7): printed, not compared
for f in examples/*.v; do
  name=$(basename "$f" .v)
  [ "$name" = l04_memory ] && continue
  v run "$f" > "out/$name.raw.txt" 2>&1
  code=$?
  grep '^# ' "out/$name.raw.txt"
  { grep -v '^# ' "out/$name.raw.txt"; echo "exit $code"; } > "out/$name.txt"
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
(cd l01-exercise && v run . V for C# and Java developers) > out/l01_exercise.txt 2>&1
echo "exit $?" >> out/l01_exercise.txt
compare l01_exercise

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

# Compiler bugs: programs that V 0.5.2 accepts, then fails to compile to C; the first line of V's message and the exit code
for f in compiler_bugs/*.v; do
  name=$(basename "$f" .v)
  (cd compiler_bugs && v run "$name.v") > "out/$name.full.txt" 2>&1
  code=$?
  { grep -m1 'C error found' "out/$name.full.txt"; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
done

# Lesson 8: v test on a project, without the timings, the order of the files and the absolute paths
(cd l08-testing && v test .) > out/l08_test.raw.txt 2>&1
code=$?
{
  grep -E '^(OK|FAIL)' out/l08_test.raw.txt | sed -E 's/^(OK|FAIL) .* [^ ]*l08-testing\//\1 /' | sort
  sed -n -E 's/^(Summary for all V _test\.v files: [^.]*\.).*/\1/p' out/l08_test.raw.txt
  echo "exit $code"
} > out/l08_test.txt
compare l08_test
# A test file run alone, and with -stats (without the timings)
(cd l08-testing && v deps/s08_cycle_test.v) > out/s08_cycle.txt 2>&1
echo "exit $?" >> out/s08_cycle.txt
compare s08_cycle
(cd l08-failing && v failing_test.v) > out/l08_failing.txt 2>&1
echo "exit $?" >> out/l08_failing.txt
compare l08_failing
(cd l08-failing && v -stats failing_test.v) > out/l08_failing_stats.raw.txt 2>&1
code=$?
{
  grep -E '^ +(OK|FAIL) |^ +Summary for running' out/l08_failing_stats.raw.txt | sed -E 's/ +[0-9]+\.[0-9]+ ms / ms /; s/Elapsed time: [0-9]+ ms\./Elapsed time: ms./'
  echo "exit $code"
} > out/l08_failing_stats.txt
compare l08_failing_stats
# v doc, v vet and v fmt
(cd l08-testing && v doc -comments deps) > out/l08_doc.txt 2>&1
echo "exit $?" >> out/l08_doc.txt
compare l08_doc
(cd vet && v vet v08_vet.v) > out/v08_vet.txt 2>&1
echo "exit $?" >> out/v08_vet.txt
compare v08_vet
(cd vet && v fmt -verify v08_vet.v) > out/v08_fmt_verify.txt 2>&1
echo "exit $?" >> out/v08_fmt_verify.txt
sed -i.bak -E 's|^.*[\\/]vet[\\/]v08_vet\.v|v08_vet.v|' out/v08_fmt_verify.txt
compare v08_fmt_verify
(cd vet && v fmt v08_vet.v) > out/v08_fmt.txt 2>&1
echo "exit $?" >> out/v08_fmt.txt
compare v08_fmt

# Lesson 4: resident memory under each memory mode, for information
for mode in "" "-gc none" "-autofree"; do
  echo "--- l04_memory ${mode:-(default)}"
  v $mode run examples/l04_memory.v || status=1
done
exit $status
