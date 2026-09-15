// examples/l02_any_unknown.ts
import { attempt, show } from './show.ts';

const saved = '{"stars": "yes", "tower": true}';

// JSON.parse returns any: every use compiles, and any spreads to what it touches
const options = JSON.parse(saved);
const stars: boolean = options.stars; // no error: any is assignable to everything
show('stars', stars);
show('typeof stars', typeof stars);
attempt('options.weather.level', () => options.weather.level);

// unknown accepts any value too, but nothing can be done with it before a check
const checked: unknown = JSON.parse(saved);
if (typeof checked === 'object' && checked !== null && 'stars' in checked) {
  show("typeof checked.stars", typeof checked.stars);
}

// never: a function that doesn't return, and a value that can't exist
function fail(message: string): never {
  throw new Error(message);
}
function starsOf(value: unknown): boolean {
  return typeof value === 'boolean' ? value : fail(`not a boolean: ${JSON.stringify(value)}`);
}
attempt('starsOf(options.stars)', () => starsOf(options.stars));
