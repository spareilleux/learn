// Reads Guitar Alchemist's OPTK v4 voicing index (the format written by FretboardVoicingsCLI's OptickIndexWriter
// and read by GA.Business.ML's OptickIndexReader), from an ArrayBuffer, in Node.js or the browser.
//
// Header, little-endian:
//   magic "OPTK"(4) version(4) header_size(4) schema_hash(4) endian 0xFEFF(2) reserved(2)
//   dim(4) count(8) instrument byte ranges 3 x (offset(8), count(8))
//   metadata_offsets_offset(8) vectors_offset(8) metadata_offset(8) metadata_length(8) weights(dim x 4)
// Then: count x u64 metadata offsets, count x dim x float32 vectors, count x msgpack records
// { diagram, instrument, midiNotes, quality_inferred }.

export const INSTRUMENTS = ['guitar', 'bass', 'ukulele'];

// The similarity partitions of OPTIC-K v1.8 in the compact vector, in order (EmbeddingSchema.CompactLayoutV4)
export const COMPACT_PARTITIONS = [
  { name: 'STRUCTURE', start: 0, dim: 24, weight: 0.45 },
  { name: 'MORPHOLOGY', start: 24, dim: 24, weight: 0.25 },
  { name: 'CONTEXT', start: 48, dim: 12, weight: 0.2 },
  { name: 'SYMBOLIC', start: 60, dim: 12, weight: 0.1 },
  { name: 'MODAL', start: 72, dim: 40, weight: 0.1 },
  { name: 'ROOT', start: 112, dim: 12, weight: 0.05 },
];

export function compactLayout() {
  return 'optk-v4-pp-r:' + COMPACT_PARTITIONS.map((p) => `${p.name}:${p.start}-${p.start + p.dim - 1}`).join(',');
}

const CRC_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c >>> 0;
  }
  return table;
})();

// CRC-32 (IEEE), the same as System.IO.Hashing.Crc32
export function crc32(bytes) {
  let crc = 0xffffffff;
  for (const b of bytes) crc = CRC_TABLE[(crc ^ b) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

export const SCHEMA_HASH_V4 = crc32(new TextEncoder().encode(compactLayout()));

export function openIndex(arrayBuffer, byteOffset = 0) {
  const view = new DataView(arrayBuffer, byteOffset);
  const magic = String.fromCharCode(view.getUint8(0), view.getUint8(1), view.getUint8(2), view.getUint8(3));
  if (magic !== 'OPTK') throw new Error('OPTK magic bytes missing');
  const version = view.getUint32(4, true);
  if (version !== 4) throw new Error(`unsupported OPTK version ${version}`);
  const headerSize = view.getUint32(8, true);
  const schemaHash = view.getUint32(12, true);
  if (view.getUint16(16, true) !== 0xfeff) throw new Error('OPTK endian marker mismatch');
  const dim = view.getUint32(20, true);
  const count = Number(view.getBigUint64(24, true));
  const ranges = [];
  let cursor = 40;
  for (let i = 0; i < 3; i++) {
    ranges.push({ byteOffset: Number(view.getBigUint64(cursor, true)), count: Number(view.getBigUint64(cursor + 8, true)) });
    cursor += 16;
  }
  const metadataOffsetsOffset = Number(view.getBigUint64(cursor, true));
  const vectorsOffset = Number(view.getBigUint64(cursor + 8, true));
  const metadataOffset = Number(view.getBigUint64(cursor + 16, true));
  const metadataLength = Number(view.getBigUint64(cursor + 24, true));
  const weights = new Float32Array(dim);
  for (let i = 0; i < dim; i++) weights[i] = view.getFloat32(cursor + 32 + i * 4, true);

  const instruments = Object.fromEntries(
    ranges.map((r, i) => [INSTRUMENTS[i], { first: (r.byteOffset - vectorsOffset) / (dim * 4), count: r.count }]),
  );
  // The vectors are copied once, so that the Float32Array is aligned whatever the file's layout
  const vectors = new Float32Array(count * dim);
  for (let i = 0; i < count * dim; i++) vectors[i] = view.getFloat32(vectorsOffset + i * 4, true);
  const bytes = new Uint8Array(arrayBuffer, byteOffset);

  return {
    version,
    headerSize,
    schemaHash,
    schemaMatches: schemaHash === SCHEMA_HASH_V4,
    dim,
    count,
    instruments,
    weights,
    vectors,
    vector: (i) => vectors.subarray(i * dim, (i + 1) * dim),
    metadata(i) {
      const off = Number(view.getBigUint64(metadataOffsetsOffset + i * 8, true));
      const reader = { bytes, pos: metadataOffset + off, end: metadataOffset + metadataLength };
      return readRecord(reader);
    },
  };
}

// The subset of MessagePack the writer produces: fixmap, strings, small ints, int arrays, nil
function readRecord(r) {
  const t = r.bytes[r.pos++];
  let n;
  if ((t & 0xf0) === 0x80) n = t & 0x0f;
  else throw new Error(`expected a msgpack fixmap, got 0x${t.toString(16)}`);
  const record = { diagram: '', instrument: '', midiNotes: [], quality: null };
  for (let i = 0; i < n; i++) {
    const key = readValue(r);
    const value = readValue(r);
    if (key === 'diagram') record.diagram = value;
    else if (key === 'instrument') record.instrument = value;
    else if (key === 'midiNotes') record.midiNotes = value;
    else if (key === 'quality_inferred') record.quality = value;
    if (r.pos > r.end) throw new Error('OPTK metadata overrun');
  }
  return record;
}

const decoder = new TextDecoder();

function readValue(r) {
  const b = r.bytes;
  const t = b[r.pos++];
  const be16 = () => ((b[r.pos++] << 8) | b[r.pos++]) >>> 0;
  const be32 = () => ((b[r.pos++] << 24) | (b[r.pos++] << 16) | (b[r.pos++] << 8) | b[r.pos++]) >>> 0;
  const str = (len) => {
    const s = decoder.decode(b.subarray(r.pos, r.pos + len));
    r.pos += len;
    return s;
  };
  const arr = (len) => Array.from({ length: len }, () => readValue(r));
  if (t === 0xc0) return null;
  if ((t & 0x80) === 0) return t;
  if ((t & 0xe0) === 0xe0) return t - 256;
  if ((t & 0xe0) === 0xa0) return str(t & 0x1f);
  if ((t & 0xf0) === 0x90) return arr(t & 0x0f);
  switch (t) {
    case 0xd9: return str(b[r.pos++]);
    case 0xda: return str(be16());
    case 0xdb: return str(be32());
    case 0xdc: return arr(be16());
    case 0xdd: return arr(be32());
    case 0xcc: return b[r.pos++];
    case 0xcd: return be16();
    case 0xce: return be32();
    case 0xd0: return (b[r.pos++] << 24) >> 24;
    case 0xd1: return (be16() << 16) >> 16;
    case 0xd2: return be32() | 0;
    default: throw new Error(`unsupported msgpack type 0x${t.toString(16)}`);
  }
}
