import test from 'node:test';
import assert from 'node:assert/strict';
import { mulberry32 } from '../src/lib/random.mjs';
import { fitRidge, fitMean, fitSingleFeature } from '../src/lib/linear.mjs';
import { buildBins, binOf, fitRandomForest, fitGradientBoosting } from '../src/lib/trees.mjs';
import { fitMlp } from '../src/lib/mlp.mjs';
import { spearman, kendallTauB, ranks, pairwiseAccuracy, bootstrapCI, mae, affineFit } from '../src/lib/metrics.mjs';
import { splitRows } from '../src/lib/split.mjs';

function sample(n, f, seed = 5) {
  const rng = mulberry32(seed);
  const X = [];
  const y = [];
  for (let i = 0; i < n; i++) {
    const row = [rng() * 4 - 2, rng() * 4 - 2, rng() * 4 - 2];
    X.push(row);
    y.push(f(row));
  }
  return { X, y };
}

test('ridge recovers a linear rule', () => {
  const { X, y } = sample(400, ([a, b, c]) => 3 * a - 2 * b + 0.5 * c + 1);
  const model = fitRidge(X, y, 0.001);
  assert.ok(Math.abs(model.predict([1, 0, 0]) - 4) < 0.05);
  assert.ok(Math.abs(model.predict([0, 1, 0]) + 1) < 0.05);
  assert.ok(model.size() > 0);
});

test('the trivial baselines are what they claim to be', () => {
  const { X, y } = sample(100, ([a]) => a);
  const m = fitMean(X, y);
  assert.equal(m.predict([9, 9, 9]), m.predict([0, 0, 0]));
  const s = fitSingleFeature(X, y, 0);
  assert.ok(Math.abs(s.a - 1) < 0.05);
});

test('binning keeps the order of the values', () => {
  const X = Array.from({ length: 200 }, (_, i) => [i, 200 - i]);
  const bins = buildBins(X, 16);
  assert.ok(binOf(0, bins.thresholds[0]) <= binOf(100, bins.thresholds[0]));
  assert.ok(binOf(100, bins.thresholds[0]) <= binOf(199, bins.thresholds[0]));
});

test('the ensembles fit an interaction that a line cannot', () => {
  const f = ([a, b]) => (a > 0 && b > 0 ? 5 : 0) + 0.1 * a;
  const { X, y } = sample(1200, f);
  const test = sample(400, f, 77);
  const ridge = fitRidge(X, y, 1);
  const forest = fitRandomForest(X, y, { trees: 12, maxDepth: 8, minLeaf: 5, mtry: 3, seed: 1 });
  const boost = fitGradientBoosting(X, y, { rounds: 60, maxDepth: 3, minLeaf: 10, learningRate: 0.15, seed: 2 });
  const rho = (m) => spearman(test.X.map((row) => m.predict(row)), test.y);
  assert.ok(rho(forest) > rho(ridge));
  assert.ok(rho(boost) > rho(ridge));
  assert.ok(boost.size() > 0 && forest.size() > 0);
});

test('the same seed gives the same ensemble', () => {
  const { X, y } = sample(300, ([a, b]) => a * b);
  const a = fitGradientBoosting(X, y, { rounds: 20, seed: 42 });
  const b = fitGradientBoosting(X, y, { rounds: 20, seed: 42 });
  assert.equal(a.predict([1, 1, 1]), b.predict([1, 1, 1]));
});

test('a small MLP learns a smooth non-linear rule', () => {
  const f = ([a, b]) => Math.sin(a) + b * b;
  const { X, y } = sample(1500, f);
  const held = sample(300, f, 91);
  const model = fitMlp(X, y, { hidden: 16, epochs: 40, batch: 64, seed: 3 });
  assert.ok(spearman(held.X.map((row) => model.predict(row)), held.y) > 0.9);
});

test('the rank statistics agree with their definitions', () => {
  assert.deepEqual([...ranks([10, 20, 20, 30])], [1, 2.5, 2.5, 4]);
  assert.ok(Math.abs(spearman([1, 2, 3, 4], [10, 20, 30, 40]) - 1) < 1e-12);
  assert.ok(Math.abs(spearman([1, 2, 3, 4], [40, 30, 20, 10]) + 1) < 1e-12);
  assert.ok(Math.abs(kendallTauB([1, 2, 3, 4], [1, 2, 3, 4]) - 1) < 1e-12);
  assert.ok(Math.abs(kendallTauB([1, 2, 3, 4], [4, 3, 2, 1]) + 1) < 1e-12);
  // One swapped pair out of six: tau = (5 - 1) / 6
  assert.ok(Math.abs(kendallTauB([1, 2, 3, 4], [1, 2, 4, 3]) - 4 / 6) < 1e-12);
  const { a, b } = affineFit([0, 1, 2], [1, 3, 5]);
  assert.ok(Math.abs(a - 2) < 1e-9 && Math.abs(b - 1) < 1e-9);
  assert.equal(mae([1, 2], [1, 4]), 1);
});

test('pairwise accuracy only draws pairs from different chords', () => {
  const pred = [1, 2, 3, 4];
  const target = [1, 2, 3, 4];
  const groups = ['a', 'a', 'b', 'b'];
  const r = pairwiseAccuracy(pred, target, groups, { pairs: 200, seed: 3 });
  assert.equal(r.accuracy, 1);
  const reversed = pairwiseAccuracy([4, 3, 2, 1], target, groups, { pairs: 200, seed: 3 });
  assert.equal(reversed.accuracy, 0);
});

test('the bootstrap resamples chords, not voicings', () => {
  const groups = Array.from({ length: 60 }, (_, i) => `g${i % 6}`);
  const ci = bootstrapCI(() => 0.5, groups, { rounds: 20 });
  assert.equal(ci.lo, 0.5);
  assert.equal(ci.hi, 0.5);
});

test('a split by chord never puts one chord on two sides', () => {
  const rows = Array.from({ length: 500 }, (_, i) => ({ c: `chord${i % 40}`, s: `shape${i % 57}` }));
  for (const mode of ['chord', 'shape']) {
    const s = splitRows(rows, mode);
    const key = mode === 'chord' ? 'c' : 's';
    assert.equal(s.groupCount, new Set(rows.map((r) => r[key])).size);
    assert.ok(s.train.length > 0 && s.test.length > 0);
    const sideOf = new Map();
    for (const side of ['train', 'val', 'test'])
      for (const i of s[side]) {
        const k = rows[i][key];
        if (sideOf.has(k)) assert.equal(sideOf.get(k), side);
        else sideOf.set(k, side);
      }
    assert.equal(s.train.length + s.val.length + s.test.length, rows.length);
  }
  const naive = splitRows(rows, 'voicing');
  assert.equal(naive.groupCount, rows.length);
});

test('keys that differ only in their last characters still land on all three sides', () => {
  // The first version of hash32 had no finalizer: the high bits barely moved between "chord0" and "chord39",
  // and every chord went to the training side.
  const rows = Array.from({ length: 3000 }, (_, i) => ({ c: `chord${i}`, s: `shape${i}` }));
  const s = splitRows(rows, 'chord');
  assert.ok(Math.abs(s.train.length / rows.length - 0.6) < 0.03, `train ${s.train.length}`);
  assert.ok(Math.abs(s.val.length / rows.length - 0.2) < 0.03, `val ${s.val.length}`);
  assert.ok(Math.abs(s.test.length / rows.length - 0.2) < 0.03, `test ${s.test.length}`);
});
