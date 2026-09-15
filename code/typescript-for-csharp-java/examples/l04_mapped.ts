// examples/l04_mapped.ts
import { show } from './show.ts';

interface SceneOptions {
  stars: boolean;
  tower: boolean;
  skyboxMode: 'milky-way' | 'nebula';
}

// keyof lists the property names as a union; T[K] is the type of one property
type OptionName = keyof SceneOptions; // 'stars' | 'tower' | 'skyboxMode'
type Skybox = SceneOptions['skyboxMode']; // 'milky-way' | 'nebula'
const name: OptionName = 'skyboxMode';
const skybox: Skybox = 'nebula';
show('name, skybox', [name, skybox]);

// A mapped type builds one property for each key of another type
type Validators<T> = {
  [K in keyof T]: (value: unknown) => value is T[K];
};

const isBoolean = (value: unknown): value is boolean => typeof value === 'boolean';
const sceneValidators: Validators<SceneOptions> = {
  stars: isBoolean,
  tower: isBoolean,
  skyboxMode: (value): value is Skybox => value === 'milky-way' || value === 'nebula',
};

// One generic merge for every options type: known keys only, valid values only, and the URL last
function merge<T extends object>(defaults: T, saved: unknown, validators: Validators<T>): T {
  const result = { ...defaults };
  if (typeof saved !== 'object' || saved === null) return result;
  for (const key of Object.keys(validators) as (keyof T)[]) {
    const value: unknown = (saved as Record<PropertyKey, unknown>)[key];
    if (Object.hasOwn(saved, key) && validators[key](value)) result[key] = value;
  }
  return result;
}

const defaults: SceneOptions = { stars: true, tower: false, skyboxMode: 'milky-way' };
const saved: unknown = JSON.parse('{"stars":"yes","tower":true,"bloom":3,"skyboxMode":"nebula","__proto__":{"isAdmin":true}}');
const state = merge(defaults, saved, sceneValidators);
if (new URLSearchParams('?tower=0').has('tower')) state.tower = false;
show('state', state);
show("'isAdmin' in state", 'isAdmin' in state);

// The library's mapped types: Partial, Readonly, Pick and Record
const patch: Partial<SceneOptions> = { tower: true };
const frozen: Readonly<SceneOptions> = Object.freeze({ ...defaults, ...patch });
const toggles: Pick<SceneOptions, 'stars' | 'tower'> = frozen;
const labels: Record<Skybox, string> = { 'milky-way': 'Milky Way', nebula: 'Nebula' };
show('toggles, labels[frozen.skyboxMode]', [toggles, labels[frozen.skyboxMode]]);
