// Loads VexTab under Node: a jsdom document for the SVG renderer, and a text-measurement canvas that VexFlow asks for
// the width and height of every glyph and string it lays out.
//
// In a browser VexFlow measures text with a <canvas> 2D context. jsdom has no canvas, and node-canvas cannot load the
// OpenType (CFF) fonts VexFlow ships on Windows, so this file hands VexFlow its own "canvas" through the public hook
// Element.setTextMeasurementCanvas(): measureText() reads advance widths and glyph outlines from the font files with
// opentype.js. It is plain JavaScript, so the layout is the same on Windows, Linux and macOS.
//
// Fonts: Bravura (music glyphs) and Academico (text), the two fonts VexFlow 5 uses by default. Any other family a
// stylesheet asks for (Arial for tab fret numbers, Times for annotations) is measured with Academico: the SVG still names
// the family it asked for, and a browser draws it with that font, a few tenths of a pixel wider or narrower.
const fs = require('node:fs');
const path = require('node:path');
const opentype = require('opentype.js');
const { JSDOM } = require('jsdom');

const fontsDir = path.join(__dirname, '..', 'node_modules', '@vexflow-fonts');
const load = (file) => opentype.parse(fs.readFileSync(path.join(fontsDir, file)));
const FONTS = {
  bravura: load('bravura/bravura.otf'),
  academico: load('academico/academico.otf'),
  'academico-bold': load('academico/academico-bold.otf'),
};

// "italic bold 30pt Bravura,Academico" -> { bold, px, families }
function parseCssFont(css) {
  const m = /^\s*(?:(italic|oblique|normal)\s+)?(?:(bold|bolder|normal|[1-9]00)\s+)?([\d.]+)(pt|px|em)?\s+(.+)$/.exec(css);
  if (!m) return { bold: false, px: 10, families: ['academico'] };
  const size = parseFloat(m[3]);
  const px = m[4] === 'pt' ? (size * 4) / 3 : m[4] === 'em' ? size * 16 : size;
  const bold = m[2] === 'bold' || m[2] === 'bolder' || Number(m[2]) >= 600;
  const families = m[5].split(',').map((f) => f.trim().replace(/^["']|["']$/g, '').toLowerCase());
  return { bold, px, families };
}

function fontFor(ch, spec) {
  for (const family of spec.families) {
    const key = family === 'academico' && spec.bold ? 'academico-bold' : family;
    const font = FONTS[key];
    if (font && font.charToGlyphIndex(ch) > 0) return font;
  }
  return spec.bold ? FONTS['academico-bold'] : FONTS.academico;
}

// The subset of CanvasRenderingContext2D that VexFlow's Element.measureText() and measureWidth() use
function measureContext() {
  let spec = parseCssFont('10pt Academico');
  return {
    get font() {
      return this._font;
    },
    set font(css) {
      this._font = css;
      spec = parseCssFont(css);
    },
    measureText(text) {
      let x = 0;
      let top = 0;
      let bottom = 0;
      let left = Infinity;
      let right = -Infinity;
      for (const ch of String(text)) {
        const font = fontFor(ch, spec);
        const glyph = font.charToGlyph(ch);
        const scale = spec.px / font.unitsPerEm;
        const box = glyph.getBoundingBox();
        if (box.x1 !== box.x2 || box.y1 !== box.y2) {
          top = Math.max(top, box.y2 * scale);
          bottom = Math.max(bottom, -box.y1 * scale);
          left = Math.min(left, x + box.x1 * scale);
          right = Math.max(right, x + box.x2 * scale);
        }
        x += glyph.advanceWidth * scale;
      }
      if (left === Infinity) left = right = 0;
      return {
        width: x,
        actualBoundingBoxAscent: top,
        actualBoundingBoxDescent: bottom,
        actualBoundingBoxLeft: -left,
        actualBoundingBoxRight: right,
      };
    },
  };
}

let loaded;

// Returns { Vex, Artist, VexTab, document }: the exports of the vextab package, with its bundled VexFlow
function loadVexTab() {
  if (loaded) return loaded;
  const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>');
  global.window = dom.window;
  global.self = dom.window;
  global.document = dom.window.document;
  global.getComputedStyle = dom.window.getComputedStyle.bind(dom.window);
  // vextab's bundle announces itself once the document is ready ("Running VexTab.Div: …"): keep that line out
  const log = console.log;
  console.log = (...args) => {
    if (!(typeof args[0] === 'string' && args[0].startsWith('Running VexTab.Div'))) log(...args);
  };
  const vextab = require('vextab');
  const ctx = measureContext();
  vextab.Vex.Flow.Element.setTextMeasurementCanvas({ getContext: () => ctx });
  loaded = { ...vextab, document: dom.window.document };
  return loaded;
}

module.exports = { loadVexTab, measureContext, parseCssFont, fontFor, FONTS };
