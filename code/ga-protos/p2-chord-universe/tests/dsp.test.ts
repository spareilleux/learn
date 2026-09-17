// Unit tests of the DSP building blocks, independent of the evaluation corpus: node --test tests/dsp.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { noteAt } from '../../../threejs/src/13-fretboard/guitar.ts';
import { NOTE_NAMES, QUALITIES, chordName, matchChord, pitchClasses } from '../src/dsp/chords.ts';
import { ChromaExtractor, defaultChromaOptions } from '../src/dsp/chroma.ts';
import { Fft } from '../src/dsp/fft.ts';
import { estimateKey, keyName, suggestNext } from '../src/dsp/harmony.ts';
import { pluck, rng, strum } from '../src/dsp/synth.ts';
import { ChordTracker } from '../src/dsp/tracker.ts';
import { OPEN_MIDI, tab, voicings } from '../src/dsp/voicings.ts';

const q = (symbol: string) => QUALITIES.findIndex((x) => x.symbol === symbol);

test('the FFT puts a sinusoid in its bin and keeps its energy (Parseval)', () => {
  const n = 1024;
  const fft = new Fft(n);
  const re = new Float64Array(n);
  const im = new Float64Array(n);
  let timeEnergy = 0;
  for (let i = 0; i < n; i++) {
    re[i] = Math.cos((2 * Math.PI * 100 * i) / n) + 0.25 * Math.sin((2 * Math.PI * 37 * i) / n);
    timeEnergy += re[i] * re[i];
  }
  fft.transform(re, im);
  const mag = Array.from(re, (r, i) => Math.hypot(r, im[i]));
  assert.equal(mag.slice(0, n / 2).indexOf(Math.max(...mag.slice(0, n / 2))), 100);
  assert.ok(Math.abs(mag[37] - (0.25 * n) / 2) < 1e-9);
  const freqEnergy = mag.reduce((s, m) => s + m * m, 0) / n;
  assert.ok(Math.abs(freqEnergy - timeEnergy) < 1e-9);
});

test('Karplus-Strong with the allpass is in tune within 3 cents, from 82 Hz to 1.3 kHz', () => {
  const sampleRate = 44100;
  for (const hz of [82.407, 440, 1318.51]) {
    const out = new Float64Array(65536);
    pluck(out, 0, sampleRate, hz, 1, rng(7));
    const re = Float64Array.from(out);
    const im = new Float64Array(out.length);
    new Fft(out.length).transform(re, im);
    // The strongest bin near the expected one, refined by parabolic interpolation
    const expected = Math.round((hz * out.length) / sampleRate);
    let k = expected;
    for (let j = expected - 3; j <= expected + 3; j++) if (Math.hypot(re[j], im[j]) > Math.hypot(re[k], im[k])) k = j;
    const [a, b, c] = [k - 1, k, k + 1].map((j) => Math.log(Math.hypot(re[j], im[j])));
    const measured = ((k + (0.5 * (a - c)) / (a - 2 * b + c)) * sampleRate) / out.length;
    const cents = 1200 * Math.log2(measured / hz);
    assert.ok(Math.abs(cents) < 3, `${hz} Hz measured ${measured.toFixed(2)} Hz (${cents.toFixed(2)} cents)`);
  }
});

test('with ideal chroma and the root in the bass, all 156 chords are recognized exactly', () => {
  for (let root = 0; root < 12; root++) {
    for (let quality = 0; quality < QUALITIES.length; quality++) {
      const chroma = new Float64Array(12);
      for (const pc of pitchClasses({ root, quality })) chroma[pc] = 1;
      const bass = new Float64Array(12);
      bass[root] = 1;
      for (const harmonicTemplates of [false]) {
        const top = matchChord(chroma, bass, { harmonicTemplates, harmonicDecay: 0.8, harmonics: 6, bassWeight: 0.08, temperature: 0.02 });
        assert.equal(top[0].name, chordName({ root, quality }));
      }
    }
  }
});

test('without a bass, identical pitch-class sets tie and GA priority decides: C6 is read as Am7', () => {
  const chroma = new Float64Array(12);
  for (const pc of pitchClasses({ root: 0, quality: q('6') })) chroma[pc] = 1;
  const top = matchChord(chroma, null);
  assert.equal(top[0].name, 'Am7');
  assert.equal(top[1].name, 'C6');
  assert.equal(top[0].score, top[1].score);
});

test('the guitar tuning agrees with the three.js course', () => {
  OPEN_MIDI.forEach((midi, s) => assert.equal(noteAt(s, 0), `${NOTE_NAMES[midi % 12]}${Math.floor(midi / 12) - 1}`));
});

test('the most common voicings are the open chords a guitarist expects', () => {
  const first = (root: number, symbol: string) => tab(voicings({ root, quality: q(symbol) })[0]);
  assert.equal(first(0, ''), 'x32010');
  assert.equal(first(9, 'm'), 'x02210');
  assert.equal(first(4, ''), '022100');
  assert.equal(first(2, ''), 'xx0232');
  assert.equal(first(4, 'm'), '022000');
});

test('a strummed open C major is tracked as C', () => {
  const sampleRate = 44100;
  const samples = strum(voicings({ root: 0, quality: 0 })[0], {
    sampleRate, seconds: 1, leadSeconds: 0.05, strumMs: 15, detuneCents: 0, stringDetuneCents: 0, snrDb: Infinity, seed: 3,
  });
  const extractor = new ChromaExtractor(defaultChromaOptions(sampleRate));
  const tracker = new ChordTracker();
  let last = null;
  for (let start = 0; start + 8192 <= samples.length; start += 2048) last = tracker.push(extractor.process(samples, start));
  assert.equal(last?.stable?.name, 'C');
});

test('key and next chord follow GA: C Am F G7 is in C major, and G7 goes to Cmaj7', () => {
  const history = [
    { root: 0, quality: q('') },
    { root: 9, quality: q('m') },
    { root: 5, quality: q('') },
    { root: 7, quality: q('7') },
  ];
  const key = estimateKey(history)!.key;
  assert.equal(keyName(key), 'C major');
  const next = suggestNext(history[3], key);
  assert.deepEqual(next.map((s) => s.name), ['Cmaj7', 'Am7']);
  assert.match(next[0].reason, /circle of fifths, V to I/);
});
