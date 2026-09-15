// Runs `vite` as npm run dev does, prints what it logs until the server is ready, then stops it: node scripts/dev-start.mjs
// In a terminal, Vite also prints "press h + enter to show help"; it doesn't when its output is piped, as here.
import { spawn } from 'node:child_process';

const vite = spawn(process.execPath, ['node_modules/vite/bin/vite.js', '--port', '5199', '--strictPort'], {
  stdio: ['ignore', 'pipe', 'inherit'],
});
const timeout = setTimeout(() => vite.kill(), 30_000);
let output = '';
vite.stdout.on('data', (chunk) => {
  output += chunk;
  if (output.includes('to expose')) vite.kill();
});
vite.on('exit', () => {
  clearTimeout(timeout);
  process.stdout.write(output);
});
