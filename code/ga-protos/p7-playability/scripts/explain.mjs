// One voicing, term by term: what GA's formula charges it, what the rule checklist charges it, and what the
// fingering search does with it. This is how the disagreements in the lesson were taken apart.
//
//   node scripts/explain.mjs 5-5-5-6-7-8 1-4-1-4-0-4
//
// Shapes are written low E first, the way a chord chart reads.

import { parseChart, chartName, formatDiagram, midiNotes, layout } from '../src/lib/voicing.mjs';
import { gaPlayability } from '../src/lib/ga-cost.mjs';
import { ruleScore } from '../src/lib/rules.mjs';
import { bestFingering } from '../src/lib/fingering.mjs';

const NOTE_NAMES = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
const STRINGS = ['high E', 'B', 'G', 'D', 'A', 'low E'];

const charts = process.argv.slice(2).filter((a) => !a.startsWith('--'));
if (!charts.length) {
  console.error('usage: explain.mjs <chart, low E first, dash separated> ...');
  process.exit(2);
}

for (const chart of charts) {
  const frets = parseChart(chart);
  const l = layout(frets);
  console.log(`\n=== ${chartName(frets)}   index diagram ${formatDiagram(frets)}`);
  console.log(
    `    notes: ${midiNotes(frets)
      .map((n) => `${NOTE_NAMES[n % 12]}${Math.floor(n / 12) - 1}`)
      .join(' ')}`,
  );
  console.log(
    `    ${l.fretted.length} fretted, ${l.open.length} open, ${l.muted.length} muted, frets ${l.minFret}-${l.maxFret} (${l.spanMm.toFixed(1)} mm), ${l.distinctFrets} distinct frets, ${l.innerMuted} muted inside`,
  );

  const ga = gaPlayability(frets);
  console.log(`\n  GA's difficulty score: ${ga.score.toFixed(3)} — "${ga.difficulty}"`);
  console.log(`    1.000  the base every voicing starts from`);
  if (ga.barreRequired) console.log(`    2.000  three adjacent strings share a fret`);
  console.log(`    ${(ga.spanScore * 3).toFixed(3)}  span of ${l.spanMm.toFixed(1)} mm / 80 x 3`);
  if (l.open.length === 0) console.log(`    1.000  no open string`);
  if (ga.minimumFingers === 4) console.log(`    1.000  four distinct frets`);

  const rules = ruleScore(frets);
  console.log(`\n  rule checklist: ${rules.score}`);
  for (const reason of rules.reasons) console.log(`    ${reason}`);

  const best = bestFingering(frets);
  console.log(`\n  fingering search: ${best.feasible ? best.cost.toFixed(3) : 'no legal fingering'}`);
  if (best.feasible) {
    for (let i = 0; i < best.notes.length; i++) {
      const n = best.notes[i];
      console.log(`    finger ${best.fingering[i]} on the ${STRINGS[n.string]} string, fret ${n.fret}`);
    }
    for (const t of best.terms) console.log(`    ${t.amount.toFixed(3).padStart(7)}  ${t.label}`);
  }
}
