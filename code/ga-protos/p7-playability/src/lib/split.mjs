// Train, validation and test, split by group. Which group you choose is the whole question:
//
//   'voicing' — every row is its own group. The naive split, and the one that leaks: two fingerings of the same
//               chord, a fret apart, end up on both sides of the wall.
//   'chord'   — the group is the pitch-class set. Every voicing of a C major triad stays on one side.
//   'shape'   — the group is the fret shape with the position removed. The same grip moved up the neck is one
//               group, which is stricter still: transposition is a second way the same thing appears twice.
//
// A group is placed by a stable hash of its key, so adding rows never moves a group from one side to the other.

import { hash32 } from './random.mjs';

export const SPLIT_MODES = ['voicing', 'chord', 'shape'];

export function groupKeyFor(mode, row, index) {
  if (mode === 'voicing') return `#${index}`;
  if (mode === 'chord') return row.chord;
  if (mode === 'shape') return row.shape;
  throw new Error(`unknown split mode ${mode}`);
}

export function splitRows(rows, mode, { seed = 1717, train = 0.6, val = 0.2 } = {}) {
  const groups = rows.map((row, i) => groupKeyFor(mode, row, i));
  const parts = { train: [], val: [], test: [] };
  const seen = new Map();
  groups.forEach((key, i) => {
    let side = seen.get(key);
    if (side === undefined) {
      const u = hash32(`${seed}:${key}`) / 4294967296;
      side = u < train ? 'train' : u < train + val ? 'val' : 'test';
      seen.set(key, side);
    }
    parts[side].push(i);
  });
  return { ...parts, groups, groupCount: seen.size };
}
