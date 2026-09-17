// Decodes the recorded corpus (eval/recorded/*.mp3, Freesound previews of CC0 recordings) with Chromium's own MP3
// decoder, the one the app uses for a file, resampled to 44.1 kHz, mixed to mono, first 8 seconds, into
// out/recorded/<id>.f32 (raw little-endian float32). Node.js has no MP3 decoder, and adding one would be a dependency
// that the browser doesn't use.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { chromium } from 'playwright';

const sources = JSON.parse(readFileSync(new URL('../eval/recorded/sources.json', import.meta.url), 'utf8')) as { id: string }[];
const out = new URL('../out/recorded/', import.meta.url);
mkdirSync(out, { recursive: true });
const browser = await chromium.launch();
try {
  const page = await browser.newPage();
  await page.setContent('<!doctype html><title>decode</title>');
  for (const { id } of sources) {
    const base64 = readFileSync(new URL(`../eval/recorded/${id}.mp3`, import.meta.url)).toString('base64');
    const samples = await page.evaluate(async (data) => {
      const bytes = Uint8Array.from(atob(data), (c) => c.charCodeAt(0));
      const context = new OfflineAudioContext(1, 1, 44100);
      const audio = await context.decodeAudioData(bytes.buffer);
      const length = Math.min(audio.length, 8 * 44100);
      const mono = new Float32Array(length);
      for (let ch = 0; ch < audio.numberOfChannels; ch++) {
        const channel = audio.getChannelData(ch);
        for (let i = 0; i < length; i++) mono[i] += channel[i] / audio.numberOfChannels;
      }
      return { values: Array.from(mono), seconds: audio.duration };
    }, base64);
    writeFileSync(new URL(`${id}.f32`, out), new Uint8Array(Float32Array.from(samples.values).buffer));
    console.log(`${id}: ${samples.seconds.toFixed(2)} s, kept ${(samples.values.length / 44100).toFixed(2)} s`);
  }
} finally {
  await browser.close();
}
