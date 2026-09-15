// examples/l02_variance.ts
import type { Equal, Expect } from './type-tests.ts';
import { attempt, show } from './show.ts';

interface Instrument {
  name: string;
}
interface Guitar extends Instrument {
  strings: number;
  tune(): string;
}

// Measured variance, tested on assignability in both directions
type Variance<Sub, Super> = [Sub] extends [Super] ? ([Super] extends [Sub] ? 'bivariant' : 'covariant') : [Super] extends [Sub] ? 'contravariant' : 'invariant';

interface Producer<T> {
  get: () => T;
}
interface Consumer<T> {
  set: (value: T) => void;
}
interface Both<T> {
  get: () => T;
  set: (value: T) => void;
}
interface WithMethod<T> {
  set(value: T): void;
}
interface Callback<T> {
  subscribe: (listener: (value: T) => void) => void;
}
interface Slot<T> {
  value: T;
}
interface ReadonlySlot<T> {
  readonly value: T;
}

type _1 = Expect<Equal<Variance<Producer<Guitar>, Producer<Instrument>>, 'covariant'>>;
type _2 = Expect<Equal<Variance<Consumer<Guitar>, Consumer<Instrument>>, 'contravariant'>>;
type _3 = Expect<Equal<Variance<Both<Guitar>, Both<Instrument>>, 'invariant'>>;
// A method parameter is bivariant, even under strictFunctionTypes
type _4 = Expect<Equal<Variance<WithMethod<Guitar>, WithMethod<Instrument>>, 'bivariant'>>;
// A parameter of a parameter is covariant again: two contravariant positions cancel out
type _5 = Expect<Equal<Variance<Callback<Guitar>, Callback<Instrument>>, 'covariant'>>;
// A mutable property is read and written, and still measured covariant
type _6 = Expect<Equal<Variance<Slot<Guitar>, Slot<Instrument>>, 'covariant'>>;
type _7 = Expect<Equal<Variance<ReadonlySlot<Guitar>, ReadonlySlot<Instrument>>, 'covariant'>>;

// The covariant mutable property is unsound: a piano gets into the guitar's slot through an alias
const guitar: Guitar = { name: 'guitar', strings: 6, tune: () => 'EADGBE' };
const guitarSlot: Slot<Guitar> = { value: guitar };
const instrumentSlot: Slot<Instrument> = guitarSlot;
instrumentSlot.value = { name: 'piano' };
attempt('guitarSlot.value.tune()', () => guitarSlot.value.tune());

// in out declares the invariance that the structure doesn't show; the same alias no longer compiles
interface SafeSlot<in out T> {
  value: T;
}
type _8 = Expect<Equal<Variance<SafeSlot<Guitar>, SafeSlot<Instrument>>, 'invariant'>>;
const safeGuitarSlot: SafeSlot<Guitar> = { value: guitar };
// @ts-expect-error: SafeSlot<Guitar> is not a SafeSlot<Instrument>
const safeInstrumentSlot: SafeSlot<Instrument> = safeGuitarSlot;
show('safeGuitarSlot.value.tune()', safeGuitarSlot.value.tune());

// The method bivariance hack of @types/react: a function type that stays bivariant under strictFunctionTypes
type EventHandler<E> = { bivarianceHack(event: E): void }['bivarianceHack'];
interface ClickEvent {
  x: number;
}
interface DoubleClickEvent extends ClickEvent {
  count: 2;
}
type _9 = Expect<Equal<Variance<EventHandler<DoubleClickEvent>, EventHandler<ClickEvent>>, 'bivariant'>>;
const onDoubleClick: EventHandler<DoubleClickEvent> = (event) => console.log(`double click ${event.count}`);
const onClick: EventHandler<ClickEvent> = onDoubleClick; // accepted: the hack lets a narrower handler through
attempt('onClick({ x: 3 })', () => onClick({ x: 3 }));
