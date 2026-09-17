// Evaluates the main configuration on the recorded corpus: 17 CC0 recordings from Freesound (eval/recorded/sources.json),
// decoded by scripts/decode-recorded.ts into out/recorded/*.f32.
//
//   node eval/recorded.ts           print the table, write eval/recorded-results.json
//   node eval/recorded.ts --check   compare with the committed file (labels and counts, not timings)
//
// A recording is not a single strum: some repeat a pattern, one starts with a percussive hit, one is a pad. So the
// clip's label is the stable label that holds for the most frames, not the last one.
import { readFileSync, writeFileSync } from 'node:fs';
import { QUALITIES, NOTE_NAMES, chordName, pcsMask, pitchClasses, type Chord } from '../src/dsp/chords.ts';
import { ChromaExtractor, defaultChromaOptions } from '../src/dsp/chroma.ts';
import { ChordTracker } from '../src/dsp/tracker.ts';

const RATE = 44100;
const HOP = 2048;
type Source = { id: string; label: string; title: string; author: string };
const sources = JSON.parse(readFileSync(new URL('./recorded/sources.json', import.meta.url), 'utf8')) as Source[];

function parse(label: string): Chord {
  const m = /^([A-G]#?)(.*)$/.exec(label)!;
  const quality = QUALITIES.findIndex((q) => q.symbol === m[2]);
  if (quality < 0) throw new Error(`unknown quality in ${label}`);
  return { root: NOTE_NAMES.indexOf(m[1] as (typeof NOTE_NAMES)[number]), quality };
}

const rows = [];
let exact = 0;
let root = 0;
let quality = 0;
let sameSet = 0;
for (const source of sources) {
  const bytes = readFileSync(new URL(`../out/recorded/${source.id}.f32`, import.meta.url));
  const samples = new Float32Array(bytes.buffer, bytes.byteOffset, bytes.byteLength / 4);
  const extractor = new ChromaExtractor(defaultChromaOptions(RATE));
  const tracker = new ChordTracker();
  const votes = new Map<string, { chord: Chord; frames: number }>();
  let frames = 0;
  for (let start = 0; start + 8192 <= samples.length; start += HOP) {
    const state = tracker.push(extractor.process(samples, start));
    frames++;
    if (!state.stable) continue;
    const vote = votes.get(state.stable.name) ?? { chord: state.stable.chord, frames: 0 };
    vote.frames++;
    votes.set(state.stable.name, vote);
  }
  const ranked = [...votes.entries()].sort((a, b) => b[1].frames - a[1].frames || a[0].localeCompare(b[0]));
  const truth = parse(source.label);
  const predicted = ranked[0]?.[1].chord ?? null;
  const ok = {
    exact: !!predicted && predicted.root === truth.root && predicted.quality === truth.quality,
    root: !!predicted && predicted.root === truth.root,
    quality: !!predicted && predicted.quality === truth.quality,
    sameSet: !!predicted && pcsMask(pitchClasses(predicted)) === pcsMask(pitchClasses(truth)),
  };
  exact += +ok.exact;
  root += +ok.root;
  quality += +ok.quality;
  sameSet += +ok.sameSet;
  rows.push({
    id: source.id,
    label: source.label,
    predicted: predicted ? chordName(predicted) : 'none',
    ...ok,
    frames,
    // The three labels that held longest, with their share of the frames
    labels: ranked.slice(0, 3).map(([name, v]) => `${name} ${Math.round((100 * v.frames) / frames)}%`),
  });
}

const output = { clips: sources.length, exact, root, quality, sameSet, rows };
console.log('| id | label | predicted | longest-held labels (share of frames) |\n|---|---|---|---|');
for (const r of rows) console.log(`| ${r.id} | ${r.label} | ${r.predicted}${r.exact ? '' : ' ✗'} | ${r.labels.join(', ')} |`);
console.log(`\nexact ${exact} of ${sources.length}, root ${root}, quality ${quality}, same pitch-class set ${sameSet}`);
const path = new URL('./recorded-results.json', import.meta.url);
if (process.argv.includes('--check')) {
  if (readFileSync(path, 'utf8') !== JSON.stringify(output, null, 2) + '\n') {
    console.error('The recorded-corpus figures differ from the committed eval/recorded-results.json');
    process.exit(1);
  }
  console.log('Same figures as the committed eval/recorded-results.json');
} else writeFileSync(path, JSON.stringify(output, null, 2) + '\n');
