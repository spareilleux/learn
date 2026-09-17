// The target this prototype tries to predict: the cost of the *best* left-hand fingering of a voicing.
//
// GA's cost never assigns fingers. It reads four summary numbers off the diagram (physical span, a barre flag,
// how many strings are open, how many distinct frets there are) and adds them up. This module does the opposite:
// it searches every legal way to put fingers 1 to 4 on the fretted notes, scores each one against a hand model,
// and returns the cheapest. That is the shape of the classic approach to guitar fingering — the "optimum path
// paradigm" of Sayegh (1989), the constraint search of Radicioni and Lombardo (2005), and the biomechanical
// reading of difficulty in Heijink and Meulenbroek (2002).
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
  barreBase: 1.0, // pressing several strings with one finger at all
  barrePerExtraString: 0.35, // and per extra string it has to hold down
  barreLowPosition: 0.8, // a barre on fret 1 or 2, where the frets are widest and the string tension highest
  mutedInside: 0.9, // a muted string between two sounding ones has to be damped
  mutedUnderBarre: 0.8, // and a muted string under the barre has to be damped against the barre
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

// placements: a map from finger number (1-4) to { fret, points: [ {x, y} ], barred: n }
function scorePlacement(placements, l, barreInfo) {
  const fingers = Object.keys(placements).map(Number).sort();
  let cost = WEIGHTS.perFinger * fingers.length;
  if (placements[4]) cost += WEIGHTS.pinky;

  for (let i = 0; i < fingers.length; i++) {
    for (let j = i + 1; j < fingers.length; j++) {
      const a = placements[fingers[i]];
      const b = placements[fingers[j]];
      const d = spanToSpan(a.points, b.points);
      const comfort = COMFORT_MM[pairKey(fingers[i], fingers[j])];
      if (d > comfort) cost += WEIGHTS.perMmOverStretch * (d - comfort);
      if (a.fret === b.fret) cost += WEIGHTS.sameFretPair;
    }
  }

  if (barreInfo) {
    cost += WEIGHTS.barreBase + WEIGHTS.barrePerExtraString * (barreInfo.barred - 1);
    if (barreInfo.fret <= 2) cost += WEIGHTS.barreLowPosition;
    cost += WEIGHTS.mutedUnderBarre * barreInfo.mutedUnder;
  }

  cost += WEIGHTS.mutedInside * l.innerMuted;
  if (l.maxFret >= 15) cost += WEIGHTS.highPosition;
  return cost;
}

// Every way to give the notes distinct fingers out of `available`, with the fret order of the fingers respected:
// a lower-numbered finger never sits on a higher fret than a higher-numbered one.
function assignDistinct(notes, available, onAssignment) {
  const used = new Array(notes.length).fill(-1);
  const taken = new Set();
  const walk = (i) => {
    if (i === notes.length) {
      onAssignment(used.slice());
      return;
    }
    for (const finger of available) {
      if (taken.has(finger)) continue;
      let ok = true;
      for (let k = 0; k < i && ok; k++) {
        const other = used[k];
        if (other < finger && notes[k].fret > notes[i].fret) ok = false;
        if (other > finger && notes[k].fret < notes[i].fret) ok = false;
      }
      if (!ok) continue;
      taken.add(finger);
      used[i] = finger;
      walk(i + 1);
      taken.delete(finger);
      used[i] = -1;
    }
  };
  walk(0);
}

function pointsOf(notes) {
  return notes.map((n) => notePointMm(n.string, n.fret));
}

/**
 * The cheapest legal fingering of a voicing.
 * Returns { cost, feasible, fingering, barre } — fingering maps a note index to a finger, barre is null or
 * { fret, strings: [lowIndex, highIndex], barred }.
 */
export function bestFingering(frets) {
  const l = layout(frets);
  const notes = l.fretted;
  if (notes.length === 0) return { cost: WEIGHTS.perFinger * 0, feasible: true, fingering: [], barre: null, l };

  let best = null;

  const consider = (assignment, barreNotes, barreInfo) => {
    const placements = {};
    if (barreInfo) placements[1] = { fret: barreInfo.fret, points: pointsOf(barreNotes) };
    assignment.notes.forEach((n, i) => {
      const finger = assignment.fingers[i];
      placements[finger] = { fret: n.fret, points: [notePointMm(n.string, n.fret)] };
    });
    const cost = scorePlacement(placements, l, barreInfo);
    if (!best || cost < best.cost - 1e-12) {
      const fingering = new Array(notes.length).fill(0);
      if (barreInfo) barreNotes.forEach((n) => (fingering[notes.indexOf(n)] = 1));
      assignment.notes.forEach((n, i) => (fingering[notes.indexOf(n)] = assignment.fingers[i]));
      best = { cost, fingering, barre: barreInfo };
    }
  };

  // 1. No barre: every note gets its own finger
  if (notes.length <= 4) {
    assignDistinct(notes, [1, 2, 3, 4], (fingers) => consider({ notes, fingers }, null, null));
  }

  // 2. A barre: finger 1 holds every sounding note of one fret, across the strings they span
  const byFret = new Map();
  for (const n of notes) {
    if (!byFret.has(n.fret)) byFret.set(n.fret, []);
    byFret.get(n.fret).push(n);
  }
  for (const [fret, group] of byFret) {
    if (group.length < 2) continue;
    if (fret !== l.minFret) continue; // finger 1 is the lowest finger: a barre behind a lower note is impossible
    const lo = Math.min(...group.map((n) => n.string));
    const hi = Math.max(...group.map((n) => n.string));
    // An open string under the barre would be fretted by it: that shape cannot be played this way
    if (l.open.some((s) => s > lo && s < hi)) continue;
    const mutedUnder = l.muted.filter((s) => s > lo && s < hi).length;
    const rest = notes.filter((n) => !group.includes(n));
    if (rest.length > 3) continue;
    const barreInfo = { fret, strings: [lo, hi], barred: group.length, mutedUnder };
    assignDistinct(rest, [2, 3, 4], (fingers) => consider({ notes: rest, fingers }, group, barreInfo));
  }

  if (!best) return { cost: WEIGHTS.maxCost, feasible: false, fingering: null, barre: null, l };
  return { cost: Math.min(best.cost, WEIGHTS.maxCost), feasible: true, fingering: best.fingering, barre: best.barre, l };
}

export function fingeringCost(frets) {
  return bestFingering(frets).cost;
}
