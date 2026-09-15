// l01-emit/src/money.ts
export type Currency = 'CAD' | 'EUR';

export interface Money {
  readonly cents: number;
  readonly currency: Currency;
}

export function add(a: Money, b: Money): Money {
  if (a.currency !== b.currency) throw new Error(`${a.currency} + ${b.currency}`);
  return { cents: a.cents + b.cents, currency: a.currency };
}

export function formatMoney(money: Money): string {
  return `${(money.cents / 100).toFixed(2)} ${money.currency}`;
}
