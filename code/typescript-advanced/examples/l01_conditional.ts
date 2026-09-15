// examples/l01_conditional.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// A conditional type picks a branch when its type argument is known
type IsString<T> = T extends string ? true : false;
type _1 = Expect<Equal<IsString<'C#'>, true>>;
type _2 = Expect<Equal<IsString<440>, false>>;

// Distributive: a type parameter checked on its own is checked once per member of a union
type ToArray<T> = T extends unknown ? T[] : never;
type _3 = Expect<Equal<ToArray<string | number>, string[] | number[]>>;
// Wrapped in a tuple, the union is checked as a whole
type ToArrayWhole<T> = [T] extends [unknown] ? T[] : never;
type _4 = Expect<Equal<ToArrayWhole<string | number>, (string | number)[]>>;

// never is the empty union: a distributive conditional type maps it to never without checking anything
type IsNeverWrong<T> = T extends never ? true : false;
type IsNever<T> = [T] extends [never] ? true : false;
type _5 = Expect<Equal<IsNeverWrong<never>, never>>;
type _6 = Expect<Equal<IsNever<never>, true>>;

// Extract and Exclude, from lib.es5.d.ts, are distributive conditional types that filter a union
type Accidental = 'natural' | 'sharp' | 'flat' | 'double-sharp' | 'double-flat';
type _7 = Expect<Equal<Extract<Accidental, `double-${string}`>, 'double-sharp' | 'double-flat'>>;
type _8 = Expect<Equal<Exclude<Accidental, `double-${string}`>, 'natural' | 'sharp' | 'flat'>>;

// infer names a part of the type being checked
type ElementOf<T> = T extends readonly (infer E)[] ? E : never;
type PayloadOf<F> = F extends (data: infer D) => void ? D : never;
type _9 = Expect<Equal<ElementOf<readonly ['E', 'A', 'D']>, 'E' | 'A' | 'D'>>;
type _10 = Expect<Equal<PayloadOf<(data: { target: string }) => void>, { target: string }>>;

// infer with a constraint: the branch is taken only if the inferred text is a number, which becomes a number type
type FretOf<T> = T extends `fret-${infer N extends number}` ? N : never;
type _11 = Expect<Equal<FretOf<'fret-12'>, 12>>;
type _12 = Expect<Equal<FretOf<'fret-XII'>, never>>;

// One name inferred twice: a union from covariant positions, an intersection from contravariant ones
type Both<T> = T extends { a: infer U; b: infer U } ? U : never;
type BothParams<T> = T extends { a: (x: infer U) => void; b: (x: infer U) => void } ? U : never;
type _13 = Expect<Equal<Both<{ a: string; b: number }>, string | number>>;
type _14 = Expect<Equal<BothParams<{ a: (x: { root: string }) => void; b: (x: { quality: string }) => void }>, { root: string } & { quality: string }>>;

// Inside a generic function, T is not known yet: the conditional type is deferred, and tsc can't pick a branch
function describe<T extends string | number>(value: T): T extends string ? 'text' : 'number' {
  const kind = typeof value === 'string' ? 'text' : 'number';
  return kind as T extends string ? 'text' : 'number'; // an assertion: narrowing value doesn't narrow T
}
const fromText = describe('C#');
const fromNumber = describe(440);
type _15 = Expect<Equal<typeof fromText, 'text'>>;
type _16 = Expect<Equal<typeof fromNumber, 'number'>>;

// Overloads describe the same function without a conditional type, and without an assertion in the body
function describeOverloaded(value: string): 'text';
function describeOverloaded(value: number): 'number';
function describeOverloaded(value: string | number): 'text' | 'number' {
  return typeof value === 'string' ? 'text' : 'number';
}

// Types are erased: at run time, only the values remain
show('describe', [fromText, fromNumber]);
show('describeOverloaded', [describeOverloaded('C#'), describeOverloaded(440)]);
