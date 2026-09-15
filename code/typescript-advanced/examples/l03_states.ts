// examples/l03_states.ts
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// GA's ChatWidget.tsx keeps the voice input in two pieces of state that can disagree:
//   const [isListening, setIsListening] = useState(false);
//   const [voiceState, setVoiceState] = useState<'idle' | 'listening' | 'processing' | 'understood'>('idle');
interface LooseVoice {
  isListening: boolean;
  voiceState: 'idle' | 'listening' | 'processing' | 'understood';
  transcript?: string;
  error?: string;
}
// 2 × 4 × 2 × 2 = 32 combinations, and most of them mean nothing: listening and idle, an error while understood…
const contradictory: LooseVoice = { isListening: false, voiceState: 'listening', error: 'network' };
show('contradictory', contradictory);

// One discriminated union: each state carries exactly the data that exists in that state
type Voice =
  | { status: 'idle' }
  | { status: 'listening'; startedAt: number }
  | { status: 'processing'; transcript: string }
  | { status: 'understood'; transcript: string }
  | { status: 'failed'; transcript: string; error: string };

// The events that move it, also a union
type VoiceEvent =
  | { type: 'start'; at: number }
  | { type: 'final-result'; transcript: string }
  | { type: 'sent' }
  | { type: 'send-failed'; error: string }
  | { type: 'stop' }
  | { type: 'reset' };

// The transitions, as a reducer: every state handles every event, and an event that doesn't apply keeps the state
function transition(state: Voice, event: VoiceEvent): Voice {
  switch (state.status) {
    case 'idle':
      return event.type === 'start' ? { status: 'listening', startedAt: event.at } : state;
    case 'listening':
      if (event.type === 'final-result') return { status: 'processing', transcript: event.transcript };
      return event.type === 'stop' ? { status: 'idle' } : state;
    case 'processing':
      if (event.type === 'sent') return { status: 'understood', transcript: state.transcript };
      return event.type === 'send-failed' ? { status: 'failed', transcript: state.transcript, error: event.error } : state;
    case 'understood':
    case 'failed':
      return event.type === 'reset' ? { status: 'idle' } : state;
    default:
      return assertNever(state);
  }
}
function assertNever(value: never): never {
  throw new Error(`unexpected state: ${JSON.stringify(value)}`);
}

// Rendering reads the data that the state guarantees, without optional checks
function label(state: Voice): string {
  switch (state.status) {
    case 'idle':
      return 'mic off';
    case 'listening':
      return `listening since ${state.startedAt} ms`;
    case 'processing':
      return `sending "${state.transcript}"`;
    case 'understood':
      return `understood "${state.transcript}"`;
    case 'failed':
      return `could not send "${state.transcript}": ${state.error}`;
  }
}

const events: VoiceEvent[] = [
  { type: 'start', at: 120 },
  { type: 'final-result', transcript: 'show me drop D voicings' },
  { type: 'send-failed', error: 'HTTP 503' },
  { type: 'sent' }, // ignored: a failed request can't succeed afterwards
  { type: 'reset' },
];
let state: Voice = { status: 'idle' };
for (const event of events) {
  state = transition(state, event);
  console.log(`${event.type.padEnd(13)} → ${label(state)}`);
}

// The number of possible values is now the number of states
type _1 = Expect<Equal<Voice['status'], 'idle' | 'listening' | 'processing' | 'understood' | 'failed'>>;
