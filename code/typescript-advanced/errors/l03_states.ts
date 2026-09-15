// errors/l03_states.ts
type Voice =
  | { status: 'idle' }
  | { status: 'listening'; startedAt: number }
  | { status: 'processing'; transcript: string }
  | { status: 'failed'; transcript: string; error: string };

function label(state: Voice): string {
  if (state.status === 'listening') return `sending "${state.transcript}"`;
  switch (state.status) {
    case 'idle':
      return 'mic off';
    case 'processing':
      return `sending "${state.transcript}"`;
  }
}

const liveTransitions = {
  stopped: { start: 'connecting' },
  connecting: { connected: 'connected', failed: 'poling' },
  connected: { stop: 'stopped' },
  polling: { stop: 'stopped' },
} as const satisfies Record<string, Record<string, string>>;
type Transitions = typeof liveTransitions;
type LiveState = keyof Transitions;
type EventOf<S extends LiveState> = keyof Transitions[S];
declare function send<S extends LiveState, E extends EventOf<S>>(state: S, event: E): Transitions[S][E];

const invalid: Voice = { status: 'idle', transcript: 'leftover' };
send('stopped', 'stop');
const next: LiveState = send('connecting', 'failed');
console.log(label(invalid), next);
