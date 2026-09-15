// solutions/l03_ex2_remote_data.ts
// GA's components keep [loading, setLoading], [error, setError] and [data, setData] side by side;
// one union replaces the three, and fold makes every caller handle every state
type RemoteData<T, E = string> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'failure'; error: E };

// One handler per status, each receiving its own member of the union: a mapped type over the discriminant
type Handlers<T, E, R> = { [S in RemoteData<T, E>['status']]: (state: Extract<RemoteData<T, E>, { status: S }>) => R };

function fold<T, E, R>(state: RemoteData<T, E>, handlers: Handlers<T, E, R>): R {
  // An assertion: tsc can't correlate handlers[state.status] with state, a known limit for unions indexed this way
  const handler = handlers[state.status] as (state: RemoteData<T, E>) => R;
  return handler(state);
}

interface Voicing {
  name: string;
  frets: string;
}
const render = (state: RemoteData<Voicing[]>) =>
  fold(state, {
    idle: () => 'search for a chord',
    loading: () => 'searching…',
    success: ({ data }) => data.map((v) => `${v.name} ${v.frets}`).join(', '),
    failure: ({ error }) => `search failed: ${error}`,
  });

const states: RemoteData<Voicing[]>[] = [
  { status: 'idle' },
  { status: 'loading' },
  { status: 'success', data: [{ name: 'C', frets: 'x32010' }, { name: 'C/G', frets: '332010' }] },
  { status: 'failure', error: 'HTTP 503' },
];
for (const state of states) console.log(render(state));

function mistakes(state: RemoteData<Voicing[]>) {
  // @ts-expect-error: the failure handler is missing
  fold(state, { idle: () => '', loading: () => '', success: () => '' });
}
console.log(typeof mistakes);
