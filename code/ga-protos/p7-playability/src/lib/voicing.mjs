// Voicings as GA's OPTK index stores them, and the fretboard geometry every cost in this prototype shares.
//
// String order: GA's index writes string 1 first, so index 0 of a fret array is the high E string and index 5
// the low E. P1 established that on row 1000 of the index ("1-2-x-5-x-1", MIDI 65, 61, 55, 41). A chord chart
// spells the same shape the other way round.
//
// Geometry: the same equal-temperament formula GA uses in PhysicalFretboardCalculator, with the same default
// scale length (Electric = 648 mm) and the same nut and bridge widths (43 mm and 52 mm).

export const SCALE_LENGTH_MM = 648.0;
export const NUT_WIDTH_MM = 43.0;
export const BRIDGE_WIDTH_MM = 52.0;

export const GUITAR_TUNING = [64, 59, 55, 50, 45, 40]; // string 1 first, as in the index

// "x-3-2-0-1-0" -> [-1, 3, 2, 0, 1, 0]; -1 is a muted string
export function parseDiagram(diagram) {
  return diagram.split('-').map((t) => (t === 'x' || t === 'X' ? -1 : Number.parseInt(t, 10)));
}

// [-1, 3, 2, 0, 1, 0] -> "x-3-2-0-1-0"
export function formatDiagram(frets) {
  return frets.map((f) => (f < 0 ? 'x' : String(f))).join('-');
}

// The other way round: a chord chart written low E first, dash separated ("x-3-2-0-1-0"), back into index order
export function parseChart(chart) {
  return parseDiagram(chart).reverse();
}

// The compact chord-chart spelling guitarists read, low E first: "x32010"
export function chartName(frets) {
  const tokens = [...frets].reverse().map((f) => (f < 0 ? 'x' : String(f)));
  return tokens.some((t) => t.length > 1) ? tokens.join('-') : tokens.join('');
}

export function midiNotes(frets, tuning = GUITAR_TUNING) {
  const notes = [];
  frets.forEach((f, s) => {
    if (f >= 0) notes.push(tuning[s] + f);
  });
  return notes;
}

// Distance from the nut to a fret, in millimetres: scale * (1 - 2^(-fret/12)) — GA's CalculateFretPositionMm
export function fretPositionMm(fret, scaleLengthMm = SCALE_LENGTH_MM) {
  return fret === 0 ? 0 : scaleLengthMm * (1 - Math.pow(2, -fret / 12));
}

export function fretDistanceMm(a, b, scaleLengthMm = SCALE_LENGTH_MM) {
  return Math.abs(fretPositionMm(b, scaleLengthMm) - fretPositionMm(a, scaleLengthMm));
}

// Where a finger actually presses: halfway between the fret wire behind the note and the one it stops against
export function pressPositionMm(fret, scaleLengthMm = SCALE_LENGTH_MM) {
  return (fretPositionMm(fret - 1, scaleLengthMm) + fretPositionMm(fret, scaleLengthMm)) / 2;
}

// Spacing between two adjacent strings at a fret — GA's CalculateStringSpacingMm
export function stringSpacingMm(fret, scaleLengthMm = SCALE_LENGTH_MM) {
  const ratio = fretPositionMm(fret, scaleLengthMm) / scaleLengthMm;
  return (NUT_WIDTH_MM + (BRIDGE_WIDTH_MM - NUT_WIDTH_MM) * ratio) / 5;
}

// The point a finger occupies, in millimetres: x along the neck from the nut, y across the strings
export function notePointMm(stringIndex, fret, scaleLengthMm = SCALE_LENGTH_MM) {
  return { x: pressPositionMm(fret, scaleLengthMm), y: stringIndex * stringSpacingMm(fret, scaleLengthMm) };
}

export function distanceMm(p, q) {
  return Math.hypot(p.x - q.x, p.y - q.y);
}

// The parts of a voicing every cost function reads
export function layout(frets) {
  const fretted = [];
  const open = [];
  const muted = [];
  const played = [];
  frets.forEach((f, s) => {
    if (f < 0) muted.push(s);
    else {
      played.push(s);
      if (f === 0) open.push(s);
      else fretted.push({ string: s, fret: f });
    }
  });
  const fretValues = fretted.map((n) => n.fret);
  const minFret = fretValues.length ? Math.min(...fretValues) : 0;
  const maxFret = fretValues.length ? Math.max(...fretValues) : 0;
  // A muted string with played strings on both sides: the fretting hand has to damp it
  let innerMuted = 0;
  if (played.length > 1) {
    const lo = Math.min(...played);
    const hi = Math.max(...played);
    for (const s of muted) if (s > lo && s < hi) innerMuted++;
  }
  return {
    frets,
    fretted,
    open,
    muted,
    played,
    minFret,
    maxFret,
    span: maxFret - minFret,
    spanMm: fretDistanceMm(minFret, maxFret),
    distinctFrets: new Set(fretValues).size,
    innerMuted,
  };
}

// The shape a voicing keeps when it is moved along the neck: frets relative to the lowest fretted one.
// Two voicings with the same key are the same grip in two positions — the split by chord does not separate them.
export function shapeKey(frets) {
  const l = layout(frets);
  if (!l.fretted.length) return frets.map((f) => (f < 0 ? 'x' : 'o')).join('');
  return frets.map((f) => (f < 0 ? 'x' : f === 0 ? 'o' : String(f - l.minFret))).join('.');
}

// The pitch-class set of a voicing, as a sorted string: the chord identity used to group the split
export function pitchClassKey(notes) {
  return [...new Set(notes.map((n) => ((n % 12) + 12) % 12))].sort((a, b) => a - b).join(',');
}
