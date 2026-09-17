// What the models are allowed to see: 21 numbers read off the diagram, all of them things a hand-written formula
// could also have used. None of them is a fingering, so the models never see the search they are asked to imitate.
//
// GA's own cost uses five of these: physicalSpanMm, barreAdjacent3, openCount, distinctFrets, and (through the
// clamp) nothing else. The rest is the room a model has to do better.

import { layout, fretPositionMm, pressPositionMm, stringSpacingMm } from './voicing.mjs';
import { gaBarreRequired } from './ga-cost.mjs';

export const FEATURE_NAMES = [
  'playedCount',
  'mutedCount',
  'openCount',
  'frettedCount',
  'minFret',
  'maxFret',
  'fretSpan',
  'physicalSpanMm',
  'distinctFrets',
  'barreAdjacent3',
  'maxAtMinFret',
  'innerMuted',
  'stringSkips',
  'maxNeighbourFretJump',
  'meanNeighbourFretJump',
  'lowStringPlayed',
  'highStringPlayed',
  'fingerSpreadMm',
  'diagonalMm',
  'meanPressMm',
  'minStringSpacingMm',
];

export function features(frets) {
  const l = layout(frets);
  const fretted = l.fretted;
  const values = fretted.map((n) => n.fret);

  const maxAtMinFret = values.length ? values.filter((f) => f === l.minFret).length : 0;

  // Gaps between played strings, and how far the frets jump from one played string to the next
  const playedSorted = [...l.played].sort((a, b) => a - b);
  let stringSkips = 0;
  for (let i = 1; i < playedSorted.length; i++) {
    const gap = playedSorted[i] - playedSorted[i - 1];
    if (gap > 1) stringSkips += gap - 1;
  }
  let maxJump = 0;
  let sumJump = 0;
  let jumps = 0;
  for (let i = 1; i < playedSorted.length; i++) {
    const a = frets[playedSorted[i - 1]];
    const b = frets[playedSorted[i]];
    const d = Math.abs(a - b);
    maxJump = Math.max(maxJump, d);
    sumJump += d;
    jumps++;
  }

  // The widest pair of fretted notes, measured on the neck, and the same distance split into its two axes
  let fingerSpread = 0;
  let diagonal = 0;
  for (let i = 0; i < fretted.length; i++) {
    for (let j = i + 1; j < fretted.length; j++) {
      const a = fretted[i];
      const b = fretted[j];
      const dx = Math.abs(pressPositionMm(a.fret) - pressPositionMm(b.fret));
      const dy = Math.abs(a.string - b.string) * stringSpacingMm(Math.min(a.fret, b.fret));
      fingerSpread = Math.max(fingerSpread, dx);
      diagonal = Math.max(diagonal, Math.hypot(dx, dy));
    }
  }

  const meanPress = fretted.length ? fretted.reduce((s, n) => s + pressPositionMm(n.fret), 0) / fretted.length : 0;

  return [
    l.played.length,
    l.muted.length,
    l.open.length,
    fretted.length,
    l.minFret,
    l.maxFret,
    l.span,
    fretPositionMm(l.maxFret) - fretPositionMm(l.minFret),
    l.distinctFrets,
    gaBarreRequired(frets) ? 1 : 0,
    maxAtMinFret,
    l.innerMuted,
    stringSkips,
    maxJump,
    jumps ? sumJump / jumps : 0,
    frets[5] >= 0 ? 1 : 0,
    frets[0] >= 0 ? 1 : 0,
    fingerSpread,
    diagonal,
    meanPress,
    stringSpacingMm(l.minFret),
  ];
}
