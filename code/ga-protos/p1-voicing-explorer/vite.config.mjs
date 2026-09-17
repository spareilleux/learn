import { defineConfig } from 'vite';

// base './' keeps every URL relative, so the build works under any path: /learn/ga-lab/p1/ on the site, or a local folder
export default defineConfig({
  base: './',
  build: {
    target: 'es2022',
    // three.webgpu.js is one large module; the warning says nothing useful here
    chunkSizeWarningLimit: 2000,
  },
  server: { port: 5198, strictPort: true },
  preview: { port: 5199, strictPort: true },
});
