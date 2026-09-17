// Scores every cost function against results/annotations.json: for each annotated pair, does the cost put the
// shape marked "harder" above the other one? Reports the high-confidence pairs on their own, then every pair,
// and lists the pairs each cost gets wrong so the lesson can show them.
//
//   node scripts/check-annotations.mjs --out results/annotation-scores.json

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { parseChart } from '../src/lib/voicing.mjs';
import { gaCost, gaPlayability } from '../src/lib/ga-cost.mjs';
import { ruleCost } from '../src/lib/rules.mjs';
import { bestFingering } from '../src/lib/fingering.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const arg = (name, fallback = null) => {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? fallback : process.argv[i + 1];
};
const annotationsPath = arg('annotations', resolve(here, '../results/annotations.json'));
const outPath = arg('out', resolve(here, '../results/annotation-scores.json'));

mkdirSync(dirname(outPath), { recursive: true });
const data = JSON.parse(readFileSync(annotationsPath, 'utf8'));
const costs = {
  'fingering-search (target)': (frets) => bestFingering(frets).cost,
  'ga-hand-written': gaCost,
  'rule-checklist': ruleCost,
};

const shapeCosts = {};
for (const [name, chart] of Object.entries(data.shapes)) {
  const frets = parseChart(chart);
  const ga = gaPlayability(frets);
  const best = bestFingering(frets);
  shapeCosts[name] = {
    chart,
    target: Number(best.cost.toFixed(3)),
    ga: Number(ga.score.toFixed(3)),
    gaDifficulty: ga.difficulty,
    rules: ruleCost(frets),
    fingering: best.fingering,
    barre: best.barre ? `fret ${best.barre.fret}, ${best.barre.barred} strings` : null,
  };
}

const report = { annotator: data.annotator, date: data.date, shapes: shapeCosts, scores: {} };

for (const [costName, cost] of Object.entries(costs)) {
  const buckets = { high: { right: 0, total: 0 }, all: { right: 0, total: 0 } };
  const wrong = [];
  for (const pair of data.pairs) {
    const ca = cost(parseChart(data.shapes[pair.a]));
    const cb = cost(parseChart(data.shapes[pair.b]));
    const harder = ca > cb ? 'a' : cb > ca ? 'b' : 'tie';
    const right = harder === pair.harder ? 1 : harder === 'tie' ? 0.5 : 0;
    buckets.all.right += right;
    buckets.all.total++;
    if (pair.confidence === 'high') {
      buckets.high.right += right;
      buckets.high.total++;
    }
    if (right < 1) {
      wrong.push({
        pair: `${pair.a} vs ${pair.b}`,
        annotated: pair.harder === 'a' ? pair.a : pair.b,
        said: harder === 'tie' ? 'a tie' : harder === 'a' ? pair.a : pair.b,
        costs: { [pair.a]: Number(ca.toFixed(3)), [pair.b]: Number(cb.toFixed(3)) },
        confidence: pair.confidence,
        why: pair.why,
      });
    }
  }
  report.scores[costName] = {
    highConfidence: Number((buckets.high.right / buckets.high.total).toFixed(4)),
    highConfidencePairs: buckets.high.total,
    allPairs: Number((buckets.all.right / buckets.all.total).toFixed(4)),
    pairs: buckets.all.total,
    wrong,
  };
}

// --check compares what this machine computes with the committed file, to the last decimal that matters:
// the costs are pure arithmetic on the diagram, so every runner must agree with the published run.
if (process.argv.includes('--check')) {
  const committed = JSON.parse(readFileSync(resolve(here, '../results/annotation-scores.json'), 'utf8'));
  const problems = [];
  for (const [name, shape] of Object.entries(report.shapes)) {
    const was = committed.shapes[name];
    if (!was) problems.push(`${name}: missing from the committed file`);
    else
      for (const field of ['target', 'ga', 'rules'])
        if (Math.abs(shape[field] - was[field]) > 1e-9) problems.push(`${name}.${field}: ${shape[field]} vs ${was[field]}`);
  }
  for (const [name, score] of Object.entries(report.scores)) {
    const was = committed.scores[name];
    if (Math.abs(score.highConfidence - was.highConfidence) > 1e-9 || Math.abs(score.allPairs - was.allPairs) > 1e-9)
      problems.push(`${name}: ${score.highConfidence}/${score.allPairs} vs ${was.highConfidence}/${was.allPairs}`);
  }
  if (problems.length) {
    console.error(`this machine disagrees with the committed scores:\n  ${problems.join('\n  ')}`);
    process.exit(1);
  }
  console.log('every cost matches the committed results/annotation-scores.json');
}

writeFileSync(outPath, `${JSON.stringify(report, null, 2)}\n`);
for (const [name, s] of Object.entries(report.scores)) {
  console.log(`${name}: ${s.highConfidence} on ${s.highConfidencePairs} high-confidence pairs, ${s.allPairs} on all ${s.pairs}`);
  for (const w of s.wrong) console.log(`   wrong: ${w.pair} — annotated ${w.annotated}, said ${w.said} (${JSON.stringify(w.costs)})`);
}
console.log(`${outPath} written`);
