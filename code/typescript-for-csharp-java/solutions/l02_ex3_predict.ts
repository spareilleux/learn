// solutions/l02_ex3_predict.ts
// Every line that tsc rejects carries @ts-expect-error: if one of them compiled, tsc would report an unused directive
interface Point {
  x: number;
  y: number;
}
interface ReadonlyPoint {
  readonly x: number;
  readonly y: number;
}

const p3 = { x: 1, y: 2, z: 3 };
const a: Point = p3; // 1. accepted: not a fresh literal, and z is extra
// @ts-expect-error 2. rejected: excess property z in a fresh object literal
const b: Point = { x: 1, y: 2, z: 3 };
const c: ReadonlyPoint = a; // 3. accepted: readonly only restricts what c can do
const d: Point = c; // 4. accepted: readonly doesn't affect assignability
// @ts-expect-error 5. rejected: [number, number] has no third element
const e: [number, number] = [1, 2, 3];
const f: number[] = [1, 2] as [number, number]; // 6. accepted: a tuple is an array
// @ts-expect-error 7. rejected: unknown must be narrowed before it is assigned to a string
const g: string = JSON.parse('"x"') as unknown;
const h: string = JSON.parse('1'); // 8. accepted: any is assignable to string, and h holds 1
// @ts-expect-error 9. rejected: null isn't a number under strictNullChecks
const i: number = null;

console.log([a, b, c, d, e, f, g, typeof h, i].length);
