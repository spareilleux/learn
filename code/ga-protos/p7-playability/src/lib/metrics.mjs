// How a predictor is scored against the target: rank agreement, absolute error after an affine calibration,
// pairwise accuracy ("which of these two is harder?"), and bootstrap confidence intervals resampled by chord,
// because voicings of the same chord are not independent draws.

import { mulberry32 } from './random.mjs';

// Ranks with ties averaged
export function ranks(values) {
  const order = values.map((v, i) => i).sort((a, b) => values[a] - values[b]);
  const r = new Float64Array(values.length);
  let i = 0;
  while (i < order.length) {
    let j = i;
    while (j + 1 < order.length && values[order[j + 1]] === values[order[i]]) j++;
    const mean = (i + j) / 2 + 1;
    for (let k = i; k <= j; k++) r[order[k]] = mean;
    i = j + 1;
  }
  return r;
}

export function pearson(a, b) {
  const n = a.length;
  let sa = 0;
  let sb = 0;
  for (let i = 0; i < n; i++) {
    sa += a[i];
    sb += b[i];
  }
  const ma = sa / n;
  const mb = sb / n;
  let num = 0;
  let da = 0;
  let db = 0;
  for (let i = 0; i < n; i++) {
    const x = a[i] - ma;
    const y = b[i] - mb;
    num += x * y;
    da += x * x;
    db += y * y;
  }
  return da === 0 || db === 0 ? 0 : num / Math.sqrt(da * db);
}

export function spearman(a, b) {
  return pearson(ranks(a), ranks(b));
}

// Kendall tau-b in O(n log n): sort by x, count inversions in y by merge sort, correct for ties.
export function kendallTauB(x, y) {
  const n = x.length;
  if (n < 2) return 0;
  const idx = Array.from({ length: n }, (_, i) => i).sort((i, j) => x[i] - x[j] || y[i] - y[j]);
  const xs = idx.map((i) => x[i]);
  const ys = idx.map((i) => y[i]);

  const tieGroups = (v) => {
    let total = 0;
    let i = 0;
    while (i < v.length) {
      let j = i;
      while (j + 1 < v.length && v[j + 1] === v[i]) j++;
      const t = j - i + 1;
      total += (t * (t - 1)) / 2;
      i = j + 1;
    }
    return total;
  };

  const n0 = (n * (n - 1)) / 2;
  const n1 = tieGroups(xs);
  const sortedY = [...ys].sort((p, q) => p - q);
  const n2 = tieGroups(sortedY);

  // joint ties: pairs equal in both
  let n3 = 0;
  let i = 0;
  while (i < n) {
    let j = i;
    while (j + 1 < n && xs[j + 1] === xs[i] && ys[j + 1] === ys[i]) j++;
    const t = j - i + 1;
    n3 += (t * (t - 1)) / 2;
    i = j + 1;
  }

  // inversions in ys
  let swaps = 0;
  const buffer = new Float64Array(n);
  const work = Float64Array.from(ys);
  const mergeSort = (lo, hi) => {
    if (hi - lo < 2) return;
    const mid = (lo + hi) >> 1;
    mergeSort(lo, mid);
    mergeSort(mid, hi);
    let p = lo;
    let q = mid;
    let k = lo;
    while (p < mid && q < hi) {
      if (work[p] <= work[q]) buffer[k++] = work[p++];
      else {
        swaps += mid - p;
        buffer[k++] = work[q++];
      }
    }
    while (p < mid) buffer[k++] = work[p++];
    while (q < hi) buffer[k++] = work[q++];
    for (let t = lo; t < hi; t++) work[t] = buffer[t];
  };
  mergeSort(0, n);

  const num = n0 - n1 - n2 + n3 - 2 * swaps;
  const den = Math.sqrt((n0 - n1) * (n0 - n2));
  return den === 0 ? 0 : num / den;
}

// A predictor on its own scale is compared by rank; to compare absolute error it is first rescaled by least
// squares on the training rows, and the same a and b are then applied to the test rows.
export function affineFit(pred, target) {
  const n = pred.length;
  let sx = 0;
  let sy = 0;
  let sxx = 0;
  let sxy = 0;
  for (let i = 0; i < n; i++) {
    sx += pred[i];
    sy += target[i];
    sxx += pred[i] * pred[i];
    sxy += pred[i] * target[i];
  }
  const den = n * sxx - sx * sx;
  const a = den === 0 ? 0 : (n * sxy - sx * sy) / den;
  const b = (sy - a * sx) / n;
  return { a, b };
}

export function mae(pred, target) {
  let s = 0;
  for (let i = 0; i < pred.length; i++) s += Math.abs(pred[i] - target[i]);
  return s / pred.length;
}

/**
 * "Which of these two is harder?" over pairs drawn from different chords, so that the question is never
 * about two fingerings of the same grip. Pairs whose target difference is below `eps` are skipped; a tie in the
 * prediction counts as half a point.
 */
export function pairwiseAccuracy(pred, target, groups, { pairs = 20000, seed = 7, eps = 1e-9 } = {}) {
  const rng = mulberry32(seed);
  const n = pred.length;
  let used = 0;
  let score = 0;
  let attempts = 0;
  while (used < pairs && attempts < pairs * 50) {
    attempts++;
    const i = Math.floor(rng() * n);
    const j = Math.floor(rng() * n);
    if (i === j || groups[i] === groups[j]) continue;
    const dt = target[i] - target[j];
    if (Math.abs(dt) <= eps) continue;
    const dp = pred[i] - pred[j];
    used++;
    if (Math.abs(dp) <= eps) score += 0.5;
    else if (Math.sign(dp) === Math.sign(dt)) score += 1;
  }
  return { accuracy: used ? score / used : 0, pairs: used };
}

// The share of within-chord pairs a predictor cannot tell apart at all
export function tieRate(pred, groups, { pairs = 20000, seed = 11, eps = 1e-9, sameGroup = true } = {}) {
  const rng = mulberry32(seed);
  const n = pred.length;
  let used = 0;
  let ties = 0;
  let attempts = 0;
  while (used < pairs && attempts < pairs * 200) {
    attempts++;
    const i = Math.floor(rng() * n);
    const j = Math.floor(rng() * n);
    if (i === j) continue;
    if (sameGroup ? groups[i] !== groups[j] : groups[i] === groups[j]) continue;
    used++;
    if (Math.abs(pred[i] - pred[j]) <= eps) ties++;
  }
  return { rate: used ? ties / used : 0, pairs: used };
}

/**
 * Percentile bootstrap, resampling whole chords rather than voicings: within a chord, voicings share a shape
 * and a pitch-class set, so treating them as independent draws would make every interval look too narrow.
 */
export function bootstrapCI(metric, groups, { rounds = 200, seed = 23, alpha = 0.05 } = {}) {
  const byGroup = new Map();
  groups.forEach((g, i) => {
    if (!byGroup.has(g)) byGroup.set(g, []);
    byGroup.get(g).push(i);
  });
  const keys = [...byGroup.keys()];
  const rng = mulberry32(seed);
  const values = [];
  for (let r = 0; r < rounds; r++) {
    const rows = [];
    for (let k = 0; k < keys.length; k++) rows.push(...byGroup.get(keys[Math.floor(rng() * keys.length)]));
    values.push(metric(rows));
  }
  values.sort((a, b) => a - b);
  const lo = values[Math.max(0, Math.floor((alpha / 2) * rounds))];
  const hi = values[Math.min(rounds - 1, Math.ceil((1 - alpha / 2) * rounds) - 1)];
  return { lo, hi, rounds };
}

export const round = (x, digits = 4) => Number.parseFloat(x.toFixed(digits));
