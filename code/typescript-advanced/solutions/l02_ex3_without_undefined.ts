// solutions/l02_ex3_without_undefined.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

interface ViewerInfo {
  connectionId: string;
  color: string;
  displayName?: string;
  avatarUrl?: string | null;
}

// Properties that may hold undefined become optional and lose undefined; null is kept, since it is a value
type WithoutUndefined<T> = { [K in keyof T]: Exclude<T[K], undefined> };

function withoutUndefined<T extends object>(value: T): Partial<WithoutUndefined<T>> {
  // An assertion: the filter removes exactly the entries whose value is undefined
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as Partial<WithoutUndefined<T>>;
}

// A patch built from a form, where a field left empty is undefined
const form: { displayName: string | undefined; avatarUrl: string | null | undefined } = { displayName: undefined, avatarUrl: null };
const patch = withoutUndefined(form);
type _1 = Expect<Equal<typeof patch, { displayName?: string; avatarUrl?: string | null }>>;

const viewer: ViewerInfo = { connectionId: 'c3', color: '#d2a8ff', displayName: 'Hari' };
const updated: ViewerInfo = { ...viewer, ...patch };
console.log(updated);
