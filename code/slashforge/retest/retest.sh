#!/usr/bin/env bash
# SlashForge course: rerun the course's reproductions against another slashforge release, without touching the
# pinned lab. The release is installed into out/retest-<version>/ (git-ignored), check.sh runs there against the
# expectations recorded for 4.4.3, and the outputs that carry a finding are printed. A FAIL means "differs from
# 4.4.3", not "broken": read each output. Run it on the old version too, as the negative control.
#
#   bash retest/retest.sh 4.5.0
#   bash retest/retest.sh 4.4.3     # negative control: every check must still pass
set -uo pipefail
cd "$(dirname "$0")/.."
VERSION=${1:?usage: bash retest/retest.sh <slashforge version>}
# The version becomes part of a folder this script deletes: accept a plain release number only, and refuse anything
# else before touching the file system.
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "refusing: '$VERSION' is not a release number like 4.5.0" >&2
  exit 2
fi
DIR="out/retest-$VERSION"
rm -rf "$DIR" && mkdir -p "$DIR"
cp -r check.sh expected scripts "$DIR/"
printf '{"name":"slashforge-retest","private":true,"devDependencies":{"slashforge":"%s"}}\n' "$VERSION" > "$DIR/package.json"
(cd "$DIR" && npm install --no-audit --no-fund --ignore-scripts > npm-install.log 2>&1) || { echo "npm install failed"; exit 2; }
(cd "$DIR" && bash check.sh > check.out 2>&1); code=$?
grep -E '^(ok|FAIL) |^slashforge |^v[0-9]' "$DIR/check.out"
echo "check.sh exit $code"
for name in l01_dry_run_vs_install l01_uninstall l02_installer_functions; do
  echo "--- $name"; cat "$DIR/out/$name.txt"
done
echo "--- dry-run labels"; grep -oE '^  (render|copy) ' "$DIR/out/l01_dry_run.txt" | sort | uniq -c
echo "--- shadowing warning on a project install"; grep -A2 'global install' "$DIR/out/l01_project.txt" || echo "(none)"
echo "--- templates running inline node -e"; grep -rl "node -e '" "$DIR/node_modules/slashforge/templates" | wc -l
bash retest/verify-step9.sh
