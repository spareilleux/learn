// Lesson 13: the measurements of GuitarAlchemist's ThreeFretboard.tsx, shared by the two versions of the page.
// GA's units: 1 unit = 10 mm; a Stratocaster's 648 mm scale length, 42 mm nut, 22 frets, 6 strings.
export const SCALE = 64.8;
export const NUT_WIDTH = 4.2;
export const FRETS = 22;
export const STRINGS = 6;
export const BOARD_THICKNESS = 0.4;
export const INLAYS = [3, 5, 7, 9, 15, 17, 19, 21];
export const DOUBLE_INLAYS = [12, 24];
// String 0 is high E, as in GA; MIDI note numbers of the open strings
const OPEN = [64, 59, 55, 50, 45, 40];
const NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

export type Position = { string: number; fret: number; color?: string };

// GA's calculateFretPosition3D: distance of fret n from the nut; the scene is centered on the middle of the scale
export const fretDistance = (n: number): number => (n === 0 ? 0 : SCALE * (1 - 1 / 2 ** (n / 12)));
export const fretX = (n: number): number => fretDistance(n) - SCALE / 2;
export const boardLength = (): number => fretDistance(FRETS) + (fretDistance(FRETS) - fretDistance(FRETS - 1)) / 2;
export const stringZ = (s: number): number => (s / (STRINGS - 1) - 0.5) * NUT_WIDTH * 0.85;
// Where a marker for (string, fret) sits: between the fret and the previous one, or just before the nut for fret 0
export const markerX = (fret: number): number => (fret === 0 ? -SCALE / 2 - 0.8 : (fretX(fret) + fretX(fret - 1)) / 2);

export function noteAt(string: number, fret: number): string {
  const midi = OPEN[string] + fret;
  return `${NAMES[midi % 12]}${Math.floor(midi / 12) - 1}`;
}

export function fretAtX(x: number): number | null {
  const distance = x + SCALE / 2;
  if (distance < -1 || distance > fretDistance(FRETS)) return null;
  if (distance <= 0) return 0;
  return Math.ceil(-12 * Math.log2(1 - distance / SCALE));
}

export function stringAtZ(z: number): number {
  let best = 0;
  for (let s = 1; s < STRINGS; s++) if (Math.abs(stringZ(s) - z) < Math.abs(stringZ(best) - z)) best = s;
  return best;
}

// The C major chord of the lesson, open position: string 4 fret 3 (C), string 3 fret 2 (E), string 1 fret 1 (C)
export const C_MAJOR: Position[] = [
  { string: 4, fret: 3, color: '#5ab0ff' },
  { string: 3, fret: 2, color: '#5ab0ff' },
  { string: 1, fret: 1, color: '#5ab0ff' },
];
