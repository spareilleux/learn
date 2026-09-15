// examples/l02_optional.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// GA's ViewerInfo, from DataLoader.ts: the server's C# record has string? DisplayName = null and string? AvatarUrl = null
interface ViewerInfo {
  connectionId: string;
  color: string;
  displayName?: string;
  avatarUrl?: string | null;
}

// With exactOptionalPropertyTypes, ? means that the property may be absent, not that it may hold undefined
const absent: ViewerInfo = { connectionId: 'a1', color: '#58a6ff' };
const withNull: ViewerInfo = { connectionId: 'b2', color: '#3fb950', avatarUrl: null };
show("'displayName' in absent", 'displayName' in absent);
show('Object.keys(withNull)', Object.keys(withNull));

// Reading an optional property still gives undefined when it is absent
type _1 = Expect<Equal<ViewerInfo['displayName'], string | undefined>>;
// Partial<T> keeps the rule: a patch can leave a property out, and can't set it to undefined
function applyPatch(viewer: ViewerInfo, patch: Partial<ViewerInfo>): ViewerInfo {
  return { ...viewer, ...patch };
}
show('applyPatch(absent, …)', applyPatch(absent, { displayName: 'Ada' }));

// Why the rule matters: a spread copies an own property holding undefined, and erases the value
const viewer: ViewerInfo = { connectionId: 'c3', color: '#d2a8ff', displayName: 'Hari' };
const sloppyPatch = { displayName: undefined };
show('{ ...viewer, ...sloppyPatch }', { ...viewer, ...sloppyPatch });

// A weak type has only optional properties: tsc requires an argument to share at least one of them
interface TuningOptions {
  capo?: number;
  dropD?: boolean;
}
function tune(options: TuningOptions): string {
  return `capo ${options.capo ?? 0}, drop D ${options.dropD ?? false}`;
}
const fromSettings = { capo: 2, theme: 'dark' };
show('tune(fromSettings)', tune(fromSettings)); // shares capo: accepted, and theme is ignored

// null and undefined are different values, and JSON has only one of them
show('JSON.stringify(withNull)', JSON.stringify(withNull));
show("JSON.stringify(sloppyPatch)", JSON.stringify(sloppyPatch));
