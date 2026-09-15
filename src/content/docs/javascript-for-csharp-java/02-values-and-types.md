---
title: 2. Values and types
description: let and const, the eight types of JavaScript, number as a double and BigInt, strings, undefined and null, == against ===, and the implicit conversions — each compared with C# and Java, with Node.js's real output.
sidebar:
  order: 2
---

Code: the files [`examples/l02_*.js`](https://github.com/spareilleux/learn/tree/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/examples), and the C# and Java sides in [`compare/l02_numbers.cs`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/compare/l02_numbers.cs) and [`compare/L02Numbers.java`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/compare/L02Numbers.java).

The examples of this lesson and the next two print their results with two small helpers from [`examples/show.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/examples/show.js). `show` prints a label, then the value the way Node.js's interactive shell would, with strings in quotes so that `'12'` and `12` look different. `attempt` does the same for a function, and prints the error instead when the function throws.

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

## let, const and var

| | C# | Java | JavaScript |
|---|---|---|---|
| A variable you can reassign | `var count = 1;` | `var count = 1;` | `let count = 1;` |
| A variable you can't reassign | a `readonly` field; no local equivalent | `final var count = 1;` | `const count = 1;` |
| A constant known at compile time | `const int Count = 1;` | `static final int COUNT = 1;` | — |
| The old way | — | — | `var count = 1;`, scoped to the function ([lesson 3](../03-functions-and-scope/#hoisting-and-the-temporal-dead-zone)) |

```js
// examples/l02_let_const.js
import { attempt, show } from './show.js';

let count = 1;
count = 2; // let: the binding can change
show('count', count);

const settings = { theme: 'dark', tabs: ['lessons'] };
settings.theme = 'light'; // const: the binding can't change, the object can
settings.tabs.push('journal');
show('settings', settings);
attempt('settings = {}', () => {
  settings = {};
});

const frozen = Object.freeze({ theme: 'dark', tabs: ['lessons'] });
attempt("frozen.theme = 'light'", () => {
  frozen.theme = 'light'; // a module is strict code: the assignment throws
});
frozen.tabs.push('journal'); // freeze is shallow
show('frozen', frozen);
```

```text
count                              2
settings                           { theme: 'light', tabs: [ 'lessons', 'journal' ] }
settings = {}                      TypeError: Assignment to constant variable.
frozen.theme = 'light'             TypeError: Cannot assign to read only property 'theme' of object '#<Object>'
frozen                             { theme: 'dark', tabs: [ 'lessons', 'journal' ] }
```

`const` is `final` in Java, not `const` in C#: the variable always refers to the same object, and the object stays mutable. [`Object.freeze`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/freeze) makes the properties of one object read-only, and not the objects they point to. The error comes at run time, when the line executes: nothing checks it before. Use `const` by default and `let` when you reassign; `var` is only found in old code.

## Values have types, variables don't

```js
// examples/l02_typeof.js
import { show } from './show.js';

let value = 42;
show('typeof value', typeof value);
value = 'forty-two'; // no error: the variable has no type
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

The specification defines [eight types](https://tc39.es/ecma262/#sec-ecmascript-language-types): seven primitive types, which are Undefined, Null, Boolean, Number, BigInt, String and Symbol, and Object. Arrays, functions, dates and maps are all objects. The [`typeof` operator](https://tc39.es/ecma262/#sec-typeof-operator) almost follows those types, with two exceptions written into the specification: it returns `'object'` for `null`, a mistake of the first implementation kept for compatibility, and `'function'` for objects you can call. To recognize an array, use [`Array.isArray`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/isArray).

In C#, the closest model is a program where every variable is declared `dynamic`. The difference comes when types don't match: C# throws a `RuntimeBinderException`, and JavaScript converts one of the values and carries on. Most of the surprises of this lesson come from those conversions. Static types that catch mistakes before the program runs are what TypeScript adds, in the next course.

## number: always a double

JavaScript has a single number type for integers and fractions: a 64-bit [IEEE 754](https://tc39.es/ecma262/#sec-ecmascript-language-types-number-type) floating-point number, the `double` of C# and Java.

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

// Integers are exact up to 2^53 - 1
show('Number.MAX_SAFE_INTEGER', Number.MAX_SAFE_INTEGER);
show('2 ** 53 + 1', 2 ** 53 + 1);
show('2 ** 53 + 1 === 2 ** 53', 2 ** 53 + 1 === 2 ** 53);
show('9007199254740993', 9007199254740993);
show('Number.isSafeInteger(2 ** 53)', Number.isSafeInteger(2 ** 53));

// Bitwise operators work on 32-bit integers
show('2 ** 31 | 0', 2 ** 31 | 0);
show('(2 ** 32 + 5) | 0', (2 ** 32 + 5) | 0);

// Zero has a sign
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

The same operations in C# and in Java:

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

What JavaScript shares with C# and Java:

- `0.1 + 0.2` is `0.30000000000000004` in all three: it is a property of binary floating point, not of JavaScript. For money, count integer cents, or use a decimal library.
- Dividing a double by zero gives `Infinity`, and `NaN` is different from everything, itself included.
- `%` keeps the sign of the dividend: `-7 % 2` is `-1` in all three.

What differs:

- **There is no integer division.** `7 / 2` is `3.5`. [`Math.trunc`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/trunc) rounds toward zero like the integer division of C# and Java; `Math.floor` rounds down, which differs for negative numbers.
- **There is no integer overflow, and no exception for dividing by zero.** Integers are exact up to 2 to the power of 53, minus 1, which is `Number.MAX_SAFE_INTEGER`; above that, the double rounds silently. The literal `9007199254740993` is already `9007199254740992` when the program starts. A C# `long` identifier sent in JSON can lose its last digits when a JavaScript client parses it, which is why some APIs send large identifiers as strings.
- **Bitwise operators convert to 32-bit integers** ([ToInt32](https://tc39.es/ecma262/#sec-toint32)): `2 ** 31 | 0` wraps to `-2147483648`, and `x | 0`, an old idiom to truncate a number, breaks above two billion.
- **The global `isNaN` converts its argument first**, so `isNaN('abc')` is `true`. [`Number.isNaN`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isNaN) doesn't convert, and is the one to use.
- **Zero has a sign that `===` ignores.** [`Object.is`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is) sees the difference between `-0` and `0`, and says that `NaN` is `NaN`.

## bigint: integers of any size

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

A [`BigInt`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt) is an integer of any size, written with an `n` suffix, like [`System.Numerics.BigInteger`](https://learn.microsoft.com/dotnet/api/system.numerics.biginteger) and [`java.math.BigInteger`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/math/BigInteger.html), with operators instead of methods. Its division truncates, like integer division in C#. Here JavaScript is *stricter* than C#: C# converts an `int` to a `BigInteger` implicitly, while JavaScript refuses to mix the two types in arithmetic and asks for an explicit `BigInt(…)` or `Number(…)`. `JSON.stringify` and `Math` don't accept BigInts either.

## string: UTF-16, immutable

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

Strings work as in C# and Java: immutable sequences of [UTF-16 code units](https://tc39.es/ecma262/#sec-ecmascript-language-types-string-type), where `length` counts code units and an emoji outside the Basic Multilingual Plane takes two. The C# and Java programs above print `2` for the same guitar. There is no separate `char` type: `course[4]` is a string of length one. Spreading a string with `...` iterates over code points, which is how to count the guitar as one. `===` compares code units, so the two spellings of `é` differ until [`normalize`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/normalize) makes them equal, and `<` compares code units too, so uppercase letters sort before lowercase ones and `'10'` sorts before `'9'`. Lesson 11 compares strings the way people read them, with `Intl.Collator`.

## undefined and null

C# and Java have one absent value, `null`. JavaScript has two.

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

// || replaces every falsy value, ?? only null and undefined
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

The language produces `undefined` by itself: for a variable without a value, a property that doesn't exist, a missing argument, and a function that returns nothing. `null` appears only when code writes it. Reading a missing property is not an error, it gives `undefined`; the error comes one step later, when you read a property *of* `undefined`, and that `TypeError` is the `NullReferenceException` of JavaScript. `JSON.stringify` keeps `null` and drops the properties that are `undefined`.

The operators `?.` and `??` work as in C#. The trap is the older logical or, `||`, which you will find everywhere: it returns its right side for *every* falsy value, `0` and the empty string included, while `??` does so only for `null` and `undefined`. `page.order || 99` turns the order `0` into `99`.

### In GuitarAlchemist/ga

[`BSPDoomExplorer.tsx`, line 4895](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L4895) reads the rotation speed of a 3D sample with `obj.userData.rotationSpeed || 0.5`, and [line 5386](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L5386) computes the time between two frames. Reduced to plain JavaScript:

```js
// examples/l02_ga_defaults.js

// Line 4895: the rotation speed of a sample, 0.5 when missing
function speedWithOr(userData) {
  return userData.rotationSpeed || 0.5;
}
function speedWithNullish(userData) {
  return userData.rotationSpeed ?? 0.5;
}
for (const userData of [{}, { rotationSpeed: 0.3 }, { rotationSpeed: 0 }]) {
  console.log(JSON.stringify(userData).padEnd(22), '||', speedWithOr(userData), ' ??', speedWithNullish(userData));
}

// Line 5386: the time since the previous frame, stored as a property of the function itself
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

Today, every sample gets a random speed between 0.3 and 0.7 ([line 3039](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L3039)), so the `||` never meets a zero. The same file stops other objects by setting `rotationSpeed = 0` ([line 5556](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L5556)): the day a sample is stopped that way, `|| 0.5` will make it turn again. `??` says what the line means.

The second line works, but not for the reason it seems. Subtraction binds tighter than `||`, so it reads `(now - updateFPS.lastTime) || 0`, not `now - (updateFPS.lastTime || 0)`. On the first frame, `lastTime` is `undefined`, the subtraction gives `NaN`, `NaN` is falsy, and the `|| 0` turns it into `0`, which the code then skips with `if (delta > 0)`.

## == and ===

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

// The one common use of ==: null or undefined in a single test
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

In C# and Java, comparing a string with a number doesn't compile. In JavaScript, `===` ([IsStrictlyEqual](https://tc39.es/ecma262/#sec-isstrictlyequal)) answers `false` when the types differ, and `==` ([IsLooselyEqual](https://tc39.es/ecma262/#sec-islooselyequal)) converts first, following a few rules:

1. Two values of the same type are compared as `===` would.
2. `null` and `undefined` are equal to each other, and to nothing else.
3. A string compared with a number becomes a number.
4. A boolean becomes a number first: `true` is `1`, `false` is `0`.
5. An object compared with a primitive is converted to a primitive, usually through its `toString` method: an empty array becomes the empty string, `[0]` becomes the string `'0'`, and `[1, 2]` becomes `'1,2'`.

`[] == false` applies rules 4, 5 and 3 in turn: `false` becomes the number zero, the empty array becomes the empty string, and the empty string becomes zero. The empty string and the string `'0'` are both loosely equal to the number zero, yet not to each other: loose equality isn't even transitive. And `null >= 0` is true while `null == 0` is false, because the relational operators convert `null` to `0` and `==` has its own rule for `null`.

Use the strict operators, `===` and `!==`, everywhere. The one idiom worth keeping is `value == null`, true for `null` and `undefined` only, which GA uses in [`DynamicPanel.tsx`, line 36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/DynamicPanel.tsx#L36). ESLint's [`eqeqeq`](https://eslint.org/docs/latest/rules/eqeqeq) rule enforces the rule and has an option to allow that idiom; it is not part of `js.configs.recommended`, the base of GA's [ESLint configuration](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/eslint.config.js#L10).

## Conversions: +, -, parsing and truthiness

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

// Parsing: Number reads the whole string, parseInt stops at the first invalid character
show("Number('')", Number(''));
show("Number(' 12 ')", Number(' 12 '));
show("Number('12px')", Number('12px'));
show("parseInt('12px', 10)", parseInt('12px', 10));
show("parseInt('', 10)", parseInt('', 10));
show("parseInt('0x1F')", parseInt('0x1F'));
show("parseInt('1e3', 10)", parseInt('1e3', 10));
show("Number('1e3')", Number('1e3'));
show('parseInt(0.0000005)', parseInt(0.0000005));

// Truthy and falsy: if converts any value to a boolean
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

`+` is the operator that surprises, because it has [two meanings](https://tc39.es/ecma262/#sec-applystringornumericbinaryoperator): if either operand is a string after conversion to a primitive, it concatenates; otherwise it adds. C# and Java concatenate `"1" + 2` into `"12"` too, as their outputs above show; the difference is that JavaScript also converts objects, an empty array to the empty string and an empty object to the text `[object Object]`, and evaluates from left to right, so `1 + 2 + '3'` is `'33'`. The other arithmetic operators, `-`, `*` and `/`, have only one meaning and convert both sides to numbers, and so does the unary `+`.

To turn text into a number on purpose:

- [`Number(text)`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/Number) reads the whole string, ignores surrounding spaces, accepts `1e3` and `0x1F`, and returns `NaN` if anything else is left. Its one trap: the empty string gives `0`.
- [`parseInt(text, 10)`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt) reads digits until the first character it can't use, so `'12px'` gives `12`. Always pass the radix: without it, a `0x` prefix switches to hexadecimal. Its argument is a string: `parseInt(0.0000005)` converts the number to `'5e-7'` first, and reads `5`.
- Neither throws. C#'s `int.Parse` and Java's `Integer.parseInt` reject `'12px'` with an exception; in JavaScript, check the result with `Number.isNaN` or `Number.isInteger`.

An `if`, `!`, `&&` and `||` accept any value and convert it with [ToBoolean](https://tc39.es/ecma262/#sec-toboolean). Eight values are *falsy*: `false`, `0`, `-0`, `0n`, the empty string, `null`, `undefined` and `NaN`. Everything else is *truthy*, including the string `'0'`, the string `'false'` and an empty array. C# and Java require a boolean in a condition, so `if (items.length)` has no equivalent there, and `if (count)` is false when the count is zero.

## Key takeaways

- `const` fixes the variable, not the object; `Object.freeze` fixes one level of an object.
- Values have types, variables don't: `typeof` tells you the type, with `'object'` for `null` and arrays.
- `number` is a `double`: no integer division, no overflow, exact integers only up to 2 to the power of 53, minus 1. `bigint` covers larger integers and refuses to mix with `number`.
- Strings are UTF-16 and immutable, as in C# and Java.
- `undefined` means "never set", `null` means "set to nothing"; `??` replaces both, `||` replaces every falsy value, `0` and `''` included.
- Use `===`. `== null` is the only loose comparison worth writing.
- `+` concatenates as soon as a string is involved; `Number` and `parseInt(text, 10)` parse, and neither throws.

## Exercises

1. Write `isBlank(value)`, true for `null`, `undefined` and strings made only of whitespace, and false for everything else, including `0`, `false` and `NaN`.

<details>
<summary>Solution</summary>

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

`!value` would be shorter and wrong: it is true for `0`, `false` and `NaN`. `value == null` covers `null` and `undefined` in one test, and the `typeof` check keeps `trim` away from values that aren't strings.

</details>

2. Write `parsePort(text)`, which returns a port number between 1 and 65535 from a string of digits, and throws a `TypeError` or a `RangeError` otherwise, as `int.Parse` or `Integer.parseInt` would. Try it with `'8080'`, `''`, `' 80'`, `'8080abc'`, `'0x50'`, `'1e3'`, `'70000'` and the number `8080`.

<details>
<summary>Solution</summary>

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

The regular expression does the work neither built-in function does: `Number` alone would accept `''` as `0`, `' 80'`, `'0x50'` and `'1e3'`, and `parseInt` would accept `'8080abc'`. Once the string is only digits, `Number` is safe. Lesson 11 covers regular expressions.

</details>

3. Predict each result, then run [`solutions/l02_ex3_predict.js`](https://github.com/spareilleux/learn/blob/c65efe4fb76e61efd229793b296d3d7a44e71baf/code/javascript-for-csharp-java/solutions/l02_ex3_predict.js): `'2' + 2 * '2'`, `null + 1`, `undefined + 1`, `[] == ![]`, `'b' + 'a' + +'a' + 'a'`, `0.1 * 3 === 0.3`, and `10n ** 400n > Number.MAX_VALUE`.

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

- `*` comes first and converts both strings: `2 * '2'` is `4`, then `'2' + 4` concatenates.
- In arithmetic, `null` becomes `0` and `undefined` becomes `NaN`.
- `![]` is `false`, since an array is truthy; then `[] == false` is `true`, as above.
- `+'a'` is `NaN`, and `'ba' + NaN` concatenates the text `NaN`.
- `0.1 * 3` is `0.30000000000000004`, like `0.1 + 0.2`.
- Comparisons, unlike arithmetic, may mix a `bigint` and a `number`: 10<sup>400</sup> is larger than the largest double, about 1.8 × 10<sup>308</sup>.

</details>

## Sources

- [ECMAScript — ECMAScript language types](https://tc39.es/ecma262/#sec-ecmascript-language-types), [the `typeof` operator](https://tc39.es/ecma262/#sec-typeof-operator), [IsLooselyEqual](https://tc39.es/ecma262/#sec-islooselyequal), [IsStrictlyEqual](https://tc39.es/ecma262/#sec-isstrictlyequal), [ToBoolean](https://tc39.es/ecma262/#sec-toboolean), [ToNumber](https://tc39.es/ecma262/#sec-tonumber), [ApplyStringOrNumericBinaryOperator](https://tc39.es/ecma262/#sec-applystringornumericbinaryoperator)
- [MDN — JavaScript data types and data structures](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Data_structures), [Equality comparisons and sameness](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Equality_comparisons_and_sameness), [Type coercion](https://developer.mozilla.org/en-US/docs/Glossary/Type_coercion)
- [Microsoft — Floating-point numeric types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types), [Java Language Specification — 4.2.3 Floating-point types](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2.3)
