#!/usr/bin/env bash
# Installs a .deb (apt) or an .rpm (dnf) as a reader would, runs the program headless from the menu
# entry's command, then removes the package and checks nothing is left. Run as root, in a throwaway
# container or a CI runner: it installs and removes system packages.
#   bash test-linux.sh <package file>
set -euo pipefail
pkg=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
app=io.github.spareilleux.observatory
fail=0
check() { if eval "$2"; then echo "ok    $1"; else echo "FAIL  $1"; fail=1; fi; }

case "$pkg" in
  *.deb) export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -y -qq "$pkg" > /tmp/install.log 2>&1 ;;
  *.rpm) dnf install -y -q "$pkg" > /tmp/install.log 2>&1 ;;
  *) echo "not a .deb or .rpm: $pkg" >&2; exit 2 ;;
esac
check 'the launcher is on PATH' 'command -v observatory > /dev/null'
check 'the menu entry names it' "grep -q '^Exec=observatory$' /usr/share/applications/$app.desktop"
check 'its icon is there' "[ -f /usr/share/icons/hicolor/256x256/apps/$app.png ]"
# /usr/share/doc/observatory/copyright too, except where documentation is not installed: rpm marks
# /usr/share/doc as documentation, and Fedora's container image installs none (tsflags=nodocs).
check 'the notices are there' '[ -f /opt/observatory/LICENSES.txt ] && [ -f /opt/observatory/GODOT_COPYRIGHT.txt ]'

# Headless: Godot's dummy display and renderer, thirty frames, then it quits.
set +e
timeout 300 observatory --headless --quit-after 30 > /tmp/run.log 2>&1
code=$?
set -e
head -n 1 /tmp/run.log
check "the program ran and quit (exit $code)" '[ "$code" -eq 0 ]'
errors=$(grep -cE 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' /tmp/run.log || true)
check "no error line in its output ($errors)" '[ "$errors" -eq 0 ]'
[ "$errors" -eq 0 ] || grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' /tmp/run.log | head -n 8

case "$pkg" in
  *.deb) apt-get remove -y -qq observatory > /tmp/remove.log 2>&1 ;;
  *.rpm) dnf remove -y -q observatory > /tmp/remove.log 2>&1 ;;
esac
check 'removed: no program, launcher or menu entry left' "[ ! -e /opt/observatory ] && [ ! -e /usr/bin/observatory ] && [ ! -e /usr/share/applications/$app.desktop ]"
exit $fail
