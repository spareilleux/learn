// From a frame of samples to a 12-bin chromagram. The pipeline, and why each step is there:
//  1. Hann window and FFT (fft.ts).
//  2. Magnitude, scaled so a full-scale sinusoid peaks at 1, then log compression log(1 + gamma * a): quiet strings and
//     upper harmonics count, loud low strings don't swamp them (Müller, Fundamentals of Music Processing, 3.1.2.1).
//  3. Spectral whitening: subtract a moving average of the log spectrum whose width grows with frequency (about two
//     semitones each side), and keep what sticks out. Broadband noise and the pick's attack are flat, so they cancel;
//     partials are peaks, so they stay.
//  4. Peak picking with parabolic interpolation: one frequency per partial instead of every bin of its main lobe,
//     which at 8192 samples spans several semitones below 150 Hz.
//  5. Tuning: the circular mean of the peaks' deviation from equal temperament, smoothed over frames, shifts the
//     semitone grid, so a guitar tuned 30 cents flat still falls in the right bins.
//  6. Notes: harmonic summation with cancellation (estimateNotes below) turns the peaks into notes, and each note adds
//     to the pitch class of its nearest semitone; the lowest supported note under 260 Hz is the bass, which the
//     matcher uses to pick a root. With notes = false, every peak adds its whitened height to its pitch class instead,
//     harmonics included, which is the classic chromagram.
// Spectral flux (the sum of positive log-magnitude differences between frames) is computed on the way, for onsets.
import { Fft, hann } from './fft.ts';

export type ChromaOptions = {
  sampleRate: number;
  frameSize: number;
  minHz: number;
  maxHz: number;
  bassMaxHz: number;
  logGamma: number;
  whitening: boolean;
  tuning: boolean;
  /** Estimate notes by harmonic summation before folding into pitch classes (true), or fold every peak (false) */
  notes: boolean;
  /** Highest fundamental considered in note mode: fret 15 of the high E string, G5, is 784 Hz */
  maxNoteHz: number;
  maxNotes: number;
  /** A note is kept while its salience is at least this fraction of the first note's */
  minSalience: number;
  /** A note adds (salience / first salience) ^ power to its pitch class: 1 weighs notes by salience, 0 counts them */
  saliencePower: number;
};

export const defaultChromaOptions = (sampleRate: number): ChromaOptions => ({
  sampleRate,
  frameSize: 8192,
  minHz: 70,
  maxHz: 5000,
  bassMaxHz: 260,
  logGamma: 1000,
  whitening: true,
  tuning: true,
  notes: true,
  maxNoteHz: 800,
  maxNotes: 10,
  minSalience: 0.15,
  saliencePower: 0.5,
});

export type ChromaFrame = {
  chroma: Float64Array;
  bass: Float64Array;
  /** RMS of the windowed frame */
  rms: number;
  /** Spectral flux, positive log-magnitude increase per bin since the previous frame */
  flux: number;
  /** Current tuning estimate, in cents */
  tuningCents: number;
  peaks: number;
};

export class ChromaExtractor {
  readonly options: ChromaOptions;
  private readonly fft: Fft;
  private readonly window: Float64Array;
  private readonly re: Float64Array;
  private readonly im: Float64Array;
  private readonly log: Float64Array;
  private readonly previous: Float64Array;
  private readonly white: Float64Array;
  private readonly prefix: Float64Array;
  private readonly lo: number;
  private readonly hi: number;
  private hasPrevious = false;
  private tuningRe = 0;
  private tuningIm = 0;

  constructor(options: ChromaOptions) {
    this.options = options;
    const n = options.frameSize;
    this.fft = new Fft(n);
    this.window = hann(n);
    this.re = new Float64Array(n);
    this.im = new Float64Array(n);
    this.log = new Float64Array(n / 2);
    this.previous = new Float64Array(n / 2);
    this.white = new Float64Array(n / 2);
    this.prefix = new Float64Array(n / 2 + 1);
    this.lo = Math.max(2, Math.floor((options.minHz * n) / options.sampleRate));
    this.hi = Math.min(n / 2 - 2, Math.ceil((options.maxHz * n) / options.sampleRate));
  }

  /** Analyzes frameSize samples starting at offset. */
  process(samples: ArrayLike<number>, offset = 0): ChromaFrame {
    const { frameSize: n, sampleRate, logGamma, whitening, tuning, bassMaxHz } = this.options;
    const { re, im, log, white, prefix, lo, hi } = this;
    let energy = 0;
    for (let i = 0; i < n; i++) {
      const x = samples[offset + i] * this.window[i];
      re[i] = x;
      im[i] = 0;
      energy += x * x;
    }
    this.fft.transform(re, im);
    // A sinusoid of amplitude A peaks at A * n / 4 under a Hann window
    const scale = 4 / n;
    let flux = 0;
    for (let k = 0; k < n / 2; k++) {
      const a = Math.sqrt(re[k] * re[k] + im[k] * im[k]) * scale;
      log[k] = Math.log1p(logGamma * a);
    }
    for (let k = lo; k <= hi; k++) {
      if (this.hasPrevious) flux += Math.max(0, log[k] - this.previous[k]);
      this.previous[k] = log[k];
    }
    flux /= hi - lo + 1;
    this.hasPrevious = true;

    if (whitening) {
      prefix[0] = 0;
      for (let k = 0; k < n / 2; k++) prefix[k + 1] = prefix[k] + log[k];
      for (let k = lo - 1; k <= hi + 1; k++) {
        const w = Math.max(4, Math.round(0.12 * k));
        const a = Math.max(0, k - w);
        const b = Math.min(n / 2 - 1, k + w);
        white[k] = Math.max(0, log[k] - (prefix[b + 1] - prefix[a]) / (b - a + 1));
      }
    } else {
      for (let k = lo - 1; k <= hi + 1; k++) white[k] = log[k];
    }

    let maxWhite = 0;
    for (let k = lo; k <= hi; k++) maxWhite = Math.max(maxWhite, white[k]);
    const chroma = new Float64Array(12);
    const bass = new Float64Array(12);
    const threshold = 0.1 * maxWhite;
    // Peaks: frequency in semitones relative to A4, and height
    const midis: number[] = [];
    const heights: number[] = [];
    const amplitudes: number[] = [];
    for (let k = lo; k <= hi; k++) {
      const h = white[k];
      if (h <= threshold || h <= white[k - 1] || h < white[k + 1]) continue;
      // Parabolic interpolation on the log spectrum
      const alpha = log[k - 1];
      const beta = log[k];
      const gamma = log[k + 1];
      const denominator = alpha - 2 * beta + gamma;
      const delta = denominator < 0 ? (0.5 * (alpha - gamma)) / denominator : 0;
      const hz = ((k + Math.max(-0.5, Math.min(0.5, delta))) * sampleRate) / n;
      midis.push(69 + 12 * Math.log2(hz / 440));
      heights.push(h);
      amplitudes.push(Math.expm1(beta) / logGamma);
    }

    if (tuning) {
      // Circular mean of the deviations, above 200 Hz where a bin is less than a third of a semitone wide
      let sr = 0;
      let si = 0;
      for (let p = 0; p < midis.length; p++) {
        if (midis[p] < 69 + 12 * Math.log2(200 / 440)) continue;
        const d = midis[p] - Math.round(midis[p]);
        sr += heights[p] * Math.cos(2 * Math.PI * d);
        si += heights[p] * Math.sin(2 * Math.PI * d);
      }
      this.tuningRe = 0.8 * this.tuningRe + sr;
      this.tuningIm = 0.8 * this.tuningIm + si;
    }
    const offsetSemitones = tuning && (this.tuningRe !== 0 || this.tuningIm !== 0) ? Math.atan2(this.tuningIm, this.tuningRe) / (2 * Math.PI) : 0;

    if (this.options.notes) {
      this.estimateNotes(midis, amplitudes, offsetSemitones, chroma, bass);
    } else {
      const bassLimit = 69 + 12 * Math.log2(bassMaxHz / 440);
      let bassPeak = -1;
      for (let p = 0; p < midis.length; p++) {
        const semitone = Math.round(midis[p] - offsetSemitones);
        chroma[((semitone % 12) + 12) % 12] += heights[p];
        if (bassPeak < 0 && midis[p] < bassLimit && heights[p] >= 0.3 * maxWhite) bassPeak = p;
      }
      if (bassPeak >= 0) {
        const semitone = Math.round(midis[bassPeak] - offsetSemitones);
        bass[((semitone % 12) + 12) % 12] = heights[bassPeak];
      }
    }
    return { chroma, bass, rms: Math.sqrt(energy / n), flux, tuningCents: offsetSemitones * 100, peaks: midis.length };
  }

  // Note estimation by harmonic summation with cancellation, after Klapuri (2006). Every peak below maxNoteHz that sits
  // within 35 cents of the tuned semitone grid is a candidate fundamental; its salience is the sum, over harmonics 1 to
  // 10, of the square roots of the amplitudes of the peaks within 40 cents of h times its frequency. The most salient
  // candidate becomes a note, the peaks it explains are removed, and the search repeats, up to maxNotes notes or until
  // the best salience falls under minSalience times the first. The third harmonic of a C no longer votes for G, and
  // the pitch classes of the notes, not of their harmonics, fill the chroma. The price: a real note that coincides with
  // a harmonic of a lower one (the F# of Gmaj7 on the top string, third harmonic of the B an octave and a fifth below)
  // is removed with it.
  private estimateNotes(midis: number[], amplitudes: number[], offset: number, chroma: Float64Array, bass: Float64Array): void {
    const amp = amplitudes.slice();
    const maxNote = 69 + 12 * Math.log2(this.options.maxNoteHz / 440);
    const onGrid = (c: number) => Math.abs(midis[c] - offset - Math.round(midis[c] - offset)) <= 0.35;
    const pcOf = (c: number) => ((Math.round(midis[c] - offset) % 12) + 12) % 12;
    const salienceOf = (c: number) => {
      let salience = 0;
      for (let h = 1; h <= 10; h++) {
        const j = nearest(midis, midis[c] + 12 * Math.log2(h));
        if (j >= 0 && amp[j] > 0) salience += Math.sqrt(amp[j]);
      }
      return salience;
    };

    // Bass, before any cancellation: the lowest on-grid peak under bassMaxHz with at least 10 % of the loudest
    // amplitude there and two of its harmonics 2 to 5 present
    const bassLimit = 69 + 12 * Math.log2(this.options.bassMaxHz / 440);
    let loudest = 0;
    for (let c = 0; c < midis.length && midis[c] < bassLimit; c++) loudest = Math.max(loudest, amp[c]);
    for (let c = 0; c < midis.length && midis[c] < bassLimit; c++) {
      if (!onGrid(c) || amp[c] < 0.1 * loudest) continue;
      let support = 0;
      for (let h = 2; h <= 5; h++) if (nearest(midis, midis[c] + 12 * Math.log2(h)) >= 0) support++;
      if (support >= 2) {
        bass[pcOf(c)] = 1;
        break;
      }
    }

    let first = 0;
    for (let iteration = 0; iteration < this.options.maxNotes; iteration++) {
      let best = -1;
      let bestSalience = 0;
      for (let c = 0; c < midis.length && midis[c] <= maxNote; c++) {
        if (amp[c] <= 0 || !onGrid(c)) continue;
        const salience = salienceOf(c);
        if (salience > bestSalience) {
          bestSalience = salience;
          best = c;
        }
      }
      if (best < 0 || bestSalience < this.options.minSalience * first) break;
      if (iteration === 0) first = bestSalience;
      chroma[pcOf(best)] += (bestSalience / first) ** this.options.saliencePower;
      for (let h = 1; h <= 10; h++) {
        const j = nearest(midis, midis[best] + 12 * Math.log2(h));
        if (j >= 0) amp[j] = 0;
      }
    }
  }
}

/** Index of the peak within 40 cents of a pitch, or -1 */
function nearest(midis: number[], target: number): number {
  let best = -1;
  let distance = 0.4;
  for (let j = 0; j < midis.length; j++) {
    const d = Math.abs(midis[j] - target);
    if (d < distance) {
      distance = d;
      best = j;
    }
  }
  return best;
}
