#!/usr/bin/env bash
# Music theory for Guitar Alchemist: fetch the three GA projects the course program references,
# and the four files of GA.Domain.Services it compiles directly, pinned on one commit of
# GuitarAlchemist/ga (blobless clone, sparse checkout)
set -euo pipefail
GA_SHA=a826864f3a012cad88e415954bf57eca0ce12aa6
PATHS=(
  /Directory.Build.props /Common/GA.Core/ /Common/GA.Business.Config/ /Common/GA.Domain.Core/
  # lesson 9: the GA.Domain.Services project pulls in ILGPU, ONNX Runtime and ASP.NET Core, so only these files
  /Common/GA.Domain.Services/Atonal/VoiceLeadingSpace.cs
  /Common/GA.Domain.Services/Atonal/SetClassOpticIndex.cs
  /Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingAnalyzer.cs
  /Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingReport.cs
)
cd "$(dirname "$0")"
if [ "$(git -C .ga rev-parse HEAD 2>/dev/null || true)" = "$GA_SHA" ]; then
  # a clone made before lesson 9 lacks its files: widening the sparse checkout fetches only those
  MSYS_NO_PATHCONV=1 git -C .ga sparse-checkout set --no-cone "${PATHS[@]}"
  echo "ga   $GA_SHA already here"
  exit 0
fi
rm -rf .ga
git clone --quiet --filter=blob:none --no-checkout https://github.com/GuitarAlchemist/ga.git .ga
MSYS_NO_PATHCONV=1 git -C .ga sparse-checkout set --no-cone "${PATHS[@]}"
git -C .ga -c advice.detachedHead=false checkout --quiet "$GA_SHA"
echo "ga   $GA_SHA"
