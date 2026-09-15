// examples/l01_mapped.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

interface Voicing {
  readonly id: string;
  frets: number[];
  capo?: number;
  label?: string;
}

// A homomorphic mapped type, { [K in keyof T]: … }, keeps each property's readonly and ? modifiers
type Nullable<T> = { [K in keyof T]: T[K] | null };
type _1 = Expect<Equal<Nullable<Voicing>, { readonly id: string | null; frets: number[] | null; capo?: number | null; label?: string | null }>>;

// -readonly and -? remove the modifiers; readonly and ? add them
type Mutable<T> = { -readonly [K in keyof T]: T[K] };
type Complete<T> = { [K in keyof T]-?: T[K] };
type _2 = Expect<Equal<Mutable<Voicing>, { id: string; frets: number[]; capo?: number; label?: string }>>;
type _3 = Expect<Equal<Complete<Voicing>, { readonly id: string; frets: number[]; capo: number; label: string }>>;

// Key remapping with as: the new key is computed, here with a template literal type
type Getters<T> = { [K in keyof T & string as `get${Capitalize<K>}`]: () => T[K] };
type _4 = Expect<Equal<keyof Getters<Voicing>, 'getId' | 'getFrets' | 'getCapo' | 'getLabel'>>;

// A key remapped to never is removed: a filter on the properties
type KeysOfType<T, V> = keyof { [K in keyof T as T[K] extends V ? K : never]: T[K] };
type OptionalKeys<T> = keyof { [K in keyof T as {} extends Pick<T, K> ? K : never]: T[K] };
type _5 = Expect<Equal<KeysOfType<Voicing, string>, 'id'>>;
type _6 = Expect<Equal<OptionalKeys<Voicing>, 'capo' | 'label'>>;

// A homomorphic mapped type applied to a tuple gives a tuple
type Boxed<T> = { [K in keyof T]: { value: T[K] } };
type _7 = Expect<Equal<Boxed<[string, number]>, [{ value: string }, { value: number }]>>;

// The implementation needs one assertion: tsc can't follow Object.entries through a key remapping
function gettersOf<T extends object>(value: T): Getters<T> {
  const entries = Object.entries(value).map(([key, v]) => [`get${key.charAt(0).toUpperCase()}${key.slice(1)}`, () => v]);
  return Object.fromEntries(entries) as Getters<T>;
}
const voicing: Voicing = { id: 'C-open', frets: [-1, 3, 2, 0, 1, 0], label: 'C major' };
const getters = gettersOf(voicing);
show('Object.keys(getters)', Object.keys(getters));
show('getters.getLabel()', getters.getLabel());
// getCapo is in the type, and not in the object: the type lists what Voicing allows, not what this value has
show("'getCapo' in getters", 'getCapo' in getters);
