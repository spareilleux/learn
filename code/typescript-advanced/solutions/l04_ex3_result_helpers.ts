// solutions/l04_ex3_result_helpers.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
const ok = <T>(value: T): Result<T, never> => ({ ok: true, value });
const err = <E>(error: E): Result<never, E> => ({ ok: false, error });

const map = <T, U, E>(result: Result<T, E>, f: (value: T) => U): Result<U, E> => (result.ok ? ok(f(result.value)) : result);
const andThen = <T, U, E, F>(result: Result<T, E>, f: (value: T) => Result<U, F>): Result<U, E | F> => (result.ok ? f(result.value) : result);

// all: a tuple of results becomes a result of a tuple, and the error type is the union of the errors
type Values<R extends readonly Result<unknown, unknown>[]> = { -readonly [K in keyof R]: R[K] extends Result<infer T, unknown> ? T : never };
type Errors<R extends readonly Result<unknown, unknown>[]> = R[number] extends infer U ? (U extends { ok: false; error: infer E } ? E : never) : never;
function all<const R extends readonly Result<unknown, unknown>[]>(results: R): Result<Values<R>, Errors<R>> {
  const values: unknown[] = [];
  for (const result of results) {
    if (!result.ok) return result as Result<never, Errors<R>>;
    values.push(result.value);
  }
  return ok(values as Values<R>); // an assertion: one value per result, in order
}

type FretError = { kind: 'fret-out-of-range'; fret: number };
type NoteError = { kind: 'unknown-note'; text: string };
const parseFret = (text: string): Result<number, FretError> => {
  const fret = Number(text);
  return Number.isInteger(fret) && fret >= 0 && fret <= 24 ? ok(fret) : err({ kind: 'fret-out-of-range', fret });
};
const parseNote = (text: string): Result<string, NoteError> => (/^[A-G][#b]?$/.test(text) ? ok(text) : err({ kind: 'unknown-note', text }));

const position = all([parseNote('E'), parseFret('7')]);
type _1 = Expect<Equal<typeof position, Result<[string, number], NoteError | FretError>>>;
console.log(map(position, ([note, fret]) => `${note} string, fret ${fret}`));
console.log(all([parseNote('H'), parseFret('7')]));
console.log(andThen(parseFret('30'), (fret) => parseNote(fret > 12 ? 'E' : 'A')));
