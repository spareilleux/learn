#!/usr/bin/env bash
# Runs the builds of lesson 11 and writes the outputs the lesson quotes into the directory given as argument.
# CI compares that directory with l11/expected. The failure messages quoted in the lesson are checked by
# FailureMessagesTest itself, against src/test/resources/messages.
set -o pipefail
out=$1
if [ -z "$out" ]; then
  echo "usage: l11/check.sh <output directory>" >&2
  exit 2
fi
mkdir -p "$out"
out=$(cd "$out" && pwd)
cd "$(dirname "$0")" || exit 1

tidy() {
  sed -e 's/[[:space:]]*$//'
}

mvn -B clean verify > "$out/verify.log" 2>&1 || { cat "$out/verify.log"; exit 1; }
grep '^\[INFO\] Tests run: [0-9]*, Failures: 0, Errors: 0, Skipped: 0$' "$out/verify.log" | tidy > "$out/tests-run.txt"
cat target/surefire-reports/TEST-*.xml | grep -o '<testcase name="[^"]*"' | sed -e 's/^<testcase name="//' -e 's/"$//' -e 's/&quot;/"/g' \
  | LC_ALL=C sort | tidy > "$out/test-names.txt"
rm "$out/verify.log"

# Without the agent, Mockito attaches itself and the JVM warns about it.
mvn -B test -Pself-attach 2>&1 \
  | grep -e '^Mockito is currently self-attaching' -e '^WARNING: A Java agent' -e '^WARNING: If a serviceability' -e '^WARNING: Dynamic loading' \
  | sed 's/loaded dynamically (.*[/\\]\(byte-buddy-agent-[0-9.]*\.jar\))/loaded dynamically (…\1)/' | awk '!seen[$0]++' | tidy > "$out/self-attach.txt"

# NullAway rejects the deliberately wrong class; javac alone accepts it.
mvn -B clean compile -Pnullaway 2>&1 | sed -n '/COMPILATION ERROR/,/BUILD FAILURE/p' | grep 'NullAway' \
  | sed 's#^\[ERROR\] .*[/\\]\(Discounts\.java\)#[ERROR] \1#' | tidy > "$out/nullaway.txt"
mvn -B -q clean
