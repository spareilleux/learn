// The demo progression, shared by the app and the fake microphone file of the headless measurement.
import { QUALITIES, type Chord } from '../dsp/chords.ts';

const q = (symbol: string) => QUALITIES.findIndex((x) => x.symbol === symbol);
/** The demo: a ii-V-I, a minor cadence with a secondary dominant, then the symmetrical chords */
export const DEMO: Chord[] = [
  { root: 0, quality: q('') },
  { root: 9, quality: q('m') },
  { root: 2, quality: q('m7') },
  { root: 7, quality: q('7') },
  { root: 0, quality: q('maj7') },
  { root: 5, quality: q('') },
  { root: 11, quality: q('m7b5') },
  { root: 4, quality: q('7') },
  { root: 9, quality: q('m') },
  { root: 2, quality: q('sus4') },
  { root: 2, quality: q('') },
  { root: 7, quality: q('add9') },
  { root: 7, quality: q('6') },
  { root: 0, quality: q('aug') },
  { root: 1, quality: q('dim7') },
  { root: 2, quality: q('m') },
];
export const DEMO_SECONDS_PER_CHORD = 1.6;
