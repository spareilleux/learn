#!/usr/bin/env bash
# C# for beginners: run every example and exercise solution and compare its output with expected/,
# and check that every rejected snippet fails with the expected compiler errors.
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

# Runs one file-based app: its input comes from input/<name>.txt, if there is one.
# dotnet clean first: the SDK doesn't recompile an unchanged file, and then prints none of its warnings.
# The output keeps the compiler messages without the folder (file(line,col): error CSxxxx: ...),
# drops the "   at ..." lines of a stack trace, and ends with the exit code: 0, 1, or "crash" for an
# unhandled exception, whose code depends on the OS (it is printed, not compared).
run() {
  local file=$1 name
  name=$(basename "$file" .cs)
  local input=/dev/null
  [ -f "input/$name.txt" ] && input="input/$name.txt"
  dotnet clean "$file" > /dev/null 2>&1
  dotnet run "$file" < "$input" > "out/$name.raw.txt" 2>&1
  local code=$?
  local shown=$code
  if [ "$code" != 0 ] && [ "$code" != 1 ]; then
    echo "# $name exit code $code"
    shown=crash
  fi
  {
    sed -E -e 's#^.*[\/]([A-Za-z0-9_]+\.cs\([0-9]+,[0-9]+\))#\1#' -e '/^   at /d' "out/$name.raw.txt"
    echo "exit $shown"
  } > "out/$name.txt"
  compare "$name"
}

for f in examples/*.cs exercises/*.cs compile_fail/*.cs; do
  run "$f"
done

# Lesson 1: the project made by `dotnet new console`
dotnet run --project l01-project/Hello > out/l01_project.txt 2>&1
echo "exit $?" >> out/l01_project.txt
compare l01_project

# Lesson 1: a file with a shebang line runs as a program on Linux and macOS
case "$(uname -s)" in
  Linux|Darwin)
    chmod +x examples/l01_shebang.cs
    ./examples/l01_shebang.cs > out/l01_shebang_exec.txt 2>&1
    echo "exit $?" >> out/l01_shebang_exec.txt
    diff expected/l01_shebang.txt out/l01_shebang_exec.txt && echo "ok   l01_shebang (./)" || { echo "FAIL l01_shebang (./)"; status=1; }
    ;;
esac

exit $status
