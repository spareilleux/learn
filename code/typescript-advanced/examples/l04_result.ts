// examples/l04_result.ts
import * as z from 'zod';
import { show } from './show.ts';

// A result: success or failure, told apart by ok, with a type for each side
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
const ok = <T>(value: T): Result<T, never> => ({ ok: true, value });
const err = <E>(error: E): Result<never, E> => ({ ok: false, error });

// The failures that a caller can do something about, as a discriminated union
type LoadError =
  | { kind: 'network'; cause: unknown }
  | { kind: 'http'; status: number }
  | { kind: 'invalid-json'; message: string }
  | { kind: 'invalid-data'; issues: string[] };

const GraphSchema = z.object({
  nodes: z.array(z.object({ id: z.string(), name: z.string() })),
  timestamp: z.iso.datetime(),
});
type GovernanceGraph = z.infer<typeof GraphSchema>;

// A fake fetch, so the example runs without a server: each URL answers differently
type Fetch = (url: string) => Promise<{ ok: boolean; status: number; text(): Promise<string> }>;
const fakeFetch: Fetch = async (url) => {
  if (url.endsWith('/offline')) throw new TypeError('fetch failed');
  const bodies: Record<string, [number, string]> = {
    '/api/governance': [200, '{"nodes":[{"id":"policy-7","name":"Alignment policy"}],"timestamp":"2026-09-15T12:00:00Z"}'],
    '/api/governance/stale': [200, '{"nodes":[{"id":"policy-7"}],"timestamp":"yesterday"}'],
    '/api/governance/html': [200, '<!doctype html>'],
    '/api/governance/missing': [404, 'Not Found'],
  };
  const [status, body] = bodies[url] ?? [500, ''];
  return { ok: status < 400, status, text: async () => body };
};

// Every expected failure is returned; a bug in this function would still throw
async function loadGraph(fetch: Fetch, url: string): Promise<Result<GovernanceGraph, LoadError>> {
  let response;
  try {
    response = await fetch(url);
  } catch (cause) {
    return err({ kind: 'network', cause });
  }
  if (!response.ok) return err({ kind: 'http', status: response.status });
  let json: unknown;
  try {
    json = JSON.parse(await response.text());
  } catch (e) {
    return err({ kind: 'invalid-json', message: e instanceof Error ? e.message : String(e) });
  }
  const parsed = GraphSchema.safeParse(json);
  if (!parsed.success) return err({ kind: 'invalid-data', issues: parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`) });
  return ok(parsed.data);
}

// The caller has to look at ok before it can reach the value, and a switch over kind covers every failure
function describe(result: Result<GovernanceGraph, LoadError>): string {
  if (result.ok) return `${result.value.nodes.length} node(s) at ${result.value.timestamp}`;
  const error = result.error;
  switch (error.kind) {
    case 'network':
      return `offline (${error.cause instanceof Error ? error.cause.message : 'unknown cause'}), keeping the static graph`;
    case 'http':
      return `HTTP ${error.status}, keeping the static graph`;
    case 'invalid-json':
      return `not JSON: ${error.message}`;
    case 'invalid-data':
      return `unexpected graph: ${error.issues.join('; ')}`;
    default:
      return error satisfies never;
  }
}

for (const url of ['/api/governance', '/api/governance/offline', '/api/governance/missing', '/api/governance/html', '/api/governance/stale']) {
  console.log(`${url.padEnd(26)} ${describe(await loadGraph(fakeFetch, url))}`);
}

// Where an exception is still the right tool: an error the caller can't handle, with the original error as its cause
function requireGraph(result: Result<GovernanceGraph, LoadError>): GovernanceGraph {
  if (result.ok) return result.value;
  throw new Error(`governance graph unavailable: ${result.error.kind}`, { cause: result.error });
}
try {
  requireGraph(await loadGraph(fakeFetch, '/api/governance/missing'));
} catch (e) {
  show('caught', e instanceof Error ? [e.message, e.cause] : e);
}
