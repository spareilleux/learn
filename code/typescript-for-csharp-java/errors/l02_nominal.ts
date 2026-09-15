// errors/l02_nominal.ts
// A #private field makes a class nominal: no other class, however similar, has that field
class Celsius {
  #value: number;
  constructor(value: number) {
    this.#value = value;
  }
  get value() {
    return this.#value;
  }
}
class Fahrenheit {
  #value: number;
  constructor(value: number) {
    this.#value = value;
  }
  get value() {
    return this.#value;
  }
}

type Kelvin = number & { readonly brand: 'Kelvin' };

const water: Celsius = new Fahrenheit(212);
const room: Kelvin = 293.15;
console.log(water.value, room);
