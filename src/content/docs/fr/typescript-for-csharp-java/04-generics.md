---
title: 4. Génériques
description: Paramètres de type, inférence et contraintes, génériques effacés à l'exécution face aux génériques réifiés de C# et à l'effacement de Java, la variance avec la bivariance des méthodes, strictFunctionTypes et les annotations in/out, puis keyof, l'accès indexé et un premier type mappé.
sidebar:
  order: 4
---

Code : les fichiers [`examples/l04_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/examples) et [`errors/l04_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors), et les côtés C# et Java dans [`compare/`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare) (`l04_generics.cs`, `l04_variance.cs`, `L04Erasure.java`, `L04Variance.java`) et [`compare_fail/`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail) (`l04_invariant_list.cs`, `l04_variance_annotation.cs`, `L04NewT.java`, `L04Wildcards.java`).

La syntaxe des génériques est celle que tu connais, `function first<T>(items: T[]): T`, et leur but aussi. Les différences se trouvent à trois endroits, que cette leçon aborde dans l'ordre : ce qui existe à l'exécution, comment `tsc` décide qu'un type générique est assignable à un autre, et les valeurs que peut prendre un paramètre de type, puisqu'en TypeScript ce peuvent être les noms des propriétés d'un autre type.

## Paramètres de type, inférence et contraintes

```ts
// examples/l04_generics.ts
import { show } from './show.ts';

// Un paramètre de type, inféré à partir de l'argument
function first<T>(items: readonly T[]): T | undefined {
  return items[0];
}
const note = first(['E', 'A', 'D']); // T est string
const fret = first([0, 2, 2]); // T est number
show('note, fret', [note, fret]);
show('first<string>([])', first<string>([])); // un argument de type explicite

// Une contrainte : T doit avoir une longueur, et garde son propre type
function longest<T extends { length: number }>(a: T, b: T): T {
  return b.length > a.length ? b : a;
}
show("longest('capo', 'strings')", longest('capo', 'strings'));
show('longest([1, 2], [1, 2, 3])', longest([1, 2], [1, 2, 3]));

// keyof et l'accès indexé : la clé est vérifiée, et le résultat a le type de cette propriété
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

// Un type générique, avec une valeur par défaut
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

- `tsc` infère `T` à partir des arguments, comme C# et Java infèrent les arguments de type d'une méthode, et un `first<string>([])` explicite sert quand rien ne peut être inféré.
- Une **contrainte**, `T extends { length: number }`, s'écrit avec `extends`, comme les bornes de Java, et peut être n'importe quel type, y compris une forme : les chaînes et les tableaux ont tous deux une `length`, et `longest` renvoie le type qu'on lui a donné, `string` ou `number[]`, et non `{ length: number }`. En C#, la même fonction demande une interface que les deux types implémentent ([contraintes sur les paramètres de type](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters)).
- **`keyof T`** est l'union des noms de propriétés de `T`, et **`T[K]`** le type de la propriété `K`. `get(standard, 'notes')` renvoie un `string[]` et `get(standard, 'capo')` un `number`, avec la même fonction : le type de retour dépend de la valeur d'un argument, ce que les génériques de C# et de Java ne peuvent pas exprimer.
- Un paramètre de type peut avoir une valeur par défaut, `Cursor = number`, comme un paramètre optionnel de C#, mais pour les types.

Les contraintes sont vérifiées à l'appel :

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

Le deuxième message montre comment fonctionne l'inférence : `tsc` a pris `T` dans le premier argument, le type littéral `"capo"`, puis a jugé le second argument par rapport à lui, au lieu de chercher un type qui convienne aux deux. Le troisième transforme une faute de frappe en erreur de compilation, ce qu'une clé `string` ne ferait pas. Sans `tsc`, `longest(10, 20)` renvoie `10`, parce que `(20).length` vaut `undefined` et que `undefined > undefined` vaut `false`, et `get` lit une propriété qui n'existe pas.

## Pas de T à l'exécution

Les génériques de C# sont **réifiés** : le runtime crée un `List<int>` distinct d'un `List<string>`, et `typeof(T)`, `new T()` et `is T` fonctionnent. Les génériques de Java sont **effacés** jusqu'à leur borne, et `javac` insère des casts là où une valeur sort. TypeScript va un pas plus loin : le type entier est retiré, et il ne reste rien vers quoi caster.

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

Le programme C# crée un `Tuner` avec `new T()`, affiche `Int32` pour `typeof(T)`, et distingue les deux types de liste. En Java, `ArrayList<Integer>` et `ArrayList<String>` sont la même classe, et la chaîne `"twelve"` reste dans une `List<Integer>` jusqu'à ce que le cast inséré par `javac` à `counts.get(0)` échoue. En TypeScript, le même code ne compile pas, et ne s'exécuterait pas s'il compilait :

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

Java refuse aussi `new T()`, et n'autorise `instanceof T` que là où le cast peut être vérifié. Ce qui les remplace, dans les deux langages, c'est de passer une valeur qui existe à l'exécution :

```ts
// examples/l04_erasure.ts
import { attempt, show } from './show.ts';

// T n'apparaît que dans le type de retour : l'appelant le choisit, et rien ne le vérifie
function parse<T>(json: string): T {
  return JSON.parse(json);
}
const count = parse<number>('"twelve"');
show('typeof count', typeof count);
attempt('count.toFixed(1)', () => count.toFixed(1));

// Il n'y a pas de T à l'exécution : passe à la fonction ce dont elle a besoin sous forme de valeur, ici un constructeur
class Tuner {
  reference = 440;
}
function create<T>(ctor: new () => T): T {
  return new ctor();
}
show('create(Tuner)', create(Tuner));

// Ou une garde de type, qui porte la vérification jusqu'à l'exécution
function parseArray<T>(json: string, isItem: (value: unknown) => value is T): T[] {
  const value: unknown = JSON.parse(json);
  if (!Array.isArray(value) || !value.every(isItem)) throw new TypeError(`not the expected array: ${json}`);
  return value;
}
const isNumber = (value: unknown): value is number => typeof value === 'number';
show("parseArray('[0, 2, 2]', isNumber)", parseArray('[0, 2, 2]', isNumber));
attempt("parseArray('[0, \"2\"]', isNumber)", () => parseArray('[0, "2"]', isNumber));

// musicService.ts de GA, lignes 17-23 : une garde générique vérifie la forme, jamais le T
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

- **`parse<T>`** est la signature la plus dangereuse de TypeScript : `T` n'apparaît que dans le type de retour, donc l'appelant le choisit et rien ne peut le vérifier. `parse<number>('"twelve"')` renvoie une chaîne typée `number`. Cela compile sans `as` parce que `JSON.parse` renvoie `any`, et c'est tout de même une assertion, cachée dans un générique.
- **`create(ctor: new () => T)`** prend le constructeur, une valeur, là où C# utiliserait `where T : new()` ; `T` est inféré à partir de lui.
- **`parseArray(json, isItem)`** prend une garde de type pour les éléments. La vérification s'exécute, et un `"2"` parmi les nombres est rejeté à la frontière : c'est le pattern de la [leçon 3](../03-unions-and-narrowing/#prédicats-de-type-et-fonctions-dassertion) rendu générique.

### Dans GuitarAlchemist/ga : une garde générique qui ne vérifie pas son T

La dernière partie de l'exemple vient de [`Apps/ga-client/src/services/musicService.ts`, lignes 17-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/musicService.ts#L17-L49), par où passe chaque appel à l'API de théorie musicale :

```ts
const isApiResponse = <T>(value: unknown): value is ApiResponse<T> => {
  if (!value || typeof value !== 'object') {
    return false;
  }

  return 'success' in value && 'data' in value;
};

const parseJson = async <T>(response: Response): Promise<T> => {
  // […] une erreur pour un statut autre que 2xx
  const json = await response.json();
  if (isApiResponse<T>(json)) {
    // […] une erreur quand success vaut false ou que data est null
    return json.data;
  }

  return json as T;
};
```

`isApiResponse<T>` promet un `ApiResponse<T>` et vérifie deux noms de propriétés : `T` est le choix de l'appelant, comme dans `parse<T>`. Quand la vérification échoue, `json as T` renvoie le corps quand même, quel qu'il soit. `fetchKeyNotes` renvoie alors une `Promise<KeyNotes>` qui contient ce que le serveur a envoyé, et un changement dans la forme de l'API apparaît sous la forme d'une `TypeError` dans un composant, comme celle que l'exemple a affichée pour `json.data.map`, loin de cette fonction. C'est un pattern courant, et raisonnable quand le serveur et son client sont construits ensemble ; le deuxième exercice écrit la version qui vérifie. Dans le même dépôt, [`CourseViewer.tsx`, ligne 152](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/CourseViewer.tsx#L152-L159) contient `function loadQueue<T>(key: string): T[]`, qui renvoie `JSON.parse(raw)` depuis `localStorage` sans même un `as`, puisque le `any` de la [leçon 2](../02-structural-typing/#any-unknown-et-never) se convertit en `T[]` en silence.

## Variance

La variance répond à une question : si une `Guitar` est un `Instrument`, une liste de guitares est-elle une liste d'instruments ? Une fonction qui prend des guitares, une fonction qui prend des instruments ?

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

// Les tableaux sont covariants : un Guitar[] est accepté comme Instrument[], et l'alias peut ajouter un piano
const guitars: Guitar[] = [guitar];
const instruments: Instrument[] = guitars;
instruments.push(piano);
show('guitars.length', guitars.length);
attempt('guitars[1].tune()', () => guitars[1].tune());

// Une propriété de type fonction est vérifiée de façon contravariante (strictFunctionTypes) ; une méthode ne l'est pas
interface WithProperty {
  play: (instrument: Instrument) => string;
}
interface WithMethod {
  play(instrument: Instrument): string;
}
const tuneGuitar = (g: Guitar) => g.tune();
const withMethod: WithMethod = { play: tuneGuitar }; // accepté : les paramètres de méthode sont bivariants
attempt('withMethod.play(piano)', () => withMethod.play(piano));
const withProperty: WithProperty = { play: (i: Instrument) => i.name }; // une fonction d'Instrument convient
show('withProperty.play(piano)', withProperty.play(piano));

// Annotations de variance : out pour un type qui ne fait que produire T, in pour un type qui ne fait que le consommer
interface Source<out T> {
  next(): T;
}
interface Sink<in T> {
  accept(value: T): void;
}
const guitarSource: Source<Guitar> = { next: () => guitar };
const instrumentSource: Source<Instrument> = guitarSource; // out : Source<Guitar> est une Source<Instrument>
const names: string[] = [];
const instrumentSink: Sink<Instrument> = { accept: (i) => names.push(i.name) };
const guitarSink: Sink<Guitar> = instrumentSink; // in : Sink<Instrument> est un Sink<Guitar>
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

**Les tableaux sont covariants, et non vérifiés.** `tsc` accepte un `Guitar[]` comme `Instrument[]`, comme C# et Java acceptent les tableaux, et l'alias pousse un piano parmi les guitares. C# et Java vérifient chaque écriture dans un tableau à l'exécution ; JavaScript n'a pas de type d'élément à vérifier, donc le piano entre, et l'erreur vient plus tard, du code qui a fait confiance à `guitars[1]` :

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

Les classes génériques de C# comme `List<T>` sont invariantes, et celles de Java aussi, là où TypeScript comparerait `List<Guitar>` et `List<Instrument>` membre par membre :

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

**Paramètres de fonction : les propriétés sont vérifiées, les méthodes non.** Une fonction qui a besoin d'une `Guitar` ne peut pas remplacer sans risque une fonction qui accepte n'importe quel `Instrument` : les paramètres doivent être contravariants. Avec [`strictFunctionTypes`](https://www.typescriptlang.org/tsconfig/#strictFunctionTypes), qui fait partie de `strict`, `tsc` le vérifie pour les propriétés dont le type est une fonction, `play: (instrument: Instrument) => string`. Il ne le fait pas pour les méthodes, `play(instrument: Instrument): string`, dont les paramètres restent **bivariants** : `withMethod` accepte `tuneGuitar`, et l'appeler avec un piano lève une exception. Cette exclusion est délibérée : selon les [notes de version de TypeScript 2.6](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-6.html), les méthodes sont exclues « pour que les classes et interfaces génériques (comme `Array<T>`) continuent à se comporter de façon essentiellement covariante », ce que `push(item: T)` empêcherait sinon. Écris les types de callback comme des propriétés quand tu veux qu'ils soient vérifiés.

**Annotations de variance.** C# déclare la variance sur les interfaces et les délégués, `IEnumerable<out T>`, `Action<in T>`, et la vérifie ([covariance et contravariance](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)). Java la déclare là où un type est utilisé, `List<? extends Object>` ([wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html)). TypeScript la calcule à partir de la structure, et accepte depuis la [4.7](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters) des annotations `out` et `in` facultatives, comme en C# :

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

// in promet que T est seulement consommé, et next le renvoie
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

La première erreur est `strictFunctionTypes` sur une propriété. Les deux suivantes sont les annotations à l'œuvre : une source d'instruments n'est pas une source de guitares, et un récepteur de guitares ne peut pas accepter n'importe quel instrument. La dernière attrape une annotation qui contredit la structure : `in T` sur une interface qui renvoie `T`. La même erreur en C# :

```text
> dotnet run l04_variance_annotation.cs
compare_fail/l04_variance_annotation.cs(6,17): error CS1961: Invalid variance: The type parameter 'T' must be contravariantly valid on 'IMislabeled<T>.Accept(T)'. 'T' is covariant.

The build failed. Fix the build errors and run again.
```

La vérification de C# est complète, celle de TypeScript ne l'est pas. L'erreur inverse, `interface Mislabeled<out T> { accept(value: T): void }`, compile avec `tsc` 7.0.2 sans message, parce qu'`accept` est une méthode et que son paramètre est bivariant, donc `T` à cette position est compatible avec les deux annotations. Le [handbook](https://www.typescriptlang.org/docs/handbook/2/generics.html#variance-annotations) est franc à leur sujet : les annotations ne changent pas la façon dont les types sont comparés structurellement, ne devraient être écrites que lorsqu'elles correspondent à la structure, et servent surtout pendant le débogage d'un type ou, après profilage, à accélérer la vérification de types extraordinairement complexes.

L'exécution de cet extrait avec `node` montre la suppression des types (*type stripping*) à l'œuvre. `declare const instrumentSource` n'existe que pour `tsc` et a été retiré, donc la ligne 24 lève une `ReferenceError`, et la ligne que Node.js affiche contient des espaces là où se trouvait l'annotation de type : les types sont remplacés par des blancs pour que les numéros de ligne et de colonne restent ceux de la source ([leçon 1](../01-compiler-and-tooling/)).

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
| Types génériques à l'exécution | réifiés : `typeof(T)`, `new T()`, `is T` | effacés jusqu'à la borne, casts insérés par `javac` | entièrement effacés |
| Contraintes | `where T : IComparable<T>, new()` | `<T extends Comparable<T>>` | `<T extends Shape>`, n'importe quel type, formes comprises |
| Tableaux | covariants, écritures vérifiées (`ArrayTypeMismatchException`) | covariants, écritures vérifiées (`ArrayStoreException`) | covariants, non vérifiés |
| Classes génériques | invariantes, variance sur les interfaces et les délégués | invariantes, variance au point d'utilisation avec `?` | structurelle : calculée à partir des membres |
| Paramètres de fonction | contravariants | — | contravariants pour les propriétés de type fonction, bivariants pour les méthodes |
| Annotations | `out T`, `in T`, entièrement vérifiées | `? extends T`, `? super T` | `out T`, `in T`, facultatives, partiellement vérifiées |

## keyof, accès indexé et types mappés

Les types TypeScript peuvent être calculés à partir d'autres types. [`keyof`](https://www.typescriptlang.org/docs/handbook/2/keyof-types.html) et l'[accès indexé](https://www.typescriptlang.org/docs/handbook/2/indexed-access-types.html) sont apparus dans `get<T, K extends keyof T>` ; un [**type mappé**](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html) parcourt les clés d'un type et construit une propriété pour chacune, `{ [K in keyof T]: … }`.

La [leçon 4 du cours JavaScript](../../javascript-for-csharp-java/04-objects-prototypes-classes/#dans-guitaralchemistga--fusionner-les-préférences-sauvegardées) a examiné les options de scène de GA, fusionnées à partir de valeurs par défaut, d'une URL et de `localStorage` avec `Object.assign`, ce qui laissait passer les clés inconnues et les mauvais types. La version typée demande un validateur par option, et un type mappé dérive le type de cette table de `SceneOptions` :

```ts
// examples/l04_mapped.ts
import { show } from './show.ts';

interface SceneOptions {
  stars: boolean;
  tower: boolean;
  skyboxMode: 'milky-way' | 'nebula';
}

// keyof liste les noms de propriétés sous forme d'union ; T[K] est le type d'une propriété
type OptionName = keyof SceneOptions; // 'stars' | 'tower' | 'skyboxMode'
type Skybox = SceneOptions['skyboxMode']; // 'milky-way' | 'nebula'
const name: OptionName = 'skyboxMode';
const skybox: Skybox = 'nebula';
show('name, skybox', [name, skybox]);

// Un type mappé construit une propriété pour chaque clé d'un autre type
type Validators<T> = {
  [K in keyof T]: (value: unknown) => value is T[K];
};

const isBoolean = (value: unknown): value is boolean => typeof value === 'boolean';
const sceneValidators: Validators<SceneOptions> = {
  stars: isBoolean,
  tower: isBoolean,
  skyboxMode: (value): value is Skybox => value === 'milky-way' || value === 'nebula',
};

// Une seule fusion générique pour tous les types d'options : clés connues seulement, valeurs valides seulement, et l'URL en dernier
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

// Les types mappés de la bibliothèque : Partial, Readonly, Pick et Record
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

- `Validators<SceneOptions>` est `{ stars: (value: unknown) => value is boolean; tower: …; skyboxMode: (value: unknown) => value is 'milky-way' | 'nebula' }`, écrit une seule fois pour tous les types d'options.
- `merge` est générique sur `T`, et `validators[key](value)` restreint `value` à `T[keyof T]`, donc `result[key] = value` compile. Le `"stars": "yes"` échoue à son validateur, le `bloom` inconnu n'est jamais lu, et la clé `__proto__` du JSON, que `JSON.parse` crée comme une propriété ordinaire, n'est pas non plus dans les validateurs : `isAdmin` n'atteint pas le résultat.
- Deux assertions restent, et chacune dit pourquoi. `Object.keys` renvoie `string[]`, et non `(keyof T)[]`, parce que le typage structurel permet à un objet d'avoir plus de clés que son type n'en liste ; ici, l'objet est la table des validateurs, dont les clés sont exactement celles de `T`. Et on sait seulement que `saved` est un `object`, qui n'a pas de signature d'index, donc il est lu comme un `Record<PropertyKey, unknown>`, dont les valeurs restent `unknown`.
- `Partial`, `Readonly`, `Pick` et `Record` sont des types mappés de la bibliothèque standard ([types utilitaires](https://www.typescriptlang.org/docs/handbook/utility-types.html)) ; `lib.es5.d.ts` définit `Partial<T>` comme `{ [P in keyof T]?: T[P] }`. La dernière ligne de la sortie montre que `Readonly` et `Pick` sont des vues, comme dans la [leçon 2](../02-structural-typing/#readonly) : `toggles` est typé avec deux propriétés et en contient trois.

Le type suit les options. Ajoutes-en une, et la table des validateurs est incomplète jusqu'à ce que quelqu'un écrive sa vérification :

```ts
// errors/l04_mapped.ts
// Une nouvelle option : l'objet des validateurs ne correspond plus, donc tsc le signale
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

C# atteindrait la même garantie avec un générateur de source ou la réflexion, et Java avec un processeur d'annotations. En TypeScript, la relation entre les deux types est un type, et `tsc` la vérifie à chaque build.

## À retenir

- `tsc` infère les arguments de type à partir de l'appel, et signale un argument en conflit par rapport à ce qu'il a inféré en premier ; les contraintes utilisent `extends` et peuvent être des formes.
- `keyof T` et `T[K]` permettent à un type de retour de dépendre d'une clé passée comme valeur.
- Les types sont entièrement effacés : pas de `new T()`, pas d'`instanceof T`, pas de `typeof(T)`. Passe un constructeur ou une garde de type à la place.
- Un `T` qui n'apparaît que dans le type de retour, `parse<T>(json): T`, est une assertion non vérifiée ; une garde générique qui ne vérifie pas `T` aussi.
- Les tableaux sont covariants et non vérifiés. Les propriétés de type fonction sont vérifiées de façon contravariante sous `strictFunctionTypes` ; les paramètres de méthode restent bivariants.
- Les annotations `in` et `out` sont facultatives, et `tsc` ne détecte pas toutes les annotations fausses.
- Un type mappé, `{ [K in keyof T]: … }`, dérive un type d'un autre, et garde les deux alignés quand le premier change.

## Exercices

1. Écris `groupBy(items, keyOf)`, qui regroupe les éléments d'un tableau selon la clé que renvoie `keyOf`, avec un type de retour dans lequel regrouper des accords par leur qualité donne les propriétés `major`, `minor` et `diminished`, chacune éventuellement absente.

<details>
<summary>Solution</summary>

[`solutions/l04_ex1_group_by.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l04_ex1_group_by.ts) :

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
const byQuality = groupBy(chords, (chord) => chord.quality); // K est 'major' | 'minor' | 'diminished'
console.log(byQuality.minor?.map((chord) => chord.name));
console.log(Object.keys(groupBy(chords, (chord) => chord.name.length)));
```

```text
[ 'Dm', 'Em' ]
[ '1', '2', '4' ]
```

`K extends PropertyKey`, c'est-à-dire `string | number | symbol`, permet d'inférer `K` comme l'union littérale des qualités, et `Partial` dit qu'une qualité peut n'avoir aucun accord, d'où `byQuality.minor?.map`. Le second appel regroupe par un `number`, et affiche les clés sous forme de chaînes : les clés des objets JavaScript sont des chaînes, et `Record<number, …>` décrit comment elles s'écrivent, pas ce que renvoie `Object.keys`. Une [`Map<K, T[]>`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map) garde les nombres ; `Object.groupBy`, en ES2024, renvoie le même `Partial<Record<K, T[]>>` que cette solution.

</details>

2. Écris `isApiResponseOf(value, isData)`, une version de l'`isApiResponse` de GA dont le `T` est vérifié, et utilise-la pour une réponse dont le `data` doit être un tableau de chaînes.

<details>
<summary>Solution</summary>

[`solutions/l04_ex2_api_response.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l04_ex2_api_response.ts) :

```ts
// solutions/l04_ex2_api_response.ts
interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: string;
}
type Guard<T> = (value: unknown) => value is T;

// La garde de T est un paramètre : la vérification de data s'exécute, au lieu d'être promise
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

La garde de `data` est un paramètre, donc `T` est inféré à partir d'elle, et l'appelant ne peut pas choisir un `T` sans fournir la vérification. Dans `parseJson`, le repli `json as T` devrait devenir une erreur levée : une réponse qui n'est pas un `ApiResponse` des données attendues est une erreur de l'API, et le dire là où elle se produit évite de la chercher dans un composant.

</details>

3. Écris `pick(value, keys)`, qui renvoie un objet avec seulement les propriétés listées, typé avec `Pick`, pour qu'une clé qui n'existe pas et une propriété qui n'a pas été choisie soient toutes deux des erreurs de compilation.

<details>
<summary>Solution</summary>

[`solutions/l04_ex3_pick.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l04_ex3_pick.ts) :

```ts
// solutions/l04_ex3_pick.ts
function pick<T extends object, K extends keyof T>(value: T, keys: readonly K[]): Pick<T, K> {
  const result = {} as Pick<T, K>; // une assertion : la boucle ci-dessous remplit chaque clé de K
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

// Jamais appelée : chaque ligne montre une erreur que tsc rejette
function mistakes() {
  // @ts-expect-error: 'weather' n'est pas une clé de SceneOptions
  pick(options, ['weather']);
  // @ts-expect-error: skyboxMode n'a pas été choisi
  return toggles.skyboxMode;
}
console.log(typeof mistakes);
```

```text
{ stars: true, tower: false } [ 'stars', 'tower' ]
function
```

`{}` n'est pas un `Pick<T, K>` tant que la boucle ne s'est pas exécutée, et `tsc` ne peut pas suivre une boucle qui remplit chaque clé d'une union, donc la fonction commence par une assertion et un commentaire qui dit ce qui la rend vraie. C'est la forme habituelle d'un utilitaire générique : une petite signature vérifiée à l'extérieur, et une seule assertion justifiée à l'intérieur.

</details>

## Sources

- [Handbook TypeScript — Génériques](https://www.typescriptlang.org/docs/handbook/2/generics.html), [Opérateur de type keyof](https://www.typescriptlang.org/docs/handbook/2/keyof-types.html), [Types à accès indexé](https://www.typescriptlang.org/docs/handbook/2/indexed-access-types.html), [Types mappés](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html), [Types utilitaires](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [Référence TSConfig — strictFunctionTypes](https://www.typescriptlang.org/tsconfig/#strictFunctionTypes) ; notes de version [2.6 — types de fonction stricts](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-6.html), [4.7 — annotations de variance](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#optional-variance-annotations-for-type-parameters)
- [Microsoft — Génériques](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/generics), [Contraintes sur les paramètres de type](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters), [Covariance et contravariance dans les génériques](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)
- [The Java Tutorials — Effacement de type](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html), [Wildcards](https://docs.oracle.com/javase/tutorial/java/generics/wildcards.html), [Restrictions sur les génériques](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html)
