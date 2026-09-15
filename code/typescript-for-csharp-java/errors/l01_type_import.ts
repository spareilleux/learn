// errors/l01_type_import.ts
import { formatMoney, Money } from '../examples/l01_money.ts';

const price: Money = { cents: 999, currency: 'CAD' };
console.log(formatMoney(price));
