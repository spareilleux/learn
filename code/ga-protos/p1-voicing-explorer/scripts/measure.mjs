// Measures what the explorer's 3D view keeps of GA's voicing space (hypotheses H1-H4 and H7 in results/hypotheses.md):
//   node scripts/measure.mjs --index <optick.index> [--sample 30000] [--seed 20260916] [--queries 2000] [--out results/measurements.json]
// Single-threaded and deterministic; about a minute on the whole index.
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { layout } from '../src/lib/diagram.mjs';
import { knnByDistance, knnByDot } from '../src/lib/knn.mjs';
import { openIndex } from '../src/lib/optick.mjs';
import { fitPca, project } from '../src/lib/pca.mjs';
import { sampleIndices } from '../src/lib/sample.mjs';
import { familyOf, FAMILY_LIST, parseGaDiagram, toChartOrder } from '../src/lib/voicing.mjs';

const args = process.argv.slice(2);
const option = (name, fallback) => (args.includes(name) ? args[args.indexOf(name) + 1] : fallback);
const indexPath = option('--index');
const sampleSize = Number(option('--sample', 30000));
const seed = Number(option('--seed', 20260916));
const queryCount = Number(option('--queries', 2000));
const out = option('--out', 'results/measurements.json');
const K = 10;
const DIMS = [2, 3, 10, 32];
const log = (s) => console.log(s);
const clock = () => performance.now();

let t = clock();
const file = readFileSync(indexPath);
const index = openIndex(file.buffer.slice(file.byteOffset, file.byteOffset + file.byteLength));
const { first, count: total } = index.instruments.guitar;
const dim = index.dim;
const loadMs = clock() - t;
log(`index: ${index.count} voicings, ${total} guitar, ${dim} dimensions, loaded in ${loadMs.toFixed(0)} ms`);

// H1: variance
t = clock();
const all = Uint32Array.from({ length: total }, (_, i) => i + first);
const pca = fitPca(index.vectors, dim, all);
const pcaMs = clock() - t;
const cumulative = (d) => pca.explained.slice(0, d).reduce((s, x) => s + x, 0);
const variance = Object.fromEntries([1, 2, 3, 10, 32, 64].map((d) => [d, +cumulative(d).toFixed(4)]));
log(`H1 cumulative explained variance: ${JSON.stringify(variance)} (PCA ${pcaMs.toFixed(0)} ms)`);

// The sample, and the queries: a seeded subset of the sample
const sampleRows = Uint32Array.from(sampleIndices(total, sampleSize, seed), (i) => i + first);
const queryPositions = Array.from(sampleIndices(sampleSize, queryCount, seed + 1));
const sampleVectors = new Float32Array(sampleSize * dim);
sampleRows.forEach((r, i) => sampleVectors.set(index.vector(r), i * dim));
const guitarVectors = index.vectors.subarray(first * dim, (first + total) * dim);
// Query rows as rows of the guitar block
const queryGuitarRows = queryPositions.map((p) => sampleRows[p] - first);

const projections = Object.fromEntries(DIMS.map((d) => [d, project(pca, index.vectors, all, d)]));
const sampleProjection = (d) => {
  const src = projections[d];
  const outRows = new Float32Array(sampleSize * d);
  sampleRows.forEach((r, i) => outRows.set(src.subarray((r - first) * d, (r - first + 1) * d), i * d));
  return outRows;
};

function dotOf(vectors, a, b) {
  let s = 0;
  for (let j = 0; j < dim; j++) s += vectors[a * dim + j] * vectors[b * dim + j];
  return s;
}

function evaluate(label, vectors, n, queries) {
  t = clock();
  const truth = knnByDot(vectors, dim, n, queries, K + 1);
  const truthMs = clock() - t;
  let ties = 0;
  let tenth = 0;
  for (let q = 0; q < queries.length; q++) {
    const s = truth.scores.subarray(q * (K + 1), (q + 1) * (K + 1));
    if (s[K - 1] === s[K]) ties++;
    tenth += s[K - 1];
  }
  const result = {
    queries: queries.length,
    candidates: n,
    exactSearchMs: +truthMs.toFixed(0),
    meanTenthNeighbourScore: +(tenth / queries.length).toFixed(4),
    tiedTenth: +(ties / queries.length).toFixed(4),
    recall: {},
    recallWithTies: {},
    familyAgreement: {},
  };
  const family = (row) => familyCache.get(row) ?? familyCache.set(row, familyOf(index.metadata(row).quality)).get(row);
  const rowOf = n === sampleSize ? (i) => sampleRows[i] : (i) => i + first;
  const agreement = (ids) => {
    let same = 0;
    queries.forEach((q, qi) => {
      const f = family(rowOf(q));
      for (let j = 0; j < K; j++) if (family(rowOf(ids[qi * (K + 1) + j] ?? ids[qi * K + j])) === f) same++;
    });
    return +(same / (queries.length * K)).toFixed(4);
  };
  result.familyAgreement.exact = agreement(truth.ids);
  for (const d of DIMS) {
    const projected = n === sampleSize ? sampleProjection(d) : projections[d];
    t = clock();
    const approx = knnByDistance(projected, d, n, queries, K);
    const ms = clock() - t;
    let strict = 0;
    let loose = 0;
    queries.forEach((q, qi) => {
      const trueIds = new Set(truth.ids.subarray(qi * (K + 1), qi * (K + 1) + K));
      const tenthScore = truth.scores[qi * (K + 1) + K - 1];
      for (let j = 0; j < K; j++) {
        const id = approx.ids[qi * K + j];
        if (trueIds.has(id)) strict++;
        if (Math.fround(dotOf(vectors, q, id)) >= tenthScore) loose++;
      }
    });
    result.recall[d] = +(strict / (queries.length * K)).toFixed(4);
    result.recallWithTies[d] = +(loose / (queries.length * K)).toFixed(4);
    const padded = new Int32Array(queries.length * (K + 1));
    queries.forEach((_, qi) => padded.set(approx.ids.subarray(qi * K, (qi + 1) * K), qi * (K + 1)));
    result.familyAgreement[`pca${d}`] = agreement(padded);
    log(`  ${label}: PCA-${d} recall@10 ${result.recall[d]} (with ties ${result.recallWithTies[d]}), search ${ms.toFixed(0)} ms`);
  }
  log(`${label}: ${JSON.stringify(result)}`);
  return result;
}
const familyCache = new Map();

const withinSample = evaluate('H2 within the sample', sampleVectors, sampleSize, queryPositions);
const againstIndex = evaluate('H3 against every guitar voicing', guitarVectors, total, queryGuitarRows);

// Exact duplicate vectors among guitar voicings
t = clock();
const seen = new Map();
let duplicates = 0;
for (let i = 0; i < total; i++) {
  const v = guitarVectors.subarray(i * dim, (i + 1) * dim);
  const key = createHash('sha1').update(new Uint8Array(v.buffer, v.byteOffset, v.byteLength)).digest('base64');
  if (seen.has(key)) duplicates++;
  else seen.set(key, i);
}
log(`duplicate vectors: ${duplicates} of ${total} (${(clock() - t).toFixed(0)} ms)`);

// H7: dots off GA's 5-fret grid, and the family mix
let offGrid = 0;
const families = new Array(FAMILY_LIST.length).fill(0);
const spans = {};
for (let i = 0; i < total; i++) {
  const meta = index.metadata(first + i);
  const chart = toChartOrder(parseGaDiagram(meta.diagram));
  if (layout(chart).marks.some((m) => m.kind === 'outside')) offGrid++;
  families[familyOf(meta.quality)]++;
  const fretted = chart.filter((f) => f > 0);
  const span = fretted.length ? Math.max(...fretted) - Math.min(...fretted) : 0;
  spans[span] = (spans[span] ?? 0) + 1;
}
log(`H7 voicings with a dot off GA's grid: ${offGrid} of ${total} (${((100 * offGrid) / total).toFixed(2)} %)`);

const result = {
  measuredAt: new Date().toISOString(),
  node: process.version,
  index: { path: indexPath, bytes: file.length, sha256: createHash('sha256').update(file).digest('hex'), voicings: index.count, guitar: total, dim },
  sample: { size: sampleSize, seed, queries: queryCount, querySeed: seed + 1 },
  timingsMs: { loadIndex: +loadMs.toFixed(0), pcaFitAllGuitar: +pcaMs.toFixed(0) },
  explainedVariance: pca.explained.slice(0, 12).map((x) => +x.toFixed(5)),
  cumulativeVariance: variance,
  withinSample,
  againstIndex,
  duplicateVectors: duplicates,
  offGridDiagrams: offGrid,
  families: Object.fromEntries(FAMILY_LIST.map((f, i) => [f.id, families[i]])),
  fretSpans: spans,
};
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, JSON.stringify(result, null, 1) + '\n');
log(`wrote ${out}`);
