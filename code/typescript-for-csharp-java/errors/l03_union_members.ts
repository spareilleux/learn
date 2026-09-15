// errors/l03_union_members.ts
type Fret = number | 'open' | 'muted';

function describe(fret: Fret): string {
  return `fret ${fret.toFixed(0)}`;
}

console.log(describe(3), describe('open'));
