// Lesson 3: a closure keeps the variables of its scope alive, not copies of their values
import { attempt, show } from './show.js';

function counter() {
  let count = 0; // private: only the returned functions can reach it
  return {
    increment: () => ++count,
    current: () => count,
  };
}
const a = counter();
const b = counter();
a.increment();
a.increment();
b.increment();
show('a.current()', a.current());
show('b.current()', b.current());
show('a.count', a.count);

// The variable is captured, so a later change is visible
let label = 'draft';
const readLabel = () => label;
label = 'published';
show('readLabel()', readLabel());

// Loops: var gives one variable for the whole loop, let gives one per iteration
const withVar = [];
for (var i = 0; i < 3; i++) {
  withVar.push(() => i);
}
const withLet = [];
for (let j = 0; j < 3; j++) {
  withLet.push(() => j);
}
show('withVar, called', withVar.map((f) => f()));
show('withLet, called', withLet.map((f) => f()));

// A callback that runs later sees the value at that time
const timeline = [];
for (var k = 0; k < 3; k++) {
  setTimeout(() => timeline.push(k), 0);
}
setTimeout(() => show('timeline', timeline), 0);
attempt('k, after the loop', () => k);
