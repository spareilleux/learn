#!/usr/bin/env bash
# ComfyUI course, lesson 12: the worker in C# and Java, against fake ComfyUI servers, and optionally a real one on the CPU.
#   bash check.sh build         builds the fake server, the C# worker and its tests, and the Java worker
#   bash check.sh test          the C# tests (xUnit) and the Java tests (JUnit), against the fake server
#   bash check.sh transcripts   both workers from the command line against fake servers, compared with expected/
#   bash check.sh integration   both workers against a real ComfyUI on the CPU: needs COMFYUI_DIR and COMFYUI_PYTHON (../server.sh)
#   bash check.sh               build, test and transcripts: no GPU, no model, no ComfyUI
#   UPDATE=1 bash check.sh ...  writes the transcripts to expected/ instead of comparing (review the diff before committing)
# MVN overrides the Maven command, PYTHON the Python used for the results file.
set -uo pipefail
cd "$(dirname "$0")"
MVN=${MVN:-mvn}
PYTHON=${PYTHON:-$(command -v python3 || command -v python)}
what=${1:-all}
status=0
mkdir -p out expected
FAKE=csharp/FakeComfy/bin/Release/net10.0/fake-comfy.dll
WORKER_CS=csharp/ComfyWorker/bin/Release/net10.0/comfy-worker.dll
WORKER_JAVA=java/target/comfy-worker.jar

compare() {
  local name=$1 file=$2
  if [ "${UPDATE:-}" = 1 ]; then
    tr -d '\r' < "$file" > "expected/$name.txt"
    echo "upd  $name ($file)"
  elif diff --strip-trailing-cr "expected/$name.txt" "$file"; then
    echo "ok   $name ($file)"
  else
    echo "FAIL $name ($file)"
    status=1
  fi
}

build() {
  dotnet build csharp/ComfyWorker.Tests -c Release -m:1 --nologo -v quiet "-clp:ErrorsOnly;NoSummary" || exit 1
  $MVN -B -q -f java/pom.xml package -DskipTests || exit 1
}

test_all() {
  dotnet "csharp/ComfyWorker.Tests/bin/Release/net10.0/ComfyWorker.Tests.dll" -parallel none > out/test-csharp.txt 2>&1
  local cs=$?
  grep -E "^\s+ComfyWorker.Tests\s+Total:" out/test-csharp.txt
  if [ $cs -ne 0 ]; then cat out/test-csharp.txt; status=1; fi
  $MVN -B -f java/pom.xml test "-Dfake.comfy=$PWD/$FAKE" > out/test-java.txt 2>&1
  local java=$?
  grep -E "Tests run:.*Fail" out/test-java.txt | tail -1
  if [ $java -ne 0 ]; then cat out/test-java.txt; status=1; fi
}

# start_fake <file> [fake options...]: starts a fake server in the background, and sets url to its address.
# Not in a $(...) subshell: the fake belongs to this shell, which stops it.
fakes=()
start_fake() {
  local file=out/$1
  shift
  dotnet "$FAKE" --port 0 "$@" > "$file" 2>&1 &
  fakes+=($!)
  for _ in $(seq 1 100); do
    if grep -q "^listening on " "$file"; then
      url=$(sed -n 's/^listening on //p' "$file" | tr -d '\r')
      return
    fi
    sleep 0.1
  done
  cat "$file" >&2
  exit 1
}

stop_fakes() {
  [ ${#fakes[@]} -eq 0 ] && return
  for pid in "${fakes[@]}"; do kill "$pid" 2> /dev/null || true; done
  wait "${fakes[@]}" 2> /dev/null
  fakes=()
}

worker() {
  local language=$1
  shift
  if [ "$language" = cs ]; then dotnet "$WORKER_CS" "$@"; else java -jar "$WORKER_JAVA" "$@"; fi
}

transcripts() {
  trap stop_fakes EXIT
  rm -rf out/store-*
  local common=(--name worker-1 --no-jitter --base-delay-ms 100 --poll-ms 200)
  for language in cs java; do
    # A duplicate job, and a job with another color
    start_fake "fake-happy-$language.txt"
    worker $language run --gpu "gpu0=$url" --store "out/store-happy-$language" --jobs jobs/happy.jsonl "${common[@]}" > "out/12-happy-$language.txt" 2>&1
    compare 12-happy "out/12-happy-$language.txt"

    # One job per failure the fake can play, in this order, then a job that works
    start_fake "fake-failures-$language.txt" --step-ms 50 --script 500,ok,drop,invalid,oom,ok,error,hang,hang
    worker $language run --gpu "gpu0=$url" --store "out/store-failures-$language" --jobs jobs/failures.jsonl "${common[@]}" \
      --attempts 2 --timeout-s 1 > "out/12-failures-$language.txt" 2>&1
    compare 12-failures "out/12-failures-$language.txt"

    # What a readiness probe sees: one server up, one port where nothing listens
    worker $language health --gpu "gpu0=$url" --gpu "gpu1=http://127.0.0.1:9" > "out/12-health-$language.txt" 2>&1
    echo "exit code $?" >> "out/12-health-$language.txt"
    compare "12-health-$language" "out/12-health-$language.txt"

    # Two GPUs, the first with two prompts from someone else: which one runs what depends on timing,
    # so only the summary is compared.
    start_fake "fake-busy-$language.txt" --busy 2 --step-ms 100
    busy=$url
    start_fake "fake-idle-$language.txt" --step-ms 100
    idle=$url
    worker $language run --gpu "gpu0=$busy" --gpu "gpu1=$idle" --store "out/store-two-$language" --jobs jobs/two-gpus.jsonl "${common[@]}" \
      > "out/12-two-gpus-$language.full.txt" 2>&1
    sed 's/^/info /' "out/12-two-gpus-$language.full.txt"
    grep "^summary:" "out/12-two-gpus-$language.full.txt" > "out/12-two-gpus-$language.txt"
    compare 12-two-gpus "out/12-two-gpus-$language.txt"
    stop_fakes

    # The GA lab's chord-to-neck experiment as 20 jobs, one GPU that runs out of memory once, then the results file.
    # The fake answers with the file names of the workflow's SaveImage nodes: this checks the jobs file, not the images.
    start_fake "fake-ga-$language.txt" --step-ms 20 --script ok,ok,oom
    worker $language run --gpu "gpu0=$url" --store "out/store-ga-$language" --jobs jobs/ga-chord-neck.jsonl "${common[@]}" \
      --attempts 3 > "out/12-ga-$language.txt" 2>&1
    compare 12-ga "out/12-ga-$language.txt"
    "$PYTHON" jobs/results.py jobs/ga-chord-neck.jsonl "out/store-ga-$language" > "out/12-ga-results-$language.csv"
    compare 12-ga-results "out/12-ga-results-$language.csv"
    stop_fakes
  done
}

integration() {
  export COMFY_PORT=${COMFY_PORT:-8188} COMFY_BASE=$PWD/out/base-real
  bash ../server.sh start || exit 1
  if ! bash ../server.sh wait; then
    bash ../server.sh stop
    exit 1
  fi
  rm -rf out/store-real-*
  # The C# worker first, then the Java worker on the same server and the same job ids: it finds them in /history.
  for language in cs java; do
    worker $language run --gpu "gpu0=http://127.0.0.1:$COMFY_PORT" --store "out/store-real-$language" --jobs jobs/real.jsonl \
      --name worker-1 --no-jitter --base-delay-ms 100 --poll-ms 500 --attempts 2 --timeout-s 120 > "out/12-real-$language.full.txt" 2>&1
    # PNG bytes depend on the zlib build: their hashes are shown, not compared.
    sed -E 's/(\.png) [0-9a-f]{16}/\1 <sha256>/g' "out/12-real-$language.full.txt" > "out/12-real-$language.txt"
    compare "12-real-$language" "out/12-real-$language.txt"
  done
  bash ../server.sh stop
}

case $what in
  build) build ;;
  test) test_all ;;
  transcripts) transcripts ;;
  integration) integration ;;
  all) build; test_all; transcripts ;;
  *) echo "usage: check.sh [build|test|transcripts|integration|all]" >&2; exit 2 ;;
esac
exit $status
