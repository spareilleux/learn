// Regression trees on binned features, and the two ensembles built on them: a random forest and gradient
// boosting with squared error. Binning the features once (at most 64 quantile bins per column) turns every
// split search into one pass of additions per feature, which is what makes this cheap enough for a CPU.

import { mulberry32 } from './random.mjs';

export function buildBins(X, maxBins = 64) {
  const n = X.length;
  const d = X[0].length;
  const thresholds = [];
  const binned = Array.from({ length: d }, () => new Uint8Array(n));
  for (let j = 0; j < d; j++) {
    const column = new Float64Array(n);
    for (let i = 0; i < n; i++) column[i] = X[i][j];
    const sorted = Float64Array.from(column).sort();
    const cuts = [];
    for (let b = 1; b < maxBins; b++) {
      const v = sorted[Math.floor((b / maxBins) * n)];
      if (cuts.length === 0 || v > cuts[cuts.length - 1]) cuts.push(v);
    }
    thresholds.push(cuts);
    for (let i = 0; i < n; i++) {
      let lo = 0;
      let hi = cuts.length;
      while (lo < hi) {
        const mid = (lo + hi) >> 1;
        if (column[i] < cuts[mid]) hi = mid;
        else lo = mid + 1;
      }
      binned[j][i] = lo;
    }
  }
  return { thresholds, binned, nBins: maxBins };
}

export function binOf(value, cuts) {
  let lo = 0;
  let hi = cuts.length;
  while (lo < hi) {
    const mid = (lo + hi) >> 1;
    if (value < cuts[mid]) hi = mid;
    else lo = mid + 1;
  }
  return lo;
}

function growTree(bins, y, rows, { maxDepth, minLeaf, mtry, rng, minGain = 1e-9 }) {
  const d = bins.binned.length;
  const nBins = bins.nBins;
  const counts = new Float64Array(nBins);
  const sums = new Float64Array(nBins);
  const featureOrder = Array.from({ length: d }, (_, j) => j);

  let nodeCount = 0;
  const build = (nodeRows, depth) => {
    nodeCount++;
    let sum = 0;
    for (const i of nodeRows) sum += y[i];
    const value = sum / nodeRows.length;
    if (depth >= maxDepth || nodeRows.length < 2 * minLeaf) return { value };

    const parentSse = sum * sum / nodeRows.length;
    let best = null;
    // Sample the features to try at this node (all of them when mtry is the full width)
    for (let k = d - 1; k > 0; k--) {
      const j = Math.floor(rng() * (k + 1));
      [featureOrder[k], featureOrder[j]] = [featureOrder[j], featureOrder[k]];
    }
    for (let t = 0; t < mtry; t++) {
      const j = featureOrder[t];
      counts.fill(0);
      sums.fill(0);
      const column = bins.binned[j];
      for (const i of nodeRows) {
        const b = column[i];
        counts[b]++;
        sums[b] += y[i];
      }
      let leftCount = 0;
      let leftSum = 0;
      for (let b = 0; b < nBins - 1; b++) {
        leftCount += counts[b];
        leftSum += sums[b];
        const rightCount = nodeRows.length - leftCount;
        if (leftCount < minLeaf || rightCount < minLeaf) continue;
        const rightSum = sum - leftSum;
        const gain = (leftSum * leftSum) / leftCount + (rightSum * rightSum) / rightCount - parentSse;
        if (!best || gain > best.gain) best = { gain, feature: j, bin: b };
      }
    }
    if (!best || best.gain <= minGain) return { value };

    const left = [];
    const right = [];
    const column = bins.binned[best.feature];
    for (const i of nodeRows) (column[i] <= best.bin ? left : right).push(i);
    if (!left.length || !right.length) return { value };
    return {
      feature: best.feature,
      threshold: bins.thresholds[best.feature][best.bin],
      gain: best.gain,
      left: build(left, depth + 1),
      right: build(right, depth + 1),
    };
  };

  const root = build(rows, 0);
  return { root, nodeCount };
}

function predictTree(node, row) {
  let n = node;
  while (n.feature !== undefined) n = row[n.feature] < n.threshold ? n.left : n.right;
  return n.value;
}

function accumulateImportance(node, into) {
  if (node.feature === undefined) return;
  into[node.feature] = (into[node.feature] ?? 0) + node.gain;
  accumulateImportance(node.left, into);
  accumulateImportance(node.right, into);
}

export function fitRandomForest(X, y, { trees = 60, maxDepth = 12, minLeaf = 5, mtry = 7, seed = 101, bins = null } = {}) {
  const b = bins ?? buildBins(X);
  const rng = mulberry32(seed);
  const n = X.length;
  const built = [];
  let nodes = 0;
  for (let t = 0; t < trees; t++) {
    const rows = new Array(n);
    for (let i = 0; i < n; i++) rows[i] = Math.floor(rng() * n);
    const tree = growTree(b, y, rows, { maxDepth, minLeaf, mtry: Math.min(mtry, X[0].length), rng });
    built.push(tree.root);
    nodes += tree.nodeCount;
  }
  const importance = {};
  for (const root of built) accumulateImportance(root, importance);
  return {
    kind: 'forest',
    trees: built,
    nodes,
    importance,
    predict(row) {
      let s = 0;
      for (const root of built) s += predictTree(root, row);
      return s / built.length;
    },
    size: () => JSON.stringify(built).length,
  };
}

export function fitGradientBoosting(
  X,
  y,
  { rounds = 300, learningRate = 0.08, maxDepth = 5, minLeaf = 20, seed = 202, bins = null, subsample = 1 } = {},
) {
  const b = bins ?? buildBins(X);
  const rng = mulberry32(seed);
  const n = X.length;
  let base = 0;
  for (const v of y) base += v;
  base /= n;
  const residual = new Float64Array(n);
  for (let i = 0; i < n; i++) residual[i] = y[i] - base;
  const current = new Float64Array(n).fill(base);
  const built = [];
  let nodes = 0;
  const allRows = Array.from({ length: n }, (_, i) => i);

  for (let r = 0; r < rounds; r++) {
    const rows =
      subsample >= 1 ? allRows : allRows.filter(() => rng() < subsample);
    const tree = growTree(b, residual, rows.length ? rows : allRows, {
      maxDepth,
      minLeaf,
      mtry: X[0].length,
      rng,
    });
    built.push(tree.root);
    nodes += tree.nodeCount;
    for (let i = 0; i < n; i++) {
      current[i] += learningRate * predictTree(tree.root, X[i]);
      residual[i] = y[i] - current[i];
    }
  }
  const importance = {};
  for (const root of built) accumulateImportance(root, importance);
  return {
    kind: 'boosting',
    base,
    trees: built,
    nodes,
    importance,
    learningRate,
    predict(row) {
      let s = base;
      for (const root of built) s += learningRate * predictTree(root, row);
      return s;
    },
    size: () => JSON.stringify({ base, learningRate, trees: built }).length,
  };
}
