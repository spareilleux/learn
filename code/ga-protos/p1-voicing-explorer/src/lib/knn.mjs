// Exact k nearest neighbours by brute force, the baseline every vector index is measured against.
// GA's index vectors are stored so that a dot product is the weighted partition cosine: the larger, the closer.

// Keeps the k best (score, id) pairs, best first; ties go to the smaller id, so results are deterministic
class TopK {
  constructor(k) {
    this.k = k;
    this.ids = new Int32Array(k).fill(-1);
    this.scores = new Float64Array(k).fill(-Infinity);
  }
  offer(id, score) {
    const { k, ids, scores } = this;
    if (score < scores[k - 1] || (score === scores[k - 1] && (ids[k - 1] === -1 ? false : id > ids[k - 1]))) return;
    let i = k - 1;
    while (i > 0 && (score > scores[i - 1] || (score === scores[i - 1] && id < ids[i - 1]))) {
      scores[i] = scores[i - 1];
      ids[i] = ids[i - 1];
      i--;
    }
    scores[i] = score;
    ids[i] = id;
  }
}

// For each query row q (a position in rows), the k rows with the largest dot product, itself excluded
export function knnByDot(rows, dim, n, queries, k) {
  const ids = new Int32Array(queries.length * k);
  const scores = new Float32Array(queries.length * k);
  queries.forEach((q, qi) => {
    const top = new TopK(k);
    const qo = q * dim;
    for (let i = 0; i < n; i++) {
      if (i === q) continue;
      const o = i * dim;
      let s = 0;
      for (let j = 0; j < dim; j++) s += rows[qo + j] * rows[o + j];
      top.offer(i, s);
    }
    ids.set(top.ids, qi * k);
    scores.set(top.scores, qi * k);
  });
  return { ids, scores, k };
}

// The same by Euclidean distance (smaller is closer): the neighbours a projection shows on screen
export function knnByDistance(rows, dim, n, queries, k) {
  const ids = new Int32Array(queries.length * k);
  const scores = new Float32Array(queries.length * k);
  queries.forEach((q, qi) => {
    const top = new TopK(k);
    const qo = q * dim;
    for (let i = 0; i < n; i++) {
      if (i === q) continue;
      const o = i * dim;
      let d = 0;
      for (let j = 0; j < dim; j++) {
        const x = rows[qo + j] - rows[o + j];
        d += x * x;
      }
      top.offer(i, -d);
    }
    ids.set(top.ids, qi * k);
    for (let j = 0; j < k; j++) scores[qi * k + j] = Math.sqrt(-top.scores[j]);
  });
  return { ids, scores, k };
}

// Mean fraction of the true k neighbours found among the approximate k neighbours
export function recallAtK(truth, approx, k) {
  const queries = truth.length / k;
  let found = 0;
  for (let q = 0; q < queries; q++) {
    const set = new Set(truth.subarray(q * k, (q + 1) * k));
    for (let j = 0; j < k; j++) if (set.has(approx[q * k + j])) found++;
  }
  return found / (queries * k);
}
