#!/usr/bin/env bash
# ComfyUI course, lesson 12: starts ComfyUI on the CPU on its own port and base directory, runs record.py against
# it, and stops it. COMFYUI_DIR is the folder with main.py, COMFYUI_PYTHON a Python with its requirements.
#   bash record.sh <out dir>
set -euo pipefail
cd "$(dirname "$0")"
: "${COMFYUI_DIR:?set COMFYUI_DIR to the folder that contains ComfyUI main.py}"
COMFYUI_PYTHON=${COMFYUI_PYTHON:-python}
PORT=${COMFY_PORT:-8199}
OUT=${1:-../data/recorded}
BASE=$(mktemp -d)
mkdir -p "$BASE/custom_nodes"
PYTHONHASHSEED=0 "$COMFYUI_PYTHON" -s "$COMFYUI_DIR/main.py" --cpu --port "$PORT" --base-directory "$BASE" \
  --database-url sqlite:///:memory: --disable-auto-launch < /dev/null > "$BASE/server.log" 2>&1 &
pid=$!
trap 'kill $pid 2> /dev/null || true' EXIT
for _ in $(seq 1 180); do
  if curl -sf "http://127.0.0.1:$PORT/system_stats" > /dev/null; then break; fi
  kill -0 $pid 2> /dev/null || { cat "$BASE/server.log"; exit 1; }
  sleep 1
done
"$COMFYUI_PYTHON" -s record.py "http://127.0.0.1:$PORT" "$OUT" "$COMFYUI_DIR" "$BASE"
grep -E "Prompt executed|invalid prompt|Interrupting|Exception|Error" "$BASE/server.log" || true
