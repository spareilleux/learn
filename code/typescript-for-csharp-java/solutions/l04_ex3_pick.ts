// solutions/l04_ex3_pick.ts
function pick<T extends object, K extends keyof T>(value: T, keys: readonly K[]): Pick<T, K> {
  const result = {} as Pick<T, K>; // an assertion: the loop below fills every key of K
  for (const key of keys) {
    result[key] = value[key];
  }
  return result;
}

interface SceneOptions {
  stars: boolean;
  tower: boolean;
  skyboxMode: 'milky-way' | 'nebula';
}
const options: SceneOptions = { stars: true, tower: false, skyboxMode: 'nebula' };
const toggles = pick(options, ['stars', 'tower']); // Pick<SceneOptions, 'stars' | 'tower'>
console.log(toggles, Object.keys(toggles));

// Never called: each line shows a mistake that tsc rejects
function mistakes() {
  // @ts-expect-error: 'weather' is not a key of SceneOptions
  pick(options, ['weather']);
  // @ts-expect-error: skyboxMode was not picked
  return toggles.skyboxMode;
}
console.log(typeof mistakes);
