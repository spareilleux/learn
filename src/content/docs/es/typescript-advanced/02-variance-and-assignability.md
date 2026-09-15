---
title: 2. Varianza y asignabilidad
description: Cómo mide tsc la varianza y dónde la medida no es segura, las anotaciones in out, el truco de bivarianza de los métodos de @types/react, satisfies frente a anotaciones y aserciones, los parámetros de tipo const, NoInfer y la inferencia a partir del tipo de retorno, exactOptionalPropertyTypes, los tipos débiles y la comparabilidad, junto a la varianza comprobada de C# y los comodines de Java.
sidebar:
  order: 2
---

Código: los archivos [`examples/l02_*`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples) y [`errors/l02_assignability.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/errors/l02_assignability.ts), y los equivalentes en C# y Java en [`compare/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare) (`l02_variance.cs`, `L02TargetTyping.java`) y [`compare_fail/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare_fail) (`l02_variant_setter.cs`, `l02_return_inference.cs`, `L02Wildcard.java`).

La [lección 4 del curso base](../../typescript-for-csharp-java/04-generics/#varianza) mostró las reglas: los arrays son covariantes y no se comprueban, las propiedades de tipo función se comprueban de forma contravariante con `strictFunctionTypes`, los parámetros de los métodos siguen siendo bivariantes, y las anotaciones `in` y `out` son opcionales. Esta lección las mide, encuentra dónde dejan pasar un valor incorrecto, y luego mira la otra mitad de "¿es esto asignable?": cómo decide `tsc` qué tipo tiene un valor en primer lugar, y cómo cambian esa decisión `satisfies`, `const` y `NoInfer`.

## Medir la varianza

La varianza puede observarse sin leer el verificador: construye el mismo tipo genérico para un subtipo y un supertipo, y prueba la asignabilidad en los dos sentidos.

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

// Varianza medida, probada sobre la asignabilidad en los dos sentidos
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
// Un parámetro de método es bivariante, incluso con strictFunctionTypes
type _4 = Expect<Equal<Variance<WithMethod<Guitar>, WithMethod<Instrument>>, 'bivariant'>>;
// Un parámetro de un parámetro vuelve a ser covariante: dos posiciones contravariantes se anulan
type _5 = Expect<Equal<Variance<Callback<Guitar>, Callback<Instrument>>, 'covariant'>>;
// Una propiedad mutable se lee y se escribe, y aun así se mide covariante
type _6 = Expect<Equal<Variance<Slot<Guitar>, Slot<Instrument>>, 'covariant'>>;
type _7 = Expect<Equal<Variance<ReadonlySlot<Guitar>, ReadonlySlot<Instrument>>, 'covariant'>>;

// La propiedad mutable covariante no es segura: un piano entra en la ranura de la guitarra a través de un alias
const guitar: Guitar = { name: 'guitar', strings: 6, tune: () => 'EADGBE' };
const guitarSlot: Slot<Guitar> = { value: guitar };
const instrumentSlot: Slot<Instrument> = guitarSlot;
instrumentSlot.value = { name: 'piano' };
attempt('guitarSlot.value.tune()', () => guitarSlot.value.tune());

// in out declara la invarianza que la estructura no muestra; el mismo alias ya no compila
interface SafeSlot<in out T> {
  value: T;
}
type _8 = Expect<Equal<Variance<SafeSlot<Guitar>, SafeSlot<Instrument>>, 'invariant'>>;
const safeGuitarSlot: SafeSlot<Guitar> = { value: guitar };
// @ts-expect-error: SafeSlot<Guitar> no es un SafeSlot<Instrument>
const safeInstrumentSlot: SafeSlot<Instrument> = safeGuitarSlot;
show('safeGuitarSlot.value.tune()', safeGuitarSlot.value.tune());

// El truco de bivarianza de los métodos de @types/react: un tipo función que sigue siendo bivariante con strictFunctionTypes
type EventHandler<E> = { bivarianceHack(event: E): void }['bivarianceHack'];
interface ClickEvent {
  x: number;
}
interface DoubleClickEvent extends ClickEvent {
  count: 2;
}
type _9 = Expect<Equal<Variance<EventHandler<DoubleClickEvent>, EventHandler<ClickEvent>>, 'bivariant'>>;
const onDoubleClick: EventHandler<DoubleClickEvent> = (event) => console.log(`double click ${event.count}`);
const onClick: EventHandler<ClickEvent> = onDoubleClick; // aceptado: el truco deja pasar un manejador más específico
attempt('onClick({ x: 3 })', () => onClick({ x: 3 }));
```

```text
guitarSlot.value.tune()            TypeError: guitarSlot.value.tune is not a function
safeGuitarSlot.value.tune()        'EADGBE'
double click undefined
onClick({ x: 3 })                  undefined
```

Las pruebas de tipos forman una tabla de lo que mide `tsc` 7.0.2, para `Guitar extends Instrument`:

| Miembro que usa `T` | Medida | ¿Segura? |
|---|---|---|
| `get: () => T` | covariante | sí |
| `set: (value: T) => void` | contravariante | sí |
| los dos | invariante | sí |
| `set(value: T): void`, un método | bivariante | no |
| `subscribe: (listener: (value: T) => void) => void` | covariante | sí |
| `value: T`, una propiedad mutable | covariante | no |
| `readonly value: T` | covariante | sí |

Dos filas no son seguras por diseño. Un parámetro de método es bivariante, como mostró el curso base. Y una propiedad mutable se mide covariante, aunque pueda escribirse: `Slot<Guitar>` se acepta como un `Slot<Instrument>`, el alias escribe un piano en ella, y `guitarSlot.value.tune()` lanza una excepción. El [handbook sobre la compatibilidad de tipos](https://www.typescriptlang.org/docs/handbook/type-compatibility.html#a-note-on-soundness) lo dice claramente: "TypeScript's type system allows certain operations that can't be known at compile-time to be safe", y las propiedades se comparan por su tipo de lectura. C# rechaza la declaración equivalente, porque un setter consume `T`:

```text
> dotnet run l02_variant_setter.cs
compare_fail/l02_variant_setter.cs(7,5): error CS1961: Invalid variance: The type parameter 'T' must be invariantly valid on 'ISlot<T>.Value'. 'T' is covariant.

The build failed. Fix the build errors and run again.
```

En C#, `out T` solo se permite en una propiedad sin setter, como `IReadOnlySlot<out T>` en el programa de comparación, y un `List<Guitar>` se convierte en `IReadOnlyList<Instrument>` pero no en `IList<Instrument>`:

```csharp
// compare/l02_variance.cs
// C# declara la varianza en las interfaces, y la comprueba contra cada miembro
List<Guitar> guitars = [new("guitar", 6)];
IReadOnlyList<Instrument> instruments = guitars; // IReadOnlyList<out T>: covariante, y de solo lectura
IReadOnlySlot<Instrument> slot = new Slot<Guitar>(guitars[0]);
Console.WriteLine($"{instruments[0].Name}, {slot.Value.Name}");

// La inferencia solo usa los argumentos: un parámetro de tipo que solo aparece en el tipo de retorno debe escribirse
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

**`in out T` restablece la invarianza.** Una anotación no puede cambiar cómo se comparan los tipos estructuralmente, pero sustituye a la varianza medida cuando `tsc` compara dos instanciaciones del mismo tipo genérico. `SafeSlot<in out T>` es invariante, y el alias ya no compila. Anota así los contenedores mutables cuando la falta de seguridad importa. La anotación solo se comprueba contra la estructura en el sentido que permite: `in T` en un tipo que lee `T` se rechaza con `TS2636`, mientras que `in out T`, que no permite nada, se acepta en cualquier tipo.

**Dos posiciones contravariantes dan una covariante.** `subscribe` toma un listener, que toma un `T`: una suscripción a guitarras puede usarse como suscripción a instrumentos, porque cada listener escrito para instrumentos acepta guitarras. El mismo razonamiento explica la intersección que produjo `infer` en la [lección 1](../01-type-level-programming/#tipos-condicionales) para dos parámetros.

**El truco de bivarianza.** [`@types/react`](https://github.com/DefinitelyTyped/DefinitelyTyped/blob/a542a0b0a0332f463dd42042f5bfb6cf36a61747/types/react/index.d.ts#L2316) declara sus manejadores de eventos como `{ bivarianceHack(event: E): void }["bivarianceHack"]`: el tipo de un método, extraído por acceso indexado, es un tipo función que conserva la bivarianza del método. `EventHandler<DoubleClickEvent>` se acepta donde se espera un `EventHandler<ClickEvent>`, y el manejador lee un `count` que no está. Los tipos de React lo hacen a propósito, para que un manejador escrito para un evento específico pueda pasarse a una prop tipada con uno más general; el precio es el `undefined` de la salida.

### Dónde se usa la medida

`tsc` no compara `Slot<Guitar>` y `Slot<Instrument>` miembro a miembro cada vez. Para una interfaz, clase o alias de tipo genérico, [`getVariancesWorker`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/relater.go#L1341-L1400) mide la varianza de cada parámetro de tipo una sola vez: instancia el tipo con dos tipos marcadores, uno subtipo del otro, y prueba la asignabilidad en los dos sentidos. Un tercer marcador, sin relación con los otros, distingue un parámetro bivariante de uno que no se usa en absoluto. El resultado se guarda en caché, y las comparaciones posteriores de dos instanciaciones solo comparan sus argumentos de tipo. Cuando la comparación de los marcadores pasó por construcciones que la medida no puede representar, como un tipo condicional, el resultado se marca como [no medible o no fiable](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/types.go#L300-L309), y el verificador recurre a una comparación estructural.

Una anotación se salta la medición: en la misma función, `out` da covariante, `in` contravariante e `in out` invariante, sin instanciar nada. Ese es el uso para el que se diseñaron las [anotaciones de varianza de la 4.7](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters): en un tipo muy grande, una anotación ahorra la medición, y en un tipo cuya medida no es fiable, da la respuesta pretendida. El handbook recomienda escribirlas solo cuando coinciden con la estructura, y sobre todo después de perfilar.

| | C# | Java | TypeScript |
|---|---|---|---|
| Dónde se declara la varianza | interfaces y delegados, `in`/`out` | en el lugar de uso, `? extends`/`? super` | en ningún sitio: se mide; `in`/`out` opcionales |
| Una propiedad con escritura | invariante, `out` rechazado (`CS1961`) | — | covariante, no segura; `in out` para corregirlo |
| Parámetros de tipos función | contravariantes (delegados, `in T`) | — | contravariantes para las propiedades, bivariantes para los métodos |
| Comprobada | por completo | por completo, con conversión de captura | en parte |

Java pone la varianza en la variable, no en el tipo. Un `List<? extends Object>` puede leerse, y no se le puede añadir nada, que es la forma en el lugar de uso de `out T`:

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

## satisfies, anotaciones y aserciones

Cuatro formas de decir "este objeto es un `Record<GovernanceHealthStatus, HexColor>`" dan cuatro tipos distintos:

```ts
// examples/l02_satisfies.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
type HexColor = `#${string}`;

// 1. Una anotación: el objeto se comprueba, y su tipo pasa a ser la anotación, así que se pierden los colores literales
const annotated: Record<GovernanceHealthStatus, HexColor> = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
};
type _1 = Expect<Equal<(typeof annotated)['error'], HexColor>>;

// 2. satisfies: la misma comprobación, y el tipo sigue siendo el inferido a partir del objeto. Aquí se conservan los literales
// porque el tipo contextual, un tipo de plantilla literal, contiene tipos literales; frente a string se ensanchan
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

// 3. as const satisfies: valores literales sea cual sea el tipo contextual, propiedades readonly, y la comprobación
const colors = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
} as const satisfies Record<GovernanceHealthStatus, HexColor>;
type _3 = Expect<Equal<(typeof colors)['error'], '#FF4444'>>;
type _3b = Expect<Equal<typeof colors, { readonly error: '#FF4444'; readonly warning: '#FFB300'; readonly healthy: '#33CC66'; readonly unknown: '#888888'; readonly contradictory: '#FF44FF' }>>;

// 4. as: una aserción, que solo comprueba que un tipo es comparable con el otro; un estado que falta pasa
const partial = { error: '#FF4444', healthy: '#33CC66' };
const asserted = partial as Record<GovernanceHealthStatus, HexColor>;
show('asserted.warning', asserted.warning);

// satisfies proporciona el tipo contextual: el parámetro de cada función se tipa sin anotación
interface Formatters {
  [status: string]: (score: number) => string;
}
const formatters = {
  healthy: (score) => `healthy (${score.toFixed(2)})`,
  warning: (score) => `watch (${Math.round(score * 100)}%)`,
} satisfies Formatters;
show('formatters.healthy(0.93)', formatters.healthy(0.93));
// El tipo inferido conserva exactamente las dos claves: formatters.error sería un error de compilación, no undefined en tiempo de ejecución
type _4 = Expect<Equal<keyof typeof formatters, 'healthy' | 'warning'>>;

// VoxtralTTS.ts de GA comprueba así el cuerpo de una petición, antes de que JSON.stringify lo borre todo
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

1. **Una anotación** comprueba el objeto y sustituye su tipo por la anotación. `annotated.error` es un `HexColor`: el hecho de que sea `'#FF4444'` se ha perdido.
2. **[`satisfies`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html#the-satisfies-operator)** (4.9) comprueba el objeto contra el tipo, y conserva el tipo inferido a partir del objeto. Que los literales sobrevivan depende del tipo contextual: frente a `` `#${string}` ``, un tipo de plantilla literal, el verificador conserva `'#FF4444'`; frente a `string`, lo ensancha a `string`, como muestra `widened`. Esperaba que el literal se ensanchara en los dos casos, y la prueba de tipos `_2` me corrigió.
3. **`as const satisfies`** conserva los literales sea cual sea el tipo contextual, hace `readonly` cada propiedad, y sigue comprobando que no falte ningún estado y que cada valor sea un color hexadecimal.
4. **Una aserción**, `as`, no comprueba casi nada: un tipo debe ser comparable con el otro. `partial`, con dos estados, es comparable con el record, ya que el record es asignable a `{ error: string; healthy: string }`, y `asserted.warning` es `undefined` en tiempo de ejecución. Con un literal de objeto escrito directamente tras `as`, `tsc` 7.0.2 sí informa de las propiedades que faltan (`TS2352`), porque los tipos del literal son entonces los propios literales, a los que el record no es asignable.

`satisfies` también proporciona un tipo contextual, por eso las funciones de `formatters` no necesitan anotación en el parámetro, y conserva las claves inferidas: `formatters.error` es un error de compilación, donde una anotación con una firma de índice lo habría tipado como función y habría devuelto `undefined`.

GA usa `satisfies` una vez en su biblioteca de componentes, en [`VoxtralTTS.ts`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/VoxtralTTS.ts#L248-L252), sobre el cuerpo de una petición justo antes de `JSON.stringify`, que borra todos los tipos. Es el sitio adecuado: el objeto conserva su tipo inferido, y un `voice_id` mal escrito se detectaría. El resto de la biblioteca usa anotaciones, como `HEALTH_STATUS_COLORS: Record<GovernanceHealthStatus, string>` en [`types.ts`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/types.ts#L203-L209), lo que basta donde solo importa la comprobación.

## Controlar la inferencia

```ts
// examples/l02_inference.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// Sin const, un argumento array se infiere como string[]: las notas se olvidan
function tuning<T extends readonly string[]>(notes: T): T {
  return notes;
}
const plain = tuning(['D', 'A', 'D', 'G', 'A', 'D']);
type _1 = Expect<Equal<typeof plain, string[]>>;

// Un parámetro de tipo const (5.0) infiere como si el llamador hubiera escrito as const
function constTuning<const T extends readonly string[]>(notes: T): T {
  return notes;
}
const dadgad = constTuning(['D', 'A', 'D', 'G', 'A', 'D']);
type _2 = Expect<Equal<typeof dadgad, readonly ['D', 'A', 'D', 'G', 'A', 'D']>>;
// Con una restricción mutable, la tupla se infiere mutable (desde la 5.3; de la 5.0 a la 5.2 recurría a string[])
function constMutable<const T extends string[]>(notes: T): T {
  return notes;
}
const fallback = constMutable(['D', 'A', 'D']);
type _3 = Expect<Equal<typeof fallback, ['D', 'A', 'D']>>;

// Cada argumento es un punto de inferencia: aquí initial añade su valor a la unión inferida a partir de states
function machine<S extends string>(states: readonly S[], initial: S) {
  return { states, current: initial };
}
const loose = machine(['idle', 'listening', 'processing'], 'understood');
type _4 = Expect<Equal<typeof loose.current, 'idle' | 'listening' | 'processing' | 'understood'>>;

// NoInfer (5.4) quita un argumento de la inferencia: S solo viene de states, e initial se comprueba contra él
function strictMachine<S extends string>(states: readonly S[], initial: NoInfer<S>) {
  return { states, current: initial };
}
const strict = strictMachine(['idle', 'listening', 'processing', 'understood'], 'idle');
type _5 = Expect<Equal<typeof strict.current, 'idle' | 'listening' | 'processing' | 'understood'>>;
// @ts-expect-error: 'speaking' no es uno de los estados
strictMachine(['idle', 'listening'], 'speaking');

// Inferencia a partir del tipo de retorno: el tipo declarado de la variable fluye hacia la llamada
function emptyList<T>(): T[] {
  return [];
}
const chords: string[] = emptyList(); // T es string, inferido del contexto, como hace Java y no hace C#
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

**Los parámetros de tipo `const`.** Sin ellos, un literal de array pasado a una función genérica se infiere como `string[]`. Un [parámetro de tipo `const`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html#const-type-parameters) (5.0) infiere como si el llamador hubiera escrito `as const`, y `dadgad` conserva sus seis notas como una tupla readonly. Las notas de la versión 5.0 advierten de que una restricción mutable, `T extends string[]`, hace que la inferencia recurra a `string[]`. Eso era cierto hasta la 5.2: ejecuté el mismo archivo con `tsc` 5.0.4, 5.2.2 y 5.3.3, y desde la 5.3 el resultado es la tupla mutable `['D', 'A', 'D']`, que también da `tsc` 7.0.2.

**Cada argumento es un punto de inferencia.** `machine(states, initial)` infiere `S` a partir de los dos parámetros. El `'understood'` pasado como `initial` no es un error para `tsc`: se convierte en un miembro más de `S`, y la máquina de estados tiene ahora un estado que no está en su lista. [`NoInfer<T>`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html#the-noinfer-utility-type) (5.4) quita una posición de la inferencia: `S` viene solo de `states`, e `initial` se comprueba contra él, así que `'speaking'` se rechaza.

**Inferencia a partir del tipo de retorno.** `const chords: string[] = emptyList()` infiere `T` como `string` a partir del tipo declarado de la variable. Java hace lo mismo con su [tipado por destino](https://docs.oracle.com/javase/tutorial/java/generics/genTypeInference.html#target_types) (*target typing*), y C# no: un parámetro de tipo que solo aparece en el tipo de retorno tiene que escribirse.

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

La advertencia `CS8321` que sigue al error es un efecto secundario: una vez que la llamada falla, el compilador considera que la función local no se usa.

## Opcional, undefined y null

```ts
// examples/l02_optional.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// El ViewerInfo de GA, de DataLoader.ts: el record C# del servidor tiene string? DisplayName = null y string? AvatarUrl = null
interface ViewerInfo {
  connectionId: string;
  color: string;
  displayName?: string;
  avatarUrl?: string | null;
}

// Con exactOptionalPropertyTypes, ? significa que la propiedad puede estar ausente, no que pueda contener undefined
const absent: ViewerInfo = { connectionId: 'a1', color: '#58a6ff' };
const withNull: ViewerInfo = { connectionId: 'b2', color: '#3fb950', avatarUrl: null };
show("'displayName' in absent", 'displayName' in absent);
show('Object.keys(withNull)', Object.keys(withNull));

// Leer una propiedad opcional sigue dando undefined cuando está ausente
type _1 = Expect<Equal<ViewerInfo['displayName'], string | undefined>>;
// Partial<T> mantiene la regla: un parche puede omitir una propiedad, y no puede ponerla a undefined
function applyPatch(viewer: ViewerInfo, patch: Partial<ViewerInfo>): ViewerInfo {
  return { ...viewer, ...patch };
}
show('applyPatch(absent, …)', applyPatch(absent, { displayName: 'Ada' }));

// Por qué importa la regla: un spread copia una propiedad propia que contiene undefined, y borra el valor
const viewer: ViewerInfo = { connectionId: 'c3', color: '#d2a8ff', displayName: 'Hari' };
const sloppyPatch = { displayName: undefined };
show('{ ...viewer, ...sloppyPatch }', { ...viewer, ...sloppyPatch });

// Un tipo débil solo tiene propiedades opcionales: tsc exige que un argumento comparta al menos una de ellas
interface TuningOptions {
  capo?: number;
  dropD?: boolean;
}
function tune(options: TuningOptions): string {
  return `capo ${options.capo ?? 0}, drop D ${options.dropD ?? false}`;
}
const fromSettings = { capo: 2, theme: 'dark' };
show('tune(fromSettings)', tune(fromSettings)); // comparte capo: aceptado, y theme se ignora

// null y undefined son valores distintos, y JSON solo tiene uno de ellos
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

El `tsconfig.json` del curso activa [`exactOptionalPropertyTypes`](https://www.typescriptlang.org/tsconfig/#exactOptionalPropertyTypes), que no forma parte de `strict`. Con ella, `displayName?: string` significa que la propiedad puede estar ausente, no que pueda contener `undefined`. La distinción existe en tiempo de ejecución: `'displayName' in absent` es `false`, mientras que un objeto con `displayName: undefined` tiene la propiedad. Importa para los spreads, como muestra la cuarta línea de la salida: un parche cuya propiedad contiene `undefined` borra el valor sobre el que se expande. `JSON.stringify` descarta la propiedad por completo, y conserva un `null`.

El [`ViewerInfo`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L218-L225) de GA declara `displayName?: string` y `avatarUrl?: string | null`. El record del servidor, en [`GovernanceHub.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Apps/ga-server/GaApi/Hubs/GovernanceHub.cs#L12-L18), es `string? DisplayName = null, string? AvatarUrl = null`, y la lección 4 muestra que SignalR envía los dos como `null`. El tipo de `displayName` es incorrecto, y el código funciona de todos modos, porque [`ForceRadiant.tsx`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L4363-L4382) lo lee con `?.` y `??`, que tratan `null` como `undefined`. Una comprobación escrita como `viewer.displayName !== undefined`, que es la que sugiere el tipo, dejaría pasar `null`.

El fragmento de abajo reúne las reglas de asignabilidad de esta sección y de las anteriores. Se ejecuta dos veces: una con las opciones del curso, y otra con `--exactOptionalPropertyTypes false`.

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

- **`TS2375`**: con `exactOptionalPropertyTypes`, `undefined` no es un valor de una propiedad opcional, ni en un objeto ni en un `Partial`. La segunda ejecución acepta las dos líneas.
- **`TS2559`**: un **tipo débil**, cuyas propiedades son todas opcionales, debe compartir al menos una propiedad con el valor que se le asigna. `{ theme, fontSize }` no comparte nada con `TuningOptions`, y se rechaza, aunque es estructuralmente asignable; `fromSettings` en el ejemplo comparte `capo`, y se acepta. La regla data de [TypeScript 2.4](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-4.html#weak-type-detection).
- **`TS2352`**: una aserción entre tipos que no son comparables. Pasar por `unknown` la silencia, por eso `as unknown as` es el patrón que hay que buscar en una base de código: la biblioteca de componentes de GA tiene 34.
- **`TS2322`** sobre `SafeSlot`: la anotación `in out` de la primera sección, y el mensaje muestra la comprobación en el otro sentido, de `{ name: string }` a `Guitar`.

## Puntos clave

- `tsc` mide la varianza a partir de la estructura; las propiedades mutables se miden covariantes y los parámetros de los métodos bivariantes, y ninguna de las dos cosas es segura. `in out T` hace invariante un tipo.
- Dos posiciones contravariantes se anulan; el truco de bivarianza de `@types/react` mantiene bivariante un tipo función a propósito.
- Una anotación sustituye el tipo inferido, `satisfies` lo comprueba y lo conserva, `as const satisfies` conserva además los literales, y `as` solo comprueba la comparabilidad.
- Los parámetros de tipo `const` infieren tuplas literales; `NoInfer` quita un argumento de la inferencia; un tipo de retorno esperado también guía la inferencia, como en Java y a diferencia de C#.
- `exactOptionalPropertyTypes` separa una propiedad ausente de una que contiene `undefined`, y `null` es un tercer caso que JSON conserva.

## Ejercicios

1. Una pequeña biblioteca de señales declara `interface Signal<T> { get(): T; set(value: T): void; subscribe(listener: (value: T) => void): () => void }`. Predice la varianza que mide `tsc`, compruébala con una prueba de tipos, y escribe dos versiones que sean invariantes.

<details>
<summary>Solución</summary>

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

// La señal tal como se escribió al principio: set es un método, así que su parámetro es bivariante, y T se mide covariante
interface Signal<T> {
  get(): T;
  set(value: T): void;
  subscribe(listener: (value: T) => void): () => void;
}
type _1 = Expect<Equal<Variance<Signal<Guitar>, Signal<Instrument>>, 'covariant'>>;

// Las propiedades de tipo función se comprueban con strictFunctionTypes: get hace T covariante, set contravariante
interface CheckedSignal<T> {
  get: () => T;
  set: (value: T) => void;
  subscribe: (listener: (value: T) => void) => () => void;
}
type _2 = Expect<Equal<Variance<CheckedSignal<Guitar>, CheckedSignal<Instrument>>, 'invariant'>>;

// O mantén los métodos, y di lo que significan
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
// @ts-expect-error: un CheckedSignal<Guitar> no es un CheckedSignal<Instrument>, que podría recibir un piano
const instruments: CheckedSignal<Instrument> = guitar;
console.log(guitar.get().name, typeof instruments);
```

```text
tuned to BEADF#B
baritone object
```

Con métodos, `set` no cuenta como contravariante, así que `get` y `subscribe` hacen covariante toda la señal, y un `Signal<Guitar>` podría guardarse en una variable `Signal<Instrument>` y recibir un piano. Las propiedades de tipo función hacen que se aplique `strictFunctionTypes`, y la señal pasa a ser invariante; `in out T` obtiene el mismo resultado conservando la sintaxis de método. La implementación usa la versión con propiedades, y la línea `@ts-expect-error` es la prueba de que el alias inseguro se rechaza.

</details>

2. Escribe `defineStatusColors(colors)`, una función que hace lo que hace `as const satisfies Record<GovernanceHealthStatus, HexColor>`: colores literales en el resultado, y un error de compilación para un estado que falta o un color que no es hexadecimal.

<details>
<summary>Solución</summary>

[`solutions/l02_ex2_define_colors.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l02_ex2_define_colors.ts):

```ts
// solutions/l02_ex2_define_colors.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
type HexColor = `#${string}`;

// Un parámetro de tipo const conserva los literales, y la restricción comprueba la completitud y el formato de cada color
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
  // @ts-expect-error: falta contradictory
  defineStatusColors({ error: '#FF4444', warning: '#FFB300', healthy: '#33CC66', unknown: '#888888' });
  // @ts-expect-error: magenta no es un color hexadecimal
  defineStatusColors({ error: '#FF4444', warning: '#FFB300', healthy: '#33CC66', unknown: '#888888', contradictory: 'magenta' });
}
console.log(colors.healthy, typeof mistakes);
```

```text
#33CC66 function
```

El modificador `const` conserva los literales, y la restricción hace el papel de `satisfies`. La forma de función era la manera habitual de conseguirlo antes de la 4.9, y sigue siendo útil cuando la comprobación necesita un genérico, por ejemplo una tabla cuyos valores deben ser claves de otro argumento.

</details>

3. Un formulario produce `{ displayName: string | undefined; avatarUrl: string | null | undefined }`, donde `undefined` significa que el campo se dejó vacío. Escribe `withoutUndefined(value)`, cuyo resultado puede expandirse sobre un `ViewerInfo` con `exactOptionalPropertyTypes`.

<details>
<summary>Solución</summary>

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

// Las propiedades que pueden contener undefined pasan a ser opcionales y pierden undefined; null se conserva, ya que es un valor
type WithoutUndefined<T> = { [K in keyof T]: Exclude<T[K], undefined> };

function withoutUndefined<T extends object>(value: T): Partial<WithoutUndefined<T>> {
  // Una aserción: el filtro elimina exactamente las entradas cuyo valor es undefined
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as Partial<WithoutUndefined<T>>;
}

// Un parche construido a partir de un formulario, donde un campo dejado vacío es undefined
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

`WithoutUndefined` quita `undefined` del tipo de cada propiedad y `Partial` hace opcional cada propiedad, que es exactamente lo que hace el filtro en tiempo de ejecución: una propiedad o está ausente o contiene un valor. `null` se conserva, ya que es un valor que envía el servidor y que el tipo permite. La salida muestra `displayName` intacto, porque el campo vacío se eliminó en lugar de expandirse como `undefined`.

</details>

## Fuentes

- [TypeScript handbook — Type compatibility](https://www.typescriptlang.org/docs/handbook/type-compatibility.html), [Generics — variance annotations](https://www.typescriptlang.org/docs/handbook/2/generics.html#variance-annotations)
- Notas de versión: [2.4 — detección de tipos débiles](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-4.html#weak-type-detection), [4.7 — anotaciones de varianza](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters), [4.9 — `satisfies`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html#the-satisfies-operator), [5.0 — parámetros de tipo `const`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html#const-type-parameters), [5.4 — `NoInfer`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html#the-noinfer-utility-type)
- [Referencia de TSConfig — exactOptionalPropertyTypes](https://www.typescriptlang.org/tsconfig/#exactOptionalPropertyTypes)
- [DefinitelyTyped — `types/react/index.d.ts`](https://github.com/DefinitelyTyped/DefinitelyTyped/blob/a542a0b0a0332f463dd42042f5bfb6cf36a61747/types/react/index.d.ts#L2316)
- [Microsoft — Covarianza y contravarianza en genéricos](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance), [Error del compilador CS1961](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/generic-type-parameters-errors#type-parameter-variance); [The Java Tutorials — Wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html), [Type inference and target types](https://docs.oracle.com/javase/tutorial/java/generics/genTypeInference.html)
