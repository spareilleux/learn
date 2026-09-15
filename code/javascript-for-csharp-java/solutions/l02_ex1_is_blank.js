// Lesson 2, exercise 1: isBlank is true for null, undefined and strings of whitespace only
import { inspect } from 'node:util';
import { show } from '../examples/show.js';

function isBlank(value) {
  return value == null || (typeof value === 'string' && value.trim() === '');
}

for (const value of [null, undefined, '', '   ', '\t\n', 'text', 0, false, NaN, []]) {
  show(`isBlank(${inspect(value)})`, isBlank(value));
}
