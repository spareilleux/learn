// Lesson 1, exercise 1: still CommonJS; require loads the ES module, extension included
const greet = require('./greet.mjs');

console.log(greet.hello('world'));
console.log('exports of greet.mjs:', Object.keys(greet));
