#!/usr/bin/env bash
# Advanced TypeScript course: type-check the examples, solutions and type tests with tsc, run them with Node.js, check
# each error snippet with tsc and run it with Node.js, and compare every output with expected/.
# The C# and Java comparisons run too when dotnet and java are installed (REQUIRE_COMPARE=1 makes them mandatory).
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
# Run npm ci in this folder first.
set -uo pipefail
cd "$(dirname "$0")"
tsc=node_modules/.bin/tsc
echo "node $(node --version), npm $(npm --version), tsc $($tsc --version)"
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

# The whole project: examples, solutions and their type tests (Expect<Equal<…>>, @ts-expect-error) must pass
run tsc_project . "$tsc" --pretty false

# Examples and solutions, run by Node.js, which strips the types
for f in examples/*.ts solutions/*.ts; do
  [ -e "$f" ] || continue
  name=$(basename "${f%.*}")
  case $name in show | type-tests) continue ;; esac
  run "$name" . node "$f"
done

# Error snippets: tsc checks each one alone, with the course's options (tsc refuses a file name next to a tsconfig.json,
# so each gets a small tsconfig that extends the course's), then Node.js runs it anyway
for f in errors/*.ts; do
  name=$(basename "${f%.*}")
  printf '{ "extends": "../tsconfig.json", "include": [], "files": ["../%s"] }\n' "$f" > "out/tsconfig.$name.json"
  run "${name}_tsc" . "$tsc" -p "out/tsconfig.$name.json" --pretty true
  # A line "// tsc options: …" checks the snippet a second time with those options added
  options=$(sed -n 's|^// tsc options: ||p' "$f" | head -1 | tr -d '\r')
  if [ -n "$options" ]; then
    # shellcheck disable=SC2086
    run "${name}_tsc_options" . "$tsc" -p "out/tsconfig.$name.json" --pretty true $options
  fi
  run "${name}_node" . node "$f"
done

# Lesson 4: the same schema bundled with each validation library, as a browser build would
run l04_bundle_sizes . node bundle-size.mjs

# The C# and Java sides of the comparisons
# csharp <file>: cleans, then builds and runs a file-based app, so the compiler's warnings are printed on every run
csharp() {
  dotnet clean "$1" > /dev/null 2>&1
  dotnet run --no-cache "$1"
}
if command -v dotnet > /dev/null; then
  for f in compare/*.cs compare_fail/*.cs; do
    [ -e "$f" ] || continue
    run "$(basename "${f%.*}")_cs" "$(dirname "$f")" csharp "$(basename "$f")"
  done
else
  echo "skip C# comparisons: dotnet not found"
  [ "${REQUIRE_COMPARE:-}" = 1 ] && status=1
fi
if command -v java > /dev/null; then
  for f in compare/*.java; do
    [ -e "$f" ] || continue
    run "$(basename "${f%.*}")_java" compare java "$(basename "$f")"
  done
  for f in compare_fail/*.java; do
    [ -e "$f" ] || continue
    run "$(basename "${f%.*}")_javac" compare_fail javac -d "../out/classes" "$(basename "$f")"
  done
else
  echo "skip Java comparisons: java not found"
  [ "${REQUIRE_COMPARE:-}" = 1 ] && status=1
fi
exit $status
