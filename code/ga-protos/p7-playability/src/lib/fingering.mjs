// The target this prototype tries to predict: the cost of the *best* left-hand fingering of a voicing.
//
// GA's cost never assigns fingers. It reads four summary numbers off the diagram (physical span, a barre flag,
// how many strings are open, how many distinct frets there are) and adds them up. This module does the opposite:
// it searches every legal way to put fingers 1 to 4 on the fretted notes, scores each one against a hand model,
// and returns the cheapest. That is the shape of the classic approach to guitar fingering — the "optimum path
// paradigm" of Sayegh (1989, doi:10.2307/3680014), the constraint search of Radicioni and Lombardo
// (2007, doi:10.1007/s10601-007-9015-y), and the biomechanical reading of difficulty in Heijink and
// Meulenbroek (2002, doi:10.1080/00222890209601952).
//
// HONESTY. This is not ground truth and no guitarist calibrated it. The geometry is GA's own
// (equal-temperament fret spacing, 648 mm scale, 43/52 mm nut and bridge), but every weight below is a constant
// I chose, listed here so that a reader can disagree with a number rather than with a black box. What makes it
// a defensible *target* is that it is a different kind of object from the thing being tested: an expensive
// combinatorial search over an explicit hand model, not a closed-form sum of four flags. results/annotations.json
// checks its ordering against a small, fully disclosed set of hand-ranked pairs of canonical shapes.

import { notePointMm, layout } from './voicing.mjs';

// Comfortable distance between two fingers, in millimetres, before a stretch starts to cost anything.
// Ordered by anatomy: index-to-middle spreads further than ring-to-little, and every gap that skips a
// finger inherits the sum of the gaps it spans.
export const COMFORT_MM = {
  '1-2': 42,
  '1-3': 66,
  '1-4': 86,
  '2-3': 34,
  '2-4': 58,
  '3-4': 30,
};

export const WEIGHTS = {
  perFinger: 0.15, // each finger you have to place costs a little
  perMmOverStretch: 0.06, // beyond the comfortable distance, per millimetre
  sameFretPair: 0.25, // two fingers crowded on one fret
  pinky: 0.2, // finger 4 is the weakest
  barreBase: 1.0, // holding several strings with one finger at all
  barrePerExtraString: 0.35, // and per extra string it has to hold down
  barreLowPosition: 0.8, // a barre on fret 1 or 2, where the frets are widest and the string tension highest
  barreWeakFinger: 0.6, // a barre with the ring finger or the little finger, not the index
  mutedInside: 0.9, // a muted string between two sounding ones has to be damped
  mutedUnderBarre: 0.8, // and a muted string under a barre has to be damped against the barre
  highPosition: 0.5, // above fret 15 the body of the guitar gets in the way
  maxCost: 12, // the cost of an unplayable voicing, for the rows that keep one
};

function pairKey(a, b) {
  return a < b ? `${a}-${b}` : `${b}-${a}`;
}

// Distance from a point to a segment: a barre is a segment across the strings, and what matters for the next
// finger is the nearest part of it.
function pointToSpan(point, span) {
  if (span.length === 1) return Math.hypot(point.x - span[0].x, point.y - span[0].y);
  const [p, q] = [span[0], span[span.length - 1]];
  const dx = q.x - p.x;
  const dy = q.y - p.y;
  const len2 = dx * dx + dy * dy;
  const t = len2 === 0 ? 0 : Math.max(0, Math.min(1, ((point.x - p.x) * dx + (point.y - p.y) * dy) / len2));
  return Math.hypot(point.x - (p.x + t * dx), point.y - (p.y + t * dy));
}

function spanToSpan(a, b) {
  return Math.min(...a.map((p) => pointToSpan(p, b)), ...b.map((p) => pointToSpan(p, a)));
}

// The search itself.
//
// The notes are taken in fret order. Fingers are numbered 1 (index) to 4 (little finger) and their numbers have
// to follow the frets: everything the index finger holds sits at or below what the middle finger holds, and so
// on. Several notes at one fret may share a finger — that is a barre, full or partial, and any finger can make
// one, which is what a guitarist does with the ring finger in an A shape. A barre is impossible when a string
// between its ends is open, or sounds at a lower fret; a muted string under it has to be damped and costs extra.
//
// Nothing else is modelled: no thumb over the top, no open string damped by the fretting hand, no partial
// capo, no note held by two fingers. Those shapes come out either dearer than a guitarist would find them or,
// for the thumb, impossible.

function evaluateAssignment(notes, assign, frets, l, terms = null) {
  const fingers = new Map();
  for (let i = 0; i < notes.length; i++) {
    const f = assign[i];
    if (!fingers.has(f)) fingers.set(f, []);
    fingers.get(f).push(notes[i]);
  }
  const note = (label, amount) => {
    if (terms && amount) terms.push({ label, amount: Number(amount.toFixed(4)) });
  };

  let cost = WEIGHTS.perFinger * fingers.size;
  note(`${fingers.size} fingers`, WEIGHTS.perFinger * fingers.size);
  if (fingers.has(4)) cost += WEIGHTS.pinky;
  if (fingers.has(4)) note('the little finger is used', WEIGHTS.pinky);

  const placements = new Map();
  for (const [finger, held] of fingers) {
    const fret = held[0].fret;
    if (held.length > 1) {
      const lo = Math.min(...held.map((n) => n.string));
      const hi = Math.max(...held.map((n) => n.string));
      let mutedUnder = 0;
      for (let s = lo + 1; s < hi; s++) {
        if (frets[s] === 0) return null; // the barre would fret an open string
        if (frets[s] > 0 && frets[s] < fret) return null; // and it cannot pass under a lower note
        if (frets[s] < 0) mutedUnder++;
      }
      cost += WEIGHTS.barreBase + WEIGHTS.barrePerExtraString * (held.length - 1);
      note(`finger ${finger} holds ${held.length} strings at fret ${fret}`, WEIGHTS.barreBase + WEIGHTS.barrePerExtraString * (held.length - 1));
      if (fret <= 2) {
        cost += WEIGHTS.barreLowPosition;
        note('that barre is on fret 1 or 2', WEIGHTS.barreLowPosition);
      }
      if (finger >= 3) {
        cost += WEIGHTS.barreWeakFinger;
        note(`and finger ${finger} is making it`, WEIGHTS.barreWeakFinger);
      }
      cost += WEIGHTS.mutedUnderBarre * mutedUnder;
      note(`${mutedUnder} muted string(s) under the barre`, WEIGHTS.mutedUnderBarre * mutedUnder);
    }
    placements.set(finger, { fret, points: held.map((n) => notePointMm(n.string, n.fret)) });
  }

  const used = [...placements.keys()].sort((a, b) => a - b);
  for (let i = 0; i < used.length; i++) {
    for (let j = i + 1; j < used.length; j++) {
      const a = placements.get(used[i]);
      const b = placements.get(used[j]);
      const d = spanToSpan(a.points, b.points);
      const comfort = COMFORT_MM[pairKey(used[i], used[j])];
      if (d > comfort) {
        cost += WEIGHTS.perMmOverStretch * (d - comfort);
        note(
          `fingers ${used[i]} and ${used[j]} are ${d.toFixed(1)} mm apart, ${(d - comfort).toFixed(1)} mm over`,
          WEIGHTS.perMmOverStretch * (d - comfort),
        );
      }
      if (a.fret === b.fret) {
        cost += WEIGHTS.sameFretPair;
        note(`fingers ${used[i]} and ${used[j]} share fret ${a.fret}`, WEIGHTS.sameFretPair);
      }
    }
  }

  cost += WEIGHTS.mutedInside * l.innerMuted;
  note(`${l.innerMuted} muted string(s) inside the chord`, WEIGHTS.mutedInside * l.innerMuted);
  if (l.maxFret >= 15) {
    cost += WEIGHTS.highPosition;
    note('the shape sits above fret 15', WEIGHTS.highPosition);
  }
  return cost;
}

/**
 * The cheapest legal fingering of a voicing.
 * Returns { cost, feasible, fingering, barres, l }, where `fingering` gives the finger of each fretted note in
 * fret order and `barres` lists the fingers that hold more than one note.
 */
export function bestFingering(frets) {
  const l = layout(frets);
  const notes = [...l.fretted].sort((a, b) => a.fret - b.fret || a.string - b.string);
  const n = notes.length;
  if (n === 0) return { cost: 0, feasible: true, fingering: [], barres: [], notes, l };

  const assign = new Int8Array(n);
  const fingerFret = new Int8Array(5).fill(-1);
  let bestCost = Infinity;
  let bestAssign = null;

  const walk = (i, groupMin, groupMax) => {
    if (i === n) {
      const cost = evaluateAssignment(notes, assign, frets, l);
      if (cost !== null && cost < bestCost - 1e-12) {
        bestCost = cost;
        bestAssign = Int8Array.from(assign);
      }
      return;
    }
    let gMin = groupMin;
    let gMax = groupMax;
    if (i > 0 && notes[i].fret !== notes[i - 1].fret) {
      gMin = gMax + 1;
      gMax = 0;
    }
    if (gMin > 4) return;
    for (let finger = gMin; finger <= 4; finger++) {
      if (fingerFret[finger] !== -1 && fingerFret[finger] !== notes[i].fret) continue;
      const fresh = fingerFret[finger] === -1;
      fingerFret[finger] = notes[i].fret;
      assign[i] = finger;
      walk(i + 1, gMin, Math.max(gMax, finger));
      if (fresh) fingerFret[finger] = -1;
    }
  };
  walk(0, 1, 0);

  if (!bestAssign) return { cost: WEIGHTS.maxCost, feasible: false, fingering: null, barres: [], notes, l };

  const counts = new Map();
  for (const finger of bestAssign) counts.set(finger, (counts.get(finger) ?? 0) + 1);
  const barres = [...counts.entries()]
    .filter(([, held]) => held > 1)
    .map(([finger, held]) => ({
      finger,
      held,
      fret: notes[[...bestAssign].indexOf(finger)].fret,
    }));

  const terms = [];
  evaluateAssignment(notes, bestAssign, frets, l, terms);

  return {
    cost: Math.min(bestCost, WEIGHTS.maxCost),
    feasible: true,
    fingering: [...bestAssign],
    barres,
    terms,
    notes,
    l,
  };
}

export function fingeringCost(frets) {
  return bestFingering(frets).cost;
}
