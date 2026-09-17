import assert from 'node:assert/strict';
import { test } from 'node:test';
import { fitPca, jacobiEigen, project } from '../src/lib/pca.mjs';
import { mulberry32 } from '../src/lib/sample.mjs';

// A cloud stretched along one direction, with a little noise
function cloud(n, dim, seed) {
  const random = mulberry32(seed);
  const rows = new Float32Array(n * dim);
  for (let i = 0; i < n; i++) {
    const t = random() * 2 - 1;
    for (let j = 0; j < dim; j++) rows[i * dim + j] = t * (dim - j) + 0.1 * (random() - 0.5);
  }
  return rows;
}

test('Jacobi finds the eigenvalues of a known symmetric matrix', () => {
  // [[2,1],[1,2]] has eigenvalues 3 and 1, with eigenvectors (1,1)/sqrt2 and (1,-1)/sqrt2
  const { values, vectors } = jacobiEigen([2, 1, 1, 2], 2);
  assert.ok(Math.abs(values[0] - 3) < 1e-12 && Math.abs(values[1] - 1) < 1e-12);
  assert.ok(Math.abs(vectors[0] - Math.SQRT1_2) < 1e-12 && Math.abs(vectors[1] - Math.SQRT1_2) < 1e-12);
});

test('PCA is deterministic: two fits give the same bits', () => {
  const rows = cloud(500, 12, 3);
  const a = fitPca(rows, 12, null);
  const b = fitPca(Float32Array.from(rows), 12, null);
  assert.deepEqual(Array.from(a.vectors), Array.from(b.vectors));
  assert.deepEqual(Array.from(a.values), Array.from(b.values));
  const all = Uint32Array.from({ length: 500 }, (_, i) => i);
  assert.deepEqual(project(a, rows, all, 3), project(b, rows, all, 3));
});

test('PCA finds the one direction a nearly one-dimensional cloud varies along', () => {
  const pca = fitPca(cloud(1000, 8, 5), 8, null);
  assert.ok(pca.explained[0] > 0.99, `explained ${pca.explained[0]}`);
  assert.ok(Math.abs(pca.explained.reduce((s, x) => s + x, 0) - 1) < 1e-9);
  // Each eigenvector's largest component is positive, so its sign never flips between runs
  for (let c = 0; c < 8; c++) {
    const row = Array.from(pca.vectors.subarray(c * 8, c * 8 + 8));
    const big = row.reduce((m, x, i) => (Math.abs(x) > Math.abs(row[m]) ? i : m), 0);
    assert.ok(row[big] > 0);
  }
});

test('the components are orthonormal', () => {
  const pca = fitPca(cloud(300, 6, 9), 6, null);
  for (let a = 0; a < 6; a++)
    for (let b = 0; b < 6; b++) {
      let dot = 0;
      for (let j = 0; j < 6; j++) dot += pca.vectors[a * 6 + j] * pca.vectors[b * 6 + j];
      assert.ok(Math.abs(dot - (a === b ? 1 : 0)) < 1e-9, `${a}.${b} = ${dot}`);
    }
});
