// Experiment 5's data: GuitarAlchemist's OPTIC-K voicing index projected to 3D, twice, for the point cloud pages.
//   node scripts/optick-project.ts [--index <path to optick.index>] [--synthetic <count>]
// The index is opened read-only and never written: the OPTK v4 layout of GA's OptickIndexReader.cs (magic, version,
// header size, schema hash, endian mark, dimension, count, instruments, offsets), then count × dimension float32 vectors,
// L2-normalized. Without an index (CI, or a machine without GA's state/ folder), --synthetic writes a documented stand-in
// of the same dimension: 16 Gaussian clusters in 124 dimensions, L2-normalized, from a fixed seed.
// The projection is PCA: mean and covariance of up to 60,000 vectors (every n-th), eigenvectors by Jacobi rotations,
// then every vector projected on components 1-3 (projection A) and 4-6 (projection B), each scaled so that 99% of the
// points fall within [-1, 1]. Output: public/generated/optick.bin (u32 count, u32 flags, count × 6 float32) and
// public/generated/optick.json (where the data came from).
import { createHash } from 'node:crypto';
import { closeSync, existsSync, mkdirSync, openSync, readSync, statSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const args = process.argv.slice(2);
const option = (name: string) => (args.includes(name) ? args[args.indexOf(name) + 1] : null);
const lab = resolve(import.meta.dirname, '..');
const defaultIndex = resolve(lab, '../../../../ga/state/voicings/optick.index');
const indexPath = option('--index') ?? defaultIndex;
const synthetic = option('--synthetic');

type Source = { kind: 'ga-index' | 'synthetic'; count: number; dimension: number; vectors: Float32Array; details: Record<string, unknown> };

function readIndex(path: string): Source {
  const fd = openSync(path, 'r');
  try {
    const header = Buffer.alloc(120);
    readSync(fd, header, 0, 120, 0);
    if (header.toString('latin1', 0, 4) !== 'OPTK') throw new Error(`${path}: no OPTK magic`);
    const version = header.readUInt32LE(4);
    const headerSize = header.readUInt32LE(8);
    const schemaHash = header.readUInt32LE(12);
    const endian = header.readUInt16LE(16);
    const dimension = header.readUInt32LE(20);
    const count = Number(header.readBigUInt64LE(24));
    const instruments = header.readUInt8(32);
    const ranges = [0, 1, 2].map((i) => ({ byteOffset: Number(header.readBigUInt64LE(40 + i * 16)), count: Number(header.readBigUInt64LE(48 + i * 16)) }));
    const vectorsOffset = Number(header.readBigUInt64LE(96));
    if (version !== 4 || endian !== 0xfeff) throw new Error(`${path}: version ${version}, endian mark ${endian.toString(16)}`);
    const bytes = Buffer.alloc(count * dimension * 4);
    readSync(fd, bytes, 0, bytes.length, vectorsOffset);
    const vectors = new Float32Array(bytes.buffer, bytes.byteOffset, count * dimension);
    const stat = statSync(path);
    return {
      kind: 'ga-index',
      count,
      dimension,
      vectors,
      details: {
        path: 'ga/state/voicings/optick.index',
        bytes: stat.size,
        modified: stat.mtime.toISOString(),
        version,
        headerSize,
        schemaHash: `0x${schemaHash.toString(16).padStart(8, '0').toUpperCase()}`,
        instruments,
        instrumentCounts: { guitar: ranges[0].count, bass: ranges[1].count, ukulele: ranges[2].count },
        vectorsSha256: createHash('sha256').update(bytes).digest('hex').slice(0, 16),
      },
    };
  } finally {
    closeSync(fd);
  }
}

function makeSynthetic(count: number, dimension = 124): Source {
  let seed = 20260916;
  const rand = () => {
    seed = (seed + 0x6d2b79f5) >>> 0;
    let t = seed;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  const gaussian = () => Math.sqrt(-2 * Math.log(1 - rand())) * Math.cos(2 * Math.PI * rand());
  const clusters = Array.from({ length: 16 }, () => Array.from({ length: dimension }, gaussian));
  const vectors = new Float32Array(count * dimension);
  for (let i = 0; i < count; i++) {
    const c = clusters[Math.floor(rand() * clusters.length)];
    let norm = 0;
    for (let d = 0; d < dimension; d++) {
      const v = c[d] + 0.6 * gaussian();
      vectors[i * dimension + d] = v;
      norm += v * v;
    }
    norm = Math.sqrt(norm);
    for (let d = 0; d < dimension; d++) vectors[i * dimension + d] /= norm;
  }
  return { kind: 'synthetic', count, dimension, vectors, details: { clusters: 16, seed: 20260916, note: 'a stand-in with the dimension of GA\'s index, not its data' } };
}

// Eigenvectors of a symmetric matrix by cyclic Jacobi rotations; returns them sorted by decreasing eigenvalue
function jacobi(matrix: Float64Array, n: number): { values: number[]; vectors: Float64Array[] } {
  const a = Float64Array.from(matrix);
  const v = new Float64Array(n * n);
  for (let i = 0; i < n; i++) v[i * n + i] = 1;
  for (let sweep = 0; sweep < 60; sweep++) {
    let off = 0;
    for (let p = 0; p < n; p++) for (let q = p + 1; q < n; q++) off += a[p * n + q] ** 2;
    if (off < 1e-18) break;
    for (let p = 0; p < n; p++) {
      for (let q = p + 1; q < n; q++) {
        const apq = a[p * n + q];
        if (Math.abs(apq) < 1e-15) continue;
        const theta = (a[q * n + q] - a[p * n + p]) / (2 * apq);
        const t = Math.sign(theta || 1) / (Math.abs(theta) + Math.sqrt(theta * theta + 1));
        const c = 1 / Math.sqrt(t * t + 1);
        const s = t * c;
        for (let k = 0; k < n; k++) {
          const akp = a[k * n + p];
          const akq = a[k * n + q];
          a[k * n + p] = c * akp - s * akq;
          a[k * n + q] = s * akp + c * akq;
        }
        for (let k = 0; k < n; k++) {
          const apk = a[p * n + k];
          const aqk = a[q * n + k];
          a[p * n + k] = c * apk - s * aqk;
          a[q * n + k] = s * apk + c * aqk;
        }
        for (let k = 0; k < n; k++) {
          const vkp = v[k * n + p];
          const vkq = v[k * n + q];
          v[k * n + p] = c * vkp - s * vkq;
          v[k * n + q] = s * vkp + c * vkq;
        }
      }
    }
  }
  const order = Array.from({ length: n }, (_, i) => i).sort((i, j) => a[j * n + j] - a[i * n + i]);
  return { values: order.map((i) => a[i * n + i]), vectors: order.map((i) => Float64Array.from({ length: n }, (_, k) => v[k * n + i])) };
}

const started = performance.now();
const source = synthetic ? makeSynthetic(Number(synthetic)) : existsSync(indexPath) ? readIndex(indexPath) : null;
if (!source) {
  console.error(`no index at ${indexPath}: pass --index <path>, or --synthetic <count> for the stand-in`);
  process.exit(1);
}
const { count, dimension: n, vectors } = source;
const stride = Math.max(1, Math.floor(count / 60_000));
const mean = new Float64Array(n);
let sampled = 0;
for (let i = 0; i < count; i += stride, sampled++) for (let d = 0; d < n; d++) mean[d] += vectors[i * n + d];
for (let d = 0; d < n; d++) mean[d] /= sampled;
const covariance = new Float64Array(n * n);
const row = new Float64Array(n);
for (let i = 0; i < count; i += stride) {
  for (let d = 0; d < n; d++) row[d] = vectors[i * n + d] - mean[d];
  for (let p = 0; p < n; p++) {
    const rp = row[p];
    for (let q = p; q < n; q++) covariance[p * n + q] += rp * row[q];
  }
}
for (let p = 0; p < n; p++) for (let q = p; q < n; q++) covariance[q * n + p] = covariance[p * n + q] /= sampled - 1;
const { values, vectors: components } = jacobi(covariance, n);
const total = values.reduce((sum, x) => sum + Math.max(0, x), 0);

const out = new Float32Array(count * 6);
for (let i = 0; i < count; i++) {
  for (let c = 0; c < 6; c++) {
    let dot = 0;
    const component = components[c];
    for (let d = 0; d < n; d++) dot += (vectors[i * n + d] - mean[d]) * component[d];
    out[i * 6 + c] = dot;
  }
}
// Scale each projection so that 99% of the coordinates fall within [-1, 1]
for (const first of [0, 3]) {
  const magnitudes = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) for (let c = 0; c < 3; c++) magnitudes[i * 3 + c] = Math.abs(out[i * 6 + first + c]);
  magnitudes.sort();
  const scale = 1 / (magnitudes[Math.floor(magnitudes.length * 0.99)] || 1);
  for (let i = 0; i < count; i++) for (let c = 0; c < 3; c++) out[i * 6 + first + c] *= scale;
}

const dir = join(lab, 'public', 'generated');
mkdirSync(dir, { recursive: true });
const header = new Uint32Array([count, source.kind === 'ga-index' ? 1 : 0]);
writeFileSync(join(dir, 'optick.bin'), Buffer.concat([Buffer.from(header.buffer), Buffer.from(out.buffer)]));
const explained = (from: number) => Math.round((values.slice(from, from + 3).reduce((a, b) => a + b, 0) / total) * 1000) / 10;
const info = {
  source: source.kind,
  count,
  dimension: n,
  ...source.details,
  pcaSample: sampled,
  varianceExplainedPercent: { projectionA: explained(0), projectionB: explained(3) },
  seconds: Math.round((performance.now() - started) / 100) / 10,
};
writeFileSync(join(dir, 'optick.json'), `${JSON.stringify(info, null, 2)}\n`);
console.log(JSON.stringify(info, null, 2));
