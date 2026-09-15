---
title: 1. Programmation au niveau des types
description: Des types qui calculent des types — les tester avec Expect et Equal, les types conditionnels, la distributivité et infer, les types mappés avec remappage des clés, les template literal types qui analysent des chaînes, les types récursifs et les limites du vérificateur dans typescript-go, puis une couche typée sur le hub SignalR de GA, comparée aux clés typées dont C# et Java ont besoin.
sidebar:
  order: 1
---

Code : les fichiers [`examples/l01_*`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples), [`examples/type-tests.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples/type-tests.ts) et [`errors/l01_*`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/errors), et les côtés C# et Java dans [`compare/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare) (`l01_typed_keys.cs`, `L01TypedKeys.java`) et [`compare_fail/`](https://github.com/spareilleux/learn/tree/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/compare_fail) (`l01_infer_from_name.cs`, `L01InferFromName.java`).

Un alias de type générique est une fonction dont les arguments et le résultat sont des types. Le vérificateur l'exécute chaque fois que l'alias est utilisé avec des arguments de type, et TypeScript donne à ce langage les constructions d'un petit langage fonctionnel : une conditionnelle, du filtrage par motif avec `infer`, une boucle sur les clés d'un objet, la concaténation et l'analyse de chaînes, et la récursion. C# et Java n'ont pas d'équivalent à l'intérieur du compilateur ; ce qui s'en approche le plus est un générateur de source ou un processeur d'annotations, qui écrivent du code avant sa compilation. Cette leçon écrit de tels types, les teste, et examine les limites que le vérificateur leur impose.

| Programmer avec des valeurs | Programmer avec des types |
|---|---|
| une fonction `f(x)` | un alias générique `F<X>` |
| `if`, `? :` | un type conditionnel, `X extends Y ? A : B` |
| déstructuration, filtrage par motif | `infer` |
| `map` sur les entrées d'un objet | un type mappé, `{ [K in keyof T]: … }` |
| gabarits de chaînes et analyse | *template literal types* |
| récursion, boucles | alias récursifs |
| un test unitaire | un type qui ne compile pas quand le résultat est faux |

## Tester les types

Les types n'ont pas de sortie à afficher, donc chaque exemple vérifie ses résultats avec un test de types : une ligne qui compile quand le type calculé est celui attendu et fait échouer le build sinon. Les deux utilitaires se trouvent dans [`type-tests.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/examples/type-tests.ts), et `check.sh` exécute `tsc` sur tout le projet, donc un test qui échoue fait échouer la CI :

```ts
// examples/type-tests.ts
// Des tests de types que tsc vérifie et que Node.js efface : Expect<Equal<A, B>> ne compile que si A et B sont le même type

// Deux types de fonction sont comparés avec un paramètre de type supplémentaire U, que tsc ne peut pas résoudre : ils ne sont assignables
// que si A et B sont identiques, ce qui attrape any, les unions et les modificateurs optionnels que extends seul laisse passer
export type Equal<A, B> = (<U>() => U extends A ? 1 : 2) extends <U>() => U extends B ? 1 : 2 ? true : false;
export type Expect<T extends true> = T;
```

`Expect<T extends true>` n'accepte que `true`. `Equal<A, B>` est moins évident. Un `[A] extends [B] ? ([B] extends [A] ? true : false) : false` plus simple compare l'assignabilité dans les deux sens, et l'assignabilité est trop permissive pour un test : `any` est assignable à tout et réciproquement, et `{ a?: string }` et `{ a?: string | undefined }` sont mutuellement assignables sans `exactOptionalPropertyTypes`. La version ci-dessus compare deux types de fonction génériques dont les types de retour sont des types conditionnels sur un paramètre de type `U` que rien ne fixe. Le vérificateur ne peut pas les évaluer, donc il compare les deux types conditionnels eux-mêmes, et ne les considère liés que si `A` et `B` sont identiques. L'astuce vient d'une [discussion dans le dépôt de TypeScript](https://github.com/microsoft/TypeScript/issues/27024#issuecomment-421529650), et des bibliothèques comme [`expect-type`](https://github.com/mmkal/expect-type) reposent sur la même idée ; la leçon 11 les compare.

Un test qui échoue, et une erreur attendue qui ne se produit pas, arrêtent tous deux le build :

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

`ElementOf<readonly string[]>` donne `never`, parce qu'un `readonly string[]` n'est pas assignable au `(infer E)[]` mutable, et le test l'attrape avec `TS2344`. La seconde erreur, `TS2578`, vient de [`// @ts-expect-error`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-9.html#-ts-expect-error-comments) : la ligne qui le suit compile, donc le commentaire est signalé comme inutilisé. Les deux ensemble forment une suite de tests de types : `Expect` pour ce qu'un type calcule, `@ts-expect-error` pour ce qu'une API doit refuser. Node.js exécute le fichier quand même et affiche `undefined`, puisque les alias de type et le commentaire sont tous effacés.

## Types conditionnels

```ts
// examples/l01_conditional.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// Un type conditionnel choisit une branche quand son argument de type est connu
type IsString<T> = T extends string ? true : false;
type _1 = Expect<Equal<IsString<'C#'>, true>>;
type _2 = Expect<Equal<IsString<440>, false>>;

// Distributif : un paramètre de type testé seul est testé une fois par membre d'une union
type ToArray<T> = T extends unknown ? T[] : never;
type _3 = Expect<Equal<ToArray<string | number>, string[] | number[]>>;
// Enveloppée dans un tuple, l'union est testée en bloc
type ToArrayWhole<T> = [T] extends [unknown] ? T[] : never;
type _4 = Expect<Equal<ToArrayWhole<string | number>, (string | number)[]>>;

// never est l'union vide : un type conditionnel distributif le transforme en never sans rien tester
type IsNeverWrong<T> = T extends never ? true : false;
type IsNever<T> = [T] extends [never] ? true : false;
type _5 = Expect<Equal<IsNeverWrong<never>, never>>;
type _6 = Expect<Equal<IsNever<never>, true>>;

// Extract et Exclude, de lib.es5.d.ts, sont des types conditionnels distributifs qui filtrent une union
type Accidental = 'natural' | 'sharp' | 'flat' | 'double-sharp' | 'double-flat';
type _7 = Expect<Equal<Extract<Accidental, `double-${string}`>, 'double-sharp' | 'double-flat'>>;
type _8 = Expect<Equal<Exclude<Accidental, `double-${string}`>, 'natural' | 'sharp' | 'flat'>>;

// infer nomme une partie du type testé
type ElementOf<T> = T extends readonly (infer E)[] ? E : never;
type PayloadOf<F> = F extends (data: infer D) => void ? D : never;
type _9 = Expect<Equal<ElementOf<readonly ['E', 'A', 'D']>, 'E' | 'A' | 'D'>>;
type _10 = Expect<Equal<PayloadOf<(data: { target: string }) => void>, { target: string }>>;

// infer avec une contrainte : la branche n'est prise que si le texte inféré est un nombre, qui devient un type nombre
type FretOf<T> = T extends `fret-${infer N extends number}` ? N : never;
type _11 = Expect<Equal<FretOf<'fret-12'>, 12>>;
type _12 = Expect<Equal<FretOf<'fret-XII'>, never>>;

// Un même nom inféré deux fois : une union depuis des positions covariantes, une intersection depuis des positions contravariantes
type Both<T> = T extends { a: infer U; b: infer U } ? U : never;
type BothParams<T> = T extends { a: (x: infer U) => void; b: (x: infer U) => void } ? U : never;
type _13 = Expect<Equal<Both<{ a: string; b: number }>, string | number>>;
type _14 = Expect<Equal<BothParams<{ a: (x: { root: string }) => void; b: (x: { quality: string }) => void }>, { root: string } & { quality: string }>>;

// Dans une fonction générique, T n'est pas encore connu : le type conditionnel est différé, et tsc ne peut pas choisir de branche
function describe<T extends string | number>(value: T): T extends string ? 'text' : 'number' {
  const kind = typeof value === 'string' ? 'text' : 'number';
  return kind as T extends string ? 'text' : 'number'; // une assertion : restreindre value ne restreint pas T
}
const fromText = describe('C#');
const fromNumber = describe(440);
type _15 = Expect<Equal<typeof fromText, 'text'>>;
type _16 = Expect<Equal<typeof fromNumber, 'number'>>;

// Des surcharges décrivent la même fonction sans type conditionnel, et sans assertion dans le corps
function describeOverloaded(value: string): 'text';
function describeOverloaded(value: number): 'number';
function describeOverloaded(value: string | number): 'text' | 'number' {
  return typeof value === 'string' ? 'text' : 'number';
}

// Les types sont effacés : à l'exécution, il ne reste que les valeurs
show('describe', [fromText, fromNumber]);
show('describeOverloaded', [describeOverloaded('C#'), describeOverloaded(440)]);
```

```text
describe                           [ 'text', 'number' ]
describeOverloaded                 [ 'text', 'number' ]
```

Un [type conditionnel](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html), `T extends U ? X : Y`, demande si `T` est assignable à `U`. Quatre de ses règles expliquent la plupart des surprises.

**La distributivité.** Quand le type testé est un paramètre de type seul, et que l'argument est une union, le type conditionnel est évalué une fois pour chaque membre et les résultats sont réunis : `ToArray<string | number>` est `string[] | number[]`, et non `(string | number)[]`. Le handbook les appelle des [types conditionnels distributifs](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html#distributive-conditional-types). C'est ce qui fait fonctionner `Extract` et `Exclude` : `lib.es5.d.ts` définit `Exclude<T, U>` comme `T extends U ? never : T`, qui garde les membres de `T` qui ne correspondent pas. Envelopper les deux côtés dans un tuple, `[T] extends [unknown]`, désactive la distribution, parce que `[T]` n'est plus un paramètre de type nu.

**`never` est l'union vide.** Un type conditionnel distributif sur zéro membre renvoie zéro résultat, donc `IsNeverWrong<never>` est `never`, et non `true`. Tester `never` demande la forme en tuple, `[T] extends [never]`. La même règle explique pourquoi un type conditionnel appliqué à un type filtré jusqu'à ne plus rien contenir disparaît sans bruit.

**`infer` nomme une partie du type testé.** `T extends readonly (infer E)[] ? E : never` correspond aux tableaux et nomme leur type d'élément. Depuis [TypeScript 4.7](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#extends-constraints-on-infer-type-variables), un `infer` peut porter une contrainte, `infer N extends number`, et quand il apparaît dans un *template literal type*, la [4.8](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-8.html#improved-inference-for-infer-types-in-template-string-types) convertit le texte reconnu en type littéral numérique : `FretOf<'fret-12'>` est le type `12`, et `'fret-XII'` ne correspond pas. Quand le même nom est inféré deux fois, les candidats sont combinés selon la position : une union dans les positions covariantes, comme deux types de propriétés, et une intersection dans les positions contravariantes, comme deux types de paramètres, parce qu'une fonction qui doit accepter les deux arguments accepte leur intersection. La leçon 2 revient sur ces positions.

**Dans un corps générique, la condition est différée.** `describe<T>` renvoie `T extends string ? 'text' : 'number'`. À chaque appel, `T` est connu, et le résultat est `'text'` ou `'number'`. Dans la fonction, `T` n'est pas connu, et restreindre `value` avec `typeof` ne restreint pas `T`, puisque `T` pourrait être l'union `string | number` elle-même. Le vérificateur ne peut pas choisir de branche, et refuse les deux littéraux :

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

L'exemple compile avec une assertion sur la valeur de retour, ce qui est la façon habituelle d'implémenter une fonction dont le type de retour est un type conditionnel. Des surcharges, comme dans `describeOverloaded`, disent la même chose aux appelants sans aucune assertion dans le corps, au prix d'une signature par cas. C# résout les surcharges de la même façon à la compilation ; ce qui n'a pas d'équivalent chez lui, c'est la signature unique dont le type de retour est calculé à partir de l'argument.

## Types mappés et remappage des clés

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

// Un type mappé homomorphe, { [K in keyof T]: … }, garde les modificateurs readonly et ? de chaque propriété
type Nullable<T> = { [K in keyof T]: T[K] | null };
type _1 = Expect<Equal<Nullable<Voicing>, { readonly id: string | null; frets: number[] | null; capo?: number | null; label?: string | null }>>;

// -readonly et -? retirent les modificateurs ; readonly et ? les ajoutent
type Mutable<T> = { -readonly [K in keyof T]: T[K] };
type Complete<T> = { [K in keyof T]-?: T[K] };
type _2 = Expect<Equal<Mutable<Voicing>, { id: string; frets: number[]; capo?: number; label?: string }>>;
type _3 = Expect<Equal<Complete<Voicing>, { readonly id: string; frets: number[]; capo: number; label: string }>>;

// Remappage des clés avec as : la nouvelle clé est calculée, ici avec un template literal type
type Getters<T> = { [K in keyof T & string as `get${Capitalize<K>}`]: () => T[K] };
type _4 = Expect<Equal<keyof Getters<Voicing>, 'getId' | 'getFrets' | 'getCapo' | 'getLabel'>>;

// Une clé remappée vers never est retirée : un filtre sur les propriétés
type KeysOfType<T, V> = keyof { [K in keyof T as T[K] extends V ? K : never]: T[K] };
type OptionalKeys<T> = keyof { [K in keyof T as {} extends Pick<T, K> ? K : never]: T[K] };
type _5 = Expect<Equal<KeysOfType<Voicing, string>, 'id'>>;
type _6 = Expect<Equal<OptionalKeys<Voicing>, 'capo' | 'label'>>;

// Un type mappé homomorphe appliqué à un tuple donne un tuple
type Boxed<T> = { [K in keyof T]: { value: T[K] } };
type _7 = Expect<Equal<Boxed<[string, number]>, [{ value: string }, { value: number }]>>;

// L'implémentation a besoin d'une assertion : tsc ne peut pas suivre Object.entries à travers un remappage des clés
function gettersOf<T extends object>(value: T): Getters<T> {
  const entries = Object.entries(value).map(([key, v]) => [`get${key.charAt(0).toUpperCase()}${key.slice(1)}`, () => v]);
  return Object.fromEntries(entries) as Getters<T>;
}
const voicing: Voicing = { id: 'C-open', frets: [-1, 3, 2, 0, 1, 0], label: 'C major' };
const getters = gettersOf(voicing);
show('Object.keys(getters)', Object.keys(getters));
show('getters.getLabel()', getters.getLabel());
// getCapo est dans le type, et pas dans l'objet : le type liste ce que Voicing permet, pas ce que cette valeur contient
show("'getCapo' in getters", 'getCapo' in getters);
```

```text
Object.keys(getters)               [ 'getId', 'getFrets', 'getLabel' ]
getters.getLabel()                 'C major'
'getCapo' in getters               false
```

Un [type mappé](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html) parcourt une union de clés. Quand cette union est `keyof T` pour un type `T`, le type mappé est dit homomorphe, et il garde les modificateurs de chaque propriété : `Nullable<Voicing>` a un `readonly id` et un `capo` optionnel, comme `Voicing`. Les modificateurs peuvent être retirés avec `-readonly` et `-?`, et c'est ainsi que la bibliothèque standard écrit `Required<T>`.

**Le remappage des clés**, ajouté dans [TypeScript 4.1](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-1.html#key-remapping-in-mapped-types), calcule un nouveau nom pour chaque clé avec `as` : `Getters<Voicing>` a `getId`, `getFrets`, `getCapo` et `getLabel`. L'intersection `keyof T & string` est nécessaire parce que `keyof` peut aussi contenir des nombres et des symboles, qu'un *template literal type* ne peut pas mettre en majuscule. Remapper une clé vers `never` retire la propriété, et c'est ainsi que `KeysOfType` et `OptionalKeys` filtrent les propriétés selon le type de leur valeur ou selon leur modificateur. `OptionalKeys` utilise une petite astuce : `{}` n'est assignable à `Pick<T, K>` que si la propriété `K` est optionnelle.

Un type mappé homomorphe appliqué à un tuple produit un tuple, `Boxed<[string, number]>`, ce qui permet à un seul type mappé de transformer chaque élément d'une liste d'arguments.

La fonction d'exécution `gettersOf` a besoin d'une assertion. `Object.entries` renvoie `[string, any][]`, et rien ne relie les chaînes calculées à l'exécution aux clés calculées par `Getters<T>`. La sortie montre l'autre écart : `getCapo` existe dans le type, parce que `Voicing` permet un `capo`, et pas dans l'objet, parce que cette valeur n'en a pas. Un type mappé décrit le type `T`, pas la valeur qui a été passée.

## Template literal types

```ts
// examples/l01_template.ts
import type { Equal, Expect } from './type-tests.ts';
import { attempt, show } from './show.ts';

// Un template literal type combine chaque membre de chaque union : 7 lettres × 3 altérations × 8 qualités
type Letter = 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G';
type Accidental = '' | '#' | 'b';
type Quality = '' | 'm' | '7' | 'maj7' | 'm7' | 'dim' | 'aug' | 'sus4';
type ChordSymbol = `${Letter}${Accidental}${Quality}`;
type _1 = Expect<Equal<Extract<ChordSymbol, `C${string}`>, 'C' | 'Cm' | 'C7' | 'Cmaj7' | 'Cm7' | 'Cdim' | 'Caug' | 'Csus4' | `C#${Quality}` | `Cb${Quality}`>>;

// infer dans un template literal type analyse une chaîne : un infer suivi d'un autre infer prend un caractère
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

// L'analyseur d'exécution est du code ordinaire ; sa signature donne à chaque argument littéral son type analysé
const chordPattern = /^([A-G][#b]?)(maj7|m7|m|7|dim|aug|sus4)?$/;
function parseChord<S extends ChordSymbol>(symbol: S): ParseChord<S> {
  const match = chordPattern.exec(symbol);
  if (!match) throw new TypeError(`not a chord symbol: ${symbol}`);
  return { root: match[1], quality: match[2] ?? '' } as ParseChord<S>; // la regex et le type disent deux fois la même chose
}
const fSharpMinor7 = parseChord('F#m7');
type _5 = Expect<Equal<typeof fSharpMinor7, { root: 'F#'; quality: 'm7' }>>;
show("parseChord('F#m7')", fSharpMinor7);
show("parseChord('Bbmaj7').root", parseChord('Bbmaj7').root);

// Un symbole connu seulement à l'exécution est une chaîne : il doit être vérifié avant l'appel
const isChordSymbol = (text: string): text is ChordSymbol => chordPattern.test(text);
for (const text of ['Gsus4', 'H7']) {
  attempt(`parse '${text}'`, () => (isChordSymbol(text) ? parseChord(text) : `rejected: ${text}`));
}

// Capitalize et les autres types de chaîne intrinsèques n'existent que pour tsc : la fonction d'exécution est écrite à part
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

Un [*template literal type*](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html) construit des types littéraux de chaîne comme un gabarit de chaîne construit des chaînes, et il se distribue sur les unions : sept lettres, trois altérations et huit qualités donnent 168 symboles d'accords, tous vérifiés par `tsc`. Le premier test de types liste les 24 symboles qui commencent par `C`, y compris `C#` et `Cb` avec chaque qualité.

Le filtrage par motif sur une chaîne utilise `infer` dans le gabarit. Deux règles font fonctionner `ParseChord`. Un `infer` suivi immédiatement d'un autre `infer` reconnaît exactement un caractère, donc `${infer L extends Letter}${infer Rest}` prend la première lettre. Et une contrainte sur l'`infer` fait échouer la correspondance quand le texte ne convient pas, et c'est ainsi que `#` et `b` sont distingués d'une qualité.

La fonction `parseChord` relie les deux mondes. Son paramètre est un `ChordSymbol`, donc un argument littéral est vérifié à la compilation, et son type de retour est `ParseChord<S>`, donc `parseChord('F#m7')` a le type `{ root: 'F#'; quality: 'm7' }`. La regex et le type décrivent deux fois la même grammaire, et rien ne vérifie qu'ils concordent, sauf des tests. Une chaîne qui arrive à l'exécution, comme `'H7'`, le nom allemand de B7, a le type `string`, et doit être vérifiée par une garde de type avant l'appel ; la garde est la moitié exécutable du type.

`Capitalize`, `Uncapitalize`, `Uppercase` et `Lowercase` sont des [types intrinsèques de manipulation de chaînes](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html#intrinsic-string-manipulation-types), implémentés dans le vérificateur. Ils n'ont pas d'équivalent à l'exécution, et `handlerName` réimplémente la mise en majuscule avec `charAt(0).toUpperCase()`.

## Types récursifs et limites du vérificateur

```ts
// examples/l01_recursive.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// Un type conditionnel récursif parcourt une chaîne un caractère à la fois : un doigté de guitare, corde de mi grave en premier
type Fret<C extends string> = C extends 'x' ? null : C extends `${infer N extends number}` ? N : never;
type Fingering<S extends string> = S extends `${infer C}${infer Rest}` ? [Fret<C>, ...Fingering<Rest>] : [];
type _1 = Expect<Equal<Fingering<'x32010'>, [null, 3, 2, 0, 1, 0]>>;

// Un type récursif suit un objet imbriqué : DeepReadonly, que la bibliothèque standard ne fournit pas
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

// Des chemins pointés dans un type imbriqué, comme les calculent les bibliothèques de formulaires et de traduction
type Paths<T> = T extends object
  ? { [K in keyof T & string]: T[K] extends readonly unknown[] ? K : T[K] extends object ? K | `${K}.${Paths<T[K]>}` : K }[keyof T & string]
  : never;
interface SceneSettings {
  camera: { position: { x: number; y: number; z: number }; fov: number };
  stars: boolean;
  tunings: Tuning[];
}
type _3 = Expect<Equal<Paths<SceneSettings>, 'camera' | 'camera.position' | 'camera.position.x' | 'camera.position.y' | 'camera.position.z' | 'camera.fov' | 'stars' | 'tunings'>>;

// Récursion terminale : quand l'appel récursif est toute la branche, tsc l'évalue dans une boucle, jusqu'à 1 000 fois.
// Fingering n'est pas récursif terminal : son appel se trouve dans un tuple. Avec un accumulateur, l'appel est la branche.
type FingeringTail<S extends string, Acc extends unknown[] = []> = S extends `${infer C}${infer Rest}` ? FingeringTail<Rest, [...Acc, Fret<C>]> : Acc;
type Long = `${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}`;
type _4 = Expect<Equal<FingeringTail<Long>['length'], 60>>;

// L'analyseur d'exécution, typé par le type récursif
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

Un alias de type peut faire référence à lui-même. `Fingering` parcourt une chaîne comme `'x32010'`, le doigté d'un accord de do majeur ouvert de la corde de mi grave à la corde de mi aigu, un caractère à la fois. `DeepReadonly` parcourt un objet, et s'arrête aux fonctions, dont les propriétés ne devraient pas passer en lecture seule. `Paths` calcule chaque chemin pointé dans un objet imbriqué, le genre de type qu'utilisent les bibliothèques de formulaires pour vérifier un nom de champ comme `'camera.position.x'` ; il s'arrête aux tableaux pour que l'union reste finie.

C'est sur la récursion que le vérificateur pose des limites, et l'extrait ci-dessous les atteint toutes les trois :

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

Les limites se trouvent dans [`internal/checker/checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go) de typescript-go, au tag de la 7.0.2 :

- **Profondeur d'instanciation : 100.** La [ligne 22016](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go#L22016-L22024) s'arrête quand 100 instanciations sont imbriquées, ou après 5 millions d'instanciations pour une même instruction, et signale `TS2589`. `Reverse` n'est pas récursif terminal : son appel récursif se trouve dans un tuple, `[...Reverse<Tail>, Head]`, donc chaque niveau attend le suivant. Dans un fichier à lui seul, inverser 48 éléments passe et 49 échoue, ce qui suggère environ deux instanciations imbriquées par niveau.
- **Récursion terminale : 1 000.** Quand un type conditionnel se résout en un autre type conditionnel dans sa branche fausse, ou en un appel récursif qui constitue toute la branche, le vérificateur l'évalue dans une boucle au lieu d'imbriquer, et la [ligne 24218](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go#L24211-L24222) arrête cette boucle après 1 000 itérations. `BuildTuple` transmet son accumulateur, donc il construit un tuple de 999 éléments, et échoue à 1 000. Cette optimisation est arrivée dans [TypeScript 4.5](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-5.html#tail-recursion-elimination-on-conditional-types).
- **Taille des unions : 100 000.** La [ligne 26521](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go#L26519-L26530) calcule la taille du produit cartésien d'un *template literal type* avant de le construire, et refuse une union de 100 000 membres ou plus avec `TS2590`. Quatre chiffres font 10 000 chaînes ; cinq en font exactement 100 000, une de trop.

L'extrait montre encore une chose, à laquelle je ne m'attendais pas. `Reversed49` échoue, et `Reversed80`, qui est plus profond, passe, parce qu'il vient après `Reversed40`. Les instanciations sont mises en cache, donc inverser 80 éléments atteint, après 40 niveaux, un tuple dont l'inversion est déjà connue. Seul, dans son propre fichier, `Reverse<BuildTuple<80>>` échoue aussi. La règle pratique est celle que suit l'exemple avec `FingeringTail` : écris les types récursifs avec un accumulateur, pour que l'appel récursif soit toute la branche, et ils pourront traiter des entrées de centaines d'éléments ; la version non terminale ne fonctionne que parce que les entrées sont courtes, et peut casser quand un type sans rapport cesse d'être en cache.

## Dans GuitarAlchemist/ga : un hub typé

La vue Prime Radiant de GA reçoit son graphe de gouvernance d'un hub SignalR. Côté client, [`DataLoader.ts`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L272-L326) enregistre dix handlers, un par événement, chacun écrit ainsi :

```ts
connection.on('NodeChanged', (data: { nodeId: string; health: unknown; healthStatus: string; color: string }) => {
  // Mise à jour partielle — un seul nœud
  onUpdate({ nodes: [data as unknown as GovernanceNode], edges: [], globalHealth: { resilienceScore: 0, lolliCount: 0, ergolCount: 0 }, timestamp: new Date().toISOString() } as GovernanceGraph);
});
```

La signature de `on` dans le client SignalR est [`on(methodName: string, newMethod: (...args: any[]) => any): void`](https://github.com/dotnet/aspnetcore/blob/a5383385245bdacc20ec19f30e46090a8154d8da/src/SignalR/clients/ts/signalr/src/HubConnection.ts#L508-L509), et [`invoke`](https://github.com/dotnet/aspnetcore/blob/a5383385245bdacc20ec19f30e46090a8154d8da/src/SignalR/clients/ts/signalr/src/HubConnection.ts#L466) prend `...args: any[]`. Chaque nom d'événement est une `string`, chaque charge utile un `any`, et chaque handler annote son paramètre à la main. Côté serveur, [`GovernanceHub.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Apps/ga-server/GaApi/Hubs/GovernanceHub.cs#L40-L43) dérive de `Hub`, et non du [`Hub<T>`](https://learn.microsoft.com/aspnet/core/signalr/hubs#strongly-typed-hubs) fortement typé, et envoie chaque événement avec `SendAsync("NodeChanged", new { … })`. Rien, d'un côté comme de l'autre, ne vérifie que les noms et les formes concordent. Le [`LiveDataConfig`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L171-L198) du client liste ensuite un callback pour la plupart des événements, là encore à la main : `onBeliefUpdate`, `onCameraSync`, `onNavigateToPlanet`, et `onScreenshotRequest` pour l'événement `RequestScreenshot`.

Une seule table d'événements suffit pour typer tout cela :

```ts
// examples/l01_hub_events.ts
// Le hub de gouvernance de GuitarAlchemist/ga, typé à partir d'une seule table d'événements au lieu d'une annotation par handler
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

// Ce que GovernanceHub.cs envoie au client, événement par événement, tel que SignalR le sérialise (noms de propriétés en camelCase)
interface GovernanceHubEvents {
  GraphUpdate: { nodes: GovernanceNode[]; timestamp: string };
  NodeChanged: { nodeId: string; health: HealthMetrics; healthStatus: string; color: string; timestamp: string };
  Connected: { message: string; connections: number; timestamp: string };
  NavigateToPlanet: { target: string; timestamp: string };
  RequestScreenshot: { reason: string; timestamp: string };
  CameraSync: { px: number; py: number; pz: number; lx: number; ly: number; lz: number; sender: string };
}
// Ce que le client peut appeler sur le hub : des listes de paramètres sous forme de tuples étiquetés
interface GovernanceHubMethods {
  Subscribe: [];
  SubmitScreenshot: [base64Image: string, format: string];
  SyncCamera: [px: number, py: number, pz: number, lx: number, ly: number, lz: number];
}

// La partie du HubConnection de @microsoft/signalr utilisée ici : chaque nom est une string, chaque argument un any
interface HubConnection {
  on(methodName: string, newMethod: (...args: any[]) => any): void;
  invoke<T = any>(methodName: string, ...args: any[]): Promise<T>;
}

// Une couche typée par-dessus : le nom est une clé de la table, et le paramètre du handler est retrouvé à partir de cette clé
function on<K extends keyof GovernanceHubEvents>(connection: HubConnection, name: K, handler: (data: GovernanceHubEvents[K]) => void): void {
  connection.on(name, handler);
}
function invoke<K extends keyof GovernanceHubMethods>(connection: HubConnection, name: K, ...args: GovernanceHubMethods[K]): Promise<void> {
  return connection.invoke(name, ...args);
}

// Le LiveDataConfig de GA liste ses callbacks à la main ; le remappage des clés les dérive de la table
type Callbacks<Events> = { [K in keyof Events & string as `on${K}`]?: (data: Events[K]) => void };
type GovernanceCallbacks = Callbacks<GovernanceHubEvents>;
type _1 = Expect<Equal<keyof GovernanceCallbacks, 'onGraphUpdate' | 'onNodeChanged' | 'onConnected' | 'onNavigateToPlanet' | 'onRequestScreenshot' | 'onCameraSync'>>;

// Une seule boucle enregistre chaque callback que l'appelant a fourni
const eventNames = ['GraphUpdate', 'NodeChanged', 'Connected', 'NavigateToPlanet', 'RequestScreenshot', 'CameraSync'] as const satisfies readonly (keyof GovernanceHubEvents)[];
type _2 = Expect<Equal<(typeof eventNames)[number], keyof GovernanceHubEvents>>;
function subscribe(connection: HubConnection, callbacks: GovernanceCallbacks): void {
  for (const name of eventNames) {
    const callback = callbacks[`on${name}`];
    if (callback) connection.on(name, callback);
  }
}

// Une fausse connexion qui enregistre les handlers et laisse l'exemple jouer le rôle du serveur
const handlers = new Map<string, (...args: any[]) => any>();
const connection: HubConnection = {
  on: (methodName, newMethod) => void handlers.set(methodName, newMethod),
  invoke: (methodName, ...args) => {
    console.log(`invoke ${methodName}(${args.join(', ')})`);
    return Promise.resolve() as Promise<never>; // une imitation : chaque appel se résout avec undefined, quel que soit le T qu'attend l'appelant
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

- **`on<K extends keyof GovernanceHubEvents>`** : le nom est une clé de la table, et le paramètre du handler est l'accès indexé `GovernanceHubEvents[K]`, retrouvé à partir du type littéral du nom. Le handler n'a besoin d'aucune annotation.
- **`invoke`** prend les paramètres de la méthode du hub sous forme de paramètre rest typé par un tuple étiqueté, `[px: number, py: number, …]`, donc un éditeur affiche les noms et `tsc` compte les arguments.
- **`Callbacks<Events>`** dérive les callbacks de `LiveDataConfig` avec le remappage des clés, `on${K}`. Les noms de GA suivent déjà ce motif pour la plupart des événements, et c'est ce qui permet à la dérivation de convenir ; la seule exception, `onScreenshotRequest`, est exactement le genre de dérive qu'un type dérivé empêche.
- **`as const satisfies`** vérifie que la liste des noms ne contient que des clés de la table, et le test de types `_2` vérifie qu'elle les contient toutes. La leçon 2 explique `satisfies`.

La couche typée transforme en erreurs de compilation quatre erreurs que le code de GA accepterait :

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

La première ligne est un nom d'événement mal orthographié, que SignalR n'appellerait jamais. La deuxième lit `data.id` sur une charge utile `NodeChanged`, qui a `nodeId` : c'est la confusion que cache le `data as unknown as GovernanceNode` de GA, et la leçon 4 montre ce qu'elle coûte à l'exécution. La troisième oublie trois des six coordonnées de la caméra. La quatrième utilise le nom de GA pour le callback de capture d'écran, et `TS7006` en découle : une fois la propriété inconnue, sa fonction n'a plus de type contextuel.

La table reste une affirmation sur le serveur. Elle dit ce que `GovernanceHub.cs` envoie, et rien ne la vérifie par rapport au code C# ; la leçon 4 ajoute la vérification à l'exécution, et générer la table à partir du hub, comme le fait [TypedSignalR.Client](https://github.com/nenoNaninu/TypedSignalR.Client.TypeScript), est l'alternative à la compilation (*à vérifier* sur GA).

### La même idée en C# et en Java

C# et Java n'ont pas de types littéraux : la chaîne `"NavigateToPlanet"` a le type `string`, et une méthode ne peut pas en tirer un type de charge utile. Un `On<T>(string name, Action<T> handler)` générique ne laisse rien à partir de quoi inférer `T` :

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

C# refuse l'appel avec `CS0411`. Java infère `T` comme `Object` puis refuse `data.target()`. La solution habituelle dans les deux langages est une clé typée : un objet qui porte le nom utilisé sur le fil et, dans son paramètre de type, le type de la charge utile.

```csharp
// compare/l01_typed_keys.cs
// C# n'a pas de types littéraux : une chaîne ne peut pas porter le type de sa charge utile, alors un objet clé typé le fait
var hub = new Hub();
hub.On(HubEvents.NavigateToPlanet, data => Console.WriteLine($"navigate to {data.Target}"));
hub.On(HubEvents.Connected, data => Console.WriteLine($"{data.Connections} clients connected"));
hub.Receive("NavigateToPlanet", new NavigateToPlanet("saturn"));
hub.Receive("Connected", new Connected(2));

record NavigateToPlanet(string Target);
record Connected(int Connections);

// La clé : un nom pour le fil, et un paramètre de type pour le compilateur
sealed record HubEvent<T>(string Name);

static class HubEvents
{
    public static readonly HubEvent<NavigateToPlanet> NavigateToPlanet = new("NavigateToPlanet");
    public static readonly HubEvent<Connected> Connected = new("Connected");
}

class Hub
{
    private readonly Dictionary<string, Action<object>> handlers = [];

    // T est inféré à partir de la clé, comme TypeScript infère K à partir de la chaîne
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

`HubEvents.NavigateToPlanet` est un `HubEvent<NavigateToPlanet>`, et `On<T>` en infère `T`, comme `on<K>` infère `K` à partir de la chaîne en TypeScript. La version Java garde une `Class<T>` dans la clé, ce qui permet aussi un cast vérifié à l'exécution : la dernière ligne le montre rejetant une charge utile du mauvais type, là où les types effacés de TypeScript ne peuvent rien vérifier. Ce qu'aucun des deux langages ne peut faire dans le système de types, c'est dériver `onNavigateToPlanet` de `NavigateToPlanet` ; en C#, c'est le travail d'un [générateur de source](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview).

| | C# | Java | TypeScript |
|---|---|---|---|
| Calculer un type à partir d'un type | non ; les générateurs de source écrivent du code | non ; les processeurs d'annotations écrivent du code | types conditionnels, mappés, *template literal types* |
| Une clé qui sélectionne un type de charge utile | un objet clé typé, `HubEvent<T>` | une clé typée avec `Class<T>` | le littéral de chaîne lui-même |
| Dériver des noms de membres | générateur de source | processeur d'annotations | remappage des clés, `on${K}` |
| Vérifier à l'exécution | casts sur des types réifiés | `Class<T>.cast` | rien : un schéma (leçon 4) |

## À retenir

- Un alias de type générique est une fonction exécutée par le vérificateur ; teste ses résultats avec `Expect<Equal<…>>` et `@ts-expect-error`, comme le fait la CI du cours.
- Un type conditionnel sur un paramètre de type nu se distribue sur les unions, transforme `never` en `never`, et est différé dans un corps générique ; enveloppe-le dans un tuple pour arrêter la distribution.
- `infer` extrait des parties d'un type, avec des contraintes depuis la 4.7, et donne des unions dans les positions covariantes et des intersections dans les positions contravariantes.
- Les types mappés homomorphes gardent les modificateurs, le remappage des clés calcule ou filtre des noms de propriétés, et les *template literal types* construisent et analysent des chaînes.
- Le vérificateur s'arrête à 100 instanciations imbriquées, 1 000 étapes récursives terminales, et des unions de 100 000 membres ; écris les types récursifs avec un accumulateur.
- Un type littéral permet à une chaîne de sélectionner un type, ce que C# et Java ne peuvent faire qu'avec un objet clé typé.

## Exercices

1. `getPath` dans `l01_recursive.ts` renvoie `unknown`. Écris `PathValue<T, P>`, le type qui se trouve au bout d'un chemin pointé, et utilise-le comme type de retour, pour que `getPath(settings, 'camera.fov')` soit un `number`.

<details>
<summary>Solution</summary>

[`solutions/l01_ex1_path_value.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l01_ex1_path_value.ts) :

```ts
// solutions/l01_ex1_path_value.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Paths<T> = T extends object
  ? { [K in keyof T & string]: T[K] extends readonly unknown[] ? K : T[K] extends object ? K | `${K}.${Paths<T[K]>}` : K }[keyof T & string]
  : never;

// Le type au bout d'un chemin pointé : détacher la première clé, la chercher, et continuer avec le reste
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
  // Une assertion : reduce parcourt les mêmes clés que PathValue, ce que tsc ne peut pas relier au contenu de la chaîne
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

`PathValue` coupe le chemin à son premier point avec `infer`, cherche la première clé dans `T`, et recommence sur le reste ; une clé qui n'est pas dans `T` donne `never`. L'appel `fov.toFixed(1)` ne compile que parce que le résultat est un `number`. L'implémentation garde une assertion : `reduce` parcourt les mêmes clés à l'exécution, et `tsc` ne peut pas relier les morceaux d'une chaîne connue seulement à l'exécution au type calculé à partir de son littéral.

</details>

2. `parseFingering` accepte n'importe quelle chaîne. Fais-lui accepter seulement des doigtés de six caractères faits de chiffres et de `x`, pour que `parseFingering('x3201')` et `parseFingering('x3201y')` soient des erreurs de compilation.

<details>
<summary>Solution</summary>

[`solutions/l01_ex2_six_strings.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l01_ex2_six_strings.ts) :

```ts
// solutions/l01_ex2_six_strings.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Fret<C extends string> = C extends 'x' ? null : C extends `${infer N extends number}` ? N : never;
type Fingering<S extends string, Acc extends unknown[] = []> = S extends `${infer C}${infer Rest}` ? Fingering<Rest, [...Acc, Fret<C>]> : Acc;

// Un doigté pour une guitare à six cordes : six caractères, chacun un chiffre ou x ; tout le reste donne never
type HasNever<T extends unknown[]> = true extends { [K in keyof T]: [T[K]] extends [never] ? true : false }[number] ? true : false;
type Valid<S extends string> = Fingering<S>['length'] extends 6 ? (HasNever<Fingering<S>> extends true ? never : S) : never;

type _1 = Expect<Equal<Valid<'x32010'>, 'x32010'>>;
type _2 = Expect<Equal<Valid<'x3201'>, never>>;
type _3 = Expect<Equal<Valid<'x3201y'>, never>>;

// S & Valid<S> : l'argument doit être à la fois le littéral et sa version vérifiée, never quand la vérification échoue
function parseFingering<S extends string>(text: S & Valid<S>): Fingering<S> {
  return [...text].map((c) => (c === 'x' ? null : Number(c))) as Fingering<S>;
}

console.log(parseFingering('x32010'), parseFingering('022100'));

function mistakes() {
  // @ts-expect-error: cinq cordes
  parseFingering('x3201');
  // @ts-expect-error: y n'est ni une case ni x
  parseFingering('x3201y');
}
console.log(typeof mistakes);
```

```text
[ null, 3, 2, 0, 1, 0 ] [ 0, 2, 2, 1, 0, 0 ]
function
```

`Valid<S>` est `S` quand le doigté a six éléments et qu'aucun d'eux n'est `never`, et `never` sinon. `HasNever` a besoin de la forme en tuple de l'`IsNever` de la leçon pour chaque élément, puisqu'un test distributif les sauterait. Le type de paramètre `S & Valid<S>` est la façon habituelle de valider un argument littéral : `S` est inféré à partir de l'argument, et quand `Valid<S>` est `never`, l'intersection est `never`, à quoi aucune chaîne n'est assignable. Les lignes `@ts-expect-error` sont les tests de types des refus.

</details>

3. Le `BeliefState` de GA, dans `DataLoader.ts`, a des propriétés en snake_case comme `truth_value` et `last_updated`, à côté de types en camelCase partout ailleurs. Écris `CamelKeys<T>`, qui renomme chaque clé en snake_case, et une fonction d'exécution `camelKeys(value)` typée avec lui.

<details>
<summary>Solution</summary>

[`solutions/l01_ex3_camel_keys.ts`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/solutions/l01_ex3_camel_keys.ts) :

```ts
// solutions/l01_ex3_camel_keys.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

// Le BeliefState de GA, dont les noms de propriétés arrivent en snake_case depuis les fichiers de croyances
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

`SnakeToCamel` est récursif : il coupe au premier tiret bas, et met en majuscule le reste converti, donc `last_updated_by_agent` devient `lastUpdatedByAgent`. `CamelKeys` remappe les clés et, étant homomorphe, garde `lastUpdated` optionnel. La conversion à l'exécution est une regex, et le test de types sur `SnakeToCamel` est ce qui relie les deux : si l'un d'eux traitait, par exemple, les chiffres différemment, seul un test avec une telle clé le remarquerait.

</details>

## Sources

- [Handbook TypeScript — Créer des types à partir de types](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html), [Types conditionnels](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html), [Types mappés](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html), [Template literal types](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html)
- Notes de version : [4.1 — remappage des clés](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-1.html#key-remapping-in-mapped-types), [4.5 — récursion terminale dans les types conditionnels](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-5.html#tail-recursion-elimination-on-conditional-types), [4.7 — contraintes `extends` sur `infer`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html#extends-constraints-on-infer-type-variables), [4.8 — `infer` dans les template string types](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-8.html#improved-inference-for-infer-types-in-template-string-types)
- [microsoft/typescript-go, `internal/checker/checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go), tag `typescript/v7.0.2`
- [dotnet/aspnetcore — `HubConnection.ts`](https://github.com/dotnet/aspnetcore/blob/a5383385245bdacc20ec19f30e46090a8154d8da/src/SignalR/clients/ts/signalr/src/HubConnection.ts), tag `v10.0.11` ; [ASP.NET Core — Hubs fortement typés](https://learn.microsoft.com/aspnet/core/signalr/hubs#strongly-typed-hubs)
- [Microsoft — Inférence de type dans les méthodes génériques (CS0411)](https://learn.microsoft.com/dotnet/csharp/misc/cs0411), [Générateurs de source](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview) ; [The Java Tutorials — Inférence de type](https://docs.oracle.com/javase/tutorial/java/generics/genTypeInference.html)
