// No type in package.json, import syntax: Node.js detects an ES module
import { twice } from './modern.mjs';
console.log(twice(4), typeof require);
