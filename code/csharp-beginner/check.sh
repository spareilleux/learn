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
# The compiler messages come first, errors before warnings, each group by line and column: the
# compiler prints the same warnings in a different order on Linux than on Windows and macOS.
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
  local message='^[A-Za-z0-9_]+\.cs\([0-9]+,[0-9]+\): (error|warning) '
  sed -E -e 's#^.*[\/]([A-Za-z0-9_]+\.cs\([0-9]+,[0-9]+\))#\1#' -e '/^   at /d' "out/$name.raw.txt" > "out/$name.norm.txt"
  {
    grep -E "$message" "out/$name.norm.txt" |
      awk '{ p = $0; sub(/^[^(]*\(/, "", p); split(p, at, /[,)]/); printf "%d\t%d\t%d\t%s\n", ($0 ~ /\): error /) ? 0 : 1, at[1], at[2], $0 }' |
      sort -s -t "$(printf '\t')" -k1,1n -k2,2n -k3,3n | cut -f4-
    grep -vE "$message" "out/$name.norm.txt"
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

# Lesson 10: a relative path starts from the current directory, so l10_where.cs runs again from the repository root
(cd ../.. && dotnet run code/csharp-beginner/examples/l10_where.cs) > out/l10_where_root.txt 2>&1
echo "exit $?" >> out/l10_where_root.txt
compare l10_where_root

# Keeps what a reader needs from `dotnet test`: compiler warnings without their folder, each failed test with its
# message, and the summary line. Drops what changes from run to run or from OS to OS: restore and build lines,
# paths, durations, stack traces. The failed tests are sorted by name: xUnit doesn't report them in a fixed order.
test_summary() {
  sed -E -e 's#^.*[\/]([A-Za-z0-9_.]+\.cs\([0-9]+,[0-9]+\))#\1#' -e 's# \[[^]]*\.csproj\]$##' \
         -e 's/ \[(< )?[0-9]+ m?s\]$//' -e 's/, Duration: [0-9]+ m?s//' |
    grep -vE '^ *(Determining projects|Restored |All projects|[0-9]+ of [0-9]+ projects|[A-Za-z.]+ -> |Test run for |VSTest version|Starting test execution|A total of |at |Stack Trace:|----- Inner Stack Trace|\[xUnit\.net)' |
    grep -vE '^[[:space:]]*$' |
    LC_ALL=C awk '
      /^  Failed / { if (block != "") print "2" block; block = $0; next }
      /^(Passed!|Failed!) / { if (block != "") print "2" block; block = ""; print "3" $0; next }
      block != "" { block = block "\037" $0; next }
      { print "1" $0 }
      END { if (block != "") print "2" block }' |
    LC_ALL=C sort |
    cut -c2- | tr '\037' '\n'
}

# Lesson 11: the tests of Fretboard.Tests pass; those of Pitfalls.Tests fail on purpose, with the messages the lesson shows.
# dotnet clean first, as for the files above: an up-to-date build prints no warning.
for project in Fretboard.Tests Pitfalls.Tests; do
  dotnet clean "l11-tests/$project" > /dev/null 2>&1
  dotnet test "l11-tests/$project" > "out/l11_$project.raw.txt" 2>&1
  code=$?
  { test_summary < "out/l11_$project.raw.txt"; echo "exit $code"; } > "out/l11_$project.txt"
  compare "l11_$project"
done

# Lesson 3: tools/fretboard.cs draws the fretboard diagram; the committed SVG must be up to date
if dotnet run tools/fretboard.cs -- --check > out/fretboard.txt 2>&1; then
  echo "ok   fretboard svg"
else
  cat out/fretboard.txt
  echo "FAIL fretboard svg: run  dotnet run code/csharp-beginner/tools/fretboard.cs"
  status=1
fi

exit $status
