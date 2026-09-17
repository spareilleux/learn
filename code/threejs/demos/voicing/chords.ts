// Chord voicings for the fretboard demo, in GuitarAlchemist's order: string 0 is high E, string 5 low E; −1 is a string
// not played. Each marker is colored by its role in the chord, computed from the chord's root.
import type { Position } from '../../src/13-fretboard/guitar.ts';
import { OPEN_STRINGS } from '../guitar/pluck.ts';

export type Chord = { name: string; root: number; voicings: { name: string; frets: number[] }[] };

const C = 0, D = 2, E = 4, F = 5, G = 7, A = 9, B = 11;

export const CHORDS: Chord[] = [
  { name: 'C', root: C, voicings: [
    { name: 'open', frets: [0, 1, 0, 2, 3, -1] },
    { name: 'A shape, fret 3', frets: [3, 5, 5, 5, 3, -1] },
    { name: 'E shape, fret 8', frets: [8, 8, 9, 10, 10, 8] },
  ] },
  { name: 'G', root: G, voicings: [
    { name: 'open', frets: [3, 0, 0, 0, 2, 3] },
    { name: 'E shape, fret 3', frets: [3, 3, 4, 5, 5, 3] },
    { name: 'A shape, fret 10', frets: [10, 12, 12, 12, 10, -1] },
  ] },
  { name: 'D', root: D, voicings: [
    { name: 'open', frets: [2, 3, 2, 0, -1, -1] },
    { name: 'A shape, fret 5', frets: [5, 7, 7, 7, 5, -1] },
    { name: 'E shape, fret 10', frets: [10, 10, 11, 12, 12, 10] },
  ] },
  { name: 'Am', root: A, voicings: [
    { name: 'open', frets: [0, 1, 2, 2, 0, -1] },
    { name: 'E shape, fret 5', frets: [5, 5, 5, 7, 7, 5] },
  ] },
  { name: 'E', root: E, voicings: [{ name: 'open', frets: [0, 0, 1, 2, 2, 0] }] },
  { name: 'Em', root: E, voicings: [{ name: 'open', frets: [0, 0, 0, 2, 2, 0] }] },
  { name: 'F', root: F, voicings: [{ name: 'E shape, fret 1', frets: [1, 1, 2, 3, 3, 1] }] },
  { name: 'Dm', root: D, voicings: [{ name: 'open', frets: [1, 3, 2, 0, -1, -1] }] },
  { name: 'G7', root: G, voicings: [{ name: 'open', frets: [1, 0, 0, 0, 2, 3] }] },
  { name: 'Cmaj7', root: C, voicings: [{ name: 'open', frets: [0, 0, 0, 2, 3, -1] }] },
  { name: 'Am7', root: A, voicings: [{ name: 'open', frets: [0, 1, 0, 2, 0, -1] }] },
  { name: 'Dm7', root: D, voicings: [{ name: 'open', frets: [1, 1, 2, 0, -1, -1] }] },
  { name: 'E7', root: E, voicings: [{ name: 'open', frets: [0, 0, 1, 0, 2, 0] }] },
  { name: 'Bm7♭5', root: B, voicings: [{ name: 'fret 2', frets: [-1, 3, 2, 3, 2, -1] }] },
];

export const ROLE_COLORS = { root: '#ff5c5c', third: '#5ab0ff', fifth: '#6fd08c', seventh: '#f4c542', other: '#c9c9c9' };

export function role(root: number, midi: number): keyof typeof ROLE_COLORS {
  const interval = (((midi - root) % 12) + 12) % 12;
  if (interval === 0) return 'root';
  if (interval === 3 || interval === 4) return 'third';
  if (interval >= 6 && interval <= 8) return 'fifth';
  if (interval === 10 || interval === 11) return 'seventh';
  return 'other';
}

// The markers of a voicing: one per string played, colored by role
export function positionsOf(chord: Chord, frets: number[]): Position[] {
  return frets.flatMap((fret, string) => (fret < 0 ? [] : [{ string, fret, color: ROLE_COLORS[role(chord.root, OPEN_STRINGS[string] + fret)] }]));
}
