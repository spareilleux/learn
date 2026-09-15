// errors/l03_exhaustive.ts
// A new kind of event: the two functions that don't handle it are now errors
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
      return `note ${event.pitch}`;
    case 'chord':
      return `chord of ${event.pitches.length}`;
    case 'rest':
      return 'rest';
    default:
      return assertNever(event);
  }
}

function beatsOf(event: MusicEvent): number {
  switch (event.kind) {
    case 'note':
    case 'chord':
    case 'rest':
      return event.beats;
  }
}

console.log(describe({ kind: 'tie', beats: 1 }), beatsOf({ kind: 'tie', beats: 1 }));
