// examples/show.ts
import { inspect } from 'node:util';

export function show(label: string, value: unknown): void {
  console.log(`${label.padEnd(34)} ${inspect(value)}`);
}

export function attempt(label: string, fn: () => unknown): void {
  try {
    show(label, fn());
  } catch (err) {
    // err is unknown: anything can be thrown, not only an Error (lesson 3 narrows it)
    console.log(`${label.padEnd(34)} ${err instanceof Error ? `${err.name}: ${err.message}` : String(err)}`);
  }
}
