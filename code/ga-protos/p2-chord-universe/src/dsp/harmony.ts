// Key and "next chord" from a small, cited subset of Guitar Alchemist's functional harmony, pinned on a826864.
//
// - Diatonic triads of a major and a natural minor key, as (semitones from the tonic, quality):
//   DomainClosures.fs#L104-L110 (majorPattern, minorPattern).
// - The seven functions and their three primary groups, tonic (I, iii, vi), subdominant (ii, IV) and dominant (V, vii°):
//   HarmonicFunction.cs#L7-L17 and HarmonicFunctionAnalyzer.cs#L92-L99.
// - Cadences: authentic V-I, plagal IV-I, deceptive V-vi, and ii7-V7-Imaj7: Cadences.yaml#L6-L50.
// Circle-of-fifths motion (the root falls a fifth) is the rule behind ii-V-I; the resolution of a diminished seventh up
// a half step is general practice, not taken from GA, and marked as such.
import { NOTE_NAMES, QUALITIES, type Chord } from './chords.ts';

const GA = 'https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/';
export const SOURCES = {
  patterns: `${GA}Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L104-L110`,
  functions: `${GA}Common/GA.Domain.Services/Tonal/HarmonicFunctionAnalyzer.cs#L92-L99`,
  cadences: `${GA}Common/GA.Business.Config/Cadences.yaml#L6-L50`,
};

type Triad = 'major' | 'minor' | 'diminished';
const MAJOR: [number, Triad][] = [[0, 'major'], [2, 'minor'], [4, 'minor'], [5, 'major'], [7, 'major'], [9, 'minor'], [11, 'diminished']];
const MINOR: [number, Triad][] = [[0, 'minor'], [2, 'diminished'], [3, 'major'], [5, 'minor'], [7, 'minor'], [8, 'major'], [10, 'major']];
const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];
type Group = 'tonic' | 'subdominant' | 'dominant';
const GROUP: Group[] = ['tonic', 'subdominant', 'tonic', 'subdominant', 'dominant', 'tonic', 'dominant'];

const q = (symbol: string): number => QUALITIES.findIndex((x) => x.symbol === symbol);

/** The triad a quality contains, for diatonic membership: C7 and Cmaj7 are major-triad chords, Bm7b5 diminished */
export function triadOf(quality: number): Triad | null {
  const s = QUALITIES[quality].symbol;
  if (['', '6', '7', 'maj7', 'add9'].includes(s)) return 'major';
  if (['m', 'm7'].includes(s)) return 'minor';
  if (['dim', 'm7b5', 'dim7'].includes(s)) return 'diminished';
  return null;
}

export type Key = { tonic: number; mode: 'major' | 'minor' };
export const keyName = (k: Key): string => `${NOTE_NAMES[k.tonic]} ${k.mode}`;

/** Degree (0-6) of a chord in a key, or -1 when its root and triad are not diatonic */
export function degreeIn(chord: Chord, key: Key): number {
  const triad = triadOf(chord.quality);
  const pattern = key.mode === 'major' ? MAJOR : MINOR;
  return pattern.findIndex(([offset, t]) => (key.tonic + offset) % 12 === chord.root && t === triad);
}

/**
 * Scores the 24 keys against the recent chords, newest last: a diatonic chord adds its weight (0.8 per step of age),
 * the tonic chord and a dominant seventh on the fifth degree half a weight more. A relative major and minor share all
 * their triads, and the course's heuristic (not GA's) lets the V7 point to its tonic. The best key wins, ties to major,
 * then to the lower tonic.
 */
export function estimateKey(history: readonly Chord[]): { key: Key; score: number } | null {
  if (history.length === 0) return null;
  let best: { key: Key; score: number } | null = null;
  for (const mode of ['major', 'minor'] as const) {
    for (let tonic = 0; tonic < 12; tonic++) {
      const key = { tonic, mode };
      let score = 0;
      history.forEach((chord, i) => {
        const weight = 0.8 ** (history.length - 1 - i);
        const d = degreeIn(chord, key);
        const dominant7 = QUALITIES[chord.quality].symbol === '7' && chord.root === (tonic + 7) % 12;
        if (d >= 0) score += weight * (d === 0 ? 1.5 : 1);
        if (dominant7) score += weight * 0.5;
      });
      if (!best || score > best.score + 1e-9) best = { key, score };
    }
  }
  return best;
}

export type Suggestion = { chord: Chord; name: string; reason: string; source: string };

function diatonic(key: Key, degree: number, seventh: boolean): Chord {
  const [offset, triad] = (key.mode === 'major' ? MAJOR : MINOR)[degree];
  const root = (key.tonic + offset) % 12;
  if (!seventh) return { root, quality: q(triad === 'major' ? '' : triad === 'minor' ? 'm' : 'dim') };
  // Seventh chords of the major key: Imaj7 ii7 iii7 IVmaj7 V7 vi7 viiø7
  const major7 = key.mode === 'major' ? ['maj7', 'm7', 'm7', 'maj7', '7', 'm7', 'm7b5'] : ['m7', 'm7b5', 'maj7', 'm7', 'm7', 'maj7', '7'];
  return { root, quality: q(major7[degree]) };
}

const numeral = (key: Key, degree: number): string => {
  const triad = (key.mode === 'major' ? MAJOR : MINOR)[degree][1];
  const r = ROMAN[degree];
  return triad === 'major' ? r : triad === 'minor' ? r.toLowerCase() : `${r.toLowerCase()}°`;
};

/** Up to three next chords, each with the rule that proposes it. */
export function suggestNext(chord: Chord, key: Key): Suggestion[] {
  const out: Suggestion[] = [];
  const add = (c: Chord, reason: string, source: string) => {
    const name = NOTE_NAMES[c.root] + QUALITIES[c.quality].symbol;
    if (out.length < 3 && !out.some((s) => s.name === name)) out.push({ chord: c, name, reason, source });
  };
  const symbol = QUALITIES[chord.quality].symbol;
  const seventh = ['7', 'maj7', 'm7', 'm7b5', 'dim7'].includes(symbol);
  const degree = degreeIn(chord, key);

  if (symbol === 'dim7') {
    add({ root: (chord.root + 1) % 12, quality: q('m') }, 'a diminished seventh resolves up a half step (general practice, not in GA)', '');
  }
  if (degree < 0) {
    if (symbol === '7') {
      const target = (chord.root + 5) % 12;
      const inKey = [0, 1, 2, 3, 4, 5, 6].find((d) => diatonic(key, d, false).root === target);
      add(inKey !== undefined ? diatonic(key, inKey, seventh) : { root: target, quality: q('') }, 'secondary dominant: the root falls a fifth', SOURCES.cadences);
    }
    add(diatonic(key, 0, seventh), `back to the tonic of ${keyName(key)}`, SOURCES.patterns);
    return out;
  }

  const group = GROUP[degree];
  const here = numeral(key, degree);
  // 1. Circle of fifths: the root falls a fifth, three degrees up (vi-ii-V-I)
  const down5 = (degree + 3) % 7;
  add(diatonic(key, down5, seventh), `circle of fifths, ${here} to ${numeral(key, down5)}`, SOURCES.patterns);
  // 2. Function: tonic to subdominant, subdominant to dominant, dominant to tonic
  if (group === 'tonic') add(diatonic(key, 3, seventh), `tonic to subdominant, ${here} to ${numeral(key, 3)}`, SOURCES.functions);
  if (group === 'subdominant') add(diatonic(key, 4, seventh), `subdominant to dominant, ${here} to ${numeral(key, 4)}`, SOURCES.functions);
  if (group === 'dominant') {
    add(diatonic(key, 0, seventh), `authentic cadence, ${here} to ${numeral(key, 0)}`, SOURCES.cadences);
    if (degree === 4) add(diatonic(key, 5, seventh), `deceptive cadence, ${here} to ${numeral(key, 5)}`, SOURCES.cadences);
  }
  // 3. Plagal IV-I, or the dominant from the tonic
  if (degree === 3) add(diatonic(key, 0, seventh), `plagal cadence, ${here} to ${numeral(key, 0)}`, SOURCES.cadences);
  if (degree === 0) add(diatonic(key, 4, seventh), `half cadence, ${here} to ${numeral(key, 4)}`, SOURCES.cadences);
  add(diatonic(key, 0, seventh), `back to the tonic, ${numeral(key, 0)}`, SOURCES.patterns);
  return out;
}
