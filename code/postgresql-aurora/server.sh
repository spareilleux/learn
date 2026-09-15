#!/usr/bin/env bash
# The course server, one container named pg: bash server.sh start | wait | copy | psql [args] | stop
#   start  runs PostgreSQL, waits until it accepts TCP connections, and copies the course files into /course
#   copy   copies sql/ and the data files again (after editing a script)
#   psql   runs psql inside the container, in /course/sql, with the course's session settings
# ENGINE=podman uses Podman instead of Docker; PG_CONTAINER names another container (CI's service).
set -euo pipefail
cd "$(dirname "$0")"
export MSYS_NO_PATHCONV=1
engine=${ENGINE:-docker}
image=postgres:18.6-trixie
name=${PG_CONTAINER:-pg}

wait_ready() {
  # -h 127.0.0.1: during its first start, the image's entrypoint runs a temporary server that listens on the
  # Unix socket only (listen_addresses=''), then stops it. pg_isready without -h would see that one.
  for _ in $(seq 1 90); do
    if $engine exec "$name" pg_isready -q -h 127.0.0.1 -U postgres; then
      return 0
    fi
    sleep 1
  done
  echo "PostgreSQL did not accept TCP connections within 90 s" >&2
  $engine logs --tail 50 "$name" >&2
  return 1
}

copy_files() {
  $engine exec "$name" rm -rf /course
  $engine exec "$name" mkdir -p /course/data/ga
  $engine cp sql "$name:/course/sql"
  $engine cp ../duckdb/data/runs.json "$name:/course/data/runs.json"
  $engine cp ../duckdb/data/jobs.json "$name:/course/data/jobs.json"
  for f in projects project_refs package_refs; do
    $engine cp "../ladybugdb/data/ga/$f.csv" "$name:/course/data/ga/$f.csv"
  done
  $engine cp data/iconic_chords.json "$name:/course/data/ga/iconic_chords.json"
}

case ${1:-} in
  start)
    $engine run -d --name "$name" -e POSTGRES_PASSWORD=learn -p 5432:5432 $image > /dev/null
    wait_ready
    copy_files
    ;;
  wait) wait_ready ;;
  copy) copy_files ;;
  psql)
    shift
    # Fixed session settings, so that outputs don't depend on the machine: messages in English, UTC, ISO dates.
    # Errors go to stderr and results to a buffered stdout: stdbuf -o0 and 2>&1 inside the container keep them
    # in the order psql wrote them.
    $engine exec -i -w /course/sql -e PGOPTIONS="-c lc_messages=C -c TimeZone=UTC -c DateStyle=ISO,MDY" \
      "$name" sh -c 'stdbuf -o0 psql -X -U postgres "$@" 2>&1' psql "$@"
    ;;
  stop) $engine rm -f "$name" > /dev/null ;;
  *)
    echo "usage: bash server.sh start|wait|copy|psql [args]|stop" >&2
    exit 2
    ;;
esac
