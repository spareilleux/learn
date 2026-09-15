// errors/l01_deferred.ts
// Without the assertion: narrowing value to string doesn't tell tsc which branch T takes
function describe<T extends string | number>(value: T): T extends string ? 'text' : 'number' {
  if (typeof value === 'string') return 'text';
  return 'number';
}
console.log(describe('C#'), describe(440));
