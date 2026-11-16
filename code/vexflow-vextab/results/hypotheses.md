# Hypotheses, written before measuring (2026-09-24)

The course renders every example under Node: jsdom for the DOM, and text measured from the font files with opentype.js
instead of a browser canvas (`lib/env.cjs`). The question is how far that is from what a reader's browser draws. The
measurement: the same `.vextab` files rendered by vextab 4.0.5's own browser bundle (`dist/main.prod.js`) in headless
Chrome, then the x and y of every `<text>` element compared with `expected/`.

Written before running anything in a browser. H2 to H4 are not blind: I had read the code paths that produce them.

- **H1, layout.** For `l01-notation`, `l02-chords` and `l03-keys`, every notehead and fret number that Chrome draws is
  within 1.0 px (x and y) of the headless render, provided Chrome has loaded Bravura and Academico. If Chrome falls back
  to another font, the gap is larger and H1 is refuted.
- **H2, logo.** Chrome also draws the "vexflow.com" logo off-centre when a notation stave is present: its x is within
  1 px of the headless value (187.78 for `l01-notation`, 600 px wide), because `ArtistRenderer` measures the logo with
  the font of the last glyph drawn, before `setFont`. Not blind: read in the code.
- **H3, muted notes.** Chrome draws `X/6` on the notation stave at octave 6, far above the staff, at the same y as the
  headless render. Not blind: read in the code (`X` is a note name to the lexer, the string becomes the octave).
- **H4, strings=4.** Chrome's SVG for `l03-strings` is 712 px high, as headless. Not blind: `TabStave.getHeight()`
  returned 572 for `setNumLines("4")` under Node.
