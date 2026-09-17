import { readdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { defineConfig } from 'vite';

// The Guitar Alchemist 3D lab: one HTML page per experiment at the root of ga-lab/ (01-neck.html, 02-…), served and built
// from here with the node_modules of code/threejs. The pages import lesson 13's files from ../src, hence fs.allow.
// PAGES=<regex> builds only the pages whose name matches.
const only = new RegExp(process.env.PAGES ?? '');
const pages = Object.fromEntries(
  readdirSync(import.meta.dirname)
    .filter((file) => /^\d\d-.*\.html$/.test(file) && only.test(file))
    .map((file) => [file.replace('.html', ''), resolve(import.meta.dirname, file)]),
);

export default defineConfig({
  root: import.meta.dirname,
  publicDir: resolve(import.meta.dirname, 'public'),
  build: {
    target: 'es2022',
    outDir: resolve(import.meta.dirname, 'dist'),
    emptyOutDir: true,
    reportCompressedSize: true,
    rolldownOptions: {
      input: pages,
      output: {
        codeSplitting: {
          groups: [{ name: (id: string) => /node_modules[\\/]three[\\/]build[\\/](three\.\w+)\.js$/.exec(id)?.[1] ?? null }],
        },
      },
    },
  },
  // Cross-origin isolation gives the pages performance.now() at 5 µs instead of 100 µs
  server: {
    port: 5288,
    strictPort: true,
    fs: { allow: [resolve(import.meta.dirname, '..')] },
    headers: { 'Cross-Origin-Opener-Policy': 'same-origin', 'Cross-Origin-Embedder-Policy': 'require-corp' },
  },
  preview: { port: 5289, strictPort: true },
});
