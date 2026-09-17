// Guitar voicings of a chord, ranked by how common they are. Not a port of GA's generator: a small search the course
// can read in one screen, with GA's string order (string 0 is high E, as in the three.js course's guitar.ts) and
// standard tuning. It feeds both the neck in the app and the synthetic corpus.
//
// Search: for each 4-fret window from the nut to fret 12, every string is muted or fretted inside the window on a
// chord tone (open strings allowed up to fret 4). A voicing keeps
//  - at least 4 strings, muted strings only on the bass side plus possibly the high E;
//  - every chord tone, except that a 4-note chord may drop its perfect fifth;
//  - at most 4 fingers, the lowest fret counting once when it is barred.
// Rank (lower first): bass not on the root +10, position (lowest fretted fret) x0.6, open strings x-0.4, muted strings
// x0.5, span x0.3, fingers x0.2.
import { QUALITIES, pitchClasses, type Chord } from './chords.ts';

/** MIDI note of each open string, string 0 = high E4 (64) to string 5 = low E2 (40) */
export const OPEN_MIDI = [64, 59, 55, 50, 45, 40] as const;

/** One fret per string, -1 = muted, index 0 = high E */
export type Voicing = { frets: number[]; cost: number; bassPc: number; inversion: boolean; position: number };

export function midiNotes(v: Voicing): number[] {
  const notes: number[] = [];
  for (let s = 5; s >= 0; s--) if (v.frets[s] >= 0) notes.push(OPEN_MIDI[s] + v.frets[s]);
  return notes;
}

/** Tab notation, low E first, as guitarists write it: C major open = x32010 */
export const tab = (v: Voicing): string =>
  [...v.frets]
    .reverse()
    .map((f) => (f < 0 ? 'x' : f < 10 ? String(f) : `(${f})`))
    .join('');

const cache = new Map<string, Voicing[]>();

export function voicings(chord: Chord): Voicing[] {
  const key = `${chord.root}:${chord.quality}`;
  const hit = cache.get(key);
  if (hit) return hit;
  const tones = new Set(pitchClasses(chord));
  const intervals = QUALITIES[chord.quality].intervals;
  const fifth = (chord.root + 7) % 12;
  const required = [...tones].filter((pc) => !(intervals.length >= 4 && pc === fifth));
  const found = new Map<string, Voicing>();

  for (let start = 0; start <= 12; start++) {
    const low = Math.max(1, start);
    const high = start + 3;
    const options: number[][] = [];
    for (let s = 0; s < 6; s++) {
      const list = [-1];
      if (start <= 4 && tones.has(OPEN_MIDI[s] % 12)) list.push(0);
      for (let f = low; f <= high; f++) if (tones.has((OPEN_MIDI[s] + f) % 12)) list.push(f);
      options.push(list);
    }
    const frets = new Array<number>(6).fill(-1);
    const visit = (s: number): void => {
      if (s < 0) {
        const v = evaluate(frets, chord.root, required);
        if (v) {
          const id = frets.join(',');
          if (!found.has(id)) found.set(id, v);
        }
        return;
      }
      for (const f of options[s]) {
        frets[s] = f;
        visit(s - 1);
      }
    };
    visit(5);
  }
  const list = [...found.values()].sort((a, b) => a.cost - b.cost || tab(a).localeCompare(tab(b)));
  cache.set(key, list);
  return list;
}

function evaluate(frets: number[], root: number, required: number[]): Voicing | null {
  // Muted strings: a run from the low E upwards, plus optionally the high E
  let s = 5;
  while (s >= 0 && frets[s] < 0) s--;
  const lowestSounding = s;
  for (let i = lowestSounding; i >= 1; i--) if (frets[i] < 0) return null;
  const sounding = frets.filter((f) => f >= 0).length;
  if (sounding < 4) return null;
  const pcs = new Set<number>();
  for (let i = 0; i < 6; i++) if (frets[i] >= 0) pcs.add((OPEN_MIDI[i] + frets[i]) % 12);
  for (const pc of required) if (!pcs.has(pc)) return null;
  const fretted = frets.filter((f) => f > 0);
  const min = fretted.length ? Math.min(...fretted) : 0;
  const max = fretted.length ? Math.max(...fretted) : 0;
  const atMin = fretted.filter((f) => f === min).length;
  const fingers = fretted.length - (atMin >= 2 ? atMin - 1 : 0);
  if (fingers > 4) return null;
  const open = frets.filter((f) => f === 0).length;
  const bassPc = (OPEN_MIDI[lowestSounding] + frets[lowestSounding]) % 12;
  const inversion = bassPc !== root;
  const cost = (inversion ? 10 : 0) + min * 0.6 - open * 0.4 + (6 - sounding) * 0.5 + (max - min) * 0.3 + fingers * 0.2;
  return { frets: [...frets], cost: Math.round(cost * 1000) / 1000, bassPc, inversion, position: min };
}
