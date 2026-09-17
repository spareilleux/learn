// The dataset CI uses: the same pipeline, without GA's 183 MB index. It enumerates the voicings of a fixed list
// of chords directly on the fretboard, so a runner needs nothing but Node.js, and the whole job stays under a
// minute. The numbers it produces are not the published ones; they only prove the code runs the same way
// everywhere and that the models still beat the trivial baseline on a small sample.

import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { GUITAR_TUNING, formatDiagram, midiNotes, shapeKey, pitchClassKey, layout } from '../src/lib/voicing.mjs';
import { gaCost } from '../src/lib/ga-cost.mjs';
import { ruleCost } from '../src/lib/rules.mjs';
import { bestFingering } from '../src/lib/fingering.mjs';
import { mulberry32, shuffle } from '../src/lib/random.mjs';

function arg(name, fallback = null) {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? fallback : process.argv[i + 1];
}

const outPath = arg('out', 'out/synthetic.jsonl');
const perChord = Number(arg('per-chord', '40'));
const maxFret = Number(arg('max-fret', '12'));
const seed = Number(arg('seed', '99'));

// Intervals from the root, as a chord generator would write them
const QUALITIES = {
  maj: [0, 4, 7],
  min: [0, 3, 7],
  dom7: [0, 4, 7, 10],
  min7: [0, 3, 7, 10],
  maj7: [0, 4, 7, 11],
  dim: [0, 3, 6],
};

mkdirSync(dirname(outPath), { recursive: true });
const rng = mulberry32(seed);
const lines = [];

for (let root = 0; root < 12; root++) {
  for (const [name, intervals] of Object.entries(QUALITIES)) {
    const pcs = new Set(intervals.map((i) => (root + i) % 12));
    // For each string, the frets that give a note of the chord, plus "muted"
    const choices = GUITAR_TUNING.map((open) => {
      const options = [-1];
      for (let f = 0; f <= maxFret; f++) if (pcs.has((open + f) % 12)) options.push(f);
      return options;
    });
    const found = [];
    const walk = (s, frets) => {
      if (found.length > 4000) return;
      if (s === 6) {
        const l = layout(frets);
        if (l.played.length < 3 || !l.fretted.length) return;
        if (l.span > 5) return;
        const notes = midiNotes(frets);
        if (new Set(notes.map((n) => n % 12)).size !== pcs.size) return;
        found.push([...frets]);
        return;
      }
      for (const f of choices[s]) walk(s + 1, [...frets, f]);
    };
    walk(0, []);
    shuffle(found, rng);
    for (const frets of found.slice(0, perChord)) {
      const best = bestFingering(frets);
      lines.push(
        JSON.stringify({
          d: formatDiagram(frets),
          q: `${root}:${name}`,
          c: pitchClassKey(midiNotes(frets)),
          s: shapeKey(frets),
          t: Number(best.cost.toFixed(6)),
          g: Number(gaCost(frets).toFixed(6)),
          r: ruleCost(frets),
          f: best.feasible ? 1 : 0,
        }),
      );
    }
  }
}

writeFileSync(outPath, `${lines.join('\n')}\n`);
console.log(`${outPath}: ${lines.length} voicings, ${Object.keys(QUALITIES).length * 12} chords`);
