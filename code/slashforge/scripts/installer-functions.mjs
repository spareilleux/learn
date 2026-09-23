// Calls the installer's own functions, which bin/install.js exports: where a command file becomes a slash
// command's name, where the two install modes put their files, and what the frontmatter check refuses.
// Loading the module does not run the installer: its entry point is guarded by `require.main === module`.
import { createRequire } from 'node:module';
import path from 'node:path';

const require = createRequire(import.meta.url);
const sf = require('slashforge/bin/install.js');

console.log('# A file path under commands/ becomes the name you type');
for (const file of [...sf.COMMAND_FILES, ...sf.SKILL_FILES]) {
  console.log(`${file.split(path.sep).join('/').padEnd(30)} ${sf.commandName(file)}`);
}

console.log('\n# The two install modes');
const global = sf.resolveTarget({ homeDir: path.resolve('/home/ada') });
const project = sf.resolveTarget({ project: true, cwd: path.resolve('/src/app') });
for (const [label, t] of [['global', global], ['project', project]]) {
  console.log(`${label.padEnd(8)} guides   ${t.guidesDir}`);
  console.log(`${label.padEnd(8)} commands ${t.commandsDir}`);
  console.log(`${label.padEnd(8)} {{INSTALL_PATH}} = ${t.installPath}`);
}

console.log('\n# What the frontmatter check refuses');
const samples = [
  ['no opening fence', 'name: /demo\ndescription: d\n---\n'],
  ['no closing fence', '---\nname: /demo\ndescription: d\n'],
  ['no description', '---\nname: /demo\n---\n'],
  ['a key with a space', '---\nname: /demo\nlong description: d\n---\n'],
  ['a closing fence with a trailing space', '---\nname: /demo\ndescription: d\n--- \n'],
  ['a folded YAML description', '---\nname: /demo\ndescription: >\n  two lines\n  of text\n---\n'],
  ['valid', '---\nname: /demo\ndescription: d\n---\nbody\n'],
];
for (const [label, content] of samples) {
  try {
    const fm = sf.parseFrontmatter(content, 'demo.md');
    console.log(`${label}: ok ${JSON.stringify(fm)}`);
  } catch (err) {
    console.log(`${label}: ${err.message}`);
  }
}
