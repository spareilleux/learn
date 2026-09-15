// errors/l02_index.ts
// tsc options: --noUncheckedIndexedAccess
const strings: string[] = ['E', 'A', 'D', 'G', 'B', 'E'];
const seventh: string = strings[6];
const record: Record<string, number> = { E: 2 };
const count: number = record['A'];
console.log(seventh.toLowerCase(), count + 1);
