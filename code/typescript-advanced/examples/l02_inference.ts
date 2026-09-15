// examples/l02_inference.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// Without const, an array argument is inferred as string[]: the notes are forgotten
function tuning<T extends readonly string[]>(notes: T): T {
  return notes;
}
const plain = tuning(['D', 'A', 'D', 'G', 'A', 'D']);
type _1 = Expect<Equal<typeof plain, string[]>>;

// A const type parameter (5.0) infers as if the caller had written as const
function constTuning<const T extends readonly string[]>(notes: T): T {
  return notes;
}
const dadgad = constTuning(['D', 'A', 'D', 'G', 'A', 'D']);
type _2 = Expect<Equal<typeof dadgad, readonly ['D', 'A', 'D', 'G', 'A', 'D']>>;
// With a mutable constraint, the tuple is inferred mutable (since 5.3; from 5.0 to 5.2 it fell back to string[])
function constMutable<const T extends string[]>(notes: T): T {
  return notes;
}
const fallback = constMutable(['D', 'A', 'D']);
type _3 = Expect<Equal<typeof fallback, ['D', 'A', 'D']>>;

// Every argument is an inference site: here initial adds its value to the union inferred from states
function machine<S extends string>(states: readonly S[], initial: S) {
  return { states, current: initial };
}
const loose = machine(['idle', 'listening', 'processing'], 'understood');
type _4 = Expect<Equal<typeof loose.current, 'idle' | 'listening' | 'processing' | 'understood'>>;

// NoInfer (5.4) removes an argument from the inference: S comes from states only, and initial is checked against it
function strictMachine<S extends string>(states: readonly S[], initial: NoInfer<S>) {
  return { states, current: initial };
}
const strict = strictMachine(['idle', 'listening', 'processing', 'understood'], 'idle');
type _5 = Expect<Equal<typeof strict.current, 'idle' | 'listening' | 'processing' | 'understood'>>;
// @ts-expect-error: 'speaking' is not one of the states
strictMachine(['idle', 'listening'], 'speaking');

// Inference from the return type: the declared type of the variable flows into the call
function emptyList<T>(): T[] {
  return [];
}
const chords: string[] = emptyList(); // T is string, inferred from the context, as Java does and C# doesn't
type _6 = Expect<Equal<ReturnType<typeof emptyList<number>>, number[]>>;

show('dadgad', dadgad);
show('loose.current', loose.current);
show('chords.length', chords.length);
