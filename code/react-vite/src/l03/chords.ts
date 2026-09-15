const sharps = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

// The chord that sounds when a shape is played with a capo: a pure function, easy to test alone
export function transpose(chord: string, semitones: number): string {
  const root = chord.length > 1 && chord[1] === '#' ? chord.slice(0, 2) : chord.slice(0, 1);
  const index = sharps.indexOf(root);
  return sharps[(index + semitones) % 12] + chord.slice(root.length);
}
