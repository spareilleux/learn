#!/usr/bin/env bash
# Runs the builds of lesson 10 and writes the outputs the lesson quotes into the directory given as argument.
# CI compares that directory with l10/expected. Paths are shortened and trailing spaces removed so that the
# outputs are the same on Windows, Linux and macOS.
set -o pipefail
out=$1
if [ -z "$out" ]; then
  echo "usage: l10/check.sh <output directory>" >&2
  exit 2
fi
mkdir -p "$out"
out=$(cd "$out" && pwd)
here=$(cd "$(dirname "$0")" && pwd)
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*) sep=';' ;;
  *) sep=':' ;;
esac

tidy() {
  sed -e 's/[[:space:]]*$//' -e 's#^.*[/\\]\([A-Za-z]*\.java:[0-9]*: \)#\1#'
}

# Runs app.Main on the class path Maven resolved: standard output, then the first line of any stack trace.
run_maven_app() {
  java -cp "app/target/classes$sep$(cat app/target/classpath.txt)" app.Main > "$out/stdout.tmp" 2> "$out/stderr.tmp"
  cat "$out/stdout.tmp"
  grep -m1 '^Exception in thread' "$out/stderr.tmp"
  rm -f "$out/stdout.tmp" "$out/stderr.tmp"
}

cd "$here/maven" || exit 1
./mvnw -q -B --version > /dev/null
for variant in default pin direct; do
  profile=
  [ "$variant" != default ] && profile=-P$variant
  ./mvnw -q -B $profile clean package dependency:tree dependency:build-classpath \
    -Dverbose -DoutputFile=target/tree.txt -Dmdep.outputFile=target/classpath.txt || exit 1
  { cat app/target/tree.txt; run_maven_app; } | tidy > "$out/maven-$variant.txt"
done
./mvnw -B -Penforce validate 2>&1 | grep '^\[ERROR\] ' | sed -n '/Require upper bound/,/^\[ERROR\] \]$/p' | tidy > "$out/maven-enforce.txt"
./mvnw -B -Ppin package dependency:analyze -DskipTests 2>&1 | grep -A1 'Used undeclared' | tidy > "$out/maven-analyze.txt"

cd "$here/gradle" || exit 1
./gradlew -q --version > /dev/null
./gradlew -q :app:dependencies --configuration runtimeClasspath | tidy > "$out/gradle-runtime.txt"
./gradlew -q :app:dependencies --configuration compileClasspath | tidy > "$out/gradle-compile.txt"
./gradlew -q :app:run | tidy > "$out/gradle-run.txt"
./gradlew -q :app:dependencyInsight --dependency commons-lang3 --configuration runtimeClasspath \
  | sed -n '/Selection reasons/,$p' | tidy > "$out/gradle-insight.txt"
./gradlew -q :app:compileLeakJava 2>&1 | sed -n '1,/errors*$/p' | tidy > "$out/gradle-leak.txt"
./gradlew -q -PfailOnConflict :app:run 2>&1 | sed -n '/What went wrong/,/identical cause/p' | tidy > "$out/gradle-fail-on-conflict.txt"
./gradlew -q -PstrictLang3 :app:dependencies --configuration runtimeClasspath | tidy > "$out/gradle-strict.txt"
./gradlew -q -PstrictLang3 :app:run > "$out/stdout.tmp" 2> "$out/stderr.tmp"
{ cat "$out/stdout.tmp"; grep -m1 '^Exception in thread' "$out/stderr.tmp"; } | tidy >> "$out/gradle-strict.txt"
rm -f "$out/stdout.tmp" "$out/stderr.tmp"

cd "$here/nuget/App" || exit 1
dotnet restore -nologo -p:Downgrade=true 2>&1 | grep 'error NU1605' | sed 's/^.*App\.csproj : //' | awk '!seen[$0]++' | tidy > "$out/nuget-downgrade.txt"
dotnet restore -nologo > /dev/null || exit 1
dotnet list package --include-transitive | grep -v -e 'projects to restore' -e 'up-to-date for restore' | tidy > "$out/nuget-resolve.txt"
dotnet run -nologo | tidy >> "$out/nuget-resolve.txt"
