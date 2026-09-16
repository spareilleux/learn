// Lesson 3: writes public/generated/studio.hdr, a small HDR environment made of numbers instead of a photo:
// a dim gradient, two softboxes 40 times brighter than the walls, and a warm floor. node scripts/make-studio-hdr.ts
// Radiance RGBE: three 8-bit mantissas sharing an 8-bit exponent, so a pixel can hold values far above 1.
import { mkdirSync, writeFileSync } from 'node:fs';

const width = 256;
const height = 128;

function rgbe([r, g, b]: [number, number, number]): number[] {
  const max = Math.max(r, g, b);
  if (max < 1e-32) return [0, 0, 0, 0];
  const exponent = Math.ceil(Math.log2(max));
  const scale = 255.9999 / 2 ** exponent;
  return [Math.floor(r * scale), Math.floor(g * scale), Math.floor(b * scale), exponent + 128];
}

function radiance(u: number, v: number): [number, number, number] {
  // u: 0 to 1 around the horizon, v: 0 at the top, 1 at the bottom
  if (v > 0.55) return [0.35, 0.25, 0.18];
  const box = (cu: number, cv: number) => Math.abs(u - cu) < 0.06 && Math.abs(v - cv) < 0.1;
  if (box(0.25, 0.25)) return [20, 20, 19];
  if (box(0.7, 0.3)) return [8, 9, 12];
  const sky = 0.5 - v * 0.6;
  return [sky, sky, sky * 1.1];
}

const pixels: number[] = [];
for (let y = 0; y < height; y++) {
  for (let x = 0; x < width; x++) pixels.push(...rgbe(radiance((x + 0.5) / width, (y + 0.5) / height)));
}

const header = `#?RADIANCE\n# written by code/threejs/scripts/make-studio-hdr.ts\nFORMAT=32-bit_rle_rgbe\n\n-Y ${height} +X ${width}\n`;
mkdirSync('public/generated', { recursive: true });
writeFileSync('public/generated/studio.hdr', Buffer.concat([Buffer.from(header, 'ascii'), Buffer.from(pixels)]));
console.log(`public/generated/studio.hdr: ${width}×${height}, ${header.length + pixels.length} bytes`);
