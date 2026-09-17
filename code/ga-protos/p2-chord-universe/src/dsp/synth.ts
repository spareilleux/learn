// A plucked-string synthesizer (Karplus-Strong), deterministic from a seed, shared by the corpus generator in Node.js
// and the demo mode in the browser.
//
// Karplus and Strong (1983) fill a delay line of length sampleRate / f with noise and feed it back through the average
// of two neighbouring samples. Jaffe and Smith (1983) added what makes it usable for pitch work: the averaging filter
// delays by half a sample, and a first-order allpass supplies the fractional rest of the period, so a note is in tune
// to a fraction of a cent instead of up to half a sample off (26 cents at 1.3 kHz and 44.1 kHz).
import { midiNotes, type Voicing } from './voicings.ts';

/** mulberry32: a 32-bit seeded generator, identical in every JavaScript engine */
export function rng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export const midiToHz = (midi: number): number => 440 * 2 ** ((midi - 69) / 12);

/** Adds one plucked note to out, starting at sample start. */
export function pluck(out: Float64Array, start: number, sampleRate: number, hz: number, amplitude: number, random: () => number, decay = 0.9965): void {
  const period = sampleRate / hz;
  // The sample read now was written n samples ago from the average of two outputs n and n - 1 samples old, so the
  // loop delays by n - 0.5, and the allpass adds the rest, kept in [0.1, 1.1) where its delay is close to frac
  const n = Math.floor(period + 0.5 - 0.1);
  const frac = period + 0.5 - n;
  const c = (1 - frac) / (1 + frac);
  const buffer = new Float64Array(n);
  // Excitation: white noise through a one-pole low-pass, which softens the attack like a pick of medium brightness
  let lp = 0;
  let mean = 0;
  for (let i = 0; i < n; i++) {
    lp = 0.5 * lp + 0.5 * (random() * 2 - 1);
    buffer[i] = lp;
    mean += lp;
  }
  mean /= n;
  for (let i = 0; i < n; i++) buffer[i] -= mean;
  let index = 0;
  let apIn = 0;
  let apOut = 0;
  const length = Math.min(out.length - start, Math.floor(sampleRate * 4));
  for (let t = 0; t < length; t++) {
    const x = buffer[index];
    const next = buffer[(index + 1) % n];
    out[start + t] += amplitude * x;
    const averaged = decay * 0.5 * (x + next);
    // First-order allpass: y[n] = c x[n] + x[n-1] - c y[n-1]
    const y = c * averaged + apIn - c * apOut;
    apIn = averaged;
    apOut = y;
    buffer[index] = y;
    index = (index + 1) % n;
  }
}

export type StrumOptions = {
  sampleRate: number;
  seconds: number;
  /** Silence before the strum */
  leadSeconds: number;
  /** Delay between two strings of the strum, low to high */
  strumMs: number;
  /** Global detuning of the guitar, in cents */
  detuneCents: number;
  /** Random detuning of each string around it, in cents (plus or minus) */
  stringDetuneCents: number;
  /** Signal-to-noise ratio of added white noise in dB; Infinity for none */
  snrDb: number;
  seed: number;
};

/** A strummed voicing, peak-normalized to 0.5, with optional detuning and noise. */
export function strum(voicing: Voicing, o: StrumOptions): Float64Array {
  const random = rng(o.seed);
  const out = new Float64Array(Math.round(o.sampleRate * o.seconds));
  const notes = midiNotes(voicing);
  notes.forEach((midi, i) => {
    const cents = o.detuneCents + (random() * 2 - 1) * o.stringDetuneCents;
    const start = Math.round(o.sampleRate * (o.leadSeconds + (i * o.strumMs) / 1000));
    pluck(out, start, o.sampleRate, midiToHz(midi + cents / 100), 0.6 + 0.4 * random(), random);
  });
  let peak = 0;
  for (let i = 0; i < out.length; i++) peak = Math.max(peak, Math.abs(out[i]));
  if (peak > 0) for (let i = 0; i < out.length; i++) out[i] *= 0.5 / peak;
  if (Number.isFinite(o.snrDb)) {
    let power = 0;
    const from = Math.round(o.sampleRate * o.leadSeconds);
    for (let i = from; i < out.length; i++) power += out[i] * out[i];
    power /= Math.max(1, out.length - from);
    const sigma = Math.sqrt(power / 10 ** (o.snrDb / 10));
    // Gaussian noise by Box-Muller
    for (let i = 0; i < out.length; i++) {
      const u = Math.max(1e-12, random());
      const v = random();
      out[i] += sigma * Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
    }
  }
  return out;
}

/** 16-bit PCM mono WAV bytes. */
export function wav(samples: ArrayLike<number>, sampleRate: number): Uint8Array {
  const bytes = new Uint8Array(44 + samples.length * 2);
  const view = new DataView(bytes.buffer);
  const ascii = (at: number, s: string) => [...s].forEach((ch, i) => view.setUint8(at + i, ch.charCodeAt(0)));
  ascii(0, 'RIFF');
  view.setUint32(4, 36 + samples.length * 2, true);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * 2, true);
  view.setUint16(32, 2, true);
  view.setUint16(34, 16, true);
  ascii(36, 'data');
  view.setUint32(40, samples.length * 2, true);
  for (let i = 0; i < samples.length; i++) view.setInt16(44 + i * 2, Math.round(Math.max(-1, Math.min(1, samples[i])) * 32767), true);
  return bytes;
}
