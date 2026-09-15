// errors/l04_mapped.ts
// A new option: the validators object no longer matches, so tsc points at it
interface SceneOptions {
  stars: boolean;
  tower: boolean;
  skyboxMode: 'milky-way' | 'nebula';
  weather: boolean;
}
type Validators<T> = {
  [K in keyof T]: (value: unknown) => value is T[K];
};

const isBoolean = (value: unknown): value is boolean => typeof value === 'boolean';
const sceneValidators: Validators<SceneOptions> = {
  stars: isBoolean,
  tower: isBoolean,
  skyboxMode: (value): value is 'milky-way' | 'nebula' => value === 'milky-way' || value === 'nebula',
};
console.log(Object.keys(sceneValidators));
