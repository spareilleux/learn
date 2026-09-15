// errors/l01_not_erasable.ts
class Price {
  constructor(private readonly cents: number) {} // a parameter property declares and assigns a field
  toString() {
    return (this.cents / 100).toFixed(2);
  }
}

namespace Tax {
  export const rate = 0.15;
}

const price = <Price>new Price(999); // the old cast syntax
console.log(`${price}`, Tax.rate);
