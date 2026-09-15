// examples/l03_brands.ts
import type { Equal, Expect } from './type-tests.ts';
import { attempt, show } from './show.ts';
import { fret, stringIndex, stringNumber, toStringIndex, toStringNumber, type Fret, type StringIndex, type StringNumber } from './l03_positions.ts';

// GA's VexTabViewer.tsx: getPitchFromTabPosition(string: number, fret: number), with 1 = high E
const openStrings = ['E/5', 'B/4', 'G/4', 'D/4', 'A/3', 'E/3'];
function openStringOf(string: StringNumber): string {
  return openStrings[string - 1] ?? 'E/3';
}
// GA's InstrumentConfig.ts: FretboardPosition { string: number; fret: number }, with 0 = highest string
interface FretboardPosition {
  string: StringIndex;
  fret: Fret;
}

const clicked: FretboardPosition = { string: stringIndex(1), fret: fret(3) }; // the B string, third fret
show('openStringOf(toStringNumber(…))', openStringOf(toStringNumber(clicked.string)));

// A brand is a type, and nothing else: at run time the value is a plain number
show('typeof clicked.string', typeof clicked.string);
show('JSON.stringify(clicked)', JSON.stringify(clicked));

// Arithmetic gives back a number: the brand says what the value is, and a new value has to be checked again
const next = clicked.fret + 1;
type _1 = Expect<Equal<typeof next, number>>;
show('fret(next)', fret(next));
attempt('fret(25)', () => fret(25));
attempt('stringNumber(0)', () => stringNumber(0));

// A branded value is still a number wherever a number is expected
show('Math.max(clicked.fret, 5)', Math.max(clicked.fret, 5));
show('toStringIndex(stringNumber(6))', toStringIndex(stringNumber(6)));

// Classes with a #private field are compared nominally: two identical shapes are not interchangeable
class Semitones {
  #value: number;
  constructor(value: number) {
    this.#value = value;
  }
  get value(): number {
    return this.#value;
  }
}
class Cents {
  #value: number;
  constructor(value: number) {
    this.#value = value;
  }
  get value(): number {
    return this.#value;
  }
}
// @ts-expect-error: a Cents is not a Semitones, although both have a value getter
const wrong: Semitones = new Cents(700);
show('new Semitones(7).value', new Semitones(7).value);
show('wrong instanceof Semitones', wrong instanceof Semitones);
