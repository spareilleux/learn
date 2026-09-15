#!/usr/bin/env bash
# GA's AI: fetch the Guitar Alchemist projects the course program references, pinned on one
# commit of GuitarAlchemist/ga (blobless clone, sparse checkout, research PDFs left out)
set -euo pipefail
GA_SHA=a826864f3a012cad88e415954bf57eca0ce12aa6
cd "$(dirname "$0")"
if [ "$(git -C .ga rev-parse HEAD 2>/dev/null || true)" = "$GA_SHA" ]; then
  echo "ga   $GA_SHA already here"
  exit 0
fi
rm -rf .ga
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
  /Common/GA.Application/ /Common/GA.Business.Core.Orchestration/ /Common/GA.Infrastructure/ /Apps/GaChatbot.Api/
git -C .ga -c advice.detachedHead=false checkout --quiet "$GA_SHA"
echo "ga   $GA_SHA"
