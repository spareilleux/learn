#!/usr/bin/env bash
# VexTab & VexFlow course: render every lesson example with VexTab and VexFlow under Node, run lesson 4's texts through
# GA's F# parser and through VexTab, and compare every output with expected/.
# UPDATE=1 bash check.sh writes the outputs to expected/ and the illustrations to src/assets/vexflow-vextab/ instead of
# comparing (review the diff before committing). Run npm ci in this folder first; lesson 4 also needs the .NET 10 SDK.
set -uo pipefail
cd "$(dirname "$0")"
assets=../../src/assets/vexflow-vextab
echo "node $(node --version), vextab $(node -p "require('vextab/package.json').version"), VexFlow $(node -p "require('./lib/env.cjs').loadVexTab().Vex.Flow.BUILD.VERSION") bundled in vextab (vexflow $(node -p "JSON.parse(require('fs').readFileSync('node_modules/vexflow/package.json')).version") installed beside it), jsdom $(node -p "require('jsdom/package.json').version"), opentype.js $(node -p "require('opentype.js/package.json').version")"
status=0
rm -rf out && mkdir -p out expected

# compare <name>: out/<name> (a file or a folder) against expected/<name>
compare() {
  local name=$1
  if [ "${UPDATE:-}" = 1 ]; then
    rm -rf "expected/$name" && cp -r "out/$name" "expected/$name"
    echo "upd  $name"
  elif diff -r --strip-trailing-cr "expected/$name" "out/$name" > out/diff.txt; then
    echo "ok   $name"
  else
    head -40 out/diff.txt
    echo "FAIL $name"
    status=1
  fi
}

# Lessons 1 to 3: each example rendered (SVG) or rejected (the error VexTab raises), and two parse trees
node render.cjs --out out/ex examples/*.vextab > /dev/null
compare ex
node render.cjs --ast --out out/ast examples/l01-notation.vextab examples/l01-fret-run.vextab > /dev/null
compare ast

# Lesson 4: every VexTab text GA writes or tests, through GA's F# parser, then through VexTab
if command -v dotnet > /dev/null; then
  bash fetch-ga.sh
  dotnet build ga/GaVexTab -c Release -m:1 -v q -nologo > out/ga-build.txt 2>&1 || { cat out/ga-build.txt; status=1; }
  dotnet run --project ga/GaVexTab -c Release --no-build -- .ga ga/cases out/ga > out/ga-fsharp.txt
  compare ga-fsharp.txt
  compare ga
  node render.cjs --out out/ga-js out/ga/*.vextab > /dev/null
  compare ga-js
  node ga/table.cjs out/ga-fsharp.txt out/ga-js > out/ga-table.md
  compare ga-table.md
else
  echo "skip lesson 4: no dotnet"
fi

# The drawings shown in the lessons: the rendered SVG, glyphs turned into outlines (illustrate.cjs)
mkdir -p out/illustrations
while read -r src name; do
  case "$src" in '#'* | '') continue ;; esac
  if [ -f "out/$src.svg" ]; then node illustrate.cjs "out/$src.svg" "out/illustrations/$name.svg"; fi
done < illustrations.txt
if [ "${UPDATE:-}" = 1 ]; then
  mkdir -p "$assets" && cp out/illustrations/*.svg "$assets/"
  echo "upd  illustrations"
elif command -v dotnet > /dev/null; then
  if diff -r --strip-trailing-cr "$assets" out/illustrations > out/diff.txt; then echo "ok   illustrations"; else head -20 out/diff.txt; echo "FAIL illustrations"; status=1; fi
fi

[ $status = 0 ] && echo "all outputs match expected/" || echo "some outputs differ from expected/"
exit $status
