import { defineConfig, type Plugin } from 'vite';

// The built page declares, in a Content Security Policy, that it may not open any connection: connect-src 'none'
// blocks fetch, XMLHttpRequest, WebSocket, EventSource and sendBeacon, so even a bug or a dependency could not upload
// the microphone's audio. Only the build gets it: the dev server needs a WebSocket for hot reload.
const noConnections: Plugin = {
  name: 'p2-no-connections',
  apply: 'build',
  transformIndexHtml: (html) =>
    html.replace(
      '<meta charset="UTF-8" />',
      `<meta charset="UTF-8" />\n    <meta http-equiv="Content-Security-Policy" content="default-src 'self'; connect-src 'none'; img-src 'self' data: blob:; object-src 'none'; base-uri 'none'; form-action 'none'" />`,
    ),
};

// Relative asset URLs, so the same build works at /, under the site's /learn/ga-lab/p2/ and from a file server.
// The fretboard's measurements come from the three.js course (../../threejs/src/13-fretboard/guitar.ts), outside
// this folder: the dev server has to be allowed to read it.
export default defineConfig({
  base: './',
  plugins: [noConnections],
  build: { target: 'es2022', outDir: 'dist', chunkSizeWarningLimit: 2000 },
  server: { port: 5192, strictPort: true, fs: { allow: ['.', '../../threejs/src/13-fretboard'] } },
  preview: { port: 5193, strictPort: true },
});
