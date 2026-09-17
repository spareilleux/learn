#!/usr/bin/env bash
# ComfyUI course, lesson 15 (audio): everything that runs without a GPU and without a model.
#   bash check.sh unit      the workflows against node definitions saved from /object_info, the pipeline against a
#                           fake server (with ffmpeg: -16 LUFS and Opus), WER arithmetic, and key and tempo estimates
#                           on a synthetic signal whose answer is known
#   bash check.sh server    starts ComfyUI on the CPU (../server.sh, port COMFY_PORT or 8196), runs the pipeline on
#                           a workflow that needs no model, then stops the server
#   bash check.sh           both
#   UPDATE=1 bash check.sh  writes the outputs to expected/ instead of comparing
# Needs Python with numpy, scipy and librosa for the analysis test (requirements.txt), and ffmpeg (FFMPEG or PATH).
set -uo pipefail
cd "$(dirname "$0")"
what=${1:-all}
py=${PYTHON:-python}
status=0
mkdir -p out expected

compare() {
  local name=$1
  if [ "${UPDATE:-}" = 1 ]; then
    tr -d '\r' < "out/$name.txt" > "expected/$name.txt"
    echo "upd  $name"
  elif diff --strip-trailing-cr "expected/$name.txt" "out/$name.txt"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
}

unit() {
  "$py" validate.py data/object_info.audio.json workflows/*.api.json > out/15-validate.txt 2>&1
  echo "exit code $?" >> out/15-validate.txt
  compare 15-validate
  PYTHONDONTWRITEBYTECODE=1 "$py" -m unittest discover -s tests -v || status=1
}

server() {
  export COMFY_PORT=${COMFY_PORT:-8196} COMFY_BASE=${COMFY_BASE:-$PWD/out/base}
  bash ../server.sh start || { status=1; return; }
  if bash ../server.sh wait; then
    "$py" pipeline.py run "http://127.0.0.1:$COMFY_PORT" workflows/15-cpu-empty-audio.api.json --out out/cpu --bitrate "" \
      2>&1 | sed -E 's/after [0-9]+\.[0-9] s/after N s/; s/-> .*(cpu_[0-9]+\.flac)/-> out\/cpu\/\1/' > out/15-server.txt
    # The file itself: FLAC, 2 seconds of stereo silence at 44.1 kHz, read back with the standard library's wave
    # module after ffmpeg, when there is one, decodes it.
    if ff=${FFMPEG:-$(command -v ffmpeg)}; [ -n "$ff" ]; then
      "$ff" -hide_banner -loglevel error -y -i out/cpu/cpu_00001.flac out/cpu/cpu.wav &&
        "$py" -c "import wave; w = wave.open('out/cpu/cpu.wav'); print('wav', w.getnchannels(), 'channels', w.getframerate(), 'Hz', w.getnframes(), 'frames')" >> out/15-server.txt
    fi
    compare 15-server
  else
    status=1
  fi
  bash ../server.sh stop
}

case "$what" in
  unit) unit ;;
  server) server ;;
  all) unit; server ;;
  *) echo "usage: check.sh [unit|server|all]" >&2; exit 2 ;;
esac
exit $status
