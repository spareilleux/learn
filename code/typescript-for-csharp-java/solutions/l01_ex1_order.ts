// solutions/l01_ex1_order.ts
interface Line {
  product: string;
  price: number;
  quantity: number;
}

function withTax(line: Line): number {
  return line.price + line.price * 0.15;
}

// The CSV gives text: convert it once, at the border, and refuse what isn't a price
function parsePrice(text: string): number {
  if (!/^\d+(\.\d{1,2})?$/.test(text)) throw new TypeError(`not a price: ${JSON.stringify(text)}`);
  return Number(text);
}

const rows = [
  ['capo', '9.99', '2'],
  ['strings', '12.5', '1'],
] as const;
const lines: Line[] = rows.map(([product, price, quantity]) => ({
  product,
  price: parsePrice(price),
  quantity: Number.parseInt(quantity, 10),
}));
for (const line of lines) {
  console.log(line.product, (withTax(line) * line.quantity).toFixed(2));
}
