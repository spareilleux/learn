#!/usr/bin/env bash
# Starts and stops one ComfyUI server on the CPU, with its own base directory,
# for check.sh. COMFYUI_DIR is the folder that contains main.py; COMFYUI_PYTHON
# is the Python that has its requirements installed.
set -euo pipefail
cd "$(dirname "$0")"
COMFYUI_DIR=${COMFYUI_DIR:-}
COMFYUI_PYTHON=${COMFYUI_PYTHON:-python}
PORT=${COMFY_PORT:-8188}
BASE=${COMFY_BASE:-$PWD/out/base}

case "${1:-}" in
  start)
    [ -n "$COMFYUI_DIR" ] || { echo "set COMFYUI_DIR to the folder that contains ComfyUI main.py" >&2; exit 2; }
    rm -rf "$BASE"
    # ComfyUI 0.36.0 stops at startup if custom_nodes is missing from the base directory.
    mkdir -p "$BASE/custom_nodes"
    # The server keeps the output nodes to run in a Python set, so their order changes from one start to the
    # next (lesson 4). A fixed hash seed makes it the same every time, and check.sh's outputs comparable.
    PYTHONHASHSEED=0 "$COMFYUI_PYTHON" -s "$COMFYUI_DIR/main.py" --cpu --port "$PORT" \
      --base-directory "$BASE" --database-url sqlite:///:memory: \
      --disable-auto-launch < /dev/null > "$BASE/server.log" 2>&1 &
    echo $! > "$BASE/server.pid"
    ;;
  wait)
    for _ in $(seq 1 120); do
      if curl -sf "http://127.0.0.1:$PORT/system_stats" > /dev/null; then exit 0; fi
      if ! kill -0 "$(cat "$BASE/server.pid")" 2> /dev/null; then break; fi
      sleep 1
    done
    cat "$BASE/server.log"
    exit 1
    ;;
  stop)
    if [ -f "$BASE/server.pid" ]; then
      kill "$(cat "$BASE/server.pid")" 2> /dev/null || true
      rm "$BASE/server.pid"
    fi
    ;;
  *)
    echo "usage: server.sh start|wait|stop" >&2
    exit 2
    ;;
esac
