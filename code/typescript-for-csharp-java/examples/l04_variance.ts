// examples/l04_variance.ts
import { attempt, show } from './show.ts';

interface Instrument {
  name: string;
}
interface Guitar extends Instrument {
  strings: number;
  tune(): string;
}
const guitar: Guitar = { name: 'guitar', strings: 6, tune: () => 'EADGBE' };
const piano: Instrument = { name: 'piano' };

// Arrays are covariant: a Guitar[] is accepted as an Instrument[], and the alias can add a piano
const guitars: Guitar[] = [guitar];
const instruments: Instrument[] = guitars;
instruments.push(piano);
show('guitars.length', guitars.length);
attempt('guitars[1].tune()', () => guitars[1].tune());

// A function property is checked contravariantly (strictFunctionTypes); a method is not
interface WithProperty {
  play: (instrument: Instrument) => string;
}
interface WithMethod {
  play(instrument: Instrument): string;
}
const tuneGuitar = (g: Guitar) => g.tune();
const withMethod: WithMethod = { play: tuneGuitar }; // accepted: method parameters are bivariant
attempt('withMethod.play(piano)', () => withMethod.play(piano));
const withProperty: WithProperty = { play: (i: Instrument) => i.name }; // a function of Instrument is fine
show('withProperty.play(piano)', withProperty.play(piano));

// Variance annotations: out for a type that only produces T, in for one that only consumes it
interface Source<out T> {
  next(): T;
}
interface Sink<in T> {
  accept(value: T): void;
}
const guitarSource: Source<Guitar> = { next: () => guitar };
const instrumentSource: Source<Instrument> = guitarSource; // out: Source<Guitar> is a Source<Instrument>
const names: string[] = [];
const instrumentSink: Sink<Instrument> = { accept: (i) => names.push(i.name) };
const guitarSink: Sink<Guitar> = instrumentSink; // in: Sink<Instrument> is a Sink<Guitar>
guitarSink.accept(guitar);
instrumentSink.accept(piano);
show('instrumentSource.next().name', instrumentSource.next().name);
show('names', names);
