// Builds the explorer into the site's public folder, where Astro copies it as is:
//   node scripts/publish.mjs            -> <repo>/public/ga-lab/p1/  (served at /learn/ga-lab/p1/)
//   node scripts/publish.mjs --out dir  -> any other folder (CI builds into dist/)
// public/data/ must hold the sample built by scripts/build-data.mjs; only voicings.bin and manifest.json are published.
import { copyFileSync, existsSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { build } from 'vite';

const args = process.argv.slice(2);
const out = resolve(args.includes('--out') ? args[args.indexOf('--out') + 1] : '../../../public/ga-lab/p1');
if (!existsSync('public/data/voicings.bin')) {
  console.error('public/data/voicings.bin is missing: run scripts/build-data.mjs first');
  process.exit(1);
}
// publicDir: false, so that nothing else under public/ (such as the local full-index data) is ever copied
await build({ configFile: 'vite.config.mjs', logLevel: 'warn', publicDir: false, build: { outDir: out, emptyOutDir: true } });
mkdirSync(join(out, 'data'), { recursive: true });
for (const f of ['voicings.bin', 'manifest.json']) copyFileSync(join('public/data', f), join(out, 'data', f));

let total = 0;
const walk = (dir) => {
  for (const f of readdirSync(dir)) {
    const p = join(dir, f);
    const s = statSync(p);
    if (s.isDirectory()) walk(p);
    else {
      total += s.size;
      console.log(`${String(s.size).padStart(9)}  ${p.slice(out.length + 1).replaceAll('\\', '/')}`);
    }
  }
};
walk(out);
console.log(`${String(total).padStart(9)}  total in ${out}`);
