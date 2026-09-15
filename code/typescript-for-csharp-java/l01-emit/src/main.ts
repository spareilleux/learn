// l01-emit/src/main.ts
import { add, formatMoney, type Money } from './money.ts';

const capo: Money = { cents: 999, currency: 'CAD' };
const strings = { cents: 1250, currency: 'CAD' } satisfies Money;
const shipping: Money = { cents: '500', currency: 'CAD' }; // a type error: tsc reports it, and writes the files anyway

console.log(formatMoney(add(add(capo, strings), shipping)));
