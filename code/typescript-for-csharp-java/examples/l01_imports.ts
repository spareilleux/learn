// examples/l01_imports.ts
import { formatMoney, type Money } from './l01_money.ts';

const price: Money = { cents: 999, currency: 'CAD' };
console.log(formatMoney(price));
