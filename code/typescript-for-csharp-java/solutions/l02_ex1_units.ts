// solutions/l02_ex1_units.ts
type Celsius = number & { readonly unit: 'Celsius' };
type Fahrenheit = number & { readonly unit: 'Fahrenheit' };

function celsius(value: number): Celsius {
  return value as Celsius;
}
function fahrenheit(value: number): Fahrenheit {
  return value as Fahrenheit;
}
function toFahrenheit(t: Celsius): Fahrenheit {
  return fahrenheit((t * 9) / 5 + 32);
}
function boils(t: Celsius): boolean {
  return t >= 100;
}

const water = celsius(100);
const oven = fahrenheit(350);
console.log(toFahrenheit(water), boils(water));

// Never called: each line shows a mistake that tsc now rejects
function mistakes() {
  // @ts-expect-error: a Fahrenheit is not a Celsius
  boils(oven);
  // @ts-expect-error: a plain number is not a Celsius either
  boils(212);
  // @ts-expect-error: the result of arithmetic is a plain number again
  const warmer: Celsius = water + 1;
  return warmer;
}
console.log(typeof mistakes);
