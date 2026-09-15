// examples/l03_discriminated.ts
import { show } from './show.ts';

// A discriminated union: every member has a kind, with a different literal type
type MusicEvent =
  | { kind: 'note'; pitch: number; beats: number }
  | { kind: 'chord'; pitches: number[]; beats: number }
  | { kind: 'rest'; beats: number };

function assertNever(value: never): never {
  throw new Error(`unexpected event: ${JSON.stringify(value)}`);
}

function describe(event: MusicEvent): string {
  switch (event.kind) {
    case 'note':
      return `note ${event.pitch} for ${event.beats}`;
    case 'chord':
      return `chord of ${event.pitches.length} for ${event.beats}`;
    case 'rest':
      return `rest for ${event.beats}`;
    default:
      return assertNever(event); // event is never here: every kind is handled
  }
}

const bar: MusicEvent[] = [
  { kind: 'chord', pitches: [48, 52, 55], beats: 2 },
  { kind: 'note', pitch: 60, beats: 1 },
  { kind: 'rest', beats: 1 },
];
for (const event of bar) show(event.kind, describe(event));

// The check that tsc did at compile time still runs, for data that didn't go through tsc
const fromServer = JSON.parse('{"kind": "tie", "beats": 1}') as MusicEvent;
try {
  describe(fromServer);
} catch (err) {
  show('describe(fromServer)', err instanceof Error ? err.message : err);
}
