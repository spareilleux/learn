// examples/l02_readonly.ts
import { attempt, show } from './show.ts';

interface Tuning {
  readonly name: string;
  readonly notes: readonly string[];
}

// readonly is checked by tsc only: nothing is frozen at run time
const standard: Tuning = { name: 'standard', notes: ['E', 'A', 'D', 'G', 'B', 'E'] };

// A readonly type is assignable to a mutable one with the same properties: the alias can write
const writable: { name: string } = standard;
writable.name = 'drop D';
show('standard.name', standard.name);

// Object.freeze gives both: a Readonly<T> for tsc, and a frozen object for the engine
const frozen = Object.freeze({ name: 'open G', notes: ['D', 'G', 'D', 'G', 'B', 'D'] });
attempt("frozen.name = 'x', after a cast", () => {
  (frozen as { name: string }).name = 'x';
});
frozen.notes.push('shallow'); // freeze is shallow, and so is Readonly<T>
show('frozen.notes.length', frozen.notes.length);

// as const: the narrowest literal types, and readonly all the way down
const modes = ['ionian', 'dorian', 'phrygian'] as const;
type Mode = (typeof modes)[number];
const mode: Mode = 'dorian';
show('modes.includes(mode)', modes.includes(mode));
