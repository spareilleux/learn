import assert from 'node:assert/strict';
import { test } from 'node:test';
import { knnByDistance, knnByDot, recallAtK } from '../src/lib/knn.mjs';
import { mulberry32, sampleIndices } from '../src/lib/sample.mjs';

function rows(n, dim, seed) {
  const random = mulberry32(seed);
  return Float32Array.from({ length: n * dim }, () => random() - 0.5);
}

// The obvious implementation: score everything, sort, take k
function naive(data, dim, n, q, k, score) {
  const query = data.subarray(q * dim, (q + 1) * dim);
  return Array.from({ length: n }, (_, i) => i)
    .filter((i) => i !== q)
    .map((i) => [i, score(query, data.subarray(i * dim, (i + 1) * dim))])
    .sort((a, b) => b[1] - a[1] || a[0] - b[0])
    .slice(0, k)
    .map(([i]) => i);
}

// Same float32 accumulation order as knn.mjs, so equal scores compare equal
const dot = (a, b) => {
  let s = 0;
  for (let j = 0; j < a.length; j++) s += a[j] * b[j];
  return s;
};
const negDist = (a, b) => {
  let s = 0;
  for (let j = 0; j < a.length; j++) s += (a[j] - b[j]) ** 2;
  return -s;
};

test('knnByDot returns the same neighbours as sorting every dot product', () => {
  const dim = 16, n = 400, k = 10;
  const data = rows(n, dim, 11);
  const queries = [0, 17, 199, 399];
  const { ids } = knnByDot(data, dim, n, queries, k);
  queries.forEach((q, qi) => assert.deepEqual(Array.from(ids.subarray(qi * k, (qi + 1) * k)), naive(data, dim, n, q, k, dot)));
});

test('knnByDistance returns the same neighbours as sorting every distance', () => {
  const dim = 3, n = 300, k = 10;
  const data = rows(n, dim, 12);
  const { ids } = knnByDistance(data, dim, n, [5, 250], k);
  [5, 250].forEach((q, qi) => assert.deepEqual(Array.from(ids.subarray(qi * k, (qi + 1) * k)), naive(data, dim, n, q, k, negDist)));
});

test('ties go to the smaller row number', () => {
  const data = new Float32Array([1, 0, 1, 0, 1, 0, 1, 0]); // four identical vectors
  const { ids } = knnByDot(data, 2, 4, [2], 2);
  assert.deepEqual(Array.from(ids), [0, 1]);
});

test('recall@k counts the shared neighbours', () => {
  const truth = Int32Array.from([1, 2, 3, 4, 5, 6]);
  assert.equal(recallAtK(truth, Int32Array.from([3, 2, 9, 6, 7, 8]), 3), 3 / 6);
});

test('the sample is deterministic, distinct and sorted', () => {
  const a = sampleIndices(10000, 500, 42);
  assert.deepEqual(a, sampleIndices(10000, 500, 42));
  assert.notDeepEqual(a, sampleIndices(10000, 500, 43));
  assert.equal(new Set(a).size, 500);
  assert.ok(a.every((x, i) => i === 0 || x > a[i - 1]));
});

test('seed 20260916 picks the same rows of the 297,910 guitar voicings everywhere', () => {
  const rowsPicked = sampleIndices(297910, 30000, 20260916);
  assert.deepEqual(Array.from(rowsPicked.subarray(0, 5)), [4, 10, 42, 47, 52]);
});
