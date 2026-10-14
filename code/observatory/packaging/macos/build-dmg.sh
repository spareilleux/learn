#!/usr/bin/env bash
# Godot's macOS export (a zip holding Observatory.app, universal, signed ad hoc by Godot) as a disk image:
# the app, a link to /Applications to drag it onto, and the notices. macOS only (ditto, codesign, hdiutil).
# The app is not notarized: that needs a paid Apple Developer account. A reader opens it the first time
# with Control-click > Open, or System Settings > Privacy & Security > Open Anyway.
#   bash build-dmg.sh <Observatory.zip> <version> <out dir> <notices dir>
set -euo pipefail
zip=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
version=$2
mkdir -p "$3"
out=$(cd "$3" && pwd)
notices=$(cd "$4" && pwd)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/image"
ditto -x -k "$zip" "$work/image"
app="$work/image/Observatory.app"
[ -d "$app" ] || { echo "no Observatory.app in $zip" >&2; exit 1; }
lipo -archs "$app/Contents/MacOS/Observatory"

# Apple Silicon runs only signed code. Godot's built-in signer signs ad hoc; Apple's codesign checks it,
# and signs again, ad hoc, only if it does not pass.
if codesign --verify --deep --strict "$app"; then
  echo "Godot's ad hoc signature verifies"
else
  echo "Godot's signature does not verify: signing again, ad hoc"
  codesign --force --deep --sign - "$app"
  codesign --verify --deep --strict "$app"
fi
codesign -dv "$app" 2>&1 | grep -E '^(Identifier|Format|Signature|CodeDirectory)' || true

for f in README.txt LICENSES.txt GODOT_COPYRIGHT.txt; do cp "$notices/$f" "$work/image/$f"; done
ln -s /Applications "$work/image/Applications"
dmg="$out/Observatory-$version-macos.dmg"
hdiutil create -quiet -volname "Observatory $version" -srcfolder "$work/image" -fs HFS+ -format UDZO -ov "$dmg"
hdiutil verify -quiet "$dmg"
ls -l "$dmg"
shasum -a 256 "$dmg"
