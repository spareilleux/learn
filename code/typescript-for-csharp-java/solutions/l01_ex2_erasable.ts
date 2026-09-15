// solutions/l01_ex2_erasable.ts
// An enum becomes an object marked as const, and a union type of its values
const Currency = { CAD: 'CAD', EUR: 'EUR' } as const;
type Currency = (typeof Currency)[keyof typeof Currency];

// A parameter property becomes a field and an assignment
class Price {
  readonly #cents: number;
  readonly currency: Currency;
  constructor(cents: number, currency: Currency) {
    this.#cents = cents;
    this.currency = currency;
  }
  toString() {
    return `${(this.#cents / 100).toFixed(2)} ${this.currency}`;
  }
}

// A namespace becomes a module, or here a frozen object
const Tax = Object.freeze({ rate: 0.15 });

const price = new Price(999, Currency.EUR); // no assertion needed: new Price already has the type Price
console.log(`${price}`, Tax.rate, Object.values(Currency));
