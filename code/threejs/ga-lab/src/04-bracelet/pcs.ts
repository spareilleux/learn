// Pitch-class sets as 12-bit masks: bit k is pitch class k (C = 0). The bracelets of the music theory course
// (music-theory-ga, lesson 2) draw a set as 12 beads on a circle, filled where the bit is set.

// Transposition by t semitones: rotate the 12 bits
export const transpose = (mask: number, t: number): number => {
  const s = ((t % 12) + 12) % 12;
  return ((mask << s) | (mask >>> (12 - s))) & 0xfff;
};

// Inversion around C: pitch class k becomes −k mod 12
export const invert = (mask: number): number => {
  let out = 0;
  for (let k = 0; k < 12; k++) if (mask & (1 << k)) out |= 1 << ((12 - k) % 12);
  return out;
};

// The smallest mask among the set's 12 transpositions (and their inversions, if asked): one representative per class
export function representative(mask: number, withInversion = false): number {
  let best = mask;
  for (let t = 0; t < 12; t++) {
    best = Math.min(best, transpose(mask, t));
    if (withInversion) best = Math.min(best, transpose(invert(mask), t));
  }
  return best;
}

// The representatives of every class, sorted: 352 under transposition, 224 under transposition and inversion
export function classes(withInversion = false): number[] {
  const set = new Set<number>();
  for (let mask = 0; mask < 4096; mask++) set.add(representative(mask, withInversion));
  return [...set].sort((a, b) => a - b);
}

// The sets a page draws: all 4,096, or the 352 transposition classes
export const setsToDraw = (count: number): number[] => (count >= 4096 ? Array.from({ length: 4096 }, (_, i) => i) : classes().slice(0, count));
