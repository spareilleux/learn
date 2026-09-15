// examples/l02_tuples.ts
import { show } from './show.ts';

// A tuple: a fixed length, and a type for each position
type Interval = [name: string, semitones: number];
const fifth: Interval = ['perfect fifth', 7];
const [name, semitones] = fifth;
show('name, semitones', [name, semitones]);

// An array: any length, one element type, and an index that tsc trusts
const strings: string[] = ['E', 'A', 'D', 'G', 'B', 'E'];
const seventh: string = strings[6]; // no error without noUncheckedIndexedAccess
show('seventh', seventh);
show('typeof seventh', typeof seventh);

const counts = new Map<string, number>([['E', 2]]);
const count = counts.get('A'); // Map.get admits it: number | undefined
show('count ?? 0', count ?? 0);

// Tuples are arrays at run time: nothing stops a push
fifth.push('extra');
show('fifth', fifth);
