// The labelled synthetic corpus: 13 qualities x 12 roots x 4 voicings = 624 strummed clips, generated from seeds, so
// every machine and every CI runner gets the same samples.
//
// For each chord, from voicings.ts's ranking:
//   v0 the most common root-position voicing, v1 a root-position voicing at fret 3 or higher, v2 one at fret 7 or
//   higher, v3 the most common inversion (lowest note not the root).
// Each clip gets one of four conditions, rotating with root + voicing index so every quality sees all four:
//   clean; detuned (the whole guitar 10 to 35 cents sharp or flat, each string a further +-8 cents); noisy (white noise
//   at 12 dB SNR); detuned and noisy.
import { QUALITIES, type Chord } from '../src/dsp/chords.ts';
import { rng, strum, type StrumOptions } from '../src/dsp/synth.ts';
import { voicings, type Voicing } from '../src/dsp/voicings.ts';

export const SAMPLE_RATE = 44100;
export const CLIP_SECONDS = 1.2;
export const LEAD_SECONDS = 0.05;
export const CONDITIONS = ['clean', 'detuned', 'noisy', 'detuned+noisy'] as const;
export const VOICING_KINDS = ['common', 'fret 3+', 'fret 7+', 'inversion'] as const;

export type Clip = {
  id: string;
  chord: Chord;
  voicing: Voicing;
  kind: (typeof VOICING_KINDS)[number];
  condition: (typeof CONDITIONS)[number];
  options: StrumOptions;
};

export function pickVoicings(chord: Chord): Voicing[] {
  const all = voicings(chord);
  const rootPosition = all.filter((v) => !v.inversion);
  const used = new Set<Voicing>();
  const take = (v: Voicing | undefined): Voicing => {
    const chosen = v ?? all.find((x) => !used.has(x))!;
    used.add(chosen);
    return chosen;
  };
  const v0 = take(rootPosition[0]);
  const v1 = take(rootPosition.find((v) => !used.has(v) && v.position >= 3 && Math.abs(v.position - v0.position) >= 2));
  const v2 = take(rootPosition.find((v) => !used.has(v) && v.position >= 7));
  const v3 = take(all.find((v) => !used.has(v) && v.inversion));
  return [v0, v1, v2, v3];
}

export function* corpus(limit = Infinity): Generator<Clip> {
  let count = 0;
  for (let quality = 0; quality < QUALITIES.length; quality++) {
    for (let root = 0; root < 12; root++) {
      const chord = { root, quality };
      const picked = pickVoicings(chord);
      for (let vi = 0; vi < 4; vi++) {
        if (count++ >= limit) return;
        const seed = 1 + quality * 1000 + root * 10 + vi;
        const random = rng(seed ^ 0x5eed);
        const condition = CONDITIONS[(root + vi) % 4];
        const detuned = condition.startsWith('detuned');
        const options: StrumOptions = {
          sampleRate: SAMPLE_RATE,
          seconds: CLIP_SECONDS,
          leadSeconds: LEAD_SECONDS,
          strumMs: 10 + 20 * random(),
          detuneCents: detuned ? (random() < 0.5 ? -1 : 1) * (10 + 25 * random()) : 0,
          stringDetuneCents: detuned ? 8 : 0,
          snrDb: condition.endsWith('noisy') ? 12 : Infinity,
          seed,
        };
        yield { id: `${quality}-${root}-${vi}`, chord, voicing: picked[vi], kind: VOICING_KINDS[vi], condition, options };
      }
    }
  }
}

export const render = (clip: Clip): Float64Array => strum(clip.voicing, clip.options);
