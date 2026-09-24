---
title: Journal
description: Dated notes of the VexTab & VexFlow course — what VexTab 4.0.5 and VexFlow 5.0.0 turned out to do, what Guitar Alchemist's VexTab code does against them, and how far the headless rendering is from Chrome, with the hypotheses written before measuring.
sidebar:
  order: 99
---

## Progress

- [x] Mission and outline
- [x] Course code: headless rendering, `check.sh`, CI on Linux, Windows and macOS
- [x] Lesson 1: first stave, first tab
- [x] Lesson 2: guitar techniques
- [x] Lesson 3: keys, times, clefs and tunings
- [x] Lesson 4: case study, GA's chatbot writes VexTab
- [ ] Lesson 5: VexFlow's own objects, a strict voice
- [ ] Lesson 6: `TabStave` and `TabNote`
- [ ] Lesson 7: rendering in React, testing with Playwright
- [ ] Lesson 8: moving GA from VexFlow 4 to 5

## QA

What the course found in the software it teaches, and in Guitar Alchemist's code that uses it. VexTab links point at [`3a5e00d`](https://github.com/0xfe/vextab/tree/3a5e00d858ae98934ba545f9bef5eb923e17e402), the commit npm's 4.0.5 was built from; VexFlow links at [`0ca6f88`](https://github.com/vexflow/vexflow/tree/0ca6f889545c33cce851b420c24945f6eb685aeb), the 5.0.0 bundled in it; GA links at [`17ccee6`](https://github.com/GuitarAlchemist/ga/tree/17ccee6885851e4b460ebd14d7f4cfb838f5541e). Every measure is an output of `check.sh`, compared in CI. Nothing has been reported upstream yet; a search of the VexTab and VexFlow issues found no existing report of these.

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| `strings=4` sizes the drawing for four tab lines | The option stays a string; VexFlow computes the stave height as `("4" + 4) * 13` | [`StaveBuilder.ts:141`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/StaveBuilder.ts#L141), [`VexTabParser.ts:86-89`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/vextab/VexTabParser.ts#L86-L89), VexFlow [`stave.ts:142`](https://github.com/vexflow/vexflow/blob/0ca6f889545c33cce851b420c24945f6eb685aeb/src/stave.ts#L142) | Drawing 712 px tall for `strings=4`, 842 for 5, 1102 for 7, against 270 for six strings; same in Chrome | Reproduced under Node and in Chrome ([lesson 3](../03-keys-time-tunings/#the-number-of-strings)) |
| `$G$` after a chord draws the text G | Any text matching a note name replaces the fret number of the chord's lowest string, and no annotation is drawn | [`ArticulationBuilder.ts:362`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArticulationBuilder.ts#L362), [`:461`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArticulationBuilder.ts#L461) | `$G$ $C$ $D$` on three chords: 0 annotations, 3 fret numbers replaced; `$.big.G$` and `$D $` are drawn as text | Reproduced. Documented as a feature for single notes; a trap for chord names ([lesson 2](../02-guitar-techniques/#annotations)) |
| `$.italic.let ring$` is italic | VexTab passes the style as VexFlow 5's third argument, the weight | [`ArticulationBuilder.ts:298-302`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArticulationBuilder.ts#L298-L302), VexFlow [`element.ts:392`](https://github.com/vexflow/vexflow/blob/0ca6f889545c33cce851b420c24945f6eb685aeb/src/element.ts#L392) | SVG says `font-weight="italic"`, no `font-style` | Reproduced |
| The `vexflow.com` logo is centred and italic | Measured before its font is set, so it is placed with the width of the wrong font, and set upright for the same reason as above | [`ArtistRenderer.ts:262-266`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArtistRenderer.ts#L262-L266) | x = 187.78 on a 600 px drawing with notation (Chrome: 188.52), | Reproduced under Node and in Chrome (H2) |
| `X/6` is a muted note on string 6 | The lexer reads `X` as a note name, so 6 becomes an octave: the notation draws an x notehead where B6 would be, at y = 0, half outside the drawing | [`vextab.jison:84`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/vextab.jison#L84), [`NoteBuilder.ts:264-266`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/NoteBuilder.ts#L264-L266) | Same position in Chrome, within 0.67 px | Reproduced under Node and in Chrome (H3). The tab is right |
| VexFlow's `eb` tuning is standard tuning a half step down | String 6 is `Db/3`, a whole step down | VexFlow [`tuning.ts:16`](https://github.com/vexflow/vexflow/blob/0ca6f889545c33cce851b420c24945f6eb685aeb/src/tuning.ts#L16) | Open string 6 drawn as C♯3 (written), where E♭3 was meant; the line is unchanged on VexFlow's `main` | Reproduced ([lesson 3](../03-keys-time-tunings/#tunings)) |
| `V` draws a harsh vibrato | VexTab calls `setHarsh` only if it exists, and VexFlow 5's `Vibrato` has none | [`ArticulationBuilder.ts:635-640`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArticulationBuilder.ts#L635-L640), VexFlow [`vibrato.ts`](https://github.com/vexflow/vexflow/blob/0ca6f889545c33cce851b420c24945f6eb685aeb/src/vibrato.ts#L86) | `7v` and `8V` draw the same three glyphs U+EAB0 | Reproduced |
| Five quarter notes in a 4/4 bar are refused | They are drawn: VexTab's voices are in soft mode | [`ArtistRenderer.ts:67`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/artist/ArtistRenderer.ts#L67) | `l01-overfull` renders | Reproduced. By design, as far as the code says ([lesson 1](../01-first-stave/#durations-and-bar-lines)) |
| GA's chatbot `vextab` blocks are VexTab | They use a GA token format, `string/fret`, with no `tabstave` or `notes` | GA [`PlayableNotationFormatter.cs:15-25`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs#L15-L25), [`:59-71`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs#L59-L71) | 12 of 12 blocks (8 beginner chords, the prompt's example, 3 e2e tests) rejected by VexTab 4.0.5 and by GA's F# parser | Reproduced, not reported to GA ([lesson 4](../04-ga-chatbot-vextab/#the-results)) |
| GA's chat client draws `vextab` blocks, as its e2e test asserts | `MemoizedVexTab` prints them in a `<pre>` | GA [`MemoizedVexTab.tsx:11-28`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Apps/ga-client/src/components/Chat/MemoizedVexTab.tsx#L11-L28), [`vextab-rendering.spec.ts:94-99`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Apps/ga-client/tests/e2e/vextab-rendering.spec.ts#L94-L99) | Read, not run; the unit test is `it.skip` | Read in the code, not run. Whether the e2e spec runs in GA's CI is *to verify* |
| GA's trace field `notation.renderer` says what drew the notation | It is the constant `"vexflow"` | GA [`OrchestratedChatApplicationService.cs:336`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs#L336) | 45 golden traces: 44 with `added_count` 0, one with 8 | Read in the code and the traces |
| GA's F# parser reads what its generator writes, and its grammar's examples | `str`, `ch` and `pint` eat the whitespace after them, including the space that starts the next tabstave option | GA [`VexTabParser.fs:22-29`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L22-L29), [`:330`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L330) | Round trip fails at column 51 or 52 for 6 of 6 parsable texts; 0 of 4 EBNF examples parse | Reproduced with GA's files compiled unchanged, not reported to GA |
| GA's F# parser accepts VexTab | It differs on techniques (after the string), flats (`b`), mid-line durations, fret runs, taps, annotations and minor keys | GA [`VexTabParser.fs:85`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L85), [`:239-244`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L239-L244), [`:413-420`](https://github.com/GuitarAlchemist/ga/blob/17ccee6885851e4b460ebd14d7f4cfb838f5541e/Common/GA.Business.DSL/Parsers/VexTabParser.fs#L413-L420) | Of 32 texts, GA's parser accepts 6 and VexTab 17; they agree on "ok" for 4 | Reproduced, not reported to GA |

## Experiments

| Question | Hypothesis, written before measuring | Result | Verdict |
|---|---|---|---|
| Does the headless rendering (jsdom, text measured with opentype.js) place glyphs where Chrome does? | H1: within 1.0 px in x and y for every text element of `l01-notation`, `l02-chords` and `l03-keys`, if Chrome loads Bravura and Academico ([`hypotheses.md`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/results/hypotheses.md), committed in `284eb7e` before any browser run) | 157 text elements over five drawings: max \|dx\| 0.74 px, max \|dy\| 0.67 px, sizes equal ([`browser-2026-09-24.txt`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/results/browser-2026-09-24.txt)). The first two runs were wrong, see [the entry](#2026-09-24--headless-against-chrome) | Confirmed |
| Is the off-centre logo an artefact of the headless setup? | H2: Chrome draws it at x within 1 px of 187.78. Not blind | Chrome: 188.52 | Confirmed |
| Does Chrome draw `X/6` in octave 6 too? | H3: yes, at the same y. Not blind | Same position, within the 0.67 px above | Confirmed |
| Is the 712 px drawing of `strings=4` an artefact of jsdom? | H4: Chrome's SVG is 712 px high. Not blind | 600 × 712 | Confirmed |

## 2026-09-24 — Which VexTab, which VexFlow

npm's `vextab` 4.0.5 was published on 2026-01-18; its sources are identical to commit `3a5e00d` of `0xfe/vextab` (checked file by file with SHA-1). Its `dist/main.prod.js` bundles VexFlow 5.0.0, `Vex.Flow.BUILD.ID` `0ca6f889…`, and re-creates VexFlow 4's `Vex.Flow` namespace over it. Installing `vexflow` next to it changes nothing for VexTab; the course pins `vexflow` 5.0.0 anyway, for lesson 5. GA, on the other hand, uses VexFlow `^4.2.5`, and vendors a `vexflow.js` 4.2.5 for its chatbot API.

## 2026-09-24 — Rendering without a browser

The bundle wants `window`, `self`, `document` and `getComputedStyle`; jsdom gives them. What it doesn't give is text measurement: VexFlow measures every glyph with a canvas. First attempt, node-canvas 3.2.3 with `registerFont` on the Bravura and Academico OTF files: on Windows it doesn't load these CFF-flavoured fonts and silently measures with a sans-serif fallback. Replaced by a small context that measures with [opentype.js](https://opentype.js.org/) from the same OTF files ([`lib/env.cjs`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/lib/env.cjs)), passed to VexFlow with `Element.setTextMeasurementCanvas`. The output is the same on the three OSes in CI, so the SVGs can be compared byte for byte after renumbering ids and rounding to two decimals.

## 2026-09-24 — Headless against Chrome

Hypotheses written and committed first (`284eb7e`). Then the same five files through the browser bundle in headless Chrome 153, reading every `<text>` back ([`browser/`](https://github.com/spareilleux/learn/tree/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/browser)).

The first run gave a gap of 204 px on the logo and garbage glyphs: the test page had no `<meta charset="utf-8">`, Chrome decoded the bundle as Windows-1252, and every SMuFL code point in it became mojibake. A measurement error, not a result. The second run was off by one element on `l02-vibrato-mute`: `compare.mjs` skipped `<text>` elements without a `y` attribute, and VexFlow writes none when y is 0, which it is for the muted note's glyph. Fixed by reading each attribute separately, with a missing one as 0. The third run is the one in the table: 0.74 px at most, on the logo.

## 2026-09-24 — GA's VexTab, run

Blobless sparse clone of GA at `17ccee6`, nine files. The C# formatter compiles alone; the three F# files compile unchanged with FParsec 1.1.1 on .NET 10, as GA references it. Results in [lesson 4](../04-ga-chatbot-vextab/). What was expected going in: that the chatbot blocks might use an older VexTab dialect. What came out: they use no VexTab dialect, the client doesn't draw them, and GA's own parser rejects its own generator's output. VexTab, meanwhile, reads GA's generator output without trouble. Nothing sent to GA: the findings are in the report to the user, who decides.

## To verify

- Whether GA's `ga-client` Playwright specs run in GA's CI; if they do, `vextab-rendering.spec.ts` should fail on `not.toBeVisible()`. Not run here.
- The `eb` tuning in a browser: the value is in VexFlow's table and the headless drawing shows C♯3, but the browser comparison didn't include `l03-tuning`.
- Firefox and Safari: the browser comparison ran in headless Chrome on Windows only.
- Whether VexFlow 4, as GA uses it, has the `setFont` argument order that made VexTab's `italic` a style there: not checked, since the course pins VexFlow 5.

## Open questions

- Is the fret override by note-name annotations meant to apply to chords, or only to single notes? The code applies it to the lowest string of any note group.
- Should VexTab validate `strings=` to a number and pass the number? One `parseInt` already exists, a line above the one that forgets it.
