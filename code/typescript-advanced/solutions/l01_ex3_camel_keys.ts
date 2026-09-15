// solutions/l01_ex3_camel_keys.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

// GA's BeliefState, whose property names come in snake_case from the belief files
interface BeliefState {
  id: string;
  proposition: string;
  truth_value: 'T' | 'F' | 'U' | 'C';
  confidence: number;
  last_updated?: string;
  evaluated_by?: string;
}

type SnakeToCamel<S extends string> = S extends `${infer Head}_${infer Tail}` ? `${Head}${Capitalize<SnakeToCamel<Tail>>}` : S;
type CamelKeys<T> = { [K in keyof T as K extends string ? SnakeToCamel<K> : K]: T[K] };

type _1 = Expect<Equal<SnakeToCamel<'last_updated_by_agent'>, 'lastUpdatedByAgent'>>;
type _2 = Expect<Equal<CamelKeys<BeliefState>, { id: string; proposition: string; truthValue: 'T' | 'F' | 'U' | 'C'; confidence: number; lastUpdated?: string; evaluatedBy?: string }>>;

const snakeToCamel = <S extends string>(text: S) => text.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase()) as SnakeToCamel<S>;

function camelKeys<T extends object>(value: T): CamelKeys<T> {
  return Object.fromEntries(Object.entries(value).map(([key, v]) => [snakeToCamel(key), v])) as CamelKeys<T>;
}

const belief: BeliefState = { id: 'b-12', proposition: 'the voicing index is fresh', truth_value: 'U', confidence: 0.6, last_updated: '2026-09-15' };
const camel = camelKeys(belief);
console.log(camel.truthValue, camel.lastUpdated, Object.keys(camel));
