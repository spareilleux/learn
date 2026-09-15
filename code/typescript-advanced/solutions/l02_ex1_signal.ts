// solutions/l02_ex1_signal.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Variance<Sub, Super> = [Sub] extends [Super] ? ([Super] extends [Sub] ? 'bivariant' : 'covariant') : [Super] extends [Sub] ? 'contravariant' : 'invariant';

interface Instrument {
  name: string;
}
interface Guitar extends Instrument {
  tune(): string;
}

// The signal as first written: set is a method, so its parameter is bivariant, and T is measured covariant
interface Signal<T> {
  get(): T;
  set(value: T): void;
  subscribe(listener: (value: T) => void): () => void;
}
type _1 = Expect<Equal<Variance<Signal<Guitar>, Signal<Instrument>>, 'covariant'>>;

// Function-type properties are checked under strictFunctionTypes: get makes T covariant, set contravariant
interface CheckedSignal<T> {
  get: () => T;
  set: (value: T) => void;
  subscribe: (listener: (value: T) => void) => () => void;
}
type _2 = Expect<Equal<Variance<CheckedSignal<Guitar>, CheckedSignal<Instrument>>, 'invariant'>>;

// Or keep the methods, and say what they mean
interface AnnotatedSignal<in out T> {
  get(): T;
  set(value: T): void;
  subscribe(listener: (value: T) => void): () => void;
}
type _3 = Expect<Equal<Variance<AnnotatedSignal<Guitar>, AnnotatedSignal<Instrument>>, 'invariant'>>;

function signal<T>(initial: T): CheckedSignal<T> {
  let value = initial;
  const listeners = new Set<(value: T) => void>();
  return {
    get: () => value,
    set: (next) => {
      value = next;
      for (const listener of listeners) listener(next);
    },
    subscribe: (listener) => {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
  };
}

const guitar = signal<Guitar>({ name: 'guitar', tune: () => 'EADGBE' });
guitar.subscribe((g) => console.log(`tuned to ${g.tune()}`));
guitar.set({ name: 'baritone', tune: () => 'BEADF#B' });
// @ts-expect-error: a CheckedSignal<Guitar> is not a CheckedSignal<Instrument>, which could set a piano
const instruments: CheckedSignal<Instrument> = guitar;
console.log(guitar.get().name, typeof instruments);
