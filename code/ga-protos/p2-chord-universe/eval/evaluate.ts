// Evaluates the chord recognizer on the synthetic corpus, with the same DSP code as the browser app.
//
//   node eval/evaluate.ts              run everything, print the tables, write eval/results.json
//   node eval/evaluate.ts --check      run everything and compare with the committed eval/results.json, ignoring the
//                                      timings (fields ending in Ms) and the machine
//   node eval/evaluate.ts --smoke 20   run the first 20 clips and print only timings (to check that the harness runs)
import { readFileSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import { performance } from 'node:perf_hooks';
import { DEFAULT_MATCH, QUALITIES, chordName, matchChord, pcsMask, pitchClasses, type Chord } from '../src/dsp/chords.ts';
import { ChromaExtractor, defaultChromaOptions, type ChromaOptions } from '../src/dsp/chroma.ts';
import { ChordTracker, DEFAULT_TRACKER, type TrackerOptions } from '../src/dsp/tracker.ts';
import { OPEN_MIDI, tab } from '../src/dsp/voicings.ts';
import { CONDITIONS, LEAD_SECONDS, SAMPLE_RATE, VOICING_KINDS, corpus, render } from './corpus.ts';

const HOP = 2048;

type Config = { name: string; chroma: ChromaOptions; tracker: TrackerOptions };
const base = defaultChromaOptions(SAMPLE_RATE);
const harmonic = { ...DEFAULT_TRACKER, match: { ...DEFAULT_MATCH, harmonicTemplates: true } };
const CONFIGS: Config[] = [
  { name: 'main: notes, binary templates, whitening, bass, tuning', chroma: base, tracker: DEFAULT_TRACKER },
  { name: 'notes, harmonic templates', chroma: base, tracker: harmonic },
  { name: 'peaks folded (classic chroma), harmonic templates', chroma: { ...base, notes: false }, tracker: harmonic },
  { name: 'peaks folded (classic chroma), binary templates', chroma: { ...base, notes: false }, tracker: DEFAULT_TRACKER },
  { name: 'no whitening', chroma: { ...base, whitening: false }, tracker: DEFAULT_TRACKER },
  { name: 'no bass term', chroma: base, tracker: { ...DEFAULT_TRACKER, match: { ...DEFAULT_MATCH, bassWeight: 0 } } },
  { name: 'no tuning correction', chroma: { ...base, tuning: false }, tracker: DEFAULT_TRACKER },
];

type Tally = { clips: number; exact: number; root: number; quality: number; sameSet: number; top3: number };
const tally = (): Tally => ({ clips: 0, exact: 0, root: 0, quality: 0, sameSet: 0, top3: 0 });
const pct = (n: number, d: number): number => (d === 0 ? 0 : Math.round((1000 * n) / d) / 10);

type ConfigResult = {
  name: string;
  overall: Tally;
  byCondition: Record<string, Tally>;
  byVoicing: Record<string, Tally>;
  byQuality: Record<string, Tally>;
  frames: { total: number; afterStrum: number; exactAfterStrum: number };
  detectionMedianMs: number;
  computeMedianMs: number;
  computeP95Ms: number;
  confusion: number[][];
  mistakes: Record<string, number>;
};

function add(t: Tally, truth: Chord, predicted: Chord | null, top: string[]) {
  t.clips++;
  if (!predicted) return;
  if (predicted.root === truth.root && predicted.quality === truth.quality) t.exact++;
  if (predicted.root === truth.root) t.root++;
  if (predicted.quality === truth.quality) t.quality++;
  if (pcsMask(pitchClasses(predicted)) === pcsMask(pitchClasses(truth))) t.sameSet++;
  if (top.includes(chordName(truth))) t.top3++;
}

const median = (xs: number[]): number => {
  if (xs.length === 0) return NaN;
  const s = [...xs].sort((a, b) => a - b);
  return s[s.length >> 1];
};
const quantile = (xs: number[], q: number): number => [...xs].sort((a, b) => a - b)[Math.min(xs.length - 1, Math.floor(q * xs.length))];

function newResult(name: string): ConfigResult {
  return {
    name,
    overall: tally(),
    byCondition: Object.fromEntries(CONDITIONS.map((c) => [c, tally()])),
    byVoicing: Object.fromEntries([...VOICING_KINDS, 'root position (all)', 'inversion (actual bass)'].map((c) => [c, tally()])),
    byQuality: Object.fromEntries(QUALITIES.map((q) => [q.symbol || 'maj', tally()])),
    frames: { total: 0, afterStrum: 0, exactAfterStrum: 0 },
    detectionMedianMs: 0,
    computeMedianMs: 0,
    computeP95Ms: 0,
    // Rows: true quality; columns: predicted quality, then "none"
    confusion: QUALITIES.map(() => new Array<number>(QUALITIES.length + 1).fill(0)),
    mistakes: {},
  };
}

const args = process.argv.slice(2);
const smoke = args.includes('--smoke') ? Number(args[args.indexOf('--smoke') + 1] ?? 20) : 0;
const check = args.includes('--check');

const results = CONFIGS.map((c) => newResult(c.name));
const detections: number[][] = CONFIGS.map(() => []);
const computeTimes: number[][] = CONFIGS.map(() => []);
const oracle = tally();
const started = performance.now();
let clipCount = 0;

for (const clip of corpus(smoke || Infinity)) {
  clipCount++;
  const samples = render(clip);
  // Oracle: the voicing's exact pitch classes (weighted by how many strings play each) and its bass, straight into the
  // matcher. What it gets wrong, no signal processing can get right with these templates.
  const ideal = new Float64Array(12);
  clip.voicing.frets.forEach((f, s) => f >= 0 && (ideal[(OPEN_MIDI[s] + f) % 12] += 1));
  const idealBass = new Float64Array(12);
  idealBass[clip.voicing.bassPc] = 1;
  const idealTop = matchChord(ideal, idealBass, { ...DEFAULT_MATCH, harmonicTemplates: false });
  add(oracle, clip.chord, idealTop[0].chord, idealTop.slice(0, 3).map((c) => c.name));

  CONFIGS.forEach((config, ci) => {
    const extractor = new ChromaExtractor(config.chroma);
    const tracker = new ChordTracker(config.tracker);
    const r = results[ci];
    let last: ReturnType<ChordTracker['push']> | null = null;
    let detected = -1;
    for (let start = 0; start + config.chroma.frameSize <= samples.length; start += HOP) {
      const t0 = performance.now();
      const state = tracker.push(extractor.process(samples, start));
      computeTimes[ci].push(performance.now() - t0);
      last = state;
      r.frames.total++;
      if (start >= LEAD_SECONDS * SAMPLE_RATE) {
        r.frames.afterStrum++;
        const ok = state.stable && state.stable.chord.root === clip.chord.root && state.stable.chord.quality === clip.chord.quality;
        if (ok) r.frames.exactAfterStrum++;
      }
      const okAny = state.stable && state.stable.chord.root === clip.chord.root && state.stable.chord.quality === clip.chord.quality;
      if (okAny && detected < 0) detected = ((start + config.chroma.frameSize) / SAMPLE_RATE - LEAD_SECONDS) * 1000;
    }
    if (detected >= 0) detections[ci].push(detected);
    const predicted = last?.stable?.chord ?? null;
    const top = last ? last.top.map((c) => c.name) : [];
    add(r.overall, clip.chord, predicted, top);
    add(r.byCondition[clip.condition], clip.chord, predicted, top);
    add(r.byVoicing[clip.kind], clip.chord, predicted, top);
    add(r.byVoicing[clip.voicing.inversion ? 'inversion (actual bass)' : 'root position (all)'], clip.chord, predicted, top);
    add(r.byQuality[QUALITIES[clip.chord.quality].symbol || 'maj'], clip.chord, predicted, top);
    r.confusion[clip.chord.quality][predicted ? predicted.quality : QUALITIES.length]++;
    if (!predicted || predicted.root !== clip.chord.root || predicted.quality !== clip.chord.quality) {
      // Mistakes by shape: true quality -> predicted quality, with the predicted root relative to the true root
      const key = predicted
        ? `${QUALITIES[clip.chord.quality].symbol || 'maj'} -> ${QUALITIES[predicted.quality].symbol || 'maj'} (root +${(predicted.root - clip.chord.root + 12) % 12})`
        : `${QUALITIES[clip.chord.quality].symbol || 'maj'} -> none`;
      r.mistakes[key] = (r.mistakes[key] ?? 0) + 1;
    }
    if (ci === 0 && process.env.P2_VERBOSE) console.log(clip.id, chordName(clip.chord), tab(clip.voicing), clip.condition, '->', last?.stable?.name ?? 'none', last?.top.map((c) => `${c.name}:${c.probability.toFixed(2)}`).join(' '));
  });
}

results.forEach((r, ci) => {
  r.detectionMedianMs = Math.round(median(detections[ci]));
  r.computeMedianMs = Math.round(median(computeTimes[ci]) * 1000) / 1000;
  r.computeP95Ms = Math.round(quantile(computeTimes[ci], 0.95) * 1000) / 1000;
  r.mistakes = Object.fromEntries(Object.entries(r.mistakes).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0])));
});
const elapsedMs = Math.round(performance.now() - started);

if (smoke) {
  console.log(`smoke: ${clipCount} clips x ${CONFIGS.length} configurations in ${elapsedMs} ms; per frame median ${results[0].computeMedianMs} ms, p95 ${results[0].computeP95Ms} ms`);
  process.exit(0);
}

const output = {
  corpus: { clips: clipCount, sampleRate: SAMPLE_RATE, frameSize: base.frameSize, hop: HOP, qualities: QUALITIES.map((q) => q.symbol || 'maj') },
  oracle,
  configs: results,
  machine: { node: process.version, platform: `${os.platform()} ${os.arch()}`, cpu: os.cpus()[0]?.model.trim(), elapsedMs },
};

// Tables
const row = (name: string, t: Tally) =>
  `| ${name} | ${t.clips} | ${pct(t.exact, t.clips)} | ${pct(t.root, t.clips)} | ${pct(t.quality, t.clips)} | ${pct(t.sameSet, t.clips)} | ${pct(t.top3, t.clips)} |`;
const header = '| | clips | exact % | root % | quality % | same pitch-class set % | truth in top 3 % |\n|---|---|---|---|---|---|---|';
console.log(`Corpus: ${clipCount} clips, ${SAMPLE_RATE} Hz, frames of ${base.frameSize} samples every ${HOP}\n`);
console.log(header);
console.log(row('oracle (ideal chroma and bass)', oracle));
for (const r of results) console.log(row(r.name, r.overall));
const main = results[0];
console.log(`\nMain configuration by condition\n\n${header}`);
for (const [k, t] of Object.entries(main.byCondition)) console.log(row(k, t));
console.log(`\nMain configuration by voicing\n\n${header}`);
for (const [k, t] of Object.entries(main.byVoicing)) console.log(row(k, t));
console.log(`\nMain configuration by quality\n\n${header}`);
for (const [k, t] of Object.entries(main.byQuality)) console.log(row(k, t));
const names = QUALITIES.map((q) => q.symbol || 'maj');
console.log(`\nConfusion matrix of qualities (rows: truth, columns: prediction)\n`);
console.log(`| truth \\ predicted | ${[...names, 'none'].join(' | ')} |`);
console.log(`|---|${[...names, 'none'].map(() => '---').join('|')}|`);
main.confusion.forEach((line, i) => console.log(`| ${names[i]} | ${line.join(' | ')} |`));
console.log(`\nMost frequent mistakes (main)\n`);
for (const [k, n] of Object.entries(main.mistakes).slice(0, 12)) console.log(`${n.toString().padStart(4)}  ${k}`);
console.log(`\nFrames after the strum with the exact stable label: ${pct(main.frames.exactAfterStrum, main.frames.afterStrum)} %`);
console.log(`Median detection time after the strum (audio time): ${main.detectionMedianMs} ms`);
console.log(`Compute per frame (FFT to label), median ${main.computeMedianMs} ms, p95 ${main.computeP95Ms} ms`);
console.log(`Total ${elapsedMs} ms`);

const path = new URL('./results.json', import.meta.url);
if (check) {
  const strip = (value: unknown): unknown =>
    JSON.parse(JSON.stringify(value, (key, v) => (key.endsWith('Ms') || key === 'machine' ? undefined : v)));
  const committed = strip(JSON.parse(readFileSync(path, 'utf8')));
  const now = strip(output);
  if (JSON.stringify(committed) !== JSON.stringify(now)) {
    console.error('\nThe accuracy figures differ from the committed eval/results.json');
    process.exit(1);
  }
  console.log('\nSame figures as the committed eval/results.json (timings not compared)');
} else {
  writeFileSync(path, JSON.stringify(output, null, 2) + '\n');
}
