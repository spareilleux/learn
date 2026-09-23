#!/usr/bin/env bash
# SlashForge course: run the pinned slashforge installer into a throwaway home directory and a throwaway repository,
# and compare everything it prints and writes with expected/. The real ~/.claude is never touched.
# UPDATE=1 bash check.sh writes the outputs to expected/ instead of comparing (review the diff before committing).
set -uo pipefail
cd "$(dirname "$0")"
node --version
node -p "'slashforge ' + require('slashforge/package.json').version"
status=0
rm -rf out
mkdir -p out expected

compare() {
  local name=$1
  if [ "${UPDATE:-}" = 1 ]; then
    cp "out/$name.txt" "expected/$name.txt"
    echo "upd  $name"
  elif diff --strip-trailing-cr "expected/$name.txt" "out/$name.txt"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
}

HOME_DIR="$PWD/out/home"
REPO_DIR="$PWD/out/repo"
BROKEN_HOME="$PWD/out/home-broken"
mkdir -p "$HOME_DIR" "$REPO_DIR" "$BROKEN_HOME"

# Node takes the home directory from USERPROFILE on Windows and from HOME elsewhere: point both at the sandbox.
# On Windows the installer prints C:\...\out\home; cygpath gives the same path with forward slashes, which is
# what normalize() matches after turning every backslash into a slash.
if command -v cygpath > /dev/null; then
  export USERPROFILE; USERPROFILE=$(cygpath -w "$HOME_DIR")
  HOME_M=$(cygpath -m "$HOME_DIR"); REPO_M=$(cygpath -m "$REPO_DIR"); BROKEN_M=$(cygpath -m "$BROKEN_HOME")
else
  HOME_M=$HOME_DIR; REPO_M=$REPO_DIR; BROKEN_M=$BROKEN_HOME
fi
export HOME="$HOME_DIR"
# The installer asks npm for a newer release after install and status; the course pins 4.4.3 on purpose.
export SLASHFORGE_NO_UPDATE_CHECK=1
SF="$PWD/node_modules/slashforge/bin/install.js"

# The sandbox paths become ~ (home) and <repo>, and the install time becomes <time>.
normalize() {
  tr -d '\r' \
    | sed -E -e 's#\\#/#g' -e "s#${BROKEN_M}#~#g" -e "s#${REPO_M}#<repo>#g" -e "s#${HOME_M}#~#g" \
        -e 's#"installed_at": "[^"]*"#"installed_at": "<time>"#' -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z#<time>#g'
}

# run NAME CMD...: runs a command with stdin from /dev/null, as in a script or CI, and records its output
# followed by its exit code.
run() {
  local name=$1; shift
  "$@" < /dev/null > "out/$name.raw.txt" 2>&1
  local code=$?
  { normalize < "out/$name.raw.txt"; echo "exit $code"; } > "out/$name.txt"
  compare "$name"
}

# files NAME DIR: the files under DIR, sorted, one per line.
files() {
  local name=$1 dir=$2
  (cd "$dir" && find . -type f | LC_ALL=C sort) > "out/$name.txt"
  compare "$name"
}

# --- Lesson 1: what the installer writes -------------------------------------------------------------------------

run l01_help node "$SF" --help
run l01_dry_run node "$SF" --dry-run
[ -e "$HOME_DIR/.claude" ] && echo "FAIL the dry run wrote to the home directory" && status=1

run l01_install node "$SF"
files l01_files "$HOME_DIR"

node scripts/dry-run-vs-install.mjs out/l01_dry_run.txt out/l01_files.txt > out/l01_dry_run_vs_install.txt
compare l01_dry_run_vs_install

{ normalize < "$HOME_DIR/.claude/setup/slashforge/meta.json"; } > out/l01_meta.txt
compare l01_meta

run l01_status node "$SF" status
# A second run finds the install. With stdin not a terminal it does not ask: it updates.
run l01_reinstall node "$SF"

# Project mode, in a repository: everything goes under ./.claude, with paths relative to the repository.
( cd "$REPO_DIR" && node "$SF" --project < /dev/null > "$PWD/../project.raw.txt" 2>&1; echo "exit $?" >> "$PWD/../project.raw.txt" )
normalize < out/project.raw.txt > out/l01_project.txt
compare l01_project
files l01_project_files "$REPO_DIR"

# uninstall does not ask either when stdin is not a terminal.
run l01_uninstall node "$SF" uninstall
files l01_after_uninstall "$HOME_DIR"
run l01_uninstall_again node "$SF" uninstall

# --- Lesson 2: inside the files --------------------------------------------------------------------------------

# The installer's own functions. The two sample paths resolve against the current drive on Windows: drop it.
node scripts/installer-functions.mjs 2>&1 | normalize | sed -E 's#[A-Za-z]:/(home|src)/#/\1/#g' > out/l02_installer_functions.txt
compare l02_installer_functions

# One line of code.md, as shipped and as rendered by each install mode.
node "$SF" < /dev/null > /dev/null 2>&1
( cd "$REPO_DIR" && node "$SF" --project < /dev/null > /dev/null 2>&1 )
{
  echo "# template";  grep -m1 'forge-workflow-quick.md`' node_modules/slashforge/templates/slashforge/code.md
  echo "# global";    grep -m1 'forge-workflow-quick.md`' "$HOME_DIR/.claude/commands/slashforge/code.md"
  echo "# project";   grep -m1 'forge-workflow-quick.md`' "$REPO_DIR/.claude/commands/slashforge/code.md"
  echo "# placeholders left in the installed files"
  echo "global  $(grep -r -c '{{' "$HOME_DIR/.claude" | awk -F: '{ n += $NF } END { print n }')"
  echo "project $(grep -r -c '{{' "$REPO_DIR/.claude" | awk -F: '{ n += $NF } END { print n }')"
} | normalize > out/l02_render.txt
compare l02_render

# Which installed files differ between the global and the project install, and in how many lines.
( cd "$HOME_DIR/.claude" && find . -type f | LC_ALL=C sort ) | while read -r f; do
  n=$(diff "$HOME_DIR/.claude/$f" "$REPO_DIR/.claude/$f" | grep -c '^<')
  [ "$n" -gt 0 ] && printf '%3d  %s\n' "$n" "$f"
done > out/l02_global_vs_project.txt
compare l02_global_vs_project

# The four commands are dispatchers: line counts of each command and of the workflow guides it delegates to.
( cd node_modules/slashforge/templates
  for f in slashforge/setup.md slashforge/code.md forge-workflow.md forge-workflow-agents.md forge-workflow-quick.md \
           slashforge/investigate.md forge-workflow-investigation.md slashforge/review-pr.md forge-workflow-review-pr.md; do
    printf '%4d  %s\n' "$(wc -l < "$f")" "$f"
  done ) > out/l02_sizes.txt
compare l02_sizes

# A template with a broken frontmatter: the installer refuses before writing anything.
rm -rf out/broken-pkg
cp -r node_modules/slashforge out/broken-pkg
sed -i.bak '/^description:/d' out/broken-pkg/templates/slashforge/verify.md && rm out/broken-pkg/templates/slashforge/verify.md.bak
if command -v cygpath > /dev/null; then USERPROFILE=$(cygpath -w "$BROKEN_HOME"); fi
HOME="$BROKEN_HOME" run l02_broken_template node out/broken-pkg/bin/install.js
if command -v cygpath > /dev/null; then USERPROFILE=$(cygpath -w "$HOME_DIR"); fi
files l02_broken_template_files "$BROKEN_HOME"

exit $status
