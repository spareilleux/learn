// Where the bracelets' pitch classes come from.
//
// Two sources, both Guitar Alchemist's:
//   - the chord qualities of `Common/GA.Domain.Core/Theory/Harmony/CanonicalChordPatternCatalog.cs`;
//   - the named scales of `Common/GA.Domain.Core/Theory/Tonal/Scales/Scale.cs`, written there as note names.
// With `--ga <clone>` the script reads both files out of a GA clone at a pinned commit, parses them, checks the chord
// half against the catalog prototype 2 already ported (imported below, not copied), and writes `data/ga-sets.json`
// with the SHA-256 of each blob it read. With no argument it re-checks the committed JSON against P2's catalog and
// against the bracelet's own invariants, which is what CI runs: the runners have no GA clone.
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { QUALITIES } from '../../p2-chord-universe/src/dsp/chords.ts';

export const GA_SHA = 'a826864f3a012cad88e415954bf57eca0ce12aa6';
export const CATALOG_PATH = 'Common/GA.Domain.Core/Theory/Harmony/CanonicalChordPatternCatalog.cs';
export const SCALE_PATH = 'Common/GA.Domain.Core/Theory/Tonal/Scales/Scale.cs';

const NATURALS: Record<string, number> = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };

/** GA writes scale notes as "C D E F G A B", sharps as "F#" and flats as "Eb" or "Db". */
export const noteToPitchClass = (note: string): number => {
  const natural = NATURALS[note[0]];
  if (natural === undefined) throw new Error(`not a note: ${note}`);
  let pc = natural;
  for (const accidental of note.slice(1)) {
    if (accidental === '#') pc += 1;
    else if (accidental === 'b') pc -= 1;
    else throw new Error(`not an accidental: ${accidental} in ${note}`);
  }
  return ((pc % 12) + 12) % 12;
};

export type ChordEntry = { id: string; intervals: number[]; priority: number };
export type ScaleEntry = { id: string; notes: string; root: number; intervals: number[] };

/** `new("major-triad", "major", "triad", [], [0, 4, 7], 0),` -> the id, the interval list and the priority. */
export const parseCatalog = (source: string): ChordEntry[] => {
  const re = /new\(\s*"([a-z0-9-]+)"\s*,\s*"[^"]*"\s*,\s*"[^"]*"\s*,\s*\[[^\]]*\]\s*,\s*\[([0-9,\s]+)\]\s*,\s*(\d+)\s*\)/g;
  const entries: ChordEntry[] = [];
  for (const m of source.matchAll(re)) {
    entries.push({ id: m[1], intervals: m[2].split(',').map((n) => Number(n.trim())), priority: Number(m[3]) });
  }
  if (!entries.length) throw new Error('no chord pattern found in the catalog');
  return entries;
};

/** `public static Scale Major => new("C D E F G A B");` -> the name and the pitch classes, rooted on the first note. */
export const parseScales = (source: string): ScaleEntry[] => {
  const re = /public\s+static\s+Scale\s+([A-Za-z0-9]+)\s*=>\s*new\("([^"]+)"\)/g;
  // GA groups the three minor scales in a nested `public static class Minor`; give those their qualified name.
  const nested = [...source.matchAll(/public\s+static\s+class\s+([A-Za-z0-9]+)/g)].map((m) => [m.index ?? 0, m[1]] as const);
  const entries: ScaleEntry[] = [];
  for (const m of source.matchAll(re)) {
    const notes = m[2].trim().split(/\s+/);
    const pcs = notes.map(noteToPitchClass);
    const root = pcs[0];
    const enclosing = nested.filter(([at]) => at < (m.index ?? 0)).at(-1);
    entries.push({ id: enclosing ? `${enclosing[1]}.${m[1]}` : m[1], notes: m[2], root, intervals: pcs.map((pc) => ((pc - root) % 12 + 12) % 12) });
  }
  if (!entries.length) throw new Error('no scale found');
  return entries;
};

export type GaSets = {
  gaSha: string;
  files: { path: string; sha256: string }[];
  chords: ChordEntry[];
  scales: ScaleEntry[];
};

/** The chord ids P2 and P5 share. Their intervals must agree exactly, or one of the two ports is wrong. */
export const crossCheckWithP2 = (chords: ChordEntry[]): string[] => {
  const byId = new Map(chords.map((c) => [c.id, c]));
  const problems: string[] = [];
  for (const q of QUALITIES) {
    const ga = byId.get(q.gaId);
    if (!ga) {
      problems.push(`${q.gaId}: absent from GA's catalog`);
      continue;
    }
    if (ga.intervals.join(',') !== q.intervals.join(',')) problems.push(`${q.gaId}: GA ${ga.intervals} vs P2 ${q.intervals}`);
    if (ga.priority !== q.priority) problems.push(`${q.gaId}: priority GA ${ga.priority} vs P2 ${q.priority}`);
  }
  return problems;
};

export const checkInvariants = (sets: GaSets): string[] => {
  const problems: string[] = [];
  for (const c of sets.chords) {
    if (c.intervals[0] !== 0) problems.push(`${c.id}: the root is not 0`);
    if (c.intervals.some((i) => i < 0 || i > 11)) problems.push(`${c.id}: an interval is outside 0..11`);
    if (new Set(c.intervals).size !== c.intervals.length) problems.push(`${c.id}: a pitch class is repeated`);
    if ([...c.intervals].sort((a, b) => a - b).join(',') !== c.intervals.join(',')) problems.push(`${c.id}: not sorted`);
  }
  for (const s of sets.scales) {
    if (s.intervals[0] !== 0) problems.push(`${s.id}: the root is not 0`);
    if (new Set(s.intervals).size !== s.intervals.length) problems.push(`${s.id}: a pitch class is repeated`);
  }
  const major = sets.scales.find((s) => s.id === 'Major');
  if (!major || major.intervals.join(',') !== '0,2,4,5,7,9,11') problems.push(`Major: ${major?.intervals} is not the major scale`);
  return problems;
};

const sha256 = (text: string) => createHash('sha256').update(text, 'utf8').digest('hex');

const main = () => {
  const args = process.argv.slice(2);
  const ga = args[args.indexOf('--ga') + 1];
  const out = new URL('../data/ga-sets.json', import.meta.url);
  let sets: GaSets;
  if (args.includes('--ga')) {
    const read = (path: string) => execFileSync('git', ['-C', ga, 'show', `${GA_SHA}:${path}`], { encoding: 'utf8', maxBuffer: 64 << 20 });
    const catalog = read(CATALOG_PATH);
    const scales = read(SCALE_PATH);
    sets = {
      gaSha: GA_SHA,
      files: [
        { path: CATALOG_PATH, sha256: sha256(catalog) },
        { path: SCALE_PATH, sha256: sha256(scales) },
      ],
      chords: parseCatalog(catalog),
      scales: parseScales(scales),
    };
  } else {
    sets = JSON.parse(readFileSync(out, 'utf8'));
  }
  const problems = [...crossCheckWithP2(sets.chords), ...checkInvariants(sets)];
  if (problems.length) {
    for (const p of problems) console.error('MISMATCH', p);
    process.exit(1);
  }
  if (args.includes('--ga')) writeFileSync(out, `${JSON.stringify(sets, null, 2)}\n`);
  console.log(`${sets.chords.length} chord patterns, ${sets.scales.length} scales, GA ${sets.gaSha.slice(0, 7)}: every check passed`);
};

if (import.meta.filename === process.argv[1]) main();
