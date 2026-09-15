// solutions/l04_ex1_group_by.ts
function groupBy<T, K extends PropertyKey>(items: readonly T[], keyOf: (item: T) => K): Partial<Record<K, T[]>> {
  const groups: Partial<Record<K, T[]>> = {};
  for (const item of items) {
    const key = keyOf(item);
    (groups[key] ??= []).push(item);
  }
  return groups;
}

interface Chord {
  name: string;
  quality: 'major' | 'minor' | 'diminished';
}
const chords: Chord[] = [
  { name: 'C', quality: 'major' },
  { name: 'Dm', quality: 'minor' },
  { name: 'Em', quality: 'minor' },
  { name: 'F', quality: 'major' },
  { name: 'Bdim', quality: 'diminished' },
];
const byQuality = groupBy(chords, (chord) => chord.quality); // K is 'major' | 'minor' | 'diminished'
console.log(byQuality.minor?.map((chord) => chord.name));
console.log(Object.keys(groupBy(chords, (chord) => chord.name.length)));
