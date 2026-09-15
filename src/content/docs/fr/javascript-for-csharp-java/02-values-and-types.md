---
title: 2. Valeurs et types
description: let et const, les huit types de JavaScript, number comme double et BigInt, les chaînes, undefined et null, == face à ===, et les conversions implicites — chacun comparé à C# et Java, avec la vraie sortie de Node.js.
sidebar:
  order: 2
---

Code : les fichiers [`examples/l02_*.js`](https://github.com/spareilleux/learn/tree/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/examples), et les côtés C# et Java dans [`compare/l02_numbers.cs`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/compare/l02_numbers.cs) et [`compare/L02Numbers.java`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/compare/L02Numbers.java).

Les exemples de cette leçon et des deux suivantes affichent leurs résultats avec deux petites fonctions utilitaires de [`examples/show.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/examples/show.js). `show` affiche une étiquette, puis la valeur comme le ferait le shell interactif de Node.js, avec les chaînes entre guillemets pour que `'12'` et `12` se distinguent. `attempt` fait de même pour une fonction, et affiche l'erreur à la place quand la fonction lève une exception.

```js
// examples/show.js
import { inspect } from 'node:util';

export function show(label, value) {
  console.log(`${label.padEnd(34)} ${inspect(value)}`);
}

export function attempt(label, fn) {
  try {
    show(label, fn());
  } catch (err) {
    console.log(`${label.padEnd(34)} ${err.name}: ${err.message}`);
  }
}
```

## let, const et var

| | C# | Java | JavaScript |
|---|---|---|---|
| Une variable que tu peux réassigner | `var count = 1;` | `var count = 1;` | `let count = 1;` |
| Une variable que tu ne peux pas réassigner | un champ `readonly` ; pas d'équivalent local | `final var count = 1;` | `const count = 1;` |
| Une constante connue à la compilation | `const int Count = 1;` | `static final int COUNT = 1;` | — |
| L'ancienne façon | — | — | `var count = 1;`, dont la portée est la fonction ([leçon 3](../03-functions-and-scope/#le-hoisting-et-la-zone-morte-temporelle)) |

```js
// examples/l02_let_const.js
import { attempt, show } from './show.js';

let count = 1;
count = 2; // let : la liaison peut changer
show('count', count);

const settings = { theme: 'dark', tabs: ['lessons'] };
settings.theme = 'light'; // const : la liaison ne peut pas changer, l'objet si
settings.tabs.push('journal');
show('settings', settings);
attempt('settings = {}', () => {
  settings = {};
});

const frozen = Object.freeze({ theme: 'dark', tabs: ['lessons'] });
attempt("frozen.theme = 'light'", () => {
  frozen.theme = 'light'; // un module est du code strict : l'affectation lève une exception
});
frozen.tabs.push('journal'); // freeze est superficiel
show('frozen', frozen);
```

```text
count                              2
settings                           { theme: 'light', tabs: [ 'lessons', 'journal' ] }
settings = {}                      TypeError: Assignment to constant variable.
frozen.theme = 'light'             TypeError: Cannot assign to read only property 'theme' of object '#<Object>'
frozen                             { theme: 'dark', tabs: [ 'lessons', 'journal' ] }
```

`const` est le `final` de Java, pas le `const` de C# : la variable désigne toujours le même objet, et l'objet reste mutable. [`Object.freeze`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/freeze) rend en lecture seule les propriétés d'un objet, et pas les objets vers lesquels elles pointent. L'erreur arrive à l'exécution, quand la ligne s'exécute : rien ne la vérifie avant. Utilise `const` par défaut et `let` quand tu réassignes ; `var` ne se trouve que dans du vieux code.

## Les valeurs ont des types, les variables non

```js
// examples/l02_typeof.js
import { show } from './show.js';

let value = 42;
show('typeof value', typeof value);
value = 'forty-two'; // pas d'erreur : la variable n'a pas de type
show('typeof value', typeof value);

show('typeof undefined', typeof undefined);
show('typeof true', typeof true);
show('typeof 3.14', typeof 3.14);
show('typeof 10n', typeof 10n);
show("typeof 'text'", typeof 'text');
show('typeof Symbol()', typeof Symbol());
show('typeof {}', typeof {});
show('typeof []', typeof []);
show('typeof null', typeof null);
show('typeof (() => 1)', typeof (() => 1));
show('Array.isArray([])', Array.isArray([]));
```

```text
typeof value                       'number'
typeof value                       'string'
typeof undefined                   'undefined'
typeof true                        'boolean'
typeof 3.14                        'number'
typeof 10n                         'bigint'
typeof 'text'                      'string'
typeof Symbol()                    'symbol'
typeof {}                          'object'
typeof []                          'object'
typeof null                        'object'
typeof (() => 1)                   'function'
Array.isArray([])                  true
```

La spécification définit [huit types](https://tc39.es/ecma262/#sec-ecmascript-language-types) : sept types primitifs, qui sont Undefined, Null, Boolean, Number, BigInt, String et Symbol, et Object. Les tableaux, les fonctions, les dates et les maps sont tous des objets. L'[opérateur `typeof`](https://tc39.es/ecma262/#sec-typeof-operator) suit presque ces types, avec deux exceptions inscrites dans la spécification : il renvoie `'object'` pour `null`, une erreur de la première implémentation conservée pour la compatibilité, et `'function'` pour les objets que l'on peut appeler. Pour reconnaître un tableau, utilise [`Array.isArray`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/isArray).

En C#, le modèle le plus proche est un programme où chaque variable est déclarée `dynamic`. La différence apparaît quand les types ne correspondent pas : C# lève une `RuntimeBinderException`, et JavaScript convertit l'une des valeurs et continue. La plupart des surprises de cette leçon viennent de ces conversions. Les types statiques qui attrapent les erreurs avant l'exécution du programme sont ce qu'ajoute TypeScript, dans le cours suivant.

## number : toujours un double

JavaScript a un seul type numérique pour les entiers et les fractions : un nombre à virgule flottante [IEEE 754](https://tc39.es/ecma262/#sec-ecmascript-language-types-number-type) sur 64 bits, le `double` de C# et Java.

```js
// examples/l02_numbers.js
import { show } from './show.js';

show('0.1 + 0.2', 0.1 + 0.2);
show('7 / 2', 7 / 2);
show('Math.trunc(-7 / 2)', Math.trunc(-7 / 2));
show('Math.floor(-7 / 2)', Math.floor(-7 / 2));
show('-7 % 2', -7 % 2);
show('1 / 0', 1 / 0);
show('0 / 0', 0 / 0);
show('NaN === NaN', NaN === NaN);
show('Number.isNaN(NaN)', Number.isNaN(NaN));
show("isNaN('abc')", isNaN('abc'));
show("Number.isNaN('abc')", Number.isNaN('abc'));

// Les entiers sont exacts jusqu'à 2^53 - 1
show('Number.MAX_SAFE_INTEGER', Number.MAX_SAFE_INTEGER);
show('2 ** 53 + 1', 2 ** 53 + 1);
show('2 ** 53 + 1 === 2 ** 53', 2 ** 53 + 1 === 2 ** 53);
show('9007199254740993', 9007199254740993);
show('Number.isSafeInteger(2 ** 53)', Number.isSafeInteger(2 ** 53));

// Les opérateurs bit à bit travaillent sur des entiers 32 bits
show('2 ** 31 | 0', 2 ** 31 | 0);
show('(2 ** 32 + 5) | 0', (2 ** 32 + 5) | 0);

// Zéro a un signe
show('-0', -0);
show('-0 === 0', -0 === 0);
show('Object.is(-0, 0)', Object.is(-0, 0));
show('(0.1 + 0.2).toFixed(2)', (0.1 + 0.2).toFixed(2));
```

```text
0.1 + 0.2                          0.30000000000000004
7 / 2                              3.5
Math.trunc(-7 / 2)                 -3
Math.floor(-7 / 2)                 -4
-7 % 2                             -1
1 / 0                              Infinity
0 / 0                              NaN
NaN === NaN                        false
Number.isNaN(NaN)                  true
isNaN('abc')                       true
Number.isNaN('abc')                false
Number.MAX_SAFE_INTEGER            9007199254740991
2 ** 53 + 1                        9007199254740992
2 ** 53 + 1 === 2 ** 53            true
9007199254740993                   9007199254740992
Number.isSafeInteger(2 ** 53)      false
2 ** 31 | 0                        -2147483648
(2 ** 32 + 5) | 0                  5
-0                                 -0
-0 === 0                           true
Object.is(-0, 0)                   false
(0.1 + 0.2).toFixed(2)             '0.30'
```

Les mêmes opérations en C# et en Java :

```text
> dotnet run l02_numbers.cs
0.1 + 0.2              0.30000000000000004
7 / 2                  3
7.0 / 2                3.5
1.0 / 0                Infinity
NaN == NaN             False
1 / zero               DivideByZeroException: Attempted to divide by zero.
int.MaxValue + 1       -2147483648
long.MaxValue          9223372036854775807
BigInteger.Pow(2, 64)  18446744073709551616
"1" + 2                12
guitar emoji .Length    2
-0.0 == 0.0            True
```

```text
> java L02Numbers.java
0.1 + 0.2              0.30000000000000004
7 / 2                  3
7.0 / 2                3.5
1.0 / 0                Infinity
NaN == NaN             false
1 / zero               java.lang.ArithmeticException: / by zero
Integer.MAX_VALUE + 1  -2147483648
Long.MAX_VALUE         9223372036854775807
BigInteger 2^64        18446744073709551616
"1" + 2                12
guitar emoji .length() 2
-0.0 == 0.0            true
```

Ce que JavaScript partage avec C# et Java :

- `0.1 + 0.2` vaut `0.30000000000000004` dans les trois : c'est une propriété de la virgule flottante binaire, pas de JavaScript. Pour de l'argent, compte en centimes entiers, ou utilise une bibliothèque décimale.
- Diviser un double par zéro donne `Infinity`, et `NaN` est différent de tout, y compris de lui-même.
- `%` garde le signe du dividende : `-7 % 2` vaut `-1` dans les trois.

Ce qui diffère :

- **Il n'y a pas de division entière.** `7 / 2` vaut `3.5`. [`Math.trunc`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/trunc) arrondit vers zéro comme la division entière de C# et Java ; `Math.floor` arrondit vers le bas, ce qui diffère pour les nombres négatifs.
- **Il n'y a pas de dépassement d'entier, ni d'exception pour une division par zéro.** Les entiers sont exacts jusqu'à 2 puissance 53, moins 1, qui est `Number.MAX_SAFE_INTEGER` ; au-delà, le double arrondit en silence. Le littéral `9007199254740993` vaut déjà `9007199254740992` au démarrage du programme. Un identifiant `long` de C# envoyé en JSON peut perdre ses derniers chiffres quand un client JavaScript le parse, et c'est pourquoi certaines API envoient les grands identifiants sous forme de chaînes.
- **Les opérateurs bit à bit convertissent en entiers 32 bits** ([ToInt32](https://tc39.es/ecma262/#sec-toint32)) : `2 ** 31 | 0` reboucle sur `-2147483648`, et `x | 0`, un vieil idiome pour tronquer un nombre, casse au-delà de deux milliards.
- **Le `isNaN` global convertit d'abord son argument**, donc `isNaN('abc')` vaut `true`. [`Number.isNaN`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isNaN) ne convertit pas, et c'est celui qu'il faut utiliser.
- **Zéro a un signe que `===` ignore.** [`Object.is`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is) voit la différence entre `-0` et `0`, et dit que `NaN` est `NaN`.

## bigint : des entiers de toute taille

```js
// examples/l02_bigint.js
import { attempt, show } from './show.js';

show('2n ** 64n', 2n ** 64n);
show('7n / 2n', 7n / 2n);
show('typeof 7n', typeof 7n);
show('BigInt(2 ** 53) + 1n', BigInt(2 ** 53) + 1n);
attempt('1n + 1', () => 1n + 1);
show('1n + BigInt(1)', 1n + BigInt(1));
show('1n == 1', 1n == 1);
show('1n === 1', 1n === 1);
show('Number(2n ** 64n)', Number(2n ** 64n));
attempt('BigInt(1.5)', () => BigInt(1.5));
attempt('JSON.stringify({ id: 1n })', () => JSON.stringify({ id: 1n }));
attempt('Math.max(1n, 2n)', () => Math.max(1n, 2n));
```

```text
2n ** 64n                          18446744073709551616n
7n / 2n                            3n
typeof 7n                          'bigint'
BigInt(2 ** 53) + 1n               9007199254740993n
1n + 1                             TypeError: Cannot mix BigInt and other types, use explicit conversions
1n + BigInt(1)                     2n
1n == 1                            true
1n === 1                           false
Number(2n ** 64n)                  18446744073709552000
BigInt(1.5)                        RangeError: The number 1.5 cannot be converted to a BigInt because it is not an integer
JSON.stringify({ id: 1n })         TypeError: Do not know how to serialize a BigInt
Math.max(1n, 2n)                   TypeError: Cannot convert a BigInt value to a number
```

Un [`BigInt`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt) est un entier de taille quelconque, écrit avec un suffixe `n`, comme [`System.Numerics.BigInteger`](https://learn.microsoft.com/dotnet/api/system.numerics.biginteger) et [`java.math.BigInteger`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigInteger.html), avec des opérateurs au lieu de méthodes. Sa division tronque, comme la division entière en C#. Ici JavaScript est *plus strict* que C# : C# convertit implicitement un `int` en `BigInteger`, alors que JavaScript refuse de mélanger les deux types dans l'arithmétique et demande un `BigInt(…)` ou un `Number(…)` explicite. `JSON.stringify` et `Math` n'acceptent pas non plus les BigInts.

## string : UTF-16, immuable

```js
// examples/l02_strings.js
import { attempt, show } from './show.js';

const course = 'JavaScript';
show('course.length', course.length);
show('course[4]', course[4]);
show('course.at(-1)', course.at(-1));
show('`${course} for C#`', `${course} for C#`);
attempt("course[0] = 'X'", () => {
  course[0] = 'X';
});
show("'é'.length", 'é'.length);
show("'e\\u0301'.length", 'é'.length);
show("'é' === 'e\\u0301'", 'é' === 'é');
show("'e\\u0301'.normalize() === 'é'", 'é'.normalize() === 'é');
show("'🎸'.length", '🎸'.length);
show("[...'🎸'].length", [...'🎸'].length);
show("'🎸'.codePointAt(0)", '🎸'.codePointAt(0));
show("'b' > 'a'", 'b' > 'a');
show("'B' > 'a'", 'B' > 'a');
show("'10' < '9'", '10' < '9');
```

```text
course.length                      10
course[4]                          'S'
course.at(-1)                      't'
`${course} for C#`                 'JavaScript for C#'
course[0] = 'X'                    TypeError: Cannot assign to read only property '0' of string 'JavaScript'
'é'.length                         1
'é'.length                   2
'é' === 'é'                  false
'é'.normalize() === 'é'      true
'🎸'.length                        2
[...'🎸'].length                   1
'🎸'.codePointAt(0)                127928
'b' > 'a'                          true
'B' > 'a'                          false
'10' < '9'                         true
```

Les chaînes fonctionnent comme en C# et en Java : des séquences immuables d'[unités de code UTF-16](https://tc39.es/ecma262/#sec-ecmascript-language-types-string-type), où `length` compte les unités de code et où un emoji hors du plan multilingue de base en prend deux. Les programmes C# et Java ci-dessus affichent `2` pour la même guitare. Il n'y a pas de type `char` séparé : `course[4]` est une chaîne de longueur un. Étaler une chaîne avec `...` itère sur les points de code, et c'est ainsi qu'on compte la guitare comme un seul caractère. `===` compare les unités de code, donc les deux écritures de `é` diffèrent jusqu'à ce que [`normalize`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/normalize) les rende égales, et `<` compare aussi les unités de code, donc les majuscules sont triées avant les minuscules et `'10'` avant `'9'`. La leçon 11 compare les chaînes comme les gens les lisent, avec `Intl.Collator`.

## undefined et null

C# et Java ont une seule valeur absente, `null`. JavaScript en a deux.

```js
// examples/l02_null_undefined.js
import { attempt, show } from './show.js';

let notAssigned;
const page = { title: 'Mission', order: 0, draft: null };

function noReturn() {}
function greet(name) {
  return name;
}

show('notAssigned', notAssigned);
show('page.author', page.author);
show('noReturn()', noReturn());
show('greet()', greet());
show('page.draft', page.draft);
show('typeof page.draft', typeof page.draft);

attempt('page.author.name', () => page.author.name);
show('page.author?.name', page.author?.name);
show("page.author ?? 'anonymous'", page.author ?? 'anonymous');

// || remplace toute valeur falsy, ?? seulement null et undefined
show('page.order || 99', page.order || 99);
show('page.order ?? 99', page.order ?? 99);

show('JSON.stringify(page)', JSON.stringify({ ...page, author: undefined }));
show('null == undefined', null == undefined);
show('null === undefined', null === undefined);
```

```text
notAssigned                        undefined
page.author                        undefined
noReturn()                         undefined
greet()                            undefined
page.draft                         null
typeof page.draft                  'object'
page.author.name                   TypeError: Cannot read properties of undefined (reading 'name')
page.author?.name                  undefined
page.author ?? 'anonymous'         'anonymous'
page.order || 99                   99
page.order ?? 99                   0
JSON.stringify(page)               '{"title":"Mission","order":0,"draft":null}'
null == undefined                  true
null === undefined                 false
```

Le langage produit `undefined` de lui-même : pour une variable sans valeur, une propriété qui n'existe pas, un argument manquant, et une fonction qui ne renvoie rien. `null` n'apparaît que quand le code l'écrit. Lire une propriété manquante n'est pas une erreur, cela donne `undefined` ; l'erreur arrive une étape plus loin, quand tu lis une propriété *de* `undefined`, et ce `TypeError` est la `NullReferenceException` de JavaScript. `JSON.stringify` garde `null` et laisse tomber les propriétés qui valent `undefined`.

Les opérateurs `?.` et `??` fonctionnent comme en C#. Le piège est l'ancien ou logique, `||`, que tu trouveras partout : il renvoie son côté droit pour *toute* valeur falsy, `0` et la chaîne vide compris, alors que `??` ne le fait que pour `null` et `undefined`. `page.order || 99` transforme l'ordre `0` en `99`.

### Dans GuitarAlchemist/ga

[`BSPDoomExplorer.tsx`, ligne 4895](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L4895) lit la vitesse de rotation d'un échantillon 3D avec `obj.userData.rotationSpeed || 0.5`, et la [ligne 5386](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L5386) calcule le temps entre deux images. Réduit à du JavaScript simple :

```js
// examples/l02_ga_defaults.js

// Ligne 4895 : la vitesse de rotation d'un échantillon, 0.5 quand elle manque
function speedWithOr(userData) {
  return userData.rotationSpeed || 0.5;
}
function speedWithNullish(userData) {
  return userData.rotationSpeed ?? 0.5;
}
for (const userData of [{}, { rotationSpeed: 0.3 }, { rotationSpeed: 0 }]) {
  console.log(JSON.stringify(userData).padEnd(22), '||', speedWithOr(userData), ' ??', speedWithNullish(userData));
}

// Ligne 5386 : le temps depuis l'image précédente, stocké comme propriété de la fonction elle-même
function updateFPS(now) {
  const delta = now - updateFPS.lastTime || 0;
  updateFPS.lastTime = now;
  return delta;
}
console.log('first frame ', updateFPS(1000));
console.log('second frame', updateFPS(1016));
console.log('undefined - 1000 =', undefined - 1000, '; NaN || 0 =', NaN || 0);
```

```text
{}                     || 0.5  ?? 0.5
{"rotationSpeed":0.3}  || 0.3  ?? 0.3
{"rotationSpeed":0}    || 0.5  ?? 0
first frame  0
second frame 16
undefined - 1000 = NaN ; NaN || 0 = 0
```

Aujourd'hui, chaque échantillon reçoit une vitesse aléatoire entre 0,3 et 0,7 ([ligne 3039](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L3039)), donc le `||` ne rencontre jamais de zéro. Le même fichier arrête d'autres objets en fixant `rotationSpeed = 0` ([ligne 5556](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L5556)) : le jour où un échantillon sera arrêté de cette façon, `|| 0.5` le fera tourner à nouveau. `??` dit ce que la ligne veut dire.

La deuxième ligne fonctionne, mais pas pour la raison qu'elle laisse croire. La soustraction est prioritaire sur `||`, donc elle se lit `(now - updateFPS.lastTime) || 0`, et non `now - (updateFPS.lastTime || 0)`. À la première image, `lastTime` vaut `undefined`, la soustraction donne `NaN`, `NaN` est falsy, et le `|| 0` le transforme en `0`, que le code ignore ensuite avec `if (delta > 0)`.

## == et ===

```js
// examples/l02_equality.js
import { show } from './show.js';

show("'0' == 0", '0' == 0);
show("'' == 0", '' == 0);
show("'' == '0'", '' == '0');
show("'1' === 1", '1' === 1);
show('true == 1', true == 1);
show("true == 'true'", true == 'true');
show('[] == false', [] == false);
show('[0] == false', [0] == false);
show("[1, 2] == '1,2'", [1, 2] == '1,2');
show('null == 0', null == 0);
show('null >= 0', null >= 0);
show('undefined == 0', undefined == 0);
show('NaN == NaN', NaN == NaN);

// Le seul usage courant de == : null ou undefined en un seul test
for (const value of [null, undefined, 0, '', false]) {
  show(`${String(value) || "''"} == null`, value == null);
}
```

```text
'0' == 0                           true
'' == 0                            true
'' == '0'                          false
'1' === 1                          false
true == 1                          true
true == 'true'                     false
[] == false                        true
[0] == false                       true
[1, 2] == '1,2'                    true
null == 0                          false
null >= 0                          true
undefined == 0                     false
NaN == NaN                         false
null == null                       true
undefined == null                  true
0 == null                          false
'' == null                         false
false == null                      false
```

En C# et en Java, comparer une chaîne à un nombre ne compile pas. En JavaScript, `===` ([IsStrictlyEqual](https://tc39.es/ecma262/#sec-isstrictlyequal)) répond `false` quand les types diffèrent, et `==` ([IsLooselyEqual](https://tc39.es/ecma262/#sec-islooselyequal)) convertit d'abord, en suivant quelques règles :

1. Deux valeurs du même type sont comparées comme le ferait `===`.
2. `null` et `undefined` sont égaux entre eux, et à rien d'autre.
3. Une chaîne comparée à un nombre devient un nombre.
4. Un booléen devient d'abord un nombre : `true` vaut `1`, `false` vaut `0`.
5. Un objet comparé à une primitive est converti en primitive, en général par sa méthode `toString` : un tableau vide devient la chaîne vide, `[0]` devient la chaîne `'0'`, et `[1, 2]` devient `'1,2'`.

`[] == false` applique tour à tour les règles 4, 5 et 3 : `false` devient le nombre zéro, le tableau vide devient la chaîne vide, et la chaîne vide devient zéro. La chaîne vide et la chaîne `'0'` sont toutes deux faiblement égales au nombre zéro, mais pas l'une à l'autre : l'égalité faible n'est même pas transitive. Et `null >= 0` est vrai alors que `null == 0` est faux, parce que les opérateurs relationnels convertissent `null` en `0` et que `==` a sa propre règle pour `null`.

Utilise les opérateurs stricts, `===` et `!==`, partout. Le seul idiome qui vaille d'être gardé est `value == null`, vrai pour `null` et `undefined` seulement, que GA utilise dans [`DynamicPanel.tsx`, ligne 36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/DynamicPanel.tsx#L36). La règle [`eqeqeq`](https://eslint.org/docs/latest/rules/eqeqeq) d'ESLint impose cette règle et a une option pour autoriser cet idiome ; elle ne fait pas partie de `js.configs.recommended`, la base de la [configuration ESLint](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/eslint.config.js#L10) de GA.

## Conversions : +, -, parsing et truthiness

```js
// examples/l02_coercion.js
import { show } from './show.js';

show("'1' + 2", '1' + 2);
show("1 + 2 + '3'", 1 + 2 + '3');
show("'3' - 1", '3' - 1);
show("'5' * '2'", '5' * '2');
show("'3' + -'1'", '3' + -'1');
show('[] + []', [] + []);
show('[] + {}', [] + {});
show("+'42'", +'42');

// Parsing : Number lit toute la chaîne, parseInt s'arrête au premier caractère invalide
show("Number('')", Number(''));
show("Number(' 12 ')", Number(' 12 '));
show("Number('12px')", Number('12px'));
show("parseInt('12px', 10)", parseInt('12px', 10));
show("parseInt('', 10)", parseInt('', 10));
show("parseInt('0x1F')", parseInt('0x1F'));
show("parseInt('1e3', 10)", parseInt('1e3', 10));
show("Number('1e3')", Number('1e3'));
show('parseInt(0.0000005)', parseInt(0.0000005));

// Truthy et falsy : if convertit n'importe quelle valeur en booléen
const values = [false, 0, -0, 0n, '', null, undefined, NaN, '0', 'false', [], {}, -1];
const falsy = values.filter((v) => !v);
const truthy = values.filter((v) => v);
show('falsy', falsy);
show('truthy', truthy);
```

```text
'1' + 2                            '12'
1 + 2 + '3'                        '33'
'3' - 1                            2
'5' * '2'                          10
'3' + -'1'                         '3-1'
[] + []                            ''
[] + {}                            '[object Object]'
+'42'                              42
Number('')                         0
Number(' 12 ')                     12
Number('12px')                     NaN
parseInt('12px', 10)               12
parseInt('', 10)                   NaN
parseInt('0x1F')                   31
parseInt('1e3', 10)                1
Number('1e3')                      1000
parseInt(0.0000005)                5
falsy                              [ false, 0, -0, 0n, '', null, undefined, NaN ]
truthy                             [ '0', 'false', [], {}, -1 ]
```

`+` est l'opérateur qui surprend, parce qu'il a [deux sens](https://tc39.es/ecma262/#sec-applystringornumericbinaryoperator) : si l'un des opérandes est une chaîne après conversion en primitive, il concatène ; sinon il additionne. C# et Java concatènent eux aussi `"1" + 2` en `"12"`, comme le montrent leurs sorties ci-dessus ; la différence est que JavaScript convertit aussi les objets, un tableau vide en chaîne vide et un objet vide en texte `[object Object]`, et évalue de gauche à droite, donc `1 + 2 + '3'` vaut `'33'`. Les autres opérateurs arithmétiques, `-`, `*` et `/`, n'ont qu'un sens et convertissent les deux côtés en nombres, tout comme le `+` unaire.

Pour transformer volontairement du texte en nombre :

- [`Number(text)`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/Number) lit toute la chaîne, ignore les espaces autour, accepte `1e3` et `0x1F`, et renvoie `NaN` s'il reste autre chose. Son seul piège : la chaîne vide donne `0`.
- [`parseInt(text, 10)`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt) lit des chiffres jusqu'au premier caractère qu'il ne peut pas utiliser, donc `'12px'` donne `12`. Passe toujours la base : sans elle, un préfixe `0x` bascule en hexadécimal. Son argument est une chaîne : `parseInt(0.0000005)` convertit d'abord le nombre en `'5e-7'`, et lit `5`.
- Aucun des deux ne lève d'exception. `int.Parse` en C# et `Integer.parseInt` en Java rejettent `'12px'` avec une exception ; en JavaScript, vérifie le résultat avec `Number.isNaN` ou `Number.isInteger`.

Un `if`, `!`, `&&` et `||` acceptent n'importe quelle valeur et la convertissent avec [ToBoolean](https://tc39.es/ecma262/#sec-toboolean). Huit valeurs sont *falsy* : `false`, `0`, `-0`, `0n`, la chaîne vide, `null`, `undefined` et `NaN`. Tout le reste est *truthy*, y compris la chaîne `'0'`, la chaîne `'false'` et un tableau vide. C# et Java exigent un booléen dans une condition, donc `if (items.length)` n'y a pas d'équivalent, et `if (count)` est faux quand le compte vaut zéro.

## À retenir

- `const` fixe la variable, pas l'objet ; `Object.freeze` fixe un niveau d'un objet.
- Les valeurs ont des types, les variables non : `typeof` te donne le type, avec `'object'` pour `null` et les tableaux.
- `number` est un `double` : pas de division entière, pas de dépassement, des entiers exacts seulement jusqu'à 2 puissance 53, moins 1. `bigint` couvre les entiers plus grands et refuse de se mélanger avec `number`.
- Les chaînes sont en UTF-16 et immuables, comme en C# et en Java.
- `undefined` signifie « jamais défini », `null` signifie « défini à rien » ; `??` remplace les deux, `||` remplace toute valeur falsy, `0` et `''` compris.
- Utilise `===`. `== null` est la seule comparaison faible qui vaille d'être écrite.
- `+` concatène dès qu'une chaîne est en jeu ; `Number` et `parseInt(text, 10)` parsent, et aucun des deux ne lève d'exception.

## Exercices

1. Écris `isBlank(value)`, vrai pour `null`, `undefined` et les chaînes faites uniquement d'espaces, et faux pour tout le reste, y compris `0`, `false` et `NaN`.

<details>
<summary>Solution</summary>

[`solutions/l02_ex1_is_blank.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/solutions/l02_ex1_is_blank.js) :

```js
function isBlank(value) {
  return value == null || (typeof value === 'string' && value.trim() === '');
}
```

```text
isBlank(null)                      true
isBlank(undefined)                 true
isBlank('')                        true
isBlank('   ')                     true
isBlank('\t\n')                    true
isBlank('text')                    false
isBlank(0)                         false
isBlank(false)                     false
isBlank(NaN)                       false
isBlank([])                        false
```

`!value` serait plus court et faux : il est vrai pour `0`, `false` et `NaN`. `value == null` couvre `null` et `undefined` en un seul test, et le contrôle `typeof` tient `trim` à l'écart des valeurs qui ne sont pas des chaînes.

</details>

2. Écris `parsePort(text)`, qui renvoie un numéro de port entre 1 et 65535 à partir d'une chaîne de chiffres, et lève un `TypeError` ou un `RangeError` sinon, comme le feraient `int.Parse` ou `Integer.parseInt`. Essaie-la avec `'8080'`, `''`, `' 80'`, `'8080abc'`, `'0x50'`, `'1e3'`, `'70000'` et le nombre `8080`.

<details>
<summary>Solution</summary>

[`solutions/l02_ex2_parse_port.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/solutions/l02_ex2_parse_port.js) :

```js
function parsePort(text) {
  if (typeof text !== 'string' || !/^\d+$/.test(text)) {
    throw new TypeError(`not a port: ${JSON.stringify(text)}`);
  }
  const port = Number(text);
  if (port < 1 || port > 65535) {
    throw new RangeError(`port out of range: ${port}`);
  }
  return port;
}
```

```text
"8080"     8080
"443"      443
""         TypeError: not a port: ""
" 80"      TypeError: not a port: " 80"
"8080abc"  TypeError: not a port: "8080abc"
"0x50"     TypeError: not a port: "0x50"
"1e3"      TypeError: not a port: "1e3"
"70000"    RangeError: port out of range: 70000
"0"        RangeError: port out of range: 0
8080       TypeError: not a port: 8080
```

L'expression régulière fait le travail qu'aucune des deux fonctions intégrées ne fait : `Number` seul accepterait `''` comme `0`, `' 80'`, `'0x50'` et `'1e3'`, et `parseInt` accepterait `'8080abc'`. Une fois que la chaîne ne contient que des chiffres, `Number` est sûr. La leçon 11 couvre les expressions régulières.

</details>

3. Prédis chaque résultat, puis exécute [`solutions/l02_ex3_predict.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/solutions/l02_ex3_predict.js) : `'2' + 2 * '2'`, `null + 1`, `undefined + 1`, `[] == ![]`, `'b' + 'a' + +'a' + 'a'`, `0.1 * 3 === 0.3`, et `10n ** 400n > Number.MAX_VALUE`.

<details>
<summary>Solution</summary>

```text
'2' + 2 * '2'                      '24'
null + 1                           1
undefined + 1                      NaN
[] == ![]                          true
'b' + 'a' + +'a' + 'a'             'baNaNa'
0.1 * 3 === 0.3                    false
10n ** 400n > Number.MAX_VALUE     true
```

- `*` passe en premier et convertit les deux chaînes : `2 * '2'` vaut `4`, puis `'2' + 4` concatène.
- En arithmétique, `null` devient `0` et `undefined` devient `NaN`.
- `![]` vaut `false`, puisqu'un tableau est truthy ; ensuite `[] == false` vaut `true`, comme plus haut.
- `+'a'` vaut `NaN`, et `'ba' + NaN` concatène le texte `NaN`.
- `0.1 * 3` vaut `0.30000000000000004`, comme `0.1 + 0.2`.
- Les comparaisons, contrairement à l'arithmétique, peuvent mélanger un `bigint` et un `number` : 10<sup>400</sup> est plus grand que le plus grand double, environ 1,8 × 10<sup>308</sup>.

</details>

## Sources

- [ECMAScript — Types du langage ECMAScript](https://tc39.es/ecma262/#sec-ecmascript-language-types), [l'opérateur `typeof`](https://tc39.es/ecma262/#sec-typeof-operator), [IsLooselyEqual](https://tc39.es/ecma262/#sec-islooselyequal), [IsStrictlyEqual](https://tc39.es/ecma262/#sec-isstrictlyequal), [ToBoolean](https://tc39.es/ecma262/#sec-toboolean), [ToNumber](https://tc39.es/ecma262/#sec-tonumber), [ApplyStringOrNumericBinaryOperator](https://tc39.es/ecma262/#sec-applystringornumericbinaryoperator)
- [MDN — Types et structures de données JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Data_structures), [Égalité et identité](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Equality_comparisons_and_sameness), [Coercition de type](https://developer.mozilla.org/en-US/docs/Glossary/Type_coercion)
- [Microsoft — Types numériques à virgule flottante](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types), [Java Language Specification — 4.2.3 Floating-point types](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2.3)
