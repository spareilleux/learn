// examples/l01_strip.ts
import { stripTypeScriptTypes } from 'node:module';

// What Node.js runs: the same text, with the types replaced by spaces
const source = `interface Line {
  price: number;
  quantity: number;
}
export function total(lines: readonly Line[]): number {
  let sum: number = 0;
  for (const line of lines) sum += line.price * line.quantity;
  return sum;
}
const empty = [] as Line[];`;
console.log(stripTypeScriptTypes(source));
