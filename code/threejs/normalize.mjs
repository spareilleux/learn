// Makes the outputs of tsc, Vite and the probes comparable between machines: node normalize.mjs < raw.txt > out.txt
// - the ANSI colors are removed
// - absolute paths under this folder become paths relative to it, with forward slashes
// - durations ("ready in 151 ms", "built in 207ms") become N, the dev server's cache hashes (?v=2ab89a96) HASH,
//   an HMR timestamp TIMESTAMP, timings printed as "6.94 µs per ray" or "initialized in 51.0 ms" N, and inline source
//   maps are shortened, and Vitest's start time and durations become TIME and N
// - stack frames ("    at …") are dropped, and the process ID of a warning becomes PID
import { readFileSync } from 'node:fs';

const course = 'threejs';
const text = readFileSync(0, 'utf8').replaceAll('\r\n', '\n');
const pathPattern = new RegExp(String.raw`(?:file://)?(?:\\\\\?\\)?[^\s'"(]*?[\\/]code[\\/]${course}(?:[\\/]([^\s'"(:]*))?`, 'g');

const lines = text
  .replace(/\x1b\[[0-9;]*m/g, '')
  .split('\n')
  .filter((line) => !/^\s+at /.test(line))
  .map((line) => line.replace(pathPattern, (_, rest) => (rest ?? '.').replaceAll('\\', '/')))
  .map((line) => line.replace(/^\(node:\d+\)/, '(node:PID)'))
  .map((line) => line.replace(/ready in \d+ ms/, 'ready in N ms').replace(/built in \d+(?:\.\d+)?m?s/, 'built in N ms'))
  .map((line) => line.replaceAll(/\?v=[0-9a-f]{8}/g, '?v=HASH'))
  .map((line) => line.replace(/\d+(?:\.\d+)? (µs|ms) per /, 'N $1 per ').replace(/initialized in \d+(?:\.\d+)? ms/, 'initialized in N ms'))
  .map((line) => line.replace(/"timestamp": \d+/, '"timestamp": TIMESTAMP'))
  // Vitest: each test's duration, and the summary's start time and durations
  .map((line) => line.replace(/^( ✓ .*) \d+ms$/, '$1'))
  .map((line) => line.replace(/Start at {2}\d\d:\d\d:\d\d/, 'Start at  TIME').replace(/Duration {2}\d+(?:\.\d+)?m?s \(.*\)/, 'Duration  N'))
  .map((line) => line.replace(/(sourceMappingURL=data:application\/json;base64,).*/, '$1…'));

process.stdout.write(lines.join('\n'));
