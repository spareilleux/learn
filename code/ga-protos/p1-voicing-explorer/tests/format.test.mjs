import assert from 'node:assert/strict';
import { test } from 'node:test';
import { decode, encode, SECTIONS } from '../src/lib/format.mjs';
import { makeFixture } from '../scripts/fixture.mjs';
import { openIndex, SCHEMA_HASH_V4 } from '../src/lib/optick.mjs';

test('the OPTIC-K v1.8 schema hash is the one GA writes', () => {
  // Read from the header of GA's optick.index built at GuitarAlchemist/ga@66bdd049
  assert.equal(SCHEMA_HASH_V4, 0x37cd8ecf);
});

test('the fixture index reads back through the OPTK reader', () => {
  const index = openIndex(makeFixture({ guitar: 5, bass: 2, ukulele: 1 }));
  assert.equal(index.count, 8);
  assert.equal(index.dim, 124);
  assert.ok(index.schemaMatches);
  assert.deepEqual(index.instruments, {
    guitar: { first: 0, count: 5 },
    bass: { first: 5, count: 2 },
    ukulele: { first: 7, count: 1 },
  });
  assert.equal(index.metadata(5).instrument, 'bass');
  let norm = 0;
  for (const x of index.vector(0)) norm += x * x;
  assert.ok(norm > 0.5 && norm <= 1.15 + 1e-5, `squared norm ${norm}`);
});

function sampleData(count, k) {
  const data = { count, k };
  for (const [name, type, per] of SECTIONS) {
    const length = count * (per === 'k' ? k : per);
    const T = name === 'neighbours' ? Uint16Array : type;
    data[name] = T.from({ length }, (_, i) => (T === Float32Array ? i * 0.25 - 3 : name === 'frets' ? (i % 8) - 1 : i % 200));
  }
  return data;
}

test('voicings.bin round-trips every section, value for value', () => {
  const data = sampleData(37, 4);
  const bytes = encode(data);
  const decoded = decode(bytes.buffer);
  assert.equal(decoded.count, 37);
  assert.equal(decoded.k, 4);
  for (const [name] of SECTIONS) assert.deepEqual(Array.from(decoded[name]), Array.from(data[name]), name);
  assert.equal(bytes.length % 4, 0);
});

test('two encodes of the same data give the same bytes', () => {
  assert.deepEqual(encode(sampleData(10, 3)), encode(sampleData(10, 3)));
});

test('decode rejects a file that is not a voicings file', () => {
  assert.throws(() => decode(new Uint8Array(64).buffer), /not a voicings file/);
});
