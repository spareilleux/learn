// Experiment 4's pitch-class set arithmetic, checked against the known counts
import { describe, expect, it } from 'vitest';
import { classes, invert, representative, setsToDraw, transpose } from '../src/04-bracelet/pcs.ts';

const C_MAJOR_TRIAD = 0b000010010001; // C, E, G

describe('pitch-class sets', () => {
  it('transposes by rotating the 12 bits', () => {
    expect(transpose(C_MAJOR_TRIAD, 2)).toBe(0b001001000100); // D, F#, A
    expect(transpose(C_MAJOR_TRIAD, 12)).toBe(C_MAJOR_TRIAD);
    expect(transpose(C_MAJOR_TRIAD, -1)).toBe(transpose(C_MAJOR_TRIAD, 11));
  });

  it('inverts a major triad into a minor one', () => {
    // −{0, 4, 7} = {0, 8, 5}: F minor
    expect(invert(C_MAJOR_TRIAD)).toBe((1 << 0) | (1 << 5) | (1 << 8));
    expect(representative(invert(C_MAJOR_TRIAD), true)).toBe(representative(C_MAJOR_TRIAD, true));
  });

  it('finds 352 transposition classes and 224 transposition-inversion classes', () => {
    expect(classes().length).toBe(352);
    expect(classes(true).length).toBe(224);
  });

  it('draws every set or the first classes', () => {
    expect(setsToDraw(4096).length).toBe(4096);
    expect(setsToDraw(352)).toEqual(classes());
  });
});
