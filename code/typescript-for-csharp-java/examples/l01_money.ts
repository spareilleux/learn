// examples/l01_money.ts
export type Currency = 'CAD' | 'EUR';

export interface Money {
  cents: number;
  currency: Currency;
}

export function formatMoney(money: Money): string {
  return `${(money.cents / 100).toFixed(2)} ${money.currency}`;
}
