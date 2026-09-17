// The explorer's data file, voicings.bin: a small header, then typed arrays the page views without copying.
//
//   magic "GAV1"(4) version u32 count u32 k u32 neighbourIdBytes u32 (2 or 4) sectionCount u32
//   then, for each section in SECTIONS order, 4-byte aligned: the array's bytes
//
// Everything is little-endian, which is what typed arrays use on every platform the page runs on.
// The chord names, families and provenance live in manifest.json next to it.

export const MAGIC = 'GAV1';
export const VERSION = 1;

// name, typed array, values per voicing (k means "neighbour count")
export const SECTIONS = [
  ['positions', Float32Array, 3], // PCA coordinates x, y, z
  ['frets', Int8Array, 6], // GA order: string 1 (high E) first; -1 = muted
  ['nameId', Uint16Array, 1], // index into manifest.names
  ['family', Uint8Array, 1], // index into manifest.families
  ['span', Uint8Array, 1], // fret span of the fretted notes
  ['lowFret', Uint8Array, 1], // lowest fretted fret, 0 when all strings are open or muted
  ['tension', Uint8Array, 1], // semitones + whole tones + tritones in the pitch-class set
  ['noteCount', Uint8Array, 1],
  ['indexRow', Uint32Array, 1], // row of the voicing in GA's optick.index
  ['neighbours', null, 'k'], // Uint16Array or Uint32Array, k rows of this file per voicing, nearest first
  ['neighbourScores', Float32Array, 'k'], // their dot products in GA's 124-dimensional space
];

const HEADER_BYTES = 24;
const align4 = (x) => (x + 3) & ~3;

function sectionType(name, type, neighbourIdBytes) {
  if (name === 'neighbours') return neighbourIdBytes === 2 ? Uint16Array : Uint32Array;
  return type;
}

export function encode(data) {
  const { count, k } = data;
  const neighbourIdBytes = count <= 65536 ? 2 : 4;
  let size = HEADER_BYTES;
  const layout = SECTIONS.map(([name, type, per]) => {
    const T = sectionType(name, type, neighbourIdBytes);
    const length = count * (per === 'k' ? k : per);
    const src = data[name];
    if (!src || src.length !== length) throw new Error(`section ${name}: expected ${length} values, got ${src?.length}`);
    size = align4(size);
    const entry = { name, T, offset: size, length };
    size += length * T.BYTES_PER_ELEMENT;
    return entry;
  });
  size = align4(size);
  const buffer = new ArrayBuffer(size);
  const view = new DataView(buffer);
  for (let i = 0; i < 4; i++) view.setUint8(i, MAGIC.charCodeAt(i));
  view.setUint32(4, VERSION, true);
  view.setUint32(8, count, true);
  view.setUint32(12, k, true);
  view.setUint32(16, neighbourIdBytes, true);
  view.setUint32(20, SECTIONS.length, true);
  for (const { name, T, offset, length } of layout) new T(buffer, offset, length).set(data[name]);
  return new Uint8Array(buffer);
}

export function decode(buffer, byteOffset = 0) {
  const view = new DataView(buffer, byteOffset);
  const magic = String.fromCharCode(...[0, 1, 2, 3].map((i) => view.getUint8(i)));
  if (magic !== MAGIC) throw new Error(`not a voicings file (magic ${JSON.stringify(magic)})`);
  const version = view.getUint32(4, true);
  if (version !== VERSION) throw new Error(`voicings file version ${version}, expected ${VERSION}`);
  const count = view.getUint32(8, true);
  const k = view.getUint32(12, true);
  const neighbourIdBytes = view.getUint32(16, true);
  if (view.getUint32(20, true) !== SECTIONS.length) throw new Error('unexpected section count');
  const out = { count, k };
  let offset = HEADER_BYTES;
  for (const [name, type, per] of SECTIONS) {
    const T = sectionType(name, type, neighbourIdBytes);
    const length = count * (per === 'k' ? k : per);
    offset = align4(offset);
    out[name] = new T(buffer, byteOffset + offset, length);
    offset += length * T.BYTES_PER_ELEMENT;
  }
  return out;
}
