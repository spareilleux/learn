// examples/l04_erasure.ts
import { attempt, show } from './show.ts';

// T appears only in the return type: the caller chooses it, and nothing checks it
function parse<T>(json: string): T {
  return JSON.parse(json);
}
const count = parse<number>('"twelve"');
show('typeof count', typeof count);
attempt('count.toFixed(1)', () => count.toFixed(1));

// There is no T at run time: pass what the function needs as a value, here a constructor
class Tuner {
  reference = 440;
}
function create<T>(ctor: new () => T): T {
  return new ctor();
}
show('create(Tuner)', create(Tuner));

// Or a type guard, which carries the check to run time
function parseArray<T>(json: string, isItem: (value: unknown) => value is T): T[] {
  const value: unknown = JSON.parse(json);
  if (!Array.isArray(value) || !value.every(isItem)) throw new TypeError(`not the expected array: ${json}`);
  return value;
}
const isNumber = (value: unknown): value is number => typeof value === 'number';
show("parseArray('[0, 2, 2]', isNumber)", parseArray('[0, 2, 2]', isNumber));
attempt("parseArray('[0, \"2\"]', isNumber)", () => parseArray('[0, "2"]', isNumber));

// GA's musicService.ts, lines 17-23: a generic guard checks the shape, never the T
interface ApiResponse<T> {
  success: boolean;
  data: T;
}
const isApiResponse = <T>(value: unknown): value is ApiResponse<T> =>
  typeof value === 'object' && value !== null && 'success' in value && 'data' in value;
const json: unknown = JSON.parse('{"success": true, "data": "C major"}');
if (isApiResponse<string[]>(json)) {
  attempt('json.data.map((n) => n.length)', () => json.data.map((n) => n.length));
}
