#!/usr/bin/env bash
# Checks every output the lessons quote.
#   1. mvn verify: the JUnit tests run each example, call each endpoint, and compare with <module>/expected.
#   2. Lesson 1's JAR, run with environment variables, compared with l01-mvc/expected/java-jar-env.txt.
#   3. The C# side of each comparison (dotnet run app.cs), compared with csharp/expected.
# Usage: bash check.sh [output directory]; UPDATE=1 rewrites the expected files instead of comparing.
set -euo pipefail
cd "$(dirname "$0")"
out=${1:-out}
mkdir -p "$out"
out=$(cd "$out" && pwd)
status=0

compare() { # expected actual
  if [ "${UPDATE:-}" = 1 ]; then
    cp "$2" "$1"
  elif ! diff --strip-trailing-cr "$1" "$2"; then
    echo "MISMATCH: $1" >&2
    status=1
  fi
}

if [ "${UPDATE:-}" = 1 ]; then
  mvn -B -fae verify -Dupdate.expected=true
else
  mvn -B -fae verify
fi

# Lesson 1: relaxed binding of environment variables, and their precedence over a profile's file.
jar() {
  java -jar l01-mvc/target/scales.jar --spring.main.web-application-type=none \
    --spring.main.banner-mode=off --logging.level.root=warn "$@"
}
{
  echo '$ SCALES_SPELLING=flats java -jar target/scales.jar --spring.profiles.active=print'
  SCALES_SPELLING=flats jar --spring.profiles.active=print
  echo '$ SCALES_DEFAULT_MODE=dorian java -jar target/scales.jar --spring.profiles.active=print,flats'
  SCALES_DEFAULT_MODE=dorian jar --spring.profiles.active=print,flats
} > "$out/java-jar-env.txt"
compare l01-mvc/expected/java-jar-env.txt "$out/java-jar-env.txt"

# The C# side: build first, so that build output never mixes with the program's.
cd csharp
mkdir -p expected
for app in l0*.cs; do
  name=${app%.cs}
  echo "== $name"
  dotnet build "$app" > "$out/$name.build.log" 2>&1 || { cat "$out/$name.build.log"; exit 1; }
  dotnet run --no-build "$app" > "$out/$name.txt"
  compare "expected/$name.txt" "$out/$name.txt"
done

exit $status
