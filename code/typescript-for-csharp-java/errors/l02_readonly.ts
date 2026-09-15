// errors/l02_readonly.ts
interface Tuning {
  readonly name: string;
  readonly notes: readonly string[];
}

const standard: Tuning = { name: 'standard', notes: ['E', 'A', 'D', 'G', 'B', 'E'] };
standard.name = 'drop D';
standard.notes[0] = 'D';
standard.notes.push('A');
console.log(standard);
