// Lesson 1: node examples/l01_hello.js Ada Grace
const names = process.argv.slice(2); // argv[0] is node, argv[1] is this file
console.log('Hello, world!');
for (const name of names) {
  console.log(`Hello, ${name}!`);
}
