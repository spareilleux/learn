// Experiment 6's texture: a 2048 × 2048 fretboard wood written to public/generated/wood-2048.png, with the same ring
// pattern as the page's procedural TSL wood (value noise here, MaterialX noise there, so the grain differs in detail).
// It stands in for the ComfyUI GA lab's seamless woods (code/comfyui/ga-lab, experiment 4) until those are rendered.
//   node scripts/wood-texture.ts [size]
// Then, for the KTX2 versions, scripts/wood-ktx2.sh (KTX-Software's ktx tool), and the Basis transcoder is copied from
// three's examples next to them.
import { copyFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { PNG } from 'pngjs';

const size = Number(process.argv[2] ?? 2048);
const lab = resolve(import.meta.dirname, '..');
const dir = join(lab, 'public', 'generated');
mkdirSync(dir, { recursive: true });

// Value noise on a lattice, smoothly interpolated, tileable with period p
const hash = (x: number, y: number) => {
  const h = Math.imul(x * 374761393 + y * 668265263, 1274126177) >>> 0;
  return ((h ^ (h >>> 13)) >>> 0) / 4294967296;
};
function noise(x: number, y: number, p: number): number {
  const xi = Math.floor(x);
  const yi = Math.floor(y);
  const fx = x - xi;
  const fy = y - yi;
  const s = (t: number) => t * t * (3 - 2 * t);
  const m = (v: number) => ((v % p) + p) % p;
  const a = hash(m(xi), m(yi));
  const b = hash(m(xi + 1), m(yi));
  const c = hash(m(xi), m(yi + 1));
  const d = hash(m(xi + 1), m(yi + 1));
  return a + (b - a) * s(fx) + (c - a) * s(fy) + (a - b - c + d) * s(fx) * s(fy);
}

// Rosewood: dark brown rings along the board, lighter between them
const dark = [0x2a, 0x17, 0x0f];
const light = [0x5a, 0x34, 0x22];
const png = new PNG({ width: size, height: size });
for (let y = 0; y < size; y++) {
  for (let x = 0; x < size; x++) {
    const u = x / size;
    const v = y / size;
    const warp = noise(u * 4, v * 12, 4) * 0.8 + noise(u * 16, v * 48, 16) * 0.2;
    const ring = (v * 12 + warp) % 1;
    const t = Math.min(1, Math.max(0, (ring - 0.2) / 0.6));
    const smooth = t * t * (3 - 2 * t);
    const fine = noise(u * 256, v * 32, 256) * 0.12;
    const i = (y * size + x) * 4;
    for (let c = 0; c < 3; c++) png.data[i + c] = Math.round(dark[c] + (light[c] - dark[c]) * Math.min(1, smooth + fine));
    png.data[i + 3] = 255;
  }
}
writeFileSync(join(dir, `wood-${size}.png`), PNG.sync.write(png));
// The Basis Universal transcoder that KTX2Loader loads, from three's examples
const basis = resolve(lab, '..', 'node_modules', 'three', 'examples', 'jsm', 'libs', 'basis');
mkdirSync(join(dir, 'basis'), { recursive: true });
for (const file of ['basis_transcoder.js', 'basis_transcoder.wasm']) copyFileSync(join(basis, file), join(dir, 'basis', file));
console.log(`wrote public/generated/wood-${size}.png and the Basis transcoder`);
