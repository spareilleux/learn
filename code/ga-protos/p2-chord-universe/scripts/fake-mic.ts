// Writes out/fake-mic.wav, the app's demo progression strummed at 48 kHz, 2 s per chord, and out/fake-mic.json, its
// labels. Chromium plays the WAV as the microphone with --use-file-for-fake-audio-capture (scripts/browser-run.ts).
import { mkdirSync, writeFileSync } from 'node:fs';
import { chordName } from '../src/dsp/chords.ts';
import { strum, wav } from '../src/dsp/synth.ts';
import { voicings } from '../src/dsp/voicings.ts';
import { DEMO } from '../src/app/demo.ts';

export const RATE = 48000;
export const SECONDS = 2;

const out = new Float64Array(RATE * SECONDS * DEMO.length + RATE);
DEMO.forEach((chord, i) => {
  const clip = strum(voicings(chord)[0], {
    sampleRate: RATE, seconds: SECONDS, leadSeconds: 0.02, strumMs: 18, detuneCents: -12, stringDetuneCents: 4, snrDb: 30, seed: 500 + i,
  });
  out.set(clip, i * RATE * SECONDS);
});
const dir = new URL('../out/', import.meta.url);
mkdirSync(dir, { recursive: true });
writeFileSync(new URL('fake-mic.wav', dir), wav(out, RATE));
writeFileSync(new URL('fake-mic.json', dir), JSON.stringify({ sampleRate: RATE, secondsPerChord: SECONDS, chords: DEMO.map(chordName) }, null, 2) + '\n');
console.log(`out/fake-mic.wav: ${DEMO.length} chords, ${(out.length / RATE).toFixed(1)} s at ${RATE} Hz`);
