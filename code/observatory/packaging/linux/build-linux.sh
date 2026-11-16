#!/usr/bin/env bash
# The Observatory's Linux export as a .deb (Debian, Ubuntu) and an .rpm (Fedora, openSUSE), from one tree:
#   /opt/observatory/          the program, its .pck and the notices
#   /usr/bin/observatory       a two-line launcher
#   /usr/share/applications/   the menu entry; /usr/share/icons/hicolor/ its icon at 128, 256, 512 px
#   /usr/share/doc/observatory/copyright   the notices (LICENSES.txt)
# Needs dpkg-deb and rpmbuild (Ubuntu: apt-get install rpm).
#   bash build-linux.sh <export dir> <version> <out dir>
set -euo pipefail
src=$(cd "$1" && pwd)
version=$2
mkdir -p "$3"
out=$(cd "$3" && pwd)
here=$(cd "$(dirname "$0")" && pwd)
app=io.github.spareilleux.observatory
files="observatory.x86_64 observatory.pck README.txt LICENSES.txt GODOT_COPYRIGHT.txt"
for f in $files; do [ -f "$src/$f" ] || { echo "$src has no $f" >&2; exit 1; }; done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
root=$work/root
install -Dm755 "$src/observatory.x86_64" "$root/opt/observatory/observatory.x86_64"
for f in observatory.pck README.txt LICENSES.txt GODOT_COPYRIGHT.txt; do
  install -Dm644 "$src/$f" "$root/opt/observatory/$f"
done
mkdir -p "$root/usr/bin"
printf '#!/bin/sh\nexec /opt/observatory/observatory.x86_64 "$@"\n' > "$root/usr/bin/observatory"
chmod 755 "$root/usr/bin/observatory"
install -Dm644 "$here/$app.desktop" "$root/usr/share/applications/$app.desktop"
for n in 128 256 512; do
  install -Dm644 "$here/../icons/observatory-$n.png" "$root/usr/share/icons/hicolor/${n}x$n/apps/$app.png"
done
install -Dm644 "$src/LICENSES.txt" "$root/usr/share/doc/observatory/copyright"

summary='The Observatory, native'
description='A library and its gardens at night, under the stars: the scene of
spareilleux.github.io/learn/observatory, on the Godot Engine. It renders with
Vulkan, and falls back to OpenGL where Vulkan is missing.'

# .deb. The binary asks for glibc 2.28 at most (its GLIBC_ symbol versions); every graphics, sound and
# windowing library is loaded at run time, so they are recommended, not required.
mkdir -p "$work/deb"
cp -a "$root/." "$work/deb/"
mkdir "$work/deb/DEBIAN"
{
  echo "Package: observatory"
  echo "Version: $version"
  echo "Section: games"
  echo "Priority: optional"
  echo "Architecture: amd64"
  echo "Maintainer: Stephane Pareilleux <spareilleux@users.noreply.github.com>"
  echo "Installed-Size: $(du -sk "$root" | cut -f1)"
  echo "Depends: libc6 (>= 2.28)"
  echo "Recommends: libvulkan1, libgl1, libx11-6, libxcursor1, libxi6, libxinerama1, libxrandr2, libfontconfig1, libpulse0 | libasound2t64 | libasound2"
  echo "Homepage: https://spareilleux.github.io/learn/observatory/"
  echo "Description: $summary"
  echo "$description" | sed 's/^/ /'
} > "$work/deb/DEBIAN/control"
dpkg-deb --root-owner-group -Zxz --build "$work/deb" "$out/observatory_${version}_amd64.deb"

# .rpm, from the same tree. The binary is Godot's release template as published: no strip, no debug
# package, no automatic dependency scan.
mkdir -p "$work/rpm/SPECS"
cat > "$work/rpm/SPECS/observatory.spec" <<EOF
Name: observatory
Version: $version
Release: 1
Summary: $summary
License: MIT (Godot Engine); the scene's notices: /opt/observatory/LICENSES.txt
URL: https://spareilleux.github.io/learn/observatory/
BuildArch: x86_64
AutoReqProv: no
Requires: glibc >= 2.28
Recommends: vulkan-loader, mesa-libGL, libX11, libXcursor, libXi, libXinerama, libXrandr, fontconfig
%global debug_package %{nil}
%global __os_install_post %{nil}

%description
$description

%install
cp -a "$root/." "%{buildroot}/"

%files
%defattr(-,root,root,-)
/opt/observatory
/usr/bin/observatory
/usr/share/applications/$app.desktop
/usr/share/icons/hicolor/128x128/apps/$app.png
/usr/share/icons/hicolor/256x256/apps/$app.png
/usr/share/icons/hicolor/512x512/apps/$app.png
/usr/share/doc/observatory
EOF
rpmbuild --quiet --define "_topdir $work/rpm" -bb "$work/rpm/SPECS/observatory.spec"
cp "$work"/rpm/RPMS/x86_64/observatory-*.rpm "$out/"

ls -l "$out"
( cd "$out" && sha256sum observatory_"$version"_amd64.deb observatory-"$version"-1.x86_64.rpm )
