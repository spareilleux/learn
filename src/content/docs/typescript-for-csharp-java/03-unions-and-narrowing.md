---
title: 3. Unions and narrowing
description: Union types, narrowing with typeof, in, instanceof and control flow, discriminated unions and exhaustiveness with never, type assertions that check nothing, type predicates and assertion functions — against C# switch expressions and Java sealed interfaces.
sidebar:
  order: 3
---

Code: the files [`examples/l03_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/examples) and [`errors/l03_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors), and the C# and Java sides in [`compare/l03_switch.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/l03_switch.cs), [`compare/l03_cast.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/l03_cast.cs), [`compare/L03Cast.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/L03Cast.java) and [`compare_fail/L03Sealed.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail/L03Sealed.java).

C# and Java model "one of several things" with a class hierarchy: an abstract base, one subclass per case, and a virtual method or a pattern match to tell them apart. JavaScript has no such hierarchy for most of its values: a fret is a number or the string `'open'`, an event is an object whose `kind` property says what it is. TypeScript describes those values with **union types**, and follows the checks in your code to know which member a value is at each line. That second part, **narrowing**, is what this lesson is about ([handbook: narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)).

## Union types

`A | B` is a value that is an `A` or a `B`. Before a check, only what every member has is allowed:

```ts
// errors/l03_union_members.ts
type Fret = number | 'open' | 'muted';

function describe(fret: Fret): string {
  return `fret ${fret.toFixed(0)}`;
}

console.log(describe(3), describe('open'));
```

```text
> npx tsc -p out/tsconfig.l03_union_members.json --pretty
errors/l03_union_members.ts:5:23 - error TS2339: Property 'toFixed' does not exist on type 'Fret'.
  Property 'toFixed' does not exist on type '"muted"'.

5   return `fret ${fret.toFixed(0)}`;
                        ~~~~~~~


Found 1 error in errors/l03_union_members.ts:5
> node errors/l03_union_members.ts
errors/l03_union_members.ts:5
  return `fret ${fret.toFixed(0)}`;
                      ^

TypeError: fret.toFixed is not a function

Node.js v24.21.0
```

`number` has `toFixed`, `'open'` and `'muted'` don't, so `Fret` doesn't either. The message names one member that lacks the property. A union of literal types, `'open' | 'muted'`, is also how TypeScript writes what C# and Java would make an `enum`, without the runtime object that Node.js refuses to strip ([lesson 1](../01-compiler-and-tooling/)).

## Narrowing

```ts
// examples/l03_narrowing.ts
import { show } from './show.ts';

// A union: a fret is a number, or 'open', or 'muted'
type Fret = number | 'open' | 'muted';

function describe(fret: Fret): string {
  if (typeof fret === 'number') {
    return `fret ${fret.toFixed(0)}`; // here fret is a number
  }
  return fret === 'open' ? 'open string' : 'not played'; // here fret is 'open' | 'muted'
}
show('describe(3)', describe(3));
show("describe('muted')", describe('muted'));

// Truthiness narrows too, and 0 is falsy: the open string played at fret 0 disappears
function label(fret: number | undefined): string {
  if (fret) return `fret ${fret}`;
  return 'no fret';
}
show('label(0)', label(0));
show('label(undefined)', label(undefined));

// in, instanceof and Array.isArray
interface Note {
  pitch: number;
}
interface Chord {
  pitches: number[];
}
function lowest(event: Note | Chord): number {
  return 'pitch' in event ? event.pitch : Math.min(...event.pitches);
}
show('lowest({ pitch: 40 })', lowest({ pitch: 40 }));
show('lowest({ pitches: [52, 45] })', lowest({ pitches: [52, 45] }));

function message(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (Array.isArray(error)) return `${error.length} errors`;
  return String(error);
}
show("message(new RangeError('fret 25'))", message(new RangeError('fret 25')));
show("message(['a', 'b'])", message(['a', 'b']));

// Control flow: after a return or a throw, the rest of the function knows more
function parseFret(text: string): Fret {
  if (text === 'o') return 'open';
  if (text === 'x') return 'muted';
  const fret = Number(text);
  if (!Number.isInteger(fret) || fret < 0) throw new RangeError(`not a fret: ${text}`);
  return fret;
}
show("'x32010'.split('').map(parseFret)", 'x32010'.split('').map(parseFret));
```

```text
describe(3)                        'fret 3'
describe('muted')                  'not played'
label(0)                           'no fret'
label(undefined)                   'no fret'
lowest({ pitch: 40 })              40
lowest({ pitches: [52, 45] })      45
message(new RangeError('fret 25')) 'fret 25'
message(['a', 'b'])                '2 errors'
'x32010'.split('').map(parseFret)  [ 'muted', 3, 2, 0, 1, 0 ]
```

Each check that JavaScript can run becomes information for `tsc`:

| Check | Narrows to | C# / Java equivalent |
|---|---|---|
| `typeof fret === 'number'` | `number`, and `'open' \| 'muted'` in the `else` | `fret is int` / `fret instanceof Integer` |
| `fret === 'open'` | the literal type `'open'` | `==` on a constant |
| `if (fret)` | removes `undefined`, `null`, and the literal types `0`, `''`, `false` | — |
| `'pitch' in event` | the members that declare `pitch` | — |
| `error instanceof Error` | `Error` | `error is Exception e` / `error instanceof Exception e` |
| `Array.isArray(error)` | `any[]` | — |
| `return`, `throw` | the rest of the function, without the cases that left | definite assignment, flow analysis |

Two of those checks deserve a warning. **Truthiness** narrows `number | undefined` to `number`, and the `if (fret)` in `label` also sends the fret `0`, the open string, to the `'no fret'` branch: `tsc` accepts it, because `0` is a `number`, and the program is wrong. The rules are those of [JavaScript lesson 2](../../javascript-for-csharp-java/02-values-and-types/#conversions----parsing-and-truthiness); compare with `!== undefined` whenever `0` or `''` is a valid value. **`in`** checks a property at run time, and structural typing lets an object have more properties than its type says: a `Chord` object that also carries a `pitch` would take the `Note` branch. `in` is reliable when the members of the union can't have each other's properties, which is what the next section builds.

`tsc` follows the code the way C#'s definite assignment analysis does, through `return`, `throw`, `&&`, `||` and `?:`: in `parseFret`, `fret` is a `number` after the two early returns, and the `throw` guarantees that it is a non-negative integer, a fact that the type `number` can't express.

## Discriminated unions

When every member of a union has the same property with a different literal type, checking that property narrows to one member. That property is the **discriminant**, here `kind`:

```ts
// examples/l03_discriminated.ts
import { show } from './show.ts';

// A discriminated union: every member has a kind, with a different literal type
type MusicEvent =
  | { kind: 'note'; pitch: number; beats: number }
  | { kind: 'chord'; pitches: number[]; beats: number }
  | { kind: 'rest'; beats: number };

function assertNever(value: never): never {
  throw new Error(`unexpected event: ${JSON.stringify(value)}`);
}

function describe(event: MusicEvent): string {
  switch (event.kind) {
    case 'note':
      return `note ${event.pitch} for ${event.beats}`;
    case 'chord':
      return `chord of ${event.pitches.length} for ${event.beats}`;
    case 'rest':
      return `rest for ${event.beats}`;
    default:
      return assertNever(event); // event is never here: every kind is handled
  }
}

const bar: MusicEvent[] = [
  { kind: 'chord', pitches: [48, 52, 55], beats: 2 },
  { kind: 'note', pitch: 60, beats: 1 },
  { kind: 'rest', beats: 1 },
];
for (const event of bar) show(event.kind, describe(event));

// The check that tsc did at compile time still runs, for data that didn't go through tsc
const fromServer = JSON.parse('{"kind": "tie", "beats": 1}') as MusicEvent;
try {
  describe(fromServer);
} catch (err) {
  show('describe(fromServer)', err instanceof Error ? err.message : err);
}
```

```text
chord                              'chord of 3 for 2'
note                               'note 60 for 1'
rest                               'rest for 1'
describe(fromServer)               'unexpected event: {"kind":"tie","beats":1}'
```

Inside `case 'note':`, `event` is `{ kind: 'note'; pitch: number; beats: number }`, and `event.pitch` compiles; in `case 'rest':` it wouldn't. After the three cases, nothing is left: `event` has the type `never`, and `assertNever(event)` compiles because a `never` is assignable to the parameter `never`. At run time the `default` branch still exists, and it catches what the types didn't: `fromServer` was asserted to be a `MusicEvent`, arrived with the kind `'tie'`, and reached `assertNever`.

A discriminated union is the TypeScript version of a closed hierarchy, a C# `abstract record` with its derived records, or a Java `sealed interface` with its `record` implementations. The data is plain objects, which is what `JSON.parse` returns and what a server sends.

## Exhaustiveness

Add a member, and every `switch` that doesn't handle it should fail to compile. With `assertNever` in the `default`, or with a declared return type, it does:

```ts
// errors/l03_exhaustive.ts
// A new kind of event: the two functions that don't handle it are now errors
type MusicEvent =
  | { kind: 'note'; pitch: number; beats: number }
  | { kind: 'chord'; pitches: number[]; beats: number }
  | { kind: 'rest'; beats: number }
  | { kind: 'tie'; beats: number };

function assertNever(value: never): never {
  throw new Error(`unexpected event: ${JSON.stringify(value)}`);
}

function describe(event: MusicEvent): string {
  switch (event.kind) {
    case 'note':
      return `note ${event.pitch}`;
    case 'chord':
      return `chord of ${event.pitches.length}`;
    case 'rest':
      return 'rest';
    default:
      return assertNever(event);
  }
}

function beatsOf(event: MusicEvent): number {
  switch (event.kind) {
    case 'note':
    case 'chord':
    case 'rest':
      return event.beats;
  }
}

console.log(describe({ kind: 'tie', beats: 1 }), beatsOf({ kind: 'tie', beats: 1 }));
```

```text
> npx tsc -p out/tsconfig.l03_exhaustive.json --pretty
errors/l03_exhaustive.ts:22:26 - error TS2345: Argument of type '{ kind: "tie"; beats: number; }' is not assignable to parameter of type 'never'.

22       return assertNever(event);
                            ~~~~~

errors/l03_exhaustive.ts:26:38 - error TS2366: Function lacks ending return statement and return type does not include 'undefined'.

26 function beatsOf(event: MusicEvent): number {
                                        ~~~~~~


Found 2 errors in the same file, starting at: errors/l03_exhaustive.ts:22
> node errors/l03_exhaustive.ts
errors/l03_exhaustive.ts:10
  throw new Error(`unexpected event: ${JSON.stringify(value)}`);
        ^

Error: unexpected event: {"kind":"tie","beats":1}

Node.js v24.21.0
```

The first error says that a `tie` event reaches a parameter that accepts nothing. The second comes from the return type: `beatsOf` promises a `number`, and a `tie` event would fall through the `switch` and return `undefined`. Without `assertNever`, a function with no declared return type, or one that returns `void`, compiles without a message ([exhaustiveness checking](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#exhaustiveness-checking)).

The same change in C#, with a [switch expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) over records, is a warning:

```text
> dotnet run l03_switch.cs
compare/l03_switch.cs(10,43): warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern '_' is not covered.
chord of 3
note 60
SwitchExpressionException
```

C# can't know that no other class derives from `MusicEvent`, so it asks for a `_` case, builds anyway, and throws [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception) on the `Tie`. Java's [sealed interfaces](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) close the hierarchy, and a [`switch` with patterns](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html) over one is checked as TypeScript checks a union:

```text
> javac L03Sealed.java
L03Sealed.java:10: error: the switch expression does not cover all possible input values
        return switch (e) {
               ^
1 error
```

| | C# | Java | TypeScript |
|---|---|---|---|
| Closed set of cases | no closed hierarchies in C# 14: a `_` case is expected | `sealed interface … permits` | a union type |
| Missing case | warning CS8509, `SwitchExpressionException` at run time | compile error | error, if the `switch` ends in `assertNever` or the function declares its return type |
| Data from outside | deserialized into the classes | deserialized into the records | plain objects: the discriminant must be checked |

## as checks nothing

C# and Java casts are checked when they run. A TypeScript **type assertion**, `value as T`, is a message to `tsc` and disappears with the other types:

```ts
// examples/l03_guards.ts, lines 11-13
const trusted = JSON.parse('{"px": 1, "py": 2}') as CameraState;
show('trusted.pz', trusted.pz);
show('trusted.pz * 2', trusted.pz * 2);
```

```text
trusted.pz                         undefined
trusted.pz * 2                     NaN
```

```text
> dotnet run l03_cast.cs
(CameraState)parsed: InvalidCastException
parsed as CameraState: True
parsed is CameraState: False
```

```text
> java L03Cast.java
(CameraState) parsed: ClassCastException
parsed instanceof CameraState: false
```

C#'s `(CameraState)parsed` throws `InvalidCastException`, `as` returns `null`, and Java's cast throws `ClassCastException`: the runtime knows the class of every object. A JavaScript object parsed from JSON has no class to compare with, and `as` doesn't try. `tsc` only refuses an assertion between two types that don't overlap at all, and `as unknown as T` goes through `unknown` to get past that refusal ([type assertions](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions)). The number `NaN` that came out of `trusted.pz * 2` is the kind of value that travels far from the line that produced it.

## Type predicates and assertion functions

A check that `tsc` can't read in one expression goes into a function whose return type says what it proves:

```ts
// examples/l03_guards.ts
import { attempt, show } from './show.ts';

interface CameraState {
  px: number;
  py: number;
  pz: number;
}

// as is not a cast: it converts nothing and checks nothing
const trusted = JSON.parse('{"px": 1, "py": 2}') as CameraState;
show('trusted.pz', trusted.pz);
show('trusted.pz * 2', trusted.pz * 2);

// A type predicate: a function that returns a boolean, and tells tsc what true means
function isCameraState(value: unknown): value is CameraState {
  return (
    typeof value === 'object' &&
    value !== null &&
    'px' in value &&
    typeof value.px === 'number' && // after 'px' in value, tsc knows value has a px property of type unknown
    'py' in value &&
    typeof value.py === 'number' &&
    'pz' in value &&
    typeof value.pz === 'number'
  );
}

function restore(saved: string): CameraState {
  const value: unknown = JSON.parse(saved);
  return isCameraState(value) ? value : { px: 0, py: 0, pz: 100 };
}
show("restore('{\"px\":1,\"py\":2}')", restore('{"px":1,"py":2}'));
show("restore('{\"px\":1,\"py\":2,\"pz\":3}')", restore('{"px":1,"py":2,"pz":3}'));

// An assertion function: it returns only if the condition holds, and throws otherwise
type Mode = 'ionian' | 'dorian' | 'phrygian';
const modes: readonly string[] = ['ionian', 'dorian', 'phrygian'];
function assertMode(value: string): asserts value is Mode {
  if (!modes.includes(value)) throw new RangeError(`unknown mode: ${value}`);
}
function brightness(mode: Mode): number {
  return modes.length - modes.indexOf(mode);
}
const fromUrl = new URLSearchParams('?mode=dorian').get('mode') ?? 'ionian';
assertMode(fromUrl);
show('brightness(fromUrl)', brightness(fromUrl)); // fromUrl is a Mode after the assertion
attempt("assertMode('locrian')", () => assertMode('locrian'));

// tsc trusts a predicate without reading it: a wrong one is a lie that compiles
function isCameraStateLie(value: unknown): value is CameraState {
  return value !== null;
}
const lie: unknown = JSON.parse('"not a camera"');
if (isCameraStateLie(lie)) {
  attempt('lie.px.toFixed(1)', () => lie.px.toFixed(1));
}
```

```text
trusted.pz                         undefined
trusted.pz * 2                     NaN
restore('{"px":1,"py":2}')         { px: 0, py: 0, pz: 100 }
restore('{"px":1,"py":2,"pz":3}')  { px: 1, py: 2, pz: 3 }
brightness(fromUrl)                2
assertMode('locrian')              RangeError: unknown mode: locrian
lie.px.toFixed(1)                  TypeError: Cannot read properties of undefined (reading 'toFixed')
```

- **`value is CameraState`**, a [type predicate](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#using-type-predicates), returns a `boolean`, and in the branch where it returned `true`, the argument is a `CameraState`. Inside `isCameraState`, each `'px' in value` narrows `value` to an object with a `px` property of type `unknown`, which `typeof value.px === 'number'` then narrows to `number`: the function compiles without a single `as`.
- **`asserts value is Mode`**, an [assertion function](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-7.html#assertion-functions), returns only when the condition holds and throws otherwise; after the call, the variable has the narrower type for the rest of the scope, like after a `throw` in the function itself. The function must be declared with an explicit type, a `function` declaration or an annotated `const`, for `tsc` to use it.
- **`tsc` doesn't read the body of a predicate.** `isCameraStateLie` checks only that the value isn't `null`, compiles, and makes `tsc` believe that a string is a camera. A predicate is an assertion with a function around it: the checks inside are what make it true, and they deserve their own tests.

That is the border pattern for data from outside the program, `JSON.parse`, `localStorage`, `fetch`, a SignalR message: an `unknown` on the way in, a predicate or a conversion that checks it, and precise types inside.

## In GuitarAlchemist/ga: statuses that the type rules out

GA's Prime Radiant, a governance graph in [`ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components), declares the health statuses a node can have in [`types.ts`, line 34](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/types.ts#L34):

```ts
export type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
```

[`ForceRadiant.tsx`, lines 720-729](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L720-L729), picks a prediction from that status, and also tests `'ok'` and `'critical'`. `tsc` 7.0.2 reports both, among the errors of lesson 1; the course reproduces the function with the same type:

```ts
// errors/l03_ga_health.ts
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
interface GovernanceNode {
  id: string;
  healthStatus?: GovernanceHealthStatus;
}

function prediction(node: GovernanceNode): string {
  const status = node.healthStatus ?? 'unknown';
  if (status === 'healthy' || status === 'ok') return 'stable';
  if (status === 'warning') return 'at risk';
  if (status === 'error' || status === 'critical') return 'failing';
  return 'uncertain';
}

console.log(prediction({ id: 'policy-7' }));
```

```text
> npx tsc -p out/tsconfig.l03_ga_health.json --pretty
errors/l03_ga_health.ts:10:31 - error TS2367: This comparison appears to be unintentional because the types '"contradictory" | "error" | "unknown" | "warning"' and '"ok"' have no overlap.

10   if (status === 'healthy' || status === 'ok') return 'stable';
                                 ~~~~~~~~~~~~~~~

errors/l03_ga_health.ts:12:29 - error TS2367: This comparison appears to be unintentional because the types '"contradictory" | "unknown"' and '"critical"' have no overlap.

12   if (status === 'error' || status === 'critical') return 'failing';
                               ~~~~~~~~~~~~~~~~~~~~~


Found 2 errors in the same file, starting at: errors/l03_ga_health.ts:10
```

The messages show narrowing at work: after `status === 'healthy'` failed, `status` can no longer be `'healthy'`, and after the `warning` line it can no longer be `'warning'` either. Neither comparison can ever be true for a value of that type. At run time, though, it can, because of where the data comes from. [`DataLoader.ts`, lines 276-278](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L276-L278), receives the `NodeChanged` message of the [SignalR JavaScript client](https://learn.microsoft.com/aspnet/core/signalr/javascript-client) with `healthStatus: string`, and passes it on as `data as unknown as GovernanceNode`:

```ts
// examples/l03_ga_health.ts
import { show } from './show.ts';

// types.ts, line 34: the statuses the front end knows
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
interface GovernanceNode {
  id: string;
  healthStatus?: GovernanceHealthStatus;
}

// DataLoader.ts, lines 276-278: a SignalR message typed with a string, passed on with a double assertion
function onNodeChanged(data: { nodeId: string; healthStatus: string }): GovernanceNode {
  return data as unknown as GovernanceNode;
}

// ForceRadiant.tsx, lines 720-729, reduced: the statuses 'ok' and 'critical' can't be in the union
function prediction(node: GovernanceNode): string {
  const status: string = node.healthStatus ?? 'unknown'; // widened to string, or tsc reports TS2367 below
  if (status === 'healthy' || status === 'ok') return 'stable';
  if (status === 'warning') return 'at risk';
  if (status === 'error' || status === 'critical') return 'failing';
  return 'uncertain';
}

const node = onNodeChanged({ nodeId: 'policy-7', healthStatus: 'critical' });
show('node.healthStatus', node.healthStatus);
show('prediction(node)', prediction(node));
const known: readonly string[] = ['error', 'warning', 'healthy', 'unknown', 'contradictory'];
show('known.includes(node.healthStatus)', known.includes(node.healthStatus ?? 'unknown'));
```

```text
node.healthStatus                  'critical'
prediction(node)                   'failing'
known.includes(node.healthStatus)  false
```

A `'critical'` from the server reaches a `GovernanceNode` whose type says it can't be `'critical'`, and the comparison that `tsc` calls unintentional is the one that handles it. Two readings are possible, and the code doesn't say which is right: the server sends `ok` and `critical` (*to verify* in GA's hub), and the union is missing two members; or it doesn't, and the comparisons are dead code. Either way, the double assertion is where the type stopped describing the data. The third exercise converts the status at that border instead. `ga-react-components` contains 34 `as unknown as`, and the same file restores the camera with [`JSON.parse(saved) as { px: number; … }`, line 3558](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L3555-L3561), the pattern of the `as` section: a saved value that lacks a coordinate would pass `undefined` to `fg.cameraPosition` (*to verify* in a browser); the second exercise checks it.

### Union order in messages

TypeScript 5.9.3, on the same GA file, printed the first union as `"warning" | "error" | "unknown" | "contradictory"`; 7.0.2 prints `"contradictory" | "error" | "unknown" | "warning"`. Neither is the order of the declaration. Up to 6.0, union members were sorted by internal type IDs, assigned in the order the checker met the types; TypeScript 7 checks files in parallel and sorts types by their content instead, so that the output doesn't depend on which thread saw a type first ([6.0 release notes, `--stableTypeOrdering`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html#the---stabletypeordering-flag)). Don't write a test that compares the text of a union in a message or a `.d.ts` across versions.

## On this site: a union inferred from JSON

This site's [`astro.config.mjs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/astro.config.mjs#L1-L4) starts with `// @ts-check`, which asks `tsc` to check a JavaScript file, and imports the generated [`streeling-sidebar.json`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/src/streeling-sidebar.json) into [Starlight's sidebar](https://starlight.astro.build/guides/sidebar/). Running `tsc` 7.0.2 on the site at that commit, with the site's own `tsconfig.json`, reports it:

```text
astro.config.mjs(146,5): error TS2322: Type '{ label: string; collapsed: true; items: ({ label: string; translations: { fr: string; es: string; }; slug: string; collapsed?: undefined; items?: undefined; } | { label: string; translations: { es: string; fr?: undefined; }; slug: string; collapsed?: undefined; items?: undefined; } | { ...; })[]; }' is not assignable to type 'SidebarItemUserConfig'.
  Types of property 'items' are incompatible.
  […]
                Types of property 'translations' are incompatible.
                  Type '{ es: string; fr?: undefined; }' is not assignable to type 'Record<string, string>'.
                    Property '"fr"' is incompatible with index signature.
                      Type 'undefined' is not assignable to type 'string'.
```

A JSON import gets the type of its content, inferred as for an object literal. The array holds entries of different shapes, so its element type is a union, and `tsc` [normalizes object literal types](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-7.html#improved-type-inference-for-object-literals) in a union: a property that one member has and another doesn't is added to the other as optional and `undefined`, so that it can be read on every member. The `Journal` entry has only a Spanish translation, gains `fr?: undefined`, and no longer fits a `Record<string, string>`. Nothing is wrong at run time: the Astro build doesn't run `tsc`, and Starlight validates the sidebar when it loads. It shows the limit of inference for data: a type written by the program, checked against the data at the border, says what the code expects, where an inferred one only says what the file happened to contain.

## Key takeaways

- A union allows only what all its members have; a check narrows it, and `tsc` follows `typeof`, `===`, truthiness, `in`, `instanceof`, `return` and `throw`.
- Truthiness narrowing also removes `0` and `''`; `in` can be fooled by extra properties.
- A discriminated union, a common literal property, is TypeScript's closed hierarchy. End its `switch` with `assertNever`, or declare the return type, and a new member is a compile error, as with Java's sealed interfaces and unlike C#'s warning.
- `as` checks nothing, where C# and Java casts throw; `as unknown as` removes the last check `tsc` makes.
- A type predicate or an assertion function narrows what `tsc` can't follow, and `tsc` trusts its body blindly.
- Data from outside comes in as `unknown` and is checked or converted once, at the border.
- Don't depend on the order of union members in messages or declaration files.

## Exercises

1. Add a `{ kind: 'tie'; beats: number }` event to the `MusicEvent` of [`errors/l03_exhaustive.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors/l03_exhaustive.ts), make both functions compile, and total the beats of a bar.

<details>
<summary>Solution</summary>

[`solutions/l03_ex1_tie.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l03_ex1_tie.ts):

```ts
// solutions/l03_ex1_tie.ts
type MusicEvent =
  | { kind: 'note'; pitch: number; beats: number }
  | { kind: 'chord'; pitches: number[]; beats: number }
  | { kind: 'rest'; beats: number }
  | { kind: 'tie'; beats: number };

function assertNever(value: never): never {
  throw new Error(`unexpected event: ${JSON.stringify(value)}`);
}

function describe(event: MusicEvent): string {
  switch (event.kind) {
    case 'note':
      return `note ${event.pitch} for ${event.beats}`;
    case 'chord':
      return `chord of ${event.pitches.length} for ${event.beats}`;
    case 'rest':
      return `rest for ${event.beats}`;
    case 'tie':
      return `tie for ${event.beats}`;
    default:
      return assertNever(event);
  }
}

// beatsOf needs no switch at all: every member has beats
function beatsOf(event: MusicEvent): number {
  return event.beats;
}

const bar: MusicEvent[] = [
  { kind: 'note', pitch: 60, beats: 2 },
  { kind: 'tie', beats: 1 },
  { kind: 'rest', beats: 1 },
];
console.log(bar.map(describe), bar.reduce((sum, event) => sum + beatsOf(event), 0));
```

```text
[ 'note 60 for 2', 'tie for 1', 'rest for 1' ] 4
```

`beats` is common to all members, so `event.beats` compiles without narrowing, and `beatsOf` has no `switch` left to forget a case in.

</details>

2. GA saves its camera as six numbers, `px`, `py`, `pz` for the position and `lx`, `ly`, `lz` for the target. Write `restoreCamera(saved: string | null): CameraState | undefined`, which returns `undefined` for a missing value, invalid JSON, a missing coordinate, or a coordinate that isn't a finite number, without `as`.

<details>
<summary>Solution</summary>

[`solutions/l03_ex2_camera.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l03_ex2_camera.ts):

```ts
// solutions/l03_ex2_camera.ts
interface CameraState {
  px: number;
  py: number;
  pz: number;
  lx: number;
  ly: number;
  lz: number;
}
const keys = ['px', 'py', 'pz', 'lx', 'ly', 'lz'] as const;

function isCameraState(value: unknown): value is CameraState {
  if (typeof value !== 'object' || value === null) return false;
  const record: { [key: string]: unknown } = { ...value };
  return keys.every((key) => typeof record[key] === 'number' && Number.isFinite(record[key]));
}

// undefined when nothing usable is saved: the caller keeps its default camera
function restoreCamera(saved: string | null): CameraState | undefined {
  if (saved === null) return undefined;
  try {
    const value: unknown = JSON.parse(saved);
    return isCameraState(value) ? value : undefined;
  } catch {
    return undefined; // not JSON at all
  }
}

const good = JSON.stringify({ px: 0, py: 50, pz: 300, lx: 0, ly: 0, lz: 0 });
console.log(restoreCamera(good));
console.log(restoreCamera(null), restoreCamera('{'), restoreCamera('{}'));
console.log(restoreCamera('{"px":0,"py":0,"pz":"300","lx":0,"ly":0,"lz":0}'));
```

```text
{ px: 0, py: 50, pz: 300, lx: 0, ly: 0, lz: 0 }
undefined undefined undefined
undefined
```

Copying the object into a `{ [key: string]: unknown }` with a spread is what lets the predicate loop over the keys: `value` is only known to be an `object`, which has no index signature, and the copy has one whose values are all `unknown`. `Number.isFinite` also rejects `Infinity`, which `JSON.parse` returns for a number too large for a double, such as `1e999` in a hand-edited `localStorage` value.

</details>

3. Write `toHealthStatus(text: string): GovernanceHealthStatus`, which maps `'ok'` to `'healthy'`, `'critical'` to `'error'` and anything unexpected to `'unknown'`, and a table of predictions that `tsc` checks for completeness, without an `if` chain.

<details>
<summary>Solution</summary>

[`solutions/l03_ex3_health.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l03_ex3_health.ts):

```ts
// solutions/l03_ex3_health.ts
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';

// The border: every string the server may send becomes one of the statuses the front end knows
function toHealthStatus(text: string): GovernanceHealthStatus {
  switch (text) {
    case 'healthy':
    case 'ok':
      return 'healthy';
    case 'warning':
      return 'warning';
    case 'error':
    case 'critical':
      return 'error';
    case 'contradictory':
      return 'contradictory';
    default:
      return 'unknown';
  }
}

// Inside, the union is true, and a Record keyed by it must list every status
const predictions: Record<GovernanceHealthStatus, string> = {
  healthy: 'stable',
  warning: 'at risk',
  error: 'failing',
  contradictory: 'uncertain',
  unknown: 'uncertain',
};

for (const text of ['ok', 'critical', 'warning', 'purple']) {
  const status = toHealthStatus(text);
  console.log(text.padEnd(9), status.padEnd(8), predictions[status]);
}
```

```text
ok        healthy  stable
critical  error    failing
warning   warning  at risk
purple    unknown  uncertain
```

The strings of the server are handled in one function, whose return type is the union: inside the program, `status` can only be one of the five values, and `predictions[status]` needs no fallback. A [`Record<GovernanceHealthStatus, string>`](https://www.typescriptlang.org/docs/handbook/utility-types.html#recordkeys-type) must have a property for every member of the union, so a sixth status added to the type makes the table an error until someone decides its prediction. Lesson 4 shows how `Record` is built.

</details>

## Sources

- [TypeScript handbook — Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html), [Everyday types: union types and type assertions](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#union-types), [Utility types](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [TypeScript 3.7 release notes — assertion functions](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-7.html#assertion-functions), [2.7 — object literal inference](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-7.html#improved-type-inference-for-object-literals), [6.0 — `--stableTypeOrdering`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html#the---stabletypeordering-flag)
- [Microsoft — switch expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [type-testing and cast operators](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/type-testing-and-cast)
- [Java — sealed classes and interfaces](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html), [pattern matching for switch](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html)
