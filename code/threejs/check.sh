#!/usr/bin/env bash
# three.js course: check the scenes and scripts with tsc, run the Node.js scripts, generate the HDR environment and the
# glTF models, open every lesson page in headless Chromium through scripts/probe.mjs, build the pages with Vite, and
# compare every output with expected/ (colors read from screenshots may differ by 2 per channel, see scripts/compare.mjs).
# The backend that WebGPURenderer picks depends on the machine: it is printed, and removed from the compared outputs.
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
# Run npm ci and npx playwright install chromium in this folder first.
set -uo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"
bin=node_modules/.bin
echo "node $(node --version), tsc $($bin/tsc --version), vite $(node -p "require('vite/package.json').version"), three $(node -p "JSON.parse(require('node:fs').readFileSync('node_modules/three/package.json')).version"), playwright $($bin/playwright --version)"
status=0
mkdir -p out/shots expected

compare() {
  local name=$1
  if [ "${UPDATE:-}" = 1 ]; then
    cp "out/$name.txt" "expected/$name.txt"
    echo "upd  $name"
  elif node scripts/compare.mjs "expected/$name.txt" "out/$name.txt"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
}

# run <name> <command…>: runs the command, normalizes its output and adds the exit code
run() {
  local name=$1
  shift
  "$@" > "out/$name.raw.txt" 2>&1
  local code=$?
  { node normalize.mjs < "out/$name.raw.txt"; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
}

# probe <name> <page> [options…]: like run, but prints the backend and the fallback warning, then removes them with the
# coordinate system, which follows the backend, and with the CPU times (fields ending in Ms)
probe() {
  local name=$1
  shift
  node scripts/probe.mjs "$@" --shot "out/shots/$name.png" > "out/$name.raw.txt" 2>&1
  local code=$?
  echo "     $name: $(grep -o '"backend": "[^"]*"' "out/$name.raw.txt") $(grep -o '"gpu": "[^"]*"' "out/$name.raw.txt")$(grep -c 'WebGPU is not available' "out/$name.raw.txt" | sed 's/^0$//; s/^[1-9].*/, after a fallback warning/')"
  { grep -v '"backend":\|"gpu":\|"coordinateSystem":\|No available adapters\|WebGPU is not available\|"[A-Za-z]*Ms":' "out/$name.raw.txt" | node normalize.mjs; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
}

# Types: the scenes, the scripts, and one snippet that tsc rejects
run l00_tsc "$bin/tsc" --noEmit -p . --pretty false
printf '{ "extends": "../errors/tsconfig.json", "files": ["../errors/l01_tojson_types.ts"] }' > out/tsconfig.l01.json
run l01_tojson_types "$bin/tsc" --noEmit -p out/tsconfig.l01.json --pretty false

# Lesson 1
run l01_scene_graph node scripts/l01-scene-graph.ts
probe l01_probe 01-scene
probe l01_probe_webgl 01-scene --webgl
probe l01_probe_webglrenderer 01-scene-webgl
probe l01_probe_linear_output 01-scene --query linear
probe l01_probe_three_cubes 01-scene --query cubes=3
run l01_exercises node scripts/l01-exercises.ts
PROBE_CHANNEL=chromium-headless-shell probe l01_probe_headless_shell 01-scene

# Lesson 2
run l02_geometries node scripts/l02-geometries.ts
probe l02_probe 02-materials-lights
probe l02_probe_noshadows 02-materials-lights --query noshadows
probe l02_probe_neck_no_shadow 02-materials-lights --query neckshadow=off
run l02_exercises node scripts/l02-exercises.ts

# Lesson 3
run l03_make_hdr node scripts/make-studio-hdr.ts
run l03_color node scripts/l03-color.ts
for tone in none aces agx neutral; do
  probe "l03_probe_$tone" 03-color --query "tone=$tone"
done
probe l03_probe_webgl_aces 03-color --webgl --query tone=aces
probe l03_probe_environment 03-environment
run l03_exercises node scripts/l03-exercises.ts
for exposure in 2 4; do
  probe "l03_probe_agx_exposure_$exposure" 03-color --query "tone=agx&exposure=$exposure"
done

# Lesson 4
run l04_make_models node scripts/make-models.ts
run l04_gltf node scripts/l04-gltf.ts
probe l04_probe 04-gltf
run l04_exercises node scripts/l04-exercises.ts

# Lesson 5
run l05_raycaster node scripts/l05-raycaster.ts
probe l05_probe 05-picking
probe l05_probe_sidebar 05-picking --query sidebar
run l05_exercises node scripts/l05-exercises.ts

# Lesson 6: the generated shaders go to their own files (out/l06_shader_*.txt), and the line that moves the string is
# compared: the rest of the code follows three.js's node builders, not the lesson
probe l06_probe 06-tsl --extract shader out/l06_shader_webgpu.txt
probe l06_probe_webgl 06-tsl --webgl --extract shader out/l06_shader_webgl.txt
probe l06_probe_harmonic_2 06-tsl --query harmonic=2 --extract shader out/l06_shader_harmonic_2.txt
run l06_shader_lines grep -h 'positionLocal = ' out/l06_shader_webgpu.txt out/l06_shader_webgl.txt

# Lesson 7
for pipeline in none bloom bloom-fxaa direct; do
  probe "l07_probe_$pipeline" 07-post --query "pipeline=$pipeline"
done
probe l07_probe_threshold_0 07-post --query threshold=0
probe l07_probe_dispose_pipeline 07-post --query dispose=pipeline
probe l07_probe_dispose_all 07-post --query dispose=all

# Lesson 8: the counts are compared, the CPU times only printed
for mode in meshes unshared instanced batched lod; do
  probe "l08_probe_$mode" 08-performance --query "mode=$mode"
  echo "     $(grep -o '"[a-zA-Z]*Ms": [0-9.]*' "out/l08_probe_$mode.raw.txt" | tr '\n' ' ')"
done
for mode in meshes instanced tiles batched lod; do
  probe "l08_probe_${mode}_close" 08-performance --query "mode=$mode&view=close"
done
probe l08_probe_batched_webgl 08-performance --webgl --query mode=batched

# The production build: one HTML page per lesson, three.js's build files in shared chunks (lessons 1 and 4). The pages of
# lessons 1 to 4 alone, as lessons 1 and 4 show it, then every page: later lessons change how the shared chunks are split
rm -rf dist
# Vite prints its warning on stderr: stdout first, then stderr, so that the order doesn't depend on the OS
run l04_build bash -c "PAGES='^0[1-4]-' $bin/vite build 2> out/l04_build.stderr.txt; code=\$?; cat out/l04_build.stderr.txt; exit \$code"
run l04_dist_files node scripts/files.mjs dist
rm -rf dist
run l08_build bash -c "$bin/vite build 2> out/l08_build.stderr.txt; code=\$?; cat out/l08_build.stderr.txt; exit \$code"
run l08_dist_files node scripts/files.mjs dist

exit $status
