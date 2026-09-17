// A deterministic sample: the same seed picks the same rows on every machine, in Node.js and in the browser.

// mulberry32, a 32-bit generator with integer arithmetic only (Math.imul), so no floating-point platform differences
export function mulberry32(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// n distinct row numbers out of total, sorted: a partial Fisher-Yates shuffle over [0, total)
export function sampleIndices(total, n, seed) {
  if (n > total) throw new Error(`cannot sample ${n} rows out of ${total}`);
  const random = mulberry32(seed);
  const pool = new Uint32Array(total);
  for (let i = 0; i < total; i++) pool[i] = i;
  for (let i = 0; i < n; i++) {
    const j = i + Math.floor(random() * (total - i));
    const t = pool[i];
    pool[i] = pool[j];
    pool[j] = t;
  }
  return pool.slice(0, n).sort();
}
