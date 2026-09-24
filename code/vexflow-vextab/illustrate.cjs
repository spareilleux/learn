// node illustrate.cjs <in.svg> <out.svg>
// Makes a rendered SVG displayable without VexFlow's fonts: every <text> drawn in Bravura or Academico (the music
// glyphs, fret numbers, text in VexFlow's default font) becomes a <path> with the outline of the same glyphs, taken from
// the same font files at the same size and position. Text in a family every browser has (Arial, Times) stays text.
// The lessons show these copies; the comparison in check.sh is on the SVG VexFlow wrote.
const fs = require('node:fs');
const { JSDOM } = require('jsdom');
const { fontFor, parseCssFont } = require('./lib/env.cjs');

const OWN = new Set(['bravura', 'academico']);

function inherited(el, name, fallback) {
  for (let e = el; e && e.getAttribute; e = e.parentNode) {
    const v = e.getAttribute(name);
    if (v) return v;
  }
  return fallback;
}

function illustrate(svgText) {
  if (!/^<svg[^>]*xmlns=/.test(svgText)) svgText = svgText.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ');
  const dom = new JSDOM(svgText, { contentType: 'image/svg+xml' });
  const doc = dom.window.document;
  for (const text of [...doc.querySelectorAll('text')]) {
    const family = inherited(text, 'font-family', 'Academico');
    const size = inherited(text, 'font-size', '10pt');
    const weight = inherited(text, 'font-weight', 'normal');
    const spec = parseCssFont(`${weight === 'bold' ? 'bold ' : ''}${size} ${family}`);
    if (!OWN.has(spec.families[0])) continue;
    let x = Number(text.getAttribute('x'));
    const y = Number(text.getAttribute('y'));
    let d = '';
    for (const ch of text.textContent) {
      const font = fontFor(ch, spec);
      d += font.getPath(ch, x, y, spec.px).toPathData(2);
      x += (font.charToGlyph(ch).advanceWidth * spec.px) / font.unitsPerEm;
    }
    const path = doc.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', d);
    path.setAttribute('stroke', 'none');
    const fill = text.getAttribute('fill');
    if (fill) path.setAttribute('fill', fill);
    text.replaceWith(path);
  }
  // For a page: ids would repeat between two drawings of one page, the invisible hit rectangles VexFlow adds for mouse
  // events serve nothing, black follows the page's text colour (dark theme), and the white patches that hide the tab
  // lines behind fret numbers take the page's background colour
  for (const rect of doc.querySelectorAll('rect[opacity="0"]')) rect.remove();
  for (const el of doc.querySelectorAll('*')) {
    el.removeAttribute('id');
    el.removeAttribute('pointer-events');
    el.removeAttribute('shadowColor');
    for (const name of ['fill', 'stroke']) {
      const v = el.getAttribute(name);
      if (v === 'black' || v === '#444' || v === '#777777') el.setAttribute(name, 'currentColor');
      if (v === 'white') {
        el.removeAttribute(name);
        el.setAttribute('style', 'fill:var(--sl-color-bg, white)');
      }
    }
  }
  doc.documentElement.setAttribute('style', 'max-width:100%;height:auto');
  return new dom.window.XMLSerializer().serializeToString(doc.documentElement) + '\n';
}

if (require.main === module) {
  const [input, output] = process.argv.slice(2);
  fs.writeFileSync(output, illustrate(fs.readFileSync(input, 'utf8')));
}

module.exports = { illustrate };
