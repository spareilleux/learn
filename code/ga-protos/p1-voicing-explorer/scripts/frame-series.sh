#!/usr/bin/env bash
# The frame-time series of results/frame-times.jsonl, one probe per line: 120 frames at 1280 x 720 in headless Chromium.
# Needs public/data (the published sample) and public/data-full (the whole guitar index, built with --sample 297910 --k 0 --with-vectors).
set -u
out=${1:-results/local/frame-times.jsonl}
mkdir -p "$(dirname "$out")"
run() { echo "== $*" >&2; node scripts/probe.mjs "$@" | grep '^{' >> "$out"; }
run                                   # 30,000 sprites, WebGPU
run --webgl                           # 30,000 sprites, WebGL 2
run --mode points                     # 30,000 1-pixel points, WebGPU
run --mode points --webgl
run --data data-full                  # 297,910 sprites, WebGPU, neighbours searched in the browser
run --data data-full --webgl
run --data data-full --mode points
run --synthetic 1000000               # a million random sprites
run --synthetic 1000000 --webgl
run --synthetic 3000000
