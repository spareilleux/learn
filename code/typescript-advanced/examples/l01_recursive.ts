// examples/l01_recursive.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// A recursive conditional type walks a string one character at a time: a guitar fingering, low E string first
type Fret<C extends string> = C extends 'x' ? null : C extends `${infer N extends number}` ? N : never;
type Fingering<S extends string> = S extends `${infer C}${infer Rest}` ? [Fret<C>, ...Fingering<Rest>] : [];
type _1 = Expect<Equal<Fingering<'x32010'>, [null, 3, 2, 0, 1, 0]>>;

// A recursive type follows a nested object: DeepReadonly, which the standard library doesn't provide
type DeepReadonly<T> = T extends (...args: never[]) => unknown
  ? T
  : T extends object
    ? { readonly [K in keyof T]: DeepReadonly<T[K]> }
    : T;
interface Tuning {
  name: string;
  strings: { note: string; octave: number }[];
}
type _2 = Expect<Equal<DeepReadonly<Tuning>, { readonly name: string; readonly strings: readonly { readonly note: string; readonly octave: number }[] }>>;

// Dotted paths into a nested type, as form and translation libraries compute them
type Paths<T> = T extends object
  ? { [K in keyof T & string]: T[K] extends readonly unknown[] ? K : T[K] extends object ? K | `${K}.${Paths<T[K]>}` : K }[keyof T & string]
  : never;
interface SceneSettings {
  camera: { position: { x: number; y: number; z: number }; fov: number };
  stars: boolean;
  tunings: Tuning[];
}
type _3 = Expect<Equal<Paths<SceneSettings>, 'camera' | 'camera.position' | 'camera.position.x' | 'camera.position.y' | 'camera.position.z' | 'camera.fov' | 'stars' | 'tunings'>>;

// Tail recursion: when the recursive call is the whole branch, tsc evaluates it in a loop, up to 1,000 times.
// Fingering is not tail-recursive: its call sits inside a tuple. With an accumulator, the call is the branch.
type FingeringTail<S extends string, Acc extends unknown[] = []> = S extends `${infer C}${infer Rest}` ? FingeringTail<Rest, [...Acc, Fret<C>]> : Acc;
type Long = `${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}${'x32010'}`;
type _4 = Expect<Equal<FingeringTail<Long>['length'], 60>>;

// The run-time parser, typed by the recursive type
function parseFingering<S extends string>(text: S): Fingering<S> {
  return [...text].map((c) => (c === 'x' ? null : Number(c))) as Fingering<S>;
}
const cMajor = parseFingering('x32010');
type _5 = Expect<Equal<(typeof cMajor)[1], 3>>;
show("parseFingering('x32010')", cMajor);

function getPath<T, P extends Paths<T>>(value: T, path: P): unknown {
  return path.split('.').reduce<unknown>((current, key) => (current as Record<string, unknown>)[key], value);
}
const settings: SceneSettings = { camera: { position: { x: 0, y: 2, z: 10 }, fov: 60 }, stars: true, tunings: [] };
show("getPath(settings, 'camera.fov')", getPath(settings, 'camera.fov'));
