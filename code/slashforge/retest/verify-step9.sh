#!/usr/bin/env bash
# SlashForge course: does setup's Step 9 size check see skill folders? Three throwaway repositories, checked with
# the command 4.4.3 shipped and with the one 4.5.0 ships (templates/forge-instructions.md, Step 9), copied here.
#   ok      a 300-line SKILL.md (limit 500)            -> both commands should pass
#   big     a 600-line SKILL.md                        -> should be flagged
#   nested  a 250-line file inside a skill folder      -> should be flagged
set -uo pipefail
cd "$(dirname "$0")/.."
FIX="out/verify-step9"
rm -rf "$FIX" && mkdir -p "$FIX"
mk() { mkdir -p "$(dirname "$1")"; seq 1 "$2" > "$1"; }
for c in ok big nested; do
  mkdir -p "$FIX/$c" && (cd "$FIX/$c" && echo '# project' > CLAUDE.md && mk .claude/rules/api.md 5)
done
(cd "$FIX/ok" && mk .claude/skills/add/SKILL.md 300)
(cd "$FIX/big" && mk .claude/skills/add/SKILL.md 600)
(cd "$FIX/nested" && mk .claude/skills/add/SKILL.md 10 && mk .claude/skills/add/ref/notes.md 250)

# 4.4.3: it lists line counts for a person to read; count what it sees.
old() { bash -c 'wc -l CLAUDE.md .claude/**/*.md' 2>/dev/null | awk '$2 != "total" { print $2 }' | grep -c skills; }
# 4.5.0, verbatim.
new() {
  find CLAUDE.md .claude \( -path .claude/setup -o -path .claude/commands/slashforge \) -prune -o -name '*.md' -exec wc -l {} + \
    | awk '$NF == "total" { next } { limit = ($NF ~ /SKILL\.md$/) ? 500 : 200 } $1 > limit { print "over " limit ": " $0; bad = 1 } END { exit bad }'
}
echo "--- Step 9 on three repositories"
for c in ok big nested; do
  seen=$(cd "$FIX/$c" && old)
  out=$(cd "$FIX/$c" && new); code=$?
  echo "$c: 4.4.3 glob sees $seen skill file(s); 4.5.0 find exits $code ${out:+($out)}"
done
