// solutions/l01_ex2_six_strings.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Fret<C extends string> = C extends 'x' ? null : C extends `${infer N extends number}` ? N : never;
type Fingering<S extends string, Acc extends unknown[] = []> = S extends `${infer C}${infer Rest}` ? Fingering<Rest, [...Acc, Fret<C>]> : Acc;

// A fingering for a six-string guitar: six characters, each a digit or x; anything else gives never
type HasNever<T extends unknown[]> = true extends { [K in keyof T]: [T[K]] extends [never] ? true : false }[number] ? true : false;
type Valid<S extends string> = Fingering<S>['length'] extends 6 ? (HasNever<Fingering<S>> extends true ? never : S) : never;

type _1 = Expect<Equal<Valid<'x32010'>, 'x32010'>>;
type _2 = Expect<Equal<Valid<'x3201'>, never>>;
type _3 = Expect<Equal<Valid<'x3201y'>, never>>;

// S & Valid<S>: the argument must be both the literal and its checked version, never when the check fails
function parseFingering<S extends string>(text: S & Valid<S>): Fingering<S> {
  return [...text].map((c) => (c === 'x' ? null : Number(c))) as Fingering<S>;
}

console.log(parseFingering('x32010'), parseFingering('022100'));

function mistakes() {
  // @ts-expect-error: five strings
  parseFingering('x3201');
  // @ts-expect-error: y is neither a fret nor x
  parseFingering('x3201y');
}
console.log(typeof mistakes);
