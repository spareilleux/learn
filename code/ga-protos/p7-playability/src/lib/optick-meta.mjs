// A metadata-only reader for GA's OPTK v4 voicing index. P1's src/lib/optick.mjs reads the whole file, vectors
// included; this prototype never looks at a vector, and copying 313,047 x 124 floats would cost 155 MB for
// nothing. The header layout is the same, documented in P1 and written by GA's OptickIndexWriter.

export const INSTRUMENTS = ['guitar', 'bass', 'ukulele'];

export function openIndexMetadata(buffer) {
  const view = new DataView(buffer.buffer, buffer.byteOffset, buffer.byteLength);
  const magic = String.fromCharCode(view.getUint8(0), view.getUint8(1), view.getUint8(2), view.getUint8(3));
  if (magic !== 'OPTK') throw new Error('OPTK magic bytes missing');
  const version = view.getUint32(4, true);
  if (version !== 4) throw new Error(`unsupported OPTK version ${version}`);
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
  const instruments = Object.fromEntries(
    ranges.map((r, i) => [INSTRUMENTS[i], { first: (r.byteOffset - vectorsOffset) / (dim * 4), count: r.count }]),
  );
  return {
    version,
    dim,
    count,
    instruments,
    metadata(i) {
      const off = Number(view.getBigUint64(metadataOffsetsOffset + i * 8, true));
      return readRecord({ bytes: buffer, pos: metadataOffset + off, end: metadataOffset + metadataLength });
    },
  };
}

function readRecord(r) {
  const t = r.bytes[r.pos++];
  if ((t & 0xf0) !== 0x80) throw new Error(`expected a msgpack fixmap, got 0x${t.toString(16)}`);
  const n = t & 0x0f;
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
