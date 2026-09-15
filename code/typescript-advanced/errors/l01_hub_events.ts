// errors/l01_hub_events.ts
// The mistakes that GA's string-based handlers let through, reported by the typed layer
interface GovernanceHubEvents {
  NodeChanged: { nodeId: string; healthStatus: string; color: string; timestamp: string };
  NavigateToPlanet: { target: string; timestamp: string };
  RequestScreenshot: { reason: string; timestamp: string };
}
interface GovernanceHubMethods {
  SyncCamera: [px: number, py: number, pz: number, lx: number, ly: number, lz: number];
}
interface HubConnection {
  on(methodName: string, newMethod: (...args: any[]) => any): void;
  invoke<T = any>(methodName: string, ...args: any[]): Promise<T>;
}
declare const connection: HubConnection;
function on<K extends keyof GovernanceHubEvents>(name: K, handler: (data: GovernanceHubEvents[K]) => void): void {
  connection.on(name, handler);
}
function invoke<K extends keyof GovernanceHubMethods>(name: K, ...args: GovernanceHubMethods[K]): Promise<void> {
  return connection.invoke(name, ...args);
}
type Callbacks<Events> = { [K in keyof Events & string as `on${K}`]?: (data: Events[K]) => void };

// The untyped API accepts all of these
connection.on('NodeChange', (data: { id: string }) => console.log(data.id));

// The typed layer doesn't
on('NodeChange', (data) => console.log(data));
on('NodeChanged', (data) => console.log(data.id));
invoke('SyncCamera', 0, 2, 10);
const callbacks: Callbacks<GovernanceHubEvents> = {
  onScreenshotRequest: (data) => console.log(data.reason),
};
