// A third opinion: a checklist of the difficulty rules guitar method books state in words, turned into points.
//
// It exists to answer one question — do GA's cost and the fingering search agree with something neither of them
// is? It is not a target and nothing is trained on it. The rules are the ones a beginner's method repeats:
// barre chords are the wall; a stretch of more than three frets is hard; muting a string in the middle of the
// chord is hard; skipping strings is hard; using all four fingers is hard; a chord with no open string has
// nothing to lean on. The points are round numbers I chose; the ordering of the rules is the claim, not the values.

import { layout } from './voicing.mjs';
import { gaBarreRequired } from './ga-cost.mjs';

export function ruleScore(frets) {
  const l = layout(frets);
  const reasons = [];
  let score = 0;
  const add = (points, why) => {
    score += points;
    reasons.push(`${why} (+${points})`);
  };

  if (!l.fretted.length) return { score: 0, reasons: ['nothing is fretted (+0)'] };

  const barre = gaBarreRequired(frets);
  if (barre) {
    add(3, 'a barre holds three adjacent strings at one fret');
    const barreFret = l.minFret;
    if (barreFret <= 2) add(1, 'the barre is on fret 1 or 2, where the frets are widest');
  }
  if (l.span >= 4) add(3, 'the stretch is four frets or more');
  else if (l.span === 3) add(1.5, 'the stretch is three frets');
  if (l.innerMuted > 0) add(1 * l.innerMuted, `${l.innerMuted} muted string(s) inside the chord`);
  if (l.distinctFrets >= 4) add(1, 'four different frets: every finger is busy');
  if (l.open.length === 0) add(1, 'no open string');
  if (l.minFret === 1 && l.span >= 2) add(0.5, 'the shape sits on the first fret');
  return { score, reasons };
}

export function ruleCost(frets) {
  return ruleScore(frets).score;
}
