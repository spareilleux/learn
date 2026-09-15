// Lesson 3: a CommonJS file isn't strict unless it asks, and a plain call gets the global object as this
function sloppy() {
  return this === globalThis;
}
function strict() {
  'use strict';
  return this;
}
console.log('sloppy() gets globalThis:', sloppy());
console.log('strict() gets:', strict());
console.log('this at the top of a CommonJS file is module.exports:', this === module.exports);

// Without strict mode, a typo creates a global variable
function typo() {
  totl = 42;
}
typo();
console.log('globalThis.totl:', globalThis.totl);
