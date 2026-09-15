// examples/l04_standard_schema.ts
// Standard Schema: one interface that Zod, Valibot and ArkType all implement, so a function can accept any of them
import type { StandardSchemaV1 } from '@standard-schema/spec';
import { type } from 'arktype';
import * as v from 'valibot';
import * as z from 'zod';
import type { Equal, Expect } from './type-tests.ts';

type Parsed<T> = { ok: true; value: T } | { ok: false; issues: string[] };

// Written once, against the interface: the output type comes from the schema, whichever library built it
async function parseJson<S extends StandardSchemaV1>(schema: S, text: string): Promise<Parsed<StandardSchemaV1.InferOutput<S>>> {
  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch (err) {
    return { ok: false, issues: [`not JSON: ${err instanceof Error ? err.message : String(err)}`] };
  }
  const result = await schema['~standard'].validate(json);
  if (result.issues) {
    return { ok: false, issues: result.issues.map((issue) => `${issue.path?.map((p) => (typeof p === 'object' ? p.key : p)).join('.') ?? ''}: ${issue.message}`) };
  }
  return { ok: true, value: result.value };
}

// The same payload type, three libraries
const zodSchema = z.object({ target: z.string().min(1), timestamp: z.iso.datetime() });
const valibotSchema = v.object({ target: v.pipe(v.string(), v.minLength(1)), timestamp: v.pipe(v.string(), v.isoTimestamp()) });
const arktypeSchema = type({ target: 'string > 0', timestamp: 'string.date.iso' });

type NavigateToPlanet = { target: string; timestamp: string };
type _1 = Expect<Equal<StandardSchemaV1.InferOutput<typeof zodSchema>, NavigateToPlanet>>;
type _2 = Expect<Equal<StandardSchemaV1.InferOutput<typeof valibotSchema>, NavigateToPlanet>>;
type _3 = Expect<Equal<StandardSchemaV1.InferOutput<typeof arktypeSchema>, NavigateToPlanet>>;

const messages = ['{"target":"saturn","timestamp":"2026-09-15T12:00:00Z"}', '{"target":"","timestamp":"yesterday"}', '{"target":'];
for (const [name, schema] of [['zod', zodSchema], ['valibot', valibotSchema], ['arktype', arktypeSchema]] as const) {
  for (const message of messages) {
    const parsed = await parseJson(schema, message);
    console.log(`${name.padEnd(8)} ${parsed.ok ? `ok: ${parsed.value.target}` : parsed.issues.join(' | ')}`);
  }
}
