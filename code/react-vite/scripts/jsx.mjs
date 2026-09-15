// Prints what Vite's transformer, Oxc, makes of a .tsx file for a production build: node scripts/jsx.mjs src/l02/TuningList.tsx
import { readFileSync } from 'node:fs';
import { transformWithOxc } from 'vite';

const file = process.argv[2];
const result = await transformWithOxc(readFileSync(file, 'utf8'), file, {
  jsx: { runtime: 'automatic', development: false },
  sourcemap: false,
});
process.stdout.write(result.code);
