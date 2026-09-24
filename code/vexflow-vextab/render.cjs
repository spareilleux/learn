// node render.cjs [--ast] [--width N] [--out DIR] <file.vextab>…
// Parses each file with VexTab, renders it to SVG with VexFlow, and writes to DIR (out/ by default): <name>.svg, the
// drawing, normalized (see normalize()); <name>.txt, "ok" and the size of the drawing, or the error VexTab raised; and
// with --ast, <name>.ast.json, the elements the parser returns before VexTab turns them into VexFlow calls.
const fs = require('node:fs');
const path = require('node:path');
const { loadVexTab } = require('./lib/env.cjs');

// What varies between runs: VexFlow numbers every element it draws ("vf-auto1042") from a counter shared by the whole
// process, so the ids are renumbered from 1 in order of appearance; coordinates are rounded to two decimals. Each
// element goes on its own line so that a diff points at the element that moved.
function normalize(svg) {
  const ids = new Map();
  return svg
    .replace(/vf-auto\d+/g, (id) => {
      if (!ids.has(id)) ids.set(id, `vf-${ids.size + 1}`);
      return ids.get(id);
    })
    .replace(/-?\d+\.\d+/g, (n) => String(Math.round(Number(n) * 100) / 100))
    .replace(/>(<[a-z])/g, '>\n$1')
    .concat('\n');
}

function render(code, width = 600) {
  const { Vex, Artist, VexTab, document } = loadVexTab();
  const div = document.createElement('div');
  const renderer = new Vex.Flow.Renderer(div, Vex.Flow.Renderer.Backends.SVG);
  const artist = new Artist(10, 10, width);
  const vextab = new VexTab(artist);
  const elements = vextab.parse(code);
  artist.render(renderer);
  const svg = div.querySelector('svg');
  return { elements, svg: div.innerHTML, width: svg.getAttribute('width'), height: svg.getAttribute('height') };
}

function main(argv) {
  let ast = false;
  let width = 600;
  let out = 'out';
  const files = [];
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--ast') ast = true;
    else if (argv[i] === '--width') width = Number(argv[++i]);
    else if (argv[i] === '--out') out = argv[++i];
    else files.push(argv[i]);
  }
  fs.mkdirSync(out, { recursive: true });
  for (const file of files) {
    const name = path.basename(file, '.vextab');
    const code = fs.readFileSync(file, 'utf8');
    let report;
    try {
      const r = render(code, width);
      fs.writeFileSync(`${out}/${name}.svg`, normalize(r.svg));
      if (ast) fs.writeFileSync(`${out}/${name}.ast.json`, JSON.stringify(r.elements, null, 2) + '\n');
      report = `ok ${r.width}x${r.height}`;
    } catch (e) {
      fs.rmSync(`${out}/${name}.svg`, { force: true });
      report = `error ${e.code ?? e.name}: ${e.message}`;
    }
    fs.writeFileSync(`${out}/${name}.txt`, report + '\n');
    console.log(`${name}: ${report}`);
  }
}

if (require.main === module) main(process.argv.slice(2));

module.exports = { render, normalize };
