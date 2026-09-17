// From frames to a stable chord label. Three rules, each with one parameter:
//  - onset: the spectral flux jumps above twice the median of the last 8 frames plus a floor; a new strum resets the
//    accumulated chroma, so the previous chord's ringing strings stop voting;
//  - integration: between onsets, chroma and bass add up with a decay of 0.75 per frame, so the label rests on the
//    last few frames rather than on one;
//  - stability: a label replaces the current one only after winning 2 frames in a row, and silence (RMS below a floor)
//    clears it.
import { matchChord, DEFAULT_MATCH, type Candidate, type MatchOptions } from './chords.ts';
import type { ChromaFrame } from './chroma.ts';

export type TrackerOptions = {
  decay: number;
  stableFrames: number;
  onsetRatio: number;
  onsetFloor: number;
  silenceRms: number;
  match: MatchOptions;
};

export const DEFAULT_TRACKER: TrackerOptions = { decay: 0.75, stableFrames: 2, onsetRatio: 2, onsetFloor: 0.02, silenceRms: 0.002, match: DEFAULT_MATCH };

export type TrackerState = {
  onset: boolean;
  /** Best candidates for the integrated chroma of this frame, best first (top 3) */
  top: Candidate[];
  /** The stable label, or null when nothing is playing or nothing has been stable yet */
  stable: Candidate | null;
  chroma: Float64Array;
};

export class ChordTracker {
  readonly options: TrackerOptions;
  private readonly chroma = new Float64Array(12);
  private readonly bass = new Float64Array(12);
  private readonly fluxHistory: number[] = [];
  private pending = '';
  private pendingCount = 0;
  private stable: Candidate | null = null;

  constructor(options: TrackerOptions = DEFAULT_TRACKER) {
    this.options = options;
  }

  push(frame: ChromaFrame): TrackerState {
    const o = this.options;
    const sorted = [...this.fluxHistory].sort((a, b) => a - b);
    const median = sorted.length ? sorted[sorted.length >> 1] : 0;
    const onset = frame.flux > o.onsetRatio * median + o.onsetFloor && frame.rms > o.silenceRms;
    this.fluxHistory.push(frame.flux);
    if (this.fluxHistory.length > 8) this.fluxHistory.shift();

    if (onset) {
      this.chroma.fill(0);
      this.bass.fill(0);
    }
    for (let i = 0; i < 12; i++) {
      this.chroma[i] = this.chroma[i] * o.decay + frame.chroma[i];
      this.bass[i] = this.bass[i] * o.decay + frame.bass[i];
    }
    if (frame.rms <= o.silenceRms) {
      this.pending = '';
      this.pendingCount = 0;
      this.stable = null;
      return { onset, top: [], stable: null, chroma: Float64Array.from(this.chroma) };
    }
    const all = matchChord(this.chroma, this.bass, o.match);
    const best = all[0];
    if (best.name === this.pending) this.pendingCount++;
    else {
      this.pending = best.name;
      this.pendingCount = 1;
    }
    if (this.pendingCount >= o.stableFrames) this.stable = best;
    else if (this.stable && this.stable.name === best.name) this.stable = best;
    return { onset, top: all.slice(0, 3), stable: this.stable, chroma: Float64Array.from(this.chroma) };
  }
}
