import test from 'node:test';
import assert from 'node:assert/strict';
import {
  parseDiagram,
  formatDiagram,
  parseChart,
  chartName,
  midiNotes,
  fretPositionMm,
  fretDistanceMm,
  stringSpacingMm,
  shapeKey,
  pitchClassKey,
  layout,
} from '../src/lib/voicing.mjs';
import { gaPlayability, gaBarreRequired, gaCost } from '../src/lib/ga-cost.mjs';
import { features, FEATURE_NAMES } from '../src/lib/features.mjs';

test('a diagram survives a round trip, and a chart is the same shape backwards', () => {
  assert.deepEqual(parseDiagram('x-3-2-0-1-0'), [-1, 3, 2, 0, 1, 0]);
  assert.equal(formatDiagram([-1, 3, 2, 0, 1, 0]), 'x-3-2-0-1-0');
  assert.deepEqual(parseChart('x-3-2-0-1-0'), [0, 1, 0, 2, 3, -1]);
  assert.equal(chartName(parseChart('x-3-2-0-1-0')), 'x32010');
});

test('row 1000 of GA\'s index reads string 1 first', () => {
  // P1 pinned this row: diagram "1-2-x-5-x-1", MIDI notes 65, 61, 55, 41
  assert.deepEqual(midiNotes(parseDiagram('1-2-x-5-x-1')), [65, 61, 55, 41]);
});

test('the fret geometry is the equal-temperament formula GA uses', () => {
  assert.equal(fretPositionMm(0), 0);
  assert.ok(Math.abs(fretPositionMm(12) - 324) < 1e-9); // the twelfth fret is half the scale
  assert.ok(Math.abs(fretDistanceMm(1, 3) - (fretPositionMm(3) - fretPositionMm(1))) < 1e-12);
  assert.ok(stringSpacingMm(12) > stringSpacingMm(0)); // the strings spread towards the bridge
  assert.ok(Math.abs(stringSpacingMm(0) - 43 / 5) < 1e-9);
});

test('the shape key forgets the position but not the muted strings', () => {
  assert.equal(shapeKey(parseChart('1-3-3-2-1-1')), shapeKey(parseChart('5-7-7-6-5-5')));
  assert.notEqual(shapeKey(parseChart('1-3-3-2-1-1')), shapeKey(parseChart('x-3-3-2-1-1')));
  assert.equal(pitchClassKey([60, 64, 67, 72]), '0,4,7');
});

test('a muted string between two sounding ones is counted, one at the edge is not', () => {
  assert.equal(layout(parseChart('x-0-2-x-1-0')).innerMuted, 1);
  assert.equal(layout(parseChart('x-0-2-2-1-0')).innerMuted, 0);
  assert.equal(layout(parseChart('x-x-0-2-3-2')).innerMuted, 0);
});

test("GA's cost is the port of VoicingPhysicalAnalyzer.CalculatePlayability", () => {
  // Open C, x32010: no barre, three distinct frets, two open strings, a span of frets 1 to 3
  const c = gaPlayability(parseChart('x-3-2-0-1-0'));
  assert.equal(c.barreRequired, false);
  assert.equal(c.handStretch, 2);
  assert.equal(c.minimumFingers, 3);
  assert.ok(Math.abs(c.spanScore - fretDistanceMm(1, 3) / 80) < 1e-12);
  assert.ok(Math.abs(c.score - (1 + 3 * (fretDistanceMm(1, 3) / 80))) < 1e-12);
  // The "Beginner" band asks for a span of at most 64 mm; frets 1 to 3 already measure 66.7 mm, so GA calls
  // the first chord of every method book Intermediate
  assert.equal(c.difficulty, 'Intermediate');
  assert.equal(gaPlayability(parseChart('0-2-2-0-0-0')).difficulty, 'Beginner');
  // The score is clamped at 10
  assert.ok(gaCost(parseChart('1-x-x-x-x-15')) <= 10);
});

test("GA's barre rule needs three *adjacent* strings at one fret, so it misses the F barre", () => {
  // The A-shape barre has three adjacent strings at fret 3 under the index finger at fret 1
  assert.equal(gaBarreRequired(parseChart('x-1-3-3-3-1')), true);
  // The E-shape F barre holds strings 1, 2 and 6 at fret 1 — three strings, not three adjacent ones
  assert.equal(gaBarreRequired(parseChart('1-3-3-2-1-1')), false);
});

test('the feature vector has one name per column and no undefined value', () => {
  const f = features(parseChart('x-3-2-0-1-0'));
  assert.equal(f.length, FEATURE_NAMES.length);
  assert.ok(f.every((v) => Number.isFinite(v)));
  assert.equal(f[FEATURE_NAMES.indexOf('openCount')], 2);
  assert.equal(f[FEATURE_NAMES.indexOf('frettedCount')], 3);
  assert.equal(f[FEATURE_NAMES.indexOf('lowStringPlayed')], 0); // x32010 mutes the low E
  assert.equal(features(parseChart('x-0-2-x-1-0'))[FEATURE_NAMES.indexOf('stringSkips')], 1);
});
