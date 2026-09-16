// Opens a lesson page in headless Chromium and prints what it reports:
//   node scripts/probe.mjs <page> [--webgl] [--query key=value] [--shot <file.png>] [--extract <key> <file>]
// The page is served by Vite's dev server, loaded with ?probe, and must set window.probe (see src/probe.ts).
// If the page reports samples ({ name: [x, y] } in CSS pixels), the screenshot's color at each point is printed instead.
// The browser's warnings and errors are printed first: three.js reports its backend fallback there.
// PROBE_CHANNEL=chromium-headless-shell uses Playwright's older headless shell instead of Chromium's new headless mode.
import { writeFileSync } from 'node:fs';
import { chromium } from 'playwright';
import { PNG } from 'pngjs';
import { createServer } from 'vite';

const [pageName, ...rest] = process.argv.slice(2);
const option = (name) => (rest.includes(name) ? rest[rest.indexOf(name) + 1] : null);
const params = ['probe'];
if (rest.includes('--webgl')) params.push('webgl');
if (option('--query')) params.push(option('--query'));

const server = await createServer({ configFile: 'vite.config.ts', logLevel: 'silent' });
await server.listen();
const browser = await chromium.launch({ channel: process.env.PROBE_CHANNEL ?? 'chromium' });
try {
  const page = await browser.newPage({ viewport: { width: 800, height: 450 }, deviceScaleFactor: 1 });
  const messages = [];
  page.on('console', (message) => {
    const text = message.text();
    // Chromium's own notices vary with the GPU driver; the favicon is absent on purpose
    if (/GL Driver Message|Failed to load resource/.test(text)) return;
    if (message.type() === 'warning' || message.type() === 'error') messages.push(`console.${message.type()}: ${text}`);
  });
  page.on('pageerror', (error) => messages.push(`pageerror: ${error.message}`));
  await page.goto(`http://localhost:5188/${pageName}.html?${params.join('&')}`);
  // A page that never reports fails after 30 s instead of waiting forever
  const result = await page.evaluate(() => Promise.race([window.probe, new Promise((_, reject) => setTimeout(() => reject(new Error('no probe result after 30 s')), 30_000))]));
  // Pages that need a pointer list actions: each is performed with Playwright's mouse, which the browser turns into real
  // pointer events, then window.probeAfter(name) returns what the page saw
  let screenshot = null;
  if (result.actions) {
    result.after = {};
    for (const { name, move, drag } of result.actions) {
      if (move) await page.mouse.move(move[0], move[1], { steps: 5 });
      if (drag) {
        await page.mouse.move(drag[0], drag[1]);
        await page.mouse.down();
        await page.mouse.move(drag[2], drag[3], { steps: 10 });
        await page.mouse.up();
      }
      result.after[name] = await page.evaluate((n) => window.probeAfter(n), name);
      if (result.shotAfter === name) screenshot = await page.screenshot();
    }
    delete result.actions;
    delete result.shotAfter;
  }
  // Long text, such as generated shader code, goes to its own file: --extract <key> <file>
  if (option('--extract')) {
    const key = option('--extract');
    writeFileSync(rest[rest.indexOf('--extract') + 2], String(result[key]));
    delete result[key];
  }
  screenshot ??= await page.screenshot();
  if (option('--shot')) writeFileSync(option('--shot'), screenshot);
  if (result.samples) {
    const png = PNG.sync.read(screenshot);
    result.pixels = Object.fromEntries(
      Object.entries(result.samples).map(([name, [x, y]]) => {
        const i = (y * png.width + x) * 4;
        return [name, `rgb(${png.data[i]}, ${png.data[i + 1]}, ${png.data[i + 2]})`];
      }),
    );
    delete result.samples;
  }
  for (const message of messages) console.log(message);
  // Arrays of numbers on one line
  console.log(JSON.stringify(result, null, 2).replace(/\[\s+([\d.,\s-]+?)\s+\]/g, (_, items) => `[${items.split(/,\s+/).join(', ')}]`));
} finally {
  await browser.close();
  await server.close();
}
