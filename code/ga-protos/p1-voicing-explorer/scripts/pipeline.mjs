// The build step as a function: GA's index in, the explorer's data file and manifest out.
// scripts/build-data.mjs calls it on the real index, the tests on a tiny generated fixture.
import { encode } from '../src/lib/format.mjs';
import { knnByDot } from '../src/lib/knn.mjs';
import { openIndex, SCHEMA_HASH_V4, COMPACT_PARTITIONS } from '../src/lib/optick.mjs';
import { fitPca, project } from '../src/lib/pca.mjs';
import { sampleIndices } from '../src/lib/sample.mjs';
import { familyOf, FAMILY_LIST, fretSpan, lowestFret, midiNotes, parseGaDiagram, tension, TUNINGS } from '../src/lib/voicing.mjs';

export function buildData(indexArrayBuffer, { sample = 30000, seed = 20260916, k = 10, fit = 'instrument', instrument = 'guitar', log = () => {} } = {}) {
  const t0 = performance.now();
  const index = openIndex(indexArrayBuffer);
  if (!index.schemaMatches)
    throw new Error(`schema hash 0x${index.schemaHash.toString(16)} is not OPTIC-K v1.8's 0x${SCHEMA_HASH_V4.toString(16)}`);
  const { first, count: total } = index.instruments[instrument];
  const n = Math.min(sample, total);
  const timings = { openMs: performance.now() - t0 };

  // Rows of the sample, as rows of the whole index
  const local = sampleIndices(total, n, seed);
  const rows = Uint32Array.from(local, (i) => i + first);
  log(`sampled ${n} of ${total} ${instrument} voicings with seed ${seed}`);

  // PCA fitted on every voicing of the instrument (or only the sample), then applied to the sample
  let t = performance.now();
  const fitRows = fit === 'sample' ? rows : Uint32Array.from({ length: total }, (_, i) => i + first);
  const pca = fitPca(index.vectors, index.dim, fitRows);
  timings.pcaMs = performance.now() - t;
  log(`PCA on ${fitRows.length} vectors: ${pca.sweeps} Jacobi sweeps, first 3 components explain ${(100 * (pca.explained[0] + pca.explained[1] + pca.explained[2])).toFixed(1)} %`);
  const raw3 = project(pca, index.vectors, rows, 3);
  let maxAbs = 0;
  for (const x of raw3) maxAbs = Math.max(maxAbs, Math.abs(x));
  const positions = raw3.map((x) => x / maxAbs);

  // Exact neighbours in the original 124 dimensions, within the sample
  t = performance.now();
  const sampleVectors = new Float32Array(n * index.dim);
  rows.forEach((r, i) => sampleVectors.set(index.vector(r), i * index.dim));
  const kk = Math.min(k, n - 1);
  const knn = knnByDot(sampleVectors, index.dim, n, Array.from({ length: n }, (_, i) => i), kk);
  timings.knnMs = performance.now() - t;
  log(`exact ${kk}-NN of ${n} voicings in ${index.dim} dimensions: ${(timings.knnMs / 1000).toFixed(1)} s`);

  const names = [];
  const nameIds = new Map();
  const data = {
    count: n,
    k: kk,
    positions,
    frets: new Int8Array(n * 6),
    nameId: new Uint16Array(n),
    family: new Uint8Array(n),
    span: new Uint8Array(n),
    lowFret: new Uint8Array(n),
    tension: new Uint8Array(n),
    noteCount: new Uint8Array(n),
    indexRow: rows,
    neighbours: n <= 65536 ? Uint16Array.from(knn.ids) : Uint32Array.from(knn.ids),
    neighbourScores: knn.scores,
  };
  const checks = { midiMismatches: 0, stringCountMismatches: 0 };
  const tuning = TUNINGS[instrument];
  rows.forEach((r, i) => {
    const meta = index.metadata(r);
    const frets = parseGaDiagram(meta.diagram);
    if (frets.length !== 6) checks.stringCountMismatches++;
    // The diagram, read string 1 first, must give back the index's own MIDI notes: this is what fixes the string order
    if (midiNotes(frets, tuning).join() !== meta.midiNotes.join()) checks.midiMismatches++;
    data.frets.set(frets.slice(0, 6), i * 6);
    const name = meta.quality ?? '?';
    if (!nameIds.has(name)) {
      nameIds.set(name, names.length);
      names.push(name);
    }
    data.nameId[i] = nameIds.get(name);
    data.family[i] = familyOf(name);
    data.span[i] = fretSpan(frets);
    data.lowFret[i] = lowestFret(frets);
    data.tension[i] = tension(meta.midiNotes);
    data.noteCount[i] = meta.midiNotes.length;
  });
  if (names.length > 65535) throw new Error('too many distinct names for Uint16');

  const bytes = encode(data);
  const manifest = {
    format: 'GAV1',
    instrument,
    count: n,
    instrumentTotal: total,
    indexTotal: index.count,
    seed,
    k: kk,
    pca: {
      fittedOn: fit === 'sample' ? 'sample' : `every ${instrument} voicing`,
      fittedRows: fitRows.length,
      explained: pca.explained.slice(0, 10).map((x) => +x.toFixed(6)),
      cumulative3: +(pca.explained[0] + pca.explained[1] + pca.explained[2]).toFixed(6),
      scale: maxAbs,
      loadingsByPartition: [0, 1, 2].map((c) =>
        Object.fromEntries(
          COMPACT_PARTITIONS.map((p) => {
            let s = 0;
            for (let j = p.start; j < p.start + p.dim; j++) s += pca.vectors[c * index.dim + j] ** 2;
            return [p.name, +s.toFixed(4)];
          }),
        ),
      ),
    },
    schemaHash: `0x${index.schemaHash.toString(16)}`,
    dim: index.dim,
    families: FAMILY_LIST,
    names,
    checks,
    bytes: bytes.length,
  };
  timings.totalMs = performance.now() - t0;
  return { bytes, manifest, timings, pca, rows, index };
}
