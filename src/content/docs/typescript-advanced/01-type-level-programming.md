---
title: 1. Type-level programming
description: Types that compute types — testing them with Expect and Equal, conditional types, distributivity and infer, mapped types with key remapping, template literal types that parse strings, recursive types and the limits of the checker in typescript-go, then a typed layer over GA's SignalR hub, compared with the typed keys that C# and Java need.
sidebar:
  order: 1
---

Code: the files [`examples/l01_*`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples), [`examples/type-tests.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples/type-tests.ts) and [`errors/l01_*`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/errors), and the C# and Java sides in [`compare/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare) (`l01_typed_keys.cs`, `L01TypedKeys.java`) and [`compare_fail/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare_fail) (`l01_infer_from_name.cs`, `L01InferFromName.java`).

A generic type alias is a function whose arguments and result are types. The checker runs it whenever the alias is used with type arguments, and TypeScript gives that language the constructs of a small functional language: a conditional, pattern matching with `infer`, a loop over the keys of an object, string concatenation and parsing, and recursion. C# and Java have no equivalent inside the compiler; what comes closest is a source generator or an annotation processor, which write code before it is compiled. This lesson writes such types, tests them, and looks at the limits that the checker sets on them.

| Programming with values | Programming with types |
|---|---|
| a function `f(x)` | a generic alias `F<X>` |
| `if`, `? :` | a conditional type, `X extends Y ? A : B` |
| destructuring, pattern matching | `infer` |
| `map` over an object's entries | a mapped type, `{ [K in keyof T]: … }` |
| string templates and parsing | template literal types |
| recursion, loops | recursive aliases |
| a unit test | a type that fails to compile when the result is wrong |

## Testing types

Types have no output to print, so each example checks its results with a type test: a line that compiles when the computed type is the expected one and fails the build otherwise. The two helpers live in [`type-tests.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples/type-tests.ts), and `check.sh` runs `tsc` on the whole project, so a failing test fails the CI:

```ts
// examples/type-tests.ts
// Type tests that tsc checks and Node.js erases: Expect<Equal<A, B>> fails to compile unless A and B are the same type

// Two function types are compared with an extra type parameter U, which tsc can't resolve: they are assignable
// only if A and B are identical, which catches any, unions and optional modifiers that extends alone lets through
export type Equal<A, B> = (<U>() => U extends A ? 1 : 2) extends <U>() => U extends B ? 1 : 2 ? true : false;
export type Expect<T extends true> = T;
```

`Expect<T extends true>` accepts only `true`. `Equal<A, B>` is less obvious. A simpler `[A] extends [B] ? ([B] extends [A] ? true : false) : false` compares assignability in both directions, and assignability is too lenient for a test: `any` is assignable to everything and back, and `{ a?: string }` and `{ a?: string | undefined }` are mutually assignable without `exactOptionalPropertyTypes`. The version above compares two generic function types whose return types are conditional types on a type parameter `U` that nothing fixes. The checker can't evaluate them, so it compares the two conditional types themselves, and considers them related only if `A` and `B` are identical. The trick comes from a [discussion in the TypeScript repository](https://github.com/microsoft/TypeScript/issues/27024#issuecomment-421529650), and libraries such as [`expect-type`](https://github.com/mmkal/expect-type) build on the same idea; lesson 11 compares them.

A test that fails, and an expected error that doesn't happen, both stop the build:

```text
> npx tsc -p out/tsconfig.l01_type_tests.json --pretty
errors/l01_type_tests.ts:8:18 - error TS2344: Type 'false' does not satisfy the constraint 'true'.

8 type _2 = Expect<Equal<ElementOf<readonly string[]>, string>>;
                   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

errors/l01_type_tests.ts:10:1 - error TS2578: Unused '@ts-expect-error' directive.

10 // @ts-expect-error: a string is not an array, so this line should be rejected
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Found 2 errors in the same file, starting at: errors/l01_type_tests.ts:8
> node errors/l01_type_tests.ts
undefined
```

`ElementOf<readonly string[]>` gives `never`, because a `readonly string[]` is not assignable to the mutable `(infer E)[]`, and the test catches it with `TS2344`. The second error, `TS2578`, comes from [`// @ts-expect-error`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-9.html#-ts-expect-error-comments): the line below it compiles, so the comment is reported as unused. The two together make a type test suite: `Expect` for what a type computes, `@ts-expect-error` for what an API must refuse. Node.js runs the file anyway and prints `undefined`, since both type aliases and the comment are erased.

## Conditional types

```ts
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
```

```text
describe                           [ 'text', 'number' ]
describeOverloaded                 [ 'text', 'number' ]
```

A [conditional type](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html), `T extends U ? X : Y`, asks whether `T` is assignable to `U`. Four of its rules explain most of the surprises.

**Distributivity.** When the checked type is a type parameter on its own, and the argument is a union, the conditional type is evaluated once for each member and the results are joined: `ToArray<string | number>` is `string[] | number[]`, not `(string | number)[]`. The handbook calls these [distributive conditional types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html#distributive-conditional-types). It is what makes `Extract` and `Exclude` work: `lib.es5.d.ts` defines `Exclude<T, U>` as `T extends U ? never : T`, which keeps the members of `T` that don't match. Wrapping both sides in a tuple, `[T] extends [unknown]`, turns distribution off, because `[T]` is no longer a naked type parameter.

**`never` is the empty union.** A distributive conditional type over zero members returns zero results, so `IsNeverWrong<never>` is `never`, not `true`. Testing for `never` needs the tuple form, `[T] extends [never]`. The same rule explains why a conditional type applied to a type that has been filtered down to nothing silently disappears.

**`infer` names a part of the checked type.** `T extends readonly (infer E)[] ? E : never` matches arrays and names their element type. Since [TypeScript 4.7](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#extends-constraints-on-infer-type-variables), an `infer` can carry a constraint, `infer N extends number`, and when it appears in a template literal, [4.8](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-8.html#improved-inference-for-infer-types-in-template-string-types) converts the matched text into a number literal type: `FretOf<'fret-12'>` is the type `12`, and `'fret-XII'` doesn't match. When the same name is inferred twice, the candidates are combined according to the position: a union in covariant positions, such as two property types, and an intersection in contravariant positions, such as two parameter types, because a function that must accept both arguments accepts their intersection. Lesson 2 comes back to these positions.

**Inside a generic body, the condition is deferred.** `describe<T>` returns `T extends string ? 'text' : 'number'`. At each call, `T` is known, and the result is `'text'` or `'number'`. Inside the function, `T` is not known, and narrowing `value` with `typeof` doesn't narrow `T`, since `T` could be the union `string | number` itself. The checker can't pick a branch, and refuses both literals:

```text
> npx tsc -p out/tsconfig.l01_deferred.json --pretty
errors/l01_deferred.ts:4:34 - error TS2322: Type '"text"' is not assignable to type 'T extends string ? "text" : "number"'.

4   if (typeof value === 'string') return 'text';
                                   ~~~~~~

errors/l01_deferred.ts:5:3 - error TS2322: Type '"number"' is not assignable to type 'T extends string ? "text" : "number"'.

5   return 'number';
    ~~~~~~


Found 2 errors in the same file, starting at: errors/l01_deferred.ts:4
> node errors/l01_deferred.ts
text number
```

The example compiles with an assertion on the return value, which is the usual way to implement a function whose return type is a conditional type. Overloads, as in `describeOverloaded`, say the same thing to callers without any assertion in the body, at the price of one signature per case. C# resolves overloads the same way at compile time; what it has no equivalent for is the single signature whose return type is computed from the argument.

## Mapped types and key remapping

```ts
// examples/l01_mapped.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

interface Voicing {
  readonly id: string;
  frets: number[];
  capo?: number;
  label?: string;
}

// A homomorphic mapped type, { [K in keyof T]: … }, keeps each property's readonly and ? modifiers
type Nullable<T> = { [K in keyof T]: T[K] | null };
type _1 = Expect<Equal<Nullable<Voicing>, { readonly id: string | null; frets: number[] | null; capo?: number | null; label?: string | null }>>;

// -readonly and -? remove the modifiers; readonly and ? add them
type Mutable<T> = { -readonly [K in keyof T]: T[K] };
type Complete<T> = { [K in keyof T]-?: T[K] };
type _2 = Expect<Equal<Mutable<Voicing>, { id: string; frets: number[]; capo?: number; label?: string }>>;
type _3 = Expect<Equal<Complete<Voicing>, { readonly id: string; frets: number[]; capo: number; label: string }>>;

// Key remapping with as: the new key is computed, here with a template literal type
type Getters<T> = { [K in keyof T & string as `get${Capitalize<K>}`]: () => T[K] };
type _4 = Expect<Equal<keyof Getters<Voicing>, 'getId' | 'getFrets' | 'getCapo' | 'getLabel'>>;

// A key remapped to never is removed: a filter on the properties
type KeysOfType<T, V> = keyof { [K in keyof T as T[K] extends V ? K : never]: T[K] };
type OptionalKeys<T> = keyof { [K in keyof T as {} extends Pick<T, K> ? K : never]: T[K] };
type _5 = Expect<Equal<KeysOfType<Voicing, string>, 'id'>>;
type _6 = Expect<Equal<OptionalKeys<Voicing>, 'capo' | 'label'>>;

// A homomorphic mapped type applied to a tuple gives a tuple
type Boxed<T> = { [K in keyof T]: { value: T[K] } };
type _7 = Expect<Equal<Boxed<[string, number]>, [{ value: string }, { value: number }]>>;

// The implementation needs one assertion: tsc can't follow Object.entries through a key remapping
function gettersOf<T extends object>(value: T): Getters<T> {
  const entries = Object.entries(value).map(([key, v]) => [`get${key.charAt(0).toUpperCase()}${key.slice(1)}`, () => v]);
  return Object.fromEntries(entries) as Getters<T>;
}
const voicing: Voicing = { id: 'C-open', frets: [-1, 3, 2, 0, 1, 0], label: 'C major' };
const getters = gettersOf(voicing);
show('Object.keys(getters)', Object.keys(getters));
show('getters.getLabel()', getters.getLabel());
// getCapo is in the type, and not in the object: the type lists what Voicing allows, not what this value has
show("'getCapo' in getters", 'getCapo' in getters);
```

```text
Object.keys(getters)               [ 'getId', 'getFrets', 'getLabel' ]
getters.getLabel()                 'C major'
'getCapo' in getters               false
```

A [mapped type](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html) iterates over a union of keys. When that union is `keyof T` for a type `T`, the mapped type is called homomorphic, and it keeps each property's modifiers: `Nullable<Voicing>` has a `readonly id` and an optional `capo`, like `Voicing`. The modifiers can be removed with `-readonly` and `-?`, which is how the standard library writes `Required<T>`.

**Key remapping**, added in [TypeScript 4.1](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-1.html#key-remapping-in-mapped-types), computes a new name for each key with `as`: `Getters<Voicing>` has `getId`, `getFrets`, `getCapo` and `getLabel`. The intersection `keyof T & string` is needed because `keyof` can also contain numbers and symbols, which a template literal type can't capitalize. Remapping a key to `never` removes the property, and that is how `KeysOfType` and `OptionalKeys` filter properties by their value type or by their modifier. `OptionalKeys` uses a small trick: `{}` is assignable to `Pick<T, K>` only if the property `K` is optional.

A homomorphic mapped type applied to a tuple produces a tuple, `Boxed<[string, number]>`, which lets a single mapped type transform every element of a list of arguments.

The run-time function `gettersOf` needs an assertion. `Object.entries` returns `[string, any][]`, and nothing relates the strings computed at run time to the keys computed by `Getters<T>`. The output shows the other gap: `getCapo` exists in the type, because `Voicing` allows a `capo`, and not in the object, because this value has none. A mapped type describes the type `T`, not the value that was passed.

## Template literal types

```ts
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
```

```text
parseChord('F#m7')                 { root: 'F#', quality: 'm7' }
parseChord('Bbmaj7').root          'Bb'
parse 'Gsus4'                      { root: 'G', quality: 'sus4' }
parse 'H7'                         'rejected: H7'
handlerName('cameraSync')          'onCameraSync'
```

A [template literal type](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html) builds string literal types the way a template literal builds strings, and it distributes over unions: seven letters, three accidentals and eight qualities give 168 chord symbols, all checked by `tsc`. The first type test lists the 24 symbols that start with `C`, including `C#` and `Cb` with every quality.

Pattern matching on a string uses `infer` inside the template. Two rules make `ParseChord` work. An `infer` followed immediately by another `infer` matches exactly one character, so `${infer L extends Letter}${infer Rest}` takes the first letter. And a constraint on the `infer` makes the match fail when the text doesn't fit, which is how `#` and `b` are told apart from a quality.

The function `parseChord` connects the two worlds. Its parameter is a `ChordSymbol`, so a literal argument is checked at compile time, and its return type is `ParseChord<S>`, so `parseChord('F#m7')` has the type `{ root: 'F#'; quality: 'm7' }`. The regex and the type describe the same grammar twice, and nothing checks that they agree, except tests. A string that arrives at run time, like `'H7'`, the German name of B7, has the type `string`, and must be checked by a type guard before the call; the guard is the run-time half of the type.

`Capitalize`, `Uncapitalize`, `Uppercase` and `Lowercase` are [intrinsic string manipulation types](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html#intrinsic-string-manipulation-types), implemented inside the checker. They have no run-time counterpart, and `handlerName` reimplements the capitalization with `charAt(0).toUpperCase()`.

## Recursive types and the checker's limits

```ts
// examples/l01_recursive.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// A recursive conditional type walks a string one character at a time: a guitar fingering, low E string first
type Fret<C extends string> = C extends 'x' ? null : C extends `${infer N extends number}` ? N : never;
type Fingering<S extends string> = S extends `${infer C}${infer Rest}` ? [Fret<C>, ...Fingering<Rest>] : [];
type _1 = Expect<Equal<Fingering<'x32010'>, [null, 3, 2, 0, 1, 0]>>;

// A recursive type follows a nested object: DeepReadonly, which the standard library doesn't provide
type DeepReadonly<T> = T extends (...args: never[]) => unknown
  ? T
  : T extends object
    ? { readonly [K in keyof T]: DeepReadonly<T[K]> }
    : T;
interface Tuning {
  name: string;
  strings: { note: string; octave: number }[];
}
type _2 = Expect<Equal<DeepReadonly<Tuning>, { readonly name: string; readonly strings: readonly { readonly note: string; readonly octave: number }[] }>>;

// Dotted paths into a nested type, as form and translation libraries compute them
type Paths<T> = T extends object
  ? { [K in keyof T & string]: T[K] extends readonly unknown[] ? K : T[K] extends object ? K | `${K}.${Paths<T[K]>}` : K }[keyof T & string]
  : never;
interface SceneSettings {
  camera: { position: { x: number; y: number; z: number }; fov: number };
  stars: boolean;
  tunings: Tuning[];
}
type _3 = Expect<Equal<Paths<SceneSettings>, 'camera' | 'camera.position' | 'camera.position.x' | 'camera.position.y' | 'camera.position.z' | 'camera.fov' | 'stars' | 'tunings'>>;

// Tail recursion: when the recursive call is the whole branch, tsc evaluates it in a loop, up to 1,000 times.
// Fingering is not tail-recursive: its call sits inside a tuple. With an accumulator, the call is the branch.
type FingeringTail<S extends string, Acc extends unknown[] = []> = S extends `${infer C}${infer Rest}` ? FingeringTail<Rest, [...Acc, Fret<C>]> : Acc;
type Long = `${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}`;
type _4 = Expect<Equal<FingeringTail<Long>['length'], 60>>;

// The run-time parser, typed by the recursive type
function parseFingering<S extends string>(text: S): Fingering<S> {
  return [...text].map((c) => (c === 'x' ? null : Number(c))) as Fingering<S>;
}
const cMajor = parseFingering('x32010');
type _5 = Expect<Equal<(typeof cMajor)[1], 3>>;
show("parseFingering('x32010')", cMajor);

function getPath<T, P extends Paths<T>>(value: T, path: P): unknown {
  return path.split('.').reduce<unknown>((current, key) => (current as Record<string, unknown>)[key], value);
}
const settings: SceneSettings = { camera: { position: { x: 0, y: 2, z: 10 }, fov: 60 }, stars: true, tunings: [] };
show("getPath(settings, 'camera.fov')", getPath(settings, 'camera.fov'));
```

```text
parseFingering('x32010')           [ null, 3, 2, 0, 1, 0 ]
getPath(settings, 'camera.fov')    60
```

A type alias can refer to itself. `Fingering` walks a string such as `'x32010'`, the fingering of an open C major chord from the low E string to the high E string, one character at a time. `DeepReadonly` walks an object, and stops at functions, whose properties shouldn't be made read-only. `Paths` computes every dotted path into a nested object, the kind of type that form libraries use to check a field name such as `'camera.position.x'`; it stops at arrays to keep the union finite.

Recursion is where the checker sets limits, and the snippet below hits all three:

```text
> npx tsc -p out/tsconfig.l01_limits.json --pretty
errors/l01_limits.ts:5:19 - error TS2589: Type instantiation is excessively deep and possibly infinite.

5 type Length1000 = BuildTuple<1000>['length'];
                    ~~~~~~~~~~~~~~~~

errors/l01_limits.ts:9:19 - error TS2589: Type instantiation is excessively deep and possibly infinite.

9 type Reversed49 = Reverse<BuildTuple<49>>['length'];
                    ~~~~~~~~~~~~~~~~~~~~~~~

errors/l01_limits.ts:17:19 - error TS2590: Expression produces a union type that is too complex to represent.

17 type FiveDigits = `${Digit}${Digit}${Digit}${Digit}${Digit}`;
                     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Found 3 errors in the same file, starting at: errors/l01_limits.ts:5
> node errors/l01_limits.ts
[ 999, 1000, 49, 40, 80 ] [ '0440', '04400' ]
```

The limits are in [`internal/checker/checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go) of typescript-go, at the tag of 7.0.2:

- **Instantiation depth: 100.** [Line 22016](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go#L22016-L22024) stops when 100 instantiations are nested, or after 5 million instantiations for the same statement, and reports `TS2589`. `Reverse` is not tail-recursive: its recursive call sits inside a tuple, `[...Reverse<Tail>, Head]`, so every level waits for the next one. In a file of its own, reversing 48 elements passes and 49 fails, which suggests about two nested instantiations per level.
- **Tail recursion: 1,000.** When a conditional type resolves to another conditional type in its false branch, or to a recursive call that is the whole branch, the checker evaluates it in a loop instead of nesting, and [line 24218](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go#L24211-L24222) stops that loop after 1,000 iterations. `BuildTuple` passes its accumulator along, so it builds a tuple of 999 elements, and fails at 1,000. This optimization arrived in [TypeScript 4.5](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-5.html#tail-recursion-elimination-on-conditional-types).
- **Union size: 100,000.** [Line 26521](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go#L26519-L26530) computes the size of a template literal's cross product before building it, and refuses a union of 100,000 members or more with `TS2590`. Four digits make 10,000 strings; five make exactly 100,000, one too many.

The snippet shows one more thing, which I didn't expect. `Reversed49` fails, and `Reversed80`, which is deeper, passes, because it comes after `Reversed40`. Instantiations are cached, so reversing 80 elements reaches, after 40 levels, a tuple whose reversal is already known. Alone, in its own file, `Reverse<BuildTuple<80>>` fails too. The practical rule is the one the example follows with `FingeringTail`: write recursive types with an accumulator, so that the recursive call is the whole branch, and they can handle inputs of hundreds of elements; the non-tail version works only because inputs are short, and may break when an unrelated type stops being cached.

## In GuitarAlchemist/ga: a typed hub

GA's Prime Radiant view receives its governance graph from a SignalR hub. On the client, [`DataLoader.ts`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L272-L326) registers ten handlers, one per event, each written like this:

```ts
connection.on('NodeChanged', (data: { nodeId: string; health: unknown; healthStatus: string; color: string }) => {
  // Partial update — single node
  onUpdate({ nodes: [data as unknown as GovernanceNode], edges: [], globalHealth: { resilienceScore: 0, lolliCount: 0, ergolCount: 0 }, timestamp: new Date().toISOString() } as GovernanceGraph);
});
```

The signature of `on` in the SignalR client is [`on(methodName: string, newMethod: (...args: any[]) => any): void`](https://github.com/dotnet/aspnetcore/blob/a5383385245bdacc20ec19f30e46090a8154d8da/src/SignalR/clients/ts/signalr/src/HubConnection.ts#L508-L509), and [`invoke`](https://github.com/dotnet/aspnetcore/blob/a5383385245bdacc20ec19f30e46090a8154d8da/src/SignalR/clients/ts/signalr/src/HubConnection.ts#L466) takes `...args: any[]`. Every event name is a `string`, every payload an `any`, and each handler annotates its parameter by hand. On the server, [`GovernanceHub.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Apps/ga-server/GaApi/Hubs/GovernanceHub.cs#L40-L43) derives from `Hub`, not from the strongly typed [`Hub<T>`](https://learn.microsoft.com/aspnet/core/signalr/hubs#strongly-typed-hubs), and sends each event with `SendAsync("NodeChanged", new { … })`. Nothing on either side checks that the names and the shapes agree. The client's [`LiveDataConfig`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L171-L198) then lists a callback for most events, again by hand: `onBeliefUpdate`, `onCameraSync`, `onNavigateToPlanet`, and `onScreenshotRequest` for the event `RequestScreenshot`.

One table of events is enough to type all of it:

```ts
// examples/l01_hub_events.ts
// GuitarAlchemist/ga's governance hub, typed from one table of events instead of one annotation per handler
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

interface HealthMetrics {
  resilienceScore: number;
  lolliCount: number;
  ergolCount: number;
}
interface GovernanceNode {
  id: string;
  name: string;
  health?: HealthMetrics;
}

// What GovernanceHub.cs sends to the client, event by event, as SignalR serializes it (camelCase property names)
interface GovernanceHubEvents {
  GraphUpdate: { nodes: GovernanceNode[]; timestamp: string };
  NodeChanged: { nodeId: string; health: HealthMetrics; healthStatus: string; color: string; timestamp: string };
  Connected: { message: string; connections: number; timestamp: string };
  NavigateToPlanet: { target: string; timestamp: string };
  RequestScreenshot: { reason: string; timestamp: string };
  CameraSync: { px: number; py: number; pz: number; lx: number; ly: number; lz: number; sender: string };
}
// What the client can call on the hub: parameter lists as labeled tuples
interface GovernanceHubMethods {
  Subscribe: [];
  SubmitScreenshot: [base64Image: string, format: string];
  SyncCamera: [px: number, py: number, pz: number, lx: number, ly: number, lz: number];
}

// The part of @microsoft/signalr's HubConnection used here: every name is a string, every argument any
interface HubConnection {
  on(methodName: string, newMethod: (...args: any[]) => any): void;
  invoke<T = any>(methodName: string, ...args: any[]): Promise<T>;
}

// A typed layer over it: the name is a key of the table, and the handler's parameter is looked up from that key
function on<K extends keyof GovernanceHubEvents>(connection: HubConnection, name: K, handler: (data: GovernanceHubEvents[K]) => void): void {
  connection.on(name, handler);
}
function invoke<K extends keyof GovernanceHubMethods>(connection: HubConnection, name: K, ...args: GovernanceHubMethods[K]): Promise<void> {
  return connection.invoke(name, ...args);
}

// GA's LiveDataConfig lists its callbacks by hand; key remapping derives them from the table
type Callbacks<Events> = { [K in keyof Events & string as `on${K}`]?: (data: Events[K]) => void };
type GovernanceCallbacks = Callbacks<GovernanceHubEvents>;
type _1 = Expect<Equal<keyof GovernanceCallbacks, 'onGraphUpdate' | 'onNodeChanged' | 'onConnected' | 'onNavigateToPlanet' | 'onRequestScreenshot' | 'onCameraSync'>>;

// One loop registers every callback that the caller provided
const eventNames = ['GraphUpdate', 'NodeChanged', 'Connected', 'NavigateToPlanet', 'RequestScreenshot', 'CameraSync'] as const satisfies readonly (keyof GovernanceHubEvents)[];
type _2 = Expect<Equal<(typeof eventNames)[number], keyof GovernanceHubEvents>>;
function subscribe(connection: HubConnection, callbacks: GovernanceCallbacks): void {
  for (const name of eventNames) {
    const callback = callbacks[`on${name}`];
    if (callback) connection.on(name, callback);
  }
}

// A fake connection that records the handlers and lets the example play the server's part
const handlers = new Map<string, (...args: any[]) => any>();
const connection: HubConnection = {
  on: (methodName, newMethod) => void handlers.set(methodName, newMethod),
  invoke: (methodName, ...args) => {
    console.log(`invoke ${methodName}(${args.join(', ')})`);
    return Promise.resolve() as Promise<never>; // a fake: every call resolves with undefined, whatever T the caller expects
  },
};
const serverSends = (name: string, data: unknown) => handlers.get(name)?.(data);

subscribe(connection, {
  onNavigateToPlanet: (data) => console.log(`navigate to ${data.target}`),
  onNodeChanged: (data) => console.log(`node ${data.nodeId} is now ${data.healthStatus}`),
});
on(connection, 'Connected', (data) => console.log(`${data.connections} clients connected`));

serverSends('NavigateToPlanet', { target: 'saturn', timestamp: '2026-09-15T12:00:00Z' });
serverSends('NodeChanged', { nodeId: 'policy-7', health: { resilienceScore: 0.4, lolliCount: 0, ergolCount: 3 }, healthStatus: 'warning', color: '#FFB300', timestamp: '2026-09-15T12:00:01Z' });
serverSends('Connected', { message: 'Connected to Governance Hub', connections: 2, timestamp: '2026-09-15T12:00:02Z' });
await invoke(connection, 'SyncCamera', 0, 2, 10, 0, 0, 0);
show('registered handlers', [...handlers.keys()]);
```

```text
navigate to saturn
node policy-7 is now warning
2 clients connected
invoke SyncCamera(0, 2, 10, 0, 0, 0)
registered handlers                [ 'NodeChanged', 'NavigateToPlanet', 'Connected' ]
```

- **`on<K extends keyof GovernanceHubEvents>`**: the name is a key of the table, and the handler's parameter is the indexed access `GovernanceHubEvents[K]`, looked up from the literal type of the name. The handler needs no annotation.
- **`invoke`** takes the hub method's parameters as a rest parameter typed by a labeled tuple, `[px: number, py: number, …]`, so an editor shows the names and `tsc` counts the arguments.
- **`Callbacks<Events>`** derives `LiveDataConfig`'s callbacks with key remapping, `on${K}`. GA's names already follow that pattern for most events, which is what makes the derivation fit; the one exception, `onScreenshotRequest`, is exactly the kind of drift that a derived type prevents.
- **`as const satisfies`** checks that the list of names contains only keys of the table, and the type test `_2` checks that it contains all of them. Lesson 2 explains `satisfies`.

The typed layer turns four mistakes that GA's code would accept into compile errors:

```text
> npx tsc -p out/tsconfig.l01_hub_events.json --pretty
errors/l01_hub_events.ts:28:4 - error TS2345: Argument of type '"NodeChange"' is not assignable to parameter of type 'keyof GovernanceHubEvents'.

28 on('NodeChange', (data) => console.log(data));
      ~~~~~~~~~~~~

errors/l01_hub_events.ts:29:46 - error TS2339: Property 'id' does not exist on type '{ nodeId: string; healthStatus: string; color: string; timestamp: string; }'.

29 on('NodeChanged', (data) => console.log(data.id));
                                                ~~

errors/l01_hub_events.ts:30:1 - error TS2554: Expected 7 arguments, but got 4.

30 invoke('SyncCamera', 0, 2, 10);
   ~~~~~~

errors/l01_hub_events.ts:32:3 - error TS2353: Object literal may only specify known properties, and 'onScreenshotRequest' does not exist in type 'Callbacks<GovernanceHubEvents>'.

32   onScreenshotRequest: (data) => console.log(data.reason),
     ~~~~~~~~~~~~~~~~~~~

errors/l01_hub_events.ts:32:25 - error TS7006: Parameter 'data' implicitly has an 'any' type.

32   onScreenshotRequest: (data) => console.log(data.reason),
                           ~~~~


Found 5 errors in the same file, starting at: errors/l01_hub_events.ts:28
```

The first line is a misspelled event name, which SignalR would never call. The second reads `data.id` on a `NodeChanged` payload, which has `nodeId`: that is the confusion that GA's `data as unknown as GovernanceNode` hides, and lesson 4 shows what it costs at run time. The third forgets three of the six camera coordinates. The fourth uses GA's name for the screenshot callback, and `TS7006` follows from it: once the property is unknown, its function has no contextual type.

The table is still a claim about the server. It says what `GovernanceHub.cs` sends, and nothing checks it against the C# code; lesson 4 adds the check at run time, and generating the table from the hub, as [TypedSignalR.Client](https://github.com/nenoNaninu/TypedSignalR.Client.TypeScript) does, is the compile-time alternative (*to verify* on GA).

### The same idea in C# and Java

C# and Java have no literal types: the string `"NavigateToPlanet"` has the type `string`, and a method can't look up a payload type from it. A generic `On<T>(string name, Action<T> handler)` leaves `T` with nothing to be inferred from:

```text
> dotnet run l01_infer_from_name.cs
compare_fail/l01_infer_from_name.cs(4,5): error CS0411: The type arguments for method 'Hub.On<T>(string, Action<T>)' cannot be inferred from the usage. Try specifying the type arguments explicitly.

The build failed. Fix the build errors and run again.
```

```text
> javac L01InferFromName.java
L01InferFromName.java:10: error: cannot find symbol
        on("NavigateToPlanet", data -> System.out.println(data.target()));
                                                              ^
  symbol:   method target()
  location: variable data of type Object
1 error
```

C# refuses the call with `CS0411`. Java infers `T` as `Object` and then refuses `data.target()`. The usual solution in both languages is a typed key: an object that carries the wire name and, in its type parameter, the payload type.

```csharp
// compare/l01_typed_keys.cs
// C# has no literal types: a string can't carry its payload's type, so a typed key object does
var hub = new Hub();
hub.On(HubEvents.NavigateToPlanet, data => Console.WriteLine($"navigate to {data.Target}"));
hub.On(HubEvents.Connected, data => Console.WriteLine($"{data.Connections} clients connected"));
hub.Receive("NavigateToPlanet", new NavigateToPlanet("saturn"));
hub.Receive("Connected", new Connected(2));

record NavigateToPlanet(string Target);
record Connected(int Connections);

// The key: a name for the wire, and a type parameter for the compiler
sealed record HubEvent<T>(string Name);

static class HubEvents
{
    public static readonly HubEvent<NavigateToPlanet> NavigateToPlanet = new("NavigateToPlanet");
    public static readonly HubEvent<Connected> Connected = new("Connected");
}

class Hub
{
    private readonly Dictionary<string, Action<object>> handlers = [];

    // T is inferred from the key, as TypeScript infers K from the string
    public void On<T>(HubEvent<T> hubEvent, Action<T> handler) => handlers[hubEvent.Name] = data => handler((T)data);

    public void Receive(string name, object data) => handlers[name](data);
}
```

```text
> dotnet run l01_typed_keys.cs
navigate to saturn
2 clients connected
```

```text
> java L01TypedKeys.java
navigate to saturn
2 clients connected
ClassCastException: Cannot cast L01TypedKeys$NavigateToPlanet to L01TypedKeys$Connected
```

`HubEvents.NavigateToPlanet` is a `HubEvent<NavigateToPlanet>`, and `On<T>` infers `T` from it, as `on<K>` infers `K` from the string in TypeScript. The Java version keeps a `Class<T>` in the key, which also allows a checked cast at run time: the last line shows it rejecting a payload of the wrong type, where TypeScript's erased types can't check anything. What neither language can do in the type system is derive `onNavigateToPlanet` from `NavigateToPlanet`; in C#, that is a job for a [source generator](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview).

| | C# | Java | TypeScript |
|---|---|---|---|
| Compute a type from a type | no; source generators write code | no; annotation processors write code | conditional, mapped, template literal types |
| A key that selects a payload type | a typed key object, `HubEvent<T>` | a typed key with `Class<T>` | the string literal itself |
| Derive member names | source generator | annotation processor | key remapping, `on${K}` |
| Check at run time | casts on reified types | `Class<T>.cast` | nothing: a schema (lesson 4) |

## Key takeaways

- A generic type alias is a function run by the checker; test its results with `Expect<Equal<…>>` and `@ts-expect-error`, as the course's CI does.
- A conditional type on a naked type parameter distributes over unions, maps `never` to `never`, and is deferred inside a generic body; wrap it in a tuple to stop distribution.
- `infer` extracts parts of a type, with constraints since 4.7, and gives unions in covariant positions and intersections in contravariant ones.
- Homomorphic mapped types keep modifiers, key remapping computes or filters property names, and template literal types build and parse strings.
- The checker stops at 100 nested instantiations, 1,000 tail-recursive steps, and unions of 100,000 members; write recursive types with an accumulator.
- A literal type lets a string select a type, which C# and Java can only do with a typed key object.

## Exercises

1. `getPath` in `l01_recursive.ts` returns `unknown`. Write `PathValue<T, P>`, the type found at the end of a dotted path, and use it as the return type, so that `getPath(settings, 'camera.fov')` is a `number`.

<details>
<summary>Solution</summary>

[`solutions/l01_ex1_path_value.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l01_ex1_path_value.ts):

```ts
// solutions/l01_ex1_path_value.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Paths<T> = T extends object
  ? { [K in keyof T & string]: T[K] extends readonly unknown[] ? K : T[K] extends object ? K | `${K}.${Paths<T[K]>}` : K }[keyof T & string]
  : never;

// The type at the end of a dotted path: split off the first key, look it up, and continue with the rest
type PathValue<T, P extends string> = P extends `${infer K}.${infer Rest}`
  ? K extends keyof T
    ? PathValue<T[K], Rest>
    : never
  : P extends keyof T
    ? T[P]
    : never;

interface SceneSettings {
  camera: { position: { x: number; y: number; z: number }; fov: number };
  stars: boolean;
  tunings: { name: string; notes: string[] }[];
}
type _1 = Expect<Equal<PathValue<SceneSettings, 'camera.fov'>, number>>;
type _2 = Expect<Equal<PathValue<SceneSettings, 'camera.position'>, { x: number; y: number; z: number }>>;
type _3 = Expect<Equal<PathValue<SceneSettings, 'tunings'>, { name: string; notes: string[] }[]>>;

function getPath<T, P extends Paths<T>>(value: T, path: P): PathValue<T, P> {
  // An assertion: reduce walks the same keys as PathValue, which tsc can't relate to the string's contents
  return path.split('.').reduce<unknown>((current, key) => (current as Record<string, unknown>)[key], value) as PathValue<T, P>;
}

const settings: SceneSettings = { camera: { position: { x: 0, y: 2, z: 10 }, fov: 60 }, stars: true, tunings: [] };
const fov = getPath(settings, 'camera.fov'); // number
const z = getPath(settings, 'camera.position.z'); // number
console.log(fov.toFixed(1), z + 1, getPath(settings, 'stars'));
```

```text
60.0 11 true
```

`PathValue` splits the path at its first dot with `infer`, looks the first key up in `T`, and recurses on the rest; a key that isn't in `T` gives `never`. The call `fov.toFixed(1)` compiles only because the result is a `number`. The implementation keeps one assertion: `reduce` walks the same keys at run time, and `tsc` can't relate the pieces of a string known only at run time to the type computed from its literal.

</details>

2. `parseFingering` accepts any string. Make it accept only six-character fingerings made of digits and `x`, so that `parseFingering('x3201')` and `parseFingering('x3201y')` are compile errors.

<details>
<summary>Solution</summary>

[`solutions/l01_ex2_six_strings.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l01_ex2_six_strings.ts):

```ts
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
```

```text
[ null, 3, 2, 0, 1, 0 ] [ 0, 2, 2, 1, 0, 0 ]
function
```

`Valid<S>` is `S` when the fingering has six elements and none of them is `never`, and `never` otherwise. `HasNever` needs the tuple form of the lesson's `IsNever` for each element, since a distributive test would skip them. The parameter type `S & Valid<S>` is the usual way to validate a literal argument: `S` is inferred from the argument, and when `Valid<S>` is `never`, the intersection is `never`, which no string is assignable to. The `@ts-expect-error` lines are the type tests of the refusals.

</details>

3. GA's `BeliefState`, in `DataLoader.ts`, has snake_case properties such as `truth_value` and `last_updated`, next to camelCase types everywhere else. Write `CamelKeys<T>`, which renames every snake_case key, and a run-time `camelKeys(value)` typed with it.

<details>
<summary>Solution</summary>

[`solutions/l01_ex3_camel_keys.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l01_ex3_camel_keys.ts):

```ts
// solutions/l01_ex3_camel_keys.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

// GA's BeliefState, whose property names come in snake_case from the belief files
interface BeliefState {
  id: string;
  proposition: string;
  truth_value: 'T' | 'F' | 'U' | 'C';
  confidence: number;
  last_updated?: string;
  evaluated_by?: string;
}

type SnakeToCamel<S extends string> = S extends `${infer Head}_${infer Tail}` ? `${Head}${Capitalize<SnakeToCamel<Tail>>}` : S;
type CamelKeys<T> = { [K in keyof T as K extends string ? SnakeToCamel<K> : K]: T[K] };

type _1 = Expect<Equal<SnakeToCamel<'last_updated_by_agent'>, 'lastUpdatedByAgent'>>;
type _2 = Expect<Equal<CamelKeys<BeliefState>, { id: string; proposition: string; truthValue: 'T' | 'F' | 'U' | 'C'; confidence: number; lastUpdated?: string; evaluatedBy?: string }>>;

const snakeToCamel = <S extends string>(text: S) => text.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase()) as SnakeToCamel<S>;

function camelKeys<T extends object>(value: T): CamelKeys<T> {
  return Object.fromEntries(Object.entries(value).map(([key, v]) => [snakeToCamel(key), v])) as CamelKeys<T>;
}

const belief: BeliefState = { id: 'b-12', proposition: 'the voicing index is fresh', truth_value: 'U', confidence: 0.6, last_updated: '2026-09-15' };
const camel = camelKeys(belief);
console.log(camel.truthValue, camel.lastUpdated, Object.keys(camel));
```

```text
U 2026-09-15 [ 'id', 'proposition', 'truthValue', 'confidence', 'lastUpdated' ]
```

`SnakeToCamel` is recursive: it splits at the first underscore, and capitalizes the converted rest, so `last_updated_by_agent` becomes `lastUpdatedByAgent`. `CamelKeys` remaps the keys and, being homomorphic, keeps `lastUpdated` optional. The run-time conversion is a regex, and the type test on `SnakeToCamel` is what ties the two together: if one of them handled, say, digits differently, only a test with such a key would notice.

</details>

## Sources

- [TypeScript handbook — Creating types from types](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html), [Conditional types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html), [Mapped types](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html), [Template literal types](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html)
- Release notes: [4.1 — key remapping](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-1.html#key-remapping-in-mapped-types), [4.5 — tail recursion on conditional types](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-5.html#tail-recursion-elimination-on-conditional-types), [4.7 — `extends` constraints on `infer`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#extends-constraints-on-infer-type-variables), [4.8 — `infer` in template string types](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-8.html#improved-inference-for-infer-types-in-template-string-types)
- [microsoft/typescript-go, `internal/checker/checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go), tag `typescript/v7.0.2`
- [dotnet/aspnetcore — `HubConnection.ts`](https://github.com/dotnet/aspnetcore/blob/a5383385245bdacc20ec19f30e46090a8154d8da/src/SignalR/clients/ts/signalr/src/HubConnection.ts), tag `v10.0.11`; [ASP.NET Core — Strongly typed hubs](https://learn.microsoft.com/aspnet/core/signalr/hubs#strongly-typed-hubs)
- [Microsoft — Type inference in generic methods (CS0411)](https://learn.microsoft.com/dotnet/csharp/misc/cs0411), [Source generators](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview); [The Java Tutorials — Type inference](https://docs.oracle.com/javase/tutorial/java/generics/genTypeInference.html)
