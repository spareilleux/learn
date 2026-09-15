---
title: 3. Uniones y narrowing
description: Tipos unión, narrowing con typeof, in, instanceof y el flujo de control, uniones discriminadas y exhaustividad con never, aserciones de tipo que no comprueban nada, predicados de tipo y funciones de aserción — frente a las expresiones switch de C# y las interfaces selladas de Java.
sidebar:
  order: 3
---

Código: los archivos [`examples/l03_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/examples) y [`errors/l03_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors), y los equivalentes en C# y Java en [`compare/l03_switch.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/l03_switch.cs), [`compare/l03_cast.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/l03_cast.cs), [`compare/L03Cast.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/L03Cast.java) y [`compare_fail/L03Sealed.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail/L03Sealed.java).

C# y Java modelan «una de varias cosas» con una jerarquía de clases: una base abstracta, una subclase por caso, y un método virtual o una coincidencia de patrones para distinguirlas. JavaScript no tiene esa jerarquía para la mayoría de sus valores: un traste es un número o la cadena `'open'`, un evento es un objeto cuya propiedad `kind` dice lo que es. TypeScript describe esos valores con **tipos unión**, y sigue las comprobaciones de tu código para saber qué miembro es un valor en cada línea. Esa segunda parte, el ***narrowing***, el estrechamiento del tipo, es el tema de esta lección ([manual: narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)).

## Tipos unión

`A | B` es un valor que es un `A` o un `B`. Antes de una comprobación, solo se permite lo que tienen todos los miembros:

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

`number` tiene `toFixed`, `'open'` y `'muted'` no, así que `Fret` tampoco. El mensaje nombra un miembro al que le falta la propiedad. Una unión de tipos literales, `'open' | 'muted'`, es también la forma en que TypeScript escribe lo que C# y Java harían con un `enum`, sin el objeto en tiempo de ejecución que Node.js se niega a eliminar ([lección 1](../01-compiler-and-tooling/)).

## Narrowing

```ts
// examples/l03_narrowing.ts
import { show } from './show.ts';

// Una unión: un traste es un number, o 'open', o 'muted'
type Fret = number | 'open' | 'muted';

function describe(fret: Fret): string {
  if (typeof fret === 'number') {
    return `fret ${fret.toFixed(0)}`; // aquí fret es un number
  }
  return fret === 'open' ? 'open string' : 'not played'; // aquí fret es 'open' | 'muted'
}
show('describe(3)', describe(3));
show("describe('muted')", describe('muted'));

// Una comprobación truthy también estrecha, y 0 es falsy: la cuerda al aire tocada en el traste 0 desaparece
function label(fret: number | undefined): string {
  if (fret) return `fret ${fret}`;
  return 'no fret';
}
show('label(0)', label(0));
show('label(undefined)', label(undefined));

// in, instanceof y Array.isArray
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

// Flujo de control: después de un return o un throw, el resto de la función sabe más
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

Cada comprobación que JavaScript puede ejecutar se convierte en información para `tsc`:

| Comprobación | Estrecha a | Equivalente en C# / Java |
|---|---|---|
| `typeof fret === 'number'` | `number`, y `'open' \| 'muted'` en el `else` | `fret is int` / `fret instanceof Integer` |
| `fret === 'open'` | el tipo literal `'open'` | `==` sobre una constante |
| `if (fret)` | quita `undefined`, `null` y los tipos literales `0`, `''`, `false` | — |
| `'pitch' in event` | los miembros que declaran `pitch` | — |
| `error instanceof Error` | `Error` | `error is Exception e` / `error instanceof Exception e` |
| `Array.isArray(error)` | `any[]` | — |
| `return`, `throw` | el resto de la función, sin los casos que salieron | asignación definitiva, análisis de flujo |

Dos de esas comprobaciones merecen una advertencia. Una **comprobación truthy** estrecha `number | undefined` a `number`, y el `if (fret)` de `label` también manda el traste `0`, la cuerda al aire, a la rama `'no fret'`: `tsc` lo acepta, porque `0` es un `number`, y el programa está mal. Las reglas son las de la [lección 2 de JavaScript](../../javascript-for-csharp-java/02-values-and-types/#conversiones----análisis-de-texto-y-valores-truthy); compara con `!== undefined` siempre que `0` o `''` sean valores válidos. **`in`** comprueba una propiedad en tiempo de ejecución, y el tipado estructural permite que un objeto tenga más propiedades de las que dice su tipo: un objeto `Chord` que también lleve un `pitch` tomaría la rama `Note`. `in` es fiable cuando los miembros de la unión no pueden tener las propiedades de los otros, que es lo que construye la sección siguiente.

`tsc` sigue el código como lo hace el análisis de asignación definitiva de C#, a través de `return`, `throw`, `&&`, `||` y `?:`: en `parseFret`, `fret` es un `number` después de los dos retornos anticipados, y el `throw` garantiza que es un entero no negativo, un hecho que el tipo `number` no puede expresar.

## Uniones discriminadas

Cuando todos los miembros de una unión tienen la misma propiedad con un tipo literal distinto, comprobar esa propiedad estrecha a un solo miembro. Esa propiedad es el **discriminante**, aquí `kind`:

```ts
// examples/l03_discriminated.ts
import { show } from './show.ts';

// Una unión discriminada: cada miembro tiene un kind, con un tipo literal distinto
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
      return assertNever(event); // aquí event es never: se tratan todos los kind
  }
}

const bar: MusicEvent[] = [
  { kind: 'chord', pitches: [48, 52, 55], beats: 2 },
  { kind: 'note', pitch: 60, beats: 1 },
  { kind: 'rest', beats: 1 },
];
for (const event of bar) show(event.kind, describe(event));

// La comprobación que tsc hizo en tiempo de compilación sigue ejecutándose, para los datos que no pasaron por tsc
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

Dentro de `case 'note':`, `event` es `{ kind: 'note'; pitch: number; beats: number }`, y `event.pitch` compila; en `case 'rest':` no compilaría. Después de los tres casos no queda nada: `event` tiene el tipo `never`, y `assertNever(event)` compila porque un `never` es asignable al parámetro `never`. En tiempo de ejecución la rama `default` sigue existiendo, y atrapa lo que los tipos no vieron: se afirmó que `fromServer` era un `MusicEvent`, llegó con el kind `'tie'` y alcanzó `assertNever`.

Una unión discriminada es la versión de TypeScript de una jerarquía cerrada, un `abstract record` de C# con sus records derivados, o una `sealed interface` de Java con sus implementaciones `record`. Los datos son objetos simples, que es lo que devuelve `JSON.parse` y lo que envía un servidor.

## Exhaustividad

Añade un miembro, y todo `switch` que no lo trate debería dejar de compilar. Con `assertNever` en el `default`, o con un tipo de retorno declarado, así ocurre:

```ts
// errors/l03_exhaustive.ts
// Un nuevo tipo de evento: las dos funciones que no lo tratan son ahora errores
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

El primer error dice que un evento `tie` llega a un parámetro que no acepta nada. El segundo viene del tipo de retorno: `beatsOf` promete un `number`, y un evento `tie` atravesaría el `switch` y devolvería `undefined`. Sin `assertNever`, una función sin tipo de retorno declarado, o una que devuelve `void`, compila sin ningún mensaje ([comprobación de exhaustividad](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#exhaustiveness-checking)).

El mismo cambio en C#, con una [expresión switch](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) sobre records, es una advertencia:

```text
> dotnet run l03_switch.cs
compare/l03_switch.cs(10,43): warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern '_' is not covered.
chord of 3
note 60
SwitchExpressionException
```

C# no puede saber que ninguna otra clase deriva de `MusicEvent`, así que pide un caso `_`, compila de todos modos y lanza [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception) con el `Tie`. Las [interfaces selladas](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) de Java cierran la jerarquía, y un [`switch` con patrones](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html) sobre una de ellas se comprueba como TypeScript comprueba una unión:

```text
> javac L03Sealed.java
L03Sealed.java:10: error: the switch expression does not cover all possible input values
        return switch (e) {
               ^
1 error
```

| | C# | Java | TypeScript |
|---|---|---|---|
| Conjunto cerrado de casos | no hay jerarquías cerradas en C# 14: se espera un caso `_` | `sealed interface … permits` | un tipo unión |
| Caso que falta | advertencia CS8509, `SwitchExpressionException` en tiempo de ejecución | error de compilación | error, si el `switch` termina en `assertNever` o la función declara su tipo de retorno |
| Datos de fuera | deserializados en las clases | deserializados en los records | objetos simples: hay que comprobar el discriminante |

## as no comprueba nada

Los casts de C# y Java se comprueban al ejecutarse. Una **aserción de tipo** de TypeScript, `value as T`, es un mensaje para `tsc` y desaparece con los demás tipos:

```ts
// examples/l03_guards.ts, líneas 11-13
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

El `(CameraState)parsed` de C# lanza `InvalidCastException`, `as` devuelve `null`, y el cast de Java lanza `ClassCastException`: el runtime conoce la clase de cada objeto. Un objeto JavaScript obtenido de un JSON no tiene clase con la que comparar, y `as` no lo intenta. `tsc` solo rechaza una aserción entre dos tipos que no se solapan en absoluto, y `as unknown as T` pasa por `unknown` para sortear ese rechazo ([aserciones de tipo](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions)). El número `NaN` que salió de `trusted.pz * 2` es el tipo de valor que viaja lejos de la línea que lo produjo.

## Predicados de tipo y funciones de aserción

Una comprobación que `tsc` no puede leer en una sola expresión va a una función cuyo tipo de retorno dice lo que prueba:

```ts
// examples/l03_guards.ts
import { attempt, show } from './show.ts';

interface CameraState {
  px: number;
  py: number;
  pz: number;
}

// as no es un cast: no convierte nada y no comprueba nada
const trusted = JSON.parse('{"px": 1, "py": 2}') as CameraState;
show('trusted.pz', trusted.pz);
show('trusted.pz * 2', trusted.pz * 2);

// Un predicado de tipo: una función que devuelve un boolean, y le dice a tsc qué significa true
function isCameraState(value: unknown): value is CameraState {
  return (
    typeof value === 'object' &&
    value !== null &&
    'px' in value &&
    typeof value.px === 'number' && // después de 'px' in value, tsc sabe que value tiene una propiedad px de tipo unknown
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

// Una función de aserción: solo retorna si la condición se cumple, y lanza una excepción en caso contrario
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
show('brightness(fromUrl)', brightness(fromUrl)); // fromUrl es un Mode después de la aserción
attempt("assertMode('locrian')", () => assertMode('locrian'));

// tsc confía en un predicado sin leerlo: uno erróneo es una mentira que compila
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

- **`value is CameraState`**, un [predicado de tipo](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#using-type-predicates), devuelve un `boolean`, y en la rama donde devolvió `true`, el argumento es un `CameraState`. Dentro de `isCameraState`, cada `'px' in value` estrecha `value` a un objeto con una propiedad `px` de tipo `unknown`, que `typeof value.px === 'number'` estrecha luego a `number`: la función compila sin un solo `as`.
- **`asserts value is Mode`**, una [función de aserción](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-7.html#assertion-functions), solo retorna cuando la condición se cumple y lanza una excepción en caso contrario; después de la llamada, la variable tiene el tipo más estrecho durante el resto del ámbito, como después de un `throw` en la propia función. La función debe declararse con un tipo explícito, una declaración `function` o una `const` anotada, para que `tsc` la use.
- **`tsc` no lee el cuerpo de un predicado.** `isCameraStateLie` solo comprueba que el valor no es `null`, compila, y hace creer a `tsc` que una cadena es una cámara. Un predicado es una aserción envuelta en una función: las comprobaciones de dentro son lo que la hace verdadera, y merecen sus propias pruebas.

Ese es el patrón de la frontera para los datos que vienen de fuera del programa, `JSON.parse`, `localStorage`, `fetch`, un mensaje SignalR: un `unknown` a la entrada, un predicado o una conversión que lo comprueba, y tipos precisos dentro.

## En GuitarAlchemist/ga: estados que el tipo excluye

El Prime Radiant de GA, un grafo de gobernanza en [`ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components), declara los estados de salud que puede tener un nodo en [`types.ts`, línea 34](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/types.ts#L34):

```ts
export type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
```

[`ForceRadiant.tsx`, líneas 720-729](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L720-L729), elige una predicción a partir de ese estado, y también prueba `'ok'` y `'critical'`. `tsc` 7.0.2 señala las dos, entre los errores de la lección 1; el curso reproduce la función con el mismo tipo:

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

Los mensajes muestran el *narrowing* en acción: después de que `status === 'healthy'` fallara, `status` ya no puede ser `'healthy'`, y después de la línea `warning` tampoco puede ser `'warning'`. Ninguna de las dos comparaciones puede ser verdadera para un valor de ese tipo. En tiempo de ejecución, sin embargo, sí puede, por el origen de los datos. [`DataLoader.ts`, líneas 276-278](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L276-L278), recibe el mensaje `NodeChanged` del [cliente JavaScript de SignalR](https://learn.microsoft.com/aspnet/core/signalr/javascript-client) con `healthStatus: string`, y lo transmite como `data as unknown as GovernanceNode`:

```ts
// examples/l03_ga_health.ts
import { show } from './show.ts';

// types.ts, línea 34: los estados que conoce el front end
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
interface GovernanceNode {
  id: string;
  healthStatus?: GovernanceHealthStatus;
}

// DataLoader.ts, líneas 276-278: un mensaje SignalR tipado con un string, transmitido con una doble aserción
function onNodeChanged(data: { nodeId: string; healthStatus: string }): GovernanceNode {
  return data as unknown as GovernanceNode;
}

// ForceRadiant.tsx, líneas 720-729, reducido: los estados 'ok' y 'critical' no pueden estar en la unión
function prediction(node: GovernanceNode): string {
  const status: string = node.healthStatus ?? 'unknown'; // ampliado a string, o tsc señala TS2367 más abajo
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

Un `'critical'` del servidor llega a un `GovernanceNode` cuyo tipo dice que no puede ser `'critical'`, y la comparación que `tsc` llama no intencionada es la que lo trata. Caben dos lecturas, y el código no dice cuál es la correcta: el servidor envía `ok` y `critical` (*por verificar* en el hub de GA), y a la unión le faltan dos miembros; o no los envía, y las comparaciones son código muerto. En cualquier caso, la doble aserción es donde el tipo dejó de describir los datos. El tercer ejercicio, en cambio, convierte el estado en esa frontera. `ga-react-components` contiene 34 `as unknown as`, y el mismo archivo restaura la cámara con [`JSON.parse(saved) as { px: number; … }`, línea 3558](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L3555-L3561), el patrón de la sección sobre `as`: un valor guardado al que le faltara una coordenada pasaría `undefined` a `fg.cameraPosition` (*por verificar* en un navegador); el segundo ejercicio lo comprueba.

### Orden de la unión en los mensajes

TypeScript 5.9.3, sobre el mismo archivo de GA, imprimió la primera unión como `"warning" | "error" | "unknown" | "contradictory"`; 7.0.2 imprime `"contradictory" | "error" | "unknown" | "warning"`. Ninguno de los dos es el orden de la declaración. Hasta la 6.0, los miembros de una unión se ordenaban por identificadores internos de tipo, asignados en el orden en que el verificador encontraba los tipos; TypeScript 7 verifica los archivos en paralelo y ordena los tipos por su contenido, para que la salida no dependa de qué hilo vio primero un tipo ([notas de la versión 6.0, `--stableTypeOrdering`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html#the---stabletypeordering-flag)). No escribas una prueba que compare el texto de una unión en un mensaje o en un `.d.ts` entre versiones.

## En este sitio: una unión inferida a partir de JSON

El [`astro.config.mjs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/astro.config.mjs#L1-L4) de este sitio empieza con `// @ts-check`, que pide a `tsc` que verifique un archivo JavaScript, e importa el [`streeling-sidebar.json`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/src/streeling-sidebar.json) generado en la [barra lateral de Starlight](https://starlight.astro.build/guides/sidebar/). Ejecutar `tsc` 7.0.2 sobre el sitio en ese commit, con el propio `tsconfig.json` del sitio, lo señala:

```text
astro.config.mjs(146,5): error TS2322: Type '{ label: string; collapsed: true; items: ({ label: string; translations: { fr: string; es: string; }; slug: string; collapsed?: undefined; items?: undefined; } | { label: string; translations: { es: string; fr?: undefined; }; slug: string; collapsed?: undefined; items?: undefined; } | { ...; })[]; }' is not assignable to type 'SidebarItemUserConfig'.
  Types of property 'items' are incompatible.
  […]
                Types of property 'translations' are incompatible.
                  Type '{ es: string; fr?: undefined; }' is not assignable to type 'Record<string, string>'.
                    Property '"fr"' is incompatible with index signature.
                      Type 'undefined' is not assignable to type 'string'.
```

Una importación JSON recibe el tipo de su contenido, inferido como para un literal de objeto. El array contiene entradas de formas distintas, así que su tipo de elemento es una unión, y `tsc` [normaliza los tipos de los literales de objeto](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-7.html#improved-type-inference-for-object-literals) en una unión: una propiedad que tiene un miembro y otro no se añade a este como opcional y `undefined`, para que pueda leerse en todos los miembros. La entrada `Journal` solo tiene traducción al español, gana `fr?: undefined`, y ya no encaja en un `Record<string, string>`. En tiempo de ejecución no hay ningún problema: el build de Astro no ejecuta `tsc`, y Starlight valida la barra lateral cuando la carga. Muestra el límite de la inferencia para los datos: un tipo escrito por el programa, comprobado contra los datos en la frontera, dice lo que el código espera, mientras que uno inferido solo dice lo que el archivo contenía por casualidad.

## Puntos clave

- Una unión solo permite lo que tienen todos sus miembros; una comprobación la estrecha, y `tsc` sigue `typeof`, `===`, las comprobaciones truthy, `in`, `instanceof`, `return` y `throw`.
- Una comprobación truthy también quita `0` y `''`; `in` puede engañarse con propiedades adicionales.
- Una unión discriminada, con una propiedad literal común, es la jerarquía cerrada de TypeScript. Termina su `switch` con `assertNever`, o declara el tipo de retorno, y un miembro nuevo es un error de compilación, como con las interfaces selladas de Java y a diferencia de la advertencia de C#.
- `as` no comprueba nada, mientras que los casts de C# y Java lanzan excepciones; `as unknown as` quita la última comprobación que hace `tsc`.
- Un predicado de tipo o una función de aserción estrecha lo que `tsc` no puede seguir, y `tsc` confía ciegamente en su cuerpo.
- Los datos de fuera entran como `unknown` y se comprueban o convierten una sola vez, en la frontera.
- No dependas del orden de los miembros de una unión en los mensajes o en los archivos de declaración.

## Ejercicios

1. Añade un evento `{ kind: 'tie'; beats: number }` al `MusicEvent` de [`errors/l03_exhaustive.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors/l03_exhaustive.ts), haz que compilen las dos funciones, y suma los tiempos de un compás.

<details>
<summary>Solución</summary>

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

// beatsOf no necesita ningún switch: todos los miembros tienen beats
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

`beats` es común a todos los miembros, así que `event.beats` compila sin *narrowing*, y a `beatsOf` no le queda ningún `switch` en el que olvidar un caso.

</details>

2. GA guarda su cámara como seis números, `px`, `py`, `pz` para la posición y `lx`, `ly`, `lz` para el objetivo. Escribe `restoreCamera(saved: string | null): CameraState | undefined`, que devuelve `undefined` para un valor ausente, un JSON no válido, una coordenada que falta o una coordenada que no es un número finito, sin `as`.

<details>
<summary>Solución</summary>

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

// undefined cuando no hay nada utilizable guardado: quien llama conserva su cámara por defecto
function restoreCamera(saved: string | null): CameraState | undefined {
  if (saved === null) return undefined;
  try {
    const value: unknown = JSON.parse(saved);
    return isCameraState(value) ? value : undefined;
  } catch {
    return undefined; // no es JSON en absoluto
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

Copiar el objeto en un `{ [key: string]: unknown }` con un spread es lo que permite al predicado recorrer las claves: de `value` solo se sabe que es un `object`, que no tiene firma de índice, y la copia tiene una cuyos valores son todos `unknown`. `Number.isFinite` también rechaza `Infinity`, que `JSON.parse` devuelve para un número demasiado grande para un double, como `1e999` en un valor de `localStorage` editado a mano.

</details>

3. Escribe `toHealthStatus(text: string): GovernanceHealthStatus`, que convierte `'ok'` en `'healthy'`, `'critical'` en `'error'` y cualquier cosa inesperada en `'unknown'`, y una tabla de predicciones cuya completitud comprueba `tsc`, sin una cadena de `if`.

<details>
<summary>Solución</summary>

[`solutions/l03_ex3_health.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l03_ex3_health.ts):

```ts
// solutions/l03_ex3_health.ts
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';

// La frontera: toda cadena que el servidor pueda enviar se convierte en uno de los estados que conoce el front end
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

// Dentro, la unión es cierta, y un Record indexado por ella debe enumerar todos los estados
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

Las cadenas del servidor se tratan en una sola función, cuyo tipo de retorno es la unión: dentro del programa, `status` solo puede ser uno de los cinco valores, y `predictions[status]` no necesita valor por defecto. Un [`Record<GovernanceHealthStatus, string>`](https://www.typescriptlang.org/docs/handbook/utility-types.html#recordkeys-type) debe tener una propiedad para cada miembro de la unión, así que un sexto estado añadido al tipo convierte la tabla en un error hasta que alguien decida su predicción. La lección 4 muestra cómo se construye `Record`.

</details>

## Fuentes

- [Manual de TypeScript — Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html), [Tipos cotidianos: tipos unión y aserciones de tipo](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#union-types), [Tipos utilitarios](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [Notas de la versión 3.7 de TypeScript — funciones de aserción](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-7.html#assertion-functions), [2.7 — inferencia para literales de objeto](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-7.html#improved-type-inference-for-object-literals), [6.0 — `--stableTypeOrdering`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html#the---stabletypeordering-flag)
- [Microsoft — expresión switch](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [operadores de prueba de tipos y de conversión](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/type-testing-and-cast)
- [Java — clases e interfaces selladas](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html), [coincidencia de patrones para switch](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html)
