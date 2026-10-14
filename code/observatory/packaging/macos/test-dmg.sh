#!/usr/bin/env bash
# Opens the disk image as a reader would, copies the app out of it (as dragging it onto Applications does,
# into a folder of the test's own), checks its architectures and signature, runs it headless, removes it.
#   bash test-dmg.sh <Observatory-<version>-macos.dmg>
set -euo pipefail
dmg=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
fail=0
check() { if eval "$2"; then echo "ok    $1"; else echo "FAIL  $1"; fail=1; fi; }

mnt=$(mktemp -d)
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$mnt" "$dmg"
trap 'hdiutil detach -quiet "$mnt" || true' EXIT
check 'the image holds Observatory.app' '[ -d "$mnt/Observatory.app" ]'
check 'and a link to /Applications' '[ -L "$mnt/Applications" ] && [ "$(readlink "$mnt/Applications")" = /Applications ]'
check 'and the notices' '[ -f "$mnt/LICENSES.txt" ] && [ -f "$mnt/GODOT_COPYRIGHT.txt" ] && [ -f "$mnt/README.txt" ]'

apps=$(mktemp -d)/Applications
mkdir -p "$apps"
ditto "$mnt/Observatory.app" "$apps/Observatory.app"
exe="$apps/Observatory.app/Contents/MacOS/Observatory"
archs=$(lipo -archs "$exe")
check "universal: $archs" '[ "$archs" = "x86_64 arm64" ]'
check 'its signature verifies' 'codesign --verify --deep --strict "$apps/Observatory.app"'
version=$(defaults read "$apps/Observatory.app/Contents/Info" CFBundleShortVersionString)
check "Info.plist: $(defaults read "$apps/Observatory.app/Contents/Info" CFBundleIdentifier) $version" '[ -n "$version" ]'

# Headless: Godot's dummy display and renderer, thirty frames, then it quits (perl's alarm: macOS has
# no timeout command).
set +e
perl -e 'alarm 300; exec @ARGV' "$exe" --headless --quit-after 30 > "$apps/run.log" 2>&1
code=$?
set -e
head -n 1 "$apps/run.log"
check "the program ran and quit (exit $code)" '[ "$code" -eq 0 ]'
errors=$(grep -cE 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$apps/run.log" || true)
check "no error line in its output ($errors)" '[ "$errors" -eq 0 ]'
[ "$errors" -eq 0 ] || grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$apps/run.log" | head -n 8

rm -rf "$apps/Observatory.app"
check 'removed' '[ ! -e "$apps/Observatory.app" ]'
exit $fail
