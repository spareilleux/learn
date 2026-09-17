#!/usr/bin/env bash
# Advanced C#: fetch the pinned GA projects, build the course programs, then compare with expected/:
# the output of each lesson, the IL and decompiled code the lessons show, and the errors of the rejected snippets.
# Lines starting with "# " depend on the machine or on timing: printed, not compared.
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
set -uo pipefail
cd "$(dirname "$0")"
bash fetch-ga.sh || exit 1
dotnet tool restore > /dev/null || exit 1
dotnet build Advanced -c Release -m:4 --nologo -v quiet "-clp:ErrorsOnly;NoSummary" || exit 1
dotnet build CompileFail -c Release -m:4 --nologo -v quiet "-clp:ErrorsOnly;NoSummary" || exit 1
# Appendix 2 builds against its own GA commit, in .ga-perf
dotnet build GaPerf -c Release -m:4 --nologo -v quiet "-clp:ErrorsOnly;NoSummary" || exit 1
# The same snippets built as Debug, for the class the compiler generates there (lesson 3)
dotnet build Snippets -c Debug -m:4 --nologo -v quiet "-clp:ErrorsOnly;NoSummary" || exit 1
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

# Runs the course program with optional environment variables: run <name> <lesson> [VAR=value...]
run() {
  local name=$1 lesson=$2
  shift 2
  env "$@" dotnet run --project Advanced -c Release --no-build -- "$lesson" < /dev/null > "out/$name.raw.txt" 2>&1
  local code=$?
  grep '^# ' "out/$name.raw.txt"
  { grep -v '^# ' "out/$name.raw.txt"; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
}

run l1 l1
run l1-boxing-no-tiering l1-boxing DOTNET_TieredCompilation=0
run l2 l2
run l2-modes-server l2-modes DOTNET_gcServer=1
run l2-modes-non-concurrent l2-modes DOTNET_gcConcurrent=0
run l3 l3
run l4 l4
run l5 l5

# Lesson 5: the Describe methods the JIT compiled for Lesson5.Shared<T>, from the JIT's own summary,
# without the tier and the code size, which depend on the machine. The app is started directly, not through
# dotnet run, so that the SDK's own process doesn't write to the same file
rm -f out/l5-jit-summary.raw.txt
DOTNET_JitStdOutFile=out/l5-jit-summary.raw.txt DOTNET_JitDisasmSummary=1   dotnet Advanced/bin/Release/net10.0/Advanced.dll l5-jit < /dev/null > out/l5-jit.raw.txt 2>&1
grep '^# ' out/l5-jit.raw.txt
{ grep -v '^# ' out/l5-jit.raw.txt; echo "JIT summary:"; grep -o 'Lesson5+Shared`1\[[^]]*\]:Describe([^)]*)' out/l5-jit-summary.raw.txt | LC_ALL=C sort -u; } > out/l5-jit.txt
compare l5-jit
run l6 l6
run l7 l7
run l8 l8
run l9 l9
run a1 a1

# Appendix 2: the same comparison as run(), for the GaPerf program
a2() {
  dotnet run --project GaPerf -c Release --no-build -- a2 < /dev/null > out/a2.raw.txt 2>&1
  local code=$?
  grep '^# ' out/a2.raw.txt
  { grep -v '^# ' out/a2.raw.txt; echo "exit $code"; } > out/a2.txt
  compare a2
}
a2

ilspy() {
  dotnet ilspycmd --disable-updatecheck "$@" 2>&1
}

# Lessons 1 and 3: the IL of the whole Snippets assembly (-il ignores -t), without the RVA comments that move when it grows
release=Snippets/bin/Release/net10.0/Snippets.dll
debug=Snippets/bin/Debug/net10.0/Snippets.dll
ilspy -il "$release" | grep -v '// Method begins at RVA' > out/snippets-il.txt
compare snippets-il

# Lesson 3: the async method decompiled as C# 4, which had no async/await, from the Release and the Debug builds
ilspy -lv CSharp4 -t Snippets.AsyncMachine "$release" > out/l3-state-machine.txt
compare l3-state-machine
ilspy -lv CSharp4 -t Snippets.AsyncMachine "$debug" | grep 'd__0' > out/l3-state-machine-debug.txt
compare l3-state-machine-debug

# Rejected snippets: each one must fail with the error on its first line
dotnet run --project CompileFail -c Release --no-build -- CompileFail/snippets > out/compile-fail.txt 2>&1
echo "exit $?" >> out/compile-fail.txt
compare compile-fail

exit $status
