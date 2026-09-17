// Runs the lab's experiments and records what they measured:
//   node scripts/run.mjs <experiment…|all> [--run <name>] [--ci] [--timeout <seconds>]
// Each experiments/<id>.json lists its runs: a page of this folder with a query (opened in headless Chromium, like lesson
// 12's scripts/probe.mjs, but with the flags below and several runs per browser), or a Node.js script.
// Without --ci: writes results/<id>/results.json (the experiment's hypothesis and predictions, the machine, every run's
// result and console messages) and a small WebP screenshot per page run.
// With --ci: runs the experiment's "ci" list with ?ci (few frames), writes out/<id>/<run>.txt with the run's counters and
// checks only, and compares it with expected/<id>__<run>.txt (UPDATE=1 writes expected/ instead). No times are compared.
import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { cpus, arch, release, totalmem, type as osType } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { chromium } from 'playwright';
import pixelmatch from 'pixelmatch';
import { PNG } from 'pngjs';
import { createServer } from 'vite';

const lab = resolve(import.meta.dirname, '..');
const args = process.argv.slice(2);
const option = (name) => (args.includes(name) ? args[args.indexOf(name) + 1] : null);
const ciMode = args.includes('--ci');
const onlyRun = option('--run');
const defaultTimeout = Number(option('--timeout') ?? (ciMode ? 240 : 180));
const optionValues = new Set([onlyRun, option('--timeout')].filter(Boolean));
const wanted = args.filter((a) => !a.startsWith('--') && !optionValues.has(a));

// No vsync, no frame rate limit, and WebGPU timestamps at full precision (Chromium quantizes them to 100 µs otherwise)
// Experiment 14 reads the JavaScript heap after a garbage collection; experiment 13 plays audio without a click
const CHROMIUM_ARGS = [
  '--disable-gpu-vsync',
  '--disable-frame-rate-limit',
  '--enable-webgpu-developer-features',
  '--autoplay-policy=no-user-gesture-required',
  '--enable-precise-memory-info',
  '--js-flags=--expose-gc',
];

const files = readdirSync(join(lab, 'experiments')).filter((f) => f.endsWith('.json')).sort();
const experiments = files
  .map((f) => JSON.parse(readFileSync(join(lab, 'experiments', f), 'utf8')))
  .filter((e) => wanted.includes('all') || wanted.some((w) => e.id === w || e.id.startsWith(`${w}-`)));
if (experiments.length === 0) {
  console.error(`usage: node scripts/run.mjs <experiment…|all> [--run name] [--ci]; experiments: ${files.join(', ')}`);
  process.exit(2);
}

function machine(browserVersion) {
  let gpu = null;
  try {
    const [name, driver] = execFileSync('nvidia-smi', ['--query-gpu=name,driver_version', '--format=csv,noheader'], { encoding: 'utf8' }).trim().split(', ');
    gpu = { name, driver };
  } catch {
    gpu = null;
  }
  const version = (name) => JSON.parse(readFileSync(resolve(lab, '..', 'node_modules', name, 'package.json'), 'utf8')).version;
  return {
    os: `${osType()} ${release()} ${arch()}`,
    cpu: cpus()[0]?.model.trim(),
    memoryGB: Math.round(totalmem() / 2 ** 30),
    gpu,
    node: process.version,
    three: version('three'),
    playwright: version('playwright'),
    browser: browserVersion,
    chromiumArgs: CHROMIUM_ARGS,
  };
}

async function toWebP(browser, png, width = 640) {
  const page = await browser.newPage();
  try {
    return await page.evaluate(
      async ({ data, width }) => {
        const image = new Image();
        image.src = `data:image/png;base64,${data}`;
        await image.decode();
        const canvas = document.createElement('canvas');
        canvas.width = Math.min(width, image.width);
        canvas.height = Math.round((image.height * canvas.width) / image.width);
        canvas.getContext('2d').drawImage(image, 0, 0, canvas.width, canvas.height);
        return canvas.toDataURL('image/webp', 0.8).split(',')[1];
      },
      { data: png.toString('base64'), width },
    );
  } finally {
    await page.close();
  }
}

// Numbers rounded for the compared files, so that a float's last digits don't fail a run
function stable(value) {
  return JSON.stringify(value, (_, v) => (typeof v === 'number' && !Number.isInteger(v) ? Math.round(v * 1000) / 1000 : v), 2);
}

let status = 0;
const server = await createServer({ configFile: join(lab, 'vite.config.ts'), logLevel: 'silent' });
await server.listen();
const port = server.config.server.port;
const browsers = new Map();
// LAB_CHANNEL=chromium-headless-shell runs everything on SwiftShader, without the GPU (for a local --ci run)
async function browserFor(run) {
  run = { ...run, channel: process.env.LAB_CHANNEL ?? run.channel };
  const key = `${run.channel ?? 'chromium'}${run.headed ? ' headed' : ''}${run.vsync ? ' vsync' : ''}`;
  if (!browsers.has(key)) {
    // One browser at a time: the machine is shared
    for (const [k, b] of browsers) {
      await b.close();
      browsers.delete(k);
    }
    // "vsync": true keeps Chromium's frame pacing, for pages that measure time against frames
    const flags = run.vsync ? CHROMIUM_ARGS.filter((a) => !/vsync|frame-rate-limit/.test(a)) : CHROMIUM_ARGS;
    browsers.set(key, await chromium.launch({ channel: run.channel ?? 'chromium', headless: !run.headed, args: flags }));
  }
  return browsers.get(key);
}

try {
  for (const experiment of experiments) {
    const runs = (ciMode ? experiment.ci : experiment.runs).filter((r) => !onlyRun || r.name === onlyRun);
    // LAB_RESULTS=<dir> writes a trial run elsewhere than results/
    const outDir = ciMode ? join(lab, 'out', experiment.id) : join(process.env.LAB_RESULTS ?? join(lab, 'results'), experiment.id);
    mkdirSync(outDir, { recursive: true });
    const resultsFile = join(outDir, 'results.json');
    // A partial run (--run) updates its entry and keeps the others
    const previous = !ciMode && onlyRun && existsSync(resultsFile) ? JSON.parse(readFileSync(resultsFile, 'utf8')) : null;
    const record = {
      experiment: experiment.id,
      title: experiment.title,
      hypothesis: experiment.hypothesis,
      predictions: experiment.predictions,
      date: new Date().toISOString(),
      machine: null,
      runs: previous?.runs ?? [],
    };
    const shots = {};
    for (const run of runs) {
      console.log(`${experiment.id} / ${run.name}`);
      let entry;
      if (experiment.node || run.node) {
        const started = Date.now();
        const child = spawnSync(process.execPath, [run.node ?? experiment.node, ...(run.args ?? [])], { cwd: lab, encoding: 'utf8', timeout: defaultTimeout * 1000 });
        const lines = child.stdout.trim().split('\n');
        let result;
        try {
          result = JSON.parse(lines.slice(lines.findIndex((l) => l.startsWith('{'))).join('\n'));
        } catch {
          result = { error: `no JSON result, exit ${child.status}`, stdout: child.stdout.slice(-2000), stderr: child.stderr.slice(-2000) };
        }
        entry = { name: run.name, args: run.args ?? [], wallSeconds: (Date.now() - started) / 1000, result };
        record.machine ??= machine(null);
      } else {
        const browser = await browserFor(run);
        record.machine ??= machine(browser.version());
        const page = await browser.newPage({ viewport: { width: run.viewport?.[0] ?? 1280, height: run.viewport?.[1] ?? 720 }, deviceScaleFactor: 1 });
        const messages = [];
        page.on('console', (m) => {
          if (/GL Driver Message|Failed to load resource/.test(m.text())) return;
          if (m.type() === 'warning' || m.type() === 'error') messages.push(`console.${m.type()}: ${m.text()}`);
        });
        page.on('pageerror', (e) => messages.push(`pageerror: ${e.message}`));
        // In CI every page runs on WebGL 2, the backend all three runners share (macOS alone has WebGPU)
        const query = ['probe', run.webgl || ciMode ? 'webgl' : null, ciMode ? 'ci' : null, run.query].filter(Boolean).join('&');
        const timeout = (run.timeout ?? defaultTimeout) * 1000;
        const started = Date.now();
        let result;
        try {
          await page.goto(`http://localhost:${port}/${experiment.page}.html?${query}`);
          result = await page.evaluate(
            (ms) => Promise.race([window.probe, new Promise((_, reject) => setTimeout(() => reject(new Error(`no result after ${ms / 1000} s`)), ms))]),
            timeout,
          );
          // The first canvas only, when the page has one
          const canvas = page.locator('canvas').first();
          const png = (await canvas.count()) ? await canvas.screenshot({ timeout }) : await page.screenshot({ timeout });
          shots[run.name] = png;
          if (!ciMode) {
            const webp = Buffer.from(await toWebP(browser, png), 'base64');
            writeFileSync(join(outDir, `${run.name}.webp`), webp);
          }
        } catch (error) {
          result = { error: String(error.message ?? error) };
        }
        await page.close();
        entry = { name: run.name, query, channel: process.env.LAB_CHANNEL ?? run.channel ?? 'chromium', headed: Boolean(run.headed), vsync: Boolean(run.vsync), wallSeconds: (Date.now() - started) / 1000, messages: [...new Set(messages)].slice(0, 40), result };
      }
      if (entry.result?.error) {
        console.log(`     error: ${entry.result.error.split('\n')[0]}`);
      }
      if (ciMode) {
        const name = `${experiment.id}__${run.name}`;
        const text = `${stable({ backend: entry.result?.backend ?? null, error: entry.result?.error ? 'see the log' : undefined, counters: entry.result?.counters, checks: entry.result?.checks })}\n`;
        if (entry.result?.error) console.log(entry.result.error);
        writeFileSync(join(outDir, `${run.name}.txt`), text);
        // The backend is printed, not compared: it follows the runner's GPU
        const compared = text.replace(/^ {2}"backend": .*\n/m, '');
        const expectedFile = join(lab, 'expected', `${name}.txt`);
        if (process.env.UPDATE === '1') {
          mkdirSync(dirname(expectedFile), { recursive: true });
          writeFileSync(expectedFile, compared);
          console.log(`upd  ${name}`);
        } else if (existsSync(expectedFile) && readFileSync(expectedFile, 'utf8').replace(/\r\n/g, '\n') === compared) {
          console.log(`ok   ${name} (${entry.result?.backend})`);
        } else {
          console.log(`FAIL ${name} (${entry.result?.backend})\n--- expected\n${existsSync(expectedFile) ? readFileSync(expectedFile, 'utf8') : '(missing)'}--- actual\n${compared}`);
          status = 1;
        }
      } else {
        record.runs = record.runs.filter((r) => r.name !== run.name);
        record.runs.push(entry);
        const r = entry.result ?? {};
        const f = (s) => (s ? `${s.median}` : '-');
        console.log(`     ${r.backend ?? ''} cpu ${f(r.stats?.cpuMs)} wall ${f(r.stats?.wallMs)} gpu ${f(r.stats?.gpuMs)} drawCalls ${r.counters?.drawCalls ?? '-'}`);
      }
    }
    // Pixel comparisons between runs of the same experiment, as the experiment lists them
    const comparisons = [];
    for (const [a, b] of experiment.compare ?? []) {
      if (!shots[a] || !shots[b]) continue;
      const pa = PNG.sync.read(shots[a]);
      const pb = PNG.sync.read(shots[b]);
      const differing = pixelmatch(pa.data, pb.data, null, pa.width, pa.height);
      comparisons.push({ a, b, differingPixels: differing, percent: Math.round((differing / (pa.width * pa.height)) * 10000) / 100 });
    }
    if (!ciMode) {
      if (comparisons.length) record.comparisons = comparisons;
      else if (previous?.comparisons) record.comparisons = previous.comparisons;
      record.runs.sort((x, y) => (experiment.runs ?? []).findIndex((r) => r.name === x.name) - (experiment.runs ?? []).findIndex((r) => r.name === y.name));
      writeFileSync(resultsFile, `${JSON.stringify(record, null, 2)}\n`);
      console.log(`wrote ${resultsFile}`);
    } else {
      for (const c of comparisons) console.log(`     ${c.a} against ${c.b}: ${c.differingPixels} pixels differ`);
    }
  }
} finally {
  for (const b of browsers.values()) await b.close();
  await server.close();
}
process.exit(status);
