// Lesson 2: number is a 64-bit IEEE 754 double, like double in C# and Java
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
