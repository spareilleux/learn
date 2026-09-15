// examples/l03_guards.ts
import { attempt, show } from './show.ts';

interface CameraState {
  px: number;
  py: number;
  pz: number;
}

// as is not a cast: it converts nothing and checks nothing
const trusted = JSON.parse('{"px": 1, "py": 2}') as CameraState;
show('trusted.pz', trusted.pz);
show('trusted.pz * 2', trusted.pz * 2);

// A type predicate: a function that returns a boolean, and tells tsc what true means
function isCameraState(value: unknown): value is CameraState {
  return (
    typeof value === 'object' &&
    value !== null &&
    'px' in value &&
    typeof value.px === 'number' && // after 'px' in value, tsc knows value has a px property of type unknown
    'py' in value &&
    typeof value.py === 'number' &&
    'pz' in value &&
    typeof value.pz === 'number'
  );
}

function restore(saved: string): CameraState {
  const value: unknown = JSON.parse(saved);
  return isCameraState(value) ? value : { px: 0, py: 0, pz: 100 };
}
show("restore('{\"px\":1,\"py\":2}')", restore('{"px":1,"py":2}'));
show("restore('{\"px\":1,\"py\":2,\"pz\":3}')", restore('{"px":1,"py":2,"pz":3}'));

// An assertion function: it returns only if the condition holds, and throws otherwise
type Mode = 'ionian' | 'dorian' | 'phrygian';
const modes: readonly string[] = ['ionian', 'dorian', 'phrygian'];
function assertMode(value: string): asserts value is Mode {
  if (!modes.includes(value)) throw new RangeError(`unknown mode: ${value}`);
}
function brightness(mode: Mode): number {
  return modes.length - modes.indexOf(mode);
}
const fromUrl = new URLSearchParams('?mode=dorian').get('mode') ?? 'ionian';
assertMode(fromUrl);
show('brightness(fromUrl)', brightness(fromUrl)); // fromUrl is a Mode after the assertion
attempt("assertMode('locrian')", () => assertMode('locrian'));

// tsc trusts a predicate without reading it: a wrong one is a lie that compiles
function isCameraStateLie(value: unknown): value is CameraState {
  return value !== null;
}
const lie: unknown = JSON.parse('"not a camera"');
if (isCameraStateLie(lie)) {
  attempt('lie.px.toFixed(1)', () => lie.px.toFixed(1));
}
