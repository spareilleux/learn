#!/usr/bin/env bash
# Sparse, blobless checkout of GuitarAlchemist/ga at the pinned commit, with only what GA.Domain.Core and its test
# project need to build, into .ga/ (or $GA_DIR). Nothing in GA is modified.
set -euo pipefail
export MSYS_NO_PATHCONV=1  # Git Bash on Windows would rewrite the leading slashes of the sparse patterns
GA_SHA=aa22f9101d5bb86800ff2819381f97986fc81fb1
GA_DIR=${GA_DIR:-"$(dirname "$0")/.ga"}
if [ -d "$GA_DIR/.git" ] && [ "$(git -C "$GA_DIR" rev-parse HEAD)" = "$GA_SHA" ]; then
  echo "ga   $GA_SHA already here"; exit 0
fi
git -c core.longpaths=true clone -q --filter=blob:none --no-checkout https://github.com/GuitarAlchemist/ga.git "$GA_DIR"
git -C "$GA_DIR" config core.longpaths true
git -C "$GA_DIR" sparse-checkout set --no-cone /global.json /Directory.Build.props /Directory.Build.targets \
  /Common/GA.Core/ /Common/GA.Business.Config/ /Common/GA.Domain.Core/ /Tests/GA.Domain.Core.Tests/
git -C "$GA_DIR" checkout -q "$GA_SHA"
echo "ga   $(git -C "$GA_DIR" rev-parse HEAD)"
