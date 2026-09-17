import test from 'node:test';
import assert from 'node:assert/strict';
import { parseChart } from '../src/lib/voicing.mjs';
import { bestFingering, fingeringCost, WEIGHTS } from '../src/lib/fingering.mjs';
import { ruleCost } from '../src/lib/rules.mjs';

const cost = (chart) => fingeringCost(parseChart(chart));

test('the search finds a fingering for the shapes a method book teaches', () => {
  for (const chart of ['0-2-2-0-0-0', 'x-0-2-2-1-0', 'x-3-2-0-1-0', '3-2-0-0-0-3', 'x-x-0-2-3-2', '1-3-3-2-1-1']) {
    const best = bestFingering(parseChart(chart));
    assert.equal(best.feasible, true, chart);
    assert.ok(best.cost < WEIGHTS.maxCost, chart);
  }
});

test('the F barre is a barre, and the search says so even though GA\'s flag does not', () => {
  const best = bestFingering(parseChart('1-3-3-2-1-1'));
  assert.equal(best.barres.length, 1, 'one finger holds several strings');
  assert.equal(best.barres[0].finger, 1, 'and it is the index finger');
  assert.equal(best.barres[0].fret, 1);
  assert.equal(best.barres[0].held, 3);
  // Three of the six notes sit at fret 1 and the index finger takes all three; the other three take a finger each
  assert.equal(best.fingering.filter((f) => f === 1).length, 3);
  assert.equal(new Set(best.fingering).size, 4);
});

test('open chords cost less than the barre chords of the same name', () => {
  assert.ok(cost('0-2-2-0-0-0') < cost('1-3-3-2-1-1'));
  assert.ok(cost('x-0-2-2-1-0') < cost('x-2-4-4-3-2'));
  assert.ok(cost('x-3-2-0-1-0') < cost('x-3-5-5-5-3'));
});

test('lifting a finger off makes a shape cheaper', () => {
  assert.ok(cost('x-0-2-0-2-0') < cost('x-0-2-2-2-0')); // A7 against A
  assert.ok(cost('0-2-0-1-0-0') < cost('0-2-2-1-0-0')); // E7 against E
  assert.ok(cost('x-3-2-0-0-0') < cost('x-3-2-0-1-0')); // Cmaj7 against C
});

test('the same grip is dearer at the first fret than up the neck', () => {
  assert.ok(cost('1-3-3-2-1-1') > cost('5-7-7-6-5-5'));
  assert.ok(cost('1-3-3-2-1-1') > cost('8-10-10-9-8-8'));
});

test('a wider stretch costs more, and six notes on six different frets cannot be played', () => {
  assert.ok(cost('x-x-7-9-8-11') > cost('x-x-7-9-8-9'));
  const impossible = bestFingering(parseChart('1-3-5-7-9-11'));
  assert.equal(impossible.feasible, false);
  assert.equal(impossible.cost, WEIGHTS.maxCost);
});

test('a muted string inside the chord costs more than the same chord without it', () => {
  assert.ok(cost('x-0-2-x-1-0') > cost('x-0-2-2-1-0'));
  assert.ok(ruleCost(parseChart('x-0-2-x-1-0')) > ruleCost(parseChart('x-0-2-2-1-0')));
});

test('the search is deterministic', () => {
  const a = bestFingering(parseChart('x-2-1-2-0-2'));
  const b = bestFingering(parseChart('x-2-1-2-0-2'));
  assert.equal(a.cost, b.cost);
  assert.deepEqual(a.fingering, b.fingering);
});
