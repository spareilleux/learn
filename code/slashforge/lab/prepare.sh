#!/usr/bin/env bash
# SlashForge course, lessons 3 to 5: prepare a throwaway lab in which Claude Code runs the SlashForge commands.
# Not run by CI: those lessons need the model, an account and a budget. See run.sh.
#
#   bash lab/prepare.sh <lab-dir>
#
# The lab has its own home directory, its own Claude Code configuration directory, its own GitHub CLI and git
# configuration, and a clone of a public repository with no remote and a pre-push hook that refuses. Nothing is
# read from or written to the real ~/.claude, and no repository of yours is touched.
set -euo pipefail
cd "$(dirname "$0")/.."

LAB=${1:?usage: bash lab/prepare.sh <lab-dir>}
[ -e "$LAB" ] && { echo "refusing: $LAB already exists; pick a new directory"; exit 1; }
mkdir -p "$LAB"
LAB=$(cd "$LAB" && pwd)
case "$LAB" in "$HOME"/.claude*|"$PWD"*) echo "refusing: the lab must be outside ~/.claude and outside this repository"; exit 1;; esac

# The repository the commands run on: SlashForge itself, at the tag the course studies. Public, MIT, no
# dependencies, and its tests run with node --test.
REPO_URL=https://github.com/rajdeepratan/SlashForge.git
REPO_TAG=v4.4.3

mkdir -p "$LAB/home/.claude" "$LAB/gh"
w() { if command -v cygpath > /dev/null; then cygpath -w "$1"; else echo "$1"; fi; }

cat > "$LAB/lab.env" <<EOF
# Sourced by run.sh. Every variable points into the lab.
export HOME='$LAB/home'
export USERPROFILE='$(w "$LAB/home")'
export CLAUDE_CONFIG_DIR='$(w "$LAB/home/.claude")'
export GH_CONFIG_DIR='$(w "$LAB/gh")'
export GIT_CONFIG_GLOBAL='$LAB/home/.gitconfig'
export GIT_CONFIG_NOSYSTEM=1
export SLASHFORGE_NO_UPDATE_CHECK=1
LAB_REPO='$LAB/repo'
EOF
# shellcheck disable=SC1091
. "$LAB/lab.env"

git config --global user.name "SlashForge lab"
git config --global user.email "lab@example.invalid"
git config --global init.defaultBranch main

git clone --quiet --branch "$REPO_TAG" --depth 1 "$REPO_URL" "$LAB/repo" 2> /dev/null
git -C "$LAB/repo" switch --quiet -c lab
git -C "$LAB/repo" remote remove origin
printf '#!/bin/sh\necho "lab: push refused" >&2\nexit 1\n' > "$LAB/repo/.git/hooks/pre-push"
chmod +x "$LAB/repo/.git/hooks/pre-push"

# The kit, from the version pinned in package.json, installed globally into the lab's home — so the
# repository's working tree stays exactly as cloned and /slashforge:setup's changes are all its own.
node node_modules/slashforge/bin/install.js < /dev/null > "$LAB/install.log" 2>&1

echo "lab:        $LAB"
echo "repository: $(git -C "$LAB/repo" log -1 --format='%h %s') ($REPO_TAG, branch lab, no remote)"
echo "kit:        $(grep -o '"version": "[^"]*"' "$LAB/home/.claude/setup/slashforge/meta.json") in $CLAUDE_CONFIG_DIR"
echo "remotes:    $(git -C "$LAB/repo" remote | wc -l)"
