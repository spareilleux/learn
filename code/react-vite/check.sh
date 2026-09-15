#!/usr/bin/env bash
# React (Vite) course: scaffold a project with create-vite, start Vite's dev server and watch an HMR update, check the
# course's application with tsc and build it with Vite, check each error snippet with tsc, lint with oxlint, run every
# Vitest file, and compare every output with expected/.
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
# Run npm ci in this folder first.
set -uo pipefail
# Git Bash on Windows would turn arguments such as /learn/react-vite/ into Windows paths
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"
bin=node_modules/.bin
echo "node $(node --version), npm $(npm --version), tsc $($bin/tsc --version), vite $(node -p "require('vite/package.json').version"), vitest $($bin/vitest --version)"
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

# print <file>: the content of a file; files <folder>: the files under a folder, sorted, without node_modules
print() { node -e "process.stdout.write(require('node:fs').readFileSync(process.argv[1], 'utf8'))" "$1"; }
files() { node scripts/files.mjs "$1"; }

# Lesson 1: the project that create-vite writes
rm -rf out/guitar-app
run l01_create out "../$bin/create-vite" guitar-app --template react-ts --no-interactive
run l01_create_files . files out/guitar-app
run l01_create_package . print out/guitar-app/package.json

# Lesson 1: the dev server, what it serves, and an HMR update
run l01_dev_start . node scripts/dev-start.mjs
run l01_dev_index . node scripts/dev-module.mjs ""
run l01_dev_main . node scripts/dev-module.mjs src/main.tsx
run l01_dev_app . node scripts/dev-module.mjs src/App.tsx
run l01_hmr . node scripts/hmr.mjs

# Lesson 1: type-check, then build for production
run l01_tsc . "$bin/tsc" -b --pretty false
rm -rf dist
run l01_build . "$bin/vite" build
run l01_dist_files . files dist

# Lesson 1: a type error that vite build ships and tsc -b stops
rm -rf out/l01-type-error && mkdir -p out/l01-type-error
cp -r index.html src tsconfig.json tsconfig.app.json tsconfig.node.json vite.config.ts out/l01-type-error/
node -e "
  const fs = require('node:fs'), file = 'out/l01-type-error/src/App.tsx';
  fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replace('count + 1', \"count + '1'\"));"
run l01_type_error_vite out/l01-type-error "../../$bin/vite" build
run l01_type_error_tsc out/l01-type-error "../../$bin/tsc" -b --pretty false

# Lesson 1, exercise 3: a build for a site served under a base path, as this site is under /learn
rm -rf out/l01-base
run l01_base . "$bin/vite" build --base /learn/react-vite/ --outDir out/l01-base
run l01_base_index . print out/l01-base/index.html

# Lesson 2: what JSX compiles to
run l02_jsx_card . node scripts/jsx.mjs src/l02/TuningCard.tsx
run l02_jsx_list . node scripts/jsx.mjs src/l02/TuningList.tsx

# The template's lint rules, on the course's code
run lint . "$bin/oxlint" src

# Error snippets: tsc checks each one alone, with the application's options (tsc refuses a file name next to a
# tsconfig.json, so each gets a small tsconfig that extends the application's)
for f in errors/*.tsx; do
  name=$(basename "${f%.*}")
  printf '{ "extends": "../tsconfig.app.json", "include": [], "files": ["../%s"] }\n' "$f" > "out/tsconfig.$name.json"
  run "${name}_tsc" . "$bin/tsc" -p "out/tsconfig.$name.json" --pretty true
done

# Tests: one Vitest run per file, printed by the course's reporter, so that the output doesn't depend on the order or
# the timing of the run
for f in $(find src -name '*.test.tsx' | sort); do
  name=$(echo "${f#src/}" | sed 's|\.test\.tsx$||; s|/|_|g')
  run "test_$name" . "$bin/vitest" run "$f" --reporter=./scripts/reporter.mjs
done
exit $status
