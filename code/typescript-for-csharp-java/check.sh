#!/usr/bin/env bash
# TypeScript course: type-check the examples and solutions with tsc, run them with Node.js, check each error snippet
# with tsc and run it with Node.js, and compare every output with expected/.
# The C# and Java comparisons run too when dotnet and java are installed (REQUIRE_COMPARE=1 makes them mandatory).
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
# Run npm ci in this folder first.
set -uo pipefail
cd "$(dirname "$0")"
tsc=node_modules/.bin/tsc
tsx=node_modules/.bin/tsx
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

# The whole project: examples and solutions must type-check without an error
run tsc_project . "$tsc" --pretty false

# Examples and solutions, run by Node.js, which strips the types
for f in examples/*.ts solutions/*.ts; do
  [ -e "$f" ] || continue
  name=$(basename "${f%.*}")
  [ "$name" = show ] && continue
  run "$name" . node "$f"
done

# Error snippets: tsc checks each one alone, with the course's options (tsc refuses a file name next to a tsconfig.json,
# so each gets a small tsconfig that extends the course's), then Node.js runs it anyway
for f in errors/*.ts; do
  name=$(basename "${f%.*}")
  printf '{ "extends": "../tsconfig.json", "include": [], "files": ["../%s"] }\n' "$f" > "out/tsconfig.$name.json"
  run "${name}_tsc" . "$tsc" -p "out/tsconfig.$name.json" --pretty true
  # A line "// tsc options: …" checks the snippet a second time with those options added
  options=$(sed -n 's|^// tsc options: ||p' "$f" | head -1 | tr -d '')
  if [ -n "$options" ]; then
    # shellcheck disable=SC2086
    run "${name}_tsc_options" . "$tsc" -p "out/tsconfig.$name.json" --pretty true $options
  fi
  run "${name}_node" . node "$f"
done

# Lesson 2: the types tsc infers, as written in a declaration file
"$tsc" -p tsconfig.json --noEmit false --declaration --emitDeclarationOnly --outDir out/dts > /dev/null
run l02_inference_dts . node -e "process.stdout.write(require('node:fs').readFileSync('out/dts/examples/l02_inference.d.ts', 'utf8'))"

# Lesson 1
run l01_tsc_file . "$tsc" examples/l01_order.ts
run l01_enum_tsx . "$tsx" errors/l01_enum.ts
run l01_enum_transform . node --experimental-transform-types errors/l01_enum.ts
rm -rf l01-emit/dist
run l01_emit_tsc l01-emit "../$tsc" --pretty false
run l01_emit_files l01-emit node -e "for (const f of require('node:fs').readdirSync('dist').sort()) console.log('dist/' + f)"
run l01_emit_main_js l01-emit node -e "process.stdout.write(require('node:fs').readFileSync('dist/main.js', 'utf8'))"
run l01_emit_node l01-emit node dist/main.js

# The C# and Java sides of the comparisons (--no-cache rebuilds, so the compiler's warnings are printed on every run)
if command -v dotnet > /dev/null; then
  for f in compare/*.cs compare_fail/*.cs; do
    [ -e "$f" ] || continue
    run "$(basename "${f%.*}")_cs" "$(dirname "$f")" dotnet run --no-cache "$(basename "$f")"
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
