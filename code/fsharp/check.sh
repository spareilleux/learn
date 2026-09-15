#!/usr/bin/env bash
# F# course: run every script, exercise solution and F# Interactive session and compare its output with expected/,
# check that every rejected snippet fails with the expected compiler message, and build and run the projects.
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
set -uo pipefail
cd "$(dirname "$0")"
export DOTNET_NOLOGO=1 DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_CLI_WORKLOAD_UPDATE_NOTIFY_DISABLE=1
dotnet --version
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

# The compiler messages keep the file name without its folder (file.fsx(line,col): error FSxxxx: ...),
# lose their trailing spaces, the blank lines around them and the " [project.fsproj]" suffix of MSBuild,
# and the "   at ..." lines of a stack trace are dropped: they contain the full paths.
normalize() {
  tr -d '\r' \
    | sed -E -e 's#^.*[\/]([A-Za-z0-9_]+\.fsx?\([0-9]+,[0-9]+\))#\1#' -e 's# \[[^]]*\.fsproj\]$##' \
        -e '/^   at /d' -e 's/[[:space:]]+$//' \
    | cat -s | sed -e '/./,$!d' | awk 1
}

# Runs one script with dotnet fsi. A first line "// check.sh args: ..." gives extra options to fsi.
run_script() {
  local file=$1 name args=""
  name=$(basename "$file" .fsx)
  if head -n 1 "$file" | grep -q '^// check.sh args: '; then
    args=$(head -n 1 "$file" | sed 's#^// check.sh args: ##')
  fi
  # shellcheck disable=SC2086
  dotnet fsi $args "$file" > "out/$name.raw.txt" 2>&1
  local code=$?
  { normalize < "out/$name.raw.txt"; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
}

for f in examples/*.fsx exercises/*.fsx compile_fail/*.fsx; do
  run_script "$f"
done

# F# Interactive sessions: the input is typed on standard input
for f in sessions/*.txt; do
  name=$(basename "$f" .txt)
  dotnet fsi --nologo < "$f" > "out/$name.raw.txt" 2>&1
  code=$?
  { normalize < "out/$name.raw.txt" | sed -e 's/^> $/>/'; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
done

# Lesson 1 projects: one builds and runs, the other two fail with a compiler error
dotnet build l01-project/Hello > out/l01_project_build.raw.txt 2>&1 || { cat out/l01_project_build.raw.txt; status=1; }
dotnet run --project l01-project/Hello --no-build > out/l01_project.raw.txt 2>&1
code=$?
{ normalize < out/l01_project.raw.txt; echo "exit $code"; } > out/l01_project.txt
compare l01_project

for project in l01-order l01-ex-module; do
  name=${project//-/_}
  dotnet build "$project/Hello" > "out/$name.raw.txt" 2>&1
  code=$?
  { grep -E ': (error|warning) FS[0-9]+' "out/$name.raw.txt" | normalize | sort -u; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
done

exit $status
