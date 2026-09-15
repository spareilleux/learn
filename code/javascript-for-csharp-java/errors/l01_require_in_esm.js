// Lesson 1: require doesn't exist in an ES module (this folder's package.json says "type": "module")
const fs = require('node:fs');
console.log(fs.existsSync('package.json'));
