#!/usr/bin/env bash
# ComfyUI course: everything that runs without a GPU and without a model, compared with expected/.
#   bash check.sh build     builds the C# tool and the Java client
#   bash check.sh offline   the workflow checks, the UI-to-API conversion and the diffs (lesson 3), no server
#   bash check.sh server    starts ComfyUI on the CPU (server.sh), runs the C# and Java clients on a workflow that
#                           needs no model (lesson 4), reads the PNGs they download, then stops the server
#   bash check.sh           all three
#   UPDATE=1 bash check.sh  writes the outputs to expected/ instead of comparing (review the diff before committing)
# The server mode needs COMFYUI_DIR (the folder with ComfyUI's main.py) and COMFYUI_PYTHON (a Python with its
# requirements), and port 8188 free: see server.sh. MVN overrides the Maven command.
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
    echo "exit code $?"
  } > out/03-validate.txt 2>&1
  compare 03-validate

  # The conversion must give, byte for byte, what the frontend's Export (API) gave.
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

  {
    comfy png-info out/run-cs/solid_00001_.png
    comfy compare out/run-cs/solid_00001_.png out/run-java/solid_00002_.png
    comfy compare out/run-java/solid_00002_.png out/run-java/inverted_00002_.png
  } > out/03-png.txt 2>&1
  compare 03-png

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
