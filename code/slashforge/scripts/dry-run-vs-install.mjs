// Compares the files `slashforge --dry-run` says it will write with the files the install actually wrote.
// Usage: node dry-run-vs-install.mjs <dry-run output> <file list>
// Both inputs are check.sh's normalized outputs, where the throwaway home directory is written `~`.
import { readFileSync } from 'node:fs';

const [dryRunFile, fileListFile] = process.argv.slice(2);

// A planned write is a line of the form "  copy   forge-rules.md   → ~/.claude/setup/slashforge/forge-rules.md".
const planned = readFileSync(dryRunFile, 'utf8')
  .split('\n')
  .filter((line) => line.includes('→'))
  .map((line) => line.split('→')[1].trim());

// The file list comes from `find . -type f` run in the home directory: "./.claude/..." becomes "~/.claude/...".
const written = readFileSync(fileListFile, 'utf8')
  .split('\n')
  .filter(Boolean)
  .map((line) => line.replace(/^\.\//, '~/'));

const plannedSet = new Set(planned);
const writtenSet = new Set(written);
const notAnnounced = written.filter((f) => !plannedSet.has(f));
const notWritten = planned.filter((f) => !writtenSet.has(f));

console.log(`dry-run lists ${planned.length} files`);
console.log(`install wrote ${written.length} files`);
console.log(`written but not in the dry-run (${notAnnounced.length}):`);
for (const f of notAnnounced) console.log(`  ${f}`);
console.log(`in the dry-run but not written (${notWritten.length}):`);
for (const f of notWritten) console.log(`  ${f}`);
