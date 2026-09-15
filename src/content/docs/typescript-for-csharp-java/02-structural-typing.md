---
title: 2. Structural typing
description: Annotations and inference, structural against nominal typing, interface and type, excess property checks, readonly, tuples, any, unknown and never, and strictNullChecks — each compared with C# and Java, with tsc's real diagnostics.
sidebar:
  order: 2
---

Code: the files [`examples/l02_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/examples) and [`errors/l02_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors), and the C# and Java sides in [`compare/l02_nullable.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/l02_nullable.cs), [`compare/L02Nullable.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/L02Nullable.java), [`compare_fail/l02_nominal.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail/l02_nominal.cs) and [`compare_fail/L02Nominal.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail/L02Nominal.java).

The examples print their results with the `show` and `attempt` helpers of [JavaScript lesson 2](../../javascript-for-csharp-java/02-values-and-types/), now with types. `err` in a `catch` has the type `unknown`, because JavaScript can throw any value, and the helper checks that it is an `Error` before reading its `message`:

```ts
// examples/show.ts
import { inspect } from 'node:util';

export function show(label: string, value: unknown): void {
  console.log(`${label.padEnd(34)} ${inspect(value)}`);
}

export function attempt(label: string, fn: () => unknown): void {
  try {
    show(label, fn());
  } catch (err) {
    // err is unknown: anything can be thrown, not only an Error (lesson 3 narrows it)
    console.log(`${label.padEnd(34)} ${err instanceof Error ? `${err.name}: ${err.message}` : String(err)}`);
  }
}
```

## Annotations and inference

An annotation is a colon and a type after a name: `let count: number`. Most of the time you don't write one, because `tsc` infers the type from the value, as `var` does in C# and Java. The fastest way to see what `tsc` inferred, outside an editor, is to ask it for a declaration file: `tsc --declaration` writes the type of everything a module exports.

```ts
// examples/l02_inference.ts
// tsc --declaration writes the types it inferred into l02_inference.d.ts (see check.sh)
export let count = 1;
export const tuning = 'EADGBE';
export const strings = ['E', 'A', 'D', 'G', 'B', 'E'];
export const capo = { fret: 2, label: 'capo' };
export const frozen = Object.freeze({ fret: 2, label: 'capo' });
export const literal = { fret: 2, label: 'capo' } as const;
export const mixed = [1, 'two', null];
export const pair: [string, number] = ['capo', 2];
export function fretOf(label: string) {
  return label === 'capo' ? capo.fret : undefined;
}
export const parsed = JSON.parse('{"fret": 2}');
```

```ts
// out/dts/examples/l02_inference.d.ts, written by tsc --declaration --emitDeclarationOnly
export declare let count: number;
export declare const tuning = "EADGBE";
export declare const strings: string[];
export declare const capo: {
    fret: number;
    label: string;
};
export declare const frozen: Readonly<{
    fret: 2;
    label: "capo";
}>;
export declare const literal: {
    readonly fret: 2;
    readonly label: 'capo';
};
export declare const mixed: (string | number | null)[];
export declare const pair: [string, number];
export declare function fretOf(label: string): number | undefined;
export declare const parsed: any;
```

Some of it is what C# would infer, and some isn't:

- `count` is a `number`, but `tuning` has the type `"EADGBE"`: a **literal type**, whose only value is that string. A `const` can't change, so `tsc` keeps the narrowest type. A `let` gets the wider `number` or `string`, since it can be reassigned.
- The properties of `capo` are widened to `number` and `string`, because an object's properties can be reassigned even when the variable is `const`. `Object.freeze` and `as const` keep the literal types, and add `readonly`.
- `mixed` is an array of `string | number | null`: a **union** of the element types, where C# refuses `new[] { 1, "two", null }` for lack of a best common type (*to verify*). Unions are the subject of [lesson 3](../03-unions-and-narrowing/).
- `fretOf` has an inferred return type, `number | undefined`, since one branch returns `undefined`.
- `parsed` is `any`, because `JSON.parse` is declared to return `any`. The section on `any` below explains why that matters.

The usual style is to annotate what other code depends on, the parameters and return types of exported functions, and to let `tsc` infer local variables. Parameters must be annotated anyway: `tsc` doesn't infer a parameter's type from the calls.

| | C# | Java | TypeScript |
|---|---|---|---|
| Numbers | `int`, `long`, `double`, `decimal`… | `int`, `long`, `double`… | `number`, `bigint` |
| Text | `string`, `char` | `String`, `char` | `string`, no character type |
| Absent value | `null` | `null` | `null` and `undefined`, two types |
| Any value, checked before use | `object` | `Object` | `unknown` |
| Any value, no checks | `dynamic` | — | `any` |
| No value at all | `void` for a return type | `void` | `void` for a return type, `never` for a value that can't exist |
| One specific value | — | — | a literal type: `'EADGBE'`, `2`, `true` |

## Structural typing

C# and Java types are **nominal**: a class is compatible with an interface because it says so, `class Vector : IPoint`. TypeScript types are **structural**: a value is compatible with a type when it has the right properties with the right types, whatever its declaration says ([type compatibility](https://www.typescriptlang.org/docs/handbook/type-compatibility.html)).

```ts
// examples/l02_structural.ts
import { show } from './show.ts';

interface Point {
  x: number;
  y: number;
}

function length(p: Point): number {
  return Math.hypot(p.x, p.y);
}

// A class never mentions Point, and its instances are Points all the same: only the shape counts
class Vector {
  x: number;
  y: number;
  z = 0;
  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}
show('length(new Vector(3, 4))', length(new Vector(3, 4)));
show('length({ x: 3, y: 4 })', length({ x: 3, y: 4 }));

// interface and type describe the same shape: both names are interchangeable
type PointAlias = { x: number; y: number };
const alias: PointAlias = { x: 6, y: 8 };
const point: Point = alias;
show('length(point)', length(point));

// Two classes with the same shape are the same type, whatever their names say
class Celsius {
  constructor(value: number) {
    this.value = value;
  }
  value: number;
}
class Fahrenheit {
  constructor(value: number) {
    this.value = value;
  }
  value: number;
}
function boils(t: Celsius): boolean {
  return t.value >= 100;
}
show('boils(new Fahrenheit(150))', boils(new Fahrenheit(150)));
const water: Celsius = new Fahrenheit(212);
show('water instanceof Celsius', water instanceof Celsius);

// A branded type: a number that only a function can produce
type Kelvin = number & { readonly brand: 'Kelvin' };
function kelvin(value: number): Kelvin {
  if (value < 0) throw new RangeError('below absolute zero');
  return value as Kelvin; // the one place where the brand is asserted
}
const room = kelvin(293.15);
show('room', room);
show('room - 273.15', room - 273.15);
```

```text
length(new Vector(3, 4))           5
length({ x: 3, y: 4 })             5
length(point)                      10
boils(new Fahrenheit(150))         true
water instanceof Celsius           false
room                               293.15
room - 273.15                      20
```

`Vector` never mentions `Point`, and its instances are accepted where a `Point` is expected, with the extra property `z`. That is what makes TypeScript fit JavaScript, where most objects are literals without a class. The cost is the second half of the example: `Celsius` and `Fahrenheit` have the same shape, so they are the same type for `tsc`, and a temperature of 150 °F is said to boil. `instanceof` still tells them apart at run time, because the prototype chain is real, but the types don't. The same code in C# and Java:

```text
> dotnet run l02_nominal.cs
compare_fail/l02_nominal.cs(2,17): error CS0029: Cannot implicitly convert type 'Fahrenheit' to 'Celsius'

The build failed. Fix the build errors and run again.
```

```text
> javac L02Nominal.java
L02Nominal.java:7: error: incompatible types: Fahrenheit cannot be converted to Celsius
        Celsius water = new Fahrenheit(212);
                        ^
1 error
```

When a type needs a name, two techniques give it one. A **branded type** intersects a primitive with a property that no plain value has, `number & { readonly brand: 'Kelvin' }`, so that only a function that asserts the brand produces one; at run time, `room` is a plain number. And a **private field** `#value` makes a class nominal, because no other class can have that field:

```ts
// errors/l02_nominal.ts
// A #private field makes a class nominal: no other class, however similar, has that field
class Celsius {
  #value: number;
  constructor(value: number) {
    this.#value = value;
  }
  get value() {
    return this.#value;
  }
}
class Fahrenheit {
  #value: number;
  constructor(value: number) {
    this.#value = value;
  }
  get value() {
    return this.#value;
  }
}

type Kelvin = number & { readonly brand: 'Kelvin' };

const water: Celsius = new Fahrenheit(212);
const room: Kelvin = 293.15;
console.log(water.value, room);
```

```text
> npx tsc -p out/tsconfig.l02_nominal.json --pretty
errors/l02_nominal.ts:24:7 - error TS2322: Type 'Fahrenheit' is not assignable to type 'Celsius'.
  Property '#value' in type 'Fahrenheit' refers to a different member that cannot be accessed from within type 'Celsius'.

24 const water: Celsius = new Fahrenheit(212);
         ~~~~~

errors/l02_nominal.ts:25:7 - error TS2322: Type 'number' is not assignable to type 'Kelvin'.
  Type 'number' is not assignable to type '{ readonly brand: "Kelvin"; }'.

25 const room: Kelvin = 293.15;
         ~~~~


Found 2 errors in the same file, starting at: errors/l02_nominal.ts:24
```

TypeScript's own `private` keyword has the same effect on compatibility, checked by `tsc` only; `#value` is also enforced by the engine ([JavaScript lesson 4](../../javascript-for-csharp-java/04-objects-prototypes-classes/#classes)).

### interface or type

`interface Point { x: number; y: number }` and `type Point = { x: number; y: number }` describe the same shape, and the example assigns one to the other without a word. The differences are elsewhere ([everyday types](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#differences-between-type-aliases-and-interfaces)):

| | `interface` | `type` |
|---|---|---|
| Object shapes | yes | yes |
| Unions, tuples, primitives, mapped types | no | yes: `type Fret = number \| 'open'` |
| Extension | `interface Guitar extends Instrument` | an intersection: `type Guitar = Instrument & { strings: number }` |
| Two declarations with the same name | merged into one interface | an error |

Declaration merging is how libraries let you add a property to a global type, and is rarely what an application wants. A reasonable rule, and the one this course follows: `interface` for object shapes, `type` for everything else.

## Excess property checks

Structural typing accepts extra properties, with one exception:

```ts
// errors/l02_excess.ts
interface SceneOptions {
  stars?: boolean;
  tower?: boolean;
  skyboxMode?: string;
}

function describe(options: SceneOptions): string {
  return `stars ${options.stars ?? true}, tower ${options.tower ?? false}`;
}

// An object literal written where a SceneOptions is expected: an unknown property is an error
console.log(describe({ stars: false, towr: true }));

// The same object in a variable first: no excess property check, and the typo is silently ignored
const fromUrl = { stars: false, towr: true };
console.log(describe(fromUrl));
```

```text
> npx tsc -p out/tsconfig.l02_excess.json --pretty
errors/l02_excess.ts:13:38 - error TS2561: Object literal may only specify known properties, but 'towr' does not exist in type 'SceneOptions'. Did you mean to write 'tower'?

13 console.log(describe({ stars: false, towr: true }));
                                        ~~~~


Found 1 error in errors/l02_excess.ts:13
> node errors/l02_excess.ts
stars false, tower false
stars false, tower false
```

An object literal written directly where a type is expected is *fresh*, and `tsc` checks it for properties the type doesn't have, since nothing else can ever read them. The same object stored in a variable first is no longer fresh: it could be used elsewhere, where `towr` means something, so `tsc` accepts it, and the typo is lost without a message. With every property optional, as in an options object, that is the case where a typo costs the most. Pass options as literals, or annotate the variable, `const fromUrl: SceneOptions = { … }`, which makes the literal fresh again.

## readonly

```ts
// errors/l02_readonly.ts
interface Tuning {
  readonly name: string;
  readonly notes: readonly string[];
}

const standard: Tuning = { name: 'standard', notes: ['E', 'A', 'D', 'G', 'B', 'E'] };
standard.name = 'drop D';
standard.notes[0] = 'D';
standard.notes.push('A');
console.log(standard);
```

```text
> npx tsc -p out/tsconfig.l02_readonly.json --pretty
errors/l02_readonly.ts:8:10 - error TS2540: Cannot assign to 'name' because it is a read-only property.

8 standard.name = 'drop D';
           ~~~~

errors/l02_readonly.ts:9:1 - error TS2542: Index signature in type 'readonly string[]' only permits reading.

9 standard.notes[0] = 'D';
  ~~~~~~~~~~~~~~~~~

errors/l02_readonly.ts:10:16 - error TS2339: Property 'push' does not exist on type 'readonly string[]'.

10 standard.notes.push('A');
                  ~~~~


Found 3 errors in the same file, starting at: errors/l02_readonly.ts:8
> node errors/l02_readonly.ts
{
  name: 'drop D',
  notes: [
    'D', 'A', 'D',
    'G', 'B', 'E',
    'A'
  ]
}
```

`readonly` on a property, and `readonly string[]` for an array, remove the writes from the type, the way `IReadOnlyList<T>` does in C#: a `readonly string[]` has no `push`. And as with `IReadOnlyList<T>`, it is a view, not an immutable object:

```ts
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
```

```text
standard.name                      'drop D'
frozen.name = 'x', after a cast    TypeError: Cannot assign to read only property 'name' of object '#<Object>'
frozen.notes.length                7
modes.includes(mode)               true
```

- Nothing is frozen at run time: `readonly` disappears with the other types, and the `node` run above modified everything.
- A readonly type is assignable to the same type without `readonly`, so an alias can write what the original couldn't. `tsc` accepts `const writable: { name: string } = standard`, and `standard.name` changes.
- `Object.freeze` gives both halves: its return type is `Readonly<…>`, and the engine refuses the write, here through a type assertion that silences `tsc`. Both are shallow, as in JavaScript.
- `as const` makes a literal readonly all the way down, with literal types. `(typeof modes)[number]` turns the array's elements into a union type, `'ionian' | 'dorian' | 'phrygian'`, the replacement for an `enum` that the second exercise of [lesson 1](../01-compiler-and-tooling/) used.

## Tuples and indexes

```ts
// examples/l02_tuples.ts
import { show } from './show.ts';

// A tuple: a fixed length, and a type for each position
type Interval = [name: string, semitones: number];
const fifth: Interval = ['perfect fifth', 7];
const [name, semitones] = fifth;
show('name, semitones', [name, semitones]);

// An array: any length, one element type, and an index that tsc trusts
const strings: string[] = ['E', 'A', 'D', 'G', 'B', 'E'];
const seventh: string = strings[6]; // no error without noUncheckedIndexedAccess
show('seventh', seventh);
show('typeof seventh', typeof seventh);

const counts = new Map<string, number>([['E', 2]]);
const count = counts.get('A'); // Map.get admits it: number | undefined
show('count ?? 0', count ?? 0);

// Tuples are arrays at run time: nothing stops a push
fifth.push('extra');
show('fifth', fifth);
```

```text
name, semitones                    [ 'perfect fifth', 7 ]
seventh                            undefined
typeof seventh                     'undefined'
count ?? 0                         0
fifth                              [ 'perfect fifth', 7, 'extra' ]
```

A tuple type fixes the length and the type of each position, and its labels, `name` and `semitones`, are documentation. At run time it is an array, and `push` works: the type only protects the positions it declares.

`strings[6]` is typed `string`, and holds `undefined`. By default `tsc` trusts an index into an array or a dictionary, where C# would throw `IndexOutOfRangeException` for an array and `KeyNotFoundException` for a dictionary, and Java `ArrayIndexOutOfBoundsException`. `Map.get` is declared honestly, `number | undefined`, but an array index or a `Record` key isn't. The option [`noUncheckedIndexedAccess`](https://www.typescriptlang.org/tsconfig/#noUncheckedIndexedAccess) adds `undefined` to every index access. It is not part of `strict`, and `tsc --init` turns it on:

```ts
// errors/l02_index.ts
// tsc options: --noUncheckedIndexedAccess
const strings: string[] = ['E', 'A', 'D', 'G', 'B', 'E'];
const seventh: string = strings[6];
const record: Record<string, number> = { E: 2 };
const count: number = record['A'];
console.log(seventh.toLowerCase(), count + 1);
```

```text
> npx tsc -p out/tsconfig.l02_index.json --pretty
> npx tsc -p out/tsconfig.l02_index.json --pretty --noUncheckedIndexedAccess
errors/l02_index.ts:4:7 - error TS2322: Type 'string | undefined' is not assignable to type 'string'.
  Type 'undefined' is not assignable to type 'string'.

4 const seventh: string = strings[6];
        ~~~~~~~

errors/l02_index.ts:6:7 - error TS2322: Type 'number | undefined' is not assignable to type 'number'.
  Type 'undefined' is not assignable to type 'number'.

6 const count: number = record['A'];
        ~~~~~


Found 2 errors in the same file, starting at: errors/l02_index.ts:4
> node errors/l02_index.ts
errors/l02_index.ts:7
console.log(seventh.toLowerCase(), count + 1);
                    ^

TypeError: Cannot read properties of undefined (reading 'toLowerCase')

Node.js v24.21.0
```

Without the option, `tsc` prints nothing and the program fails on the first line that uses the missing element. With it, every index needs a check, which is noisy in loops over known indexes and right for lookups by key.

## any, unknown and never

```ts
// examples/l02_any_unknown.ts
import { attempt, show } from './show.ts';

const saved = '{"stars": "yes", "tower": true}';

// JSON.parse returns any: every use compiles, and any spreads to what it touches
const options = JSON.parse(saved);
const stars: boolean = options.stars; // no error: any is assignable to everything
show('stars', stars);
show('typeof stars', typeof stars);
attempt('options.weather.level', () => options.weather.level);

// unknown accepts any value too, but nothing can be done with it before a check
const checked: unknown = JSON.parse(saved);
if (typeof checked === 'object' && checked !== null && 'stars' in checked) {
  show("typeof checked.stars", typeof checked.stars);
}

// never: a function that doesn't return, and a value that can't exist
function fail(message: string): never {
  throw new Error(message);
}
function starsOf(value: unknown): boolean {
  return typeof value === 'boolean' ? value : fail(`not a boolean: ${JSON.stringify(value)}`);
}
attempt('starsOf(options.stars)', () => starsOf(options.stars));
```

```text
stars                              'yes'
typeof stars                       'string'
options.weather.level              TypeError: Cannot read properties of undefined (reading 'level')
typeof checked.stars               'string'
starsOf(options.stars)             Error: not a boolean: "yes"
```

**`any`** switches the checker off for a value. `options` is `any` because `JSON.parse` returns `any`, so `options.stars` is `any` too, and `any` is assignable to every type: `stars` is declared `boolean` and holds the string `'yes'`, and `options.weather.level` compiles and throws. `any` behaves like C#'s [`dynamic`](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interop/using-type-dynamic), with one difference: C# binds a `dynamic` operation when it runs and throws `RuntimeBinderException` for a member that doesn't exist, where JavaScript reads `undefined` and carries on. It spreads silently from the functions that return it, `JSON.parse`, `response.json()` and the untyped parts of libraries, to everything it touches.

**`unknown`** also accepts every value, and allows nothing until a check has *narrowed* it, like `object` in C#:

```ts
// errors/l02_unknown.ts
const options: unknown = JSON.parse('{"stars": "yes"}');
const stars: boolean = options.stars;
const copy: boolean = options;

console.log(stars, copy);
```

```text
> npx tsc -p out/tsconfig.l02_unknown.json --pretty
errors/l02_unknown.ts:3:24 - error TS18046: 'options' is of type 'unknown'.

3 const stars: boolean = options.stars;
                         ~~~~~~~

errors/l02_unknown.ts:4:7 - error TS2322: Type 'unknown' is not assignable to type 'boolean'.

4 const copy: boolean = options;
        ~~~~


Found 2 errors in the same file, starting at: errors/l02_unknown.ts:3
```

In the example, `typeof checked === 'object'`, `!== null` and `'stars' in checked` narrow `checked` step by step, until `checked.stars` compiles. [Lesson 3](../03-unions-and-narrowing/) is about those checks. Write `const value: unknown = JSON.parse(text)`: the annotation turns the `any` into an `unknown` on the spot, and `tsc` then asks for a check before each use.

**`never`** is the type with no values. A function that always throws returns `never`, like a C# method marked [`[DoesNotReturn]`](https://learn.microsoft.com/dotnet/api/system.diagnostics.codeanalysis.doesnotreturnattribute), and a `never` is assignable to every type, which is why `fail(…)` fits in the `boolean` branch of `starsOf`. Lesson 3 uses `never` to check that a `switch` handles every case.

## null and undefined

With `strictNullChecks`, part of `strict`, `null` and `undefined` are separate types, and `string` doesn't include them. A value that may be absent says so, `string | undefined`, or `name?: string` for an optional parameter or property:

```ts
// errors/l02_null.ts
function initial(name?: string): string {
  return name.charAt(0);
}

const tunings = new Map([['standard', 'EADGBE']]);
const dropD: string = tunings.get('drop D');

let capo: number = null;
console.log(initial(), dropD.length, capo);
```

```text
> npx tsc -p out/tsconfig.l02_null.json --pretty
errors/l02_null.ts:3:10 - error TS18048: 'name' is possibly 'undefined'.

3   return name.charAt(0);
           ~~~~

errors/l02_null.ts:7:7 - error TS2322: Type 'string | undefined' is not assignable to type 'string'.
  Type 'undefined' is not assignable to type 'string'.

7 const dropD: string = tunings.get('drop D');
        ~~~~~

errors/l02_null.ts:9:5 - error TS2322: Type 'null' is not assignable to type 'number'.

9 let capo: number = null;
      ~~~~


Found 3 errors in the same file, starting at: errors/l02_null.ts:3
> node errors/l02_null.ts
errors/l02_null.ts:3
  return name.charAt(0);
              ^

TypeError: Cannot read properties of undefined (reading 'charAt')

Node.js v24.21.0
```

The fix is the narrowing of lesson 3, or the operators that [JavaScript lesson 2](../../javascript-for-csharp-java/02-values-and-types/#undefined-and-null) introduced:

```ts
// examples/l02_null.ts
import { attempt, show } from './show.ts';

function initial(name?: string): string {
  return name === undefined ? '?' : name.charAt(0); // narrowed: name is a string in the second branch
}
show('initial()', initial());
show("initial('Ada')", initial('Ada'));

const tunings = new Map([['standard', 'EADGBE']]);
show("tunings.get('drop D')?.length", tunings.get('drop D')?.length);
show("tunings.get('drop D') ?? 'DADGBE'", tunings.get('drop D') ?? 'DADGBE');

// The non-null assertion ! silences tsc, and checks nothing
attempt("tunings.get('drop D')!.length", () => tunings.get('drop D')!.length);
```

```text
initial()                          '?'
initial('Ada')                     'A'
tunings.get('drop D')?.length      undefined
tunings.get('drop D') ?? 'DADGBE'  'DADGBE'
tunings.get('drop D')!.length      TypeError: Cannot read properties of undefined (reading 'length')
```

C#'s [nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references) are the same idea, with the same `!` operator, but they produce warnings:

```text
> dotnet run l02_nullable.cs
compare/l02_nullable.cs(4,33): warning CS8602: Dereference of a possibly null reference.
Initial(null): NullReferenceException
certain.Length: NullReferenceException
```

```text
> java L02Nullable.java
initial(dropD): NullPointerException
```

| | C# with `<Nullable>enable</Nullable>` | Java | TypeScript with `strictNullChecks` |
|---|---|---|---|
| A type that may be absent | `string?` | nothing in the type; annotations such as [JSpecify](https://jspecify.dev/)'s `@Nullable` | `string \| undefined`, `string \| null`, `name?: string` |
| Using it without a check | warning CS8602, the program builds | nothing, until `NullPointerException` | error TS18048, and the program still runs |
| "Trust me" | `name!` | — | `name!` |
| At run time | `NullReferenceException` | `NullPointerException` | `TypeError: Cannot read properties of undefined` |

In both C# and TypeScript, `!` only silences the compiler: `tunings.get('drop D')!.length` compiles and throws. Use it where you know something the checker can't, and prefer a check that says what should happen when you are wrong.

## The strict family

`strict` turns on eight options, listed in the compiler's source as the [`strictFlag` options](https://github.com/microsoft/TypeScript/blob/v6.0.3/src/compiler/commandLineParser.ts):

| Option | What it checks | Lesson |
|---|---|---|
| `strictNullChecks` | `null` and `undefined` are separate types | this one |
| `noImplicitAny` | a parameter or variable whose type can't be inferred must be annotated | this one |
| `useUnknownInCatchVariables` | the variable of a `catch` is `unknown`, not `any` | the `attempt` helper above |
| `strictFunctionTypes` | function types are checked contravariantly in their parameters | [4](../04-generics/) |
| `strictBindCallApply` | `bind`, `call` and `apply` check their arguments | — |
| `strictPropertyInitialization` | a class field must be initialized, in its declaration or the constructor | — |
| `strictBuiltinIteratorReturn` | the built-in iterators' `return` value is `undefined`, not `any` | — |
| `noImplicitThis` | `this` must have a known type in a function | — |

A project can set `"strict": true` and switch one of them back off, and that is where to look first in an existing `tsconfig.json`.

## In GuitarAlchemist/ga: noImplicitAny switched off

[`ga-react-components/tsconfig.app.json`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/tsconfig.app.json#L17-L20) sets `"noImplicitAny": false` three lines above `"strict": true`. The file is read as a whole, so the specific option wins over the family, and every parameter whose type can't be inferred silently becomes `any`. [`ga-client`'s](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/tsconfig.app.json#L17-L18) doesn't have the line.

I ran `tsc -p tsconfig.app.json --noImplicitAny true` on the component library, with TypeScript 5.9.3 and the dependencies resolved from its `package.json`: it adds 4 errors to those of lesson 1, two `TS7006`, `Parameter 'child' implicitly has an 'any' type` and the same for `obj`, in [`BSPDoomExplorer.tsx`, lines 4363 and 4367](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L4363-L4367), and two `TS7053` for indexing a `Record<HexavalentTruth, string>` with a plain `string` in [`IxqlFormPanel.tsx`, lines 83 and 112](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/IxqlFormPanel.tsx#L83). Switching the option back on costs four annotations; the `any` that the project doesn't see comes from elsewhere, from 42 calls to `JSON.parse` and from 18 `as any` in its sources, which lesson 3 looks at.

## Key takeaways

- `tsc` infers local types, including literal types for constants; annotate parameters and exported signatures. `tsc --declaration` shows what it inferred.
- Compatibility is structural: same shape, same type, whatever the names. Brands and `#private` fields give a type a name when it needs one.
- An object literal written where a type is expected is checked for extra properties; the same object passed through a variable isn't.
- `readonly` is a compile-time view: an alias without `readonly` can still write, and nothing is frozen.
- Array and `Record` indexes are trusted unless `noUncheckedIndexedAccess` is on.
- `any` disables checking and spreads; `unknown` requires a check; `never` has no values. `JSON.parse` returns `any`: store it in an `unknown`.
- `strictNullChecks` makes absence part of the type, as C#'s nullable reference types do, but as errors; `!` silences both compilers and checks nothing.

## Exercises

1. Write branded types `Celsius` and `Fahrenheit`, a function `toFahrenheit(t: Celsius): Fahrenheit`, and `boils(t: Celsius)`, and show three mistakes that `tsc` now rejects, in a file that `tsc` accepts.

<details>
<summary>Solution</summary>

[`solutions/l02_ex1_units.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l02_ex1_units.ts):

```ts
// solutions/l02_ex1_units.ts
type Celsius = number & { readonly unit: 'Celsius' };
type Fahrenheit = number & { readonly unit: 'Fahrenheit' };

function celsius(value: number): Celsius {
  return value as Celsius;
}
function fahrenheit(value: number): Fahrenheit {
  return value as Fahrenheit;
}
function toFahrenheit(t: Celsius): Fahrenheit {
  return fahrenheit((t * 9) / 5 + 32);
}
function boils(t: Celsius): boolean {
  return t >= 100;
}

const water = celsius(100);
const oven = fahrenheit(350);
console.log(toFahrenheit(water), boils(water));

// Never called: each line shows a mistake that tsc now rejects
function mistakes() {
  // @ts-expect-error: a Fahrenheit is not a Celsius
  boils(oven);
  // @ts-expect-error: a plain number is not a Celsius either
  boils(212);
  // @ts-expect-error: the result of arithmetic is a plain number again
  const warmer: Celsius = water + 1;
  return warmer;
}
console.log(typeof mistakes);
```

```text
212 true
function
```

A `// @ts-expect-error` comment tells `tsc` that the next line must be an error: the file compiles, and if a later change made one of those lines valid, `tsc` would report the directive as unused. It is the TypeScript way to test that code is *rejected*, where this course uses separate error snippets. The third mistake shows the limit of brands: arithmetic on a `Celsius` gives a plain `number`, so each operation that should keep the unit goes through a function.

</details>

2. Write `loadTunings(raw: string | null): Tuning[]` for tunings saved as JSON, which returns only the entries that have a string `name` and an array of string `notes`, and an empty array for anything else, invalid JSON included.

<details>
<summary>Solution</summary>

[`solutions/l02_ex2_load_tunings.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l02_ex2_load_tunings.ts):

```ts
// solutions/l02_ex2_load_tunings.ts
interface Tuning {
  name: string;
  notes: string[];
}

// JSON.parse into unknown: tsc lets nothing through until each property is checked
function loadTunings(raw: string | null): Tuning[] {
  if (raw === null) return [];
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    return [];
  }
  if (!Array.isArray(value)) return [];
  const tunings: Tuning[] = [];
  for (const item of value) {
    if (
      typeof item === 'object' &&
      item !== null &&
      typeof item.name === 'string' &&
      Array.isArray(item.notes) &&
      item.notes.every((note: unknown) => typeof note === 'string')
    ) {
      tunings.push({ name: item.name, notes: item.notes });
    }
  }
  return tunings;
}

console.log(loadTunings(null));
console.log(loadTunings('{not json'));
console.log(loadTunings('{"name": "standard"}'));
console.log(loadTunings('[{"name": "drop D", "notes": ["D","A","D","G","B","E"]}, {"name": 7}, {"name": "open", "notes": [1]}]'));
```

```text
[]
[]
[]
[ { name: 'drop D', notes: [ 'D', 'A', 'D', 'G', 'B', 'E' ] } ]
```

The result of `JSON.parse` goes into an `unknown`, and the function returns new objects built from checked properties only, so an extra property in the saved data doesn't reach the program. Look at `item.name`, though: it compiled without an `'name' in item` check, because `Array.isArray` narrows an `unknown` to `any[]`, and each `item` is `any` again. `any` comes back through the declarations of the standard library; the `typeof` checks are what make this function correct, not `tsc`.

</details>

3. For each numbered line of [`solutions/l02_ex3_predict.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l02_ex3_predict.ts), predict whether `tsc` accepts it, then remove the `@ts-expect-error` comments and run `tsc` to check.

```ts
interface Point { x: number; y: number }
interface ReadonlyPoint { readonly x: number; readonly y: number }

const p3 = { x: 1, y: 2, z: 3 };
const a: Point = p3; // 1
const b: Point = { x: 1, y: 2, z: 3 }; // 2
const c: ReadonlyPoint = a; // 3
const d: Point = c; // 4
const e: [number, number] = [1, 2, 3]; // 5
const f: number[] = [1, 2] as [number, number]; // 6
const g: string = JSON.parse('"x"') as unknown; // 7
const h: string = JSON.parse('1'); // 8
const i: number = null; // 9
```

<details>
<summary>Solution</summary>

```ts
// solutions/l02_ex3_predict.ts
// Every line that tsc rejects carries @ts-expect-error: if one of them compiled, tsc would report an unused directive
interface Point {
  x: number;
  y: number;
}
interface ReadonlyPoint {
  readonly x: number;
  readonly y: number;
}

const p3 = { x: 1, y: 2, z: 3 };
const a: Point = p3; // 1. accepted: not a fresh literal, and z is extra
// @ts-expect-error 2. rejected: excess property z in a fresh object literal
const b: Point = { x: 1, y: 2, z: 3 };
const c: ReadonlyPoint = a; // 3. accepted: readonly only restricts what c can do
const d: Point = c; // 4. accepted: readonly doesn't affect assignability
// @ts-expect-error 5. rejected: [number, number] has no third element
const e: [number, number] = [1, 2, 3];
const f: number[] = [1, 2] as [number, number]; // 6. accepted: a tuple is an array
// @ts-expect-error 7. rejected: unknown must be narrowed before it is assigned to a string
const g: string = JSON.parse('"x"') as unknown;
const h: string = JSON.parse('1'); // 8. accepted: any is assignable to string, and h holds 1
// @ts-expect-error 9. rejected: null isn't a number under strictNullChecks
const i: number = null;

console.log([a, b, c, d, e, f, g, typeof h, i].length);
```

```text
9
```

Lines 2, 5, 7 and 9 are rejected: a fresh literal with an extra property, a tuple of the wrong length, an `unknown` used as a `string`, and `null` under `strictNullChecks`. Lines 1, 3, 4, 6 and 8 are accepted, and two of them deserve a second look: line 4 drops `readonly` through an alias, and line 8 stores the number `1` in a `string`, because `JSON.parse` returns `any`.

</details>

## Sources

- [TypeScript handbook — Everyday types](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html), [Object types](https://www.typescriptlang.org/docs/handbook/2/objects.html), [Type compatibility](https://www.typescriptlang.org/docs/handbook/type-compatibility.html), [Type inference](https://www.typescriptlang.org/docs/handbook/type-inference.html)
- [TSConfig reference — strict](https://www.typescriptlang.org/tsconfig/#strict), [strictNullChecks](https://www.typescriptlang.org/tsconfig/#strictNullChecks), [noImplicitAny](https://www.typescriptlang.org/tsconfig/#noImplicitAny), [noUncheckedIndexedAccess](https://www.typescriptlang.org/tsconfig/#noUncheckedIndexedAccess)
- [Microsoft — Nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references), [Using type dynamic](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interop/using-type-dynamic)
