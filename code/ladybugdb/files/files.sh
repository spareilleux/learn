#!/usr/bin/env bash
# LadybugDB course, lesson 8: database files, the WAL, two processes on one file, a killed process,
# EXPORT and IMPORT DATABASE, and storage versions.
# Run from code/ladybugdb: bash files/files.sh (needs lbug, and lbug19 for the last part)
# Lines starting with "# " depend on the operating system: check.sh prints them without comparing them.
set -uo pipefail
cd "$(dirname "$0")/.."
D=out/files
rm -rf "$D" && mkdir -p "$D"

# The CLI in CSV mode, with the paths and OS error details of its messages made the same on every OS
q() {
  lbug --no_progress_bar --no_stats --mode csv "$@" 2>&1 | tr -d '\r' |
    sed -E 's#[^ ]*[/\\]out[/\\]files[/\\]#out/files/#g; s/ \(Error: [^)]*\)//; s/ handle: [0-9]+//'
}
files() { echo "files: $(cd "$D" && ls -1 | grep -v '\.txt$' | tr '\n' ' ')"; }
# Waits for a file to exist, for at most 30 seconds.
# The CLI writes its output to a file only when it exits: its output can't tell that a query has run.
wait_for() {
  for _ in $(seq 150); do
    [ -e "$1" ] && return 0
    sleep 0.2
  done
  echo "timeout waiting for $1"
}
LOAD="CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING, language STRING, sdk STRING, frameworks STRING, in_solution BOOLEAN);
CREATE REL TABLE REFERENCES(FROM Project TO Project);
COPY Project FROM 'data/ga/projects.csv' (HEADER = true);
COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true, IGNORE_ERRORS = true);"
COUNT="MATCH (p:Project) RETURN count(*) AS projects;"

echo "== 1. A read-only CLI can't create a file"
echo "RETURN 1;" | q --read_only "$D/ga.lbdb"
files

echo "== 2. Create and load, then close"
echo "$LOAD" | q "$D/ga.lbdb" > /dev/null
files

echo "== 3. A process that stays open after a commit"
lbug --no_progress_bar --no_stats --mode csv "$D/ga.lbdb" > "$D/writer.txt" 2>&1 < <(
  echo "CREATE (:Project {path: 'New/One.csproj', name: 'One'});"
  sleep 20) &
writer=$!
# The commit writes the WAL
wait_for "$D/ga.lbdb.wal"
files
echo "-- a second process, read-write"
echo "$COUNT" | q "$D/ga.lbdb"
echo "-- a second process, read-only"
echo "$COUNT" | q --read_only "$D/ga.lbdb" | sed 's/^/# /'

echo "== 4. The same process, killed"
kill -9 $writer
wait $writer 2>/dev/null
files
echo "$COUNT" | q "$D/ga.lbdb"
files

echo "== 5. Killed inside a transaction"
lbug --no_progress_bar --no_stats --mode csv "$D/ga.lbdb" > "$D/writer.txt" 2>&1 < <(
  echo "BEGIN TRANSACTION;"
  echo "CREATE (:Project {path: 'New/Two.csproj', name: 'Two'});"
  sleep 20) &
writer=$!
# Nothing on disk shows an uncommitted transaction: give the CLI time to run it
sleep 5
files
kill -9 $writer
wait $writer 2>/dev/null
echo "MATCH (p:Project) WHERE p.path STARTS WITH 'New/' RETURN p.name ORDER BY p.name;" | q "$D/ga.lbdb"

echo "== 6. A read-only process, then a writer"
lbug --no_progress_bar --no_stats --mode csv --read_only "$D/ga.lbdb" > "$D/reader.txt" 2>&1 < <(
  echo "$COUNT"
  sleep 8
  echo "$COUNT"
  echo "MATCH (p:Project {name: 'GA.Core'}) RETURN count(*) AS ga_core;") &
reader=$!
sleep 3
q "$D/ga.lbdb" <<EOF
MATCH (p:Project {name: 'GA.Core'}) DETACH DELETE p;
UNWIND range(1, 1000) AS i CREATE (:Project {path: 'Generated/' + string(i), name: 'Generated' + string(i)});
CHECKPOINT;
$COUNT
EOF
wait $reader
echo "-- what the reader saw"
tr -d '\r' < "$D/reader.txt"

echo "== 7. EXPORT DATABASE and IMPORT DATABASE"
echo "CREATE MACRO major(version) AS split_part(version, '.', 1);" | q "$D/ga.lbdb"
echo "EXPORT DATABASE '$D/export' (format = 'csv', header = true);" | q "$D/ga.lbdb"
echo "export: $(cd "$D/export" && ls -1 | tr '\n' ' ')"
tr -d '\r' < "$D/export/schema.cypher"
# The order of the COPY options changes from one OS to the next
tr -d '\r' < "$D/export/copy.cypher" | sed 's/^/# /'
head -1 "$D/export/Project.csv" | tr -d '\r'
q "$D/imported.lbdb" <<EOF
IMPORT DATABASE '$D/export';
$COUNT
MATCH ()-[r:REFERENCES]->() RETURN count(*) AS references;
RETURN major('10.0.1') AS major;
EOF
echo "-- into a database that isn't empty"
echo "IMPORT DATABASE '$D/export';" | q "$D/ga.lbdb"

echo "== 8. A file of LadybugDB 0.19.1, opened by 0.20.4"
if command -v lbug19 > /dev/null; then
  q19() { lbug19 --no_progress_bar --no_stats --mode csv "$@" 2>&1 | tr -d '\r'; }
  echo "CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING); CREATE (:Project {path: 'Common/GA.Core/GA.Core.csproj', name: 'GA.Core'});" | q19 "$D/old.lbdb" > /dev/null
  echo "-- 0.20.4, read-only"
  echo "$COUNT" | q --read_only "$D/old.lbdb"
  echo "-- 0.19.1"
  echo "$COUNT" | q19 "$D/old.lbdb"
  echo "-- 0.20.4, read-write"
  echo "$COUNT" | q "$D/old.lbdb"
  echo "-- 0.19.1 again"
  echo "$COUNT" | q19 "$D/old.lbdb"
else
  echo "skip: lbug19 not found"
fi
