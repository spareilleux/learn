// Ridge regression by the normal equations, solved with a Cholesky factorisation. Features are standardised
// first, so one regularisation strength means the same thing for a count and for a distance in millimetres.

export function standardiser(X) {
  const n = X.length;
  const d = X[0].length;
  const mean = new Float64Array(d);
  const sd = new Float64Array(d);
  for (const row of X) for (let j = 0; j < d; j++) mean[j] += row[j];
  for (let j = 0; j < d; j++) mean[j] /= n;
  for (const row of X) for (let j = 0; j < d; j++) sd[j] += (row[j] - mean[j]) ** 2;
  for (let j = 0; j < d; j++) sd[j] = Math.sqrt(sd[j] / n) || 1;
  return {
    mean: [...mean],
    sd: [...sd],
    apply(row) {
      const out = new Float64Array(d);
      for (let j = 0; j < d; j++) out[j] = (row[j] - mean[j]) / sd[j];
      return out;
    },
  };
}

function choleskySolve(A, b) {
  const n = b.length;
  const L = Array.from({ length: n }, () => new Float64Array(n));
  for (let i = 0; i < n; i++) {
    for (let j = 0; j <= i; j++) {
      let s = A[i][j];
      for (let k = 0; k < j; k++) s -= L[i][k] * L[j][k];
      if (i === j) L[i][i] = Math.sqrt(Math.max(s, 1e-12));
      else L[i][j] = s / L[j][j];
    }
  }
  const y = new Float64Array(n);
  for (let i = 0; i < n; i++) {
    let s = b[i];
    for (let k = 0; k < i; k++) s -= L[i][k] * y[k];
    y[i] = s / L[i][i];
  }
  const x = new Float64Array(n);
  for (let i = n - 1; i >= 0; i--) {
    let s = y[i];
    for (let k = i + 1; k < n; k++) s -= L[k][i] * x[k];
    x[i] = s / L[i][i];
  }
  return x;
}

export function fitRidge(X, y, lambda = 1) {
  const std = standardiser(X);
  const d = X[0].length;
  const A = Array.from({ length: d }, () => new Float64Array(d));
  const b = new Float64Array(d);
  let meanY = 0;
  for (const v of y) meanY += v;
  meanY /= y.length;
  for (let i = 0; i < X.length; i++) {
    const z = std.apply(X[i]);
    const t = y[i] - meanY;
    for (let a = 0; a < d; a++) {
      b[a] += z[a] * t;
      for (let c = 0; c <= a; c++) A[a][c] += z[a] * z[c];
    }
  }
  for (let a = 0; a < d; a++) {
    for (let c = 0; c < a; c++) A[c][a] = A[a][c];
    A[a][a] += lambda;
  }
  const w = choleskySolve(A, b);
  return {
    kind: 'ridge',
    weights: [...w],
    intercept: meanY,
    std,
    predict(row) {
      const z = std.apply(row);
      let s = meanY;
      for (let j = 0; j < d; j++) s += w[j] * z[j];
      return s;
    },
    size() {
      return JSON.stringify({ w: [...w], m: std.mean, s: std.sd, b: meanY }).length;
    },
  };
}

// A one-feature baseline: the least-squares line through a single column
export function fitSingleFeature(X, y, column) {
  const n = X.length;
  let sx = 0;
  let sy = 0;
  let sxx = 0;
  let sxy = 0;
  for (let i = 0; i < n; i++) {
    const x = X[i][column];
    sx += x;
    sy += y[i];
    sxx += x * x;
    sxy += x * y[i];
  }
  const den = n * sxx - sx * sx;
  const a = den === 0 ? 0 : (n * sxy - sx * sy) / den;
  const b = (sy - a * sx) / n;
  return {
    kind: 'single',
    column,
    a,
    b,
    predict: (row) => a * row[column] + b,
    size: () => JSON.stringify({ a, b, column }).length,
  };
}

export function fitMean(X, y) {
  let m = 0;
  for (const v of y) m += v;
  m /= y.length;
  return { kind: 'mean', predict: () => m, size: () => JSON.stringify({ m }).length };
}
