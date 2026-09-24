// node browser/measure.mjs <chrome> <file.vextab>…
// Renders each file with vextab 4.0.5's own browser bundle in headless Chrome, and prints the x, y and text of every
// <text> element and the size of each drawing, as JSON. Compared with expected/ by browser/compare.mjs.
// Not run by CI: it needs Chrome and the network (VexFlow loads Bravura and Academico from cdn.jsdelivr.net).
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { pathToFileURL } from 'node:url';

const [chrome, ...files] = process.argv.slice(2);
const bundle = pathToFileURL(path.resolve('node_modules/vextab/dist/main.prod.js')).href;
const sources = Object.fromEntries(files.map((f) => [path.basename(f, '.vextab'), fs.readFileSync(f, 'utf8')]));
const html = `<!DOCTYPE html><html><head><meta charset="utf-8"></head><body><pre id="out">pending</pre><script src="${bundle}"></script><script>
(async () => {
  const { Vex, Artist, VexTab } = vextab;
  await Vex.Flow.loadFonts('Bravura', 'Academico');
  await document.fonts.ready;
  const result = { userAgent: navigator.userAgent, fonts: [...document.fonts].map((f) => f.family + ' ' + f.status) };
  for (const [name, code] of Object.entries(${JSON.stringify(sources)})) {
    const div = document.createElement('div');
    document.body.appendChild(div);
    const renderer = new Vex.Flow.Renderer(div, Vex.Flow.Renderer.Backends.SVG);
    const artist = new Artist(10, 10, 600);
    new VexTab(artist).parse(code);
    artist.render(renderer);
    const svg = div.querySelector('svg');
    result[name] = {
      size: svg.getAttribute('width') + 'x' + svg.getAttribute('height'),
      texts: [...svg.querySelectorAll('text')].map((t) => [t.textContent, Number(t.getAttribute('x')), Number(t.getAttribute('y'))]),
    };
  }
  document.getElementById('out').textContent = JSON.stringify(result);
})().catch((e) => { document.getElementById('out').textContent = 'ERROR ' + e.message; });
</script></body></html>`;
const page = path.join(os.tmpdir(), 'vextab-measure.html');
fs.writeFileSync(page, html);
const dom = execFileSync(chrome, ['--headless=new', '--disable-gpu', '--allow-file-access-from-files', '--virtual-time-budget=15000', '--dump-dom', pathToFileURL(page).href], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
const out = /<pre id="out">([\s\S]*?)<\/pre>/.exec(dom)[1].replace(/&quot;/g, '"').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
process.stdout.write(out + '\n');
