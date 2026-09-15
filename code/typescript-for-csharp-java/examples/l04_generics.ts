// examples/l04_generics.ts
import { show } from './show.ts';

// A type parameter, inferred from the argument
function first<T>(items: readonly T[]): T | undefined {
  return items[0];
}
const note = first(['E', 'A', 'D']); // T is string
const fret = first([0, 2, 2]); // T is number
show('note, fret', [note, fret]);
show('first<string>([])', first<string>([])); // an explicit type argument

// A constraint: T must have a length, and keeps its own type
function longest<T extends { length: number }>(a: T, b: T): T {
  return b.length > a.length ? b : a;
}
show("longest('capo', 'strings')", longest('capo', 'strings'));
show('longest([1, 2], [1, 2, 3])', longest([1, 2], [1, 2, 3]));

// keyof and indexed access: the key is checked, and the result has the type of that property
interface Tuning {
  name: string;
  notes: string[];
  capo: number;
}
function get<T, K extends keyof T>(value: T, key: K): T[K] {
  return value[key];
}
const standard: Tuning = { name: 'standard', notes: ['E', 'A', 'D', 'G', 'B', 'E'], capo: 0 };
const notes = get(standard, 'notes'); // string[]
const capo = get(standard, 'capo'); // number
show("get(standard, 'notes').join('')", notes.join(''));
show("get(standard, 'capo') + 2", capo + 2);

// A generic type, with a default
interface Page<T, Cursor = number> {
  items: T[];
  next?: Cursor;
}
const page: Page<Tuning> = { items: [standard], next: 2 };
const byName: Page<string, string> = { items: ['drop D'], next: 'open G' };
show('page.items.length, byName.next', [page.items.length, byName.next]);
