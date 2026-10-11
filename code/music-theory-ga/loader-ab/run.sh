#!/usr/bin/env bash
# Music theory for Guitar Alchemist, lesson 17: GA's NeoRiemannianConfig loader built twice from the pinned clone,
# as it is, and with the word `private` removed from its three YAML records (three lines), then run on the same file.
# Prints what each variant loads; check.sh compares it with expected.txt
set -euo pipefail
cd "$(dirname "$0")"
src=../.ga/Common/GA.Business.Config
for variant in private public; do
  rm -rf "build/$variant"
  mkdir -p "build/$variant"
  cp "$src/ConfigFileLocator.fs" "$src/NeoRiemannian.yaml" loader-ab.fsproj Program.fs "build/$variant/"
  if [ "$variant" = public ]; then
    sed -E 's/type private (TransformYaml|CycleYaml|NeoRiemannianYaml)/type \1/' "$src/NeoRiemannianConfig.fs" > "build/$variant/NeoRiemannianConfig.fs"
  else
    cp "$src/NeoRiemannianConfig.fs" "build/$variant/"
  fi
  echo "== $variant: $(grep -c -E 'type private (TransformYaml|CycleYaml|NeoRiemannianYaml)' "build/$variant/NeoRiemannianConfig.fs" || true) private records"
  dotnet build "build/$variant/loader-ab.fsproj" -c Release --nologo -v quiet > "build/$variant/build.log" 2>&1 || { cat "build/$variant/build.log"; exit 1; }
  dotnet run --project "build/$variant/loader-ab.fsproj" -c Release --no-build
done
