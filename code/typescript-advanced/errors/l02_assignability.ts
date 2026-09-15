// errors/l02_assignability.ts
// tsc options: --exactOptionalPropertyTypes false
interface ViewerInfo {
  connectionId: string;
  displayName?: string;
}
interface TuningOptions {
  capo?: number;
  dropD?: boolean;
}
interface Guitar {
  name: string;
  strings: number;
}
interface SafeSlot<in out T> {
  value: T;
}

// exactOptionalPropertyTypes: undefined is not a value of an optional property
const explicit: ViewerInfo = { connectionId: 'a1', displayName: undefined };
const patch: Partial<ViewerInfo> = { displayName: undefined };

// A weak type: no property in common
const theme = { theme: 'dark', fontSize: 14 };
const options: TuningOptions = theme;

// An assertion between types that don't overlap
const guitar = { name: 'guitar', strings: 6 } as Guitar;
const fret = guitar as unknown as number; // through unknown, anything goes
const tuning = guitar as string[];

// Invariance declared with in out
declare const guitarSlot: SafeSlot<Guitar>;
const namedSlot: SafeSlot<{ name: string }> = guitarSlot;

console.log(explicit, patch, options, fret, tuning, namedSlot);
