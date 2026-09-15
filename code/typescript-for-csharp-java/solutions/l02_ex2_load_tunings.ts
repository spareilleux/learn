// solutions/l02_ex2_load_tunings.ts
interface Tuning {
  name: string;
  notes: string[];
}

// JSON.parse into unknown: tsc lets nothing through until each property is checked
function loadTunings(raw: string | null): Tuning[] {
  if (raw === null) return [];
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    return [];
  }
  if (!Array.isArray(value)) return [];
  const tunings: Tuning[] = [];
  for (const item of value) {
    if (
      typeof item === 'object' &&
      item !== null &&
      typeof item.name === 'string' &&
      Array.isArray(item.notes) &&
      item.notes.every((note: unknown) => typeof note === 'string')
    ) {
      tunings.push({ name: item.name, notes: item.notes });
    }
  }
  return tunings;
}

console.log(loadTunings(null));
console.log(loadTunings('{not json'));
console.log(loadTunings('{"name": "standard"}'));
console.log(loadTunings('[{"name": "drop D", "notes": ["D","A","D","G","B","E"]}, {"name": 7}, {"name": "open", "notes": [1]}]'));
