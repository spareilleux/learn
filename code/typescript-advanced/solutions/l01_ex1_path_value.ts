// solutions/l01_ex1_path_value.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Paths<T> = T extends object
  ? { [K in keyof T & string]: T[K] extends readonly unknown[] ? K : T[K] extends object ? K | `${K}.${Paths<T[K]>}` : K }[keyof T & string]
  : never;

// The type at the end of a dotted path: split off the first key, look it up, and continue with the rest
type PathValue<T, P extends string> = P extends `${infer K}.${infer Rest}`
  ? K extends keyof T
    ? PathValue<T[K], Rest>
    : never
  : P extends keyof T
    ? T[P]
    : never;

interface SceneSettings {
  camera: { position: { x: number; y: number; z: number }; fov: number };
  stars: boolean;
  tunings: { name: string; notes: string[] }[];
}
type _1 = Expect<Equal<PathValue<SceneSettings, 'camera.fov'>, number>>;
type _2 = Expect<Equal<PathValue<SceneSettings, 'camera.position'>, { x: number; y: number; z: number }>>;
type _3 = Expect<Equal<PathValue<SceneSettings, 'tunings'>, { name: string; notes: string[] }[]>>;

function getPath<T, P extends Paths<T>>(value: T, path: P): PathValue<T, P> {
  // An assertion: reduce walks the same keys as PathValue, which tsc can't relate to the string's contents
  return path.split('.').reduce<unknown>((current, key) => (current as Record<string, unknown>)[key], value) as PathValue<T, P>;
}

const settings: SceneSettings = { camera: { position: { x: 0, y: 2, z: 10 }, fov: 60 }, stars: true, tunings: [] };
const fov = getPath(settings, 'camera.fov'); // number
const z = getPath(settings, 'camera.position.z'); // number
console.log(fov.toFixed(1), z + 1, getPath(settings, 'stars'));
