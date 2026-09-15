// errors/l04_variance.ts
interface Instrument {
  name: string;
}
interface Guitar extends Instrument {
  strings: number;
  tune(): string;
}

interface WithProperty {
  play: (instrument: Instrument) => string;
}
const tuneGuitar = (g: Guitar) => g.tune();
const withProperty: WithProperty = { play: tuneGuitar };

interface Source<out T> {
  next(): T;
}
interface Sink<in T> {
  accept(value: T): void;
}
declare const instrumentSource: Source<Instrument>;
declare const guitarSink: Sink<Guitar>;
const guitarSource: Source<Guitar> = instrumentSource;
const instrumentSink: Sink<Instrument> = guitarSink;

// in promises that T is only consumed, and next returns it
interface Mislabeled<in T> {
  next(): T;
}

console.log(withProperty, guitarSource, instrumentSink);
