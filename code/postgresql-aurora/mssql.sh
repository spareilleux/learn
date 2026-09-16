#!/usr/bin/env bash
# Lesson 13's SQL Server, one container named mssql: bash mssql.sh start | copy | sqlcmd <script> | stop
#   start   runs SQL Server 2025, waits until it accepts logins, and copies the course files into /course
#   copy    copies mssql/ and the data files again (after editing a script)
#   sqlcmd  runs a script of mssql/ with sqlcmd inside the container
# ENGINE=podman uses Podman instead of Docker; MS_CONTAINER names another container (CI's service).
set -euo pipefail
cd "$(dirname "$0")"
export MSYS_NO_PATHCONV=1
engine=${ENGINE:-docker}
image=mcr.microsoft.com/mssql/server:2025-CU9-ubuntu-24.04
name=${MS_CONTAINER:-mssql}
# A development password, as for PostgreSQL in server.sh
password='Learn-2026!'
sqlcmd=(/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$password")

wait_ready() {
  for _ in $(seq 1 120); do
    if $engine exec "$name" "${sqlcmd[@]}" -l 2 -Q "SELECT 1" > /dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "SQL Server did not accept logins within 120 s" >&2
  $engine logs --tail 50 "$name" >&2
  return 1
}

copy_files() {
  $engine exec -u 0 "$name" rm -rf /course
  $engine exec -u 0 "$name" mkdir -p /course/data
  $engine cp mssql "$name:/course/mssql"
  $engine cp ../duckdb/data/runs.json "$name:/course/data/runs.json"
  $engine cp ../duckdb/data/jobs.json "$name:/course/data/jobs.json"
  $engine exec -u 0 "$name" chmod -R a+rX /course
}

case ${1:-} in
  start)
    $engine run -d --name "$name" -e ACCEPT_EULA=Y -e "MSSQL_SA_PASSWORD=$password" -e MSSQL_MEMORY_LIMIT_MB=2048 \
      -p 1433:1433 $image > /dev/null
    wait_ready
    copy_files
    ;;
  wait) wait_ready ;;
  copy) copy_files ;;
  sqlcmd)
    # -W trims trailing spaces, -s '|' separates columns; error messages name the container's host name, masked here
    $engine exec "$name" "${sqlcmd[@]}" -W -s '|' -i "/course/mssql/$2" 2>&1 | sed -E 's/, Server [^,]+, /, Server mssql, /'
    ;;
  stop) $engine rm -f "$name" > /dev/null ;;
  *)
    echo "usage: bash mssql.sh start|wait|copy|sqlcmd <script>|stop" >&2
    exit 2
    ;;
esac
