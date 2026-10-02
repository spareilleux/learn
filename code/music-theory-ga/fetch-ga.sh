#!/usr/bin/env bash
# Music theory for Guitar Alchemist: fetch the three GA projects the course program references,
# and the files of GA.Domain.Services and GaApi it compiles directly, pinned on one commit of
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
  # lesson 10: the ICV distance behind the chatbot's substitutions, and the service behind get_borrowed_chords
  /Common/GA.Domain.Services/GlobalUsings.cs
  /Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs
  /Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs
  /Common/GA.Domain.Services/Atonal/Grothendieck/IGrothendieckService.cs
  /Common/GA.Domain.Services/Chords/ChordTemplateFactory.cs
  /Apps/ga-server/GaApi/Services/ContextualChordService.cs
  /Apps/ga-server/GaApi/Models/ContextualChords.cs
  # lesson 11: the ranking of a modal family's members by brightness
  /Common/GA.Domain.Services/Unified/UnifiedModeService.cs
  # lesson 12: the atonal chord analysis and its test of a symmetrical set
  /Common/GA.Domain.Services/Chords/Analysis/Atonal/AtonalChordAnalysisService.cs
  # lesson 13: the chord-symbol parser of GA.Domain.Services, and the services that name extensions and alterations
  /Common/GA.Domain.Services/Chords/Parsing/ChordSymbolParser.cs
  /Common/GA.Domain.Services/Chords/BasicChordExtensionsService.cs
  /Common/GA.Domain.Services/Chords/ChordAlterationService.cs
)
cd "$(dirname "$0")"
if [ "$(git -C .ga rev-parse HEAD 2>/dev/null || true)" = "$GA_SHA" ]; then
  # a clone made before lessons 9 and 10 lacks their files: widening the sparse checkout fetches only those
  MSYS_NO_PATHCONV=1 git -C .ga sparse-checkout set --no-cone "${PATHS[@]}"
  echo "ga   $GA_SHA already here"
  exit 0
fi
rm -rf .ga
git clone --quiet --filter=blob:none --no-checkout https://github.com/GuitarAlchemist/ga.git .ga
MSYS_NO_PATHCONV=1 git -C .ga sparse-checkout set --no-cone "${PATHS[@]}"
git -C .ga -c advice.detachedHead=false checkout --quiet "$GA_SHA"
echo "ga   $GA_SHA"
