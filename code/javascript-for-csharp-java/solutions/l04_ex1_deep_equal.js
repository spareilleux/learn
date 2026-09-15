// Lesson 4, exercise 1: deepEqual compares plain objects and arrays by content, like record equality
function deepEqual(a, b) {
  if (Object.is(a, b)) return true;
  if (typeof a !== 'object' || typeof b !== 'object' || a === null || b === null) return false;
  if (Object.getPrototypeOf(a) !== Object.getPrototypeOf(b)) return false;
  const keys = Object.keys(a);
  if (keys.length !== Object.keys(b).length) return false;
  return keys.every((key) => Object.hasOwn(b, key) && deepEqual(a[key], b[key]));
}

console.log(deepEqual({ x: 1, tags: ['a'] }, { tags: ['a'], x: 1 }));
console.log(deepEqual({ x: 1 }, { x: 1, y: undefined }));
console.log(deepEqual([1, 2], { 0: 1, 1: 2 }));
console.log(deepEqual(NaN, NaN), deepEqual(0, -0));
console.log(deepEqual(new Date(0), new Date(1)));
