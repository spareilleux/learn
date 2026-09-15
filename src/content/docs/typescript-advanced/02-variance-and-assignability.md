---
title: 2. Variance and assignability
description: How tsc measures variance and where the measure is unsound, in out annotations, the method bivariance hack of @types/react, satisfies against annotations and assertions, const type parameters, NoInfer and inference from the return type, exactOptionalPropertyTypes, weak types and comparability, next to C#'s checked variance and Java's wildcards.
sidebar:
  order: 2
---

Code: the files [`examples/l02_*`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples) and [`errors/l02_assignability.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/errors/l02_assignability.ts), and the C# and Java sides in [`compare/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare) (`l02_variance.cs`, `L02TargetTyping.java`) and [`compare_fail/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare_fail) (`l02_variant_setter.cs`, `l02_return_inference.cs`, `L02Wildcard.java`).

[Lesson 4 of the base course](../../typescript-for-csharp-java/04-generics/#variance) showed the rules: arrays are covariant and unchecked, function-type properties are checked contravariantly under `strictFunctionTypes`, method parameters stay bivariant, and `in` and `out` annotations are optional. This lesson measures them, finds where they let a wrong value through, and then looks at the other half of "is this assignable": how `tsc` decides what type a value has in the first place, and how `satisfies`, `const` and `NoInfer` change that decision.

## Measuring variance

Variance can be observed without reading the checker: build the same generic type for a subtype and a supertype, and test assignability in both directions.

```ts
// examples/l02_variance.ts
import type { Equal, Expect } from './type-tests.ts';
import { attempt, show } from './show.ts';

interface Instrument {
  name: string;
}
interface Guitar extends Instrument {
  strings: number;
  tune(): string;
}

// Measured variance, tested on assignability in both directions
type Variance<Sub, Super> = [Sub] extends [Super] ? ([Super] extends [Sub] ? 'bivariant' : 'covariant') : [Super] extends [Sub] ? 'contravariant' : 'invariant';

interface Producer<T> {
  get: () => T;
}
interface Consumer<T> {
  set: (value: T) => void;
}
interface Both<T> {
  get: () => T;
  set: (value: T) => void;
}
interface WithMethod<T> {
  set(value: T): void;
}
interface Callback<T> {
  subscribe: (listener: (value: T) => void) => void;
}
interface Slot<T> {
  value: T;
}
interface ReadonlySlot<T> {
  readonly value: T;
}

type _1 = Expect<Equal<Variance<Producer<Guitar>, Producer<Instrument>>, 'covariant'>>;
type _2 = Expect<Equal<Variance<Consumer<Guitar>, Consumer<Instrument>>, 'contravariant'>>;
type _3 = Expect<Equal<Variance<Both<Guitar>, Both<Instrument>>, 'invariant'>>;
// A method parameter is bivariant, even under strictFunctionTypes
type _4 = Expect<Equal<Variance<WithMethod<Guitar>, WithMethod<Instrument>>, 'bivariant'>>;
// A parameter of a parameter is covariant again: two contravariant positions cancel out
type _5 = Expect<Equal<Variance<Callback<Guitar>, Callback<Instrument>>, 'covariant'>>;
// A mutable property is read and written, and still measured covariant
type _6 = Expect<Equal<Variance<Slot<Guitar>, Slot<Instrument>>, 'covariant'>>;
type _7 = Expect<Equal<Variance<ReadonlySlot<Guitar>, ReadonlySlot<Instrument>>, 'covariant'>>;

// The covariant mutable property is unsound: a piano gets into the guitar's slot through an alias
const guitar: Guitar = { name: 'guitar', strings: 6, tune: () => 'EADGBE' };
const guitarSlot: Slot<Guitar> = { value: guitar };
const instrumentSlot: Slot<Instrument> = guitarSlot;
instrumentSlot.value = { name: 'piano' };
attempt('guitarSlot.value.tune()', () => guitarSlot.value.tune());

// in out declares the invariance that the structure doesn't show; the same alias no longer compiles
interface SafeSlot<in out T> {
  value: T;
}
type _8 = Expect<Equal<Variance<SafeSlot<Guitar>, SafeSlot<Instrument>>, 'invariant'>>;
const safeGuitarSlot: SafeSlot<Guitar> = { value: guitar };
// @ts-expect-error: SafeSlot<Guitar> is not a SafeSlot<Instrument>
const safeInstrumentSlot: SafeSlot<Instrument> = safeGuitarSlot;
show('safeGuitarSlot.value.tune()', safeGuitarSlot.value.tune());

// The method bivariance hack of @types/react: a function type that stays bivariant under strictFunctionTypes
type EventHandler<E> = { bivarianceHack(event: E): void }['bivarianceHack'];
interface ClickEvent {
  x: number;
}
interface DoubleClickEvent extends ClickEvent {
  count: 2;
}
type _9 = Expect<Equal<Variance<EventHandler<DoubleClickEvent>, EventHandler<ClickEvent>>, 'bivariant'>>;
const onDoubleClick: EventHandler<DoubleClickEvent> = (event) => console.log(`double click ${event.count}`);
const onClick: EventHandler<ClickEvent> = onDoubleClick; // accepted: the hack lets a narrower handler through
attempt('onClick({ x: 3 })', () => onClick({ x: 3 }));
```

```text
guitarSlot.value.tune()            TypeError: guitarSlot.value.tune is not a function
safeGuitarSlot.value.tune()        'EADGBE'
double click undefined
onClick({ x: 3 })                  undefined
```

The type tests make a table of what `tsc` 7.0.2 measures, for `Guitar extends Instrument`:

| Member that uses `T` | Measured | Sound? |
|---|---|---|
| `get: () => T` | covariant | yes |
| `set: (value: T) => void` | contravariant | yes |
| both | invariant | yes |
| `set(value: T): void`, a method | bivariant | no |
| `subscribe: (listener: (value: T) => void) => void` | covariant | yes |
| `value: T`, a mutable property | covariant | no |
| `readonly value: T` | covariant | yes |

Two rows are unsound by design. A method parameter is bivariant, as the base course showed. And a mutable property is measured covariant, although it can be written: `Slot<Guitar>` is accepted as a `Slot<Instrument>`, the alias writes a piano into it, and `guitarSlot.value.tune()` throws. The [handbook on type compatibility](https://www.typescriptlang.org/docs/handbook/type-compatibility.html#a-note-on-soundness) says it plainly: "TypeScript's type system allows certain operations that can't be known at compile-time to be safe", and properties are compared by their read type. C# refuses the equivalent declaration, because a setter consumes `T`:

```text
> dotnet run l02_variant_setter.cs
compare_fail/l02_variant_setter.cs(7,5): error CS1961: Invalid variance: The type parameter 'T' must be invariantly valid on 'ISlot<T>.Value'. 'T' is covariant.

The build failed. Fix the build errors and run again.
```

In C#, `out T` is only allowed on a property without a setter, like `IReadOnlySlot<out T>` in the comparison program, and a `List<Guitar>` converts to `IReadOnlyList<Instrument>` but not to `IList<Instrument>`:

```csharp
// compare/l02_variance.cs
// C# declares variance on interfaces, and checks it against every member
List<Guitar> guitars = [new("guitar", 6)];
IReadOnlyList<Instrument> instruments = guitars; // IReadOnlyList<out T>: covariant, and read-only
IReadOnlySlot<Instrument> slot = new Slot<Guitar>(guitars[0]);
Console.WriteLine($"{instruments[0].Name}, {slot.Value.Name}");

// Inference uses the arguments only: a type parameter that appears only in the return type must be written
List<string> chords = EmptyList<string>();
Console.WriteLine(chords.Count);

static List<T> EmptyList<T>() => [];

record Instrument(string Name);
record Guitar(string Name, int Strings) : Instrument(Name);

interface IReadOnlySlot<out T>
{
    T Value { get; }
}

class Slot<T>(T value) : IReadOnlySlot<T>
{
    public T Value { get; set; } = value;
}
```

```text
> dotnet run l02_variance.cs
guitar, guitar
0
```

**`in out T` restores invariance.** An annotation can't change how types are compared structurally, but it replaces the measured variance when `tsc` compares two instantiations of the same generic type. `SafeSlot<in out T>` is invariant, and the alias no longer compiles. Annotate mutable containers that way when the unsoundness matters. The annotation is checked against the structure only in the direction it permits: `in T` on a type that reads `T` is refused with `TS2636`, while `in out T`, which permits nothing, is accepted on any type.

**Two contravariant positions make a covariant one.** `subscribe` takes a listener, which takes a `T`: a subscription to guitars can be used as a subscription to instruments, because every listener written for instruments accepts guitars. The same reasoning explains the intersection that `infer` produced in [lesson 1](../01-type-level-programming/#conditional-types) for two parameters.

**The bivariance hack.** [`@types/react`](https://github.com/DefinitelyTyped/DefinitelyTyped/blob/a542a0b0a0332f463dd42042f5bfb6cf36a61747/types/react/index.d.ts#L2316) declares its event handlers as `{ bivarianceHack(event: E): void }["bivarianceHack"]`: the type of a method, extracted by indexed access, is a function type that keeps the method's bivariance. `EventHandler<DoubleClickEvent>` is accepted where an `EventHandler<ClickEvent>` is expected, and the handler reads a `count` that isn't there. React's types do it on purpose, so that a handler written for a specific event can be passed to a prop typed with a more general one; the price is the `undefined` in the output.

### Where the measure is used

`tsc` doesn't compare `Slot<Guitar>` and `Slot<Instrument>` member by member each time. For a generic interface, class or type alias, [`getVariancesWorker`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/relater.go#L1341-L1400) measures the variance of each type parameter once: it instantiates the type with two marker types, one a subtype of the other, and tests assignability both ways. A third, unrelated marker tells a bivariant parameter from one that isn't used at all. The result is cached, and later comparisons of two instantiations only compare their type arguments. When the comparison of the markers went through constructs that the measure can't represent, such as a conditional type, the result is flagged [unmeasurable or unreliable](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/types.go#L300-L309), and the checker falls back to a structural comparison.

An annotation skips the measurement: in the same function, `out` gives covariant, `in` contravariant and `in out` invariant, without instantiating anything. That is the use that the [variance annotations of 4.7](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters) were designed for: on a very large type, an annotation saves the measurement, and on a type whose measure is unreliable, it gives the intended answer. The handbook recommends writing them only when they match the structure, and mostly after profiling.

| | C# | Java | TypeScript |
|---|---|---|---|
| Where variance is declared | interfaces and delegates, `in`/`out` | at the use site, `? extends`/`? super` | nowhere: measured; optional `in`/`out` |
| A writable property | invariant, `out` refused (`CS1961`) | — | covariant, unsound; `in out` to fix |
| Parameters of function types | contravariant (delegates, `in T`) | — | contravariant for properties, bivariant for methods |
| Checked | fully | fully, with capture conversion | partly |

Java puts variance on the variable, not on the type. A `List<? extends Object>` can be read, and nothing can be added to it, which is the use-site form of `out T`:

```text
> javac L02Wildcard.java
L02Wildcard.java:12: error: incompatible types: Instrument cannot be converted to CAP#1
        objects.add(new Instrument("piano"));
                    ^
  where CAP#1 is a fresh type-variable:
    CAP#1 extends Object from capture of ? extends Object
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
1 error
```

## satisfies, annotations and assertions

Four ways to say "this object is a `Record<GovernanceHealthStatus, HexColor>`" give four different types:

```ts
// examples/l02_satisfies.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
type HexColor = `#${string}`;

// 1. An annotation: the object is checked, and its type becomes the annotation, so the literal colors are lost
const annotated: Record<GovernanceHealthStatus, HexColor> = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
};
type _1 = Expect<Equal<(typeof annotated)['error'], HexColor>>;

// 2. satisfies: the same check, and the type stays the one inferred from the object. The literals are kept here
// because the contextual type, a template literal type, contains literal types; against string they widen
const satisfying = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
} satisfies Record<GovernanceHealthStatus, HexColor>;
type _2 = Expect<Equal<(typeof satisfying)['error'], '#FF4444'>>;
const widened = { error: '#FF4444' } satisfies Record<'error', string>;
type _2b = Expect<Equal<(typeof widened)['error'], string>>;

// 3. as const satisfies: literal values whatever the contextual type, readonly properties, and the check
const colors = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
} as const satisfies Record<GovernanceHealthStatus, HexColor>;
type _3 = Expect<Equal<(typeof colors)['error'], '#FF4444'>>;
type _3b = Expect<Equal<typeof colors, { readonly error: '#FF4444'; readonly warning: '#FFB300'; readonly healthy: '#33CC66'; readonly unknown: '#888888'; readonly contradictory: '#FF44FF' }>>;

// 4. as: an assertion, which checks only that one type is comparable to the other; a missing status gets through
const partial = { error: '#FF4444', healthy: '#33CC66' };
const asserted = partial as Record<GovernanceHealthStatus, HexColor>;
show('asserted.warning', asserted.warning);

// satisfies provides the contextual type: the parameter of each function is typed without an annotation
interface Formatters {
  [status: string]: (score: number) => string;
}
const formatters = {
  healthy: (score) => `healthy (${score.toFixed(2)})`,
  warning: (score) => `watch (${Math.round(score * 100)}%)`,
} satisfies Formatters;
show('formatters.healthy(0.93)', formatters.healthy(0.93));
// The inferred type keeps exactly the two keys: formatters.error would be a compile error, not undefined at run time
type _4 = Expect<Equal<keyof typeof formatters, 'healthy' | 'warning'>>;

// GA's VoxtralTTS.ts checks a request body the same way, before JSON.stringify erases everything
const body = JSON.stringify({
  model: 'voxtral-mini-tts-2603',
  input: 'The voicing index is fresh.',
  voice_id: 'demerzel',
} satisfies { model: string; input: string; voice_id: string });
show('body', body);
```

```text
asserted.warning                   undefined
formatters.healthy(0.93)           'healthy (0.93)'
body                               '{"model":"voxtral-mini-tts-2603","input":"The voicing index is fresh.","voice_id":"demerzel"}'
```

1. **An annotation** checks the object and replaces its type with the annotation. `annotated.error` is a `HexColor`: the fact that it is `'#FF4444'` is gone.
2. **[`satisfies`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html#the-satisfies-operator)** (4.9) checks the object against the type, and keeps the type inferred from the object. Whether the literals survive depends on the contextual type: against `` `#${string}` ``, a template literal type, the checker keeps `'#FF4444'`; against `string`, it widens to `string`, as `widened` shows. I expected the literal to be widened in both cases, and the type test `_2` corrected me.
3. **`as const satisfies`** keeps the literals whatever the contextual type, makes every property `readonly`, and still checks that no status is missing and every value is a hex color.
4. **An assertion**, `as`, checks almost nothing: one type must be comparable to the other. `partial`, with two statuses, is comparable to the record, since the record is assignable to `{ error: string; healthy: string }`, and `asserted.warning` is `undefined` at run time. With an object literal written directly after `as`, `tsc` 7.0.2 does report the missing properties (`TS2352`), because the literal's types are then the literals themselves, which the record isn't assignable to.

`satisfies` also provides a contextual type, which is why the functions in `formatters` need no parameter annotation, and it keeps the inferred keys: `formatters.error` is a compile error, where an annotation with an index signature would have typed it as a function and returned `undefined`.

GA uses `satisfies` once in its component library, in [`VoxtralTTS.ts`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/VoxtralTTS.ts#L248-L252), on the body of a request just before `JSON.stringify`, which erases every type. It is the right place for it: the object keeps its inferred type, and a misspelled `voice_id` would be caught. The rest of the library uses annotations, such as `HEALTH_STATUS_COLORS: Record<GovernanceHealthStatus, string>` in [`types.ts`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/types.ts#L203-L209), which is enough where only the check matters.

## Controlling inference

```ts
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
```

```text
dadgad                             [ 'D', 'A', 'D', 'G', 'A', 'D' ]
loose.current                      'understood'
chords.length                      0
```

**`const` type parameters.** Without them, an array literal passed to a generic function is inferred as `string[]`. A [`const` type parameter](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html#const-type-parameters) (5.0) infers as if the caller had written `as const`, and `dadgad` keeps its six notes as a readonly tuple. The 5.0 release notes warn that a mutable constraint, `T extends string[]`, makes the inference fall back to `string[]`. That was true up to 5.2: I ran the same file with `tsc` 5.0.4, 5.2.2 and 5.3.3, and since 5.3 the result is the mutable tuple `['D', 'A', 'D']`, which `tsc` 7.0.2 also gives.

**Every argument is an inference site.** `machine(states, initial)` infers `S` from both parameters. The `'understood'` passed as `initial` is not a mistake for `tsc`: it becomes one more member of `S`, and the state machine now has a state that isn't in its list. [`NoInfer<T>`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html#the-noinfer-utility-type) (5.4) removes a position from inference: `S` comes from `states` alone, and `initial` is checked against it, so `'speaking'` is refused.

**Inference from the return type.** `const chords: string[] = emptyList()` infers `T` as `string` from the declared type of the variable. Java does the same with its [target typing](https://docs.oracle.com/javase/tutorial/java/generics/genTypeInference.html#target_types), and C# doesn't: a type parameter that appears only in the return type has to be written.

```text
> java L02TargetTyping.java
[Cmaj7]
```

```text
> dotnet run l02_return_inference.cs
compare_fail/l02_return_inference.cs(2,23): error CS0411: The type arguments for method 'EmptyList<T>()' cannot be inferred from the usage. Try specifying the type arguments explicitly.
compare_fail/l02_return_inference.cs(5,16): warning CS8321: The local function 'EmptyList' is declared but never used

The build failed. Fix the build errors and run again.
```

The warning `CS8321` that follows the error is a side effect: once the call fails, the compiler considers the local function unused.

## Optional, undefined and null

```ts
// examples/l02_optional.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// GA's ViewerInfo, from DataLoader.ts: the server's C# record has string? DisplayName = null and string? AvatarUrl = null
interface ViewerInfo {
  connectionId: string;
  color: string;
  displayName?: string;
  avatarUrl?: string | null;
}

// With exactOptionalPropertyTypes, ? means that the property may be absent, not that it may hold undefined
const absent: ViewerInfo = { connectionId: 'a1', color: '#58a6ff' };
const withNull: ViewerInfo = { connectionId: 'b2', color: '#3fb950', avatarUrl: null };
show("'displayName' in absent", 'displayName' in absent);
show('Object.keys(withNull)', Object.keys(withNull));

// Reading an optional property still gives undefined when it is absent
type _1 = Expect<Equal<ViewerInfo['displayName'], string | undefined>>;
// Partial<T> keeps the rule: a patch can leave a property out, and can't set it to undefined
function applyPatch(viewer: ViewerInfo, patch: Partial<ViewerInfo>): ViewerInfo {
  return { ...viewer, ...patch };
}
show('applyPatch(absent, …)', applyPatch(absent, { displayName: 'Ada' }));

// Why the rule matters: a spread copies an own property holding undefined, and erases the value
const viewer: ViewerInfo = { connectionId: 'c3', color: '#d2a8ff', displayName: 'Hari' };
const sloppyPatch = { displayName: undefined };
show('{ ...viewer, ...sloppyPatch }', { ...viewer, ...sloppyPatch });

// A weak type has only optional properties: tsc requires an argument to share at least one of them
interface TuningOptions {
  capo?: number;
  dropD?: boolean;
}
function tune(options: TuningOptions): string {
  return `capo ${options.capo ?? 0}, drop D ${options.dropD ?? false}`;
}
const fromSettings = { capo: 2, theme: 'dark' };
show('tune(fromSettings)', tune(fromSettings)); // shares capo: accepted, and theme is ignored

// null and undefined are different values, and JSON has only one of them
show('JSON.stringify(withNull)', JSON.stringify(withNull));
show("JSON.stringify(sloppyPatch)", JSON.stringify(sloppyPatch));
```

```text
'displayName' in absent            false
Object.keys(withNull)              [ 'connectionId', 'color', 'avatarUrl' ]
applyPatch(absent, …)              { connectionId: 'a1', color: '#58a6ff', displayName: 'Ada' }
{ ...viewer, ...sloppyPatch }      { connectionId: 'c3', color: '#d2a8ff', displayName: undefined }
tune(fromSettings)                 'capo 2, drop D false'
JSON.stringify(withNull)           '{"connectionId":"b2","color":"#3fb950","avatarUrl":null}'
JSON.stringify(sloppyPatch)        '{}'
```

The course's `tsconfig.json` turns on [`exactOptionalPropertyTypes`](https://www.typescriptlang.org/tsconfig/#exactOptionalPropertyTypes), which isn't part of `strict`. With it, `displayName?: string` means that the property may be absent, not that it may hold `undefined`. The distinction exists at run time: `'displayName' in absent` is `false`, while an object with `displayName: undefined` has the property. It matters for spreads, as the fourth line of the output shows: a patch whose property holds `undefined` erases the value it is spread over. `JSON.stringify` drops the property altogether, and keeps a `null`.

GA's [`ViewerInfo`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L218-L225) declares `displayName?: string` and `avatarUrl?: string | null`. The server's record, in [`GovernanceHub.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Apps/ga-server/GaApi/Hubs/GovernanceHub.cs#L12-L18), is `string? DisplayName = null, string? AvatarUrl = null`, and lesson 4 shows that SignalR sends both as `null`. The type of `displayName` is wrong, and the code works anyway, because [`ForceRadiant.tsx`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L4363-L4382) reads it with `?.` and `??`, which treat `null` like `undefined`. A check written as `viewer.displayName !== undefined`, which the type suggests, would let `null` through.

The snippet below collects the assignability rules of this section and the previous ones. It runs twice: once with the course's options, and once with `--exactOptionalPropertyTypes false`.

```text
> npx tsc -p out/tsconfig.l02_assignability.json --pretty
errors/l02_assignability.ts:20:7 - error TS2375: Type '{ connectionId: string; displayName: undefined; }' is not assignable to type 'ViewerInfo' with 'exactOptionalPropertyTypes: true'. Consider adding 'undefined' to the types of the target's properties.
  Types of property 'displayName' are incompatible.
    Type 'undefined' is not assignable to type 'string'.

20 const explicit: ViewerInfo = { connectionId: 'a1', displayName: undefined };
         ~~~~~~~~

errors/l02_assignability.ts:21:7 - error TS2375: Type '{ displayName: undefined; }' is not assignable to type 'Partial<ViewerInfo>' with 'exactOptionalPropertyTypes: true'. Consider adding 'undefined' to the types of the target's properties.
  Types of property 'displayName' are incompatible.
    Type 'undefined' is not assignable to type 'string'.

21 const patch: Partial<ViewerInfo> = { displayName: undefined };
         ~~~~~

errors/l02_assignability.ts:25:7 - error TS2559: Type '{ theme: string; fontSize: number; }' has no properties in common with type 'TuningOptions'.

25 const options: TuningOptions = theme;
         ~~~~~~~

errors/l02_assignability.ts:30:16 - error TS2352: Conversion of type 'Guitar' to type 'string[]' may be a mistake because neither type sufficiently overlaps with the other. If this was intentional, convert the expression to 'unknown' first.
  Type 'Guitar' is missing the following properties from type 'string[]': length, pop, push, concat, and 35 more.

30 const tuning = guitar as string[];
                  ~~~~~~~~~~~~~~~~~~

errors/l02_assignability.ts:34:7 - error TS2322: Type 'SafeSlot<Guitar>' is not assignable to type 'SafeSlot<{ name: string; }>'.
  Property 'strings' is missing in type '{ name: string; }' but required in type 'Guitar'.

34 const namedSlot: SafeSlot<{ name: string }> = guitarSlot;
         ~~~~~~~~~


Found 5 errors in the same file, starting at: errors/l02_assignability.ts:20
```

```text
> npx tsc -p out/tsconfig.l02_assignability.json --pretty --exactOptionalPropertyTypes false
errors/l02_assignability.ts:25:7 - error TS2559: Type '{ theme: string; fontSize: number; }' has no properties in common with type 'TuningOptions'.

25 const options: TuningOptions = theme;
         ~~~~~~~

errors/l02_assignability.ts:30:16 - error TS2352: Conversion of type 'Guitar' to type 'string[]' may be a mistake because neither type sufficiently overlaps with the other. If this was intentional, convert the expression to 'unknown' first.
  Type 'Guitar' is missing the following properties from type 'string[]': length, pop, push, concat, and 35 more.

30 const tuning = guitar as string[];
                  ~~~~~~~~~~~~~~~~~~

errors/l02_assignability.ts:34:7 - error TS2322: Type 'SafeSlot<Guitar>' is not assignable to type 'SafeSlot<{ name: string; }>'.
  Property 'strings' is missing in type '{ name: string; }' but required in type 'Guitar'.

34 const namedSlot: SafeSlot<{ name: string }> = guitarSlot;
         ~~~~~~~~~


Found 3 errors in the same file, starting at: errors/l02_assignability.ts:25
```

- **`TS2375`**: with `exactOptionalPropertyTypes`, `undefined` is not a value of an optional property, in an object and in a `Partial`. The second run accepts both lines.
- **`TS2559`**: a **weak type**, whose properties are all optional, must share at least one property with the value assigned to it. `{ theme, fontSize }` shares nothing with `TuningOptions`, and is refused, although it is structurally assignable; `fromSettings` in the example shares `capo`, and is accepted. The rule dates from [TypeScript 2.4](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-4.html#weak-type-detection).
- **`TS2352`**: an assertion between types that aren't comparable. Going through `unknown` silences it, which is why `as unknown as` is the pattern to search for in a code base: GA's component library has 34 of them.
- **`TS2322`** on `SafeSlot`: the `in out` annotation of the first section, and the message shows the check in the other direction, from `{ name: string }` to `Guitar`.

## Key takeaways

- `tsc` measures variance from the structure; mutable properties are measured covariant and method parameters bivariant, both unsound. `in out T` makes a type invariant.
- Two contravariant positions cancel out; the bivariance hack of `@types/react` keeps a function type bivariant on purpose.
- An annotation replaces the inferred type, `satisfies` checks and keeps it, `as const satisfies` keeps the literals too, and `as` checks only comparability.
- `const` type parameters infer literal tuples; `NoInfer` removes an argument from inference; an expected return type also drives inference, as in Java and unlike C#.
- `exactOptionalPropertyTypes` separates an absent property from one that holds `undefined`, and `null` is a third case that JSON keeps.

## Exercises

1. A small signal library declares `interface Signal<T> { get(): T; set(value: T): void; subscribe(listener: (value: T) => void): () => void }`. Predict the variance that `tsc` measures, check it with a type test, and write two versions that are invariant.

<details>
<summary>Solution</summary>

[`solutions/l02_ex1_signal.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l02_ex1_signal.ts):

```ts
// solutions/l02_ex1_signal.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Variance<Sub, Super> = [Sub] extends [Super] ? ([Super] extends [Sub] ? 'bivariant' : 'covariant') : [Super] extends [Sub] ? 'contravariant' : 'invariant';

interface Instrument {
  name: string;
}
interface Guitar extends Instrument {
  tune(): string;
}

// The signal as first written: set is a method, so its parameter is bivariant, and T is measured covariant
interface Signal<T> {
  get(): T;
  set(value: T): void;
  subscribe(listener: (value: T) => void): () => void;
}
type _1 = Expect<Equal<Variance<Signal<Guitar>, Signal<Instrument>>, 'covariant'>>;

// Function-type properties are checked under strictFunctionTypes: get makes T covariant, set contravariant
interface CheckedSignal<T> {
  get: () => T;
  set: (value: T) => void;
  subscribe: (listener: (value: T) => void) => () => void;
}
type _2 = Expect<Equal<Variance<CheckedSignal<Guitar>, CheckedSignal<Instrument>>, 'invariant'>>;

// Or keep the methods, and say what they mean
interface AnnotatedSignal<in out T> {
  get(): T;
  set(value: T): void;
  subscribe(listener: (value: T) => void): () => void;
}
type _3 = Expect<Equal<Variance<AnnotatedSignal<Guitar>, AnnotatedSignal<Instrument>>, 'invariant'>>;

function signal<T>(initial: T): CheckedSignal<T> {
  let value = initial;
  const listeners = new Set<(value: T) => void>();
  return {
    get: () => value,
    set: (next) => {
      value = next;
      for (const listener of listeners) listener(next);
    },
    subscribe: (listener) => {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
  };
}

const guitar = signal<Guitar>({ name: 'guitar', tune: () => 'EADGBE' });
guitar.subscribe((g) => console.log(`tuned to ${g.tune()}`));
guitar.set({ name: 'baritone', tune: () => 'BEADF#B' });
// @ts-expect-error: a CheckedSignal<Guitar> is not a CheckedSignal<Instrument>, which could set a piano
const instruments: CheckedSignal<Instrument> = guitar;
console.log(guitar.get().name, typeof instruments);
```

```text
tuned to BEADF#B
baritone object
```

With methods, `set` doesn't count as contravariant, so `get` and `subscribe` make the whole signal covariant, and a `Signal<Guitar>` could be stored in a `Signal<Instrument>` variable and given a piano. Function-type properties make `strictFunctionTypes` apply, and the signal becomes invariant; `in out T` gets the same result while keeping the method syntax. The implementation uses the property version, and the `@ts-expect-error` line is the test that the unsafe alias is refused.

</details>

2. Write `defineStatusColors(colors)`, a function that does what `as const satisfies Record<GovernanceHealthStatus, HexColor>` does: literal colors in the result, a compile error for a missing status or a color that isn't hexadecimal.

<details>
<summary>Solution</summary>

[`solutions/l02_ex2_define_colors.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l02_ex2_define_colors.ts):

```ts
// solutions/l02_ex2_define_colors.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
type HexColor = `#${string}`;

// A const type parameter keeps the literals, and the constraint checks completeness and the format of each color
function defineStatusColors<const T extends Record<GovernanceHealthStatus, HexColor>>(colors: T): T {
  return colors;
}

const colors = defineStatusColors({
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
});
type _1 = Expect<Equal<(typeof colors)['healthy'], '#33CC66'>>;

function mistakes() {
  // @ts-expect-error: contradictory is missing
  defineStatusColors({ error: '#FF4444', warning: '#FFB300', healthy: '#33CC66', unknown: '#888888' });
  // @ts-expect-error: magenta is not a hex color
  defineStatusColors({ error: '#FF4444', warning: '#FFB300', healthy: '#33CC66', unknown: '#888888', contradictory: 'magenta' });
}
console.log(colors.healthy, typeof mistakes);
```

```text
#33CC66 function
```

The `const` modifier keeps the literals, and the constraint plays the role of `satisfies`. The function form was the usual way to get this before 4.9, and it is still useful when the check needs a generic, for instance a table whose values must be keys of another argument.

</details>

3. A form produces `{ displayName: string | undefined; avatarUrl: string | null | undefined }`, where `undefined` means that the field was left empty. Write `withoutUndefined(value)`, whose result can be spread over a `ViewerInfo` under `exactOptionalPropertyTypes`.

<details>
<summary>Solution</summary>

[`solutions/l02_ex3_without_undefined.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l02_ex3_without_undefined.ts):

```ts
// solutions/l02_ex3_without_undefined.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

interface ViewerInfo {
  connectionId: string;
  color: string;
  displayName?: string;
  avatarUrl?: string | null;
}

// Properties that may hold undefined become optional and lose undefined; null is kept, since it is a value
type WithoutUndefined<T> = { [K in keyof T]: Exclude<T[K], undefined> };

function withoutUndefined<T extends object>(value: T): Partial<WithoutUndefined<T>> {
  // An assertion: the filter removes exactly the entries whose value is undefined
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as Partial<WithoutUndefined<T>>;
}

// A patch built from a form, where a field left empty is undefined
const form: { displayName: string | undefined; avatarUrl: string | null | undefined } = { displayName: undefined, avatarUrl: null };
const patch = withoutUndefined(form);
type _1 = Expect<Equal<typeof patch, { displayName?: string; avatarUrl?: string | null }>>;

const viewer: ViewerInfo = { connectionId: 'c3', color: '#d2a8ff', displayName: 'Hari' };
const updated: ViewerInfo = { ...viewer, ...patch };
console.log(updated);
```

```text
{
  connectionId: 'c3',
  color: '#d2a8ff',
  displayName: 'Hari',
  avatarUrl: null
}
```

`WithoutUndefined` removes `undefined` from each property type and `Partial` makes each property optional, which is exactly what the filter does at run time: a property is either absent or holds a value. `null` is kept, since it is a value that the server sends and the type allows. The output shows `displayName` untouched, because the empty field was removed instead of being spread as `undefined`.

</details>

## Sources

- [TypeScript handbook — Type compatibility](https://www.typescriptlang.org/docs/handbook/type-compatibility.html), [Generics — variance annotations](https://www.typescriptlang.org/docs/handbook/2/generics.html#variance-annotations)
- Release notes: [2.4 — weak type detection](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-4.html#weak-type-detection), [4.7 — variance annotations](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters), [4.9 — `satisfies`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html#the-satisfies-operator), [5.0 — `const` type parameters](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html#const-type-parameters), [5.4 — `NoInfer`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html#the-noinfer-utility-type)
- [TSConfig reference — exactOptionalPropertyTypes](https://www.typescriptlang.org/tsconfig/#exactOptionalPropertyTypes)
- [DefinitelyTyped — `types/react/index.d.ts`](https://github.com/DefinitelyTyped/DefinitelyTyped/blob/a542a0b0a0332f463dd42042f5bfb6cf36a61747/types/react/index.d.ts#L2316)
- [Microsoft — Covariance and contravariance in generics](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance), [Compiler error CS1961](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/generic-type-parameters-errors#type-parameter-variance); [The Java Tutorials — Wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html), [Type inference and target types](https://docs.oracle.com/javase/tutorial/java/generics/genTypeInference.html)
