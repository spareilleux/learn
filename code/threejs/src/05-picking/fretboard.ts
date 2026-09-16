// Lesson 5: a fretboard made of primitives, shared by the page and by scripts/l05-raycaster.ts (no DOM needed here).
// Units: the neck is 3.6 long, the scale length is 6.5, so fret 12 sits at half the scale from the nut.
import * as THREE from 'three/webgpu';

export const SCALE = 6.5;
export const NUT_X = -2;
export const FRETS = 12;
export const STRINGS = 6;
export const NECK_TOP = 0.36;
const NECK_WIDTH = 0.55;
// Standard tuning, from string 6 (low E) to string 1 (high E), as MIDI note numbers
const OPEN_STRINGS = [40, 45, 50, 55, 59, 64];
const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

// Position of fret n along X (fret 0 is the nut)
export const fretX = (n: number): number => NUT_X + SCALE * (1 - 2 ** (-n / 12));
// Z of string s, from 1 (high E, nearest the camera) to 6 (low E)
export const stringZ = (s: number): number => (NECK_WIDTH / 2 - 0.05) * (1 - ((s - 1) * 2) / (STRINGS - 1));

// Where a finger at x presses: 0 before the nut side of fret 1, n between fret n − 1 and fret n
export function fretAt(x: number): number | null {
  if (x < NUT_X || x > fretX(FRETS)) return null;
  return Math.ceil(-12 * Math.log2(1 - (x - NUT_X) / SCALE));
}

// The nearest string to z
export function stringAt(z: number): number {
  let best = 1;
  for (let s = 2; s <= STRINGS; s++) if (Math.abs(stringZ(s) - z) < Math.abs(stringZ(best) - z)) best = s;
  return best;
}

export function noteName(string: number, fret: number): string {
  const midi = OPEN_STRINGS[STRINGS - string] + fret;
  return `${NOTE_NAMES[midi % 12]}${Math.floor(midi / 12) - 1}`;
}

// The middle of the space where a finger presses fret n on string s, on top of the neck
export const pressPoint = (s: number, n: number): THREE.Vector3 => new THREE.Vector3((fretX(n - 1) + fretX(n)) / 2, NECK_TOP, stringZ(s));

export function buildFretboard() {
  const board = new THREE.Group();
  board.name = 'fretboard';

  const neckLength = fretX(FRETS) + 0.35 - NUT_X;
  const neck = new THREE.Mesh(
    new THREE.BoxGeometry(neckLength, 0.12, NECK_WIDTH),
    new THREE.MeshStandardMaterial({ color: 0x4a2c1d, roughness: 0.75 }),
  );
  neck.name = 'neck';
  neck.position.set(NUT_X + neckLength / 2, NECK_TOP - 0.06, 0);
  board.add(neck);

  // One geometry and one material for all the frets, one mesh per fret
  const fretGeometry = new THREE.CylinderGeometry(0.012, 0.012, NECK_WIDTH, 12).rotateX(Math.PI / 2);
  const fretMaterial = new THREE.MeshStandardMaterial({ color: 0xc9c5bd, metalness: 1, roughness: 0.3 });
  const frets: THREE.Mesh[] = [];
  for (let n = 1; n <= FRETS; n++) {
    const fret = new THREE.Mesh(fretGeometry, fretMaterial);
    fret.name = `fret ${n}`;
    fret.position.set(fretX(n), NECK_TOP + 0.01, 0);
    board.add(fret);
    frets.push(fret);
  }

  // Strings get thicker from 1 to 6
  const stringMaterial = new THREE.MeshStandardMaterial({ color: 0xd8d2c4, metalness: 1, roughness: 0.35 });
  const strings: THREE.Mesh[] = [];
  for (let s = 1; s <= STRINGS; s++) {
    const radius = 0.003 + s * 0.0012;
    const string = new THREE.Mesh(new THREE.CylinderGeometry(radius, radius, neckLength, 8).rotateZ(Math.PI / 2), stringMaterial);
    string.name = `string ${s}`;
    string.position.set(NUT_X + neckLength / 2, NECK_TOP + 0.035, stringZ(s));
    board.add(string);
    strings.push(string);
  }

  return { board, neck, frets, strings };
}
