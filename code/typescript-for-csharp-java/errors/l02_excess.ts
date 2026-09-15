// errors/l02_excess.ts
interface SceneOptions {
  stars?: boolean;
  tower?: boolean;
  skyboxMode?: string;
}

function describe(options: SceneOptions): string {
  return `stars ${options.stars ?? true}, tower ${options.tower ?? false}`;
}

// An object literal written where a SceneOptions is expected: an unknown property is an error
console.log(describe({ stars: false, towr: true }));

// The same object in a variable first: no excess property check, and the typo is silently ignored
const fromUrl = { stars: false, towr: true };
console.log(describe(fromUrl));
