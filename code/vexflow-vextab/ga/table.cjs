// node ga/table.cjs <ga-fsharp.txt> <VexTab results folder>
// The table of lesson 4: for each text, what GA's F# parser says and what VexTab 4.0.5 says, and, when GA's parser
// accepts the text, whether VexTab reads what GA's generator writes back.
const fs = require('node:fs');

const [fsharp, jsDir] = process.argv.slice(2);
const cases = [];
for (const block of fs.readFileSync(fsharp, 'utf8').replace(/\r\n/g, '\n').split(/^== /m).slice(1)) {
  const lines = block.split('\n');
  const [, id, source] = /^(\S+) \((.*)\)$/.exec(lines[0]);
  const text = lines.filter((l) => l.startsWith('   ')).map((l) => l.slice(3));
  const parse = lines.find((l) => l.startsWith('parse: ')).slice(7);
  const roundTrip = lines.find((l) => l.startsWith('round trip: '));
  cases.push({ id, source, text, parse, roundTrip: roundTrip && roundTrip.slice(12) });
}

const short = (result) => {
  if (result.startsWith('ok')) return result.startsWith('ok,') ? 'ok' : result;
  const at = /Ln: (\d+) Col: (\d+)/.exec(result) ?? /line (\d+)(?: column (\d+))?/.exec(result);
  return at ? `error, line ${at[1]}${at[2] ? ` col. ${at[2]}` : ''}` : 'error';
};
const vextab = (id) => {
  const r = fs.readFileSync(`${jsDir}/${id}.txt`, 'utf8').split('\n')[0];
  return r.startsWith('ok') ? 'ok' : short(r);
};

console.log('| Case | Text | GA `parse` | VexTab 4.0.5 | GA `generate`, read back by GA / by VexTab |');
console.log('|---|---|---|---|---|');
for (const c of cases) {
  const text = c.text.map((l) => '`' + l.replace(/\|/g, '\\|') + '`').join('<br/>');
  const generated = fs.existsSync(`${jsDir}/${c.id}-generated.txt`)
    ? `${c.roundTrip.startsWith('same') ? 'ok' : short(c.roundTrip)} / ${vextab(c.id + '-generated')}`
    : '—';
  console.log(`| ${c.id} | ${text} | ${short(c.parse)} | ${vextab(c.id)} | ${generated} |`);
}
