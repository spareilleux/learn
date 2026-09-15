// An ES module can import a CommonJS module: module.exports becomes the default export
import legacy, { half } from './legacy.cjs';

console.log('default import:', legacy);
console.log('named import:  ', half(3));
