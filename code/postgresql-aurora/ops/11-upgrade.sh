#!/usr/bin/env bash
# Lesson 11: a major upgrade from PostgreSQL 17 to 18 with pg_upgrade, and the statistics it keeps.
# Needs the PostgreSQL 17 binaries in the course container, installed first as root (check.sh does it):
#   docker exec pg sh -c 'apt-get update -qq && apt-get install -qq -y --no-install-recommends postgresql-17'
# Run as the postgres user: bash check.sh ops, or docker exec -i -u postgres pg bash -s < ops/11-upgrade.sh
set -u
export PGUSER=postgres
old=/usr/lib/postgresql/17/bin new=/usr/lib/postgresql/18/bin
cd /tmp
rm -rf pg17 pg18 ./*.log
say() { printf '\n-- %s\n' "$*"; }
sql() { local port=$1; shift; psql -X -p "$port" -d learn "$@" 2>&1; }

say "A PostgreSQL 17 cluster, with a table, its statistics, and extended statistics"
$old/initdb -D pg17 --auth=trust > /dev/null
$old/pg_ctl -D pg17 -l pg17.log -o "-p 5436" -w start > /dev/null || exit 1
psql -X -q -p 5436 -c 'CREATE DATABASE learn'
sql 5436 -q <<'EOF'
CREATE SCHEMA ci;
CREATE TABLE ci.runs (
    run_id bigint PRIMARY KEY, workflow_name text NOT NULL, event text NOT NULL, conclusion text,
    head_branch text NOT NULL, created_at timestamptz NOT NULL
);
INSERT INTO ci.runs
SELECT r."databaseId", r."workflowName", r.event, r.conclusion, r."headBranch", r."createdAt"
FROM jsonb_to_recordset(pg_read_file('/course/data/runs.json')::jsonb) AS r(
    "databaseId" bigint, "workflowName" text, event text, conclusion text, "headBranch" text, "createdAt" timestamptz);
CREATE STATISTICS ci.runs_workflow_event (dependencies) ON workflow_name, event FROM ci.runs;
ANALYZE ci.runs;
EOF
# The major version only: the minor one moves with the Debian packages
sql 5436 -c "SELECT current_setting('server_version_num')::int / 10000 AS version, current_setting('data_checksums') AS checksums"
statistics="SELECT (SELECT count(*) FROM pg_stats WHERE schemaname = 'ci') AS column_stats,
                   (SELECT count(*) FROM pg_stats_ext WHERE statistics_schemaname = 'ci') AS extended_stats"
sql 5436 -c "$statistics"
$old/pg_ctl -D pg17 -m fast -w stop > /dev/null

say "A new 18 cluster: initdb 18 turns data checksums on, 17 left them off"
$new/initdb -D pg18 --auth=trust > /dev/null
$new/pg_upgrade --old-bindir=$old --new-bindir=$new --old-datadir=pg17 --new-datadir=pg18 --check 2>&1 | grep -v '^$'
rm -rf pg18
$new/initdb -D pg18 --auth=trust --no-data-checksums > /dev/null

say "The upgrade: --swap moves the old data directory into the new cluster, so the 17 cluster can't be started again"
$new/pg_upgrade --old-bindir=$old --new-bindir=$new --old-datadir=pg17 --new-datadir=pg18 --swap 2>&1 | grep -v '^$'
$new/pg_ctl -D pg18 -l pg18.log -o "-p 5436" -w start > /dev/null || exit 1
sql 5436 -c "SELECT current_setting('server_version_num')::int / 10000 AS version, count(*) AS runs FROM ci.runs"
# Column statistics came across; extended statistics didn't
sql 5436 -c "$statistics"
$new/vacuumdb -p 5436 --all --analyze-only --missing-stats-only 2>&1
sql 5436 -c "$statistics"

say "Clean-up"
$new/pg_ctl -D pg18 -m fast -w stop > /dev/null
rm -rf pg17 pg18 ./*.log delete_old_cluster.sh
echo "done"
