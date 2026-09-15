// errors/l04_erasure.ts
function create<T>(): T {
  return new T();
}
function isOf<T>(value: unknown): value is T {
  return value instanceof T;
}

console.log(create<Date>(), isOf<Date>(new Date()));
