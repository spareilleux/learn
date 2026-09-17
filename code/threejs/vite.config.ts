import { readdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { defineConfig } from 'vite';

// One HTML page per lesson at the root of the project: 01-scene.html, 02-…
// PAGES=<regex> builds only the pages whose name matches, e.g. PAGES='^0[1-4]-' for the pages of lessons 1 to 4
const only = new RegExp(process.env.PAGES ?? '');
const pages = Object.fromEntries(
  readdirSync(import.meta.dirname)
    .filter((file) => /^\d\d-.*\.html$/.test(file) && only.test(file))
    .map((file) => [file.replace('.html', ''), resolve(import.meta.dirname, file)]),
);

export default defineConfig({
  // WebGPURenderer is initialized with a top-level await in each page
  build: {
    target: 'es2022',
    rolldownOptions: {
      input: pages,
      // Each of three.js's build files in its own chunk, named after it (three.core, three.module, three.webgpu),
      // instead of a chunk named after the first page module that imports it
      output: {
        codeSplitting: {
          groups: [{ name: (id: string) => /node_modules[\\/]three[\\/]build[\\/](three\.\w+)\.js$/.exec(id)?.[1] ?? null }],
        },
      },
    },
  },
  // The dev server scans the build inputs for dependencies to pre-bundle; the demos' pages too, or the first visit to one
  // finds a new dependency, and Vite reloads the page under the probe ("Execution context was destroyed")
  optimizeDeps: { entries: ['*.html', 'demos/*.html'] },
  server: { port: 5188, strictPort: true },
  preview: { port: 5189, strictPort: true },
});
