---
title: 4. Genéricos
description: Parámetros de tipo, inferencia y restricciones, genéricos borrados en tiempo de ejecución frente a los genéricos reificados de C# y el borrado de Java, la varianza con la bivarianza de los métodos, strictFunctionTypes y las anotaciones in/out, y luego keyof, el acceso indexado y un primer tipo mapeado.
sidebar:
  order: 4
---

Código: los archivos [`examples/l04_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/examples) y [`errors/l04_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors), y los equivalentes en C# y Java en [`compare/`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare) (`l04_generics.cs`, `l04_variance.cs`, `L04Erasure.java`, `L04Variance.java`) y [`compare_fail/`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail) (`l04_invariant_list.cs`, `l04_variance_annotation.cs`, `L04NewT.java`, `L04Wildcards.java`).

La sintaxis de los genéricos es la que ya conoces, `function first<T>(items: T[]): T`, y el propósito también. Las diferencias están en tres sitios, que esta lección recorre por orden: lo que existe en tiempo de ejecución, cómo decide `tsc` que un tipo genérico es asignable a otro, y sobre qué puede variar un parámetro de tipo, ya que en TypeScript puede ser los nombres de propiedad de otro tipo.

## Parámetros de tipo, inferencia y restricciones

```ts
// examples/l04_generics.ts
import { show } from './show.ts';

// Un parámetro de tipo, inferido a partir del argumento
function first<T>(items: readonly T[]): T | undefined {
  return items[0];
}
const note = first(['E', 'A', 'D']); // T es string
const fret = first([0, 2, 2]); // T es number
show('note, fret', [note, fret]);
show('first<string>([])', first<string>([])); // un argumento de tipo explícito

// Una restricción: T debe tener una longitud, y conserva su propio tipo
function longest<T extends { length: number }>(a: T, b: T): T {
  return b.length > a.length ? b : a;
}
show("longest('capo', 'strings')", longest('capo', 'strings'));
show('longest([1, 2], [1, 2, 3])', longest([1, 2], [1, 2, 3]));

// keyof y el acceso indexado: la clave se comprueba, y el resultado tiene el tipo de esa propiedad
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

// Un tipo genérico, con un valor por defecto
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

- `tsc` infiere `T` a partir de los argumentos, como C# y Java infieren los argumentos de tipo de un método, y un `first<string>([])` explícito sirve cuando no se puede inferir nada.
- Una **restricción**, `T extends { length: number }`, se escribe con `extends`, como los límites de Java, y puede ser cualquier tipo, incluida una forma: las cadenas y los arrays tienen ambos un `length`, y `longest` devuelve el tipo que recibió, `string` o `number[]`, no `{ length: number }`. En C#, la misma función necesita una interfaz que implementen los dos tipos ([restricciones de parámetros de tipo](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters)).
- **`keyof T`** es la unión de los nombres de propiedad de `T`, y **`T[K]`** el tipo de la propiedad `K`. `get(standard, 'notes')` devuelve un `string[]` y `get(standard, 'capo')` un `number`, desde la misma función: el tipo de retorno depende del valor de un argumento, algo que los genéricos de C# y Java no pueden expresar.
- Un parámetro de tipo puede tener un valor por defecto, `Cursor = number`, como un parámetro opcional de C#, pero para tipos.

Las restricciones se comprueban en la llamada:

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

El segundo mensaje muestra cómo funciona la inferencia: `tsc` tomó `T` del primer argumento, el tipo literal `"capo"`, y luego comparó el segundo argumento con él, en lugar de buscar un tipo que encaje con los dos. El tercero convierte una errata en un error de compilación, cosa que una clave `string` no haría. Sin `tsc`, `longest(10, 20)` devuelve `10`, porque `(20).length` es `undefined` y `undefined > undefined` es `false`, y `get` lee una propiedad que no existe.

## Ningún T en tiempo de ejecución

Los genéricos de C# están **reificados**: el runtime crea un `List<int>` distinto de un `List<string>`, y `typeof(T)`, `new T()` e `is T` funcionan. Los genéricos de Java se **borran** hasta su límite, y `javac` inserta casts allí donde sale un valor. TypeScript va un paso más allá: se elimina el tipo entero, y no queda nada a lo que hacer un cast.

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

El programa C# crea un `Tuner` con `new T()`, imprime `Int32` para `typeof(T)`, y distingue los dos tipos de lista. `ArrayList<Integer>` y `ArrayList<String>` son la misma clase en Java, y la cadena `"twelve"` se queda en una `List<Integer>` hasta que falla el cast que `javac` insertó en `counts.get(0)`. En TypeScript, el mismo código no compila, y no se ejecutaría si compilara:

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

Java también rechaza `new T()`, y solo permite `instanceof T` donde el cast se puede comprobar. Lo que los sustituye, en los dos lenguajes, es pasar un valor que exista en tiempo de ejecución:

```ts
// examples/l04_erasure.ts
import { attempt, show } from './show.ts';

// T solo aparece en el tipo de retorno: el llamador lo elige, y nada lo comprueba
function parse<T>(json: string): T {
  return JSON.parse(json);
}
const count = parse<number>('"twelve"');
show('typeof count', typeof count);
attempt('count.toFixed(1)', () => count.toFixed(1));

// No hay T en tiempo de ejecución: pasa como valor lo que la función necesita, aquí un constructor
class Tuner {
  reference = 440;
}
function create<T>(ctor: new () => T): T {
  return new ctor();
}
show('create(Tuner)', create(Tuner));

// O una guarda de tipo, que lleva la comprobación al tiempo de ejecución
function parseArray<T>(json: string, isItem: (value: unknown) => value is T): T[] {
  const value: unknown = JSON.parse(json);
  if (!Array.isArray(value) || !value.every(isItem)) throw new TypeError(`not the expected array: ${json}`);
  return value;
}
const isNumber = (value: unknown): value is number => typeof value === 'number';
show("parseArray('[0, 2, 2]', isNumber)", parseArray('[0, 2, 2]', isNumber));
attempt("parseArray('[0, \"2\"]', isNumber)", () => parseArray('[0, "2"]', isNumber));

// musicService.ts de GA, líneas 17-23: una guarda genérica comprueba la forma, nunca el T
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

- **`parse<T>`** es la firma más peligrosa de TypeScript: `T` solo aparece en el tipo de retorno, así que el llamador lo elige y nada puede comprobarlo. `parse<number>('"twelve"')` devuelve una cadena con tipo `number`. Compila sin `as` porque `JSON.parse` devuelve `any`, y aun así es una aserción, escondida en un genérico.
- **`create(ctor: new () => T)`** recibe el constructor, un valor, donde C# usaría `where T : new()`; `T` se infiere a partir de él.
- **`parseArray(json, isItem)`** recibe una guarda de tipo para los elementos. La comprobación se ejecuta, y un `"2"` entre los números se rechaza en la frontera: es el patrón de la [lección 3](../03-unions-and-narrowing/#predicados-de-tipo-y-funciones-de-aserción) hecho genérico.

### En GuitarAlchemist/ga: una guarda genérica que no comprueba su T

La última parte del ejemplo viene de [`Apps/ga-client/src/services/musicService.ts`, líneas 17-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/musicService.ts#L17-L49), por donde pasa cada llamada a la API de teoría musical:

```ts
const isApiResponse = <T>(value: unknown): value is ApiResponse<T> => {
  if (!value || typeof value !== 'object') {
    return false;
  }

  return 'success' in value && 'data' in value;
};

const parseJson = async <T>(response: Response): Promise<T> => {
  // […] un error para un estado distinto de 2xx
  const json = await response.json();
  if (isApiResponse<T>(json)) {
    // […] un error cuando success es false o data es null
    return json.data;
  }

  return json as T;
};
```

`isApiResponse<T>` promete un `ApiResponse<T>` y comprueba dos nombres de propiedad: `T` lo elige el llamador, como en `parse<T>`. Cuando la comprobación falla, `json as T` devuelve el cuerpo de todos modos, sea lo que sea. `fetchKeyNotes` devuelve entonces un `Promise<KeyNotes>` que contiene lo que envió el servidor, y un cambio en la forma de la API aparece como un `TypeError` en un componente, como el que imprimió el ejemplo para `json.data.map`, lejos de esta función. Es un patrón habitual, y razonable cuando el servidor y su cliente se construyen juntos; el segundo ejercicio escribe la versión que comprueba. En el mismo repositorio, [`CourseViewer.tsx`, línea 152](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/CourseViewer.tsx#L152-L159), tiene `function loadQueue<T>(key: string): T[]`, que devuelve `JSON.parse(raw)` desde `localStorage` sin siquiera un `as`, ya que el `any` de la [lección 2](../02-structural-typing/#any-unknown-y-never) se convierte en `T[]` en silencio.

## Varianza

La varianza responde a una pregunta: si un `Guitar` es un `Instrument`, ¿una lista de guitarras es una lista de instrumentos? ¿Y una función que recibe guitarras, o una que recibe instrumentos?

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

// Los arrays son covariantes: un Guitar[] se acepta como Instrument[], y el alias puede añadir un piano
const guitars: Guitar[] = [guitar];
const instruments: Instrument[] = guitars;
instruments.push(piano);
show('guitars.length', guitars.length);
attempt('guitars[1].tune()', () => guitars[1].tune());

// Una propiedad de tipo función se comprueba de forma contravariante (strictFunctionTypes); un método no
interface WithProperty {
  play: (instrument: Instrument) => string;
}
interface WithMethod {
  play(instrument: Instrument): string;
}
const tuneGuitar = (g: Guitar) => g.tune();
const withMethod: WithMethod = { play: tuneGuitar }; // aceptado: los parámetros de los métodos son bivariantes
attempt('withMethod.play(piano)', () => withMethod.play(piano));
const withProperty: WithProperty = { play: (i: Instrument) => i.name }; // una función de Instrument es válida
show('withProperty.play(piano)', withProperty.play(piano));

// Anotaciones de varianza: out para un tipo que solo produce T, in para uno que solo lo consume
interface Source<out T> {
  next(): T;
}
interface Sink<in T> {
  accept(value: T): void;
}
const guitarSource: Source<Guitar> = { next: () => guitar };
const instrumentSource: Source<Instrument> = guitarSource; // out: Source<Guitar> es un Source<Instrument>
const names: string[] = [];
const instrumentSink: Sink<Instrument> = { accept: (i) => names.push(i.name) };
const guitarSink: Sink<Guitar> = instrumentSink; // in: Sink<Instrument> es un Sink<Guitar>
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

**Los arrays son covariantes, y no se comprueban.** `tsc` acepta un `Guitar[]` como `Instrument[]`, igual que C# y Java aceptan los arrays, y el alias mete un piano entre las guitarras. C# y Java comprueban cada escritura en un array en tiempo de ejecución; JavaScript no tiene tipo de elemento que comprobar, así que el piano entra, y el error llega más tarde, desde el código que confió en `guitars[1]`:

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

Las clases genéricas de C# como `List<T>` son invariantes, y las de Java también, mientras que TypeScript compararía `List<Guitar>` y `List<Instrument>` miembro a miembro:

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

**Parámetros de función: las propiedades se comprueban, los métodos no.** Una función que necesita un `Guitar` no puede sustituir sin riesgo a una que acepta cualquier `Instrument`: los parámetros deben ser contravariantes. Con [`strictFunctionTypes`](https://www.typescriptlang.org/tsconfig/#strictFunctionTypes), que forma parte de `strict`, `tsc` lo comprueba para las propiedades cuyo tipo es una función, `play: (instrument: Instrument) => string`. No lo hace para los métodos, `play(instrument: Instrument): string`, cuyos parámetros siguen siendo **bivariantes**: `withMethod` acepta `tuneGuitar`, y llamarlo con un piano lanza una excepción. La excepción es deliberada: en palabras de las [notas de la versión 2.6 de TypeScript](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-6.html), los métodos quedan excluidos "to ensure generic classes and interfaces (such as `Array<T>`) continue to mostly relate covariantly", algo que `push(item: T)` impediría de otro modo. Escribe los tipos de callback como propiedades cuando quieras que se comprueben.

**Anotaciones de varianza.** C# declara la varianza en las interfaces y los delegados, `IEnumerable<out T>`, `Action<in T>`, y la comprueba ([covarianza y contravarianza](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)). Java la declara donde se usa un tipo, `List<? extends Object>` ([comodines](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html)). TypeScript la calcula a partir de la estructura, y desde la [4.7](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters) acepta anotaciones `out` e `in` opcionales, como en C#:

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

// in promete que T solo se consume, y next lo devuelve
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

El primer error es `strictFunctionTypes` sobre una propiedad. Los dos siguientes son las anotaciones en acción: una fuente de instrumentos no es una fuente de guitarras, y un sumidero de guitarras no puede aceptar cualquier instrumento. El último detecta una anotación que contradice la estructura: `in T` en una interfaz que devuelve `T`. El mismo error en C#:

```text
> dotnet run l04_variance_annotation.cs
compare_fail/l04_variance_annotation.cs(6,17): error CS1961: Invalid variance: The type parameter 'T' must be contravariantly valid on 'IMislabeled<T>.Accept(T)'. 'T' is covariant.

The build failed. Fix the build errors and run again.
```

La comprobación de C# es completa, y la de TypeScript no. El error contrario, `interface Mislabeled<out T> { accept(value: T): void }`, compila con `tsc` 7.0.2 sin ningún mensaje, porque `accept` es un método y su parámetro es bivariante, así que `T` en esa posición es compatible con las dos anotaciones. El [handbook](https://www.typescriptlang.org/docs/handbook/2/generics.html#variance-annotations) es tajante sobre ellas: las anotaciones no cambian cómo se comparan estructuralmente los tipos, solo deben escribirse cuando coinciden con la estructura, y sirven sobre todo para depurar un tipo o, tras medir el rendimiento, para acelerar la comprobación de tipos extraordinariamente complejos.

La ejecución con `node` de ese fragmento muestra la eliminación de tipos (*type stripping*) en acción. `declare const instrumentSource` solo existe para `tsc` y se eliminó, así que la línea 24 lanza un `ReferenceError`, y la línea que imprime Node.js tiene espacios donde estaba la anotación de tipo: los tipos se sustituyen por espacios en blanco para que los números de línea y de columna sigan siendo los del fuente ([lección 1](../01-compiler-and-tooling/)).

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
| Tipos genéricos en tiempo de ejecución | reificados: `typeof(T)`, `new T()`, `is T` | borrados hasta el límite, casts insertados por `javac` | borrados por completo |
| Restricciones | `where T : IComparable<T>, new()` | `<T extends Comparable<T>>` | `<T extends Shape>`, cualquier tipo, formas incluidas |
| Arrays | covariantes, escrituras comprobadas (`ArrayTypeMismatchException`) | covariantes, escrituras comprobadas (`ArrayStoreException`) | covariantes, sin comprobar |
| Clases genéricas | invariantes, varianza en interfaces y delegados | invariantes, varianza en el punto de uso con `?` | estructural: calculada a partir de los miembros |
| Parámetros de función | contravariantes | — | contravariantes para las propiedades de tipo función, bivariantes para los métodos |
| Anotaciones | `out T`, `in T`, comprobadas por completo | `? extends T`, `? super T` | `out T`, `in T`, opcionales, comprobadas en parte |

## keyof, acceso indexado y tipos mapeados

Los tipos de TypeScript se pueden calcular a partir de otros tipos. [`keyof`](https://www.typescriptlang.org/docs/handbook/2/keyof-types.html) y el [acceso indexado](https://www.typescriptlang.org/docs/handbook/2/indexed-access-types.html) aparecieron en `get<T, K extends keyof T>`; un [**tipo mapeado**](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html) recorre las claves de un tipo y construye una propiedad para cada una, `{ [K in keyof T]: … }`.

La [lección 4 de JavaScript](../../javascript-for-csharp-java/04-objects-prototypes-classes/#en-guitaralchemistga-fusionar-las-preferencias-guardadas) examinó las opciones de escena de GA, fusionadas a partir de valores por defecto, una URL y `localStorage` con `Object.assign`, que dejaba pasar claves desconocidas y tipos equivocados. La versión tipada necesita un validador por opción, y un tipo mapeado deriva el tipo de esa tabla a partir de `SceneOptions`:

```ts
// examples/l04_mapped.ts
import { show } from './show.ts';

interface SceneOptions {
  stars: boolean;
  tower: boolean;
  skyboxMode: 'milky-way' | 'nebula';
}

// keyof lista los nombres de propiedad como una unión; T[K] es el tipo de una propiedad
type OptionName = keyof SceneOptions; // 'stars' | 'tower' | 'skyboxMode'
type Skybox = SceneOptions['skyboxMode']; // 'milky-way' | 'nebula'
const name: OptionName = 'skyboxMode';
const skybox: Skybox = 'nebula';
show('name, skybox', [name, skybox]);

// Un tipo mapeado construye una propiedad por cada clave de otro tipo
type Validators<T> = {
  [K in keyof T]: (value: unknown) => value is T[K];
};

const isBoolean = (value: unknown): value is boolean => typeof value === 'boolean';
const sceneValidators: Validators<SceneOptions> = {
  stars: isBoolean,
  tower: isBoolean,
  skyboxMode: (value): value is Skybox => value === 'milky-way' || value === 'nebula',
};

// Una única fusión genérica para cualquier tipo de opciones: solo claves conocidas, solo valores válidos, y la URL al final
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

// Los tipos mapeados de la biblioteca: Partial, Readonly, Pick y Record
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

- `Validators<SceneOptions>` es `{ stars: (value: unknown) => value is boolean; tower: …; skyboxMode: (value: unknown) => value is 'milky-way' | 'nebula' }`, escrito una sola vez para cualquier tipo de opciones.
- `merge` es genérica sobre `T`, y `validators[key](value)` estrecha `value` a `T[keyof T]`, así que `result[key] = value` compila. El `"stars": "yes"` no pasa su validador, el `bloom` desconocido nunca se lee, y la clave `__proto__` del JSON, que `JSON.parse` crea como una propiedad normal, tampoco está en los validadores: `isAdmin` no llega al resultado.
- Quedan dos aserciones, y cada una dice por qué. `Object.keys` devuelve `string[]`, no `(keyof T)[]`, porque el tipado estructural permite que un objeto tenga más claves de las que lista su tipo; aquí el objeto es la tabla de validadores, cuyas claves son exactamente las de `T`. Y de `saved` solo se sabe que es un `object`, que no tiene firma de índice, así que se lee como un `Record<PropertyKey, unknown>`, cuyos valores siguen siendo `unknown`.
- `Partial`, `Readonly`, `Pick` y `Record` son tipos mapeados de la biblioteca estándar ([utility types](https://www.typescriptlang.org/docs/handbook/utility-types.html)); `lib.es5.d.ts` define `Partial<T>` como `{ [P in keyof T]?: T[P] }`. La última línea de la salida muestra que `Readonly` y `Pick` son vistas, como en la [lección 2](../02-structural-typing/#readonly): `toggles` tiene un tipo con dos propiedades y contiene tres.

El tipo sigue a las opciones. Añade una, y la tabla de validadores queda incompleta hasta que alguien escriba su comprobación:

```ts
// errors/l04_mapped.ts
// Una opción nueva: el objeto de validadores ya no coincide, así que tsc lo señala
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

C# alcanzaría la misma garantía con un generador de código fuente o con reflexión, y Java con un procesador de anotaciones. En TypeScript, la relación entre los dos tipos es un tipo, y `tsc` la comprueba en cada build.

## Puntos clave

- `tsc` infiere los argumentos de tipo a partir de la llamada, y compara un argumento en conflicto con lo que infirió primero; las restricciones usan `extends` y pueden ser formas.
- `keyof T` y `T[K]` permiten que un tipo de retorno dependa de una clave pasada como valor.
- Los tipos se borran por completo: nada de `new T()`, ni `instanceof T`, ni `typeof(T)`. Pasa en su lugar un constructor o una guarda de tipo.
- Un `T` que solo aparece en el tipo de retorno, `parse<T>(json): T`, es una aserción sin comprobar; también lo es una guarda genérica que no comprueba `T`.
- Los arrays son covariantes y no se comprueban. Las propiedades de tipo función se comprueban de forma contravariante con `strictFunctionTypes`; los parámetros de los métodos siguen siendo bivariantes.
- Las anotaciones `in` y `out` son opcionales, y `tsc` no detecta todas las erróneas.
- Un tipo mapeado, `{ [K in keyof T]: … }`, deriva un tipo de otro, y mantiene los dos sincronizados cuando cambia el primero.

## Ejercicios

1. Escribe `groupBy(items, keyOf)`, que agrupa los elementos de un array por la clave que devuelve `keyOf`, con un tipo de retorno en el que agrupar acordes por su calidad dé las propiedades `major`, `minor` y `diminished`, cada una posiblemente ausente.

<details>
<summary>Solución</summary>

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
const byQuality = groupBy(chords, (chord) => chord.quality); // K es 'major' | 'minor' | 'diminished'
console.log(byQuality.minor?.map((chord) => chord.name));
console.log(Object.keys(groupBy(chords, (chord) => chord.name.length)));
```

```text
[ 'Dm', 'Em' ]
[ '1', '2', '4' ]
```

`K extends PropertyKey`, que es `string | number | symbol`, permite que `K` se infiera como la unión literal de las calidades, y `Partial` dice que una calidad puede no tener acordes, de ahí `byQuality.minor?.map`. La segunda llamada agrupa por un `number`, e imprime las claves como cadenas: las claves de los objetos JavaScript son cadenas, y `Record<number, …>` describe cómo se escriben, no lo que devuelve `Object.keys`. Un [`Map<K, T[]>`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map) conserva los números; `Object.groupBy`, en ES2024, devuelve el mismo `Partial<Record<K, T[]>>` que esta solución.

</details>

2. Escribe `isApiResponseOf(value, isData)`, una versión del `isApiResponse` de GA cuyo `T` se comprueba, y úsala para una respuesta cuyo `data` debe ser un array de cadenas.

<details>
<summary>Solución</summary>

[`solutions/l04_ex2_api_response.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l04_ex2_api_response.ts):

```ts
// solutions/l04_ex2_api_response.ts
interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: string;
}
type Guard<T> = (value: unknown) => value is T;

// La guarda de T es un parámetro: la comprobación de data se ejecuta, en lugar de prometerse
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

La guarda de `data` es un parámetro, así que `T` se infiere a partir de ella, y el llamador no puede elegir un `T` sin aportar la comprobación. En `parseJson`, el recurso final `json as T` tendría que convertirse en un error lanzado: una respuesta que no es un `ApiResponse` de los datos esperados es un error de la API, y decirlo donde ocurre ahorra buscarlo en un componente.

</details>

3. Escribe `pick(value, keys)`, que devuelve un objeto con solo las propiedades listadas, con el tipo `Pick`, de modo que una clave que no existe y una propiedad que no se eligió sean ambas errores de compilación.

<details>
<summary>Solución</summary>

[`solutions/l04_ex3_pick.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l04_ex3_pick.ts):

```ts
// solutions/l04_ex3_pick.ts
function pick<T extends object, K extends keyof T>(value: T, keys: readonly K[]): Pick<T, K> {
  const result = {} as Pick<T, K>; // una aserción: el bucle de abajo rellena cada clave de K
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

// Nunca se llama: cada línea muestra un error que tsc rechaza
function mistakes() {
  // @ts-expect-error: 'weather' no es una clave de SceneOptions
  pick(options, ['weather']);
  // @ts-expect-error: skyboxMode no se eligió
  return toggles.skyboxMode;
}
console.log(typeof mistakes);
```

```text
{ stars: true, tower: false } [ 'stars', 'tower' ]
function
```

`{}` no es un `Pick<T, K>` hasta que el bucle se ha ejecutado, y `tsc` no puede seguir un bucle que rellena cada clave de una unión, así que la función empieza con una aserción y un comentario que dice qué la hace cierta. Esa es la forma habitual de una utilidad genérica: por fuera, una firma pequeña y comprobada, y por dentro, una aserción justificada.

</details>

## Fuentes

- [TypeScript handbook — Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html), [Keyof type operator](https://www.typescriptlang.org/docs/handbook/2/keyof-types.html), [Indexed access types](https://www.typescriptlang.org/docs/handbook/2/indexed-access-types.html), [Mapped types](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html), [Utility types](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [Referencia de TSConfig — strictFunctionTypes](https://www.typescriptlang.org/tsconfig/#strictFunctionTypes); notas de la versión [2.6 — strict function types](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-6.html), [4.7 — anotaciones de varianza](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters)
- [Microsoft — Genéricos](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/generics), [Restricciones de parámetros de tipo](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters), [Covarianza y contravarianza en genéricos](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)
- [The Java Tutorials — Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html), [Wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html), [Restrictions on generics](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html)
