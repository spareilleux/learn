// solutions/l03_ex1_tie.ts
type MusicEvent =
  | { kind: 'note'; pitch: number; beats: number }
  | { kind: 'chord'; pitches: number[]; beats: number }
  | { kind: 'rest'; beats: number }
  | { kind: 'tie'; beats: number };

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
    case 'tie':
      return `tie for ${event.beats}`;
    default:
      return assertNever(event);
  }
}

// beatsOf needs no switch at all: every member has beats
function beatsOf(event: MusicEvent): number {
  return event.beats;
}

const bar: MusicEvent[] = [
  { kind: 'note', pitch: 60, beats: 2 },
  { kind: 'tie', beats: 1 },
  { kind: 'rest', beats: 1 },
];
console.log(bar.map(describe), bar.reduce((sum, event) => sum + beatsOf(event), 0));
