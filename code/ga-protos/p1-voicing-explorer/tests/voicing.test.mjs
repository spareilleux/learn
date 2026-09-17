import assert from 'node:assert/strict';
import { test } from 'node:test';
import { baseFret, layout } from '../src/lib/diagram.mjs';
import { pluck, strum } from '../src/lib/synth.mjs';
import {
  chartName,
  familyOf,
  FAMILY_LIST,
  fretSpan,
  intervalClassVector,
  midiNotes,
  parseChordName,
  parseGaDiagram,
  tension,
  toChartOrder,
} from '../src/lib/voicing.mjs';

test("GA's index writes string 1, the high E, first", () => {
  // Row 1000 of GA's optick.index at 66bdd049: diagram "1-2-x-5-x-1", midiNotes [65, 61, 55, 41], "Gm7b5/F"
  const frets = parseGaDiagram('1-2-x-5-x-1');
  assert.deepEqual(midiNotes(frets), [65, 61, 55, 41]);
  // Read low E first, the same shape is the chart 1x5x21
  assert.equal(chartName(toChartOrder(frets)), '1x5x21');
});

test('open C is x32010 on a chord chart and 0-1-0-2-3-x in GA', () => {
  const ga = parseGaDiagram('0-1-0-2-3-x');
  assert.equal(chartName(toChartOrder(ga)), 'x32010');
  assert.deepEqual(midiNotes(ga), [64, 60, 55, 52, 48]);
});

test('the diagram draws low E on the left', () => {
  // Open C: the muted string must be the leftmost mark, the dot on fret 3 the second
  const l = layout(toChartOrder(parseGaDiagram('0-1-0-2-3-x')));
  assert.equal(l.marks[0].kind, 'muted');
  assert.equal(l.marks[1].kind, 'dot');
  assert.ok(l.marks[0].x < l.marks[5].x);
  assert.equal(l.base, 1);
});

test("GA's base-fret rule leaves a dot off the grid when the lowest fret is 2 and the span is 4", () => {
  const chart = [2, 4, 6, -1, -1, -1];
  assert.equal(baseFret(chart), 1);
  assert.equal(layout(chart).marks[2].kind, 'outside');
});

test('fret span ignores open and muted strings', () => {
  assert.equal(fretSpan(parseGaDiagram('12-11-10-12-13-11')), 3);
  assert.equal(fretSpan(parseGaDiagram('0-1-0-2-3-x')), 2);
});

test('interval-class vector and tension of a few chords', () => {
  assert.deepEqual(intervalClassVector([48, 52, 55]), [0, 0, 1, 1, 1, 0]); // C major
  assert.equal(tension([48, 52, 55]), 0);
  assert.deepEqual(intervalClassVector([55, 59, 62, 65]), [0, 1, 2, 1, 1, 1]); // G7
  assert.equal(tension([55, 59, 62, 65]), 2);
});

test('chord names split into root, suffix and bass', () => {
  assert.deepEqual(parseChordName('Gm7b5/F'), { root: 7, suffix: 'm7b5', bass: 5 });
  assert.deepEqual(parseChordName('Abmaj7'), { root: 8, suffix: 'maj7', bass: null });
  assert.equal(parseChordName('Forte 5-7 (pentachord)').root, null);
  assert.equal(parseChordName('C + Gb (Tritone)').root, null);
});

test('families', () => {
  const id = (name) => FAMILY_LIST[familyOf(name)].id;
  assert.equal(id('E'), 'major');
  assert.equal(id('C/E'), 'major');
  assert.equal(id('Am'), 'minor');
  assert.equal(id('F5'), 'power');
  assert.equal(id('Esus2'), 'sus');
  assert.equal(id('Emaj7'), 'maj7');
  assert.equal(id('G7'), 'dom7');
  assert.equal(id('Em(maj7)'), 'min7');
  assert.equal(id('Gm7b5/F'), 'half-dim');
  assert.equal(id('Bbadd11/Eb'), 'add');
  assert.equal(id('Forte 6-Z43 (hexachord)'), 'unnamed');
});

test('Karplus-Strong: one period of noise, decaying, deterministic', () => {
  const a = pluck(110, { sampleRate: 8000, seconds: 1 });
  assert.equal(a.length, 8000);
  assert.deepEqual(a, pluck(110, { sampleRate: 8000, seconds: 1 }));
  const rms = (from, to) => Math.sqrt(a.subarray(from, to).reduce((s, x) => s + x * x, 0) / (to - from));
  assert.ok(rms(7000, 8000) < rms(0, 1000) / 2, 'the string decays');
  const s = strum([40, 45, 50], { sampleRate: 8000, seconds: 0.5, strumMs: 10 });
  assert.equal(s.length, 4000 + 3 * 80);
});
