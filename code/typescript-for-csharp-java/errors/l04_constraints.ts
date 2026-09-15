// errors/l04_constraints.ts
function longest<T extends { length: number }>(a: T, b: T): T {
  return b.length > a.length ? b : a;
}
interface Tuning {
  name: string;
  capo: number;
}
function get<T, K extends keyof T>(value: T, key: K): T[K] {
  return value[key];
}

const standard: Tuning = { name: 'standard', capo: 0 };
console.log(longest(10, 20), longest('capo', [1, 2]));
console.log(get(standard, 'nmae'));
