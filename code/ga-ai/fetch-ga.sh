#!/usr/bin/env bash
# GA's AI: fetch the Guitar Alchemist projects the course program references, pinned on one
# commit of GuitarAlchemist/ga (blobless clone, sparse checkout, research PDFs left out)
set -euo pipefail
GA_SHA=a826864f3a012cad88e415954bf57eca0ce12aa6
# Lesson 7 also compiles three files of GA pull request #749, at its merge commit
FIX_SHA=d7efd4142908542d469e0b1a9e6dd3dceba8ecc5
FIX_FILES="InvalidChordNames.cs ImprovisationSkill.cs ChordIntentMatching.cs"
# Lesson 8 reads GA's prompt corpus, outside the sparse checkout, at the pinned commit
CORPUS=Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml
cd "$(dirname "$0")"
if [ "$(git -C .ga rev-parse HEAD 2>/dev/null || true)" = "$GA_SHA" ]; then
  echo "ga   $GA_SHA already here"
else
  rm -rf .ga .ga-fix .ga-files
  git clone --quiet --filter=blob:none --no-checkout https://github.com/GuitarAlchemist/ga.git .ga
  git -C .ga config core.longpaths true
  # GA.Business.ML and its project references, the CLI that writes the OPTIC-K index,
  # and the chatbot host with its orchestration projects
  MSYS_NO_PATHCONV=1 git -C .ga sparse-checkout set --no-cone \
    /Directory.Build.props /Directory.Build.targets \
    /Common/GA.Core/ /Common/GA.Domain.Core/ /Common/GA.Domain.Repositories/ /Common/GA.Domain.Services/ \
    /Common/GA.Business.Config/ /Common/GA.Business.Core/ /Common/GA.Business.Assets/ /Common/GA.Business.DSL/ \
    /Common/GA.Business.ML/ '!/Common/GA.Business.ML/Documentation/Papers/' \
    /Common/GA.Providers.Anthropic/ /GA.Data.MongoDB/ /GuitarAlchemist.Registry/ \
    '/Demos/Music Theory/FretboardVoicingsCLI/' \
    /Common/GA.Application/ /Common/GA.Business.Core.Orchestration/ /Common/GA.Infrastructure/ /Apps/GaChatbot.Api/ \
    /skills/
  git -C .ga -c advice.detachedHead=false checkout --quiet "$GA_SHA"
  echo "ga   $GA_SHA"
fi
# The SKILL.md files the host loads, which a clone made before lesson 8 lacks
if [ ! -d .ga/skills ]; then
  MSYS_NO_PATHCONV=1 git -C .ga sparse-checkout add /skills/
fi
if [ "$(cat .ga-fix/SHA 2>/dev/null || true)" != "$FIX_SHA" ]; then
  # The blobless clone fetches the three files on demand; an older clone may lack the commit
  git -C .ga cat-file -e "$FIX_SHA^{commit}" 2>/dev/null || git -C .ga fetch --quiet --filter=blob:none origin "$FIX_SHA"
  rm -rf .ga-fix
  mkdir .ga-fix
  for f in $FIX_FILES; do
    git -C .ga show "$FIX_SHA:Common/GA.Business.ML/Agents/Skills/$f" > ".ga-fix/$f"
  done
  echo "$FIX_SHA" > .ga-fix/SHA
fi
echo "fix  $FIX_SHA"
if [ ! -s .ga-files/prompts.yaml ]; then
  mkdir -p .ga-files
  git -C .ga show "$GA_SHA:$CORPUS" > .ga-files/prompts.yaml.tmp
  mv .ga-files/prompts.yaml.tmp .ga-files/prompts.yaml
fi
echo "file $CORPUS"
