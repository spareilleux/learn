// Chord qualities and template matching.
//
// The 13 qualities are ported from Guitar Alchemist's CanonicalChordPatternCatalog, pinned on a826864:
// https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/CanonicalChordPatternCatalog.cs#L45-L112
// GA stores each pattern as root-relative intervals mod 12 (a pitch-class set with the root at 0) and a priority,
// "lower priority wins when multiple patterns match" (lines 7-9). The ids, intervals and priorities below are GA's;
// the short symbols are the course's.

export type Quality = {
  /** Symbol suffix: C + 'm7' */
  symbol: string;
  /** GA's pattern id */
  gaId: string;
  intervals: readonly number[];
  priority: number;
  /** Line in CanonicalChordPatternCatalog.cs at a826864 */
  gaLine: number;
};

export const QUALITIES: readonly Quality[] = [
  { symbol: '', gaId: 'major-triad', intervals: [0, 4, 7], priority: 0, gaLine: 47 },
  { symbol: 'm', gaId: 'minor-triad', intervals: [0, 3, 7], priority: 1, gaLine: 48 },
  { symbol: 'dim', gaId: 'diminished-triad', intervals: [0, 3, 6], priority: 2, gaLine: 49 },
  { symbol: 'aug', gaId: 'augmented-triad', intervals: [0, 4, 8], priority: 3, gaLine: 50 },
  { symbol: 'sus2', gaId: 'sus2', intervals: [0, 2, 7], priority: 8, gaLine: 51 },
  { symbol: 'sus4', gaId: 'sus4', intervals: [0, 5, 7], priority: 8, gaLine: 52 },
  { symbol: '6', gaId: 'major-6', intervals: [0, 4, 7, 9], priority: 10, gaLine: 55 },
  { symbol: '7', gaId: 'dominant-7', intervals: [0, 4, 7, 10], priority: 5, gaLine: 61 },
  { symbol: 'maj7', gaId: 'major-7', intervals: [0, 4, 7, 11], priority: 5, gaLine: 62 },
  { symbol: 'm7', gaId: 'minor-7', intervals: [0, 3, 7, 10], priority: 5, gaLine: 63 },
  { symbol: 'm7b5', gaId: 'half-diminished-7', intervals: [0, 3, 6, 10], priority: 6, gaLine: 65 },
  { symbol: 'dim7', gaId: 'diminished-7', intervals: [0, 3, 6, 9], priority: 7, gaLine: 66 },
  { symbol: 'add9', gaId: 'add-9', intervals: [0, 2, 4, 7], priority: 50, gaLine: 107 },
];

export const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'] as const;

export type Chord = { root: number; quality: number };

export const chordName = (c: Chord): string => NOTE_NAMES[c.root] + QUALITIES[c.quality].symbol;
export const pitchClasses = (c: Chord): number[] => QUALITIES[c.quality].intervals.map((i) => (c.root + i) % 12);
/** GA's 12-bit pitch-class set id: bit i set when pitch class i is in the set. */
export const pcsMask = (pcs: readonly number[]): number => pcs.reduce((m, pc) => m | (1 << pc), 0);

export type MatchOptions = {
  /**
   * Model the harmonics of each chord tone in the template (true), for a chromagram that folds harmonics in, or use a
   * binary template (false), for a chromagram of estimated notes
   */
  harmonicTemplates: boolean;
  /** Weight of harmonic h is decay^(h-1) */
  harmonicDecay: number;
  harmonics: number;
  /** Weight of the bass chroma at the candidate's root */
  bassWeight: number;
  /** Softmax temperature that turns scores into a confidence */
  temperature: number;
};

export const DEFAULT_MATCH: MatchOptions = { harmonicTemplates: false, harmonicDecay: 0.8, harmonics: 6, bassWeight: 0.08, temperature: 0.02 };

// Harmonic h of a note, as a pitch-class offset from the note: 1 and 2 are the note, 3 a fifth, 4 the note, 5 a major
// third (14 cents flat), 6 a fifth, 7 a minor seventh (31 cents flat), 8 the note.
const HARMONIC_PC = [0, 0, 0, 7, 0, 4, 7, 10, 0];

export type Candidate = { chord: Chord; name: string; score: number; probability: number };

// Templates are built once per option set: 12 roots x 13 qualities, each an L2-normalized 12-vector
const templateCache = new Map<string, Float64Array[]>();
function templates(options: MatchOptions): Float64Array[] {
  const key = `${options.harmonicTemplates}:${options.harmonicDecay}:${options.harmonics}`;
  let list = templateCache.get(key);
  if (list) return list;
  list = [];
  for (let root = 0; root < 12; root++) {
    for (let q = 0; q < QUALITIES.length; q++) {
      const t = new Float64Array(12);
      // Sorted, so that two chords with the same pitch-class set (C6 and Am7) get bit-identical templates and tie exactly
      for (const pc of pitchClasses({ root, quality: q }).sort((a, b) => a - b)) {
        if (!options.harmonicTemplates) t[pc] += 1;
        else for (let h = 1; h <= options.harmonics; h++) t[(pc + HARMONIC_PC[h]) % 12] += options.harmonicDecay ** (h - 1);
      }
      normalize(t);
      list.push(t);
    }
  }
  templateCache.set(key, list);
  return list;
}

export function normalize(v: Float64Array): Float64Array {
  let sum = 0;
  for (let i = 0; i < v.length; i++) sum += v[i] * v[i];
  const norm = Math.sqrt(sum);
  if (norm > 0) for (let i = 0; i < v.length; i++) v[i] /= norm;
  return v;
}

/**
 * Scores the 156 chords against a chroma vector: cosine similarity with the template, plus a small bonus when the
 * bass chroma peaks on the candidate's root. Ties (same pitch-class set, same bass) go to GA's lower priority, then
 * to the lower root. Returns all candidates, best first, with softmax probabilities.
 */
export function matchChord(chroma: ArrayLike<number>, bass: ArrayLike<number> | null, options: MatchOptions = DEFAULT_MATCH): Candidate[] {
  const c = normalize(Float64Array.from(chroma));
  let bassMax = 0;
  if (bass) for (let i = 0; i < 12; i++) bassMax = Math.max(bassMax, bass[i]);
  const list = templates(options);
  const out: Candidate[] = [];
  for (let root = 0; root < 12; root++) {
    for (let q = 0; q < QUALITIES.length; q++) {
      const t = list[root * QUALITIES.length + q];
      let score = 0;
      for (let i = 0; i < 12; i++) score += c[i] * t[i];
      if (bass && bassMax > 0) score += (options.bassWeight * bass[root]) / bassMax;
      const chord = { root, quality: q };
      out.push({ chord, name: chordName(chord), score, probability: 0 });
    }
  }
  out.sort((a, b) => b.score - a.score || QUALITIES[a.chord.quality].priority - QUALITIES[b.chord.quality].priority || a.chord.root - b.chord.root);
  // Softmax, shifted by the best score for numerical stability
  let z = 0;
  for (const cand of out) z += Math.exp((cand.score - out[0].score) / options.temperature);
  for (const cand of out) cand.probability = Math.exp((cand.score - out[0].score) / options.temperature) / z;
  return out;
}
