// One run of the built app in headless Chromium with a fake microphone: node scripts/browser-run.ts [--webgl]
// Needs `npm run build` and `node scripts/fake-mic.ts` first. Serves dist/ on localhost (a secure context, so
// getUserMedia is allowed), grants the microphone without a prompt, feeds out/fake-mic.wav as its signal, opens
// ?source=mic, waits for the progression to play, and writes out/browser-run.json: the renderer backend, the sample
// rate, the labels in order, how many of the expected chords were found in order, and the compute time per frame.
// The machine's timings are for the author's machine; on CI runners they are counters only.
import { createReadStream, existsSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const root = fileURLToPath(new URL('..', import.meta.url));
const dist = join(root, 'dist');
const wavPath = join(root, 'out', 'fake-mic.wav');
const labels = JSON.parse(readFileSync(join(root, 'out', 'fake-mic.json'), 'utf8')) as { secondsPerChord: number; chords: string[] };
const forceWebGL = process.argv.includes('--webgl');
const types: Record<string, string> = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json' };

const server = createServer((request, response) => {
  const path = normalize(join(dist, decodeURIComponent(new URL(request.url ?? '/', 'http://x').pathname)));
  const file = existsSync(path) && statSync(path).isDirectory() ? join(path, 'index.html') : path;
  if (!file.startsWith(dist) || !existsSync(file)) {
    response.writeHead(404).end();
    return;
  }
  response.writeHead(200, { 'content-type': types[extname(file)] ?? 'application/octet-stream' });
  createReadStream(file).pipe(response);
});
await new Promise<void>((resolve) => server.listen(5194, '127.0.0.1', resolve));

const browser = await chromium.launch({
  args: [
    '--use-fake-ui-for-media-stream',
    '--use-fake-device-for-media-stream',
    `--use-file-for-fake-audio-capture=${wavPath}`,
    '--autoplay-policy=no-user-gesture-required',
    '--enable-unsafe-webgpu',
  ],
});
const requests: string[] = [];
try {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('request', (r) => requests.push(r.url()));
  await page.goto(`http://localhost:5194/?source=mic${forceWebGL ? '&webgl' : ''}`);
  const seconds = labels.chords.length * labels.secondsPerChord + 1;
  await page.waitForTimeout(seconds * 1000);
  const probe = await page.evaluate(() => (window as unknown as { __p2: { backend: string; sampleRate: number; frames: number; computeMs: number[]; labels: { t: number; name: string; confidence: number }[]; error?: string } }).__p2);
  await page.screenshot({ path: join(root, 'out', 'browser-run.png') });
  // Longest common subsequence between the expected chords and the labels, over the first pass of the looping file
  const found = probe.labels.filter((l) => l.t < seconds * 1000).map((l) => l.name);
  const a = labels.chords;
  const table = Array.from({ length: a.length + 1 }, () => new Array<number>(found.length + 1).fill(0));
  for (let i = 1; i <= a.length; i++)
    for (let j = 1; j <= found.length; j++) table[i][j] = a[i - 1] === found[j - 1] ? table[i - 1][j - 1] + 1 : Math.max(table[i - 1][j], table[i][j - 1]);
  const sorted = [...probe.computeMs].sort((x, y) => x - y);
  const result = {
    backend: probe.backend,
    browser: browser.version(),
    sampleRate: probe.sampleRate,
    frames: probe.frames,
    error: probe.error ?? null,
    expected: a,
    labels: probe.labels,
    inOrder: table[a.length][found.length],
    extraLabels: found.length - table[a.length][found.length],
    computeMedianMs: sorted[sorted.length >> 1],
    computeP95Ms: sorted[Math.floor(sorted.length * 0.95)],
    // Every request the page made: only localhost, and no audio upload
    offsite: requests.filter((u) => !u.startsWith('http://localhost:5194/')),
  };
  writeFileSync(join(root, 'out', 'browser-run.json'), JSON.stringify(result, null, 2) + '\n');
  console.log(`${result.backend}, ${result.browser}, ${result.sampleRate} Hz, ${result.frames} frames`);
  console.log(`expected chords found in order: ${result.inOrder} of ${a.length}, extra labels: ${result.extraLabels}`);
  console.log(`labels: ${found.join(' ')}`);
  console.log(`compute per frame: median ${result.computeMedianMs?.toFixed(2)} ms, p95 ${result.computeP95Ms?.toFixed(2)} ms; offsite requests: ${result.offsite.length}`);
} finally {
  await browser.close();
  server.close();
}
