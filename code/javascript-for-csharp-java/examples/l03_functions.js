// Lesson 3: three ways to write a function, and what a call checks (almost nothing)
import { show } from './show.js';

function add(a, b) {
  return a + b;
}
const subtract = function (a, b) {
  return a - b;
};
const multiply = (a, b) => a * b;

show('add(2, 3)', add(2, 3));
show('subtract(2, 3)', subtract(2, 3));
show('multiply(2, 3)', multiply(2, 3));

// Too few or too many arguments: no error
show('add(2)', add(2));
show('add(2, 3, 4)', add(2, 3, 4));
show('add.length', add.length);

// Default values and rest parameters
function greet(name = 'reader', ...titles) {
  return `Hello, ${[...titles, name].join(' ')}!`;
}
show('greet()', greet());
show("greet('Hopper', 'Admiral')", greet('Hopper', 'Admiral'));
show('greet(undefined)', greet(undefined));
show('greet(null)', greet(null));

// No overloading: in a function body, the second declaration replaces the first
function overloads() {
  function describe(page) {
    return `page ${page}`;
  }
  function describe(page, locale) {
    return `page ${page} in ${locale}`;
  }
  return describe('mission');
}
show('overloads()', overloads());

// Functions are objects: they can be stored, passed and given properties
const operations = { add, subtract, multiply };
show('Object.keys(operations)', Object.keys(operations));
// map calls its callback with (element, index, array): extra arguments are silently used
show('[1, 2, 3].map(multiply)', [1, 2, 3].map(multiply));
show("['1', '2', '3'].map(parseInt)", ['1', '2', '3'].map(parseInt));
show('typeof add', typeof add);
show('add.name', add.name);
