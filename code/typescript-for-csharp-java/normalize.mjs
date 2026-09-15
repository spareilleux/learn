// Makes tsc, Node.js, dotnet and javac output comparable between machines: node normalize.mjs < raw.txt > out.txt
// - the ANSI colors of tsc --pretty are removed
// - absolute paths and file URLs under this folder become paths relative to it, with forward slashes
// - stack frames ("    at …") are dropped: they name Node's internal files and lines (a last frame followed by
//   the error's properties keeps its opening brace)
// - the process ID of a warning becomes PID
import { readFileSync } from 'node:fs';

const course = 'typescript-for-csharp-java';
const text = readFileSync(0, 'utf8').replaceAll('\r\n', '\n');
const pathPattern = new RegExp(String.raw`(?:file://)?(?:\\\\\?\\)?[^\s'"(]*?${course}(?:[\\/]([^\s'"(:]*))?`, 'g');

const lines = text
  .replace(/\x1b\[[0-9;]*m/g, '')
  .split('\n')
  .map((line) => (/^\s+at .* \{$/.test(line) ? '{' : line))
  .filter((line) => !/^\s+at /.test(line))
  .map((line) => line.replace(pathPattern, (_, rest) => (rest ?? '.').replaceAll('\\', '/')))
  .map((line) => line.replace(/^\(node:\d+\)/, '(node:PID)'));

process.stdout.write(lines.join('\n'));
