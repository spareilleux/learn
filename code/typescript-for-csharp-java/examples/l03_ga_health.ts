// examples/l03_ga_health.ts
import { show } from './show.ts';

// types.ts, line 34: the statuses the front end knows
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
interface GovernanceNode {
  id: string;
  healthStatus?: GovernanceHealthStatus;
}

// DataLoader.ts, lines 276-278: a SignalR message typed with a string, passed on with a double assertion
function onNodeChanged(data: { nodeId: string; healthStatus: string }): GovernanceNode {
  return data as unknown as GovernanceNode;
}

// ForceRadiant.tsx, lines 720-729, reduced: the statuses 'ok' and 'critical' can't be in the union
function prediction(node: GovernanceNode): string {
  const status: string = node.healthStatus ?? 'unknown'; // widened to string, or tsc reports TS2367 below
  if (status === 'healthy' || status === 'ok') return 'stable';
  if (status === 'warning') return 'at risk';
  if (status === 'error' || status === 'critical') return 'failing';
  return 'uncertain';
}

const node = onNodeChanged({ nodeId: 'policy-7', healthStatus: 'critical' });
show('node.healthStatus', node.healthStatus);
show('prediction(node)', prediction(node));
const known: readonly string[] = ['error', 'warning', 'healthy', 'unknown', 'contradictory'];
show('known.includes(node.healthStatus)', known.includes(node.healthStatus ?? 'unknown'));
