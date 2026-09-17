// The pitch classes the bracelet is built from must still be GA's, and must still agree with what prototype 2 shows
// on screen. These run without a GA clone: they read the committed data/ga-sets.json and P2's own catalog.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { QUALITIES } from '../../p2-chord-universe/src/dsp/chords.ts';
import { GA_SHA, checkInvariants, crossCheckWithP2, noteToPitchClass, parseCatalog, parseScales, type GaSets } from '../scripts/ga-sets.ts';

const sets: GaSets = JSON.parse(readFileSync(new URL('../data/ga-sets.json', import.meta.url), 'utf8'));

test('the committed sets come from the pinned GA commit', () => {
  assert.equal(sets.gaSha, GA_SHA);
  assert.equal(sets.files.length, 2);
  for (const f of sets.files) assert.match(f.sha256, /^[0-9a-f]{64}$/);
});

test('every set GA gives is a usable pitch-class set', () => {
  assert.deepEqual(checkInvariants(sets), []);
});

test('the chord qualities agree with the ones prototype 2 already ported', () => {
  assert.deepEqual(crossCheckWithP2(sets.chords), []);
  assert.ok(sets.chords.length > QUALITIES.length);
});

test('the sets the lesson quotes', () => {
  const byId = new Map(sets.chords.map((c) => [c.id, c.intervals.join(' ')]));
  assert.equal(byId.get('major-triad'), '0 4 7');
  assert.equal(byId.get('diminished-7'), '0 3 6 9');
  assert.equal(byId.get('half-diminished-7'), '0 3 6 10');
  const scales = new Map(sets.scales.map((s) => [s.id, s.intervals.join(' ')]));
  assert.equal(scales.get('Major'), '0 2 4 5 7 9 11');
  assert.equal(scales.get('Minor.Natural'), '0 2 3 5 7 8 10');
});

test("A natural minor lights the same twelve positions as C major", () => {
  const major = sets.scales.find((s) => s.id === 'Major')!;
  const minor = sets.scales.find((s) => s.id === 'Minor.Natural')!;
  const lit = (root: number, intervals: number[]) => [...intervals.map((i) => (root + i) % 12)].sort((a, b) => a - b).join(' ');
  assert.equal(lit(major.root, major.intervals), lit(minor.root, minor.intervals));
});

test('note names are read the way GA writes them', () => {
  assert.equal(noteToPitchClass('C'), 0);
  assert.equal(noteToPitchClass('F#'), 6);
  assert.equal(noteToPitchClass('Gb'), 6);
  assert.equal(noteToPitchClass('Bb'), 10);
  assert.equal(noteToPitchClass('Bbb'), 9);
});

test('the parsers read GA syntax, not ours', () => {
  const catalog = 'new("x-triad", "major", "triad", [], [0, 4, 7], 3),\nnew("y", "minor", "7th", ["b5"], [0, 3, 6, 10], 6),';
  assert.deepEqual(parseCatalog(catalog), [
    { id: 'x-triad', intervals: [0, 4, 7], priority: 3 },
    { id: 'y', intervals: [0, 3, 6, 10], priority: 6 },
  ]);
  const scale = 'public static Scale Major => new("C D E F G A B");\npublic static class Minor\n{\npublic static Scale Natural => new("A B C D E F G");\n}';
  assert.deepEqual(parseScales(scale).map((s) => `${s.id} ${s.intervals.join(' ')}`), [
    'Major 0 2 4 5 7 9 11',
    'Minor.Natural 0 2 3 5 7 8 10',
  ]);
});
