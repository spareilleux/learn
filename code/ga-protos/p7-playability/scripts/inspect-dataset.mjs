// A look at the dataset that is not a measurement: how the voicings the search cannot finger are distributed,
// and what GA's cost says about them.
//
//   node scripts/inspect-dataset.mjs --data G:/learn-lab/ga-protos/p7/all.jsonl

import { readFileSync } from 'node:fs';
import { parseDiagram, chartName, layout } from '../src/lib/voicing.mjs';

const i = process.argv.indexOf('--data');
const path = i === -1 ? 'G:/learn-lab/ga-protos/p7/all.jsonl' : process.argv[i + 1];
const rows = readFileSync(path, 'utf8').split('\n').filter((l) => l.length > 1).map((l) => JSON.parse(l));
const bad = rows.filter((r) => r.f === 0);
const good = rows.filter((r) => r.f === 1);
console.log(`${bad.length} of ${rows.length} voicings have no legal fingering (${((100 * bad.length) / rows.length).toFixed(1)} %)`);

const histogram = (list, key) => {
  const h = new Map();
  for (const r of list) h.set(key(r), (h.get(key(r)) ?? 0) + 1);
  return [...h.entries()].sort((a, b) => b[1] - a[1]);
};

const shape = (r) => {
  const l = layout(parseDiagram(r.d));
  return `${l.fretted.length} fretted, ${l.distinctFrets} frets, span ${l.span}`;
};
console.log('\nthe shapes the search rejects:');
for (const [k, n] of histogram(bad, shape).slice(0, 12)) console.log(`  ${n.toString().padStart(7)}  ${k}`);
console.log('\nthe shapes it accepts:');
for (const [k, n] of histogram(good, shape).slice(0, 12)) console.log(`  ${n.toString().padStart(7)}  ${k}`);

console.log('\nten rejected voicings, as a chart:');
for (const r of bad.slice(0, 10)) console.log(`  ${chartName(parseDiagram(r.d)).padEnd(12)} ${String(r.q).padEnd(24)} GA ${r.g}`);

const gaOfBad = bad.map((r) => r.g).sort((a, b) => a - b);
const gaOfGood = good.map((r) => r.g).sort((a, b) => a - b);
const median = (v) => v[Math.floor(v.length / 2)];
console.log(`\nGA's cost: median ${median(gaOfBad).toFixed(3)} on the rejected voicings, ${median(gaOfGood).toFixed(3)} on the others`);
console.log(`GA's cost never exceeds ${Math.max(...gaOfBad).toFixed(3)} on a voicing nobody can finger`);
