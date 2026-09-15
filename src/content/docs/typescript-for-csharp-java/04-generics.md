---
title: 4. Generics
description: Type parameters, inference and constraints, generics erased at run time against C#'s reified generics and Java's erasure, variance with method bivariance, strictFunctionTypes and in/out annotations, then keyof, indexed access and a first mapped type.
sidebar:
  order: 4
---

Code: the files [`examples/l04_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/examples) and [`errors/l04_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors), and the C# and Java sides in [`compare/`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare) (`l04_generics.cs`, `l04_variance.cs`, `L04Erasure.java`, `L04Variance.java`) and [`compare_fail/`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail) (`l04_invariant_list.cs`, `l04_variance_annotation.cs`, `L04NewT.java`, `L04Wildcards.java`).

The syntax of generics is the one you know, `function first<T>(items: T[]): T`, and so is the purpose. The differences are in three places, which this lesson takes in order: what exists at run time, how `tsc` decides that one generic type is assignable to another, and what a type parameter can range over, since in TypeScript it can be the property names of another type.

## Type parameters, inference and constraints

```ts
// examples/l04_generics.ts
import { show } from './show.ts';

// A type parameter, inferred from the argument
function first<T>(items: readonly T[]): T | undefined {
  return items[0];
}
const note = first(['E', 'A', 'D']); // T is string
const fret = first([0, 2, 2]); // T is number
show('note, fret', [note, fret]);
show('first<string>([])', first<string>([])); // an explicit type argument

// A constraint: T must have a length, and keeps its own type
function longest<T extends { length: number }>(a: T, b: T): T {
  return b.length > a.length ? b : a;
}
show("longest('capo', 'strings')", longest('capo', 'strings'));
show('longest([1, 2], [1, 2, 3])', longest([1, 2], [1, 2, 3]));

// keyof and indexed access: the key is checked, and the result has the type of that property
interface Tuning {
  name: string;
  notes: string[];
  capo: number;
}
function get<T, K extends keyof T>(value: T, key: K): T[K] {
  return value[key];
}
const standard: Tuning = { name: 'standard', notes: ['E', 'A', 'D', 'G', 'B', 'E'], capo: 0 };
const notes = get(standard, 'notes'); // string[]
const capo = get(standard, 'capo'); // number
show("get(standard, 'notes').join('')", notes.join(''));
show("get(standard, 'capo') + 2", capo + 2);

// A generic type, with a default
interface Page<T, Cursor = number> {
  items: T[];
  next?: Cursor;
}
const page: Page<Tuning> = { items: [standard], next: 2 };
const byName: Page<string, string> = { items: ['drop D'], next: 'open G' };
show('page.items.length, byName.next', [page.items.length, byName.next]);
```

```text
note, fret                         [ 'E', 0 ]
first<string>([])                  undefined
longest('capo', 'strings')         'strings'
longest([1, 2], [1, 2, 3])         [ 1, 2, 3 ]
get(standard, 'notes').join('')    'EADGBE'
get(standard, 'capo') + 2          2
page.items.length, byName.next     [ 1, 'open G' ]
```

- `tsc` infers `T` from the arguments, as C# and Java infer a method's type arguments, and an explicit `first<string>([])` is there when nothing can be inferred.
- A **constraint**, `T extends { length: number }`, is written with `extends`, like Java's bounds, and can be any type, including a shape: strings and arrays both have a `length`, and `longest` returns the type it was given, `string` or `number[]`, not `{ length: number }`. In C#, the same function needs an interface that both types implement ([constraints on type parameters](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters)).
- **`keyof T`** is the union of `T`'s property names, and **`T[K]`** the type of the property `K`. `get(standard, 'notes')` returns a `string[]` and `get(standard, 'capo')` a `number`, from the same function: the return type depends on the value of an argument, which C# and Java generics can't express.
- A type parameter can have a default, `Cursor = number`, like a C# optional parameter but for types.

The constraints are checked at the call:

```ts
// errors/l04_constraints.ts
function longest<T extends { length: number }>(a: T, b: T): T {
  return b.length > a.length ? b : a;
}
interface Tuning {
  name: string;
  capo: number;
}
function get<T, K extends keyof T>(value: T, key: K): T[K] {
  return value[key];
}

const standard: Tuning = { name: 'standard', capo: 0 };
console.log(longest(10, 20), longest('capo', [1, 2]));
console.log(get(standard, 'nmae'));
```

```text
> npx tsc -p out/tsconfig.l04_constraints.json --pretty
errors/l04_constraints.ts:14:21 - error TS2345: Argument of type 'number' is not assignable to parameter of type '{ length: number; }'.

14 console.log(longest(10, 20), longest('capo', [1, 2]));
                       ~~

errors/l04_constraints.ts:14:46 - error TS2345: Argument of type 'number[]' is not assignable to parameter of type '"capo"'.

14 console.log(longest(10, 20), longest('capo', [1, 2]));
                                                ~~~~~~

errors/l04_constraints.ts:15:27 - error TS2345: Argument of type '"nmae"' is not assignable to parameter of type 'keyof Tuning'.

15 console.log(get(standard, 'nmae'));
                             ~~~~~~


Found 3 errors in the same file, starting at: errors/l04_constraints.ts:14
> node errors/l04_constraints.ts
10 capo
undefined
```

The second message shows how inference works: `tsc` took `T` from the first argument, the literal type `"capo"`, and then reported the second argument against it, instead of looking for a type that fits both. The third turns a typo into a compile error, which a `string` key would not. Without `tsc`, `longest(10, 20)` returns `10`, because `(20).length` is `undefined` and `undefined > undefined` is `false`, and `get` reads a property that doesn't exist.

## No T at run time

C# generics are **reified**: the runtime creates a `List<int>` distinct from a `List<string>`, and `typeof(T)`, `new T()` and `is T` work. Java generics are **erased** to their bound, and `javac` inserts casts where a value comes out. TypeScript goes one step further: the whole type is removed, and there is nothing left to cast to.

```text
> dotnet run l04_generics.cs
440
Int32, default 0
False
True
```

```text
> java L04Erasure.java
true
counts: [twelve]
counts.get(0): ClassCastException
```

The C# program creates a `Tuner` with `new T()`, prints `Int32` for `typeof(T)`, and tells the two list types apart. Java's `ArrayList<Integer>` and `ArrayList<String>` are the same class, and the string `"twelve"` sits in a `List<Integer>` until the cast that `javac` inserted at `counts.get(0)` fails. In TypeScript, the same code doesn't compile, and wouldn't run if it did:

```ts
// errors/l04_erasure.ts
function create<T>(): T {
  return new T();
}
function isOf<T>(value: unknown): value is T {
  return value instanceof T;
}

console.log(create<Date>(), isOf<Date>(new Date()));
```

```text
> npx tsc -p out/tsconfig.l04_erasure.json --pretty
errors/l04_erasure.ts:3:14 - error TS2693: 'T' only refers to a type, but is being used as a value here.

3   return new T();
               ~

errors/l04_erasure.ts:6:27 - error TS2693: 'T' only refers to a type, but is being used as a value here.

6   return value instanceof T;
                            ~


Found 2 errors in the same file, starting at: errors/l04_erasure.ts:3
> node errors/l04_erasure.ts
errors/l04_erasure.ts:3
  return new T();
  ^

ReferenceError: T is not defined

Node.js v24.21.0
```

```text
> javac L04NewT.java
L04NewT.java:4: error: unexpected type
        return new T();
                   ^
  required: class
  found:    type parameter T
  where T is a type-variable:
    T extends Object declared in method <T>create()
L04NewT.java:8: error: Object cannot be safely cast to T
        return value instanceof T;
               ^
  where T is a type-variable:
    T extends Object declared in method <T>isOf(Object)
2 errors
```

Java refuses `new T()` too, and allows `instanceof T` only where the cast can be checked. What replaces them, in both languages, is to pass a value that exists at run time:

```ts
// examples/l04_erasure.ts
import { attempt, show } from './show.ts';

// T appears only in the return type: the caller chooses it, and nothing checks it
function parse<T>(json: string): T {
  return JSON.parse(json);
}
const count = parse<number>('"twelve"');
show('typeof count', typeof count);
attempt('count.toFixed(1)', () => count.toFixed(1));

// There is no T at run time: pass what the function needs as a value, here a constructor
class Tuner {
  reference = 440;
}
function create<T>(ctor: new () => T): T {
  return new ctor();
}
show('create(Tuner)', create(Tuner));

// Or a type guard, which carries the check to run time
function parseArray<T>(json: string, isItem: (value: unknown) => value is T): T[] {
  const value: unknown = JSON.parse(json);
  if (!Array.isArray(value) || !value.every(isItem)) throw new TypeError(`not the expected array: ${json}`);
  return value;
}
const isNumber = (value: unknown): value is number => typeof value === 'number';
show("parseArray('[0, 2, 2]', isNumber)", parseArray('[0, 2, 2]', isNumber));
attempt("parseArray('[0, \"2\"]', isNumber)", () => parseArray('[0, "2"]', isNumber));

// GA's musicService.ts, lines 17-23: a generic guard checks the shape, never the T
interface ApiResponse<T> {
  success: boolean;
  data: T;
}
const isApiResponse = <T>(value: unknown): value is ApiResponse<T> =>
  typeof value === 'object' && value !== null && 'success' in value && 'data' in value;
const json: unknown = JSON.parse('{"success": true, "data": "C major"}');
if (isApiResponse<string[]>(json)) {
  attempt('json.data.map((n) => n.length)', () => json.data.map((n) => n.length));
}
```

```text
typeof count                       'string'
count.toFixed(1)                   TypeError: count.toFixed is not a function
create(Tuner)                      Tuner { reference: 440 }
parseArray('[0, 2, 2]', isNumber)  [ 0, 2, 2 ]
parseArray('[0, "2"]', isNumber)   TypeError: not the expected array: [0, "2"]
json.data.map((n) => n.length)     TypeError: json.data.map is not a function
```

- **`parse<T>`** is the most dangerous signature in TypeScript: `T` appears only in the return type, so the caller picks it and nothing can check it. `parse<number>('"twelve"')` returns a string typed `number`. It compiles without an `as` because `JSON.parse` returns `any`, and it is an assertion all the same, hidden in a generic.
- **`create(ctor: new () => T)`** takes the constructor, a value, where C# would use `where T : new()`; `T` is inferred from it.
- **`parseArray(json, isItem)`** takes a type guard for the elements. The check runs, and a `"2"` among the numbers is rejected at the border, the pattern of [lesson 3](../03-unions-and-narrowing/#type-predicates-and-assertion-functions) made generic.

### In GuitarAlchemist/ga: a generic guard that doesn't check its T

The last part of the example comes from [`Apps/ga-client/src/services/musicService.ts`, lines 17-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/musicService.ts#L17-L49), which every call to the music theory API goes through:

```ts
const isApiResponse = <T>(value: unknown): value is ApiResponse<T> => {
  if (!value || typeof value !== 'object') {
    return false;
  }

  return 'success' in value && 'data' in value;
};

const parseJson = async <T>(response: Response): Promise<T> => {
  // […] an error for a status other than 2xx
  const json = await response.json();
  if (isApiResponse<T>(json)) {
    // […] an error when success is false or data is null
    return json.data;
  }

  return json as T;
};
```

`isApiResponse<T>` promises an `ApiResponse<T>` and checks two property names: `T` is the caller's choice, as in `parse<T>`. When the check fails, `json as T` returns the body anyway, whatever it is. `fetchKeyNotes` then returns a `Promise<KeyNotes>` that holds what the server sent, and a change in the API's shape shows up as a `TypeError` in a component, like the one the example printed for `json.data.map`, far from this function. That's a common pattern, and a reasonable one when the server and its client are built together; the second exercise writes the version that checks. The same repository's [`CourseViewer.tsx`, line 152](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/CourseViewer.tsx#L152-L159), has `function loadQueue<T>(key: string): T[]`, which returns `JSON.parse(raw)` from `localStorage` without even an `as`, since the `any` of [lesson 2](../02-structural-typing/#any-unknown-and-never) converts to `T[]` silently.

## Variance

Variance answers one question: if a `Guitar` is an `Instrument`, is a list of guitars a list of instruments? A function that takes guitars, a function that takes instruments?

```ts
// examples/l04_variance.ts
import { attempt, show } from './show.ts';

interface Instrument {
  name: string;
}
interface Guitar extends Instrument {
  strings: number;
  tune(): string;
}
const guitar: Guitar = { name: 'guitar', strings: 6, tune: () => 'EADGBE' };
const piano: Instrument = { name: 'piano' };

// Arrays are covariant: a Guitar[] is accepted as an Instrument[], and the alias can add a piano
const guitars: Guitar[] = [guitar];
const instruments: Instrument[] = guitars;
instruments.push(piano);
show('guitars.length', guitars.length);
attempt('guitars[1].tune()', () => guitars[1].tune());

// A function property is checked contravariantly (strictFunctionTypes); a method is not
interface WithProperty {
  play: (instrument: Instrument) => string;
}
interface WithMethod {
  play(instrument: Instrument): string;
}
const tuneGuitar = (g: Guitar) => g.tune();
const withMethod: WithMethod = { play: tuneGuitar }; // accepted: method parameters are bivariant
attempt('withMethod.play(piano)', () => withMethod.play(piano));
const withProperty: WithProperty = { play: (i: Instrument) => i.name }; // a function of Instrument is fine
show('withProperty.play(piano)', withProperty.play(piano));

// Variance annotations: out for a type that only produces T, in for one that only consumes it
interface Source<out T> {
  next(): T;
}
interface Sink<in T> {
  accept(value: T): void;
}
const guitarSource: Source<Guitar> = { next: () => guitar };
const instrumentSource: Source<Instrument> = guitarSource; // out: Source<Guitar> is a Source<Instrument>
const names: string[] = [];
const instrumentSink: Sink<Instrument> = { accept: (i) => names.push(i.name) };
const guitarSink: Sink<Guitar> = instrumentSink; // in: Sink<Instrument> is a Sink<Guitar>
guitarSink.accept(guitar);
instrumentSink.accept(piano);
show('instrumentSource.next().name', instrumentSource.next().name);
show('names', names);
```

```text
guitars.length                     2
guitars[1].tune()                  TypeError: guitars[1].tune is not a function
withMethod.play(piano)             TypeError: g.tune is not a function
withProperty.play(piano)           'piano'
instrumentSource.next().name       'guitar'
names                              [ 'guitar', 'piano' ]
```

**Arrays are covariant, and unchecked.** `tsc` accepts a `Guitar[]` as an `Instrument[]`, as C# and Java accept arrays, and the alias pushes a piano into the guitars. C# and Java check each write into an array at run time; JavaScript has no element type to check, so the piano gets in, and the error comes later, from the code that trusted `guitars[1]`:

```text
> dotnet run l04_variance.cs
instruments[0] = piano: ArrayTypeMismatchException
playing guitar
sequence: Guitar { Name = guitar }
```

```text
> java L04Variance.java
objects[0] = 440: ArrayStoreException
producer.get(0): E
```

C# generic classes such as `List<T>` are invariant, and Java's are too, where TypeScript would compare `List<Guitar>` and `List<Instrument>` member by member:

```text
> dotnet run l04_invariant_list.cs
compare_fail/l04_invariant_list.cs(4,32): error CS0029: Cannot implicitly convert type 'System.Collections.Generic.List<Guitar>' to 'System.Collections.Generic.List<Instrument>'

The build failed. Fix the build errors and run again.
```

```text
> javac L04Wildcards.java
L04Wildcards.java:7: error: incompatible types: ArrayList<String> cannot be converted to List<Object>
        List<Object> objects = new ArrayList<String>();
                               ^
1 error
```

**Function parameters: properties are checked, methods are not.** A function that needs a `Guitar` can't safely stand in for one that accepts any `Instrument`: parameters must be contravariant. With [`strictFunctionTypes`](https://www.typescriptlang.org/tsconfig/#strictFunctionTypes), part of `strict`, `tsc` checks that for properties whose type is a function, `play: (instrument: Instrument) => string`. It doesn't for methods, `play(instrument: Instrument): string`, whose parameters stay **bivariant**: `withMethod` accepts `tuneGuitar`, and calling it with a piano throws. The exception is deliberate: in the words of the [TypeScript 2.6 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-6.html), methods are excluded "to ensure generic classes and interfaces (such as `Array<T>`) continue to mostly relate covariantly", which `push(item: T)` would otherwise prevent. Write callback types as properties when you want them checked.

**Variance annotations.** C# declares variance on interfaces and delegates, `IEnumerable<out T>`, `Action<in T>`, and checks it ([covariance and contravariance](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)). Java declares it where a type is used, `List<? extends Object>` ([wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html)). TypeScript computes it from the structure, and since [4.7](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters) accepts optional `out` and `in` annotations, as in C#:

```ts
// errors/l04_variance.ts
interface Instrument {
  name: string;
}
interface Guitar extends Instrument {
  strings: number;
  tune(): string;
}

interface WithProperty {
  play: (instrument: Instrument) => string;
}
const tuneGuitar = (g: Guitar) => g.tune();
const withProperty: WithProperty = { play: tuneGuitar };

interface Source<out T> {
  next(): T;
}
interface Sink<in T> {
  accept(value: T): void;
}
declare const instrumentSource: Source<Instrument>;
declare const guitarSink: Sink<Guitar>;
const guitarSource: Source<Guitar> = instrumentSource;
const instrumentSink: Sink<Instrument> = guitarSink;

// in promises that T is only consumed, and next returns it
interface Mislabeled<in T> {
  next(): T;
}

console.log(withProperty, guitarSource, instrumentSink);
```

```text
> npx tsc -p out/tsconfig.l04_variance.json --pretty
errors/l04_variance.ts:14:38 - error TS2322: Type '(g: Guitar) => string' is not assignable to type '(instrument: Instrument) => string'.
  Types of parameters 'g' and 'instrument' are incompatible.
    Type 'Instrument' is missing the following properties from type 'Guitar': strings, tune

14 const withProperty: WithProperty = { play: tuneGuitar };
                                        ~~~~

  errors/l04_variance.ts:11:3 - The expected type comes from property 'play' which is declared here on type 'WithProperty'
    11   play: (instrument: Instrument) => string;
         ~~~~

errors/l04_variance.ts:24:7 - error TS2322: Type 'Source<Instrument>' is not assignable to type 'Source<Guitar>'.
  Type 'Instrument' is missing the following properties from type 'Guitar': strings, tune

24 const guitarSource: Source<Guitar> = instrumentSource;
         ~~~~~~~~~~~~

errors/l04_variance.ts:25:7 - error TS2322: Type 'Sink<Guitar>' is not assignable to type 'Sink<Instrument>'.
  Type 'Instrument' is missing the following properties from type 'Guitar': strings, tune

25 const instrumentSink: Sink<Instrument> = guitarSink;
         ~~~~~~~~~~~~~~

errors/l04_variance.ts:28:22 - error TS2636: Type 'Mislabeled<super-T>' is not assignable to type 'Mislabeled<sub-T>' as implied by variance annotation.
  The types returned by 'next()' are incompatible between these types.
    Type 'super-T' is not assignable to type 'sub-T'.

28 interface Mislabeled<in T> {
                        ~~~~


Found 4 errors in the same file, starting at: errors/l04_variance.ts:14
```

The first error is `strictFunctionTypes` on a property. The next two are the annotations at work: a source of instruments isn't a source of guitars, and a sink of guitars can't accept any instrument. The last one catches an annotation that contradicts the structure: `in T` on an interface that returns `T`. The same mistake in C#:

```text
> dotnet run l04_variance_annotation.cs
compare_fail/l04_variance_annotation.cs(6,17): error CS1961: Invalid variance: The type parameter 'T' must be contravariantly valid on 'IMislabeled<T>.Accept(T)'. 'T' is covariant.

The build failed. Fix the build errors and run again.
```

The C# check is complete, and TypeScript's isn't. The opposite mistake, `interface Mislabeled<out T> { accept(value: T): void }`, compiles with `tsc` 7.0.2 without a message, because `accept` is a method and its parameter is bivariant, so `T` in that position is compatible with both annotations. The [handbook](https://www.typescriptlang.org/docs/handbook/2/generics.html#variance-annotations) is blunt about them: annotations don't change how types are compared structurally, should be written only when they match the structure, and are useful mainly while debugging a type or, after profiling, to speed up the check of extraordinarily complex types.

The `node` run of that snippet shows type stripping at work. `declare const instrumentSource` exists only for `tsc` and was removed, so line 24 throws a `ReferenceError`, and the line that Node.js prints has spaces where the type annotation was: types are replaced with whitespace so that line and column numbers stay those of the source ([lesson 1](../01-compiler-and-tooling/)).

```text
> node errors/l04_variance.ts
errors/l04_variance.ts:24
const guitarSource                 = instrumentSource;
                                     ^

ReferenceError: instrumentSource is not defined

Node.js v24.21.0
```

| | C# | Java | TypeScript |
|---|---|---|---|
| Generic types at run time | reified: `typeof(T)`, `new T()`, `is T` | erased to the bound, casts inserted by `javac` | erased completely |
| Constraints | `where T : IComparable<T>, new()` | `<T extends Comparable<T>>` | `<T extends Shape>`, any type, shapes included |
| Arrays | covariant, writes checked (`ArrayTypeMismatchException`) | covariant, writes checked (`ArrayStoreException`) | covariant, not checked |
| Generic classes | invariant, variance on interfaces and delegates | invariant, variance at the use site with `?` | structural: computed from the members |
| Function parameters | contravariant | — | contravariant for function-type properties, bivariant for methods |
| Annotations | `out T`, `in T`, fully checked | `? extends T`, `? super T` | `out T`, `in T`, optional, partly checked |

## keyof, indexed access and mapped types

TypeScript types can be computed from other types. [`keyof`](https://www.typescriptlang.org/docs/handbook/2/keyof-types.html) and [indexed access](https://www.typescriptlang.org/docs/handbook/2/indexed-access-types.html) appeared in `get<T, K extends keyof T>`; a [**mapped type**](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html) goes through the keys of a type and builds a property for each, `{ [K in keyof T]: … }`.

[JavaScript lesson 4](../../javascript-for-csharp-java/04-objects-prototypes-classes/#in-guitaralchemistga-merging-saved-preferences) looked at GA's scene options, merged from defaults, a URL and `localStorage` with `Object.assign`, which let unknown keys and wrong types through. The typed version needs one validator per option, and a mapped type derives the type of that table from `SceneOptions`:

```ts
// examples/l04_mapped.ts
import { show } from './show.ts';

interface SceneOptions {
  stars: boolean;
  tower: boolean;
  skyboxMode: 'milky-way' | 'nebula';
}

// keyof lists the property names as a union; T[K] is the type of one property
type OptionName = keyof SceneOptions; // 'stars' | 'tower' | 'skyboxMode'
type Skybox = SceneOptions['skyboxMode']; // 'milky-way' | 'nebula'
const name: OptionName = 'skyboxMode';
const skybox: Skybox = 'nebula';
show('name, skybox', [name, skybox]);

// A mapped type builds one property for each key of another type
type Validators<T> = {
  [K in keyof T]: (value: unknown) => value is T[K];
};

const isBoolean = (value: unknown): value is boolean => typeof value === 'boolean';
const sceneValidators: Validators<SceneOptions> = {
  stars: isBoolean,
  tower: isBoolean,
  skyboxMode: (value): value is Skybox => value === 'milky-way' || value === 'nebula',
};

// One generic merge for every options type: known keys only, valid values only, and the URL last
function merge<T extends object>(defaults: T, saved: unknown, validators: Validators<T>): T {
  const result = { ...defaults };
  if (typeof saved !== 'object' || saved === null) return result;
  for (const key of Object.keys(validators) as (keyof T)[]) {
    const value: unknown = (saved as Record<PropertyKey, unknown>)[key];
    if (Object.hasOwn(saved, key) && validators[key](value)) result[key] = value;
  }
  return result;
}

const defaults: SceneOptions = { stars: true, tower: false, skyboxMode: 'milky-way' };
const saved: unknown = JSON.parse('{"stars":"yes","tower":true,"bloom":3,"skyboxMode":"nebula","__proto__":{"isAdmin":true}}');
const state = merge(defaults, saved, sceneValidators);
if (new URLSearchParams('?tower=0').has('tower')) state.tower = false;
show('state', state);
show("'isAdmin' in state", 'isAdmin' in state);

// The library's mapped types: Partial, Readonly, Pick and Record
const patch: Partial<SceneOptions> = { tower: true };
const frozen: Readonly<SceneOptions> = Object.freeze({ ...defaults, ...patch });
const toggles: Pick<SceneOptions, 'stars' | 'tower'> = frozen;
const labels: Record<Skybox, string> = { 'milky-way': 'Milky Way', nebula: 'Nebula' };
show('toggles, labels[frozen.skyboxMode]', [toggles, labels[frozen.skyboxMode]]);
```

```text
name, skybox                       [ 'skyboxMode', 'nebula' ]
state                              { stars: true, tower: false, skyboxMode: 'nebula' }
'isAdmin' in state                 false
toggles, labels[frozen.skyboxMode] [ { stars: true, tower: true, skyboxMode: 'milky-way' }, 'Milky Way' ]
```

- `Validators<SceneOptions>` is `{ stars: (value: unknown) => value is boolean; tower: …; skyboxMode: (value: unknown) => value is 'milky-way' | 'nebula' }`, written once for every options type.
- `merge` is generic over `T`, and `validators[key](value)` narrows `value` to `T[keyof T]`, so `result[key] = value` compiles. The `"stars": "yes"` fails its validator, the unknown `bloom` is never read, and the `__proto__` key of the JSON, which `JSON.parse` creates as an ordinary property, isn't in the validators either: `isAdmin` doesn't reach the result.
- Two assertions remain, and each says why. `Object.keys` returns `string[]`, not `(keyof T)[]`, because structural typing lets an object have more keys than its type lists; here the object is the validators table, whose keys are exactly those of `T`. And `saved` is only known to be an `object`, which has no index signature, so it is read as a `Record<PropertyKey, unknown>`, whose values are still `unknown`.
- `Partial`, `Readonly`, `Pick` and `Record` are mapped types from the standard library ([utility types](https://www.typescriptlang.org/docs/handbook/utility-types.html)); `lib.es5.d.ts` defines `Partial<T>` as `{ [P in keyof T]?: T[P] }`. The last line of the output shows that `Readonly` and `Pick` are views, as in [lesson 2](../02-structural-typing/#readonly): `toggles` is typed with two properties and holds three.

The type follows the options. Add one, and the validators table is incomplete until someone writes its check:

```ts
// errors/l04_mapped.ts
// A new option: the validators object no longer matches, so tsc points at it
interface SceneOptions {
  stars: boolean;
  tower: boolean;
  skyboxMode: 'milky-way' | 'nebula';
  weather: boolean;
}
type Validators<T> = {
  [K in keyof T]: (value: unknown) => value is T[K];
};

const isBoolean = (value: unknown): value is boolean => typeof value === 'boolean';
const sceneValidators: Validators<SceneOptions> = {
  stars: isBoolean,
  tower: isBoolean,
  skyboxMode: (value): value is 'milky-way' | 'nebula' => value === 'milky-way' || value === 'nebula',
};
console.log(Object.keys(sceneValidators));
```

```text
> npx tsc -p out/tsconfig.l04_mapped.json --pretty
errors/l04_mapped.ts:14:7 - error TS2741: Property 'weather' is missing in type '{ stars: (value: unknown) => value is boolean; tower: (value: unknown) => value is boolean; skyboxMode: (value: unknown) => value is "milky-way" | "nebula"; }' but required in type 'Validators<SceneOptions>'.

14 const sceneValidators: Validators<SceneOptions> = {
         ~~~~~~~~~~~~~~~

  errors/l04_mapped.ts:7:3 - 'weather' is declared here.
    7   weather: boolean;
        ~~~~~~~


Found 1 error in errors/l04_mapped.ts:14
```

C# would reach the same guarantee with a source generator or reflection, and Java with an annotation processor. In TypeScript, the relation between the two types is a type, and `tsc` checks it on every build.

## Key takeaways

- `tsc` infers type arguments from the call, and reports a conflicting argument against what it inferred first; constraints use `extends` and can be shapes.
- `keyof T` and `T[K]` let a return type depend on a key passed as a value.
- Types are erased entirely: no `new T()`, no `instanceof T`, no `typeof(T)`. Pass a constructor or a type guard instead.
- A `T` that appears only in the return type, `parse<T>(json): T`, is an unchecked assertion; so is a generic guard that doesn't check `T`.
- Arrays are covariant and unchecked. Function-type properties are checked contravariantly under `strictFunctionTypes`; method parameters stay bivariant.
- `in` and `out` annotations are optional, and `tsc` doesn't catch every wrong one.
- A mapped type, `{ [K in keyof T]: … }`, derives one type from another, and keeps the two in step as the first one changes.

## Exercises

1. Write `groupBy(items, keyOf)`, which groups the elements of an array by the key that `keyOf` returns, with a return type in which grouping chords by their quality gives the properties `major`, `minor` and `diminished`, each possibly absent.

<details>
<summary>Solution</summary>

[`solutions/l04_ex1_group_by.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l04_ex1_group_by.ts):

```ts
// solutions/l04_ex1_group_by.ts
function groupBy<T, K extends PropertyKey>(items: readonly T[], keyOf: (item: T) => K): Partial<Record<K, T[]>> {
  const groups: Partial<Record<K, T[]>> = {};
  for (const item of items) {
    const key = keyOf(item);
    (groups[key] ??= []).push(item);
  }
  return groups;
}

interface Chord {
  name: string;
  quality: 'major' | 'minor' | 'diminished';
}
const chords: Chord[] = [
  { name: 'C', quality: 'major' },
  { name: 'Dm', quality: 'minor' },
  { name: 'Em', quality: 'minor' },
  { name: 'F', quality: 'major' },
  { name: 'Bdim', quality: 'diminished' },
];
const byQuality = groupBy(chords, (chord) => chord.quality); // K is 'major' | 'minor' | 'diminished'
console.log(byQuality.minor?.map((chord) => chord.name));
console.log(Object.keys(groupBy(chords, (chord) => chord.name.length)));
```

```text
[ 'Dm', 'Em' ]
[ '1', '2', '4' ]
```

`K extends PropertyKey`, which is `string | number | symbol`, lets `K` be inferred as the literal union of the qualities, and `Partial` says that a quality may have no chords, hence `byQuality.minor?.map`. The second call groups by a `number`, and prints the keys as strings: JavaScript object keys are strings, and `Record<number, …>` describes how they are written, not what `Object.keys` returns. A [`Map<K, T[]>`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map) keeps the numbers; `Object.groupBy`, in ES2024, returns the same `Partial<Record<K, T[]>>` as this solution.

</details>

2. Write `isApiResponseOf(value, isData)`, a version of GA's `isApiResponse` whose `T` is checked, and use it for a response whose `data` must be an array of strings.

<details>
<summary>Solution</summary>

[`solutions/l04_ex2_api_response.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l04_ex2_api_response.ts):

```ts
// solutions/l04_ex2_api_response.ts
interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: string;
}
type Guard<T> = (value: unknown) => value is T;

// The guard for T is a parameter: the check on data runs, instead of being promised
function isApiResponseOf<T>(value: unknown, isData: Guard<T>): value is ApiResponse<T> {
  return (
    typeof value === 'object' &&
    value !== null &&
    'success' in value &&
    typeof value.success === 'boolean' &&
    'data' in value &&
    isData(value.data)
  );
}

const isStringArray: Guard<string[]> = (value): value is string[] =>
  Array.isArray(value) && value.every((item) => typeof item === 'string');

for (const text of ['{"success": true, "data": ["C", "E", "G"]}', '{"success": true, "data": "C major"}']) {
  const json: unknown = JSON.parse(text);
  if (isApiResponseOf(json, isStringArray)) {
    console.log('notes:', json.data.join(' '));
  } else {
    console.log('rejected:', text);
  }
}
```

```text
notes: C E G
rejected: {"success": true, "data": "C major"}
```

The guard for `data` is a parameter, so `T` is inferred from it, and the caller can't choose a `T` without providing the check. In `parseJson`, the fallback `json as T` would have to become a thrown error: a response that isn't an `ApiResponse` of the expected data is an error of the API, and saying so where it happens saves looking for it in a component.

</details>

3. Write `pick(value, keys)`, which returns an object with only the listed properties, typed with `Pick`, so that a key that doesn't exist and a property that wasn't picked are both compile errors.

<details>
<summary>Solution</summary>

[`solutions/l04_ex3_pick.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l04_ex3_pick.ts):

```ts
// solutions/l04_ex3_pick.ts
function pick<T extends object, K extends keyof T>(value: T, keys: readonly K[]): Pick<T, K> {
  const result = {} as Pick<T, K>; // an assertion: the loop below fills every key of K
  for (const key of keys) {
    result[key] = value[key];
  }
  return result;
}

interface SceneOptions {
  stars: boolean;
  tower: boolean;
  skyboxMode: 'milky-way' | 'nebula';
}
const options: SceneOptions = { stars: true, tower: false, skyboxMode: 'nebula' };
const toggles = pick(options, ['stars', 'tower']); // Pick<SceneOptions, 'stars' | 'tower'>
console.log(toggles, Object.keys(toggles));

// Never called: each line shows a mistake that tsc rejects
function mistakes() {
  // @ts-expect-error: 'weather' is not a key of SceneOptions
  pick(options, ['weather']);
  // @ts-expect-error: skyboxMode was not picked
  return toggles.skyboxMode;
}
console.log(typeof mistakes);
```

```text
{ stars: true, tower: false } [ 'stars', 'tower' ]
function
```

`{}` is not a `Pick<T, K>` until the loop has run, and `tsc` can't follow a loop that fills every key of a union, so the function starts with an assertion and a comment that says what makes it true. That is the usual shape of a generic utility: a small, checked signature outside, and one justified assertion inside.

</details>

## Sources

- [TypeScript handbook — Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html), [Keyof type operator](https://www.typescriptlang.org/docs/handbook/2/keyof-types.html), [Indexed access types](https://www.typescriptlang.org/docs/handbook/2/indexed-access-types.html), [Mapped types](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html), [Utility types](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [TSConfig reference — strictFunctionTypes](https://www.typescriptlang.org/tsconfig/#strictFunctionTypes); release notes [2.6 — strict function types](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-6.html), [4.7 — variance annotations](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters)
- [Microsoft — Generics](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/generics), [Constraints on type parameters](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters), [Covariance and contravariance in generics](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)
- [The Java Tutorials — Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html), [Wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html), [Restrictions on generics](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html)
