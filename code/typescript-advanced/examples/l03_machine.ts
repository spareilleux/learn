// examples/l03_machine.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// GA's live connection in DataLoader.ts: SignalR first, HTTP polling as a fallback, three mutable variables
// (active, connection, pollInterval) and a status reported as 'connected' | 'polling' | 'disconnected'.
// A transition table, checked by satisfies and kept literal by as const
const liveTransitions = {
  stopped: { start: 'connecting' },
  connecting: { connected: 'connected', failed: 'polling', stop: 'stopped' },
  connected: { dropped: 'reconnecting', stop: 'stopped' },
  reconnecting: { reconnected: 'connected', closed: 'polling', stop: 'stopped' },
  polling: { stop: 'stopped' },
} as const satisfies Record<string, Record<string, string>>;

type Transitions = typeof liveTransitions;
type LiveState = keyof Transitions;
type EventOf<S extends LiveState> = keyof Transitions[S];
type Next<S extends LiveState, E extends EventOf<S>> = Transitions[S][E];

// Every target of the table is a state: a typo in a target would make this test fail
type Targets = { [S in LiveState]: Transitions[S][keyof Transitions[S]] }[LiveState];
type _1 = Expect<Equal<[Targets] extends [LiveState] ? true : false, true>>;
type _2 = Expect<Equal<EventOf<'connected'>, 'dropped' | 'stop'>>;
type _3 = Expect<Equal<Next<'connecting', 'failed'>, 'polling'>>;

// send accepts only the events of the current state, and its result type is the next state
function send<S extends LiveState, E extends EventOf<S>>(state: S, event: E): Next<S, E> {
  const targets: Record<string, string> = liveTransitions[state];
  return targets[event as string] as Next<S, E>; // an assertion: the lookup is the one the type describes
}

const s1 = send('stopped', 'start');
const s2 = send(s1, 'connected');
const s3 = send(s2, 'dropped');
const s4 = send(s3, 'closed');
type _4 = Expect<Equal<typeof s4, 'polling'>>;
show('stopped → … → s4', [s1, s2, s3, s4]);

// A state known only at run time is a union: send accepts the events that every member of the union allows
type _5 = Expect<Equal<EventOf<LiveState>, never>>; // stopped has no stop event
function stop(state: Exclude<LiveState, 'stopped'>) {
  return send(state, 'stop');
}
type _6 = Expect<Equal<ReturnType<typeof stop>, 'stopped'>>;
show("stop('reconnecting')", stop('reconnecting'));

// What the table says, listed at run time
for (const [state, events] of Object.entries(liveTransitions)) {
  console.log(`${state.padEnd(13)} ${Object.entries(events).map(([event, next]) => `${event} → ${next}`).join(', ')}`);
}
