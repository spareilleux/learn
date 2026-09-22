// Serves the site's public/ folder under /learn/ like GitHub Pages, opens the published explorer with ?probe&frames=5,
// and fails on a page error or a wrong point count: node scripts/check-published.mjs [--root ../../../public]
import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, resolve } from 'node:path';
import { chromium } from 'playwright';

const args = process.argv.slice(2);
const root = resolve(args.includes('--root') ? args[args.indexOf('--root') + 1] : '../../../public');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.bin': 'application/octet-stream', '.png': 'image/png' };
const server = createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  if (!url.pathname.startsWith('/learn/')) return res.writeHead(404).end();
  let file = join(root, decodeURIComponent(url.pathname.slice('/learn/'.length)));
  if (existsSync(file) && statSync(file).isDirectory()) file = join(file, 'index.html');
  if (!existsSync(file)) return res.writeHead(404).end();
  res.writeHead(200, { 'content-type': types[extname(file)] ?? 'application/octet-stream' });
  createReadStream(file).pipe(res);
});
// Ask the OS for a free loopback port so concurrent checks and local dev servers cannot collide.
await new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(0, '127.0.0.1', resolve);
});
const { port } = server.address();
const browser = await chromium.launch({ channel: process.env.PROBE_CHANNEL ?? 'chromium' });
let failed = false;
try {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('pageerror', (e) => {
    console.log(`pageerror: ${e.message}`);
    failed = true;
  });
  page.on('response', (r) => r.status() >= 400 && console.log(`HTTP ${r.status()} ${r.url()}`));
  await page.goto(`http://127.0.0.1:${port}/learn/ga-lab/p1/?probe&frames=5`);
  const result = await page.evaluate(() => Promise.race([window.probe, new Promise((_, reject) => setTimeout(() => reject(new Error('no probe result')), 60000))]));
  console.log(JSON.stringify({ backend: result.backend, points: result.points, dataBytes: result.dataBytes }));
  if (result.points !== 30000 && !args.includes('--any-count')) failed = true;
} finally {
  await browser.close();
  server.close();
}
process.exit(failed ? 1 : 0);
