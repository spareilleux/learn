#!/usr/bin/env bash
# VexTab & VexFlow, lesson 4: fetch the GA files the lesson runs and reads, pinned on one commit of
# GuitarAlchemist/ga (blobless clone, sparse checkout)
set -euo pipefail
GA_SHA=17ccee6885851e4b460ebd14d7f4cfb838f5541e
cd "$(dirname "$0")"
if [ "$(git -C .ga rev-parse HEAD 2>/dev/null || true)" = "$GA_SHA" ]; then
  echo "ga   $GA_SHA already here"
  exit 0
fi
rm -rf .ga
git clone --quiet --filter=blob:none --no-checkout https://github.com/GuitarAlchemist/ga.git .ga
MSYS_NO_PATHCONV=1 git -C .ga sparse-checkout set --no-cone \
  /Common/GA.Business.DSL/Types/VexTabTypes.fs \
  /Common/GA.Business.DSL/Parsers/VexTabParser.fs \
  /Common/GA.Business.DSL/Generators/VexTabGenerator.fs \
  /Common/GA.Business.DSL/Grammars/VexTab.ebnf \
  /Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs \
  /Common/GA.Business.ML/Agents/Skills/BeginnerChordsSkill.cs \
  /Apps/ga-client/tests/e2e/vextab-rendering.spec.ts \
  /Apps/ga-client/src/test/ChatMessage.test.tsx \
  /Apps/ga-client/src/test/performance.test.ts
git -C .ga -c advice.detachedHead=false checkout --quiet "$GA_SHA"
echo "ga   $GA_SHA"
