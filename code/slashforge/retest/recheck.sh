#!/usr/bin/env bash
# SlashForge course: recheck a 5.x release, whose layout check.sh's 4.4.3 expectations no longer describe. It installs
# the npm package into a throwaway home under out/recheck-<version>/ (git-ignored), prints one line per check of the
# journal's 2026-10-09 table, and runs SlashForge's own tests from a clone of the tag. The real ~/.claude and ~/.agents
# are never touched. Needs Node 24, npm, git and network access. Runs in Git Bash on Windows and in bash on Linux.
#
#   bash retest/recheck.sh 5.2.1
set -uo pipefail
cd "$(dirname "$0")/.."
VERSION=${1:?usage: bash retest/recheck.sh <slashforge version>}
# The version becomes part of a folder this script deletes: accept a plain release number only.
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "refusing: '$VERSION' is not a release number like 5.2.1" >&2
  exit 2
fi
R="$PWD/out/recheck-$VERSION"
rm -rf "$R" && mkdir -p "$R/pkg"
echo "node $(node --version), $(uname -s), slashforge $VERSION"

(cd "$R/pkg" && npm pack "slashforge@$VERSION" --silent > /dev/null && tar xzf "slashforge-$VERSION.tgz") || { echo "npm pack failed"; exit 2; }
# LF line endings whatever the machine's core.autocrlf: two of SlashForge's tests compare templates byte for byte.
git -c core.autocrlf=false -c advice.detachedHead=false clone -q --branch "v$VERSION" https://github.com/rajdeepratan/SlashForge.git "$R/sf" \
  || { echo "clone failed"; exit 2; }
echo "tag v$VERSION at $(git -C "$R/sf" rev-parse HEAD)"
for d in bin templates; do
  diff -rq "$R/pkg/package/$d" "$R/sf/$d" > /dev/null && echo "npm package $d/ == tag $d/" || echo "npm package $d/ DIFFERS from the tag"
done

SF="$R/pkg/package/bin/install.js"
H="$R/home"
mkdir -p "$H" "$R/repo"
# Node takes the home directory from USERPROFILE on Windows and from HOME elsewhere: point both at the sandbox. The
# installer prints that path back, with backslashes on Windows; HOME_M is the same path with forward slashes.
export HOME="$H" SLASHFORGE_NO_UPDATE_CHECK=1
if command -v cygpath > /dev/null; then
  export USERPROFILE; USERPROFILE=$(cygpath -w "$H"); HOME_M=$(cygpath -m "$H")
else
  HOME_M=$H
fi
unset CI
installer() { node "$SF" "$@" < /dev/null 2>&1; }
home_files() { (cd "$H" && find . -type f | LC_ALL=C sort); }

dry=$(installer --dry-run)
[ -e "$H/.claude" ] || [ -e "$H/.agents" ] && echo "FAIL the dry run wrote to the home directory"
planned=$(echo "$dry" | grep '→' | sed -e 's/.*→ *//' -e 's#\\#/#g' -e "s#^$HOME_M#.#" | tr -d '\r' | LC_ALL=C sort)
install_out=$(installer)
written=$(home_files)
echo "dry run lists $(echo "$planned" | wc -l | tr -d ' '), install writes $(echo "$written" | wc -l | tr -d ' ')"
echo "  written, not announced: $(comm -13 <(echo "$planned") <(echo "$written") | wc -l | tr -d ' ')"
echo "  announced, not written: $(comm -23 <(echo "$planned") <(echo "$written") | wc -l | tr -d ' ')"
echo "files per root: $(echo "$written" | awk -F/ '{ print $2 }' | sort | uniq -c | awk '{ printf "%s %s  ", $2, $1 }')"
echo "dry-run labels: $(echo "$dry" | grep -c '^  render') render, $(echo "$dry" | grep -c '^  copy') copy, $(echo "$dry" | grep -c '^  write') write"
echo "closing message names /slashforge-test or /slashforge-refactor: $(echo "$install_out" | grep -c 'slashforge-test\|slashforge-refactor') lines"
echo "status lists $(installer status | grep -c '^      • /slashforge-[a-z-]*$') Claude Code commands"
echo "disable-model-invocation: $(grep -l 'disable-model-invocation' "$H"/.claude/commands/*.md | wc -l | tr -d ' ') of $(ls "$H"/.claude/commands/*.md | wc -l | tr -d ' ') Claude Code files," \
  "$(grep -l 'disable-model-invocation' "$H"/.agents/skills/*/SKILL.md | wc -l | tr -d ' ') of $(ls "$H"/.agents/skills/*/SKILL.md | wc -l | tr -d ' ') Cursor and Codex skills"

(cd "$R/repo" && git init -q . && installer --project) > "$R/project.txt"
echo "warnings on a --project install with a global one present: $(grep -c '^⚠' "$R/project.txt")"

echo mine > "$H/.claude/setup/slashforge/my-notes.md"
echo mine > "$H/.agents/skills/slashforge-code/my-notes.md"
un=$(installer uninstall); un_code=$?
echo "uninstall with no terminal: $(echo "$un" | head -1) (exit $un_code)"
installer uninstall --yes > /dev/null
echo "left after uninstall --yes, from two files of mine: $(home_files | tr '\n' ' ')"

# The frontmatter check: a folded description, then a closing fence followed by a space, each in a copy of the package.
for variant in folded-description fence-trailing-space; do
  rm -rf "$R/fm" && mkdir -p "$R/fm/home" && cp -r "$R/pkg/package" "$R/fm/pkg"
  V="$R/fm/pkg/templates/slashforge/verify.md"
  if [ "$variant" = folded-description ]; then
    awk '!done && /^description: / { sub(/^description: /, "description: >\n  "); done = 1 } { print }' "$V" > "$V.tmp"
  else
    awk '/^---$/ && ++c == 2 { print "--- "; next } { print }' "$V" > "$V.tmp"
  fi
  mv "$V.tmp" "$V"
  if command -v cygpath > /dev/null; then FM_USERPROFILE=$(cygpath -w "$R/fm/home"); else FM_USERPROFILE=; fi
  HOME="$R/fm/home" USERPROFILE="$FM_USERPROFILE" node "$R/fm/pkg/bin/install.js" < /dev/null > /dev/null 2>&1
  echo "frontmatter, $variant: install exit $?"
done

# Setup's size check (Step 9), copied from the claude target of slashforge-instructions.md, on a throwaway repository.
F="$R/step9"
mkdir -p "$F/.claude/rules" "$F/.claude/skills/ok" "$F/.claude/skills/big" "$F/.claude/setup/slashforge" "$F/.claude/commands"
printf '# P\n' > "$F/CLAUDE.md"
seq 1 250 > "$F/.claude/rules/api.md"; seq 1 300 > "$F/.claude/skills/ok/SKILL.md"; seq 1 600 > "$F/.claude/skills/big/SKILL.md"
seq 1 900 > "$F/.claude/setup/slashforge/guide.md"; seq 1 900 > "$F/.claude/commands/slashforge-code.md"; seq 1 210 > "$F/.claude/commands/mine.md"
grep -q "find CLAUDE.md .claude" "$R/sf/templates/slashforge-instructions.md" || echo "WARN the Step 9 command changed upstream"
(cd "$F" && find CLAUDE.md .claude \( -path .claude/setup -o -path '.claude/commands/slashforge-*.md' \) -prune -o -name '*.md' -exec wc -l {} + \
  | awk '$NF == "total" { next } { limit = ($NF ~ /SKILL\.md$/) ? 500 : 200 } $1 > limit { print "  over " limit ": " $1, $2; bad = 1 } END { exit bad }' | LC_ALL=C sort)
echo "step 9 exit $?"

# SlashForge's own tests. SSH_CONNECTION makes the old opener assertion (test/install.test.js:570 at v5.2.1) bail out:
# without it, the helper runs start on Windows, and wslview or explorer.exe under WSL, where WSLg sets DISPLAY.
start=$(date +%s%N)
(cd "$R/sf" && SSH_CONNECTION='1.2.3.4 22 5.6.7.8 22' node --test --test-reporter=tap > "$R/tests-tap.txt" 2>&1)
code=$?
echo "node --test: exit $code, wall $(awk -v a="$start" -v b="$(date +%s%N)" 'BEGIN { printf "%.1f", (b - a) / 1e9 }') s"
grep -E '^# (tests|pass|fail|skipped) ' "$R/tests-tap.txt" | tr '\n' ' '; echo
grep '^not ok' "$R/tests-tap.txt"
echo "slowest: $(awk '/^# Subtest:/ { name = substr($0, 12) } /^  duration_ms:/ { print $2, name }' "$R/tests-tap.txt" | sort -rn | head -1)"
