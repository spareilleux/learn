// A CommonJS module can require an ES module without top-level await (Node.js 22.12 and later)
const modern = require('./modern.mjs');

console.log(modern);
console.log(modern.twice(21), modern.default);
