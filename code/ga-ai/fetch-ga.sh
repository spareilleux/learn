#!/usr/bin/env bash
# GA's AI: fetch the Guitar Alchemist projects the course program references, pinned on one
# commit of GuitarAlchemist/ga (blobless clone, sparse checkout, research PDFs left out)
set -euo pipefail
GA_SHA=a826864f3a012cad88e415954bf57eca0ce12aa6
# Lesson 7 also compiles three files of GA pull request #749, at its merge commit
FIX_SHA=d7efd4142908542d469e0b1a9e6dd3dceba8ecc5
FIX_FILES="InvalidChordNames.cs ImprovisationSkill.cs ChordIntentMatching.cs"
# Lesson 11 also compiles GA's key identification service as it is on main, after #625 and
# 6baf32e, against the pinned domain
KEYS_SHA=6baf32ed9b35c9b8a1645cb8d6836aafd0713a40
KEYS_FILE=Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs
# Lesson 13 also compiles GA's DSL closures at the same commit, where domain.analyzeProgression
# takes its key from that service; the file is unchanged on main since
DSL_FILE=Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs
# Lesson 8 reads GA's prompt corpus, outside the sparse checkout, at the pinned commit
CORPUS=Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml
cd "$(dirname "$0")"
if [ "$(git -C .ga rev-parse HEAD 2>/dev/null || true)" = "$GA_SHA" ]; then
  echo "ga   $GA_SHA already here"
else
  rm -rf .ga .ga-fix .ga-keys .ga-dsl .ga-files
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
if [ "$(cat .ga-keys/SHA 2>/dev/null || true)" != "$KEYS_SHA" ]; then
  git -C .ga cat-file -e "$KEYS_SHA^{commit}" 2>/dev/null || git -C .ga fetch --quiet --filter=blob:none origin "$KEYS_SHA"
  rm -rf .ga-keys
  mkdir .ga-keys
  git -C .ga show "$KEYS_SHA:$KEYS_FILE" > .ga-keys/KeyIdentificationService.cs
  echo "$KEYS_SHA" > .ga-keys/SHA
fi
echo "keys $KEYS_SHA"
if [ "$(cat .ga-dsl/SHA 2>/dev/null || true)" != "$KEYS_SHA" ]; then
  git -C .ga cat-file -e "$KEYS_SHA^{commit}" 2>/dev/null || git -C .ga fetch --quiet --filter=blob:none origin "$KEYS_SHA"
  rm -rf .ga-dsl
  mkdir .ga-dsl
  git -C .ga show "$KEYS_SHA:$DSL_FILE" > .ga-dsl/DomainClosures.fs
  echo "$KEYS_SHA" > .ga-dsl/SHA
fi
echo "dsl  $KEYS_SHA"
if [ ! -s .ga-files/prompts.yaml ]; then
  mkdir -p .ga-files
  git -C .ga show "$GA_SHA:$CORPUS" > .ga-files/prompts.yaml.tmp
  mv .ga-files/prompts.yaml.tmp .ga-files/prompts.yaml
fi
echo "file $CORPUS"
