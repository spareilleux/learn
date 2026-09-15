// examples/type-tests.ts
// Type tests that tsc checks and Node.js erases: Expect<Equal<A, B>> fails to compile unless A and B are the same type

// Two function types are compared with an extra type parameter U, which tsc can't resolve: they are assignable
// only if A and B are identical, which catches any, unions and optional modifiers that extends alone lets through
export type Equal<A, B> = (<U>() => U extends A ? 1 : 2) extends <U>() => U extends B ? 1 : 2 ? true : false;
export type Expect<T extends true> = T;
