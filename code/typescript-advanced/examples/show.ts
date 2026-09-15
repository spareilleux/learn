// examples/show.ts
import { inspect } from 'node:util';

export function show(label: string, value: unknown): void {
  console.log(`${label.padEnd(34)} ${inspect(value, { depth: 4, breakLength: 100 })}`);
}

export function attempt(label: string, fn: () => unknown): void {
  try {
    show(label, fn());
  } catch (err) {
    console.log(`${label.padEnd(34)} ${err instanceof Error ? `${err.name}: ${err.message}` : String(err)}`);
  }
}
