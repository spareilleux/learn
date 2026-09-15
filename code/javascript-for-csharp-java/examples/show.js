// show prints a label, padded, then the value as Node's REPL would: strings in quotes, -0 as -0, 10n as 10n
import { inspect } from 'node:util';

export function show(label, value) {
  console.log(`${label.padEnd(34)} ${inspect(value)}`);
}

// attempt runs a function and prints its result, or the name and message of the error it throws
export function attempt(label, fn) {
  try {
    show(label, fn());
  } catch (err) {
    console.log(`${label.padEnd(34)} ${err.name}: ${err.message}`);
  }
}
