// errors/l04_result.ts
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
type LoadError = { kind: 'network'; cause: unknown } | { kind: 'http'; status: number } | { kind: 'invalid-json'; message: string };
declare function loadGraph(url: string): Promise<Result<{ nodes: string[] }, LoadError>>;

const result = await loadGraph('/api/governance');
console.log(result.value.nodes); // the value exists only when ok is true

function describe(error: LoadError): string {
  switch (error.kind) {
    case 'network':
      return 'offline';
    case 'http':
      return `HTTP ${error.status}`;
    default:
      return error satisfies never; // invalid-json is not handled
  }
}

try {
  JSON.parse('<!doctype html>');
} catch (e) {
  console.log(e.message, describe({ kind: 'http', status: 500 }));
}
