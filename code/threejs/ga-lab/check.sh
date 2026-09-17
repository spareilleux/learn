#!/usr/bin/env bash
# Guitar Alchemist 3D lab: type-check, unit tests, the data scripts, every experiment's "ci" runs (renderer.info counters
# and checks only, never times, compared with expected/), and a Vite build of the pages.
# UPDATE=1 bash ga-lab/check.sh writes expected/ instead of comparing (review the diff before committing).
# Uses the course's node_modules: run npm ci and npx playwright install chromium chromium-headless-shell in code/threejs.
set -uo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"
bin=../node_modules/.bin
echo "node $(node --version), tsc $($bin/tsc --version), three $(node -p "JSON.parse(require('node:fs').readFileSync('../node_modules/three/package.json')).version"), playwright $($bin/playwright --version)"
status=0
step() {
  echo "== $*"
  "$@" || { echo "FAIL $*"; status=1; }
}

step "$bin/tsc" --noEmit -p .
step "$bin/vitest" run --config vitest.config.ts
# Experiment 5 reads public/generated/optick.bin: a machine without GA's index gets the synthetic stand-in (the page's
# counters do not depend on the data), and a local run keeps the projection of the real index
[ -f public/generated/optick.bin ] || step node scripts/optick-project.ts --synthetic 20000
step node scripts/guitar-body.ts
# Every page runs on WebGL 2 in CI (--ci adds ?webgl), in whichever Chromium the runner has; experiment 11 runs in Node
step node scripts/run.mjs all --ci --timeout 300
step "$bin/vite" build --config vite.config.ts --logLevel warn
exit $status
