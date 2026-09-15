// examples/l02_inference.ts
// tsc --declaration writes the types it inferred into l02_inference.d.ts (see check.sh)
export let count = 1;
export const tuning = 'EADGBE';
export const strings = ['E', 'A', 'D', 'G', 'B', 'E'];
export const capo = { fret: 2, label: 'capo' };
export const frozen = Object.freeze({ fret: 2, label: 'capo' });
export const literal = { fret: 2, label: 'capo' } as const;
export const mixed = [1, 'two', null];
export const pair: [string, number] = ['capo', 2];
export function fretOf(label: string) {
  return label === 'capo' ? capo.fret : undefined;
}
export const parsed = JSON.parse('{"fret": 2}');
