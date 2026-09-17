// Writes the tiny test index to fixture/optick.index: node scripts/make-fixture.mjs
import { mkdirSync, writeFileSync } from 'node:fs';
import { makeFixture } from './fixture.mjs';

mkdirSync('fixture', { recursive: true });
const buffer = makeFixture();
writeFileSync('fixture/optick.index', new Uint8Array(buffer));
console.log(`fixture/optick.index: ${buffer.byteLength} bytes`);
