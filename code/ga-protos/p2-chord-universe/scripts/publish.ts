// Builds the app into the site's public folder, where Astro copies it as is:
//   node scripts/publish.ts            -> <repo>/public/ga-lab/p2/  (served at /learn/ga-lab/p2/)
//   node scripts/publish.ts --out dir  -> any other folder
// Copies out/browser-run.png, the headless run's screenshot, as screenshot.png for the lesson's preview.
// Prints every file and the total, since the whole lab must stay under 20 MB.
import { copyFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { join, resolve, sep } from 'node:path';
import { build } from 'vite';

const args = process.argv.slice(2);
const out = resolve(args.includes('--out') ? args[args.indexOf('--out') + 1] : '../../../public/ga-lab/p2');
await build({ configFile: 'vite.config.ts', logLevel: 'warn', build: { outDir: out, emptyOutDir: true } });
if (existsSync('out/browser-run.png')) copyFileSync('out/browser-run.png', join(out, 'screenshot.png'));
let total = 0;
const walk = (dir: string) => {
  for (const f of readdirSync(dir)) {
    const p = join(dir, f);
    const s = statSync(p);
    if (s.isDirectory()) walk(p);
    else {
      total += s.size;
      console.log(`${String(s.size).padStart(9)}  ${p.slice(out.length + 1).replaceAll(sep, '/')}`);
    }
  }
};
walk(out);
console.log(`${String(total).padStart(9)}  total in ${out}`);
