# Helpers sourced by check.sh and the lesson scripts.
# step <name> <command…>: runs the command, keeps its raw output in out/<name>.raw.txt, writes the normalized output
# and the exit code to out/<name>.txt, then compares it with expected/<name>.txt (UPDATE=1 writes expected/ instead).

# Git Bash on Windows would turn /etc/… arguments into C:/Program Files/Git/etc/…
export MSYS_NO_PATHCONV=1

K8S_DIR=${K8S_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
mkdir -p "$K8S_DIR/out" "$K8S_DIR/expected"
status=${status:-0}

# Fields that change on every run become placeholders; runs of spaces become one, since column widths follow them.
# The kubelet appends the node's own search domains to a pod's resolv.conf (on a CI runner, an internal.cloudapp.net
# domain): they are dropped after cluster.local.
normalize() {
  sed -E \
    -e 's/\r$//' \
    -e 's/^(search [^ ]+\.svc\.cluster\.local svc\.cluster\.local cluster\.local) .*$/\1/' \
    -e 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z/<time>/g' \
    -e 's/\b(I|W|E)[0-9]{4} [0-9:.]+ +[0-9]+ /\1<time> /g' \
    -e 's/\b[0-9]{1,3}(\.[0-9]{1,3}){3}\b/<ip>/g' \
    -e 's/<ip>:[0-9]{4,5}\b/<ip>:<port>/g' \
    -e 's/-[b-df-hj-np-tv-z2-9]{8,10}-[b-df-hj-np-tv-z2-9]{5}\b/-<rs>-<pod>/g' \
    -e 's/\b(kindnet|kube-proxy|curl|dns)-[b-df-hj-np-tv-z2-9]{5}\b/\1-<pod>/g' \
    -e 's/(^| )[0-9]+(s|m|h|d)([0-9]+(s|m|h))?( |$)/\1<age>\5/g' \
    -e 's/(^| )[0-9]+(s|m|h|d)([0-9]+(s|m|h))?( |$)/\1<age>\5/g' \
    -e 's/\(<age> ago\)|\([0-9]+(s|m|h|d)([0-9]+(s|m))? ago\)/(<age> ago)/g' \
    -e 's/ +/ /g' \
    -e 's/ $//'
}

compare() {
  local name=$1
  if [ "${UPDATE:-}" = 1 ]; then
    cp "$K8S_DIR/out/$name.txt" "$K8S_DIR/expected/$name.txt"
    echo "upd  $name"
  elif diff "$K8S_DIR/expected/$name.txt" "$K8S_DIR/out/$name.txt"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
}

step() {
  local name=$1
  shift
  "$@" > "$K8S_DIR/out/$name.raw.txt" 2>&1
  local code=$?
  { normalize < "$K8S_DIR/out/$name.raw.txt"; echo "exit $code"; } > "$K8S_DIR/out/$name.txt"
  compare "$name"
}

# sh_step <name> <shell code>: the same, for a pipeline or several commands
sh_step() {
  local name=$1
  step "$name" bash -c "$2"
}

# wait_for <seconds> <shell condition>: polls every second until the condition holds, fails after the delay
wait_for() {
  local limit=$1 i=0
  until bash -c "$2" > /dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge "$limit" ]; then
      echo "timed out after ${limit}s: $2"
      return 1
    fi
    sleep 1
  done
}

# record <name> <shell code>: keeps the raw output in out/<name>.raw.txt for a lesson to quote, without comparing it
# (timings and counts that change from run to run)
record() {
  bash -c "$2" > "$K8S_DIR/out/$1.raw.txt" 2>&1
  echo "rec  $1"
}
