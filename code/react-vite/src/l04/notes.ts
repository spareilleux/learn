// Parsing and validating a tuning typed as text: a plain function, with a result that says what went wrong
const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const flats: Record<string, string> = { Db: 'C#', Eb: 'D#', Gb: 'F#', Ab: 'G#', Bb: 'A#' };

export type ParseResult = { ok: true; notes: string[] } | { ok: false; error: string };

export function parseNotes(text: string): ParseResult {
  const tokens = text.trim().split(/\s+/).filter((token) => token !== '');
  if (tokens.length !== 6) return { ok: false, error: `A guitar tuning has 6 notes, not ${tokens.length}.` };
  const notes: string[] = [];
  for (const token of tokens) {
    const name = token[0].toUpperCase() + token.slice(1);
    const note = flats[name] ?? name;
    if (!names.includes(note)) return { ok: false, error: `"${token}" is not a note.` };
    notes.push(note);
  }
  return { ok: true, notes };
}
