// A small multilayer perceptron: one hidden layer of tanh units, one linear output, trained with Adam on
// mini-batches. Inputs and target are standardised, so the same learning rate works whatever the units are.

import { mulberry32 } from './random.mjs';
import { standardiser } from './linear.mjs';

export function fitMlp(
  X,
  y,
  { hidden = 32, epochs = 60, batch = 128, learningRate = 0.01, seed = 303, beta1 = 0.9, beta2 = 0.999, eps = 1e-8 } = {},
) {
  const n = X.length;
  const d = X[0].length;
  const std = standardiser(X);
  const Z = X.map((row) => std.apply(row));
  let meanY = 0;
  for (const v of y) meanY += v;
  meanY /= n;
  let sdY = 0;
  for (const v of y) sdY += (v - meanY) ** 2;
  sdY = Math.sqrt(sdY / n) || 1;
  const t = Float64Array.from(y, (v) => (v - meanY) / sdY);

  const rng = mulberry32(seed);
  const gauss = () => {
    const u = Math.max(rng(), 1e-12);
    return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * rng());
  };
  const W1 = new Float64Array(hidden * d);
  const b1 = new Float64Array(hidden);
  const W2 = new Float64Array(hidden);
  let b2 = 0;
  const scale = Math.sqrt(1 / d);
  for (let i = 0; i < W1.length; i++) W1[i] = gauss() * scale;
  for (let i = 0; i < hidden; i++) W2[i] = gauss() * Math.sqrt(1 / hidden);

  const make = () => ({ m: new Float64Array(hidden * d), v: new Float64Array(hidden * d) });
  const aW1 = make();
  const ab1 = { m: new Float64Array(hidden), v: new Float64Array(hidden) };
  const aW2 = { m: new Float64Array(hidden), v: new Float64Array(hidden) };
  let mb2 = 0;
  let vb2 = 0;
  let step = 0;

  const order = Array.from({ length: n }, (_, i) => i);
  const h = new Float64Array(hidden);
  const gW1 = new Float64Array(hidden * d);
  const gb1 = new Float64Array(hidden);
  const gW2 = new Float64Array(hidden);

  for (let epoch = 0; epoch < epochs; epoch++) {
    for (let i = n - 1; i > 0; i--) {
      const j = Math.floor(rng() * (i + 1));
      [order[i], order[j]] = [order[j], order[i]];
    }
    for (let start = 0; start < n; start += batch) {
      const end = Math.min(n, start + batch);
      gW1.fill(0);
      gb1.fill(0);
      gW2.fill(0);
      let gb2 = 0;
      for (let s = start; s < end; s++) {
        const row = Z[order[s]];
        let out = b2;
        for (let k = 0; k < hidden; k++) {
          let a = b1[k];
          const base = k * d;
          for (let j = 0; j < d; j++) a += W1[base + j] * row[j];
          h[k] = Math.tanh(a);
          out += W2[k] * h[k];
        }
        const err = out - t[order[s]];
        gb2 += err;
        for (let k = 0; k < hidden; k++) {
          gW2[k] += err * h[k];
          const dh = err * W2[k] * (1 - h[k] * h[k]);
          gb1[k] += dh;
          const base = k * d;
          for (let j = 0; j < d; j++) gW1[base + j] += dh * row[j];
        }
      }
      const m = end - start;
      step++;
      const bc1 = 1 - Math.pow(beta1, step);
      const bc2 = 1 - Math.pow(beta2, step);
      const adam = (value, grad, state, index) => {
        const g = grad / m;
        state.m[index] = beta1 * state.m[index] + (1 - beta1) * g;
        state.v[index] = beta2 * state.v[index] + (1 - beta2) * g * g;
        return value - (learningRate * (state.m[index] / bc1)) / (Math.sqrt(state.v[index] / bc2) + eps);
      };
      for (let i = 0; i < W1.length; i++) W1[i] = adam(W1[i], gW1[i], aW1, i);
      for (let k = 0; k < hidden; k++) {
        b1[k] = adam(b1[k], gb1[k], ab1, k);
        W2[k] = adam(W2[k], gW2[k], aW2, k);
      }
      const g = gb2 / m;
      mb2 = beta1 * mb2 + (1 - beta1) * g;
      vb2 = beta2 * vb2 + (1 - beta2) * g * g;
      b2 -= (learningRate * (mb2 / bc1)) / (Math.sqrt(vb2 / bc2) + eps);
    }
  }

  return {
    kind: 'mlp',
    hidden,
    predict(row) {
      const z = std.apply(row);
      let out = b2;
      for (let k = 0; k < hidden; k++) {
        let a = b1[k];
        const base = k * d;
        for (let j = 0; j < d; j++) a += W1[base + j] * z[j];
        out += W2[k] * Math.tanh(a);
      }
      return out * sdY + meanY;
    },
    size: () =>
      JSON.stringify({ W1: [...W1], b1: [...b1], W2: [...W2], b2, mean: std.mean, sd: std.sd, meanY, sdY }).length,
  };
}
