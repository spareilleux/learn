#!/usr/bin/env bash
# SlashForge course, lessons 3 to 5: run one prompt through Claude Code in the lab that prepare.sh made,
# with an explicit ceiling, and record what it cost.
#
#   bash lab/run.sh <lab-dir> <name> <max-usd> <max-turns> <prompt>
#
# There is no default ceiling on purpose: every run names its budget. The run is headless (claude -p), so it
# stops at the first question the workflow asks — a SlashForge gate ends the run, it is never answered here.
# Edits are accepted inside the lab repository; shell commands are limited to read-only git, ls and the
# repository's tests; push, gh, the web and MCP servers are refused.
set -uo pipefail

LAB=${1:?lab dir}; NAME=${2:?name}; MAX_USD=${3:?max usd}; MAX_TURNS=${4:?max turns}; PROMPT=${5:?prompt}
# shellcheck disable=SC1091
. "$LAB/lab.env"
OUT="$LAB/runs/$NAME"
mkdir -p "$OUT"

# Edit and Write are not listed: acceptEdits accepts them inside the lab repository only, and anything outside is
# refused. (Listing them, as e1 did, pre-approved writes anywhere: the model wrote a helper script into %TEMP%.)
ALLOWED=(Read Glob Grep "Bash(git status:*)" "Bash(git log:*)" "Bash(git diff:*)" "Bash(git show:*)"
         "Bash(git branch:*)" "Bash(ls:*)" "Bash(node --test:*)" "Bash(npm test:*)" "Bash(node bin/install.js --dry-run:*)"
         ${EXTRA_ALLOWED:+"$EXTRA_ALLOWED"})
DENIED=("Bash(git push:*)" "Bash(gh:*)" "Bash(npm publish:*)" "Bash(curl:*)" WebFetch WebSearch)
# GH_STATUS_ONLY=1 lets the run call `gh auth status` and nothing else from gh: in the lab, GH_CONFIG_DIR is empty,
# so gh is logged out, and every other gh command is still refused.
if [ "${GH_STATUS_ONLY:-}" = 1 ]; then
  ALLOWED+=("Bash(gh auth status:*)")
  DENIED=("Bash(git push:*)" "Bash(gh auth login:*)" "Bash(gh pr:*)" "Bash(gh api:*)" "Bash(gh repo:*)" "Bash(npm publish:*)" "Bash(curl:*)" WebFetch WebSearch)
fi

{
  echo "name:      $NAME"
  echo "claude:    $(claude --version 2>&1)"
  echo "ceiling:   $MAX_USD USD, $MAX_TURNS turns, 900 s"
  echo "prompt:    $PROMPT"
  echo "head:      $(git -C "$LAB_REPO" log -1 --format=%h)"
} > "$OUT/run.txt"

touch "$OUT/.start"
start=$(date +%s)
( cd "$LAB_REPO" && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_CHILD_SESSION \
    -u CLAUDE_CODE_MESSAGING_SOCKET -u CLAUDE_CODE_MESSAGING_TOKEN -u CLAUDE_CODE_ENTRYPOINT -u ANTHROPIC_API_KEY \
    timeout 900 claude -p "$PROMPT" --output-format json \
      --max-budget-usd "$MAX_USD" --max-turns "$MAX_TURNS" \
      --permission-mode acceptEdits --strict-mcp-config \
      --allowedTools "${ALLOWED[@]}" --disallowedTools "${DENIED[@]}" \
      < /dev/null > "$OUT/result.json" 2> "$OUT/stderr.txt" )
code=$?
{
  echo "exit:      $code"
  echo "wall:      $(( $(date +%s) - start )) s"
  node -e '
    let r; try { r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); } catch { console.log("json:      none"); process.exit(0); }
    const u = r.usage || {};
    console.log("subtype:   " + r.subtype + (r.is_error ? " (error)" : ""));
    console.log("turns:     " + r.num_turns);
    console.log("model:     " + Object.keys(r.modelUsage || {}).join(", "));
    console.log("duration:  " + r.duration_ms + " ms (API " + r.duration_api_ms + " ms)");
    console.log("tokens:    in " + u.input_tokens + ", cache write " + u.cache_creation_input_tokens + ", cache read " + u.cache_read_input_tokens + ", out " + u.output_tokens);
    console.log("cost:      " + r.total_cost_usd + " USD (as computed by Claude Code)");
    console.log("denials:   " + (r.permission_denials || []).length);
  ' "$OUT/result.json"
  echo "changed:   $(git -C "$LAB_REPO" status --porcelain | wc -l) path(s) in the lab repository"
  # Files that appeared since the run started in the temp folder and next to the lab (not recursively): a write
  # that escaped the lab repository shows here. Other programs write status files there too, so the names are listed.
  echo "escaped:"
  find "${TMP:-/tmp}" "$(dirname "$LAB")" -maxdepth 1 -type f -newer "$OUT/.start" 2>/dev/null     | grep -v 'ga-claude-status-git-' | sed 's/^/  /'
} >> "$OUT/run.txt"
cat "$OUT/run.txt"
