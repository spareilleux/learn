// Checks that a small index regenerated with GA's own CLI agrees with the big one, voicing by voicing:
//   node scripts/compare-indexes.mjs <small optick.index> <big optick.index>
// Each voicing of the small index is looked up by instrument and diagram in the big one, and its vector compared.
// Dedup keeps the cheapest voicing of each (shape, pitch classes) group, so a partial export keeps other representatives:
// vectorFound counts the small index's vectors that exist, bit for bit, anywhere in the big one.
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { openIndex } from '../src/lib/optick.mjs';

const open = (path) => {
  const f = readFileSync(path);
  return openIndex(f.buffer.slice(f.byteOffset, f.byteOffset + f.byteLength));
};
const [small, big] = process.argv.slice(2).map(open);
const byDiagram = new Map();
for (let i = 0; i < big.count; i++) {
  const m = big.metadata(i);
  byDiagram.set(`${m.instrument} ${m.diagram}`, i);
}
const hash = (v) => createHash('sha1').update(new Uint8Array(v.buffer, v.byteOffset, v.byteLength)).digest('base64');
const bigVectors = new Set();
for (let i = 0; i < big.count; i++) bigVectors.add(hash(big.vector(i)));
let vectorFound = 0;
for (let i = 0; i < small.count; i++) if (bigVectors.has(hash(small.vector(i)))) vectorFound++;
let identical = 0, differ = 0, missing = 0, sameName = 0;
let maxAbs = 0;
for (let i = 0; i < small.count; i++) {
  const m = small.metadata(i);
  const j = byDiagram.get(`${m.instrument} ${m.diagram}`);
  if (j === undefined) {
    missing++;
    continue;
  }
  const a = small.vector(i), b = big.vector(j);
  let same = true;
  for (let d = 0; d < a.length; d++) {
    const diff = Math.abs(a[d] - b[d]);
    if (diff > 0) same = false;
    maxAbs = Math.max(maxAbs, diff);
  }
  same ? identical++ : differ++;
  if (big.metadata(j).quality === m.quality) sameName++;
}
console.log(JSON.stringify({ small: small.count, big: big.count, identical, differ, missing, vectorFound, sameName, maxAbsDifference: maxAbs }));
