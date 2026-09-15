---
title: 2. Variance et assignabilité
description: Comment tsc mesure la variance et où la mesure n'est pas sûre, les annotations in out, le method bivariance hack de @types/react, satisfies face aux annotations et aux assertions, les paramètres de type const, NoInfer et l'inférence à partir du type de retour, exactOptionalPropertyTypes, les types faibles et la comparabilité, en regard de la variance vérifiée de C# et des wildcards de Java.
sidebar:
  order: 2
---

Code : les fichiers [`examples/l02_*`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples) et [`errors/l02_assignability.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/errors/l02_assignability.ts), et les côtés C# et Java dans [`compare/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare) (`l02_variance.cs`, `L02TargetTyping.java`) et [`compare_fail/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare_fail) (`l02_variant_setter.cs`, `l02_return_inference.cs`, `L02Wildcard.java`).

La [leçon 4 du cours de base](../../typescript-for-csharp-java/04-generics/#variance) a montré les règles : les tableaux sont covariants et non vérifiés, les propriétés de type fonction sont vérifiées de façon contravariante sous `strictFunctionTypes`, les paramètres de méthode restent bivariants, et les annotations `in` et `out` sont facultatives. Cette leçon les mesure, trouve où elles laissent passer une mauvaise valeur, puis regarde l'autre moitié de « est-ce assignable » : comment `tsc` décide d'abord du type d'une valeur, et comment `satisfies`, `const` et `NoInfer` changent cette décision.

## Mesurer la variance

La variance s'observe sans lire le vérificateur : construis le même type générique pour un sous-type et un supertype, et teste l'assignabilité dans les deux sens.

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

// Variance mesurée, testée sur l'assignabilité dans les deux sens
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
// Un paramètre de méthode est bivariant, même sous strictFunctionTypes
type _4 = Expect<Equal<Variance<WithMethod<Guitar>, WithMethod<Instrument>>, 'bivariant'>>;
// Un paramètre d'un paramètre redevient covariant : deux positions contravariantes s'annulent
type _5 = Expect<Equal<Variance<Callback<Guitar>, Callback<Instrument>>, 'covariant'>>;
// Une propriété mutable est lue et écrite, et quand même mesurée covariante
type _6 = Expect<Equal<Variance<Slot<Guitar>, Slot<Instrument>>, 'covariant'>>;
type _7 = Expect<Equal<Variance<ReadonlySlot<Guitar>, ReadonlySlot<Instrument>>, 'covariant'>>;

// La propriété mutable covariante n'est pas sûre : un piano entre dans l'emplacement de la guitare par un alias
const guitar: Guitar = { name: 'guitar', strings: 6, tune: () => 'EADGBE' };
const guitarSlot: Slot<Guitar> = { value: guitar };
const instrumentSlot: Slot<Instrument> = guitarSlot;
instrumentSlot.value = { name: 'piano' };
attempt('guitarSlot.value.tune()', () => guitarSlot.value.tune());

// in out déclare l'invariance que la structure ne montre pas ; le même alias ne compile plus
interface SafeSlot<in out T> {
  value: T;
}
type _8 = Expect<Equal<Variance<SafeSlot<Guitar>, SafeSlot<Instrument>>, 'invariant'>>;
const safeGuitarSlot: SafeSlot<Guitar> = { value: guitar };
// @ts-expect-error: SafeSlot<Guitar> n'est pas un SafeSlot<Instrument>
const safeInstrumentSlot: SafeSlot<Instrument> = safeGuitarSlot;
show('safeGuitarSlot.value.tune()', safeGuitarSlot.value.tune());

// Le method bivariance hack de @types/react : un type fonction qui reste bivariant sous strictFunctionTypes
type EventHandler<E> = { bivarianceHack(event: E): void }['bivarianceHack'];
interface ClickEvent {
  x: number;
}
interface DoubleClickEvent extends ClickEvent {
  count: 2;
}
type _9 = Expect<Equal<Variance<EventHandler<DoubleClickEvent>, EventHandler<ClickEvent>>, 'bivariant'>>;
const onDoubleClick: EventHandler<DoubleClickEvent> = (event) => console.log(`double click ${event.count}`);
const onClick: EventHandler<ClickEvent> = onDoubleClick; // accepté : le hack laisse passer un gestionnaire plus étroit
attempt('onClick({ x: 3 })', () => onClick({ x: 3 }));
```

```text
guitarSlot.value.tune()            TypeError: guitarSlot.value.tune is not a function
safeGuitarSlot.value.tune()        'EADGBE'
double click undefined
onClick({ x: 3 })                  undefined
```

Les tests de types dressent un tableau de ce que mesure `tsc` 7.0.2, pour `Guitar extends Instrument` :

| Membre qui utilise `T` | Mesure | Sûr ? |
|---|---|---|
| `get: () => T` | covariant | oui |
| `set: (value: T) => void` | contravariant | oui |
| les deux | invariant | oui |
| `set(value: T): void`, une méthode | bivariant | non |
| `subscribe: (listener: (value: T) => void) => void` | covariant | oui |
| `value: T`, une propriété mutable | covariant | non |
| `readonly value: T` | covariant | oui |

Deux lignes ne sont pas sûres, et c'est voulu. Un paramètre de méthode est bivariant, comme l'a montré le cours de base. Et une propriété mutable est mesurée covariante, bien qu'on puisse l'écrire : `Slot<Guitar>` est accepté comme `Slot<Instrument>`, l'alias y écrit un piano, et `guitarSlot.value.tune()` lève une exception. Le [handbook sur la compatibilité des types](https://www.typescriptlang.org/docs/handbook/type-compatibility.html#a-note-on-soundness) le dit clairement : « le système de types de TypeScript autorise certaines opérations dont on ne peut pas savoir à la compilation qu'elles sont sûres », et les propriétés sont comparées selon leur type en lecture. C# refuse la déclaration équivalente, parce qu'un setter consomme `T` :

```text
> dotnet run l02_variant_setter.cs
compare_fail/l02_variant_setter.cs(7,5): error CS1961: Invalid variance: The type parameter 'T' must be invariantly valid on 'ISlot<T>.Value'. 'T' is covariant.

The build failed. Fix the build errors and run again.
```

En C#, `out T` n'est autorisé que sur une propriété sans setter, comme `IReadOnlySlot<out T>` dans le programme de comparaison, et une `List<Guitar>` se convertit en `IReadOnlyList<Instrument>` mais pas en `IList<Instrument>` :

```csharp
// compare/l02_variance.cs
// C# déclare la variance sur les interfaces, et la vérifie par rapport à chaque membre
List<Guitar> guitars = [new("guitar", 6)];
IReadOnlyList<Instrument> instruments = guitars; // IReadOnlyList<out T> : covariante, et en lecture seule
IReadOnlySlot<Instrument> slot = new Slot<Guitar>(guitars[0]);
Console.WriteLine($"{instruments[0].Name}, {slot.Value.Name}");

// L'inférence n'utilise que les arguments : un paramètre de type qui n'apparaît que dans le type de retour doit être écrit
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

**`in out T` rétablit l'invariance.** Une annotation ne peut pas changer la façon dont les types sont comparés structurellement, mais elle remplace la variance mesurée quand `tsc` compare deux instanciations du même type générique. `SafeSlot<in out T>` est invariant, et l'alias ne compile plus. Annote ainsi les conteneurs mutables quand le trou de typage compte. L'annotation n'est vérifiée par rapport à la structure que dans le sens qu'elle permet : `in T` sur un type qui lit `T` est refusé avec `TS2636`, tandis que `in out T`, qui ne permet rien, est accepté sur n'importe quel type.

**Deux positions contravariantes en font une covariante.** `subscribe` prend un écouteur, qui prend un `T` : un abonnement aux guitares peut servir d'abonnement aux instruments, parce que chaque écouteur écrit pour des instruments accepte des guitares. Le même raisonnement explique l'intersection qu'`infer` a produite dans la [leçon 1](../01-type-level-programming/#types-conditionnels) pour deux paramètres.

**Le bivariance hack.** [`@types/react`](https://github.com/DefinitelyTyped/DefinitelyTyped/blob/a542a0b0a0332f463dd42042f5bfb6cf36a61747/types/react/index.d.ts#L2316) déclare ses gestionnaires d'événements comme `{ bivarianceHack(event: E): void }["bivarianceHack"]` : le type d'une méthode, extrait par accès indexé, est un type fonction qui garde la bivariance de la méthode. `EventHandler<DoubleClickEvent>` est accepté là où un `EventHandler<ClickEvent>` est attendu, et le gestionnaire lit un `count` qui n'existe pas. Les types de React le font exprès, pour qu'un gestionnaire écrit pour un événement précis puisse être passé à une prop typée avec un événement plus général ; le prix est le `undefined` de la sortie.

### Où la mesure sert

`tsc` ne compare pas `Slot<Guitar>` et `Slot<Instrument>` membre par membre à chaque fois. Pour une interface, une classe ou un alias de type générique, [`getVariancesWorker`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/relater.go#L1341-L1400) mesure une seule fois la variance de chaque paramètre de type : il instancie le type avec deux types marqueurs, l'un sous-type de l'autre, et teste l'assignabilité dans les deux sens. Un troisième marqueur, sans rapport avec les deux autres, distingue un paramètre bivariant d'un paramètre inutilisé. Le résultat est mis en cache, et les comparaisons suivantes de deux instanciations ne comparent que leurs arguments de type. Quand la comparaison des marqueurs est passée par des constructions que la mesure ne sait pas représenter, comme un type conditionnel, le résultat est marqué [non mesurable ou non fiable](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/types.go#L300-L309), et le vérificateur se rabat sur une comparaison structurelle.

Une annotation évite la mesure : dans la même fonction, `out` donne covariant, `in` contravariant et `in out` invariant, sans rien instancier. C'est l'usage pour lequel les [annotations de variance de la 4.7](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters) ont été conçues : sur un très gros type, une annotation économise la mesure, et sur un type dont la mesure n'est pas fiable, elle donne la réponse voulue. Le handbook recommande de ne les écrire que lorsqu'elles correspondent à la structure, et surtout après profilage.

| | C# | Java | TypeScript |
|---|---|---|---|
| Où la variance est déclarée | interfaces et délégués, `in`/`out` | au point d'utilisation, `? extends`/`? super` | nulle part : mesurée ; `in`/`out` facultatifs |
| Une propriété modifiable | invariante, `out` refusé (`CS1961`) | — | covariante, non sûre ; `in out` pour corriger |
| Paramètres des types fonction | contravariants (délégués, `in T`) | — | contravariants pour les propriétés, bivariants pour les méthodes |
| Vérifiée | entièrement | entièrement, avec la conversion par capture | partiellement |

Java place la variance sur la variable, pas sur le type. Une `List<? extends Object>` peut être lue, et on ne peut rien y ajouter, ce qui est la forme au point d'utilisation de `out T` :

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

## satisfies, annotations et assertions

Quatre façons de dire « cet objet est un `Record<GovernanceHealthStatus, HexColor>` » donnent quatre types différents :

```ts
// examples/l02_satisfies.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
type HexColor = `#${string}`;

// 1. Une annotation : l'objet est vérifié, et son type devient l'annotation, donc les couleurs littérales sont perdues
const annotated: Record<GovernanceHealthStatus, HexColor> = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
};
type _1 = Expect<Equal<(typeof annotated)['error'], HexColor>>;

// 2. satisfies : la même vérification, et le type reste celui inféré à partir de l'objet. Les littéraux sont gardés ici
// parce que le type contextuel, un template literal type, contient des types littéraux ; face à string, ils s'élargissent
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

// 3. as const satisfies : des valeurs littérales quel que soit le type contextuel, des propriétés readonly, et la vérification
const colors = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
} as const satisfies Record<GovernanceHealthStatus, HexColor>;
type _3 = Expect<Equal<(typeof colors)['error'], '#FF4444'>>;
type _3b = Expect<Equal<typeof colors, { readonly error: '#FF4444'; readonly warning: '#FFB300'; readonly healthy: '#33CC66'; readonly unknown: '#888888'; readonly contradictory: '#FF44FF' }>>;

// 4. as : une assertion, qui vérifie seulement qu'un type est comparable à l'autre ; un statut manquant passe
const partial = { error: '#FF4444', healthy: '#33CC66' };
const asserted = partial as Record<GovernanceHealthStatus, HexColor>;
show('asserted.warning', asserted.warning);

// satisfies fournit le type contextuel : le paramètre de chaque fonction est typé sans annotation
interface Formatters {
  [status: string]: (score: number) => string;
}
const formatters = {
  healthy: (score) => `healthy (${score.toFixed(2)})`,
  warning: (score) => `watch (${Math.round(score * 100)}%)`,
} satisfies Formatters;
show('formatters.healthy(0.93)', formatters.healthy(0.93));
// Le type inféré garde exactement les deux clés : formatters.error serait une erreur de compilation, pas undefined à l'exécution
type _4 = Expect<Equal<keyof typeof formatters, 'healthy' | 'warning'>>;

// VoxtralTTS.ts de GA vérifie de la même façon le corps d'une requête, avant que JSON.stringify n'efface tout
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

1. **Une annotation** vérifie l'objet et remplace son type par l'annotation. `annotated.error` est un `HexColor` : le fait qu'il vaille `'#FF4444'` a disparu.
2. **[`satisfies`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html#the-satisfies-operator)** (4.9) vérifie l'objet par rapport au type, et garde le type inféré à partir de l'objet. Que les littéraux survivent dépend du type contextuel : face à `` `#${string}` ``, un *template literal type*, le vérificateur garde `'#FF4444'` ; face à `string`, il élargit à `string`, comme le montre `widened`. Je m'attendais à ce que le littéral soit élargi dans les deux cas, et le test de types `_2` m'a corrigé.
3. **`as const satisfies`** garde les littéraux quel que soit le type contextuel, rend chaque propriété `readonly`, et vérifie quand même qu'aucun statut ne manque et que chaque valeur est une couleur hexadécimale.
4. **Une assertion**, `as`, ne vérifie presque rien : un type doit être comparable à l'autre. `partial`, avec deux statuts, est comparable au record, puisque le record est assignable à `{ error: string; healthy: string }`, et `asserted.warning` vaut `undefined` à l'exécution. Avec un littéral objet écrit directement après `as`, `tsc` 7.0.2 signale bien les propriétés manquantes (`TS2352`), parce que les types du littéral sont alors les littéraux eux-mêmes, auxquels le record n'est pas assignable.

`satisfies` fournit aussi un type contextuel, ce qui explique que les fonctions de `formatters` n'aient besoin d'aucune annotation de paramètre, et il garde les clés inférées : `formatters.error` est une erreur de compilation, là où une annotation avec une signature d'index l'aurait typé comme une fonction et aurait renvoyé `undefined`.

GA utilise `satisfies` une fois dans sa bibliothèque de composants, dans [`VoxtralTTS.ts`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/VoxtralTTS.ts#L248-L252), sur le corps d'une requête juste avant `JSON.stringify`, qui efface tous les types. C'est le bon endroit : l'objet garde son type inféré, et un `voice_id` mal orthographié serait détecté. Le reste de la bibliothèque utilise des annotations, comme `HEALTH_STATUS_COLORS: Record<GovernanceHealthStatus, string>` dans [`types.ts`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/types.ts#L203-L209), ce qui suffit là où seule la vérification compte.

## Contrôler l'inférence

```ts
// examples/l02_inference.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// Sans const, un argument tableau est inféré comme string[] : les notes sont oubliées
function tuning<T extends readonly string[]>(notes: T): T {
  return notes;
}
const plain = tuning(['D', 'A', 'D', 'G', 'A', 'D']);
type _1 = Expect<Equal<typeof plain, string[]>>;

// Un paramètre de type const (5.0) infère comme si l'appelant avait écrit as const
function constTuning<const T extends readonly string[]>(notes: T): T {
  return notes;
}
const dadgad = constTuning(['D', 'A', 'D', 'G', 'A', 'D']);
type _2 = Expect<Equal<typeof dadgad, readonly ['D', 'A', 'D', 'G', 'A', 'D']>>;
// Avec une contrainte mutable, le tuple est inféré mutable (depuis la 5.3 ; de la 5.0 à la 5.2, on retombait sur string[])
function constMutable<const T extends string[]>(notes: T): T {
  return notes;
}
const fallback = constMutable(['D', 'A', 'D']);
type _3 = Expect<Equal<typeof fallback, ['D', 'A', 'D']>>;

// Chaque argument est un site d'inférence : ici initial ajoute sa valeur à l'union inférée à partir de states
function machine<S extends string>(states: readonly S[], initial: S) {
  return { states, current: initial };
}
const loose = machine(['idle', 'listening', 'processing'], 'understood');
type _4 = Expect<Equal<typeof loose.current, 'idle' | 'listening' | 'processing' | 'understood'>>;

// NoInfer (5.4) retire un argument de l'inférence : S vient de states seul, et initial est vérifié par rapport à lui
function strictMachine<S extends string>(states: readonly S[], initial: NoInfer<S>) {
  return { states, current: initial };
}
const strict = strictMachine(['idle', 'listening', 'processing', 'understood'], 'idle');
type _5 = Expect<Equal<typeof strict.current, 'idle' | 'listening' | 'processing' | 'understood'>>;
// @ts-expect-error: 'speaking' ne fait pas partie des états
strictMachine(['idle', 'listening'], 'speaking');

// Inférence à partir du type de retour : le type déclaré de la variable se propage dans l'appel
function emptyList<T>(): T[] {
  return [];
}
const chords: string[] = emptyList(); // T est string, inféré à partir du contexte, comme le fait Java et pas C#
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

**Les paramètres de type `const`.** Sans eux, un littéral tableau passé à une fonction générique est inféré comme `string[]`. Un [paramètre de type `const`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html#const-type-parameters) (5.0) infère comme si l'appelant avait écrit `as const`, et `dadgad` garde ses six notes sous forme de tuple en lecture seule. Les notes de version de la 5.0 préviennent qu'une contrainte mutable, `T extends string[]`, fait retomber l'inférence sur `string[]`. C'était vrai jusqu'à la 5.2 : j'ai exécuté le même fichier avec `tsc` 5.0.4, 5.2.2 et 5.3.3, et depuis la 5.3 le résultat est le tuple mutable `['D', 'A', 'D']`, que donne aussi `tsc` 7.0.2.

**Chaque argument est un site d'inférence.** `machine(states, initial)` infère `S` à partir des deux paramètres. Le `'understood'` passé comme `initial` n'est pas une erreur pour `tsc` : il devient un membre de plus de `S`, et la machine à états a maintenant un état qui n'est pas dans sa liste. [`NoInfer<T>`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html#the-noinfer-utility-type) (5.4) retire une position de l'inférence : `S` vient de `states` seul, et `initial` est vérifié par rapport à lui, donc `'speaking'` est refusé.

**L'inférence à partir du type de retour.** `const chords: string[] = emptyList()` infère `T` comme `string` à partir du type déclaré de la variable. Java fait de même avec son [typage par la cible](https://docs.oracle.com/javase/tutorial/java/generics/genTypeInference.html#target_types), et C# non : un paramètre de type qui n'apparaît que dans le type de retour doit être écrit.

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

L'avertissement `CS8321` qui suit l'erreur est un effet de bord : une fois que l'appel échoue, le compilateur considère la fonction locale comme inutilisée.

## Optionnel, undefined et null

```ts
// examples/l02_optional.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// Le ViewerInfo de GA, tiré de DataLoader.ts : le record C# du serveur a string? DisplayName = null et string? AvatarUrl = null
interface ViewerInfo {
  connectionId: string;
  color: string;
  displayName?: string;
  avatarUrl?: string | null;
}

// Avec exactOptionalPropertyTypes, ? signifie que la propriété peut être absente, pas qu'elle peut contenir undefined
const absent: ViewerInfo = { connectionId: 'a1', color: '#58a6ff' };
const withNull: ViewerInfo = { connectionId: 'b2', color: '#3fb950', avatarUrl: null };
show("'displayName' in absent", 'displayName' in absent);
show('Object.keys(withNull)', Object.keys(withNull));

// Lire une propriété optionnelle donne quand même undefined quand elle est absente
type _1 = Expect<Equal<ViewerInfo['displayName'], string | undefined>>;
// Partial<T> garde la règle : un patch peut omettre une propriété, et ne peut pas la mettre à undefined
function applyPatch(viewer: ViewerInfo, patch: Partial<ViewerInfo>): ViewerInfo {
  return { ...viewer, ...patch };
}
show('applyPatch(absent, …)', applyPatch(absent, { displayName: 'Ada' }));

// Pourquoi la règle compte : un spread copie une propriété propre qui contient undefined, et efface la valeur
const viewer: ViewerInfo = { connectionId: 'c3', color: '#d2a8ff', displayName: 'Hari' };
const sloppyPatch = { displayName: undefined };
show('{ ...viewer, ...sloppyPatch }', { ...viewer, ...sloppyPatch });

// Un type faible n'a que des propriétés optionnelles : tsc exige qu'un argument partage au moins l'une d'elles
interface TuningOptions {
  capo?: number;
  dropD?: boolean;
}
function tune(options: TuningOptions): string {
  return `capo ${options.capo ?? 0}, drop D ${options.dropD ?? false}`;
}
const fromSettings = { capo: 2, theme: 'dark' };
show('tune(fromSettings)', tune(fromSettings)); // partage capo : accepté, et theme est ignoré

// null et undefined sont des valeurs différentes, et JSON n'en a qu'une
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

Le `tsconfig.json` du cours active [`exactOptionalPropertyTypes`](https://www.typescriptlang.org/tsconfig/#exactOptionalPropertyTypes), qui ne fait pas partie de `strict`. Avec cette option, `displayName?: string` signifie que la propriété peut être absente, pas qu'elle peut contenir `undefined`. La distinction existe à l'exécution : `'displayName' in absent` vaut `false`, alors qu'un objet avec `displayName: undefined` possède la propriété. Elle compte pour les spreads, comme le montre la quatrième ligne de la sortie : un patch dont la propriété contient `undefined` efface la valeur sur laquelle il est étalé. `JSON.stringify` supprime complètement la propriété, et garde un `null`.

Le [`ViewerInfo`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L218-L225) de GA déclare `displayName?: string` et `avatarUrl?: string | null`. Le record du serveur, dans [`GovernanceHub.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Apps/ga-server/GaApi/Hubs/GovernanceHub.cs#L12-L18), est `string? DisplayName = null, string? AvatarUrl = null`, et la leçon 4 montre que SignalR envoie les deux sous forme de `null`. Le type de `displayName` est faux, et le code fonctionne quand même, parce que [`ForceRadiant.tsx`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L4363-L4382) le lit avec `?.` et `??`, qui traitent `null` comme `undefined`. Une vérification écrite `viewer.displayName !== undefined`, comme le suggère le type, laisserait passer `null`.

L'extrait ci-dessous rassemble les règles d'assignabilité de cette section et des précédentes. Il s'exécute deux fois : une fois avec les options du cours, et une fois avec `--exactOptionalPropertyTypes false`.

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

- **`TS2375`** : avec `exactOptionalPropertyTypes`, `undefined` n'est pas une valeur d'une propriété optionnelle, dans un objet comme dans un `Partial`. La seconde exécution accepte les deux lignes.
- **`TS2559`** : un **type faible**, dont toutes les propriétés sont optionnelles, doit partager au moins une propriété avec la valeur qu'on lui assigne. `{ theme, fontSize }` n'a rien en commun avec `TuningOptions`, et il est refusé, bien qu'il soit structurellement assignable ; `fromSettings`, dans l'exemple, partage `capo`, et il est accepté. La règle date de [TypeScript 2.4](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-4.html#weak-type-detection).
- **`TS2352`** : une assertion entre des types qui ne sont pas comparables. Passer par `unknown` la fait taire, c'est pourquoi `as unknown as` est le motif à rechercher dans une base de code : la bibliothèque de composants de GA en compte 34.
- **`TS2322`** sur `SafeSlot` : l'annotation `in out` de la première section, et le message montre la vérification dans l'autre sens, de `{ name: string }` vers `Guitar`.

## À retenir

- `tsc` mesure la variance à partir de la structure ; les propriétés mutables sont mesurées covariantes et les paramètres de méthode bivariants, deux cas non sûrs. `in out T` rend un type invariant.
- Deux positions contravariantes s'annulent ; le bivariance hack de `@types/react` garde exprès un type fonction bivariant.
- Une annotation remplace le type inféré, `satisfies` le vérifie et le garde, `as const satisfies` garde en plus les littéraux, et `as` ne vérifie que la comparabilité.
- Les paramètres de type `const` infèrent des tuples littéraux ; `NoInfer` retire un argument de l'inférence ; un type de retour attendu guide aussi l'inférence, comme en Java et contrairement à C#.
- `exactOptionalPropertyTypes` distingue une propriété absente d'une propriété qui contient `undefined`, et `null` est un troisième cas, que JSON conserve.

## Exercices

1. Une petite bibliothèque de signaux déclare `interface Signal<T> { get(): T; set(value: T): void; subscribe(listener: (value: T) => void): () => void }`. Prédis la variance que mesure `tsc`, vérifie-la avec un test de types, et écris deux versions invariantes.

<details>
<summary>Solution</summary>

[`solutions/l02_ex1_signal.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l02_ex1_signal.ts) :

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

// Le signal tel qu'il a été écrit : set est une méthode, donc son paramètre est bivariant, et T est mesuré covariant
interface Signal<T> {
  get(): T;
  set(value: T): void;
  subscribe(listener: (value: T) => void): () => void;
}
type _1 = Expect<Equal<Variance<Signal<Guitar>, Signal<Instrument>>, 'covariant'>>;

// Les propriétés de type fonction sont vérifiées sous strictFunctionTypes : get rend T covariant, set contravariant
interface CheckedSignal<T> {
  get: () => T;
  set: (value: T) => void;
  subscribe: (listener: (value: T) => void) => () => void;
}
type _2 = Expect<Equal<Variance<CheckedSignal<Guitar>, CheckedSignal<Instrument>>, 'invariant'>>;

// Ou garde les méthodes, et dis ce qu'elles signifient
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
// @ts-expect-error: un CheckedSignal<Guitar> n'est pas un CheckedSignal<Instrument>, qui pourrait recevoir un piano
const instruments: CheckedSignal<Instrument> = guitar;
console.log(guitar.get().name, typeof instruments);
```

```text
tuned to BEADF#B
baritone object
```

Avec des méthodes, `set` ne compte pas comme contravariant, donc `get` et `subscribe` rendent tout le signal covariant, et un `Signal<Guitar>` pourrait être rangé dans une variable `Signal<Instrument>` et recevoir un piano. Des propriétés de type fonction font s'appliquer `strictFunctionTypes`, et le signal devient invariant ; `in out T` obtient le même résultat en gardant la syntaxe des méthodes. L'implémentation utilise la version à propriétés, et la ligne `@ts-expect-error` est le test qui vérifie que l'alias dangereux est refusé.

</details>

2. Écris `defineStatusColors(colors)`, une fonction qui fait ce que fait `as const satisfies Record<GovernanceHealthStatus, HexColor>` : des couleurs littérales dans le résultat, une erreur de compilation pour un statut manquant ou une couleur qui n'est pas hexadécimale.

<details>
<summary>Solution</summary>

[`solutions/l02_ex2_define_colors.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l02_ex2_define_colors.ts) :

```ts
// solutions/l02_ex2_define_colors.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
type HexColor = `#${string}`;

// Un paramètre de type const garde les littéraux, et la contrainte vérifie la complétude et le format de chaque couleur
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
  // @ts-expect-error: contradictory manque
  defineStatusColors({ error: '#FF4444', warning: '#FFB300', healthy: '#33CC66', unknown: '#888888' });
  // @ts-expect-error: magenta n'est pas une couleur hexadécimale
  defineStatusColors({ error: '#FF4444', warning: '#FFB300', healthy: '#33CC66', unknown: '#888888', contradictory: 'magenta' });
}
console.log(colors.healthy, typeof mistakes);
```

```text
#33CC66 function
```

Le modificateur `const` garde les littéraux, et la contrainte joue le rôle de `satisfies`. La forme fonction était la façon habituelle d'obtenir ce résultat avant la 4.9, et elle reste utile quand la vérification a besoin d'un générique, par exemple une table dont les valeurs doivent être des clés d'un autre argument.

</details>

3. Un formulaire produit `{ displayName: string | undefined; avatarUrl: string | null | undefined }`, où `undefined` signifie que le champ a été laissé vide. Écris `withoutUndefined(value)`, dont le résultat peut être étalé sur un `ViewerInfo` sous `exactOptionalPropertyTypes`.

<details>
<summary>Solution</summary>

[`solutions/l02_ex3_without_undefined.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l02_ex3_without_undefined.ts) :

```ts
// solutions/l02_ex3_without_undefined.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

interface ViewerInfo {
  connectionId: string;
  color: string;
  displayName?: string;
  avatarUrl?: string | null;
}

// Les propriétés qui peuvent contenir undefined deviennent optionnelles et perdent undefined ; null est gardé, puisque c'est une valeur
type WithoutUndefined<T> = { [K in keyof T]: Exclude<T[K], undefined> };

function withoutUndefined<T extends object>(value: T): Partial<WithoutUndefined<T>> {
  // Une assertion : le filtre retire exactement les entrées dont la valeur est undefined
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as Partial<WithoutUndefined<T>>;
}

// Un patch construit à partir d'un formulaire, où un champ laissé vide vaut undefined
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

`WithoutUndefined` retire `undefined` du type de chaque propriété et `Partial` rend chaque propriété optionnelle, ce qui est exactement ce que fait le filtre à l'exécution : une propriété est soit absente, soit porteuse d'une valeur. `null` est gardé, puisque c'est une valeur que le serveur envoie et que le type autorise. La sortie montre `displayName` intact, parce que le champ vide a été retiré au lieu d'être étalé sous forme de `undefined`.

</details>

## Sources

- [Handbook TypeScript — Compatibilité des types](https://www.typescriptlang.org/docs/handbook/type-compatibility.html), [Génériques — annotations de variance](https://www.typescriptlang.org/docs/handbook/2/generics.html#variance-annotations)
- Notes de version : [2.4 — détection des types faibles](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-4.html#weak-type-detection), [4.7 — annotations de variance](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters), [4.9 — `satisfies`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html#the-satisfies-operator), [5.0 — paramètres de type `const`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html#const-type-parameters), [5.4 — `NoInfer`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html#the-noinfer-utility-type)
- [Référence TSConfig — exactOptionalPropertyTypes](https://www.typescriptlang.org/tsconfig/#exactOptionalPropertyTypes)
- [DefinitelyTyped — `types/react/index.d.ts`](https://github.com/DefinitelyTyped/DefinitelyTyped/blob/a542a0b0a0332f463dd42042f5bfb6cf36a61747/types/react/index.d.ts#L2316)
- [Microsoft — Covariance et contravariance dans les génériques](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance), [Erreur du compilateur CS1961](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/generic-type-parameters-errors#type-parameter-variance) ; [The Java Tutorials — Wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html), [Inférence de type et types cibles](https://docs.oracle.com/javase/tutorial/java/generics/genTypeInference.html)
