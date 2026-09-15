---
title: 1. Programación a nivel de tipos
description: Tipos que calculan tipos — probarlos con Expect y Equal, tipos condicionales, distributividad e infer, tipos mapeados con reasignación de claves, tipos de plantilla literal que analizan cadenas, tipos recursivos y los límites del verificador en typescript-go, y luego una capa tipada sobre el hub SignalR de GA, comparada con las claves tipadas que necesitan C# y Java.
sidebar:
  order: 1
---

Código: los archivos [`examples/l01_*`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples), [`examples/type-tests.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples/type-tests.ts) y [`errors/l01_*`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/errors), y los equivalentes en C# y Java en [`compare/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare) (`l01_typed_keys.cs`, `L01TypedKeys.java`) y [`compare_fail/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare_fail) (`l01_infer_from_name.cs`, `L01InferFromName.java`).

Un alias de tipo genérico es una función cuyos argumentos y resultado son tipos. El verificador la ejecuta cada vez que el alias se usa con argumentos de tipo, y TypeScript le da a ese lenguaje las construcciones de un pequeño lenguaje funcional: un condicional, *pattern matching* con `infer`, un bucle sobre las claves de un objeto, concatenación y análisis de cadenas, y recursión. C# y Java no tienen equivalente dentro del compilador; lo más parecido es un generador de código fuente o un procesador de anotaciones, que escriben código antes de compilarlo. Esta lección escribe tipos así, los prueba, y mira los límites que el verificador les impone.

| Programar con valores | Programar con tipos |
|---|---|
| una función `f(x)` | un alias genérico `F<X>` |
| `if`, `? :` | un tipo condicional, `X extends Y ? A : B` |
| desestructuración, *pattern matching* | `infer` |
| `map` sobre las entradas de un objeto | un tipo mapeado, `{ [K in keyof T]: … }` |
| plantillas de cadena y análisis | tipos de plantilla literal |
| recursión, bucles | alias recursivos |
| una prueba unitaria | un tipo que no compila cuando el resultado es incorrecto |

## Probar los tipos

Los tipos no tienen salida que imprimir, así que cada ejemplo comprueba sus resultados con una prueba de tipos: una línea que compila cuando el tipo calculado es el esperado y hace fallar la build en caso contrario. Las dos utilidades viven en [`type-tests.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples/type-tests.ts), y `check.sh` ejecuta `tsc` sobre todo el proyecto, así que una prueba que falla hace fallar la CI:

```ts
// examples/type-tests.ts
// Pruebas de tipos que tsc comprueba y Node.js borra: Expect<Equal<A, B>> no compila salvo que A y B sean el mismo tipo

// Se comparan dos tipos función con un parámetro de tipo extra U, que tsc no puede resolver: son asignables
// solo si A y B son idénticos, lo que detecta any, las uniones y los modificadores opcionales que extends solo deja pasar
export type Equal<A, B> = (<U>() => U extends A ? 1 : 2) extends <U>() => U extends B ? 1 : 2 ? true : false;
export type Expect<T extends true> = T;
```

`Expect<T extends true>` solo acepta `true`. `Equal<A, B>` es menos evidente. Un `[A] extends [B] ? ([B] extends [A] ? true : false) : false` más simple compara la asignabilidad en los dos sentidos, y la asignabilidad es demasiado permisiva para una prueba: `any` es asignable a todo y viceversa, y `{ a?: string }` y `{ a?: string | undefined }` son mutuamente asignables sin `exactOptionalPropertyTypes`. La versión de arriba compara dos tipos función genéricos cuyos tipos de retorno son tipos condicionales sobre un parámetro de tipo `U` que nada fija. El verificador no puede evaluarlos, así que compara los dos tipos condicionales en sí, y solo los considera relacionados si `A` y `B` son idénticos. El truco viene de una [discusión en el repositorio de TypeScript](https://github.com/microsoft/TypeScript/issues/27024#issuecomment-421529650), y bibliotecas como [`expect-type`](https://github.com/mmkal/expect-type) se basan en la misma idea; la lección 11 las compara.

Una prueba que falla, y un error esperado que no se produce, detienen ambos la build:

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

`ElementOf<readonly string[]>` da `never`, porque un `readonly string[]` no es asignable al mutable `(infer E)[]`, y la prueba lo detecta con `TS2344`. El segundo error, `TS2578`, viene de [`// @ts-expect-error`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-9.html#-ts-expect-error-comments): la línea de debajo compila, así que el comentario se señala como no usado. Los dos juntos forman una batería de pruebas de tipos: `Expect` para lo que calcula un tipo, `@ts-expect-error` para lo que una API debe rechazar. Node.js ejecuta el archivo de todos modos e imprime `undefined`, ya que tanto los alias de tipo como el comentario se borran.

## Tipos condicionales

```ts
// examples/l01_conditional.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// Un tipo condicional elige una rama cuando su argumento de tipo es conocido
type IsString<T> = T extends string ? true : false;
type _1 = Expect<Equal<IsString<'C#'>, true>>;
type _2 = Expect<Equal<IsString<440>, false>>;

// Distributivo: un parámetro de tipo comprobado por sí solo se comprueba una vez por miembro de una unión
type ToArray<T> = T extends unknown ? T[] : never;
type _3 = Expect<Equal<ToArray<string | number>, string[] | number[]>>;
// Envuelta en una tupla, la unión se comprueba como un todo
type ToArrayWhole<T> = [T] extends [unknown] ? T[] : never;
type _4 = Expect<Equal<ToArrayWhole<string | number>, (string | number)[]>>;

// never es la unión vacía: un tipo condicional distributivo lo convierte en never sin comprobar nada
type IsNeverWrong<T> = T extends never ? true : false;
type IsNever<T> = [T] extends [never] ? true : false;
type _5 = Expect<Equal<IsNeverWrong<never>, never>>;
type _6 = Expect<Equal<IsNever<never>, true>>;

// Extract y Exclude, de lib.es5.d.ts, son tipos condicionales distributivos que filtran una unión
type Accidental = 'natural' | 'sharp' | 'flat' | 'double-sharp' | 'double-flat';
type _7 = Expect<Equal<Extract<Accidental, `double-${string}`>, 'double-sharp' | 'double-flat'>>;
type _8 = Expect<Equal<Exclude<Accidental, `double-${string}`>, 'natural' | 'sharp' | 'flat'>>;

// infer da nombre a una parte del tipo que se comprueba
type ElementOf<T> = T extends readonly (infer E)[] ? E : never;
type PayloadOf<F> = F extends (data: infer D) => void ? D : never;
type _9 = Expect<Equal<ElementOf<readonly ['E', 'A', 'D']>, 'E' | 'A' | 'D'>>;
type _10 = Expect<Equal<PayloadOf<(data: { target: string }) => void>, { target: string }>>;

// infer con una restricción: la rama solo se toma si el texto inferido es un número, que pasa a ser un tipo numérico
type FretOf<T> = T extends `fret-${infer N extends number}` ? N : never;
type _11 = Expect<Equal<FretOf<'fret-12'>, 12>>;
type _12 = Expect<Equal<FretOf<'fret-XII'>, never>>;

// Un nombre inferido dos veces: una unión desde posiciones covariantes, una intersección desde las contravariantes
type Both<T> = T extends { a: infer U; b: infer U } ? U : never;
type BothParams<T> = T extends { a: (x: infer U) => void; b: (x: infer U) => void } ? U : never;
type _13 = Expect<Equal<Both<{ a: string; b: number }>, string | number>>;
type _14 = Expect<Equal<BothParams<{ a: (x: { root: string }) => void; b: (x: { quality: string }) => void }>, { root: string } & { quality: string }>>;

// Dentro de una función genérica, T todavía no se conoce: el tipo condicional se difiere, y tsc no puede elegir rama
function describe<T extends string | number>(value: T): T extends string ? 'text' : 'number' {
  const kind = typeof value === 'string' ? 'text' : 'number';
  return kind as T extends string ? 'text' : 'number'; // una aserción: estrechar value no estrecha T
}
const fromText = describe('C#');
const fromNumber = describe(440);
type _15 = Expect<Equal<typeof fromText, 'text'>>;
type _16 = Expect<Equal<typeof fromNumber, 'number'>>;

// Las sobrecargas describen la misma función sin tipo condicional, y sin aserción en el cuerpo
function describeOverloaded(value: string): 'text';
function describeOverloaded(value: number): 'number';
function describeOverloaded(value: string | number): 'text' | 'number' {
  return typeof value === 'string' ? 'text' : 'number';
}

// Los tipos se borran: en tiempo de ejecución solo quedan los valores
show('describe', [fromText, fromNumber]);
show('describeOverloaded', [describeOverloaded('C#'), describeOverloaded(440)]);
```

```text
describe                           [ 'text', 'number' ]
describeOverloaded                 [ 'text', 'number' ]
```

Un [tipo condicional](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html), `T extends U ? X : Y`, pregunta si `T` es asignable a `U`. Cuatro de sus reglas explican la mayoría de las sorpresas.

**Distributividad.** Cuando el tipo comprobado es un parámetro de tipo por sí solo, y el argumento es una unión, el tipo condicional se evalúa una vez por cada miembro y los resultados se unen: `ToArray<string | number>` es `string[] | number[]`, no `(string | number)[]`. El handbook los llama [tipos condicionales distributivos](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html#distributive-conditional-types). Es lo que hace funcionar `Extract` y `Exclude`: `lib.es5.d.ts` define `Exclude<T, U>` como `T extends U ? never : T`, que conserva los miembros de `T` que no coinciden. Envolver los dos lados en una tupla, `[T] extends [unknown]`, desactiva la distribución, porque `[T]` ya no es un parámetro de tipo desnudo.

**`never` es la unión vacía.** Un tipo condicional distributivo sobre cero miembros devuelve cero resultados, así que `IsNeverWrong<never>` es `never`, no `true`. Comprobar `never` necesita la forma de tupla, `[T] extends [never]`. La misma regla explica por qué un tipo condicional aplicado a un tipo que se ha filtrado hasta quedar vacío desaparece en silencio.

**`infer` da nombre a una parte del tipo comprobado.** `T extends readonly (infer E)[] ? E : never` coincide con los arrays y da nombre a su tipo de elemento. Desde [TypeScript 4.7](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#extends-constraints-on-infer-type-variables), un `infer` puede llevar una restricción, `infer N extends number`, y cuando aparece en una plantilla literal, la [4.8](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-8.html#improved-inference-for-infer-types-in-template-string-types) convierte el texto coincidente en un tipo literal numérico: `FretOf<'fret-12'>` es el tipo `12`, y `'fret-XII'` no coincide. Cuando el mismo nombre se infiere dos veces, los candidatos se combinan según la posición: una unión en posiciones covariantes, como dos tipos de propiedad, y una intersección en posiciones contravariantes, como dos tipos de parámetro, porque una función que debe aceptar los dos argumentos acepta su intersección. La lección 2 vuelve sobre estas posiciones.

**Dentro de un cuerpo genérico, la condición se difiere.** `describe<T>` devuelve `T extends string ? 'text' : 'number'`. En cada llamada, `T` es conocido, y el resultado es `'text'` o `'number'`. Dentro de la función, `T` no se conoce, y estrechar `value` con `typeof` no estrecha `T`, ya que `T` podría ser la propia unión `string | number`. El verificador no puede elegir rama, y rechaza los dos literales:

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

El ejemplo compila con una aserción sobre el valor de retorno, que es la forma habitual de implementar una función cuyo tipo de retorno es un tipo condicional. Las sobrecargas, como en `describeOverloaded`, dicen lo mismo a los llamadores sin ninguna aserción en el cuerpo, al precio de una firma por caso. C# resuelve las sobrecargas de la misma manera en tiempo de compilación; para lo que no tiene equivalente es para la firma única cuyo tipo de retorno se calcula a partir del argumento.

## Tipos mapeados y reasignación de claves

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

// Un tipo mapeado homomórfico, { [K in keyof T]: … }, conserva los modificadores readonly y ? de cada propiedad
type Nullable<T> = { [K in keyof T]: T[K] | null };
type _1 = Expect<Equal<Nullable<Voicing>, { readonly id: string | null; frets: number[] | null; capo?: number | null; label?: string | null }>>;

// -readonly y -? quitan los modificadores; readonly y ? los añaden
type Mutable<T> = { -readonly [K in keyof T]: T[K] };
type Complete<T> = { [K in keyof T]-?: T[K] };
type _2 = Expect<Equal<Mutable<Voicing>, { id: string; frets: number[]; capo?: number; label?: string }>>;
type _3 = Expect<Equal<Complete<Voicing>, { readonly id: string; frets: number[]; capo: number; label: string }>>;

// Reasignación de claves con as: la nueva clave se calcula, aquí con un tipo de plantilla literal
type Getters<T> = { [K in keyof T & string as `get${Capitalize<K>}`]: () => T[K] };
type _4 = Expect<Equal<keyof Getters<Voicing>, 'getId' | 'getFrets' | 'getCapo' | 'getLabel'>>;

// Una clave reasignada a never se elimina: un filtro sobre las propiedades
type KeysOfType<T, V> = keyof { [K in keyof T as T[K] extends V ? K : never]: T[K] };
type OptionalKeys<T> = keyof { [K in keyof T as {} extends Pick<T, K> ? K : never]: T[K] };
type _5 = Expect<Equal<KeysOfType<Voicing, string>, 'id'>>;
type _6 = Expect<Equal<OptionalKeys<Voicing>, 'capo' | 'label'>>;

// Un tipo mapeado homomórfico aplicado a una tupla da una tupla
type Boxed<T> = { [K in keyof T]: { value: T[K] } };
type _7 = Expect<Equal<Boxed<[string, number]>, [{ value: string }, { value: number }]>>;

// La implementación necesita una aserción: tsc no puede seguir Object.entries a través de una reasignación de claves
function gettersOf<T extends object>(value: T): Getters<T> {
  const entries = Object.entries(value).map(([key, v]) => [`get${key.charAt(0).toUpperCase()}${key.slice(1)}`, () => v]);
  return Object.fromEntries(entries) as Getters<T>;
}
const voicing: Voicing = { id: 'C-open', frets: [-1, 3, 2, 0, 1, 0], label: 'C major' };
const getters = gettersOf(voicing);
show('Object.keys(getters)', Object.keys(getters));
show('getters.getLabel()', getters.getLabel());
// getCapo está en el tipo, y no en el objeto: el tipo lista lo que Voicing permite, no lo que tiene este valor
show("'getCapo' in getters", 'getCapo' in getters);
```

```text
Object.keys(getters)               [ 'getId', 'getFrets', 'getLabel' ]
getters.getLabel()                 'C major'
'getCapo' in getters               false
```

Un [tipo mapeado](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html) itera sobre una unión de claves. Cuando esa unión es `keyof T` para un tipo `T`, el tipo mapeado se llama homomórfico, y conserva los modificadores de cada propiedad: `Nullable<Voicing>` tiene un `readonly id` y un `capo` opcional, como `Voicing`. Los modificadores pueden quitarse con `-readonly` y `-?`, que es como la biblioteca estándar escribe `Required<T>`.

**La reasignación de claves**, añadida en [TypeScript 4.1](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-1.html#key-remapping-in-mapped-types), calcula un nuevo nombre para cada clave con `as`: `Getters<Voicing>` tiene `getId`, `getFrets`, `getCapo` y `getLabel`. La intersección `keyof T & string` hace falta porque `keyof` también puede contener números y símbolos, que un tipo de plantilla literal no puede poner en mayúscula. Reasignar una clave a `never` elimina la propiedad, y así es como `KeysOfType` y `OptionalKeys` filtran las propiedades por su tipo de valor o por su modificador. `OptionalKeys` usa un pequeño truco: `{}` es asignable a `Pick<T, K>` solo si la propiedad `K` es opcional.

Un tipo mapeado homomórfico aplicado a una tupla produce una tupla, `Boxed<[string, number]>`, lo que permite que un único tipo mapeado transforme cada elemento de una lista de argumentos.

La función de tiempo de ejecución `gettersOf` necesita una aserción. `Object.entries` devuelve `[string, any][]`, y nada relaciona las cadenas calculadas en tiempo de ejecución con las claves calculadas por `Getters<T>`. La salida muestra el otro hueco: `getCapo` existe en el tipo, porque `Voicing` permite un `capo`, y no en el objeto, porque este valor no lo tiene. Un tipo mapeado describe el tipo `T`, no el valor que se pasó.

## Tipos de plantilla literal

```ts
// examples/l01_template.ts
import type { Equal, Expect } from './type-tests.ts';
import { attempt, show } from './show.ts';

// Un tipo de plantilla literal combina cada miembro de cada unión: 7 letras × 3 alteraciones × 8 calidades
type Letter = 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G';
type Accidental = '' | '#' | 'b';
type Quality = '' | 'm' | '7' | 'maj7' | 'm7' | 'dim' | 'aug' | 'sus4';
type ChordSymbol = `${Letter}${Accidental}${Quality}`;
type _1 = Expect<Equal<Extract<ChordSymbol, `C${string}`>, 'C' | 'Cm' | 'C7' | 'Cmaj7' | 'Cm7' | 'Cdim' | 'Caug' | 'Csus4' | `C#${Quality}` | `Cb${Quality}`>>;

// infer dentro de un tipo de plantilla literal analiza una cadena: un infer seguido de otro infer toma un carácter
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

// El analizador de tiempo de ejecución es código normal; su firma da a cada argumento literal su tipo analizado
const chordPattern = /^([A-G][#b]?)(maj7|m7|m|7|dim|aug|sus4)?$/;
function parseChord<S extends ChordSymbol>(symbol: S): ParseChord<S> {
  const match = chordPattern.exec(symbol);
  if (!match) throw new TypeError(`not a chord symbol: ${symbol}`);
  return { root: match[1], quality: match[2] ?? '' } as ParseChord<S>; // la regex y el tipo dicen lo mismo dos veces
}
const fSharpMinor7 = parseChord('F#m7');
type _5 = Expect<Equal<typeof fSharpMinor7, { root: 'F#'; quality: 'm7' }>>;
show("parseChord('F#m7')", fSharpMinor7);
show("parseChord('Bbmaj7').root", parseChord('Bbmaj7').root);

// Un símbolo conocido solo en tiempo de ejecución es un string: hay que comprobarlo antes de la llamada
const isChordSymbol = (text: string): text is ChordSymbol => chordPattern.test(text);
for (const text of ['Gsus4', 'H7']) {
  attempt(`parse '${text}'`, () => (isChordSymbol(text) ? parseChord(text) : `rejected: ${text}`));
}

// Capitalize y los demás tipos de cadena intrínsecos solo existen para tsc: la función de tiempo de ejecución se escribe aparte
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

Un [tipo de plantilla literal](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html) construye tipos literales de cadena igual que una plantilla literal construye cadenas, y se distribuye sobre las uniones: siete letras, tres alteraciones y ocho calidades dan 168 símbolos de acorde, todos comprobados por `tsc`. La primera prueba de tipos lista los 24 símbolos que empiezan por `C`, incluidos `C#` y `Cb` con cada calidad.

El *pattern matching* sobre una cadena usa `infer` dentro de la plantilla. Dos reglas hacen funcionar `ParseChord`. Un `infer` seguido inmediatamente de otro `infer` coincide exactamente con un carácter, así que `${infer L extends Letter}${infer Rest}` toma la primera letra. Y una restricción sobre el `infer` hace fallar la coincidencia cuando el texto no encaja, que es como se distinguen `#` y `b` de una calidad.

La función `parseChord` conecta los dos mundos. Su parámetro es un `ChordSymbol`, así que un argumento literal se comprueba en tiempo de compilación, y su tipo de retorno es `ParseChord<S>`, así que `parseChord('F#m7')` tiene el tipo `{ root: 'F#'; quality: 'm7' }`. La regex y el tipo describen la misma gramática dos veces, y nada comprueba que coincidan, salvo las pruebas. Una cadena que llega en tiempo de ejecución, como `'H7'`, el nombre alemán de B7, tiene el tipo `string`, y debe comprobarse con una guarda de tipo antes de la llamada; la guarda es la mitad de tiempo de ejecución del tipo.

`Capitalize`, `Uncapitalize`, `Uppercase` y `Lowercase` son [tipos intrínsecos de manipulación de cadenas](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html#intrinsic-string-manipulation-types), implementados dentro del verificador. No tienen contrapartida en tiempo de ejecución, y `handlerName` vuelve a implementar el paso a mayúscula con `charAt(0).toUpperCase()`.

## Tipos recursivos y los límites del verificador

```ts
// examples/l01_recursive.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// Un tipo condicional recursivo recorre una cadena carácter a carácter: una digitación de guitarra, empezando por la cuerda Mi grave
type Fret<C extends string> = C extends 'x' ? null : C extends `${infer N extends number}` ? N : never;
type Fingering<S extends string> = S extends `${infer C}${infer Rest}` ? [Fret<C>, ...Fingering<Rest>] : [];
type _1 = Expect<Equal<Fingering<'x32010'>, [null, 3, 2, 0, 1, 0]>>;

// Un tipo recursivo sigue un objeto anidado: DeepReadonly, que la biblioteca estándar no proporciona
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

// Rutas con puntos dentro de un tipo anidado, como las calculan las bibliotecas de formularios y de traducción
type Paths<T> = T extends object
  ? { [K in keyof T & string]: T[K] extends readonly unknown[] ? K : T[K] extends object ? K | `${K}.${Paths<T[K]>}` : K }[keyof T & string]
  : never;
interface SceneSettings {
  camera: { position: { x: number; y: number; z: number }; fov: number };
  stars: boolean;
  tunings: Tuning[];
}
type _3 = Expect<Equal<Paths<SceneSettings>, 'camera' | 'camera.position' | 'camera.position.x' | 'camera.position.y' | 'camera.position.z' | 'camera.fov' | 'stars' | 'tunings'>>;

// Recursión de cola: cuando la llamada recursiva es toda la rama, tsc la evalúa en un bucle, hasta 1,000 veces.
// Fingering no tiene recursión de cola: su llamada está dentro de una tupla. Con un acumulador, la llamada es la rama.
type FingeringTail<S extends string, Acc extends unknown[] = []> = S extends `${infer C}${infer Rest}` ? FingeringTail<Rest, [...Acc, Fret<C>]> : Acc;
type Long = `${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}`;
type _4 = Expect<Equal<FingeringTail<Long>['length'], 60>>;

// El analizador de tiempo de ejecución, tipado por el tipo recursivo
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

Un alias de tipo puede referirse a sí mismo. `Fingering` recorre una cadena como `'x32010'`, la digitación de un acorde abierto de Do mayor desde la cuerda Mi grave hasta la Mi aguda, carácter a carácter. `DeepReadonly` recorre un objeto, y se detiene en las funciones, cuyas propiedades no deberían volverse de solo lectura. `Paths` calcula cada ruta con puntos dentro de un objeto anidado, el tipo de tipo que usan las bibliotecas de formularios para comprobar un nombre de campo como `'camera.position.x'`; se detiene en los arrays para que la unión siga siendo finita.

La recursión es donde el verificador pone límites, y el fragmento de abajo choca con los tres:

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

Los límites están en [`internal/checker/checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go) de typescript-go, en la etiqueta de la 7.0.2:

- **Profundidad de instanciación: 100.** La [línea 22016](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go#L22016-L22024) se detiene cuando hay 100 instanciaciones anidadas, o tras 5 millones de instanciaciones para la misma sentencia, e informa de `TS2589`. `Reverse` no tiene recursión de cola: su llamada recursiva está dentro de una tupla, `[...Reverse<Tail>, Head]`, así que cada nivel espera al siguiente. En un archivo propio, invertir 48 elementos pasa y 49 falla, lo que sugiere unas dos instanciaciones anidadas por nivel.
- **Recursión de cola: 1,000.** Cuando un tipo condicional se resuelve en otro tipo condicional en su rama falsa, o en una llamada recursiva que es toda la rama, el verificador lo evalúa en un bucle en lugar de anidarlo, y la [línea 24218](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go#L24211-L24222) detiene ese bucle tras 1,000 iteraciones. `BuildTuple` va pasando su acumulador, así que construye una tupla de 999 elementos, y falla en 1,000. Esta optimización llegó en [TypeScript 4.5](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-5.html#tail-recursion-elimination-on-conditional-types).
- **Tamaño de las uniones: 100,000.** La [línea 26521](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go#L26519-L26530) calcula el tamaño del producto cartesiano de una plantilla literal antes de construirlo, y rechaza una unión de 100,000 miembros o más con `TS2590`. Cuatro dígitos dan 10,000 cadenas; cinco dan exactamente 100,000, una de más.

El fragmento muestra algo más, que no esperaba. `Reversed49` falla, y `Reversed80`, que es más profundo, pasa, porque viene después de `Reversed40`. Las instanciaciones se guardan en caché, así que invertir 80 elementos llega, tras 40 niveles, a una tupla cuya inversión ya se conoce. Solo, en su propio archivo, `Reverse<BuildTuple<80>>` también falla. La regla práctica es la que sigue el ejemplo con `FingeringTail`: escribe los tipos recursivos con un acumulador, de modo que la llamada recursiva sea toda la rama, y podrán manejar entradas de cientos de elementos; la versión sin recursión de cola solo funciona porque las entradas son cortas, y puede romperse cuando un tipo sin relación deja de estar en caché.

## En GuitarAlchemist/ga: un hub tipado

La vista Prime Radiant de GA recibe su grafo de gobernanza de un hub SignalR. En el cliente, [`DataLoader.ts`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L272-L326) registra diez manejadores, uno por evento, cada uno escrito así:

```ts
connection.on('NodeChanged', (data: { nodeId: string; health: unknown; healthStatus: string; color: string }) => {
  // Actualización parcial — un solo nodo
  onUpdate({ nodes: [data as unknown as GovernanceNode], edges: [], globalHealth: { resilienceScore: 0, lolliCount: 0, ergolCount: 0 }, timestamp: new Date().toISOString() } as GovernanceGraph);
});
```

La firma de `on` en el cliente SignalR es [`on(methodName: string, newMethod: (...args: any[]) => any): void`](https://github.com/dotnet/aspnetcore/blob/a5383385245bdacc20ec19f30e46090a8154d8da/src/SignalR/clients/ts/signalr/src/HubConnection.ts#L508-L509), e [`invoke`](https://github.com/dotnet/aspnetcore/blob/a5383385245bdacc20ec19f30e46090a8154d8da/src/SignalR/clients/ts/signalr/src/HubConnection.ts#L466) toma `...args: any[]`. Cada nombre de evento es un `string`, cada carga útil un `any`, y cada manejador anota su parámetro a mano. En el servidor, [`GovernanceHub.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Apps/ga-server/GaApi/Hubs/GovernanceHub.cs#L40-L43) deriva de `Hub`, no del [`Hub<T>`](https://learn.microsoft.com/aspnet/core/signalr/hubs#strongly-typed-hubs) fuertemente tipado, y envía cada evento con `SendAsync("NodeChanged", new { … })`. Nada en ninguno de los dos lados comprueba que los nombres y las formas coincidan. El [`LiveDataConfig`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L171-L198) del cliente lista luego un callback para la mayoría de los eventos, de nuevo a mano: `onBeliefUpdate`, `onCameraSync`, `onNavigateToPlanet`, y `onScreenshotRequest` para el evento `RequestScreenshot`.

Basta una tabla de eventos para tiparlo todo:

```ts
// examples/l01_hub_events.ts
// El hub de gobernanza de GuitarAlchemist/ga, tipado a partir de una tabla de eventos en lugar de una anotación por manejador
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

// Lo que GovernanceHub.cs envía al cliente, evento por evento, tal como lo serializa SignalR (nombres de propiedad en camelCase)
interface GovernanceHubEvents {
  GraphUpdate: { nodes: GovernanceNode[]; timestamp: string };
  NodeChanged: { nodeId: string; health: HealthMetrics; healthStatus: string; color: string; timestamp: string };
  Connected: { message: string; connections: number; timestamp: string };
  NavigateToPlanet: { target: string; timestamp: string };
  RequestScreenshot: { reason: string; timestamp: string };
  CameraSync: { px: number; py: number; pz: number; lx: number; ly: number; lz: number; sender: string };
}
// Lo que el cliente puede llamar en el hub: listas de parámetros como tuplas etiquetadas
interface GovernanceHubMethods {
  Subscribe: [];
  SubmitScreenshot: [base64Image: string, format: string];
  SyncCamera: [px: number, py: number, pz: number, lx: number, ly: number, lz: number];
}

// La parte del HubConnection de @microsoft/signalr que se usa aquí: cada nombre es un string, cada argumento any
interface HubConnection {
  on(methodName: string, newMethod: (...args: any[]) => any): void;
  invoke<T = any>(methodName: string, ...args: any[]): Promise<T>;
}

// Una capa tipada encima: el nombre es una clave de la tabla, y el parámetro del manejador se busca a partir de esa clave
function on<K extends keyof GovernanceHubEvents>(connection: HubConnection, name: K, handler: (data: GovernanceHubEvents[K]) => void): void {
  connection.on(name, handler);
}
function invoke<K extends keyof GovernanceHubMethods>(connection: HubConnection, name: K, ...args: GovernanceHubMethods[K]): Promise<void> {
  return connection.invoke(name, ...args);
}

// El LiveDataConfig de GA lista sus callbacks a mano; la reasignación de claves los deriva de la tabla
type Callbacks<Events> = { [K in keyof Events & string as `on${K}`]?: (data: Events[K]) => void };
type GovernanceCallbacks = Callbacks<GovernanceHubEvents>;
type _1 = Expect<Equal<keyof GovernanceCallbacks, 'onGraphUpdate' | 'onNodeChanged' | 'onConnected' | 'onNavigateToPlanet' | 'onRequestScreenshot' | 'onCameraSync'>>;

// Un bucle registra cada callback que proporcionó el llamador
const eventNames = ['GraphUpdate', 'NodeChanged', 'Connected', 'NavigateToPlanet', 'RequestScreenshot', 'CameraSync'] as const satisfies readonly (keyof GovernanceHubEvents)[];
type _2 = Expect<Equal<(typeof eventNames)[number], keyof GovernanceHubEvents>>;
function subscribe(connection: HubConnection, callbacks: GovernanceCallbacks): void {
  for (const name of eventNames) {
    const callback = callbacks[`on${name}`];
    if (callback) connection.on(name, callback);
  }
}

// Una conexión falsa que registra los manejadores y deja que el ejemplo haga el papel del servidor
const handlers = new Map<string, (...args: any[]) => any>();
const connection: HubConnection = {
  on: (methodName, newMethod) => void handlers.set(methodName, newMethod),
  invoke: (methodName, ...args) => {
    console.log(`invoke ${methodName}(${args.join(', ')})`);
    return Promise.resolve() as Promise<never>; // una falsificación: cada llamada se resuelve con undefined, sea cual sea el T que espera el llamador
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

- **`on<K extends keyof GovernanceHubEvents>`**: el nombre es una clave de la tabla, y el parámetro del manejador es el acceso indexado `GovernanceHubEvents[K]`, buscado a partir del tipo literal del nombre. El manejador no necesita anotación.
- **`invoke`** toma los parámetros del método del hub como un parámetro rest tipado por una tupla etiquetada, `[px: number, py: number, …]`, así que un editor muestra los nombres y `tsc` cuenta los argumentos.
- **`Callbacks<Events>`** deriva los callbacks de `LiveDataConfig` con reasignación de claves, `on${K}`. Los nombres de GA ya siguen ese patrón para la mayoría de los eventos, que es lo que hace que la derivación encaje; la única excepción, `onScreenshotRequest`, es exactamente el tipo de deriva que evita un tipo derivado.
- **`as const satisfies`** comprueba que la lista de nombres solo contiene claves de la tabla, y la prueba de tipos `_2` comprueba que las contiene todas. La lección 2 explica `satisfies`.

La capa tipada convierte en errores de compilación cuatro fallos que el código de GA aceptaría:

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

La primera línea es un nombre de evento mal escrito, al que SignalR nunca llamaría. La segunda lee `data.id` sobre una carga útil `NodeChanged`, que tiene `nodeId`: esa es la confusión que oculta el `data as unknown as GovernanceNode` de GA, y la lección 4 muestra lo que cuesta en tiempo de ejecución. La tercera olvida tres de las seis coordenadas de la cámara. La cuarta usa el nombre de GA para el callback de la captura de pantalla, y `TS7006` se deriva de ello: una vez que la propiedad es desconocida, su función no tiene tipo contextual.

La tabla sigue siendo una afirmación sobre el servidor. Dice lo que envía `GovernanceHub.cs`, y nada la comprueba contra el código C#; la lección 4 añade la comprobación en tiempo de ejecución, y generar la tabla a partir del hub, como hace [TypedSignalR.Client](https://github.com/nenoNaninu/TypedSignalR.Client.TypeScript), es la alternativa en tiempo de compilación (*por verificar* en GA).

### La misma idea en C# y Java

C# y Java no tienen tipos literales: la cadena `"NavigateToPlanet"` tiene el tipo `string`, y un método no puede buscar a partir de ella un tipo de carga útil. Un `On<T>(string name, Action<T> handler)` genérico deja a `T` sin nada a partir de lo que inferirse:

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

C# rechaza la llamada con `CS0411`. Java infiere `T` como `Object` y luego rechaza `data.target()`. La solución habitual en los dos lenguajes es una clave tipada: un objeto que lleva el nombre usado en la red y, en su parámetro de tipo, el tipo de la carga útil.

```csharp
// compare/l01_typed_keys.cs
// C# no tiene tipos literales: una cadena no puede llevar el tipo de su carga útil, así que lo hace un objeto clave tipado
var hub = new Hub();
hub.On(HubEvents.NavigateToPlanet, data => Console.WriteLine($"navigate to {data.Target}"));
hub.On(HubEvents.Connected, data => Console.WriteLine($"{data.Connections} clients connected"));
hub.Receive("NavigateToPlanet", new NavigateToPlanet("saturn"));
hub.Receive("Connected", new Connected(2));

record NavigateToPlanet(string Target);
record Connected(int Connections);

// La clave: un nombre para la red, y un parámetro de tipo para el compilador
sealed record HubEvent<T>(string Name);

static class HubEvents
{
    public static readonly HubEvent<NavigateToPlanet> NavigateToPlanet = new("NavigateToPlanet");
    public static readonly HubEvent<Connected> Connected = new("Connected");
}

class Hub
{
    private readonly Dictionary<string, Action<object>> handlers = [];

    // T se infiere a partir de la clave, como TypeScript infiere K a partir de la cadena
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

`HubEvents.NavigateToPlanet` es un `HubEvent<NavigateToPlanet>`, y `On<T>` infiere `T` a partir de él, como `on<K>` infiere `K` a partir de la cadena en TypeScript. La versión Java guarda un `Class<T>` en la clave, lo que también permite un cast comprobado en tiempo de ejecución: la última línea lo muestra rechazando una carga útil del tipo equivocado, donde los tipos borrados de TypeScript no pueden comprobar nada. Lo que ninguno de los dos lenguajes puede hacer en el sistema de tipos es derivar `onNavigateToPlanet` de `NavigateToPlanet`; en C#, eso es trabajo para un [generador de código fuente](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview).

| | C# | Java | TypeScript |
|---|---|---|---|
| Calcular un tipo a partir de un tipo | no; los generadores de código fuente escriben código | no; los procesadores de anotaciones escriben código | tipos condicionales, mapeados, de plantilla literal |
| Una clave que selecciona un tipo de carga útil | un objeto clave tipado, `HubEvent<T>` | una clave tipada con `Class<T>` | el propio literal de cadena |
| Derivar nombres de miembros | generador de código fuente | procesador de anotaciones | reasignación de claves, `on${K}` |
| Comprobar en tiempo de ejecución | casts sobre tipos reificados | `Class<T>.cast` | nada: un esquema (lección 4) |

## Puntos clave

- Un alias de tipo genérico es una función ejecutada por el verificador; prueba sus resultados con `Expect<Equal<…>>` y `@ts-expect-error`, como hace la CI del curso.
- Un tipo condicional sobre un parámetro de tipo desnudo se distribuye sobre las uniones, convierte `never` en `never`, y se difiere dentro de un cuerpo genérico; envuélvelo en una tupla para detener la distribución.
- `infer` extrae partes de un tipo, con restricciones desde la 4.7, y da uniones en posiciones covariantes e intersecciones en las contravariantes.
- Los tipos mapeados homomórficos conservan los modificadores, la reasignación de claves calcula o filtra nombres de propiedad, y los tipos de plantilla literal construyen y analizan cadenas.
- El verificador se detiene en 100 instanciaciones anidadas, 1,000 pasos de recursión de cola, y uniones de 100,000 miembros; escribe los tipos recursivos con un acumulador.
- Un tipo literal permite que una cadena seleccione un tipo, lo que C# y Java solo pueden hacer con un objeto clave tipado.

## Ejercicios

1. `getPath` en `l01_recursive.ts` devuelve `unknown`. Escribe `PathValue<T, P>`, el tipo que se encuentra al final de una ruta con puntos, y úsalo como tipo de retorno, de modo que `getPath(settings, 'camera.fov')` sea un `number`.

<details>
<summary>Solución</summary>

[`solutions/l01_ex1_path_value.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l01_ex1_path_value.ts):

```ts
// solutions/l01_ex1_path_value.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Paths<T> = T extends object
  ? { [K in keyof T & string]: T[K] extends readonly unknown[] ? K : T[K] extends object ? K | `${K}.${Paths<T[K]>}` : K }[keyof T & string]
  : never;

// El tipo al final de una ruta con puntos: separa la primera clave, búscala, y continúa con el resto
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
  // Una aserción: reduce recorre las mismas claves que PathValue, algo que tsc no puede relacionar con el contenido de la cadena
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

`PathValue` divide la ruta en su primer punto con `infer`, busca la primera clave en `T`, y aplica la recursión al resto; una clave que no está en `T` da `never`. La llamada `fov.toFixed(1)` solo compila porque el resultado es un `number`. La implementación conserva una aserción: `reduce` recorre las mismas claves en tiempo de ejecución, y `tsc` no puede relacionar los trozos de una cadena conocida solo en tiempo de ejecución con el tipo calculado a partir de su literal.

</details>

2. `parseFingering` acepta cualquier cadena. Haz que solo acepte digitaciones de seis caracteres formadas por dígitos y `x`, de modo que `parseFingering('x3201')` y `parseFingering('x3201y')` sean errores de compilación.

<details>
<summary>Solución</summary>

[`solutions/l01_ex2_six_strings.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l01_ex2_six_strings.ts):

```ts
// solutions/l01_ex2_six_strings.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Fret<C extends string> = C extends 'x' ? null : C extends `${infer N extends number}` ? N : never;
type Fingering<S extends string, Acc extends unknown[] = []> = S extends `${infer C}${infer Rest}` ? Fingering<Rest, [...Acc, Fret<C>]> : Acc;

// Una digitación para una guitarra de seis cuerdas: seis caracteres, cada uno un dígito o x; cualquier otra cosa da never
type HasNever<T extends unknown[]> = true extends { [K in keyof T]: [T[K]] extends [never] ? true : false }[number] ? true : false;
type Valid<S extends string> = Fingering<S>['length'] extends 6 ? (HasNever<Fingering<S>> extends true ? never : S) : never;

type _1 = Expect<Equal<Valid<'x32010'>, 'x32010'>>;
type _2 = Expect<Equal<Valid<'x3201'>, never>>;
type _3 = Expect<Equal<Valid<'x3201y'>, never>>;

// S & Valid<S>: el argumento debe ser a la vez el literal y su versión comprobada, never cuando la comprobación falla
function parseFingering<S extends string>(text: S & Valid<S>): Fingering<S> {
  return [...text].map((c) => (c === 'x' ? null : Number(c))) as Fingering<S>;
}

console.log(parseFingering('x32010'), parseFingering('022100'));

function mistakes() {
  // @ts-expect-error: cinco cuerdas
  parseFingering('x3201');
  // @ts-expect-error: y no es ni un traste ni x
  parseFingering('x3201y');
}
console.log(typeof mistakes);
```

```text
[ null, 3, 2, 0, 1, 0 ] [ 0, 2, 2, 1, 0, 0 ]
function
```

`Valid<S>` es `S` cuando la digitación tiene seis elementos y ninguno de ellos es `never`, y `never` en caso contrario. `HasNever` necesita la forma de tupla del `IsNever` de la lección para cada elemento, ya que una prueba distributiva se los saltaría. El tipo de parámetro `S & Valid<S>` es la forma habitual de validar un argumento literal: `S` se infiere a partir del argumento, y cuando `Valid<S>` es `never`, la intersección es `never`, a la que ninguna cadena es asignable. Las líneas `@ts-expect-error` son las pruebas de tipos de los rechazos.

</details>

3. El `BeliefState` de GA, en `DataLoader.ts`, tiene propiedades en snake_case como `truth_value` y `last_updated`, junto a tipos en camelCase en todo lo demás. Escribe `CamelKeys<T>`, que renombra cada clave en snake_case, y un `camelKeys(value)` de tiempo de ejecución tipado con él.

<details>
<summary>Solución</summary>

[`solutions/l01_ex3_camel_keys.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l01_ex3_camel_keys.ts):

```ts
// solutions/l01_ex3_camel_keys.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

// El BeliefState de GA, cuyos nombres de propiedad llegan en snake_case desde los archivos de creencias
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

`SnakeToCamel` es recursivo: divide en el primer guion bajo, y pone en mayúscula el resto convertido, así que `last_updated_by_agent` se convierte en `lastUpdatedByAgent`. `CamelKeys` reasigna las claves y, al ser homomórfico, mantiene `lastUpdated` opcional. La conversión en tiempo de ejecución es una regex, y la prueba de tipos sobre `SnakeToCamel` es lo que une las dos: si una de ellas tratara, por ejemplo, los dígitos de otra manera, solo lo notaría una prueba con una clave así.

</details>

## Fuentes

- [TypeScript handbook — Creating types from types](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html), [Conditional types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html), [Mapped types](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html), [Template literal types](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html)
- Notas de versión: [4.1 — reasignación de claves](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-1.html#key-remapping-in-mapped-types), [4.5 — recursión de cola en los tipos condicionales](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-5.html#tail-recursion-elimination-on-conditional-types), [4.7 — restricciones `extends` en `infer`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#extends-constraints-on-infer-type-variables), [4.8 — `infer` en los tipos de plantilla de cadena](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-8.html#improved-inference-for-infer-types-in-template-string-types)
- [microsoft/typescript-go, `internal/checker/checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go), etiqueta `typescript/v7.0.2`
- [dotnet/aspnetcore — `HubConnection.ts`](https://github.com/dotnet/aspnetcore/blob/a5383385245bdacc20ec19f30e46090a8154d8da/src/SignalR/clients/ts/signalr/src/HubConnection.ts), etiqueta `v10.0.11`; [ASP.NET Core — Hubs fuertemente tipados](https://learn.microsoft.com/aspnet/core/signalr/hubs#strongly-typed-hubs)
- [Microsoft — Inferencia de tipos en métodos genéricos (CS0411)](https://learn.microsoft.com/dotnet/csharp/misc/cs0411), [Generadores de código fuente](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview); [The Java Tutorials — Type inference](https://docs.oracle.com/javase/tutorial/java/generics/genTypeInference.html)
