// Principal component analysis with no dependency: the covariance matrix in float64, diagonalized by cyclic Jacobi
// rotations (the method of the machine-learning-ix course, lesson 5). Deterministic: same input, same bits out,
// because the loops run in a fixed order and each eigenvector's sign is fixed (its largest component is positive).

// rows: Float32Array of n x dim, read at the given row indices (all rows when indices is null)
export function covariance(rows, dim, indices) {
  const n = indices ? indices.length : rows.length / dim;
  const mean = new Float64Array(dim);
  const at = (k) => (indices ? indices[k] : k) * dim;
  for (let k = 0; k < n; k++) {
    const o = at(k);
    for (let j = 0; j < dim; j++) mean[j] += rows[o + j];
  }
  for (let j = 0; j < dim; j++) mean[j] /= n;
  const cov = new Float64Array(dim * dim);
  const centered = new Float64Array(dim);
  for (let k = 0; k < n; k++) {
    const o = at(k);
    for (let j = 0; j < dim; j++) centered[j] = rows[o + j] - mean[j];
    for (let a = 0; a < dim; a++) {
      const ca = centered[a];
      if (ca === 0) continue;
      const base = a * dim;
      for (let b = a; b < dim; b++) cov[base + b] += ca * centered[b];
    }
  }
  for (let a = 0; a < dim; a++)
    for (let b = a; b < dim; b++) {
      cov[a * dim + b] /= n - 1;
      cov[b * dim + a] = cov[a * dim + b];
    }
  return { mean, cov, n };
}

// Eigen-decomposition of a symmetric matrix. Returns eigenvalues in decreasing order and the matching unit eigenvectors
// as rows of a dim x dim Float64Array.
export function jacobiEigen(matrix, dim, { maxSweeps = 100, tolerance = 1e-12 } = {}) {
  const a = Float64Array.from(matrix);
  const v = new Float64Array(dim * dim);
  for (let i = 0; i < dim; i++) v[i * dim + i] = 1;
  let sweeps = 0;
  for (; sweeps < maxSweeps; sweeps++) {
    let off = 0;
    let diag = 0;
    for (let p = 0; p < dim; p++) {
      diag += a[p * dim + p] ** 2;
      for (let q = p + 1; q < dim; q++) off += a[p * dim + q] ** 2;
    }
    if (off <= tolerance * tolerance * Math.max(diag, 1e-300)) break;
    for (let p = 0; p < dim - 1; p++)
      for (let q = p + 1; q < dim; q++) {
        const apq = a[p * dim + q];
        if (Math.abs(apq) < 1e-300) continue;
        const app = a[p * dim + p];
        const aqq = a[q * dim + q];
        const theta = (aqq - app) / (2 * apq);
        const t = Math.sign(theta || 1) / (Math.abs(theta) + Math.sqrt(theta * theta + 1));
        const c = 1 / Math.sqrt(t * t + 1);
        const s = t * c;
        for (let k = 0; k < dim; k++) {
          const akp = a[k * dim + p];
          const akq = a[k * dim + q];
          a[k * dim + p] = c * akp - s * akq;
          a[k * dim + q] = s * akp + c * akq;
        }
        for (let k = 0; k < dim; k++) {
          const apk = a[p * dim + k];
          const aqk = a[q * dim + k];
          a[p * dim + k] = c * apk - s * aqk;
          a[q * dim + k] = s * apk + c * aqk;
        }
        for (let k = 0; k < dim; k++) {
          const vkp = v[k * dim + p];
          const vkq = v[k * dim + q];
          v[k * dim + p] = c * vkp - s * vkq;
          v[k * dim + q] = s * vkp + c * vkq;
        }
      }
  }
  const order = Array.from({ length: dim }, (_, i) => i).sort((x, y) => a[y * dim + y] - a[x * dim + x] || x - y);
  const values = new Float64Array(dim);
  const vectors = new Float64Array(dim * dim);
  order.forEach((col, r) => {
    values[r] = a[col * dim + col];
    let big = 0;
    for (let k = 0; k < dim; k++) if (Math.abs(v[k * dim + col]) > Math.abs(v[big * dim + col])) big = k;
    const sign = v[big * dim + col] < 0 ? -1 : 1;
    for (let k = 0; k < dim; k++) vectors[r * dim + k] = sign * v[k * dim + col];
  });
  return { values, vectors, sweeps };
}

export function fitPca(rows, dim, indices) {
  const { mean, cov, n } = covariance(rows, dim, indices);
  const { values, vectors, sweeps } = jacobiEigen(cov, dim);
  const total = values.reduce((s, x) => s + Math.max(x, 0), 0);
  const explained = Array.from(values, (x) => Math.max(x, 0) / total);
  return { dim, n, mean, values, vectors, explained, sweeps };
}

// Projects the given rows on the first k components: Float32Array of indices.length x k
export function project(pca, rows, indices, k) {
  const { dim, mean, vectors } = pca;
  const out = new Float32Array(indices.length * k);
  for (let r = 0; r < indices.length; r++) {
    const o = indices[r] * dim;
    for (let c = 0; c < k; c++) {
      let s = 0;
      const base = c * dim;
      for (let j = 0; j < dim; j++) s += (rows[o + j] - mean[j]) * vectors[base + j];
      out[r * k + c] = s;
    }
  }
  return out;
}
