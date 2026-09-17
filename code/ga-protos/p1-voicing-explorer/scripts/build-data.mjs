// Builds the explorer's data from GA's OPTIC-K index:
//   node scripts/build-data.mjs --index <optick.index> [--out public/data] [--sample 30000] [--seed 20260916]
//                               [--k 10] [--fit instrument|sample] [--ga-sha <sha>]
// Writes <out>/voicings.bin and <out>/manifest.json, and prints what it did.
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { buildData } from './pipeline.mjs';

const args = process.argv.slice(2);
const option = (name, fallback) => (args.includes(name) ? args[args.indexOf(name) + 1] : fallback);
const indexPath = option('--index');
if (!indexPath) {
  console.error('usage: node scripts/build-data.mjs --index <optick.index> [--out dir] [--sample n] [--seed s] [--k k] [--fit instrument|sample] [--ga-sha sha]');
  process.exit(1);
}
const out = option('--out', 'public/data');

const file = readFileSync(indexPath);
const sha256 = createHash('sha256').update(file).digest('hex');
const arrayBuffer = file.buffer.slice(file.byteOffset, file.byteOffset + file.byteLength);
const { bytes, manifest, timings } = buildData(arrayBuffer, {
  sample: Number(option('--sample', 30000)),
  seed: Number(option('--seed', 20260916)),
  k: Number(option('--k', 10)),
  fit: option('--fit', 'instrument'),
  log: (line) => console.log(line),
});
manifest.source = {
  repository: 'https://github.com/GuitarAlchemist/ga',
  commit: option('--ga-sha', 'unknown'),
  indexBytes: file.length,
  indexSha256: sha256,
};

mkdirSync(out, { recursive: true });
writeFileSync(join(out, 'voicings.bin'), bytes);
writeFileSync(join(out, 'manifest.json'), JSON.stringify(manifest, null, 1) + '\n');
console.log(`checks: ${JSON.stringify(manifest.checks)}`);
console.log(`PCA explained variance, first 3 components: ${manifest.pca.explained.slice(0, 3).map((x) => (100 * x).toFixed(1) + ' %').join(', ')}`);
console.log(`wrote ${join(out, 'voicings.bin')} (${bytes.length} bytes) and manifest.json (${manifest.names.length} chord names)`);
console.log(`timings: ${Object.entries(timings).map(([k, v]) => `${k} ${Math.round(v)}`).join(', ')}`);
