// errors/l01_order.ts
interface Line {
  product: string;
  price: number;
  quantity: number;
}

function withTax(line: Line): number {
  return line.price + line.price * 0.15;
}

// The prices come from a CSV file, where everything is text
const lines: Line[] = [
  { product: 'capo', price: '9.99', quantity: 2 },
  { product: 'strings', price: 12.5, quantity: 1 },
];
for (const line of lines) {
  console.log(line.product, withTax(line) * line.quantity);
}
