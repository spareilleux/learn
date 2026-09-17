#!/usr/bin/env bash
# Blender course: runs each lesson's bpy script in Blender without a window and compares its report with expected/.
#   bash check.sh                 every lesson
#   bash check.sh l01_datablocks  one script
#   UPDATE=1 bash check.sh        writes the reports to expected/ instead of comparing (review the diff before committing)
# BLENDER is the Blender executable (default: blender on the PATH). Lines of a report that start with "# " are timings
# or sizes that change from run to run: they stay in out/, and check.sh leaves them out of the comparison.
set -uo pipefail
cd "$(dirname "$0")"
BLENDER=${BLENDER:-blender}
status=0
mkdir -p out expected

run() {
  local name=$1
  if ! "$BLENDER" --background --factory-startup --python-exit-code 1 --python "scripts/$name.py" -- out > "out/$name.log" 2>&1; then
    echo "FAIL $name (Blender exited with an error; the end of out/$name.log follows)"
    tail -20 "out/$name.log"
    status=1
    return
  fi
  grep -v '^# ' "out/$name.txt" > "out/$name.cmp"
  grep '^# ' "out/$name.txt" | sed 's/^/     /'
  if [ "${UPDATE:-}" = 1 ]; then
    cp "out/$name.cmp" "expected/$name.txt"
    echo "upd  $name"
  elif diff --strip-trailing-cr "expected/$name.txt" "out/$name.cmp"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
}

"$BLENDER" --version | head -1
if [ $# -gt 0 ]; then
  for name in "$@"; do run "$name"; done
else
  for script in scripts/l[0-9][0-9]_*.py; do run "$(basename "$script" .py)"; done
fi
exit $status
