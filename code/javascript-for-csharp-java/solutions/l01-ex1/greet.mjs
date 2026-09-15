// Lesson 1, exercise 1: greet.js of l01-cjs, rewritten as an ES module
const punctuation = '!';

export function hello(name) {
  return `Hello, ${capitalize(name)}${punctuation}`;
}

function capitalize(text) {
  return text.charAt(0).toUpperCase() + text.slice(1);
}
