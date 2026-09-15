// bundle-size.mjs: bundles the same schema with each library, as a browser build would, and prints the sizes
// node bundle-size.mjs; esbuild is pinned in package.json, so the sizes only change with the versions
import { build } from 'esbuild';
import { gzipSync } from 'node:zlib';

const libraries = ['zod-named', 'zod', 'zod-mini', 'valibot', 'arktype'];
console.log('library     minified   gzip');
for (const library of libraries) {
  const result = await build({
    entryPoints: [`bundle/${library}.ts`],
    bundle: true,
    minify: true,
    format: 'esm',
    platform: 'browser',
    target: 'es2022',
    write: false,
  });
  const code = result.outputFiles[0].contents;
  const kb = (bytes) => `${(bytes / 1024).toFixed(1)} kB`.padStart(9);
  console.log(`${library.padEnd(10)} ${kb(code.length)} ${kb(gzipSync(code, { level: 9 }).length)}`);
}
