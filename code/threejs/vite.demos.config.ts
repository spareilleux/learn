// The live demos published with the course site: the lesson pages, each with a "try it" panel, and the complete scenes
// in demos/. Built into the site's public folder, served under /learn/threejs-demos/:
//   npx vite build --config vite.demos.config.ts
// The lesson pages' own sources are not changed: the panel is a separate script, added to their HTML here only, so the
// builds that lessons 1, 4 and 13 quote (vite.config.ts) stay the same.
import { readdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { defineConfig, type Plugin } from 'vite';

const root = import.meta.dirname;
const lessonPages = readdirSync(root).filter((file) => /^\d\d-.*\.html$/.test(file));
const demoPages = readdirSync(resolve(root, 'demos')).filter((file) => file.endsWith('.html'));
const input = Object.fromEntries([
  ...lessonPages.map((file) => [file.replace('.html', ''), resolve(root, file)]),
  ...demoPages.map((file) => [`demos/${file.replace('.html', '')}`, resolve(root, 'demos', file)]),
]);

// Adds demos/try/try.ts to every lesson page
const tryItPanel: Plugin = {
  name: 'try-it-panel',
  transformIndexHtml: {
    order: 'pre',
    handler(html, context) {
      if (!/^\/\d\d-[^/]*\.html$/.test(context.path)) return html;
      return html.replace('</body>', '    <script type="module" src="/demos/try/try.ts"></script>\n  </body>');
    },
  },
};

export default defineConfig({
  base: '/learn/threejs-demos/',
  plugins: [tryItPanel],
  build: {
    target: 'es2022',
    outDir: resolve(root, '../../public/threejs-demos'),
    emptyOutDir: true,
    // No source maps and no size warnings: the published folder should stay small
    sourcemap: false,
    chunkSizeWarningLimit: 4000,
    rolldownOptions: {
      input,
      output: {
        codeSplitting: {
          groups: [{ name: (id: string) => /node_modules[\\/]three[\\/]build[\\/](three\.\w+)\.js$/.exec(id)?.[1] ?? null }],
        },
      },
    },
  },
});
