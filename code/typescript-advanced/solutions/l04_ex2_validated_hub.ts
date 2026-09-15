// solutions/l04_ex2_validated_hub.ts
import type { StandardSchemaV1 } from '@standard-schema/spec';
import * as z from 'zod';

interface HubConnection {
  on(methodName: string, newMethod: (...args: any[]) => any): void;
}

// The table of lesson 1 now holds schemas, and the payload types are derived from them
const governanceHubEvents = {
  NavigateToPlanet: z.object({ target: z.string().min(1), timestamp: z.iso.datetime() }),
  NodeChanged: z.object({ nodeId: z.string().min(1), healthStatus: z.string(), color: z.string() }),
} satisfies Record<string, StandardSchemaV1>;
type Events = typeof governanceHubEvents;
type Payload<K extends keyof Events> = StandardSchemaV1.InferOutput<Events[K]>;

// The handler receives validated data only; an invalid message goes to onInvalid, with the issues
function on<K extends keyof Events & string>(connection: HubConnection, name: K, handler: (data: Payload<K>) => void, onInvalid: (name: string, issues: readonly StandardSchemaV1.Issue[]) => void): void {
  const schema: StandardSchemaV1<unknown, Payload<K>> = governanceHubEvents[name];
  connection.on(name, (data: unknown) => {
    const result = schema['~standard'].validate(data);
    if (result instanceof Promise) throw new TypeError(`${name}: asynchronous schemas are not supported here`);
    if (result.issues) onInvalid(name, result.issues);
    else handler(result.value);
  });
}

const handlers = new Map<string, (data: unknown) => void>();
const connection: HubConnection = { on: (name, handler) => void handlers.set(name, handler) };
const reportInvalid = (name: string, issues: readonly StandardSchemaV1.Issue[]) => console.log(`invalid ${name}: ${issues.map((i) => i.message).join('; ')}`);

on(connection, 'NavigateToPlanet', (data) => console.log(`navigate to ${data.target}`), reportInvalid);
on(connection, 'NodeChanged', (data) => console.log(`node ${data.nodeId} is ${data.healthStatus}`), reportInvalid);

handlers.get('NavigateToPlanet')?.({ target: 'saturn', timestamp: '2026-09-15T12:00:00Z' });
handlers.get('NavigateToPlanet')?.({ planet: 'saturn' });
handlers.get('NodeChanged')?.({ nodeId: 'policy-7', healthStatus: 'warning', color: '#FFB300' });
