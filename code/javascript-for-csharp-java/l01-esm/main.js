// "type": "module" in package.json: .js files are ES modules
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import farewell, { hello } from './greet.js'; // the extension is required

const names = process.argv.length > 2 ? process.argv.slice(2) : ['world'];
for (const name of names) {
  console.log(hello(name));
}
console.log(farewell(names[0]));

// No __dirname in an ES module: import.meta gives the module's own location
const manifest = JSON.parse(await readFile(path.join(import.meta.dirname, 'package.json'), 'utf8')); // top-level await
console.log(`${manifest.name}: ${path.basename(import.meta.filename)}, typeof require = ${typeof require}`);
