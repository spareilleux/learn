---
title: 2. Valores y tipos
description: let y const, los ocho tipos de JavaScript, number como double y BigInt, las cadenas, undefined y null, == frente a ===, y las conversiones implícitas — cada uno comparado con C# y Java, con la salida real de Node.js.
sidebar:
  order: 2
---

Código: los archivos [`examples/l02_*.js`](https://github.com/spareilleux/learn/tree/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/examples), y los equivalentes en C# y Java en [`compare/l02_numbers.cs`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/compare/l02_numbers.cs) y [`compare/L02Numbers.java`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/compare/L02Numbers.java).

Los ejemplos de esta lección y de las dos siguientes imprimen sus resultados con dos pequeñas funciones auxiliares de [`examples/show.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/examples/show.js). `show` imprime una etiqueta, y luego el valor tal como lo mostraría la shell interactiva de Node.js, con las cadenas entre comillas para que `'12'` y `12` se vean distintos. `attempt` hace lo mismo con una función, e imprime el error en su lugar cuando la función lanza una excepción.

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

## let, const y var

| | C# | Java | JavaScript |
|---|---|---|---|
| Una variable que puedes reasignar | `var count = 1;` | `var count = 1;` | `let count = 1;` |
| Una variable que no puedes reasignar | un campo `readonly`; sin equivalente local | `final var count = 1;` | `const count = 1;` |
| Una constante conocida en tiempo de compilación | `const int Count = 1;` | `static final int COUNT = 1;` | — |
| La forma antigua | — | — | `var count = 1;`, con ámbito de función ([lección 3](../03-functions-and-scope/#hoisting-y-la-zona-muerta-temporal)) |

```js
// examples/l02_let_const.js
import { attempt, show } from './show.js';

let count = 1;
count = 2; // let: el enlace puede cambiar
show('count', count);

const settings = { theme: 'dark', tabs: ['lessons'] };
settings.theme = 'light'; // const: el enlace no puede cambiar, el objeto sí
settings.tabs.push('journal');
show('settings', settings);
attempt('settings = {}', () => {
  settings = {};
});

const frozen = Object.freeze({ theme: 'dark', tabs: ['lessons'] });
attempt("frozen.theme = 'light'", () => {
  frozen.theme = 'light'; // un módulo es código estricto: la asignación lanza una excepción
});
frozen.tabs.push('journal'); // freeze es superficial
show('frozen', frozen);
```

```text
count                              2
settings                           { theme: 'light', tabs: [ 'lessons', 'journal' ] }
settings = {}                      TypeError: Assignment to constant variable.
frozen.theme = 'light'             TypeError: Cannot assign to read only property 'theme' of object '#<Object>'
frozen                             { theme: 'dark', tabs: [ 'lessons', 'journal' ] }
```

`const` es el `final` de Java, no el `const` de C#: la variable siempre se refiere al mismo objeto, y el objeto sigue siendo mutable. [`Object.freeze`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/freeze) hace de solo lectura las propiedades de un objeto, pero no los objetos a los que apuntan. El error llega en tiempo de ejecución, cuando se ejecuta la línea: nada lo comprueba antes. Usa `const` por defecto y `let` cuando reasignes; `var` solo se encuentra en código antiguo.

## Los valores tienen tipos, las variables no

```js
// examples/l02_typeof.js
import { show } from './show.js';

let value = 42;
show('typeof value', typeof value);
value = 'forty-two'; // sin error: la variable no tiene tipo
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

La especificación define [ocho tipos](https://tc39.es/ecma262/#sec-ecmascript-language-types): siete tipos primitivos, que son Undefined, Null, Boolean, Number, BigInt, String y Symbol, y Object. Los arrays, las funciones, las fechas y los maps son todos objetos. El [operador `typeof`](https://tc39.es/ecma262/#sec-typeof-operator) sigue casi esos tipos, con dos excepciones escritas en la especificación: devuelve `'object'` para `null`, un error de la primera implementación que se mantuvo por compatibilidad, y `'function'` para los objetos que se pueden llamar. Para reconocer un array, usa [`Array.isArray`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/isArray).

En C#, el modelo más cercano es un programa donde cada variable se declara `dynamic`. La diferencia aparece cuando los tipos no coinciden: C# lanza una `RuntimeBinderException`, y JavaScript convierte uno de los valores y sigue adelante. La mayoría de las sorpresas de esta lección vienen de esas conversiones. Los tipos estáticos que detectan los errores antes de que se ejecute el programa son lo que añade TypeScript, en el próximo curso.

## number: siempre un double

JavaScript tiene un único tipo numérico para los enteros y los decimales: un número de coma flotante [IEEE 754](https://tc39.es/ecma262/#sec-ecmascript-language-types-number-type) de 64 bits, el `double` de C# y Java.

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

// Los enteros son exactos hasta 2^53 - 1
show('Number.MAX_SAFE_INTEGER', Number.MAX_SAFE_INTEGER);
show('2 ** 53 + 1', 2 ** 53 + 1);
show('2 ** 53 + 1 === 2 ** 53', 2 ** 53 + 1 === 2 ** 53);
show('9007199254740993', 9007199254740993);
show('Number.isSafeInteger(2 ** 53)', Number.isSafeInteger(2 ** 53));

// Los operadores bit a bit trabajan con enteros de 32 bits
show('2 ** 31 | 0', 2 ** 31 | 0);
show('(2 ** 32 + 5) | 0', (2 ** 32 + 5) | 0);

// El cero tiene signo
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

Las mismas operaciones en C# y en Java:

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

Lo que JavaScript comparte con C# y Java:

- `0.1 + 0.2` vale `0.30000000000000004` en los tres: es una propiedad de la coma flotante binaria, no de JavaScript. Para el dinero, cuenta céntimos enteros, o usa una biblioteca decimal.
- Dividir un double entre cero da `Infinity`, y `NaN` es distinto de todo, incluido él mismo.
- `%` conserva el signo del dividendo: `-7 % 2` vale `-1` en los tres.

Lo que difiere:

- **No hay división entera.** `7 / 2` vale `3.5`. [`Math.trunc`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/trunc) redondea hacia cero como la división entera de C# y Java; `Math.floor` redondea hacia abajo, lo que difiere para los números negativos.
- **No hay desbordamiento de enteros, ni excepción al dividir entre cero.** Los enteros son exactos hasta 2 elevado a 53, menos 1, que es `Number.MAX_SAFE_INTEGER`; por encima, el double redondea en silencio. El literal `9007199254740993` ya vale `9007199254740992` cuando arranca el programa. Un identificador `long` de C# enviado en JSON puede perder sus últimas cifras cuando un cliente JavaScript lo analiza, y por eso algunas API envían los identificadores grandes como cadenas.
- **Los operadores bit a bit convierten a enteros de 32 bits** ([ToInt32](https://tc39.es/ecma262/#sec-toint32)): `2 ** 31 | 0` da la vuelta a `-2147483648`, y `x | 0`, un viejo truco para truncar un número, falla por encima de dos mil millones.
- **La función global `isNaN` convierte primero su argumento**, así que `isNaN('abc')` vale `true`. [`Number.isNaN`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isNaN) no convierte, y es la que hay que usar.
- **El cero tiene un signo que `===` ignora.** [`Object.is`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is) ve la diferencia entre `-0` y `0`, y dice que `NaN` es `NaN`.

## bigint: enteros de cualquier tamaño

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

Un [`BigInt`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt) es un entero de cualquier tamaño, escrito con un sufijo `n`, como [`System.Numerics.BigInteger`](https://learn.microsoft.com/dotnet/api/system.numerics.biginteger) y [`java.math.BigInteger`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigInteger.html), con operadores en lugar de métodos. Su división trunca, como la división entera en C#. Aquí JavaScript es *más estricto* que C#: C# convierte un `int` en `BigInteger` implícitamente, mientras que JavaScript se niega a mezclar los dos tipos en la aritmética y pide un `BigInt(…)` o un `Number(…)` explícito. `JSON.stringify` y `Math` tampoco aceptan los BigInt.

## string: UTF-16, inmutable

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

Las cadenas funcionan como en C# y Java: secuencias inmutables de [unidades de código UTF-16](https://tc39.es/ecma262/#sec-ecmascript-language-types-string-type), donde `length` cuenta unidades de código y un emoji fuera del plano multilingüe básico ocupa dos. Los programas C# y Java de arriba imprimen `2` para la misma guitarra. No hay un tipo `char` separado: `course[4]` es una cadena de longitud uno. Expandir una cadena con `...` recorre los puntos de código, y así se cuenta la guitarra como uno. `===` compara unidades de código, así que las dos grafías de `é` difieren hasta que [`normalize`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/normalize) las iguala, y `<` también compara unidades de código, así que las mayúsculas se ordenan antes que las minúsculas y `'10'` se ordena antes que `'9'`. La lección 11 compara las cadenas como las lee la gente, con `Intl.Collator`.

## undefined y null

C# y Java tienen un valor ausente, `null`. JavaScript tiene dos.

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

// || sustituye todo valor falsy, ?? solo null y undefined
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

El lenguaje produce `undefined` por sí mismo: para una variable sin valor, una propiedad que no existe, un argumento que falta y una función que no devuelve nada. `null` solo aparece cuando el código lo escribe. Leer una propiedad que no existe no es un error, da `undefined`; el error llega un paso después, cuando lees una propiedad *de* `undefined`, y ese `TypeError` es la `NullReferenceException` de JavaScript. `JSON.stringify` conserva `null` y descarta las propiedades que valen `undefined`.

Los operadores `?.` y `??` funcionan como en C#. La trampa es el o lógico más antiguo, `||`, que encontrarás por todas partes: devuelve su lado derecho para *todo* valor falsy, incluidos `0` y la cadena vacía, mientras que `??` solo lo hace para `null` y `undefined`. `page.order || 99` convierte el orden `0` en `99`.

### En GuitarAlchemist/ga

[`BSPDoomExplorer.tsx`, línea 4895](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L4895) lee la velocidad de rotación de una muestra 3D con `obj.userData.rotationSpeed || 0.5`, y la [línea 5386](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L5386) calcula el tiempo entre dos fotogramas. Reducido a JavaScript puro:

```js
// examples/l02_ga_defaults.js

// Línea 4895: la velocidad de rotación de una muestra, 0.5 si falta
function speedWithOr(userData) {
  return userData.rotationSpeed || 0.5;
}
function speedWithNullish(userData) {
  return userData.rotationSpeed ?? 0.5;
}
for (const userData of [{}, { rotationSpeed: 0.3 }, { rotationSpeed: 0 }]) {
  console.log(JSON.stringify(userData).padEnd(22), '||', speedWithOr(userData), ' ??', speedWithNullish(userData));
}

// Línea 5386: el tiempo desde el fotograma anterior, guardado como propiedad de la propia función
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

Hoy, cada muestra recibe una velocidad aleatoria entre 0.3 y 0.7 ([línea 3039](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L3039)), así que el `||` nunca se encuentra con un cero. El mismo archivo detiene otros objetos poniendo `rotationSpeed = 0` ([línea 5556](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L5556)): el día en que se detenga una muestra de esa manera, `|| 0.5` la hará girar de nuevo. `??` dice lo que la línea quiere decir.

La segunda línea funciona, pero no por la razón que parece. La resta tiene más precedencia que `||`, así que se lee `(now - updateFPS.lastTime) || 0`, no `now - (updateFPS.lastTime || 0)`. En el primer fotograma, `lastTime` vale `undefined`, la resta da `NaN`, `NaN` es falsy, y el `|| 0` lo convierte en `0`, que el código luego omite con `if (delta > 0)`.

## == y ===

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

// El único uso habitual de ==: null o undefined en una sola prueba
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

En C# y Java, comparar una cadena con un número no compila. En JavaScript, `===` ([IsStrictlyEqual](https://tc39.es/ecma262/#sec-isstrictlyequal)) responde `false` cuando los tipos difieren, y `==` ([IsLooselyEqual](https://tc39.es/ecma262/#sec-islooselyequal)) convierte primero, siguiendo unas pocas reglas:

1. Dos valores del mismo tipo se comparan como lo haría `===`.
2. `null` y `undefined` son iguales entre sí, y a nada más.
3. Una cadena comparada con un número se convierte en número.
4. Un booleano se convierte primero en número: `true` es `1`, `false` es `0`.
5. Un objeto comparado con un primitivo se convierte en primitivo, normalmente mediante su método `toString`: un array vacío se convierte en la cadena vacía, `[0]` se convierte en la cadena `'0'`, y `[1, 2]` se convierte en `'1,2'`.

`[] == false` aplica las reglas 4, 5 y 3 una tras otra: `false` se convierte en el número cero, el array vacío se convierte en la cadena vacía, y la cadena vacía se convierte en cero. La cadena vacía y la cadena `'0'` son ambas débilmente iguales al número cero, y sin embargo no lo son entre sí: la igualdad débil ni siquiera es transitiva. Y `null >= 0` es verdadero mientras que `null == 0` es falso, porque los operadores relacionales convierten `null` en `0` y `==` tiene su propia regla para `null`.

Usa los operadores estrictos, `===` y `!==`, en todas partes. La única expresión idiomática que vale la pena conservar es `value == null`, verdadera solo para `null` y `undefined`, que GA usa en [`DynamicPanel.tsx`, línea 36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/DynamicPanel.tsx#L36). La regla [`eqeqeq`](https://eslint.org/docs/latest/rules/eqeqeq) de ESLint impone la norma y tiene una opción para permitir esa expresión; no forma parte de `js.configs.recommended`, la base de la [configuración de ESLint](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/eslint.config.js#L10) de GA.

## Conversiones: +, -, análisis de texto y valores truthy

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

// Análisis: Number lee toda la cadena, parseInt se detiene en el primer carácter no válido
show("Number('')", Number(''));
show("Number(' 12 ')", Number(' 12 '));
show("Number('12px')", Number('12px'));
show("parseInt('12px', 10)", parseInt('12px', 10));
show("parseInt('', 10)", parseInt('', 10));
show("parseInt('0x1F')", parseInt('0x1F'));
show("parseInt('1e3', 10)", parseInt('1e3', 10));
show("Number('1e3')", Number('1e3'));
show('parseInt(0.0000005)', parseInt(0.0000005));

// Truthy y falsy: if convierte cualquier valor en booleano
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

`+` es el operador que sorprende, porque tiene [dos significados](https://tc39.es/ecma262/#sec-applystringornumericbinaryoperator): si alguno de los operandos es una cadena tras convertirlo en primitivo, concatena; si no, suma. C# y Java también concatenan `"1" + 2` en `"12"`, como muestran sus salidas de arriba; la diferencia es que JavaScript también convierte los objetos, un array vacío en la cadena vacía y un objeto vacío en el texto `[object Object]`, y evalúa de izquierda a derecha, así que `1 + 2 + '3'` vale `'33'`. Los demás operadores aritméticos, `-`, `*` y `/`, solo tienen un significado y convierten ambos lados en números, igual que el `+` unario.

Para convertir texto en número a propósito:

- [`Number(text)`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/Number) lee toda la cadena, ignora los espacios de alrededor, acepta `1e3` y `0x1F`, y devuelve `NaN` si queda cualquier otra cosa. Su única trampa: la cadena vacía da `0`.
- [`parseInt(text, 10)`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt) lee cifras hasta el primer carácter que no puede usar, así que `'12px'` da `12`. Pasa siempre la base: sin ella, un prefijo `0x` cambia a hexadecimal. Su argumento es una cadena: `parseInt(0.0000005)` convierte primero el número en `'5e-7'`, y lee `5`.
- Ninguno de los dos lanza excepciones. `int.Parse` de C# e `Integer.parseInt` de Java rechazan `'12px'` con una excepción; en JavaScript, comprueba el resultado con `Number.isNaN` o `Number.isInteger`.

Un `if`, `!`, `&&` y `||` aceptan cualquier valor y lo convierten con [ToBoolean](https://tc39.es/ecma262/#sec-toboolean). Ocho valores son *falsy*: `false`, `0`, `-0`, `0n`, la cadena vacía, `null`, `undefined` y `NaN`. Todo lo demás es *truthy*, incluidas la cadena `'0'`, la cadena `'false'` y un array vacío. C# y Java exigen un booleano en una condición, así que `if (items.length)` no tiene equivalente allí, e `if (count)` es falso cuando la cuenta vale cero.

## Puntos clave

- `const` fija la variable, no el objeto; `Object.freeze` fija un nivel de un objeto.
- Los valores tienen tipos, las variables no: `typeof` te dice el tipo, con `'object'` para `null` y los arrays.
- `number` es un `double`: sin división entera, sin desbordamiento, con enteros exactos solo hasta 2 elevado a 53, menos 1. `bigint` cubre los enteros más grandes y se niega a mezclarse con `number`.
- Las cadenas son UTF-16 e inmutables, como en C# y Java.
- `undefined` significa "nunca asignado", `null` significa "asignado a nada"; `??` sustituye a ambos, `||` sustituye todo valor falsy, incluidos `0` y `''`.
- Usa `===`. `== null` es la única comparación débil que vale la pena escribir.
- `+` concatena en cuanto interviene una cadena; `Number` y `parseInt(text, 10)` analizan texto, y ninguno de los dos lanza excepciones.

## Ejercicios

1. Escribe `isBlank(value)`, verdadera para `null`, `undefined` y las cadenas formadas solo por espacios en blanco, y falsa para todo lo demás, incluidos `0`, `false` y `NaN`.

<details>
<summary>Solución</summary>

[`solutions/l02_ex1_is_blank.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/solutions/l02_ex1_is_blank.js):

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

`!value` sería más corto e incorrecto: es verdadero para `0`, `false` y `NaN`. `value == null` cubre `null` y `undefined` en una sola prueba, y la comprobación con `typeof` evita llamar a `trim` sobre valores que no son cadenas.

</details>

2. Escribe `parsePort(text)`, que devuelve un número de puerto entre 1 y 65535 a partir de una cadena de cifras, y lanza un `TypeError` o un `RangeError` en caso contrario, como harían `int.Parse` o `Integer.parseInt`. Pruébala con `'8080'`, `''`, `' 80'`, `'8080abc'`, `'0x50'`, `'1e3'`, `'70000'` y el número `8080`.

<details>
<summary>Solución</summary>

[`solutions/l02_ex2_parse_port.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/solutions/l02_ex2_parse_port.js):

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

La expresión regular hace el trabajo que no hace ninguna de las funciones integradas: `Number` sola aceptaría `''` como `0`, `' 80'`, `'0x50'` y `'1e3'`, y `parseInt` aceptaría `'8080abc'`. Una vez que la cadena solo contiene cifras, `Number` es segura. La lección 11 trata las expresiones regulares.

</details>

3. Predice cada resultado, y luego ejecuta [`solutions/l02_ex3_predict.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/solutions/l02_ex3_predict.js): `'2' + 2 * '2'`, `null + 1`, `undefined + 1`, `[] == ![]`, `'b' + 'a' + +'a' + 'a'`, `0.1 * 3 === 0.3`, y `10n ** 400n > Number.MAX_VALUE`.

<details>
<summary>Solución</summary>

```text
'2' + 2 * '2'                      '24'
null + 1                           1
undefined + 1                      NaN
[] == ![]                          true
'b' + 'a' + +'a' + 'a'             'baNaNa'
0.1 * 3 === 0.3                    false
10n ** 400n > Number.MAX_VALUE     true
```

- `*` va primero y convierte ambas cadenas: `2 * '2'` vale `4`, y luego `'2' + 4` concatena.
- En aritmética, `null` se convierte en `0` y `undefined` en `NaN`.
- `![]` vale `false`, ya que un array es truthy; luego `[] == false` vale `true`, como arriba.
- `+'a'` vale `NaN`, y `'ba' + NaN` concatena el texto `NaN`.
- `0.1 * 3` vale `0.30000000000000004`, como `0.1 + 0.2`.
- Las comparaciones, a diferencia de la aritmética, pueden mezclar un `bigint` y un `number`: 10<sup>400</sup> es mayor que el mayor double, de unos 1.8 × 10<sup>308</sup>.

</details>

## Fuentes

- [ECMAScript — tipos del lenguaje ECMAScript](https://tc39.es/ecma262/#sec-ecmascript-language-types), [el operador `typeof`](https://tc39.es/ecma262/#sec-typeof-operator), [IsLooselyEqual](https://tc39.es/ecma262/#sec-islooselyequal), [IsStrictlyEqual](https://tc39.es/ecma262/#sec-isstrictlyequal), [ToBoolean](https://tc39.es/ecma262/#sec-toboolean), [ToNumber](https://tc39.es/ecma262/#sec-tonumber), [ApplyStringOrNumericBinaryOperator](https://tc39.es/ecma262/#sec-applystringornumericbinaryoperator)
- [MDN — tipos y estructuras de datos de JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Data_structures), [comparaciones de igualdad e identidad](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Equality_comparisons_and_sameness), [coerción de tipos](https://developer.mozilla.org/en-US/docs/Glossary/Type_coercion)
- [Microsoft — tipos numéricos de coma flotante](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types), [Java Language Specification — 4.2.3 Floating-point types](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2.3)
