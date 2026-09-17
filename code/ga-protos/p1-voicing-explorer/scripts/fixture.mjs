// A tiny OPTK v4 index in GA's format, for tests and CI: real guitar diagrams and MIDI notes, chord names from a short
// list, and vectors built like GA's (each partition L2-normalized, then scaled by the square root of its weight).
// The writer mirrors FretboardVoicingsCLI's OptickIndexWriter (GuitarAlchemist/ga@66bdd049).
import { COMPACT_PARTITIONS, SCHEMA_HASH_V4 } from '../src/lib/optick.mjs';
import { mulberry32 } from '../src/lib/sample.mjs';
import { midiNotes, TUNINGS } from '../src/lib/voicing.mjs';

const NAMES = ['C', 'Am', 'G7', 'Fmaj7', 'Dm7', 'E5', 'Bm7b5', 'Asus4', 'Cadd9', 'Forte 5-7 (pentachord)'];

export function makeFixture({ guitar = 240, bass = 6, ukulele = 6, seed = 7 } = {}) {
  const random = mulberry32(seed);
  const entries = [];
  for (const [instrument, count] of [['guitar', guitar], ['bass', bass], ['ukulele', ukulele]]) {
    const tuning = TUNINGS[instrument];
    for (let i = 0; i < count; i++) {
      const start = Math.floor(random() * 12);
      const frets = tuning.map(() => (random() < 0.25 ? -1 : start + Math.floor(random() * 4)));
      if (frets.filter((f) => f >= 0).length < 2) frets[0] = frets[1] = start;
      entries.push({
        instrument,
        diagram: frets.map((f) => (f < 0 ? 'x' : String(f))).join('-'),
        midiNotes: midiNotes(frets, tuning),
        quality: NAMES[Math.floor(random() * NAMES.length)],
        vector: vectorFor(random),
      });
    }
  }
  return writeIndex(entries);
}

function vectorFor(random) {
  const v = new Float32Array(124);
  for (const p of COMPACT_PARTITIONS) {
    let norm = 0;
    for (let j = 0; j < p.dim; j++) {
      const x = random() < 0.5 ? 0 : random();
      v[p.start + j] = x;
      norm += x * x;
    }
    norm = Math.sqrt(norm);
    for (let j = 0; j < p.dim; j++) v[p.start + j] = norm > 0 ? (v[p.start + j] / norm) * Math.sqrt(p.weight) : 0;
  }
  return v;
}

// entries sorted guitar, bass, ukulele
export function writeIndex(entries) {
  const dim = 124;
  const records = entries.map(msgpackRecord);
  const metadataLength = records.reduce((s, r) => s + r.length, 0);
  const headerSize = 4 + 4 + 4 + 4 + 2 + 2 + 4 + 8 + 3 * 16 + 4 * 8 + dim * 4;
  const count = entries.length;
  const metadataOffsetsOffset = headerSize;
  const vectorsOffset = metadataOffsetsOffset + count * 8;
  const metadataOffset = vectorsOffset + count * dim * 4;
  const buffer = new ArrayBuffer(metadataOffset + metadataLength);
  const view = new DataView(buffer);
  const bytes = new Uint8Array(buffer);
  bytes.set(new TextEncoder().encode('OPTK'), 0);
  view.setUint32(4, 4, true);
  view.setUint32(8, headerSize, true);
  view.setUint32(12, SCHEMA_HASH_V4, true);
  view.setUint16(16, 0xfeff, true);
  view.setUint32(20, dim, true);
  view.setBigUint64(24, BigInt(count), true);
  let cursor = 40;
  let before = 0;
  for (const instrument of ['guitar', 'bass', 'ukulele']) {
    const n = entries.filter((e) => e.instrument === instrument).length;
    view.setBigUint64(cursor, BigInt(vectorsOffset + before * dim * 4), true);
    view.setBigUint64(cursor + 8, BigInt(n), true);
    before += n;
    cursor += 16;
  }
  view.setBigUint64(cursor, BigInt(metadataOffsetsOffset), true);
  view.setBigUint64(cursor + 8, BigInt(vectorsOffset), true);
  view.setBigUint64(cursor + 16, BigInt(metadataOffset), true);
  view.setBigUint64(cursor + 24, BigInt(metadataLength), true);
  for (const p of COMPACT_PARTITIONS)
    for (let j = 0; j < p.dim; j++) view.setFloat32(cursor + 32 + (p.start + j) * 4, Math.sqrt(p.weight), true);
  let recordOffset = 0;
  entries.forEach((e, i) => {
    view.setBigUint64(metadataOffsetsOffset + i * 8, BigInt(recordOffset), true);
    for (let j = 0; j < dim; j++) view.setFloat32(vectorsOffset + (i * dim + j) * 4, e.vector[j], true);
    bytes.set(records[i], metadataOffset + recordOffset);
    recordOffset += records[i].length;
  });
  return buffer;
}

function msgpackRecord(e) {
  const out = [0x84];
  const str = (s) => {
    const b = new TextEncoder().encode(s);
    if (b.length < 32) out.push(0xa0 | b.length);
    else out.push(0xd9, b.length);
    out.push(...b);
  };
  str('diagram');
  str(e.diagram);
  str('instrument');
  str(e.instrument);
  str('midiNotes');
  out.push(0x90 | e.midiNotes.length, ...e.midiNotes);
  str('quality_inferred');
  if (e.quality === null) out.push(0xc0);
  else str(e.quality);
  return Uint8Array.from(out);
}
