// examples/l01_hub_events.ts
// GuitarAlchemist/ga's governance hub, typed from one table of events instead of one annotation per handler
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

interface HealthMetrics {
  resilienceScore: number;
  lolliCount: number;
  ergolCount: number;
}
interface GovernanceNode {
  id: string;
  name: string;
  health?: HealthMetrics;
}

// What GovernanceHub.cs sends to the client, event by event, as SignalR serializes it (camelCase property names)
interface GovernanceHubEvents {
  GraphUpdate: { nodes: GovernanceNode[]; timestamp: string };
  NodeChanged: { nodeId: string; health: HealthMetrics; healthStatus: string; color: string; timestamp: string };
  Connected: { message: string; connections: number; timestamp: string };
  NavigateToPlanet: { target: string; timestamp: string };
  RequestScreenshot: { reason: string; timestamp: string };
  CameraSync: { px: number; py: number; pz: number; lx: number; ly: number; lz: number; sender: string };
}
// What the client can call on the hub: parameter lists as labeled tuples
interface GovernanceHubMethods {
  Subscribe: [];
  SubmitScreenshot: [base64Image: string, format: string];
  SyncCamera: [px: number, py: number, pz: number, lx: number, ly: number, lz: number];
}

// The part of @microsoft/signalr's HubConnection used here: every name is a string, every argument any
interface HubConnection {
  on(methodName: string, newMethod: (...args: any[]) => any): void;
  invoke<T = any>(methodName: string, ...args: any[]): Promise<T>;
}

// A typed layer over it: the name is a key of the table, and the handler's parameter is looked up from that key
function on<K extends keyof GovernanceHubEvents>(connection: HubConnection, name: K, handler: (data: GovernanceHubEvents[K]) => void): void {
  connection.on(name, handler);
}
function invoke<K extends keyof GovernanceHubMethods>(connection: HubConnection, name: K, ...args: GovernanceHubMethods[K]): Promise<void> {
  return connection.invoke(name, ...args);
}

// GA's LiveDataConfig lists its callbacks by hand; key remapping derives them from the table
type Callbacks<Events> = { [K in keyof Events & string as `on${K}`]?: (data: Events[K]) => void };
type GovernanceCallbacks = Callbacks<GovernanceHubEvents>;
type _1 = Expect<Equal<keyof GovernanceCallbacks, 'onGraphUpdate' | 'onNodeChanged' | 'onConnected' | 'onNavigateToPlanet' | 'onRequestScreenshot' | 'onCameraSync'>>;

// One loop registers every callback that the caller provided
const eventNames = ['GraphUpdate', 'NodeChanged', 'Connected', 'NavigateToPlanet', 'RequestScreenshot', 'CameraSync'] as const satisfies readonly (keyof GovernanceHubEvents)[];
type _2 = Expect<Equal<(typeof eventNames)[number], keyof GovernanceHubEvents>>;
function subscribe(connection: HubConnection, callbacks: GovernanceCallbacks): void {
  for (const name of eventNames) {
    const callback = callbacks[`on${name}`];
    if (callback) connection.on(name, callback);
  }
}

// A fake connection that records the handlers and lets the example play the server's part
const handlers = new Map<string, (...args: any[]) => any>();
const connection: HubConnection = {
  on: (methodName, newMethod) => void handlers.set(methodName, newMethod),
  invoke: (methodName, ...args) => {
    console.log(`invoke ${methodName}(${args.join(', ')})`);
    return Promise.resolve() as Promise<never>; // a fake: every call resolves with undefined, whatever T the caller expects
  },
};
const serverSends = (name: string, data: unknown) => handlers.get(name)?.(data);

subscribe(connection, {
  onNavigateToPlanet: (data) => console.log(`navigate to ${data.target}`),
  onNodeChanged: (data) => console.log(`node ${data.nodeId} is now ${data.healthStatus}`),
});
on(connection, 'Connected', (data) => console.log(`${data.connections} clients connected`));

serverSends('NavigateToPlanet', { target: 'saturn', timestamp: '2026-09-15T12:00:00Z' });
serverSends('NodeChanged', { nodeId: 'policy-7', health: { resilienceScore: 0.4, lolliCount: 0, ergolCount: 3 }, healthStatus: 'warning', color: '#FFB300', timestamp: '2026-09-15T12:00:01Z' });
serverSends('Connected', { message: 'Connected to Governance Hub', connections: 2, timestamp: '2026-09-15T12:00:02Z' });
await invoke(connection, 'SyncCamera', 0, 2, 10, 0, 0, 0);
show('registered handlers', [...handlers.keys()]);
