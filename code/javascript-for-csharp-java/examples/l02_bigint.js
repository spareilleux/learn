// Lesson 2: BigInt, integers of any size, like BigInteger in .NET and Java
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
