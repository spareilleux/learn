// The gate CI applies to the reduced run: not "the numbers are the published ones" — they are not, the dataset
// is generated on the runner — but "the pipeline is still doing its job on every operating system".

import { readFileSync } from 'node:fs';

const i = process.argv.indexOf('--run');
const path = i === -1 ? 'out/ci-measurements.json' : process.argv[i + 1];
const run = JSON.parse(readFileSync(path, 'utf8'));
const by = (mode, name) => run.splits[mode].models.find((m) => m.name === name);

const gbt = by('chord', 'gradient-boosting');
const forest = by('chord', 'random-forest');
const ridge = by('chord', 'ridge');
const ga = by('chord', 'ga-hand-written');
const mean = by('chord', 'baseline-mean');

console.log(`chord split: boosting ${gbt.spearman}, forest ${forest.spearman}, ridge ${ridge.spearman}, GA ${ga.spearman}`);
console.log(`boosting trained in ${gbt.trainMs} ms and serialises to ${gbt.sizeBytes} bytes`);
console.log(`prediction is ${run.speed.speedup} times faster than the fingering search`);
console.log(`the whole reduced run took ${(run.totalMs / 1000).toFixed(1)} s on ${run.platform}, Node ${run.node}`);

const failures = [];
const want = (condition, message) => {
  if (!condition) failures.push(message);
};

want(run.dataset.rows >= 1000, `only ${run.dataset.rows} voicings in the reduced dataset`);
want(gbt.spearman > ga.spearman, `the boosted trees (${gbt.spearman}) did not beat GA's cost (${ga.spearman})`);
want(forest.spearman > ga.spearman, `the forest (${forest.spearman}) did not beat GA's cost (${ga.spearman})`);
want(gbt.pairwise > 0.8, `pairwise accuracy below 0.8: ${gbt.pairwise}`);
want(Math.abs(mean.pairwise - 0.5) < 1e-9, `the mean baseline is not at 0.5: ${mean.pairwise}`);
want(run.speed.searchMsPerVoicing > 0 && run.speed.modelMsPerVoicing > 0, 'the speed probe measured nothing');
want(run.splits.chord.groups > 20, `the split by chord found only ${run.splits.chord.groups} chords`);
want(run.splits.chord.train > 0 && run.splits.chord.val > 0, 'the split by chord left no training or validation rows');
want(run.totalMs < 10 * 60 * 1000, `the reduced run took ${run.totalMs} ms`);
for (const mode of ['voicing', 'chord', 'shape'])
  want(run.splits[mode].test > 0, `the split by ${mode} left no test rows`);

if (failures.length) {
  console.error(failures.join('\n'));
  process.exit(1);
}
console.log('every gate passed');
