// Lists the files under a folder, sorted, with forward slashes, without node_modules: node scripts/files.mjs dist
import { readdirSync } from 'node:fs';
import { join, relative } from 'node:path';

const root = process.argv[2];
const names = readdirSync(root, { recursive: true, withFileTypes: true })
  .filter((entry) => entry.isFile() && !entry.parentPath.includes('node_modules'))
  .map((entry) => relative(root, join(entry.parentPath, entry.name)).replaceAll('\\', '/'));
console.log(names.sort().join('\n'));
