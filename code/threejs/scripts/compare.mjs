// Compares an output with its expected file: node scripts/compare.mjs expected.txt out.txt
// Lines must be equal, except colors read from a screenshot, rgb(r, g, b), where each channel may differ by 2:
// GPUs and software rasterizers round the same shader result differently (lesson 3).
import { readFileSync } from 'node:fs';

const [expectedPath, actualPath] = process.argv.slice(2);
const lines = (path) => readFileSync(path, 'utf8').replaceAll('\r\n', '\n').split('\n');
const expected = lines(expectedPath);
const actual = lines(actualPath);
const rgb = /rgb\((\d+), (\d+), (\d+)\)/;
const tolerance = 2;

let differences = 0;
for (let i = 0; i < Math.max(expected.length, actual.length); i++) {
  const [a, b] = [expected[i] ?? '', actual[i] ?? ''];
  if (a === b) continue;
  const [ma, mb] = [rgb.exec(a), rgb.exec(b)];
  const close =
    ma && mb && a.replace(rgb, '') === b.replace(rgb, '') && [1, 2, 3].every((c) => Math.abs(Number(ma[c]) - Number(mb[c])) <= tolerance);
  if (close) {
    console.log(`~${i + 1}: ${b.trim()} (expected ${ma[0]})`);
  } else {
    console.log(`${i + 1}c${i + 1}\n< ${a}\n---\n> ${b}`);
    differences++;
  }
}
process.exit(differences === 0 ? 0 : 1);
