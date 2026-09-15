// examples/l01_template.ts
import type { Equal, Expect } from './type-tests.ts';
import { attempt, show } from './show.ts';

// A template literal type combines every member of each union: 7 letters × 3 accidentals × 8 qualities
type Letter = 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G';
type Accidental = '' | '#' | 'b';
type Quality = '' | 'm' | '7' | 'maj7' | 'm7' | 'dim' | 'aug' | 'sus4';
type ChordSymbol = `${Letter}${Accidental}${Quality}`;
type _1 = Expect<Equal<Extract<ChordSymbol, `C${string}`>, 'C' | 'Cm' | 'C7' | 'Cmaj7' | 'Cm7' | 'Cdim' | 'Caug' | 'Csus4' | `C#${Quality}` | `Cb${Quality}`>>;

// infer inside a template literal type parses a string: an infer followed by another infer takes one character
type ParseChord<S extends string> = S extends `${infer L extends Letter}${infer Rest}`
  ? Rest extends `${infer A extends '#' | 'b'}${infer Q extends Quality}`
    ? { root: `${L}${A}`; quality: Q }
    : Rest extends Quality
      ? { root: L; quality: Rest }
      : never
  : never;
type _2 = Expect<Equal<ParseChord<'F#m7'>, { root: 'F#'; quality: 'm7' }>>;
type _3 = Expect<Equal<ParseChord<'Bbmaj7'>, { root: 'Bb'; quality: 'maj7' }>>;
type _4 = Expect<Equal<ParseChord<'E'>, { root: 'E'; quality: '' }>>;

// The run-time parser is ordinary code; its signature gives each literal argument its parsed type
const chordPattern = /^([A-G][#b]?)(maj7|m7|m|7|dim|aug|sus4)?$/;
function parseChord<S extends ChordSymbol>(symbol: S): ParseChord<S> {
  const match = chordPattern.exec(symbol);
  if (!match) throw new TypeError(`not a chord symbol: ${symbol}`);
  return { root: match[1], quality: match[2] ?? '' } as ParseChord<S>; // the regex and the type say the same thing twice
}
const fSharpMinor7 = parseChord('F#m7');
type _5 = Expect<Equal<typeof fSharpMinor7, { root: 'F#'; quality: 'm7' }>>;
show("parseChord('F#m7')", fSharpMinor7);
show("parseChord('Bbmaj7').root", parseChord('Bbmaj7').root);

// A symbol known only at run time is a string: it has to be checked before the call
const isChordSymbol = (text: string): text is ChordSymbol => chordPattern.test(text);
for (const text of ['Gsus4', 'H7']) {
  attempt(`parse '${text}'`, () => (isChordSymbol(text) ? parseChord(text) : `rejected: ${text}`));
}

// Capitalize and the other intrinsic string types exist only for tsc: the run-time function is written separately
type HandlerName<E extends string> = `on${Capitalize<E>}`;
type _6 = Expect<Equal<HandlerName<'graphUpdate' | 'cameraSync'>, 'onGraphUpdate' | 'onCameraSync'>>;
const handlerName = <E extends string>(event: E) => `on${event.charAt(0).toUpperCase()}${event.slice(1)}` as HandlerName<E>;
show("handlerName('cameraSync')", handlerName('cameraSync'));
