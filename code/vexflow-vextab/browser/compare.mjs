// node browser/compare.mjs <browser.json> <expected folder>
// For each drawing measured in Chrome: its size against the headless one, and the largest gap in x and in y between
// the n-th <text> element of each render (VexFlow draws them in the same order in both).
import fs from 'node:fs';

const [json, dir] = process.argv.slice(2);
const browser = JSON.parse(fs.readFileSync(json, 'utf8'));
console.log(browser.userAgent.match(/HeadlessChrome\/[\d.]+/)[0]);
for (const [name, b] of Object.entries(browser)) {
  if (!b.texts) continue;
  const svg = fs.readFileSync(`${dir}/${name}.svg`, 'utf8');
  const size = /width="(\d+)" height="(\d+)"/.exec(svg).slice(1).join('x');
  // VexFlow leaves out an attribute whose value is 0 (a note at y = 0 has no y): read each one, 0 when absent
  const attr = (tag, name) => Number((new RegExp(` ${name}="([-\\d.]+)"`).exec(tag) ?? [0, 0])[1]);
  const texts = [...svg.matchAll(/(<text[^>]*>)([^<]*)</g)].map((m) => [m[2], attr(m[1], 'x'), attr(m[1], 'y')]);
  let dx = 0;
  let dy = 0;
  let worst = '';
  const n = Math.min(texts.length, b.texts.length);
  for (let i = 0; i < n; i++) {
    const gx = Math.abs(texts[i][1] - b.texts[i][1]);
    const gy = Math.abs(texts[i][2] - b.texts[i][2]);
    if (gx > dx) [dx, worst] = [gx, `#${i} headless ${texts[i][1]} chrome ${b.texts[i][1]}`];
    dy = Math.max(dy, gy);
  }
  console.log(`${name}: size headless ${size} chrome ${b.size}; texts ${texts.length}/${b.texts.length}; max |dx| ${dx.toFixed(2)} (${worst}); max |dy| ${dy.toFixed(2)}`);
}
