// errors/l01_type_tests.ts
// A type test that fails, and an expected error that doesn't happen: both are compile errors
import type { Equal, Expect } from '../examples/type-tests.ts';

type ElementOf<T> = T extends (infer E)[] ? E : never;

type _1 = Expect<Equal<ElementOf<string[]>, string>>;
type _2 = Expect<Equal<ElementOf<readonly string[]>, string>>;

// @ts-expect-error: a string is not an array, so this line should be rejected
const notAnError: ElementOf<'EADGBE'> = undefined as never;
console.log(notAnError);
