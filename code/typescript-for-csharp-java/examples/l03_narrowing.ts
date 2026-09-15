// examples/l03_narrowing.ts
import { show } from './show.ts';

// A union: a fret is a number, or 'open', or 'muted'
type Fret = number | 'open' | 'muted';

function describe(fret: Fret): string {
  if (typeof fret === 'number') {
    return `fret ${fret.toFixed(0)}`; // here fret is a number
  }
  return fret === 'open' ? 'open string' : 'not played'; // here fret is 'open' | 'muted'
}
show('describe(3)', describe(3));
show("describe('muted')", describe('muted'));

// Truthiness narrows too, and 0 is falsy: the open string played at fret 0 disappears
function label(fret: number | undefined): string {
  if (fret) return `fret ${fret}`;
  return 'no fret';
}
show('label(0)', label(0));
show('label(undefined)', label(undefined));

// in, instanceof and Array.isArray
interface Note {
  pitch: number;
}
interface Chord {
  pitches: number[];
}
function lowest(event: Note | Chord): number {
  return 'pitch' in event ? event.pitch : Math.min(...event.pitches);
}
show('lowest({ pitch: 40 })', lowest({ pitch: 40 }));
show('lowest({ pitches: [52, 45] })', lowest({ pitches: [52, 45] }));

function message(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (Array.isArray(error)) return `${error.length} errors`;
  return String(error);
}
show("message(new RangeError('fret 25'))", message(new RangeError('fret 25')));
show("message(['a', 'b'])", message(['a', 'b']));

// Control flow: after a return or a throw, the rest of the function knows more
function parseFret(text: string): Fret {
  if (text === 'o') return 'open';
  if (text === 'x') return 'muted';
  const fret = Number(text);
  if (!Number.isInteger(fret) || fret < 0) throw new RangeError(`not a fret: ${text}`);
  return fret;
}
show("'x32010'.split('').map(parseFret)", 'x32010'.split('').map(parseFret));
