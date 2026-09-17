// Voicings as GA's index stores them, and what the explorer derives from them.
//
// String order. GA's index writes a guitar diagram string 1 first: "x-3-2-0-1-0" means high E muted ... low E open.
// Guitarists, chord charts and GA's own React FretDiagram read low E first (x32010 is open C). This module keeps GA's
// order in the data (gaFrets) and converts only for display (chartFrets).

export const TUNINGS = {
  // MIDI notes, string 1 (highest) first, as in GA's index
  guitar: [64, 59, 55, 50, 45, 40],
  bass: [43, 38, 33, 28],
  ukulele: [69, 64, 60, 67],
};

export const NOTE_NAMES = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
const PC = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };

// "x-3-2-0-1-0" -> [-1, 3, 2, 0, 1, 0], in GA's order (string 1 first); -1 = muted
export function parseGaDiagram(diagram) {
  return diagram.split('-').map((t) => (t === 'x' || t === 'X' ? -1 : Number.parseInt(t, 10)));
}

// GA order (string 1 = high E first) -> chart order (low E first)
export function toChartOrder(gaFrets) {
  return [...gaFrets].reverse();
}

// Chart order -> the compact chord-chart spelling guitarists write, "x32010"; frets over 9 use dashes
export function chartName(chartFrets) {
  const tokens = chartFrets.map((f) => (f < 0 ? 'x' : String(f)));
  return tokens.some((t) => t.length > 1) ? tokens.join('-') : tokens.join('');
}

// MIDI notes of the played strings, string 1 first (the order of the index's midiNotes)
export function midiNotes(gaFrets, tuning = TUNINGS.guitar) {
  const notes = [];
  gaFrets.forEach((f, s) => {
    if (f >= 0) notes.push(tuning[s] + f);
  });
  return notes;
}

export function fretSpan(gaFrets) {
  const fretted = gaFrets.filter((f) => f > 0);
  return fretted.length ? Math.max(...fretted) - Math.min(...fretted) : 0;
}

export function lowestFret(gaFrets) {
  const fretted = gaFrets.filter((f) => f > 0);
  return fretted.length ? Math.min(...fretted) : 0;
}

// Interval-class vector of the pitch-class set: counts of interval classes 1 to 6
export function intervalClassVector(notes) {
  const pcs = [...new Set(notes.map((n) => ((n % 12) + 12) % 12))];
  const icv = [0, 0, 0, 0, 0, 0];
  for (let i = 0; i < pcs.length; i++)
    for (let j = i + 1; j < pcs.length; j++) {
      const d = Math.abs(pcs[i] - pcs[j]);
      icv[Math.min(d, 12 - d) - 1]++;
    }
  return icv;
}

// The explorer's tension proxy, not a GA value: the number of semitones, whole tones and tritones in the set.
// GA's STRUCTURE partition has a "tension" slot, but the index stores it normalized with its partition, so it can't be read back.
export function tension(notes) {
  const icv = intervalClassVector(notes);
  return icv[0] + icv[1] + icv[5];
}

// "Gm7b5/F" -> { root: 7, suffix: "m7b5", bass: 5 }; names GA couldn't spell ("Forte 5-7 (pentachord)") -> root null
export function parseChordName(name) {
  const m = /^([A-G])([b#]?)(.*?)(?:\/([A-G])([b#]?))?$/.exec(name ?? '');
  if (!m || /\s/.test(m[3])) return { root: null, suffix: name ?? '', bass: null };
  const pc = (letter, acc) => (PC[letter] + (acc === 'b' ? 11 : acc === '#' ? 1 : 0)) % 12;
  return { root: pc(m[1], m[2]), suffix: m[3], bass: m[4] ? pc(m[4], m[5]) : null };
}

// Families used to colour the cloud, in legend order. The first rule that matches a chord suffix wins.
export const FAMILIES = [
  { id: 'major', label: 'Major triad', test: (s) => s === '' },
  { id: 'minor', label: 'Minor triad', test: (s) => s === 'm' },
  { id: 'power', label: 'Power chord (5)', test: (s) => s === '5' },
  { id: 'sus', label: 'Suspended', test: (s) => /^(7)?sus[24]?$/.test(s) },
  { id: 'dim-aug', label: 'Diminished / augmented', test: (s) => /^(dim|aug|\+)$/.test(s) },
  { id: 'maj7', label: 'Major 7th', test: (s) => /^maj7$|^6$|^6\/9$|^maj9|^maj13|^maj7#11/.test(s) },
  { id: 'dom7', label: 'Dominant 7th', test: (s) => /^(7|9|11|13)([b#]\d+)*$/.test(s) },
  { id: 'min7', label: 'Minor 7th', test: (s) => /^m(7|6|9|11|13)$|^m\(maj7\)$|^m6\/9$/.test(s) },
  { id: 'half-dim', label: 'Half-diminished / dim7', test: (s) => /^(m7b5|dim7)$/.test(s) },
  { id: 'add', label: 'Added tones', test: (s) => /add/.test(s) },
  { id: 'other-named', label: 'Other named chords', test: () => true },
];
export const UNNAMED = { id: 'unnamed', label: 'Named by set class or interval only' };
export const FAMILY_LIST = [...FAMILIES.map(({ id, label }) => ({ id, label })), UNNAMED];

export function familyOf(name) {
  const { root, suffix } = parseChordName(name);
  if (root === null) return FAMILY_LIST.length - 1;
  return FAMILIES.findIndex((f) => f.test(suffix));
}
