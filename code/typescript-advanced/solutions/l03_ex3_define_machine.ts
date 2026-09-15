// solutions/l03_ex3_define_machine.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

// The constraint refers to T itself: every target must be one of the table's own keys
function defineMachine<const T extends Record<string, Record<string, keyof T>>>(transitions: T): T {
  return transitions;
}

const live = defineMachine({
  stopped: { start: 'connecting' },
  connecting: { connected: 'connected', failed: 'polling', stop: 'stopped' },
  connected: { dropped: 'reconnecting', stop: 'stopped' },
  reconnecting: { reconnected: 'connected', closed: 'polling', stop: 'stopped' },
  polling: { stop: 'stopped' },
});
type _1 = Expect<Equal<(typeof live)['connecting']['failed'], 'polling'>>;

function mistakes() {
  defineMachine({
    stopped: { start: 'connecting' },
    // @ts-expect-error: 'poling' is not a state
    connecting: { failed: 'poling' },
  });
}
console.log(Object.keys(live), typeof mistakes);
