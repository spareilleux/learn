// Turns GA's OPTK index into the dataset this prototype learns on: one line per guitar voicing, with its
// diagram, the chord it belongs to, its shape with the position removed, GA's hand-written cost, the rule
// checklist, and the target — the cost of the best fingering found by the search in src/lib/fingering.mjs.
//
//   node scripts/build-dataset.mjs --index G:/learn-33/ga-p1/optick.index --out G:/learn-lab/ga-protos/p7/all.jsonl
//   node scripts/build-dataset.mjs --index ... --out ... --sample 60000 --seed 20260917
//
// Nothing here is a measurement: it only writes down what the three cost functions say about each voicing.

import { readFileSync, writeFileSync, mkdirSync, createWriteStream } from 'node:fs';
import { dirname } from 'node:path';
import { createHash } from 'node:crypto';
import { openIndexMetadata } from '../src/lib/optick-meta.mjs';
import { parseDiagram, shapeKey, pitchClassKey, layout } from '../src/lib/voicing.mjs';
import { gaCost } from '../src/lib/ga-cost.mjs';
import { ruleCost } from '../src/lib/rules.mjs';
import { bestFingering } from '../src/lib/fingering.mjs';
import { mulberry32, shuffle } from '../src/lib/random.mjs';

function arg(name, fallback = null) {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? fallback : process.argv[i + 1];
}

const indexPath = arg('index');
const outPath = arg('out');
const sample = Number(arg('sample', '0'));
const seed = Number(arg('seed', '20260917'));
const statsPath = arg('stats');
if (!indexPath || !outPath) {
  console.error('usage: build-dataset.mjs --index <optick.index> --out <file.jsonl> [--sample N] [--seed S] [--stats f.json]');
  process.exit(2);
}

mkdirSync(dirname(outPath), { recursive: true });
const started = Date.now();
const buffer = readFileSync(indexPath);
const sha256 = createHash('sha256').update(buffer).digest('hex');
const index = openIndexMetadata(buffer);
const guitar = index.instruments.guitar;
console.log(`${indexPath}: ${buffer.length} bytes, sha256 ${sha256}`);
console.log(`${index.count} voicings, ${guitar.count} guitar from row ${guitar.first}`);

let rows = Array.from({ length: guitar.count }, (_, i) => guitar.first + i);
if (sample > 0 && sample < rows.length) {
  shuffle(rows, mulberry32(seed));
  rows = rows.slice(0, sample).sort((a, b) => a - b);
}

const out = createWriteStream(outPath);
const stats = {
  index: { path: indexPath, bytes: buffer.length, sha256, count: index.count, guitar: guitar.count },
  seed,
  rows: rows.length,
  infeasible: 0,
  noFretted: 0,
  target: { min: Infinity, max: -Infinity, sum: 0 },
  ga: { min: Infinity, max: -Infinity, sum: 0 },
  chords: 0,
  shapes: 0,
  searchMs: 0,
};
const chords = new Set();
const shapes = new Set();

let written = 0;
for (const row of rows) {
  const meta = index.metadata(row);
  if (meta.instrument !== 'guitar') continue;
  const frets = parseDiagram(meta.diagram);
  if (frets.length !== 6) continue;
  const l = layout(frets);
  if (!l.fretted.length) {
    stats.noFretted++;
    continue;
  }
  const t0 = process.hrtime.bigint();
  const best = bestFingering(frets);
  stats.searchMs += Number(process.hrtime.bigint() - t0) / 1e6;
  if (!best.feasible) stats.infeasible++;
  const chord = pitchClassKey(meta.midiNotes);
  const shape = shapeKey(frets);
  chords.add(chord);
  shapes.add(shape);
  const ga = gaCost(frets);
  const rule = ruleCost(frets);
  stats.target.min = Math.min(stats.target.min, best.cost);
  stats.target.max = Math.max(stats.target.max, best.cost);
  stats.target.sum += best.cost;
  stats.ga.min = Math.min(stats.ga.min, ga);
  stats.ga.max = Math.max(stats.ga.max, ga);
  stats.ga.sum += ga;
  out.write(
    `${JSON.stringify({
      row,
      d: meta.diagram,
      q: meta.quality,
      c: chord,
      s: shape,
      t: Number(best.cost.toFixed(6)),
      g: Number(ga.toFixed(6)),
      r: rule,
      f: best.feasible ? 1 : 0,
    })}\n`,
  );
  written++;
  if (written % 25000 === 0) console.log(`  ${written} rows, ${((Date.now() - started) / 1000).toFixed(1)} s`);
}
out.end();

stats.written = written;
stats.chords = chords.size;
stats.shapes = shapes.size;
stats.target.mean = stats.target.sum / written;
stats.ga.mean = stats.ga.sum / written;
stats.totalMs = Date.now() - started;
console.log(JSON.stringify(stats, null, 2));
if (statsPath) writeFileSync(statsPath, `${JSON.stringify(stats, null, 2)}\n`);
