---
title: 2. Tipado estructural
description: Anotaciones e inferencia, tipado estructural frente a nominal, interface y type, comprobación de propiedades sobrantes, readonly, tuplas, any, unknown y never, y strictNullChecks — cada uno comparado con C# y Java, con los diagnósticos reales de tsc.
sidebar:
  order: 2
---

Código: los archivos [`examples/l02_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/examples) y [`errors/l02_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors), y los equivalentes en C# y Java en [`compare/l02_nullable.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/l02_nullable.cs), [`compare/L02Nullable.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/L02Nullable.java), [`compare_fail/l02_nominal.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail/l02_nominal.cs) y [`compare_fail/L02Nominal.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail/L02Nominal.java).

Los ejemplos imprimen sus resultados con las funciones auxiliares `show` y `attempt` de la [lección 2 de JavaScript](../../javascript-for-csharp-java/02-values-and-types/), ahora con tipos. `err` en un `catch` tiene el tipo `unknown`, porque JavaScript puede lanzar cualquier valor, y la función auxiliar comprueba que es un `Error` antes de leer su `message`:

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
    // err es unknown: se puede lanzar cualquier cosa, no solo un Error (la lección 3 lo estrecha)
    console.log(`${label.padEnd(34)} ${err instanceof Error ? `${err.name}: ${err.message}` : String(err)}`);
  }
}
```

## Anotaciones e inferencia

Una anotación es dos puntos y un tipo después de un nombre: `let count: number`. La mayoría de las veces no escribes ninguna, porque `tsc` infiere el tipo a partir del valor, como hace `var` en C# y Java. La forma más rápida de ver lo que `tsc` infirió, fuera de un editor, es pedirle un archivo de declaración: `tsc --declaration` escribe el tipo de todo lo que exporta un módulo.

```ts
// examples/l02_inference.ts
// tsc --declaration escribe los tipos que infirió en l02_inference.d.ts (ver check.sh)
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
// out/dts/examples/l02_inference.d.ts, escrito por tsc --declaration --emitDeclarationOnly
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

Una parte es lo que C# inferiría, y otra no:

- `count` es un `number`, pero `tuning` tiene el tipo `"EADGBE"`: un **tipo literal**, cuyo único valor es esa cadena. Un `const` no puede cambiar, así que `tsc` conserva el tipo más estrecho. Un `let` recibe el tipo más amplio, `number` o `string`, ya que puede reasignarse.
- Las propiedades de `capo` se amplían a `number` y `string`, porque las propiedades de un objeto pueden reasignarse aunque la variable sea `const`. `Object.freeze` y `as const` conservan los tipos literales, y añaden `readonly`.
- `mixed` es un array de `string | number | null`: una **unión** de los tipos de los elementos, donde C# rechaza `new[] { 1, "two", null }` por falta de un mejor tipo común (*por verificar*). Las uniones son el tema de la [lección 3](../03-unions-and-narrowing/).
- `fretOf` tiene un tipo de retorno inferido, `number | undefined`, ya que una rama devuelve `undefined`.
- `parsed` es `any`, porque `JSON.parse` está declarado para devolver `any`. La sección sobre `any`, más abajo, explica por qué importa.

El estilo habitual es anotar aquello de lo que depende otro código, los parámetros y los tipos de retorno de las funciones exportadas, y dejar que `tsc` infiera las variables locales. Los parámetros hay que anotarlos de todos modos: `tsc` no infiere el tipo de un parámetro a partir de las llamadas.

| | C# | Java | TypeScript |
|---|---|---|---|
| Números | `int`, `long`, `double`, `decimal`… | `int`, `long`, `double`… | `number`, `bigint` |
| Texto | `string`, `char` | `String`, `char` | `string`, sin tipo carácter |
| Valor ausente | `null` | `null` | `null` y `undefined`, dos tipos |
| Cualquier valor, comprobado antes de usarlo | `object` | `Object` | `unknown` |
| Cualquier valor, sin comprobaciones | `dynamic` | — | `any` |
| Ningún valor | `void` como tipo de retorno | `void` | `void` como tipo de retorno, `never` para un valor que no puede existir |
| Un valor concreto | — | — | un tipo literal: `'EADGBE'`, `2`, `true` |

## Tipado estructural

Los tipos de C# y Java son **nominales**: una clase es compatible con una interfaz porque lo declara, `class Vector : IPoint`. Los tipos de TypeScript son **estructurales**: un valor es compatible con un tipo cuando tiene las propiedades correctas con los tipos correctos, diga lo que diga su declaración ([compatibilidad de tipos](https://www.typescriptlang.org/docs/handbook/type-compatibility.html)).

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

// Una clase nunca menciona Point, y sus instancias son Points de todos modos: solo cuenta la forma
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

// interface y type describen la misma forma: los dos nombres son intercambiables
type PointAlias = { x: number; y: number };
const alias: PointAlias = { x: 6, y: 8 };
const point: Point = alias;
show('length(point)', length(point));

// Dos clases con la misma forma son el mismo tipo, digan lo que digan sus nombres
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

// Un tipo con marca: un number que solo una función puede producir
type Kelvin = number & { readonly brand: 'Kelvin' };
function kelvin(value: number): Kelvin {
  if (value < 0) throw new RangeError('below absolute zero');
  return value as Kelvin; // el único lugar donde se afirma la marca
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

`Vector` nunca menciona `Point`, y sus instancias se aceptan donde se espera un `Point`, con la propiedad adicional `z`. Eso es lo que hace que TypeScript encaje con JavaScript, donde la mayoría de los objetos son literales sin clase. El coste es la segunda mitad del ejemplo: `Celsius` y `Fahrenheit` tienen la misma forma, así que son el mismo tipo para `tsc`, y se da por hecho que una temperatura de 150 °F hierve. `instanceof` sigue distinguiéndolos en tiempo de ejecución, porque la cadena de prototipos es real, pero los tipos no. El mismo código en C# y Java:

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

Cuando un tipo necesita un nombre, dos técnicas se lo dan. Un **tipo con marca** (*branded type*) interseca un primitivo con una propiedad que ningún valor simple tiene, `number & { readonly brand: 'Kelvin' }`, de modo que solo una función que afirma la marca produce uno; en tiempo de ejecución, `room` es un número simple. Y un **campo privado** `#value` hace nominal una clase, porque ninguna otra clase puede tener ese campo:

```ts
// errors/l02_nominal.ts
// Un campo #private hace nominal una clase: ninguna otra clase, por parecida que sea, tiene ese campo
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

La palabra clave `private` propia de TypeScript tiene el mismo efecto sobre la compatibilidad, pero solo la comprueba `tsc`; `#value` también la impone el motor ([lección 4 de JavaScript](../../javascript-for-csharp-java/04-objects-prototypes-classes/#clases)).

### interface o type

`interface Point { x: number; y: number }` y `type Point = { x: number; y: number }` describen la misma forma, y el ejemplo asigna uno al otro sin ninguna queja. Las diferencias están en otra parte ([tipos cotidianos](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#differences-between-type-aliases-and-interfaces)):

| | `interface` | `type` |
|---|---|---|
| Formas de objeto | sí | sí |
| Uniones, tuplas, primitivos, tipos mapeados | no | sí: `type Fret = number \| 'open'` |
| Extensión | `interface Guitar extends Instrument` | una intersección: `type Guitar = Instrument & { strings: number }` |
| Dos declaraciones con el mismo nombre | fusionadas en una sola interfaz | un error |

La fusión de declaraciones es la manera en que las bibliotecas te permiten añadir una propiedad a un tipo global, y rara vez es lo que quiere una aplicación. Una regla razonable, y la que sigue este curso: `interface` para las formas de objeto, `type` para todo lo demás.

## Comprobación de propiedades sobrantes

El tipado estructural acepta propiedades adicionales, con una excepción:

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

// Un literal de objeto escrito donde se espera un SceneOptions: una propiedad desconocida es un error
console.log(describe({ stars: false, towr: true }));

// El mismo objeto, primero en una variable: sin comprobación de propiedades sobrantes, y la errata se ignora en silencio
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

Un literal de objeto escrito directamente donde se espera un tipo es *fresco*, y `tsc` comprueba si tiene propiedades que el tipo no tiene, ya que nada más podrá leerlas nunca. El mismo objeto guardado antes en una variable ya no es fresco: podría usarse en otro sitio, donde `towr` significa algo, así que `tsc` lo acepta, y la errata se pierde sin ningún mensaje. Con todas las propiedades opcionales, como en un objeto de opciones, es el caso en que una errata cuesta más. Pasa las opciones como literales, o anota la variable, `const fromUrl: SceneOptions = { … }`, lo que vuelve a hacer fresco el literal.

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

`readonly` en una propiedad, y `readonly string[]` para un array, quitan las escrituras del tipo, como hace `IReadOnlyList<T>` en C#: un `readonly string[]` no tiene `push`. Y como con `IReadOnlyList<T>`, es una vista, no un objeto inmutable:

```ts
// examples/l02_readonly.ts
import { attempt, show } from './show.ts';

interface Tuning {
  readonly name: string;
  readonly notes: readonly string[];
}

// readonly solo lo comprueba tsc: nada se congela en tiempo de ejecución
const standard: Tuning = { name: 'standard', notes: ['E', 'A', 'D', 'G', 'B', 'E'] };

// Un tipo readonly es asignable a uno mutable con las mismas propiedades: el alias puede escribir
const writable: { name: string } = standard;
writable.name = 'drop D';
show('standard.name', standard.name);

// Object.freeze da las dos cosas: un Readonly<T> para tsc, y un objeto congelado para el motor
const frozen = Object.freeze({ name: 'open G', notes: ['D', 'G', 'D', 'G', 'B', 'D'] });
attempt("frozen.name = 'x', after a cast", () => {
  (frozen as { name: string }).name = 'x';
});
frozen.notes.push('shallow'); // freeze es superficial, y Readonly<T> también
show('frozen.notes.length', frozen.notes.length);

// as const: los tipos literales más estrechos, y readonly hasta el fondo
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

- Nada se congela en tiempo de ejecución: `readonly` desaparece con los demás tipos, y la ejecución con `node` de arriba lo modificó todo.
- Un tipo readonly es asignable al mismo tipo sin `readonly`, así que un alias puede escribir lo que el original no podía. `tsc` acepta `const writable: { name: string } = standard`, y `standard.name` cambia.
- `Object.freeze` da las dos mitades: su tipo de retorno es `Readonly<…>`, y el motor rechaza la escritura, aquí a través de una aserción de tipo que silencia a `tsc`. Las dos son superficiales, como en JavaScript.
- `as const` hace un literal readonly hasta el fondo, con tipos literales. `(typeof modes)[number]` convierte los elementos del array en un tipo unión, `'ionian' | 'dorian' | 'phrygian'`, el sustituto de un `enum` que usó el segundo ejercicio de la [lección 1](../01-compiler-and-tooling/).

## Tuplas e índices

```ts
// examples/l02_tuples.ts
import { show } from './show.ts';

// Una tupla: una longitud fija, y un tipo para cada posición
type Interval = [name: string, semitones: number];
const fifth: Interval = ['perfect fifth', 7];
const [name, semitones] = fifth;
show('name, semitones', [name, semitones]);

// Un array: cualquier longitud, un solo tipo de elemento, y un índice en el que tsc confía
const strings: string[] = ['E', 'A', 'D', 'G', 'B', 'E'];
const seventh: string = strings[6]; // ningún error sin noUncheckedIndexedAccess
show('seventh', seventh);
show('typeof seventh', typeof seventh);

const counts = new Map<string, number>([['E', 2]]);
const count = counts.get('A'); // Map.get lo admite: number | undefined
show('count ?? 0', count ?? 0);

// Las tuplas son arrays en tiempo de ejecución: nada impide un push
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

Un tipo tupla fija la longitud y el tipo de cada posición, y sus etiquetas, `name` y `semitones`, son documentación. En tiempo de ejecución es un array, y `push` funciona: el tipo solo protege las posiciones que declara.

`strings[6]` tiene el tipo `string`, y contiene `undefined`. Por defecto `tsc` confía en un índice en un array o en un diccionario, donde C# lanzaría `IndexOutOfRangeException` para un array y `KeyNotFoundException` para un diccionario, y Java `ArrayIndexOutOfBoundsException`. `Map.get` está declarado con honestidad, `number | undefined`, pero un índice de array o una clave de `Record` no. La opción [`noUncheckedIndexedAccess`](https://www.typescriptlang.org/tsconfig/#noUncheckedIndexedAccess) añade `undefined` a cada acceso por índice. No forma parte de `strict`, y `tsc --init` la activa:

```ts
// errors/l02_index.ts
// opciones de tsc: --noUncheckedIndexedAccess
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

Sin la opción, `tsc` no imprime nada y el programa falla en la primera línea que usa el elemento que falta. Con ella, cada índice necesita una comprobación, lo que resulta ruidoso en los bucles sobre índices conocidos y adecuado en las búsquedas por clave.

## any, unknown y never

```ts
// examples/l02_any_unknown.ts
import { attempt, show } from './show.ts';

const saved = '{"stars": "yes", "tower": true}';

// JSON.parse devuelve any: todo uso compila, y any se propaga a lo que toca
const options = JSON.parse(saved);
const stars: boolean = options.stars; // ningún error: any es asignable a todo
show('stars', stars);
show('typeof stars', typeof stars);
attempt('options.weather.level', () => options.weather.level);

// unknown también acepta cualquier valor, pero no se puede hacer nada con él antes de una comprobación
const checked: unknown = JSON.parse(saved);
if (typeof checked === 'object' && checked !== null && 'stars' in checked) {
  show("typeof checked.stars", typeof checked.stars);
}

// never: una función que no retorna, y un valor que no puede existir
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

**`any`** desactiva el verificador para un valor. `options` es `any` porque `JSON.parse` devuelve `any`, así que `options.stars` también es `any`, y `any` es asignable a todos los tipos: `stars` está declarado `boolean` y contiene la cadena `'yes'`, y `options.weather.level` compila y lanza una excepción. `any` se comporta como el [`dynamic`](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interop/using-type-dynamic) de C#, con una diferencia: C# enlaza una operación `dynamic` cuando se ejecuta y lanza `RuntimeBinderException` para un miembro que no existe, mientras que JavaScript lee `undefined` y sigue adelante. Se propaga en silencio desde las funciones que lo devuelven, `JSON.parse`, `response.json()` y las partes sin tipos de las bibliotecas, a todo lo que toca.

**`unknown`** también acepta todos los valores, y no permite nada hasta que una comprobación lo ha *estrechado*, como `object` en C#:

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

En el ejemplo, `typeof checked === 'object'`, `!== null` y `'stars' in checked` estrechan `checked` paso a paso, hasta que `checked.stars` compila. La [lección 3](../03-unions-and-narrowing/) trata de esas comprobaciones. Escribe `const value: unknown = JSON.parse(text)`: la anotación convierte el `any` en un `unknown` en el acto, y `tsc` pide entonces una comprobación antes de cada uso.

**`never`** es el tipo sin valores. Una función que siempre lanza una excepción devuelve `never`, como un método de C# marcado con [`[DoesNotReturn]`](https://learn.microsoft.com/dotnet/api/system.diagnostics.codeanalysis.doesnotreturnattribute), y un `never` es asignable a todos los tipos, por eso `fail(…)` cabe en la rama `boolean` de `starsOf`. La lección 3 usa `never` para comprobar que un `switch` trata todos los casos.

## null y undefined

Con `strictNullChecks`, que forma parte de `strict`, `null` y `undefined` son tipos separados, y `string` no los incluye. Un valor que puede estar ausente lo dice, `string | undefined`, o `name?: string` para un parámetro o una propiedad opcional:

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

La solución es el *narrowing*, el estrechamiento del tipo, de la lección 3, o los operadores que introdujo la [lección 2 de JavaScript](../../javascript-for-csharp-java/02-values-and-types/#undefined-y-null):

```ts
// examples/l02_null.ts
import { attempt, show } from './show.ts';

function initial(name?: string): string {
  return name === undefined ? '?' : name.charAt(0); // estrechado: name es un string en la segunda rama
}
show('initial()', initial());
show("initial('Ada')", initial('Ada'));

const tunings = new Map([['standard', 'EADGBE']]);
show("tunings.get('drop D')?.length", tunings.get('drop D')?.length);
show("tunings.get('drop D') ?? 'DADGBE'", tunings.get('drop D') ?? 'DADGBE');

// La aserción de no nulo ! silencia a tsc, y no comprueba nada
attempt("tunings.get('drop D')!.length", () => tunings.get('drop D')!.length);
```

```text
initial()                          '?'
initial('Ada')                     'A'
tunings.get('drop D')?.length      undefined
tunings.get('drop D') ?? 'DADGBE'  'DADGBE'
tunings.get('drop D')!.length      TypeError: Cannot read properties of undefined (reading 'length')
```

Los [tipos de referencia que aceptan valores NULL](https://learn.microsoft.com/dotnet/csharp/nullable-references) de C# son la misma idea, con el mismo operador `!`, pero producen advertencias:

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

| | C# con `<Nullable>enable</Nullable>` | Java | TypeScript con `strictNullChecks` |
|---|---|---|---|
| Un tipo que puede estar ausente | `string?` | nada en el tipo; anotaciones como `@Nullable` de [JSpecify](https://jspecify.dev/) | `string \| undefined`, `string \| null`, `name?: string` |
| Usarlo sin comprobación | advertencia CS8602, el programa compila | nada, hasta `NullPointerException` | error TS18048, y el programa se ejecuta igualmente |
| «Confía en mí» | `name!` | — | `name!` |
| En tiempo de ejecución | `NullReferenceException` | `NullPointerException` | `TypeError: Cannot read properties of undefined` |

Tanto en C# como en TypeScript, `!` solo silencia al compilador: `tunings.get('drop D')!.length` compila y lanza una excepción. Úsalo donde sabes algo que el verificador no puede saber, y prefiere una comprobación que diga qué debe pasar cuando te equivocas.

## La familia strict

`strict` activa ocho opciones, enumeradas en el código fuente del compilador como las [opciones `strictFlag`](https://github.com/microsoft/TypeScript/blob/v6.0.3/src/compiler/commandLineParser.ts):

| Opción | Qué comprueba | Lección |
|---|---|---|
| `strictNullChecks` | `null` y `undefined` son tipos separados | esta |
| `noImplicitAny` | un parámetro o una variable cuyo tipo no se puede inferir debe anotarse | esta |
| `useUnknownInCatchVariables` | la variable de un `catch` es `unknown`, no `any` | la función auxiliar `attempt` de arriba |
| `strictFunctionTypes` | los tipos de función se comprueban de forma contravariante en sus parámetros | [4](../04-generics/) |
| `strictBindCallApply` | `bind`, `call` y `apply` comprueban sus argumentos | — |
| `strictPropertyInitialization` | un campo de clase debe inicializarse, en su declaración o en el constructor | — |
| `strictBuiltinIteratorReturn` | el valor `return` de los iteradores integrados es `undefined`, no `any` | — |
| `noImplicitThis` | `this` debe tener un tipo conocido en una función | — |

Un proyecto puede poner `"strict": true` y volver a desactivar una de ellas, y es lo primero que hay que buscar en un `tsconfig.json` existente.

## En GuitarAlchemist/ga: noImplicitAny desactivado

[`ga-react-components/tsconfig.app.json`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/tsconfig.app.json#L17-L20) pone `"noImplicitAny": false` tres líneas por encima de `"strict": true`. El archivo se lee como un todo, así que la opción específica gana a la familia, y todo parámetro cuyo tipo no se puede inferir se convierte en silencio en `any`. El de [`ga-client`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/tsconfig.app.json#L17-L18) no tiene esa línea.

Ejecuté `tsc -p tsconfig.app.json --noImplicitAny true` en la biblioteca de componentes, con TypeScript 5.9.3 y las dependencias resueltas a partir de su `package.json`: añade 4 errores a los de la lección 1, dos `TS7006`, `Parameter 'child' implicitly has an 'any' type` y lo mismo para `obj`, en [`BSPDoomExplorer.tsx`, líneas 4363 y 4367](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L4363-L4367), y dos `TS7053` por indexar un `Record<HexavalentTruth, string>` con un `string` simple en [`IxqlFormPanel.tsx`, líneas 83 y 112](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/IxqlFormPanel.tsx#L83). Volver a activar la opción cuesta cuatro anotaciones; el `any` que el proyecto no ve viene de otra parte, de 42 llamadas a `JSON.parse` y de 18 `as any` en su código fuente, que examina la lección 3.

## Puntos clave

- `tsc` infiere los tipos locales, incluidos los tipos literales de las constantes; anota los parámetros y las firmas exportadas. `tsc --declaration` muestra lo que infirió.
- La compatibilidad es estructural: misma forma, mismo tipo, digan lo que digan los nombres. Las marcas y los campos `#private` dan un nombre a un tipo cuando lo necesita.
- Un literal de objeto escrito donde se espera un tipo se comprueba en busca de propiedades sobrantes; el mismo objeto pasado a través de una variable, no.
- `readonly` es una vista en tiempo de compilación: un alias sin `readonly` todavía puede escribir, y nada se congela.
- Los índices de array y de `Record` se dan por buenos salvo que `noUncheckedIndexedAccess` esté activada.
- `any` desactiva la comprobación y se propaga; `unknown` exige una comprobación; `never` no tiene valores. `JSON.parse` devuelve `any`: guárdalo en un `unknown`.
- `strictNullChecks` hace que la ausencia forme parte del tipo, como los tipos de referencia que aceptan valores NULL de C#, pero como errores; `!` silencia a los dos compiladores y no comprueba nada.

## Ejercicios

1. Escribe los tipos con marca `Celsius` y `Fahrenheit`, una función `toFahrenheit(t: Celsius): Fahrenheit` y `boils(t: Celsius)`, y muestra tres errores que `tsc` ahora rechaza, en un archivo que `tsc` acepta.

<details>
<summary>Solución</summary>

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

// Nunca se llama: cada línea muestra un error que tsc ahora rechaza
function mistakes() {
  // @ts-expect-error: un Fahrenheit no es un Celsius
  boils(oven);
  // @ts-expect-error: un number simple tampoco es un Celsius
  boils(212);
  // @ts-expect-error: el resultado de una operación aritmética vuelve a ser un number simple
  const warmer: Celsius = water + 1;
  return warmer;
}
console.log(typeof mistakes);
```

```text
212 true
function
```

Un comentario `// @ts-expect-error` le dice a `tsc` que la línea siguiente debe ser un error: el archivo compila, y si un cambio posterior hiciera válida una de esas líneas, `tsc` señalaría la directiva como no utilizada. Es la forma de TypeScript de probar que un código es *rechazado*, donde este curso usa fragmentos de error separados. El tercer error muestra el límite de las marcas: una operación aritmética sobre un `Celsius` da un `number` simple, así que cada operación que debería conservar la unidad pasa por una función.

</details>

2. Escribe `loadTunings(raw: string | null): Tuning[]` para afinaciones guardadas como JSON, que devuelve solo las entradas que tienen un `name` de tipo cadena y un array de cadenas `notes`, y un array vacío para cualquier otra cosa, JSON no válido incluido.

<details>
<summary>Solución</summary>

[`solutions/l02_ex2_load_tunings.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l02_ex2_load_tunings.ts):

```ts
// solutions/l02_ex2_load_tunings.ts
interface Tuning {
  name: string;
  notes: string[];
}

// JSON.parse en un unknown: tsc no deja pasar nada hasta que se comprueba cada propiedad
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

El resultado de `JSON.parse` va a un `unknown`, y la función devuelve objetos nuevos construidos solo con propiedades comprobadas, así que una propiedad adicional en los datos guardados no llega al programa. Fíjate, sin embargo, en `item.name`: compiló sin una comprobación `'name' in item`, porque `Array.isArray` estrecha un `unknown` a `any[]`, y cada `item` vuelve a ser `any`. `any` regresa a través de las declaraciones de la biblioteca estándar; las comprobaciones `typeof` son lo que hace correcta esta función, no `tsc`.

</details>

3. Para cada línea numerada de [`solutions/l02_ex3_predict.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l02_ex3_predict.ts), predice si `tsc` la acepta, luego quita los comentarios `@ts-expect-error` y ejecuta `tsc` para comprobarlo.

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
<summary>Solución</summary>

```ts
// solutions/l02_ex3_predict.ts
// Cada línea que tsc rechaza lleva @ts-expect-error: si una de ellas compilara, tsc señalaría una directiva no utilizada
interface Point {
  x: number;
  y: number;
}
interface ReadonlyPoint {
  readonly x: number;
  readonly y: number;
}

const p3 = { x: 1, y: 2, z: 3 };
const a: Point = p3; // 1. aceptada: no es un literal fresco, y z sobra
// @ts-expect-error 2. rechazada: propiedad sobrante z en un literal de objeto fresco
const b: Point = { x: 1, y: 2, z: 3 };
const c: ReadonlyPoint = a; // 3. aceptada: readonly solo restringe lo que c puede hacer
const d: Point = c; // 4. aceptada: readonly no afecta a la asignabilidad
// @ts-expect-error 5. rechazada: [number, number] no tiene tercer elemento
const e: [number, number] = [1, 2, 3];
const f: number[] = [1, 2] as [number, number]; // 6. aceptada: una tupla es un array
// @ts-expect-error 7. rechazada: unknown debe estrecharse antes de asignarlo a un string
const g: string = JSON.parse('"x"') as unknown;
const h: string = JSON.parse('1'); // 8. aceptada: any es asignable a string, y h contiene 1
// @ts-expect-error 9. rechazada: null no es un number con strictNullChecks
const i: number = null;

console.log([a, b, c, d, e, f, g, typeof h, i].length);
```

```text
9
```

Las líneas 2, 5, 7 y 9 se rechazan: un literal fresco con una propiedad sobrante, una tupla de longitud incorrecta, un `unknown` usado como `string`, y `null` con `strictNullChecks`. Las líneas 1, 3, 4, 6 y 8 se aceptan, y dos de ellas merecen una segunda mirada: la línea 4 pierde el `readonly` a través de un alias, y la línea 8 guarda el número `1` en un `string`, porque `JSON.parse` devuelve `any`.

</details>

## Fuentes

- [Manual de TypeScript — Tipos cotidianos](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html), [Tipos de objeto](https://www.typescriptlang.org/docs/handbook/2/objects.html), [Compatibilidad de tipos](https://www.typescriptlang.org/docs/handbook/type-compatibility.html), [Inferencia de tipos](https://www.typescriptlang.org/docs/handbook/type-inference.html)
- [Referencia de TSConfig — strict](https://www.typescriptlang.org/tsconfig/#strict), [strictNullChecks](https://www.typescriptlang.org/tsconfig/#strictNullChecks), [noImplicitAny](https://www.typescriptlang.org/tsconfig/#noImplicitAny), [noUncheckedIndexedAccess](https://www.typescriptlang.org/tsconfig/#noUncheckedIndexedAccess)
- [Microsoft — Tipos de referencia que aceptan valores NULL](https://learn.microsoft.com/dotnet/csharp/nullable-references), [Uso del tipo dynamic](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interop/using-type-dynamic)
