// Opens the explorer in headless Chromium with ?probe and prints its frame-time report as one JSON line:
//   node scripts/probe.mjs [--webgl] [--mode points] [--data data-full] [--synthetic n] [--frames 120] [--select i] [--shot file.png]
// Serves the project with Vite's dev server. Playwright's default headless Chromium gets a real WebGPU adapter on Windows;
// on a CI runner without a GPU it falls back to a software rasterizer, so its times mean nothing there.
import { writeFileSync } from 'node:fs';
import { chromium } from 'playwright';
import { createServer } from 'vite';

const args = process.argv.slice(2);
const option = (name) => (args.includes(name) ? args[args.indexOf(name) + 1] : null);
const query = ['probe'];
if (args.includes('--webgl')) query.push('webgl');
for (const key of ['mode', 'data', 'synthetic', 'frames', 'select']) if (option(`--${key}`)) query.push(`${key}=${option(`--${key}`)}`);
const timeoutMs = Number(process.env.PROBE_TIMEOUT ?? 120) * 1000;

const server = await createServer({ configFile: 'vite.config.mjs', logLevel: 'silent' });
await server.listen();
// channel 'chromium' is Chromium's new headless mode, which gets a GPU adapter; the default headless shell has none
const browser = await chromium.launch({ channel: process.env.PROBE_CHANNEL ?? 'chromium' });
try {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const messages = [];
  page.on('console', (m) => (m.type() === 'error' || m.type() === 'warning') && !/GL Driver Message|favicon/.test(m.text()) && messages.push(`console.${m.type()}: ${m.text()}`));
  page.on('pageerror', (e) => messages.push(`pageerror: ${e.message}`));
  const t0 = Date.now();
  await page.goto(`http://localhost:5198/index.html?${query.join('&')}`);
  const result = await page.evaluate(
    (ms) => Promise.race([window.probe, new Promise((_, reject) => setTimeout(() => reject(new Error(`no probe result after ${ms / 1000} s`)), ms))]),
    timeoutMs,
  );
  result.pageToReportMs = Date.now() - t0;
  result.browser = browser.version();
  if (option('--shot')) writeFileSync(option('--shot'), await page.screenshot());
  for (const m of messages) console.log(m);
  console.log(JSON.stringify(result));
} finally {
  await browser.close();
  await server.close();
}
