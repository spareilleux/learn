#!/usr/bin/env bash
# JavaScript course: run every example, error snippet and solution with Node.js, and compare the output with expected/.
# The C# and Java comparisons run too when dotnet and java are installed (REQUIRE_COMPARE=1 makes them mandatory).
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
set -uo pipefail
cd "$(dirname "$0")"
echo "node $(node --version), npm $(npm --version)"
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

# run <name> <folder> <command…>: runs the command from the folder, then normalizes its output and adds the exit code
run() {
  local name=$1 dir=$2
  shift 2
  (cd "$dir" && "$@") > "out/$name.raw.txt" 2>&1
  local code=$?
  { node normalize.mjs < "out/$name.raw.txt"; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
}

# Examples and solutions, run from this folder
for f in examples/*.js examples/*.cjs solutions/*.js; do
  [ -e "$f" ] || continue
  name=$(basename "${f%.*}")
  [ "$name" = show ] && continue
  run "$name" . node "$f"
done
run l01_hello_args . node examples/l01_hello.js Ada Grace

# Error snippets, run from their folder: Node.js suggests a missing extension relative to the current folder
for f in errors/*.js errors/*.cjs; do
  run "$(basename "${f%.*}")" errors node "$(basename "$f")"
done
run l01_missing_extension_root . node errors/l01_missing_extension.js

# Lesson 1: the two module systems, their interoperability, and package scripts
run l01_esm l01-esm node main.js
run l01_esm_run l01-esm node --run greet
run l01_esm_npm_run l01-esm npm run greet --silent
run l01_cjs l01-cjs node main.js Ada
run l01_from_esm l01-interop node from-esm.mjs
run l01_from_cjs l01-interop node from-cjs.cjs
run l01_detect l01-interop node detect.js
for d in solutions/*/; do
  [ -e "$d/main.js" ] || continue
  run "$(basename "$d")" "$d" node main.js
done

# The C# and Java sides of the comparisons
if command -v dotnet > /dev/null; then
  for f in compare/*.cs; do
    run "$(basename "${f%.*}")_cs" compare dotnet run "$(basename "$f")"
  done
else
  echo "skip C# comparisons: dotnet not found"
  [ "${REQUIRE_COMPARE:-}" = 1 ] && status=1
fi
if command -v java > /dev/null; then
  for f in compare/*.java; do
    run "$(basename "${f%.*}")_java" compare java "$(basename "$f")"
  done
  for f in compare_fail/*.java; do
    run "$(basename "${f%.*}")_javac" compare_fail javac -d "../out/classes" "$(basename "$f")"
  done
else
  echo "skip Java comparisons: java not found"
  [ "${REQUIRE_COMPARE:-}" = 1 ] && status=1
fi
exit $status
