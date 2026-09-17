import assert from 'node:assert/strict';
import { test } from 'node:test';
import { makeFixture } from '../scripts/fixture.mjs';
import { buildData } from '../scripts/pipeline.mjs';
import { decode } from '../src/lib/format.mjs';
import { knnByDot } from '../src/lib/knn.mjs';

test('the build step on the fixture: same bytes twice, consistent sections', () => {
  const a = buildData(makeFixture(), { sample: 100, seed: 3, k: 5 });
  const b = buildData(makeFixture(), { sample: 100, seed: 3, k: 5 });
  assert.deepEqual(a.bytes, b.bytes);
  assert.deepEqual(a.manifest.checks, { midiMismatches: 0, stringCountMismatches: 0 });

  const data = decode(a.bytes.buffer);
  assert.equal(data.count, 100);
  assert.equal(data.k, 5);
  for (const x of data.positions) assert.ok(Math.abs(x) <= 1);
  // The stored neighbours are the exact ones in the index's 124 dimensions
  const vectors = new Float32Array(100 * 124);
  data.indexRow.forEach((r, i) => vectors.set(a.index.vector(r), i * 124));
  const truth = knnByDot(vectors, 124, 100, [0, 42, 99], 5);
  [0, 42, 99].forEach((q, qi) => assert.deepEqual(Array.from(data.neighbours.subarray(q * 5, q * 5 + 5)), Array.from(truth.ids.subarray(qi * 5, qi * 5 + 5))));
  // Only guitar rows
  assert.ok(data.indexRow.every((r) => r < a.manifest.instrumentTotal));
});

test('a different seed picks a different sample', () => {
  const a = buildData(makeFixture(), { sample: 50, seed: 1, k: 3 });
  const b = buildData(makeFixture(), { sample: 50, seed: 2, k: 3 });
  assert.notDeepEqual(Array.from(decode(a.bytes.buffer).indexRow), Array.from(decode(b.bytes.buffer).indexRow));
});
