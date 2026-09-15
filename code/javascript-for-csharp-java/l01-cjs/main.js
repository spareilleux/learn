// "type": "commonjs" in package.json: .js files are CommonJS modules
const fs = require('node:fs');
const path = require('node:path');
const { hello } = require('./greet'); // the extension can be left out

const names = process.argv.length > 2 ? process.argv.slice(2) : ['world'];
for (const name of names) {
  console.log(hello(name));
}

const manifest = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8'));
console.log(`${manifest.name}: ${path.basename(__filename)}, typeof require = ${typeof require}`);
