#!/usr/bin/env bash
# Guitar Alchemist lab: the checks that need no GPU.
#   bash check.sh unit     the runner against a fake server, the measures, the dot detector on synthetic necks, the
#                          experiment files, and (with COMFYUI_DIR set) every workflow's nodes and inputs read from
#                          ComfyUI's source
#   bash check.sh server   CI only: starts ComfyUI on the CPU with the GA node pack, checks every workflow against
#                          its /object_info, runs the runner twice on a no-model fixture (the second run must submit
#                          nothing), then stops the server. Needs COMFYUI_DIR and COMFYUI_PYTHON, and port 8190 free.
#   bash check.sh          unit only
# The lab's runner itself never starts a server: this script does, for CI, on a machine without a GPU.
set -uo pipefail
cd "$(dirname "$0")"
PY=${PYTHON:-python}
what=${1:-unit}
status=0

unit() {
  "$PY" -m unittest discover -s tests -t . || status=1
}

server() {
  local port=${GALAB_PORT:-8190} base=$PWD/out/ci-base url
  url=http://127.0.0.1:$port
  rm -rf "$base" out/ci-run
  rm -rf out/ci-mesh out/ci-meshes
  mkdir -p "$base/custom_nodes" "$base/input/3d" out/ci-models
  cp -r ../custom-nodes/ga "$base/custom_nodes/ga"
  cp tests/fixtures/cube.glb "$base/input/3d/galab-cube.glb"
  PYTHONHASHSEED=0 "$COMFYUI_PYTHON" -s "$COMFYUI_DIR/main.py" --cpu --port "$port" --base-directory "$base" \
    --database-url sqlite:///:memory: --disable-auto-launch < /dev/null > "$base/server.log" 2>&1 &
  local pid=$!
  for _ in $(seq 1 180); do
    curl -sf "$url/system_stats" > /dev/null && break
    kill -0 "$pid" 2> /dev/null || break
    sleep 1
  done
  if ! curl -sf "$url/system_stats" > /dev/null; then
    cat "$base/server.log"
    kill "$pid" 2> /dev/null
    exit 1
  fi
  "$COMFYUI_PYTHON" -m runner.validate --server "$url" workflows/*.api.json tests/ci/mesh-cpu.api.json || status=1
  local run=("$COMFYUI_PYTHON" -m runner run tests/ci/ga-nodes-cpu.yaml --server "$url" --models-dir out/ci-models
             --out out/ci-run --margin-gb 1 --min-free-vram-gb 0)
  "${run[@]}" || status=1
  "${run[@]}" > out/ci-second.txt 2>&1 || status=1
  cat out/ci-second.txt
  "$COMFYUI_PYTHON" - <<'EOF' || status=1
import json
r = json.load(open("out/ci-run/results.json"))
states = [i["status"] for i in r["items"]]
outputs = [len(i["outputs"]) for i in r["items"]]
print("states", states, "outputs per item", outputs, "version", r["server"]["comfyui_version"])
assert states == ["done"] * 4 and outputs == [2] * 4, "every item done with 2 outputs"
assert all(i["texts"] for i in r["items"]), "PreviewAny texts recorded"
assert "4 item(s) already done" in open("out/ci-second.txt").read(), "the second run skipped every item"
EOF
  # Core mesh nodes and SaveGLB on the fixture box: the runner downloads, hashes and measures each .glb.
  local mesh=("$COMFYUI_PYTHON" -m runner run tests/ci/mesh-cpu.yaml --server "$url" --models-dir out/ci-models
              --out out/ci-mesh --meshes out/ci-meshes --margin-gb 1 --min-free-vram-gb 0)
  "${mesh[@]}" || status=1
  "${mesh[@]}" > out/ci-mesh-second.txt 2>&1 || status=1
  cat out/ci-mesh-second.txt
  "$COMFYUI_PYTHON" - <<'EOF' || status=1
import json
r = json.load(open("out/ci-mesh/results.json"))
print(json.dumps([{"status": i["status"], "error": i.get("error"),
                   "glb": [{k: o.get("glb", {}).get(k) for k in ("triangles", "vertices", "bbox", "topology")}
                           for o in i.get("outputs") or []]} for i in r["items"]], indent=1))
assert [i["status"] for i in r["items"]] == ["done"] * 2, "both mesh items done"
for item in r["items"]:
    by_node = {o["node"]: o["glb"] for o in item["outputs"]}
    assert set(by_node) == {"5", "6"}, by_node.keys()
    raw = by_node["6"]
    assert raw["triangles"] == 12 and raw["topology"]["watertight"], raw
    assert raw["bbox"]["extents"] == [2.0, 1.0, 0.5], raw["bbox"]
    assert by_node["5"]["triangles"] <= 12, by_node["5"]
assert "2 item(s) already done" in open("out/ci-mesh-second.txt").read(), "the second mesh run skipped every item"
EOF
  kill "$pid" 2> /dev/null
  wait "$pid" 2> /dev/null
}

case $what in
  unit) unit ;;
  server) server ;;
  *) echo "usage: check.sh [unit|server]" >&2; exit 2 ;;
esac
exit $status
