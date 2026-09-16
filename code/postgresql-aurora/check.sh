#!/usr/bin/env bash
# PostgreSQL and Aurora course: run every lesson script with psql inside the server's container, then the C# and
# Java programs, and compare every output the lessons quote with expected/.
#   bash check.sh build      only builds the C# and Java programs (CI on Windows and macOS: no Docker there)
#   bash check.sh sql        runs the SQL scripts only, except those that need pgvector
#   bash check.sh pgvector   runs sql/*-pgvector*.sql, on a server started with PG_IMAGE=pgvector/pgvector:0.8.6-pg18-trixie
#   bash check.sh programs   runs the C# and Java programs only (already built)
#   bash check.sh            builds, runs the SQL scripts and the programs; the server must be up (bash server.sh start)
#   UPDATE=1 bash check.sh   writes the outputs to expected/ instead of comparing (review the diff before committing)
# PG_CONTAINER and ENGINE are passed on to server.sh; PG_CONNECTION (C#) and PG_JDBC_URL (Java) override where the programs connect.
set -uo pipefail
cd "$(dirname "$0")"
MVN=${MVN:-mvn}
what=${1:-all}
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

psql_quiet() { bash server.sh psql -q "$@" > /dev/null 2>&1; }

# A fresh learn database and no course role, as if the previous lesson had never run
reset() {
  psql_quiet -d postgres -c "DROP DATABASE IF EXISTS learn WITH (FORCE)"
  for role in app reader; do
    psql_quiet -d postgres -c "DROP ROLE IF EXISTS $role"
  done
}

build() {
  dotnet build csharp -c Release -m:1 --nologo -v quiet "-clp:ErrorsOnly;NoSummary" || exit 1
  $MVN -B -q -f java/pom.xml package || exit 1
}

# run_sql <pgvector|other>: the scripts that need pgvector, or the others
run_sql() {
  bash server.sh copy || exit 1
  for script in sql/[0-9][0-9]-*.sql; do
    name=$(basename "$script" .sql)
    case $name in
      *-pgvector*) [ "$1" = pgvector ] || continue ;;
      *) [ "$1" = pgvector ] && continue ;;
    esac
    reset
    if [ "${name#01-getting-started}" = "$name" ]; then
      psql_quiet -d postgres -c "CREATE DATABASE learn"
      db=learn
    else
      db=postgres
    fi
    bash server.sh psql -d $db < "$script" > "out/$name.txt" 2>&1
    compare "$name"
  done
}

# step <expected name> <command...>: runs the command, records its output, compares
step() {
  local name=$1
  shift
  "$@" < /dev/null > "out/$name.txt" 2>&1
  compare "$name"
}

cs() { dotnet csharp/bin/Release/net10.0/pg.dll "$@"; }
# The JDBC driver sends the JVM's time zone to the server: fixed here so that the output is the same on every machine
java_client() { java -Duser.timezone=America/Toronto -jar java/target/pg.jar "$@"; }

run_programs() {
  reset
  psql_quiet -d postgres -c "CREATE DATABASE learn"
  bash server.sh psql -q -d learn -c '\o /dev/null' -c '\ir schema.sql' > /dev/null || exit 1
  # Lesson 4: Npgsql, EF Core, the JDBC driver and HikariCP
  step l04-connect-cs cs l04-connect
  step l04-connect-java java_client l04-connect
  step l04-parameters-cs cs l04-parameters
  step l04-parameters-java java_client l04-parameters
  step l04-pool-cs cs l04-pool
  step l04-pool-java java_client l04-pool
  step l04-prepare-cs cs l04-prepare
  step l04-prepare-java java_client l04-prepare
  step l04-copy-cs cs l04-copy
  step l04-copy-java java_client l04-copy
  step l04-generated-keys-java java_client l04-generated-keys
  step l04-efcore cs l04-efcore
  step l04-efcore-ga cs l04-efcore-ga
  step l04-exercise-batch-cs cs l04-exercise-batch
  step l04-exercise-batch-java java_client l04-exercise-batch
  step l04-too-many-cs cs l04-too-many
  step l04-target-cs cs l04-target
  step l04-target-java java_client l04-target
  # Lesson 6: two sessions at once
  step l06-isolation-cs cs l06-isolation
  step l06-lost-update-cs cs l06-lost-update
  step l06-lost-update-java java_client l06-lost-update
  step l06-write-skew-cs cs l06-write-skew
  step l06-locks-cs cs l06-locks
  step l06-deadlock-cs cs l06-deadlock
  step l06-vacuum-horizon-cs cs l06-vacuum-horizon
  step l06-retry-java java_client l06-retry
  step l06-skip-locked-cs cs l06-skip-locked
  # Lesson 8: functions and procedures from the drivers
  step l08-routines-cs cs l08-routines
  step l08-routines-java java_client l08-routines
  step l08-trigger-error-cs cs l08-trigger-error
  echo "---- lesson 4 timings (not compared)"
  cs l04-timings
}

case $what in
  build) build ;;
  sql) run_sql other ;;
  pgvector) run_sql pgvector ;;
  programs) run_programs ;;
  all)
    build
    run_sql other
    run_programs
    ;;
  *)
    echo "usage: bash check.sh [build|sql|pgvector|programs]" >&2
    exit 2
    ;;
esac
exit $status
