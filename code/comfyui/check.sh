#!/usr/bin/env bash
# ComfyUI course: everything that runs without a GPU and without a model, compared with expected/.
#   bash check.sh build     builds the C# tool and the Java client
#   bash check.sh offline   the workflow checks, the UI-to-API conversion and the diffs (lesson 3), model file
#                           headers read from two tiny files (lessons 7 and 8), and texture maps (lesson 13), no server
#   bash check.sh server    starts ComfyUI on the CPU (server.sh), runs the C# and Java clients on a workflow that
#                           needs no model (lesson 4), reads the PNGs they download, uploads images and runs the
#                           mask nodes (lesson 5), then stops the server
#   bash check.sh           all three
#   UPDATE=1 bash check.sh  writes the outputs to expected/ instead of comparing (review the diff before committing)
# The server mode needs COMFYUI_DIR (the folder with ComfyUI's main.py) and COMFYUI_PYTHON (a Python with its
# requirements), and port 8188 free: see server.sh. MVN overrides the Maven command, PYTHON the Python that
# writes the tiny model files.
set -uo pipefail
cd "$(dirname "$0")"
MVN=${MVN:-mvn}
what=${1:-all}
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

comfy() { dotnet out/csharp/comfy.dll "$@"; }

build() {
  dotnet build csharp -c Release -o out/csharp -m:1 --nologo -v quiet "-clp:ErrorsOnly;NoSummary" || exit 1
  $MVN -B -q -f java/pom.xml package || exit 1
}

offline() {
  {
    comfy validate workflows/01-txt2img.api.json
    comfy validate workflows/01-txt2img.api.json data/object_info.json
    comfy validate workflows/solid-color.api.json data/object_info.json
    comfy validate workflows/03-broken.api.json data/object_info.json
    comfy validate workflows/03-dynamic-combo.api.json data/object_info-dynamic.json
    comfy validate workflows/03-dynamic-broken.api.json data/object_info-dynamic.json
    echo "exit code $?"
  } > out/03-validate.txt 2>&1
  compare 03-validate

  # Every workflow the course ships, against node definitions captured from a
  # model-free ComfyUI on the CPU (data/object_info-course.json): class names,
  # input names including the dotted ones, links, output slots and values. No
  # server and no GPU here. The two files that are wrong on purpose are left out.
  {
    for wf in workflows/*.api.json; do
      # The 03-dynamic-* files belong to the hand-made fixture above, and two of
      # the three are wrong on purpose.
      case $wf in *03-broken.api.json | *03-dynamic-*.api.json) continue ;; esac
      printf '%s: ' "$(basename "$wf")"
      comfy validate "$wf" data/object_info-course.json | sed 's/;.*//'
    done
  } > out/03-workflows.txt 2>&1
  compare 03-workflows

  # Lesson 13: normal and roughness maps from a tileable pattern, with NumPy and Pillow (ComfyUI's requirements)
  py=${COMFYUI_PYTHON:-${PYTHON:-python}}

  # Lesson 9: which files LoadImage and LoadVideo can list depends on the machine's
  # MIME table, not on ComfyUI. Printed on each OS, not compared.
  PYTHONDONTWRITEBYTECODE=1 "$py" data/mime-info.py
  mkdir -p out/textures
  {
    PYTHONDONTWRITEBYTECODE=1 "$py" textures/test_maps.py 2>&1 | grep -v "^Ran "
    PYTHONDONTWRITEBYTECODE=1 "$py" textures/maps.py pattern out/textures/pattern.png 64
    PYTHONDONTWRITEBYTECODE=1 "$py" textures/maps.py normal out/textures/pattern.png out/textures/normal.png
    PYTHONDONTWRITEBYTECODE=1 "$py" textures/maps.py roughness out/textures/pattern.png out/textures/roughness.png
    for f in pattern normal roughness; do comfy png-info out/textures/$f.png | tail -1; done
    PYTHONDONTWRITEBYTECODE=1 "$py" textures/maps.py seam out/textures/normal.png
  } > out/13-maps.txt 2>&1
  compare 13-maps

  # The conversion must give, byte for byte, what the frontend's Export (API) gave.
  # Lessons 7 and 8: what a model file's header says, on two tiny files written by a script
  "${PYTHON:-python}" data/tiny-safetensors.py out/tiny > /dev/null
  {
    comfy safetensors-info out/tiny/tiny-lora.safetensors
    comfy safetensors-info out/tiny/tiny-quant.safetensors
  } > out/07-safetensors.txt 2>&1
  compare 07-safetensors

  comfy ui-to-api workflows/01-txt2img.ui.json data/object_info.json > out/converted.api.json
  if diff --strip-trailing-cr workflows/01-txt2img.exported.api.json out/converted.api.json > /dev/null; then
    echo "ok   03-ui-to-api (same bytes as the frontend's export)"
  else
    echo "FAIL 03-ui-to-api"
    status=1
  fi

  {
    comfy diff workflows/01-txt2img.api.json workflows/01-txt2img.exported.api.json
    comfy diff workflows/01-txt2img.api.json workflows/03-broken.api.json
  } > out/03-diff.txt 2>&1
  compare 03-diff
}

server() {
  bash server.sh start || exit 1
  if ! bash server.sh wait; then
    bash server.sh stop
    exit 1
  fi
  local url=http://127.0.0.1:${COMFY_PORT:-8188}

  # What this server's nodes look like, against the definitions saved for the offline checks
  comfy object-info "$url" CheckpointLoaderSimple EmptyLatentImage CLIPTextEncode KSampler VAEDecode SaveImage EmptyImage ImageInvert \
    > out/object_info.json 2> /dev/null
  if diff --strip-trailing-cr data/object_info.json out/object_info.json > /dev/null; then
    echo "ok   object_info (same node definitions as data/object_info.json)"
  else
    echo "FAIL object_info"
    diff --strip-trailing-cr data/object_info.json out/object_info.json | head -20
    status=1
  fi

  {
    echo "--- C#, first run"
    comfy run "$url" workflows/solid-color.api.json --out out/run-cs
    echo "--- C#, same workflow again"
    comfy run "$url" workflows/solid-color.api.json --out out/run-cs
    echo "--- C#, a broken workflow"
    comfy run "$url" workflows/03-broken.api.json
    echo "exit code $?"
  } > out/04-run-csharp.txt 2>&1
  compare 04-run-csharp

  {
    echo "--- Java, another color"
    java -jar java/target/comfy.jar run "$url" workflows/solid-color.api.json --set 1.color=65280 --out out/run-java
    echo "--- Java, a broken workflow"
    java -jar java/target/comfy.jar run "$url" workflows/03-broken.api.json
    echo "exit code $?"
  } > out/04-run-java.txt 2>&1
  compare 04-run-java

  # Lesson 4, around the happy path: a file that passes validation because it is in
  # the input list and fails when the server opens it, then two calls that answer 200
  # whether or not there was anything to act on. The server's own path is cut out of
  # the message: it differs on every machine.
  printf 'this is not a PNG file at all\n' > out/not-an-image.png
  {
    comfy run "$url" workflows/05-masks.api.json --image 1.image=out/not-an-image.png
    echo "exit code $?"
    echo "--- POST /interrupt with nothing running"
    curl -s -o /dev/null -w "%{http_code}\n" -X POST "$url/interrupt"
    echo "--- POST /queue, deleting a prompt id that is not in the queue"
    curl -s -o /dev/null -w "%{http_code}\n" -X POST -H 'Content-Type: application/json' \
      -d '{"delete":["00000000-0000-4000-8000-000000000000"]}' "$url/queue"
  } > out/04-errors.full.txt 2>&1
  sed "s|image file '.*[/\\\\]|image file '.../|" out/04-errors.full.txt > out/04-errors.txt
  compare 04-errors

  {
    comfy png-info out/run-cs/solid_00001_.png
    comfy compare out/run-cs/solid_00001_.png out/run-java/solid_00002_.png
    comfy compare out/run-java/solid_00002_.png out/run-java/inverted_00002_.png
  } > out/03-png.txt 2>&1
  compare 03-png

  # Lesson 5: images made by the tool, uploaded, and the mask nodes, which need no model
  {
    comfy make-image 64 48 out/pattern.png
    comfy cut out/pattern.png out/pattern-hole.png 32 24 12 8 4
    mkdir -p out/other && cp out/pattern.png out/other/pattern-hole.png
    echo "--- the mask workflow, with its input uploaded first"
    comfy run "$url" workflows/05-masks.api.json --image 1.image=out/pattern-hole.png --out out/run-05
    echo "--- the same file again, then other bytes under the same name, then with overwrite"
    comfy upload "$url" out/pattern-hole.png
    comfy upload "$url" out/other/pattern-hole.png
    comfy upload "$url" out/other/pattern-hole.png --overwrite
    comfy upload "$url" out/pattern.png --subfolder ../outside
    echo "exit code $?"
  } > out/05-masks.full.txt 2>&1
  # Canny's edges differ from one machine to the next (lesson 6): its hash is printed, not compared.
  grep "node 12:" out/05-masks.full.txt | sed 's/^/info /'
  "$COMFYUI_PYTHON" -c "from PIL import Image; im = Image.open('out/run-05/canny_00001_.png').convert('L'); print('info Canny edge pixels:', sum(1 for v in im.tobytes() if v > 127), 'of', im.width * im.height)"
  grep -v "node 12:" out/05-masks.full.txt > out/05-masks.txt
  compare 05-masks

  bash server.sh stop
}

case $what in
  build) build ;;
  offline) offline ;;
  server) server ;;
  all) build; offline; server ;;
  *) echo "usage: check.sh [build|offline|server|all]" >&2; exit 2 ;;
esac
exit $status
