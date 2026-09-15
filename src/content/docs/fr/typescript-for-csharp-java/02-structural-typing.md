---
title: 2. Typage structurel
description: Annotations et inférence, typage structurel face au typage nominal, interface et type, vérification des propriétés en trop, readonly, tuples, any, unknown et never, et strictNullChecks — chacun comparé à C# et Java, avec les vrais diagnostics de tsc.
sidebar:
  order: 2
---

Code : les fichiers [`examples/l02_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/examples) et [`errors/l02_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors), et les côtés C# et Java dans [`compare/l02_nullable.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/l02_nullable.cs), [`compare/L02Nullable.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/L02Nullable.java), [`compare_fail/l02_nominal.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail/l02_nominal.cs) et [`compare_fail/L02Nominal.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail/L02Nominal.java).

Les exemples affichent leurs résultats avec les fonctions utilitaires `show` et `attempt` de la [leçon 2 de JavaScript](../../javascript-for-csharp-java/02-values-and-types/), désormais typées. `err` dans un `catch` a le type `unknown`, parce que JavaScript peut lever n'importe quelle valeur, et la fonction vérifie que c'est une `Error` avant de lire son `message` :

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
    // err est unknown : on peut lever n'importe quoi, pas seulement une Error (la leçon 3 le restreint)
    console.log(`${label.padEnd(34)} ${err instanceof Error ? `${err.name}: ${err.message}` : String(err)}`);
  }
}
```

## Annotations et inférence

Une annotation, c'est un deux-points et un type après un nom : `let count: number`. La plupart du temps, tu n'en écris pas, parce que `tsc` infère le type à partir de la valeur, comme le fait `var` en C# et en Java. Le moyen le plus rapide de voir ce que `tsc` a inféré, hors d'un éditeur, est de lui demander un fichier de déclaration : `tsc --declaration` écrit le type de tout ce qu'un module exporte.

```ts
// examples/l02_inference.ts
// tsc --declaration écrit les types qu'il a inférés dans l02_inference.d.ts (voir check.sh)
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
// out/dts/examples/l02_inference.d.ts, écrit par tsc --declaration --emitDeclarationOnly
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

Une partie correspond à ce que C# inférerait, une autre non :

- `count` est un `number`, mais `tuning` a le type `"EADGBE"` : un **type littéral**, dont la seule valeur est cette chaîne. Un `const` ne peut pas changer, donc `tsc` garde le type le plus étroit. Un `let` reçoit le type plus large `number` ou `string`, puisqu'il peut être réassigné.
- Les propriétés de `capo` sont élargies en `number` et `string`, parce que les propriétés d'un objet peuvent être réassignées même quand la variable est `const`. `Object.freeze` et `as const` gardent les types littéraux, et ajoutent `readonly`.
- `mixed` est un tableau de `string | number | null` : une **union** des types des éléments, là où C# refuse `new[] { 1, "two", null }` faute de meilleur type commun (*à vérifier*). Les unions sont le sujet de la [leçon 3](../03-unions-and-narrowing/).
- `fretOf` a un type de retour inféré, `number | undefined`, puisqu'une branche renvoie `undefined`.
- `parsed` est `any`, parce que `JSON.parse` est déclaré comme renvoyant `any`. La section sur `any`, plus bas, explique pourquoi c'est important.

Le style habituel consiste à annoter ce dont dépend le reste du code, les paramètres et les types de retour des fonctions exportées, et à laisser `tsc` inférer les variables locales. Les paramètres doivent être annotés de toute façon : `tsc` n'infère pas le type d'un paramètre à partir des appels.

| | C# | Java | TypeScript |
|---|---|---|---|
| Nombres | `int`, `long`, `double`, `decimal`… | `int`, `long`, `double`… | `number`, `bigint` |
| Texte | `string`, `char` | `String`, `char` | `string`, pas de type caractère |
| Valeur absente | `null` | `null` | `null` et `undefined`, deux types |
| N'importe quelle valeur, vérifiée avant usage | `object` | `Object` | `unknown` |
| N'importe quelle valeur, sans vérification | `dynamic` | — | `any` |
| Aucune valeur | `void` pour un type de retour | `void` | `void` pour un type de retour, `never` pour une valeur qui ne peut pas exister |
| Une valeur précise | — | — | un type littéral : `'EADGBE'`, `2`, `true` |

## Typage structurel

Les types de C# et de Java sont **nominaux** : une classe est compatible avec une interface parce qu'elle le déclare, `class Vector : IPoint`. Les types de TypeScript sont **structurels** : une valeur est compatible avec un type quand elle a les bonnes propriétés avec les bons types, quoi que dise sa déclaration ([compatibilité des types](https://www.typescriptlang.org/docs/handbook/type-compatibility.html)).

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

// Une classe qui ne mentionne jamais Point, et dont les instances sont pourtant des Points : seule la forme compte
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

// interface et type décrivent la même forme : les deux noms sont interchangeables
type PointAlias = { x: number; y: number };
const alias: PointAlias = { x: 6, y: 8 };
const point: Point = alias;
show('length(point)', length(point));

// Deux classes de même forme sont le même type, quoi que disent leurs noms
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

// Un type marqué : un nombre que seule une fonction peut produire
type Kelvin = number & { readonly brand: 'Kelvin' };
function kelvin(value: number): Kelvin {
  if (value < 0) throw new RangeError('below absolute zero');
  return value as Kelvin; // le seul endroit où la marque est affirmée
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

`Vector` ne mentionne jamais `Point`, et ses instances sont acceptées là où un `Point` est attendu, avec la propriété `z` en plus. C'est ce qui permet à TypeScript de coller à JavaScript, où la plupart des objets sont des littéraux sans classe. Le prix à payer est la seconde moitié de l'exemple : `Celsius` et `Fahrenheit` ont la même forme, donc ils sont le même type pour `tsc`, et une température de 150 °F est déclarée bouillante. `instanceof` les distingue toujours à l'exécution, parce que la chaîne de prototypes est réelle, mais les types, eux, ne les distinguent pas. Le même code en C# et en Java :

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

Quand un type a besoin d'un nom, deux techniques lui en donnent un. Un **type marqué** (*branded type*) est l'intersection d'un type primitif et d'une propriété qu'aucune valeur ordinaire ne possède, `number & { readonly brand: 'Kelvin' }`, de sorte que seule une fonction qui affirme la marque en produit un ; à l'exécution, `room` est un simple nombre. Et un **champ privé** `#value` rend une classe nominale, parce qu'aucune autre classe ne peut avoir ce champ :

```ts
// errors/l02_nominal.ts
// Un champ #private rend une classe nominale : aucune autre classe, si semblable soit-elle, n'a ce champ
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

Le mot-clé `private` propre à TypeScript a le même effet sur la compatibilité, vérifié par `tsc` seulement ; `#value` est aussi imposé par le moteur ([leçon 4 de JavaScript](../../javascript-for-csharp-java/04-objects-prototypes-classes/#classes)).

### interface ou type

`interface Point { x: number; y: number }` et `type Point = { x: number; y: number }` décrivent la même forme, et l'exemple assigne l'un à l'autre sans broncher. Les différences sont ailleurs ([types de tous les jours](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#differences-between-type-aliases-and-interfaces)) :

| | `interface` | `type` |
|---|---|---|
| Formes d'objets | oui | oui |
| Unions, tuples, primitifs, types mappés | non | oui : `type Fret = number \| 'open'` |
| Extension | `interface Guitar extends Instrument` | une intersection : `type Guitar = Instrument & { strings: number }` |
| Deux déclarations du même nom | fusionnées en une seule interface | une erreur |

La fusion de déclarations est ce qui permet aux bibliothèques d'ajouter une propriété à un type global, et c'est rarement ce que veut une application. Une règle raisonnable, et celle que suit ce cours : `interface` pour les formes d'objets, `type` pour tout le reste.

## Vérification des propriétés en trop

Le typage structurel accepte les propriétés en trop, à une exception près :

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

// Un littéral objet écrit là où un SceneOptions est attendu : une propriété inconnue est une erreur
console.log(describe({ stars: false, towr: true }));

// Le même objet d'abord placé dans une variable : pas de vérification des propriétés en trop, et la faute de frappe est ignorée en silence
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

Un littéral objet écrit directement là où un type est attendu est « frais », et `tsc` y cherche les propriétés que le type n'a pas, puisque rien d'autre ne pourra jamais les lire. Le même objet stocké d'abord dans une variable n'est plus frais : il pourrait servir ailleurs, là où `towr` a un sens, donc `tsc` l'accepte, et la faute de frappe se perd sans message. Avec des propriétés toutes optionnelles, comme dans un objet d'options, c'est le cas où une faute de frappe coûte le plus cher. Passe les options sous forme de littéraux, ou annote la variable, `const fromUrl: SceneOptions = { … }`, ce qui rend le littéral à nouveau frais.

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

`readonly` sur une propriété, et `readonly string[]` pour un tableau, retirent les écritures du type, comme le fait `IReadOnlyList<T>` en C# : un `readonly string[]` n'a pas de `push`. Et comme avec `IReadOnlyList<T>`, c'est une vue, pas un objet immuable :

```ts
// examples/l02_readonly.ts
import { attempt, show } from './show.ts';

interface Tuning {
  readonly name: string;
  readonly notes: readonly string[];
}

// readonly n'est vérifié que par tsc : rien n'est gelé à l'exécution
const standard: Tuning = { name: 'standard', notes: ['E', 'A', 'D', 'G', 'B', 'E'] };

// Un type readonly est assignable à un type mutable qui a les mêmes propriétés : l'alias peut écrire
const writable: { name: string } = standard;
writable.name = 'drop D';
show('standard.name', standard.name);

// Object.freeze donne les deux : un Readonly<T> pour tsc, et un objet gelé pour le moteur
const frozen = Object.freeze({ name: 'open G', notes: ['D', 'G', 'D', 'G', 'B', 'D'] });
attempt("frozen.name = 'x', after a cast", () => {
  (frozen as { name: string }).name = 'x';
});
frozen.notes.push('shallow'); // freeze est superficiel, et Readonly<T> aussi
show('frozen.notes.length', frozen.notes.length);

// as const : les types littéraux les plus étroits, et readonly à tous les niveaux
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

- Rien n'est gelé à l'exécution : `readonly` disparaît avec les autres types, et l'exécution par `node` ci-dessus a tout modifié.
- Un type readonly est assignable au même type sans `readonly`, donc un alias peut écrire ce que l'original ne pouvait pas. `tsc` accepte `const writable: { name: string } = standard`, et `standard.name` change.
- `Object.freeze` donne les deux moitiés : son type de retour est `Readonly<…>`, et le moteur refuse l'écriture, ici faite à travers une assertion de type qui fait taire `tsc`. Les deux sont superficiels, comme en JavaScript.
- `as const` rend un littéral readonly à tous les niveaux, avec des types littéraux. `(typeof modes)[number]` transforme les éléments du tableau en type union, `'ionian' | 'dorian' | 'phrygian'`, le remplaçant d'un `enum` qu'utilisait le deuxième exercice de la [leçon 1](../01-compiler-and-tooling/).

## Tuples et index

```ts
// examples/l02_tuples.ts
import { show } from './show.ts';

// Un tuple : une longueur fixe, et un type pour chaque position
type Interval = [name: string, semitones: number];
const fifth: Interval = ['perfect fifth', 7];
const [name, semitones] = fifth;
show('name, semitones', [name, semitones]);

// Un tableau : une longueur quelconque, un seul type d'élément, et un index auquel tsc fait confiance
const strings: string[] = ['E', 'A', 'D', 'G', 'B', 'E'];
const seventh: string = strings[6]; // pas d'erreur sans noUncheckedIndexedAccess
show('seventh', seventh);
show('typeof seventh', typeof seventh);

const counts = new Map<string, number>([['E', 2]]);
const count = counts.get('A'); // Map.get l'admet : number | undefined
show('count ?? 0', count ?? 0);

// Les tuples sont des tableaux à l'exécution : rien n'empêche un push
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

Un type tuple fixe la longueur et le type de chaque position, et ses étiquettes, `name` et `semitones`, servent de documentation. À l'exécution, c'est un tableau, et `push` fonctionne : le type ne protège que les positions qu'il déclare.

`strings[6]` est typé `string`, et contient `undefined`. Par défaut, `tsc` fait confiance à un index dans un tableau ou un dictionnaire, là où C# lèverait `IndexOutOfRangeException` pour un tableau et `KeyNotFoundException` pour un dictionnaire, et Java `ArrayIndexOutOfBoundsException`. `Map.get` est déclaré honnêtement, `number | undefined`, mais un index de tableau ou une clé de `Record` ne l'est pas. L'option [`noUncheckedIndexedAccess`](https://www.typescriptlang.org/tsconfig/#noUncheckedIndexedAccess) ajoute `undefined` à chaque accès par index. Elle ne fait pas partie de `strict`, et `tsc --init` l'active :

```ts
// errors/l02_index.ts
// options de tsc : --noUncheckedIndexedAccess
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

Sans l'option, `tsc` n'affiche rien et le programme échoue à la première ligne qui utilise l'élément manquant. Avec elle, chaque index demande une vérification, ce qui est bruyant dans les boucles sur des index connus, et juste pour les recherches par clé.

## any, unknown et never

```ts
// examples/l02_any_unknown.ts
import { attempt, show } from './show.ts';

const saved = '{"stars": "yes", "tower": true}';

// JSON.parse renvoie any : tout usage compile, et any se propage à tout ce qu'il touche
const options = JSON.parse(saved);
const stars: boolean = options.stars; // pas d'erreur : any est assignable à tout
show('stars', stars);
show('typeof stars', typeof stars);
attempt('options.weather.level', () => options.weather.level);

// unknown accepte lui aussi n'importe quelle valeur, mais on ne peut rien en faire avant une vérification
const checked: unknown = JSON.parse(saved);
if (typeof checked === 'object' && checked !== null && 'stars' in checked) {
  show("typeof checked.stars", typeof checked.stars);
}

// never : une fonction qui ne revient pas, et une valeur qui ne peut pas exister
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

**`any`** désactive le vérificateur pour une valeur. `options` est `any` parce que `JSON.parse` renvoie `any`, donc `options.stars` est `any` aussi, et `any` est assignable à tous les types : `stars` est déclaré `boolean` et contient la chaîne `'yes'`, et `options.weather.level` compile et lève une exception. `any` se comporte comme le [`dynamic`](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interop/using-type-dynamic) de C#, à une différence près : C# lie une opération `dynamic` au moment où elle s'exécute et lève `RuntimeBinderException` pour un membre qui n'existe pas, là où JavaScript lit `undefined` et continue. Il se propage en silence, depuis les fonctions qui le renvoient, `JSON.parse`, `response.json()` et les parties non typées des bibliothèques, à tout ce qu'il touche.

**`unknown`** accepte lui aussi toutes les valeurs, et ne permet rien tant qu'une vérification ne l'a pas *restreint*, comme `object` en C# :

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

Dans l'exemple, `typeof checked === 'object'`, `!== null` et `'stars' in checked` restreignent `checked` étape par étape, jusqu'à ce que `checked.stars` compile. La [leçon 3](../03-unions-and-narrowing/) porte sur ces vérifications. Écris `const value: unknown = JSON.parse(text)` : l'annotation transforme le `any` en `unknown` sur-le-champ, et `tsc` demande ensuite une vérification avant chaque usage.

**`never`** est le type qui n'a aucune valeur. Une fonction qui lève toujours une exception renvoie `never`, comme une méthode C# marquée [`[DoesNotReturn]`](https://learn.microsoft.com/dotnet/api/system.diagnostics.codeanalysis.doesnotreturnattribute), et un `never` est assignable à tous les types, c'est pourquoi `fail(…)` trouve sa place dans la branche `boolean` de `starsOf`. La leçon 3 utilise `never` pour vérifier qu'un `switch` traite tous les cas.

## null et undefined

Avec `strictNullChecks`, qui fait partie de `strict`, `null` et `undefined` sont des types séparés, et `string` ne les inclut pas. Une valeur qui peut être absente le dit, `string | undefined`, ou `name?: string` pour un paramètre ou une propriété optionnels :

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

La correction passe par le *narrowing* de la leçon 3, ou par les opérateurs que la [leçon 2 de JavaScript](../../javascript-for-csharp-java/02-values-and-types/#undefined-et-null) a présentés :

```ts
// examples/l02_null.ts
import { attempt, show } from './show.ts';

function initial(name?: string): string {
  return name === undefined ? '?' : name.charAt(0); // restreint : name est une string dans la seconde branche
}
show('initial()', initial());
show("initial('Ada')", initial('Ada'));

const tunings = new Map([['standard', 'EADGBE']]);
show("tunings.get('drop D')?.length", tunings.get('drop D')?.length);
show("tunings.get('drop D') ?? 'DADGBE'", tunings.get('drop D') ?? 'DADGBE');

// L'assertion non nulle ! fait taire tsc, et ne vérifie rien
attempt("tunings.get('drop D')!.length", () => tunings.get('drop D')!.length);
```

```text
initial()                          '?'
initial('Ada')                     'A'
tunings.get('drop D')?.length      undefined
tunings.get('drop D') ?? 'DADGBE'  'DADGBE'
tunings.get('drop D')!.length      TypeError: Cannot read properties of undefined (reading 'length')
```

Les [types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references) de C# reposent sur la même idée, avec le même opérateur `!`, mais ils produisent des avertissements :

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

| | C# avec `<Nullable>enable</Nullable>` | Java | TypeScript avec `strictNullChecks` |
|---|---|---|---|
| Un type qui peut être absent | `string?` | rien dans le type ; des annotations comme le `@Nullable` de [JSpecify](https://jspecify.dev/) | `string \| undefined`, `string \| null`, `name?: string` |
| L'utiliser sans vérification | avertissement CS8602, le programme se compile | rien, jusqu'à `NullPointerException` | erreur TS18048, et le programme s'exécute quand même |
| « Fais-moi confiance » | `name!` | — | `name!` |
| À l'exécution | `NullReferenceException` | `NullPointerException` | `TypeError: Cannot read properties of undefined` |

En C# comme en TypeScript, `!` ne fait que faire taire le compilateur : `tunings.get('drop D')!.length` compile et lève une exception. Utilise-le là où tu sais quelque chose que le vérificateur ne peut pas savoir, et préfère une vérification qui dit ce qui doit se passer si tu te trompes.

## La famille strict

`strict` active huit options, listées dans le code source du compilateur comme les [options `strictFlag`](https://github.com/microsoft/TypeScript/blob/v6.0.3/src/compiler/commandLineParser.ts) :

| Option | Ce qu'elle vérifie | Leçon |
|---|---|---|
| `strictNullChecks` | `null` et `undefined` sont des types séparés | celle-ci |
| `noImplicitAny` | un paramètre ou une variable dont le type ne peut pas être inféré doit être annoté | celle-ci |
| `useUnknownInCatchVariables` | la variable d'un `catch` est `unknown`, pas `any` | la fonction `attempt` plus haut |
| `strictFunctionTypes` | les types de fonctions sont vérifiés de façon contravariante dans leurs paramètres | [4](../04-generics/) |
| `strictBindCallApply` | `bind`, `call` et `apply` vérifient leurs arguments | — |
| `strictPropertyInitialization` | un champ de classe doit être initialisé, dans sa déclaration ou dans le constructeur | — |
| `strictBuiltinIteratorReturn` | la valeur `return` des itérateurs intégrés est `undefined`, pas `any` | — |
| `noImplicitThis` | `this` doit avoir un type connu dans une fonction | — |

Un projet peut fixer `"strict": true` et désactiver ensuite l'une d'elles, et c'est là qu'il faut regarder en premier dans un `tsconfig.json` existant.

## Dans GuitarAlchemist/ga : noImplicitAny désactivé

[`ga-react-components/tsconfig.app.json`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/tsconfig.app.json#L17-L20) fixe `"noImplicitAny": false` trois lignes au-dessus de `"strict": true`. Le fichier est lu comme un tout, donc l'option spécifique l'emporte sur la famille, et chaque paramètre dont le type ne peut pas être inféré devient `any` en silence. Celui de [`ga-client`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/tsconfig.app.json#L17-L18) n'a pas cette ligne.

J'ai lancé `tsc -p tsconfig.app.json --noImplicitAny true` sur la bibliothèque de composants, avec TypeScript 5.9.3 et les dépendances résolues à partir de son `package.json` : cela ajoute 4 erreurs à celles de la leçon 1, deux `TS7006`, `Parameter 'child' implicitly has an 'any' type` et la même pour `obj`, dans [`BSPDoomExplorer.tsx`, lignes 4363 et 4367](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L4363-L4367), et deux `TS7053` pour l'indexation d'un `Record<HexavalentTruth, string>` par une simple `string` dans [`IxqlFormPanel.tsx`, lignes 83 et 112](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/IxqlFormPanel.tsx#L83). Réactiver l'option coûte quatre annotations ; le `any` que le projet ne voit pas vient d'ailleurs, de 42 appels à `JSON.parse` et de 18 `as any` dans ses sources, que la leçon 3 examine.

## À retenir

- `tsc` infère les types locaux, y compris des types littéraux pour les constantes ; annote les paramètres et les signatures exportées. `tsc --declaration` montre ce qu'il a inféré.
- La compatibilité est structurelle : même forme, même type, quels que soient les noms. Les marques et les champs `#private` donnent un nom à un type quand il en a besoin.
- Un littéral objet écrit là où un type est attendu est vérifié pour les propriétés en trop ; le même objet passé par une variable ne l'est pas.
- `readonly` est une vue à la compilation : un alias sans `readonly` peut toujours écrire, et rien n'est gelé.
- Les index de tableaux et de `Record` sont crus sur parole, sauf si `noUncheckedIndexedAccess` est activé.
- `any` désactive la vérification et se propage ; `unknown` exige une vérification ; `never` n'a aucune valeur. `JSON.parse` renvoie `any` : stocke son résultat dans un `unknown`.
- `strictNullChecks` fait de l'absence une partie du type, comme les types référence nullables de C#, mais sous forme d'erreurs ; `!` fait taire les deux compilateurs et ne vérifie rien.

## Exercices

1. Écris des types marqués `Celsius` et `Fahrenheit`, une fonction `toFahrenheit(t: Celsius): Fahrenheit`, et `boils(t: Celsius)`, et montre trois erreurs que `tsc` rejette désormais, dans un fichier que `tsc` accepte.

<details>
<summary>Solution</summary>

[`solutions/l02_ex1_units.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l02_ex1_units.ts) :

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

// Jamais appelée : chaque ligne montre une erreur que tsc rejette désormais
function mistakes() {
  // @ts-expect-error: un Fahrenheit n'est pas un Celsius
  boils(oven);
  // @ts-expect-error: un simple nombre n'est pas non plus un Celsius
  boils(212);
  // @ts-expect-error: le résultat d'une opération arithmétique redevient un simple nombre
  const warmer: Celsius = water + 1;
  return warmer;
}
console.log(typeof mistakes);
```

```text
212 true
function
```

Un commentaire `// @ts-expect-error` indique à `tsc` que la ligne suivante doit être une erreur : le fichier compile, et si un changement ultérieur rendait l'une de ces lignes valide, `tsc` signalerait la directive comme inutilisée. C'est la façon TypeScript de tester que du code est *rejeté*, là où ce cours utilise des extraits d'erreur séparés. La troisième erreur montre la limite des marques : l'arithmétique sur un `Celsius` donne un simple `number`, donc chaque opération qui devrait garder l'unité passe par une fonction.

</details>

2. Écris `loadTunings(raw: string | null): Tuning[]` pour des accordages enregistrés en JSON, qui renvoie seulement les entrées ayant un `name` de type chaîne et un tableau de chaînes `notes`, et un tableau vide pour tout le reste, JSON invalide compris.

<details>
<summary>Solution</summary>

[`solutions/l02_ex2_load_tunings.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l02_ex2_load_tunings.ts) :

```ts
// solutions/l02_ex2_load_tunings.ts
interface Tuning {
  name: string;
  notes: string[];
}

// JSON.parse dans un unknown : tsc ne laisse rien passer tant que chaque propriété n'est pas vérifiée
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

Le résultat de `JSON.parse` va dans un `unknown`, et la fonction renvoie de nouveaux objets construits uniquement à partir de propriétés vérifiées, donc une propriété en trop dans les données enregistrées n'atteint pas le programme. Regarde pourtant `item.name` : il a compilé sans vérification `'name' in item`, parce que `Array.isArray` restreint un `unknown` en `any[]`, et chaque `item` redevient `any`. `any` revient par les déclarations de la bibliothèque standard ; ce sont les vérifications `typeof` qui rendent cette fonction correcte, pas `tsc`.

</details>

3. Pour chaque ligne numérotée de [`solutions/l02_ex3_predict.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l02_ex3_predict.ts), prédis si `tsc` l'accepte, puis retire les commentaires `@ts-expect-error` et lance `tsc` pour vérifier.

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
<summary>Solution</summary>

```ts
// solutions/l02_ex3_predict.ts
// Chaque ligne que tsc rejette porte @ts-expect-error : si l'une d'elles compilait, tsc signalerait une directive inutilisée
interface Point {
  x: number;
  y: number;
}
interface ReadonlyPoint {
  readonly x: number;
  readonly y: number;
}

const p3 = { x: 1, y: 2, z: 3 };
const a: Point = p3; // 1. acceptée : ce n'est pas un littéral frais, et z est en trop
// @ts-expect-error 2. rejetée : propriété z en trop dans un littéral objet frais
const b: Point = { x: 1, y: 2, z: 3 };
const c: ReadonlyPoint = a; // 3. acceptée : readonly restreint seulement ce que c peut faire
const d: Point = c; // 4. acceptée : readonly n'affecte pas l'assignabilité
// @ts-expect-error 5. rejetée : [number, number] n'a pas de troisième élément
const e: [number, number] = [1, 2, 3];
const f: number[] = [1, 2] as [number, number]; // 6. acceptée : un tuple est un tableau
// @ts-expect-error 7. rejetée : un unknown doit être restreint avant d'être assigné à une string
const g: string = JSON.parse('"x"') as unknown;
const h: string = JSON.parse('1'); // 8. acceptée : any est assignable à string, et h contient 1
// @ts-expect-error 9. rejetée : null n'est pas un number sous strictNullChecks
const i: number = null;

console.log([a, b, c, d, e, f, g, typeof h, i].length);
```

```text
9
```

Les lignes 2, 5, 7 et 9 sont rejetées : un littéral frais avec une propriété en trop, un tuple de mauvaise longueur, un `unknown` utilisé comme `string`, et `null` sous `strictNullChecks`. Les lignes 1, 3, 4, 6 et 8 sont acceptées, et deux d'entre elles méritent un second regard : la ligne 4 perd `readonly` à travers un alias, et la ligne 8 stocke le nombre `1` dans une `string`, parce que `JSON.parse` renvoie `any`.

</details>

## Sources

- [Manuel TypeScript — Types de tous les jours](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html), [Types objet](https://www.typescriptlang.org/docs/handbook/2/objects.html), [Compatibilité des types](https://www.typescriptlang.org/docs/handbook/type-compatibility.html), [Inférence de types](https://www.typescriptlang.org/docs/handbook/type-inference.html)
- [Référence TSConfig — strict](https://www.typescriptlang.org/tsconfig/#strict), [strictNullChecks](https://www.typescriptlang.org/tsconfig/#strictNullChecks), [noImplicitAny](https://www.typescriptlang.org/tsconfig/#noImplicitAny), [noUncheckedIndexedAccess](https://www.typescriptlang.org/tsconfig/#noUncheckedIndexedAccess)
- [Microsoft — Types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references), [Utilisation du type dynamic](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interop/using-type-dynamic)
