// Lesson 12: comparing screenshots pixel by pixel: node scripts/l12-pixels.ts <reference.png> <candidate.png> [threshold]
// pixelmatch counts the pixels whose color differs by more than the threshold (0 to 1, in its perceptual color distance,
// default 0.1) and marks anti-aliased pixels apart. It prints the counts and writes the differences to out/diff-*.png.
import { readFileSync, writeFileSync } from 'node:fs';
import { basename } from 'node:path';
import pixelmatch from 'pixelmatch';
import { PNG } from 'pngjs';

const [referencePath, candidatePath, thresholdArg] = process.argv.slice(2);
const reference = PNG.sync.read(readFileSync(referencePath));
const candidate = PNG.sync.read(readFileSync(candidatePath));
if (reference.width !== candidate.width || reference.height !== candidate.height) {
  console.log(`different sizes: ${reference.width}x${reference.height} and ${candidate.width}x${candidate.height}`);
  process.exit(1);
}
const { width, height } = reference;
const diff = new PNG({ width, height });
const threshold = Number(thresholdArg ?? 0.1);
const total = width * height;

// Exact equality first, byte by byte
let exact = 0;
for (let i = 0; i < reference.data.length; i += 4) {
  if (reference.data[i] !== candidate.data[i] || reference.data[i + 1] !== candidate.data[i + 1] || reference.data[i + 2] !== candidate.data[i + 2]) exact++;
}
const differing = pixelmatch(reference.data, candidate.data, diff.data, width, height, { threshold, includeAA: false });
const name = `${basename(referencePath, '.png')}-vs-${basename(candidatePath, '.png')}`;
writeFileSync(`out/diff-${name}.png`, PNG.sync.write(diff));
const percent = (n: number) => `${((n / total) * 100).toFixed(2)} %`;
console.log(`${basename(referencePath)} and ${basename(candidatePath)}, ${width}x${height}:`);
console.log(`  pixels not byte-identical: ${exact} (${percent(exact)})`);
console.log(`  pixels over pixelmatch's threshold ${threshold}, anti-aliasing excluded: ${differing} (${percent(differing)})`);
