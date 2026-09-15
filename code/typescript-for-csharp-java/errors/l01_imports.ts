// errors/l01_imports.ts
import { formatMoney, Money } from '../examples/l01_money';

const price: Money = { cents: 999, currency: 'CAD' };
console.log(formatMoney(price));
