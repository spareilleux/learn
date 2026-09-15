#!/usr/bin/env bash
# Python course: type-check the examples, solutions and tests with mypy, run every example and solution with Python,
# check each error snippet with mypy and run it with Python, run the scripts with their inline dependencies and the
# tests with pytest, and compare every output with expected/.
# The C# and Java comparisons run too when dotnet and java are installed (REQUIRE_COMPARE=1 makes them mandatory).
# SKIP_COMPARE=1 skips them, to check the Python side quickly.
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
# Run uv sync --locked in this folder first.
set -uo pipefail
cd "$(dirname "$0")"
# Outputs in UTF-8 on every OS, without colors, and no __pycache__ folders next to the snippets
export PYTHONUTF8=1 PYTHON_COLORS=0 NO_COLOR=1 PYTHONDONTWRITEBYTECODE=1
echo "$(uv --version), $(uv run --frozen python --version), $(uv run --frozen mypy --version)"
COURSE_DIR=$PWD
status=0
rm -rf out
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

# run [--uv] <name> <folder> <command…>: runs the command from the folder, then normalizes its output and adds the
# exit code; --uv also drops uv's progress lines
run() {
  local flags=()
  if [ "$1" = --uv ]; then flags=(--uv); shift; fi
  local name=$1 dir=$2
  shift 2
  (cd "$dir" && "$@") > "out/$name.raw.txt" 2>&1
  local code=$?
  { uv run --frozen --project "$COURSE_DIR" python "$COURSE_DIR/normalize.py" "${flags[@]}" < "out/$name.raw.txt"; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
}

# py <arguments…>: the course's Python, from any folder
py() { uv run --frozen --project "$COURSE_DIR" python "$@"; }

# The whole project: examples, solutions and tests must type-check under mypy --strict
run mypy_project . uv run --frozen mypy

# Examples and solutions, run by Python
for f in examples/*.py solutions/*.py; do
  [ -e "$f" ] || continue
  run "$(basename "${f%.py}")" . py "$f"
done

# Error snippets: mypy checks each one alone, with the course's options, then Python runs it anyway
for f in errors/*.py; do
  name=$(basename "${f%.py}")
  run "${name}_mypy" . uv run --frozen mypy "$f"
  run "${name}_python" . py "$f"
done

# Scripts that declare their own dependencies (PEP 723): uv creates an environment for each one
for f in scripts/*.py; do
  [ -e "$f" ] || continue
  run --uv "$(basename "${f%.py}")" . uv run --script "$f"
done

# The tests
run pytest . uv run --frozen pytest -q

# Lesson 1
# The versions that uv resolves in the demonstration project: the packages published before this date
export UV_EXCLUDE_NEWER=2026-09-15T00:00:00Z
run l01_py_compile . py -m py_compile errors/l01_order.py
rm -rf out/uv-demo && mkdir -p out/uv-demo
run --uv l01_uv_init out/uv-demo uv init hello --python 3.14.7 --author-from none --vcs none --no-workspace
run l01_uv_init_files out/uv-demo/hello py -c "import pathlib; [print(p.as_posix()) for p in sorted(pathlib.Path('.').rglob('*'))]"
run l01_uv_init_pyproject out/uv-demo/hello py -c "print(open('pyproject.toml').read(), end='')"
run --uv l01_uv_run out/uv-demo/hello uv run hello
run --uv l01_uv_add out/uv-demo/hello uv add httpx==0.28.1
run --uv l01_uv_add_dev out/uv-demo/hello uv add --dev pytest==9.1.1
run l01_uv_add_pyproject out/uv-demo/hello py -c "print(open('pyproject.toml').read(), end='')"
run --uv l01_uv_tree out/uv-demo/hello uv tree --universal
run --uv l01_uv_lock_check out/uv-demo/hello uv lock --check
# Exercise 3: a .python-version that the project's requires-python refuses
rm -rf out/pin && mkdir -p out/pin
printf '[project]\nname = "pin"\nversion = "0.1.0"\nrequires-python = ">=3.15"\ndependencies = []\n' > out/pin/pyproject.toml
printf '3.14.7\n' > out/pin/.python-version
run l01-ex3_pin out/pin uv run python --version

# Lesson 3: the order of a set of strings depends on the seed of str's hash function, random in each process by default
for seed in 1 2; do
  run "l03_hash_seed_$seed" . env PYTHONHASHSEED=$seed uv run --frozen python -c "print({'E', 'A', 'D', 'G', 'B'})"
done

# The C# and Java sides of the comparisons
# csharp <file>: cleans, then builds and runs a file-based app, so the compiler's warnings are printed on every run
csharp() {
  dotnet clean "$1" > /dev/null 2>&1
  dotnet run --no-cache "$1"
}
if [ -n "${SKIP_COMPARE:-}" ]; then
  echo "skip C# and Java comparisons: SKIP_COMPARE is set"
elif command -v dotnet > /dev/null; then
  for f in compare/*.cs compare_fail/*.cs; do
    [ -e "$f" ] || continue
    run "$(basename "${f%.*}")_cs" "$(dirname "$f")" csharp "$(basename "$f")"
  done
else
  echo "skip C# comparisons: dotnet not found"
  [ "${REQUIRE_COMPARE:-}" = 1 ] && status=1
fi
if [ -n "${SKIP_COMPARE:-}" ]; then
  :
elif command -v java > /dev/null; then
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
