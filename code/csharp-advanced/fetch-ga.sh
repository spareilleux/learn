#!/usr/bin/env bash
# Advanced C#: fetch the GA projects the course programs reference, from GuitarAlchemist/ga (blobless clones, sparse checkouts):
#   .ga       pinned for the lessons and appendix 1: GA.Core, GA.Domain.Core, GA.Business.Config
#   .ga-perf  pinned for appendix 2, the voicing-analysis path: GA.Domain.Services and what it references
set -euo pipefail
cd "$(dirname "$0")"

# fetch <folder> <sha> <sparse paths...>
fetch() {
  local dir=$1 sha=$2
  shift 2
  if [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)" = "$sha" ]; then
    echo "ga   $sha already in $dir"
    return
  fi
  rm -rf "$dir"
  git clone --quiet --filter=blob:none --no-checkout https://github.com/GuitarAlchemist/ga.git "$dir"
  MSYS_NO_PATHCONV=1 git -C "$dir" sparse-checkout set --no-cone "$@"
  git -C "$dir" -c advice.detachedHead=false checkout --quiet "$sha"
  echo "ga   $sha in $dir"
}

fetch .ga a826864f3a012cad88e415954bf57eca0ce12aa6   /Directory.Build.props /Common/GA.Core/ /Common/GA.Business.Config/ /Common/GA.Domain.Core/

fetch .ga-perf 66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e   /Directory.Build.props /Directory.Build.targets /Common/GA.Core/ /Common/GA.Business.Config/ /Common/GA.Domain.Core/   /Common/GA.Domain.Services/ /Common/GA.Domain.Repositories/ /Common/GA.Business.Core/
