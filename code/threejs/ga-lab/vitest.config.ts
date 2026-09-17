// The lab's unit tests are named *.lab.ts, so that the course's own "vitest run tests" (code/threejs/check.sh), which
// matches every *.test.ts under code/threejs, does not pick them up.
import { defineConfig } from 'vitest/config';

export default defineConfig({ test: { root: import.meta.dirname, include: ['tests/**/*.lab.ts'] } });
