// Experiment 14's bundle sizes: builds each implementation's module (src/14-r3f-vs-vanilla/r3f.tsx and vanilla.ts) alone
// with Vite, as an entry of its own, then sums the bytes and gzip bytes of the JavaScript files it produces, with and
// without three.js's own chunks.
//   node scripts/bundle-sizes.mjs
import { mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { gzipSync } from 'node:zlib';
import { build } from 'vite';

const lab = resolve(import.meta.dirname, '..');
const variants = { r3f: '14-r3f-vs-vanilla/r3f.tsx', vanilla: '14-r3f-vs-vanilla/vanilla.ts' };
const result = {};
for (const [name, entry] of Object.entries(variants)) {
  const outDir = join(lab, 'out', `bundle-${name}`);
  rmSync(outDir, { recursive: true, force: true });
  mkdirSync(outDir, { recursive: true });
  await build({
    configFile: false,
    root: lab,
    logLevel: 'silent',
    build: {
      target: 'es2022',
      outDir,
      emptyOutDir: true,
      rolldownOptions: {
        input: join(lab, 'src', entry),
        // The modules export start() and call nothing: without this, the build keeps no code at all
        preserveEntrySignatures: 'exports-only',
        output: { codeSplitting: { groups: [{ name: (id) => /node_modules[\\/]three[\\/]build[\\/](three\.\w+)\.js$/.exec(id)?.[1] ?? null }] } },
      },
    },
  });
  const files = readdirSync(join(outDir, 'assets')).filter((f) => f.endsWith('.js'));
  const sizes = files.map((f) => {
    const bytes = readFileSync(join(outDir, 'assets', f));
    return { file: f.replace(/-[\w-]{8}\.js$/, '.js'), bytes: bytes.length, gzip: gzipSync(bytes).length };
  });
  const sum = (list, key) => list.reduce((s, x) => s + x[key], 0);
  const withoutThree = sizes.filter((s) => !/^three\./.test(s.file));
  result[name] = {
    files: sizes,
    totalKB: Math.round(sum(sizes, 'bytes') / 1024),
    totalGzipKB: Math.round(sum(sizes, 'gzip') / 1024),
    withoutThreeGzipKB: Math.round(sum(withoutThree, 'gzip') / 1024),
  };
}
writeFileSync(join(lab, 'out', 'bundle-sizes.json'), `${JSON.stringify(result, null, 2)}\n`);
console.log(JSON.stringify(result, null, 2));
