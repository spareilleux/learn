// examples/l02_satisfies.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
type HexColor = `#${string}`;

// 1. An annotation: the object is checked, and its type becomes the annotation, so the literal colors are lost
const annotated: Record<GovernanceHealthStatus, HexColor> = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
};
type _1 = Expect<Equal<(typeof annotated)['error'], HexColor>>;

// 2. satisfies: the same check, and the type stays the one inferred from the object. The literals are kept here
// because the contextual type, a template literal type, contains literal types; against string they widen
const satisfying = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
} satisfies Record<GovernanceHealthStatus, HexColor>;
type _2 = Expect<Equal<(typeof satisfying)['error'], '#FF4444'>>;
const widened = { error: '#FF4444' } satisfies Record<'error', string>;
type _2b = Expect<Equal<(typeof widened)['error'], string>>;

// 3. as const satisfies: literal values whatever the contextual type, readonly properties, and the check
const colors = {
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
} as const satisfies Record<GovernanceHealthStatus, HexColor>;
type _3 = Expect<Equal<(typeof colors)['error'], '#FF4444'>>;
type _3b = Expect<Equal<typeof colors, { readonly error: '#FF4444'; readonly warning: '#FFB300'; readonly healthy: '#33CC66'; readonly unknown: '#888888'; readonly contradictory: '#FF44FF' }>>;

// 4. as: an assertion, which checks only that one type is comparable to the other; a missing status gets through
const partial = { error: '#FF4444', healthy: '#33CC66' };
const asserted = partial as Record<GovernanceHealthStatus, HexColor>;
show('asserted.warning', asserted.warning);

// satisfies provides the contextual type: the parameter of each function is typed without an annotation
interface Formatters {
  [status: string]: (score: number) => string;
}
const formatters = {
  healthy: (score) => `healthy (${score.toFixed(2)})`,
  warning: (score) => `watch (${Math.round(score * 100)}%)`,
} satisfies Formatters;
show('formatters.healthy(0.93)', formatters.healthy(0.93));
// The inferred type keeps exactly the two keys: formatters.error would be a compile error, not undefined at run time
type _4 = Expect<Equal<keyof typeof formatters, 'healthy' | 'warning'>>;

// GA's VoxtralTTS.ts checks a request body the same way, before JSON.stringify erases everything
const body = JSON.stringify({
  model: 'voxtral-mini-tts-2603',
  input: 'The voicing index is fresh.',
  voice_id: 'demerzel',
} satisfies { model: string; input: string; voice_id: string });
show('body', body);
