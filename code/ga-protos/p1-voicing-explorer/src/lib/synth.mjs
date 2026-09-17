// Plucked strings by Karplus-Strong: a delay line one period long, filled with noise, fed back through a two-point
// average. The average is a low-pass filter, so the high partials die first, as on a real string.
// Pure functions: they return samples, and the page hands them to WebAudio.
import { mulberry32 } from './sample.mjs';

export const midiToHz = (midi) => 440 * 2 ** ((midi - 69) / 12);

export function pluck(frequency, { sampleRate = 44100, seconds = 2, decay = 0.996, seed = 1 } = {}) {
  const period = Math.max(2, Math.round(sampleRate / frequency));
  const random = mulberry32(seed);
  const line = new Float32Array(period);
  for (let i = 0; i < period; i++) line[i] = random() * 2 - 1;
  const out = new Float32Array(Math.round(sampleRate * seconds));
  for (let i = 0; i < out.length; i++) {
    const j = i % period;
    const next = line[(j + 1) % period];
    out[i] = line[j];
    line[j] = decay * 0.5 * (line[j] + next);
  }
  return out;
}

// A strum: the notes in playing order (low string first), each starting strumMs after the previous one
export function strum(midiNotesLowFirst, { sampleRate = 44100, seconds = 2.5, strumMs = 35, gain = 0.25 } = {}) {
  const offset = Math.round((sampleRate * strumMs) / 1000);
  const out = new Float32Array(Math.round(sampleRate * seconds) + offset * midiNotesLowFirst.length);
  midiNotesLowFirst.forEach((midi, i) => {
    const samples = pluck(midiToHz(midi), { sampleRate, seconds, seed: 1 + i });
    for (let s = 0; s < samples.length; s++) out[i * offset + s] += gain * samples[s];
  });
  return out;
}
