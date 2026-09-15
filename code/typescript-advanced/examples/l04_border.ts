// examples/l04_border.ts
// GuitarAlchemist/ga's NodeChanged handler, reduced: the payload is asserted to be a node, and the update is lost
import * as z from 'zod';
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

// DataLoader.ts, updateNodeHealth: looks each existing node up by id in the fresh nodes, and updates its health
function updateNodeHealth(existingNodes: GovernanceNode[], freshNodes: GovernanceNode[]): string[] {
  const freshMap = new Map(freshNodes.map((n) => [n.id, n]));
  const updated: string[] = [];
  for (const node of existingNodes) {
    const fresh = freshMap.get(node.id);
    if (!fresh?.health) continue;
    node.health = fresh.health;
    updated.push(node.id);
  }
  return updated;
}

const scene: GovernanceNode[] = [{ id: 'policy-7', name: 'Alignment policy', health: { resilienceScore: 0.9, lolliCount: 0, ergolCount: 3 } }];

// The message that GovernanceHub.BroadcastNodeChanged sends, as SignalR serializes it (compare/l04_hub_json.cs)
const message = '{"nodeId":"policy-7","health":{"resilienceScore":0.4,"lolliCount":0,"ergolCount":3},"healthStatus":"warning","color":"#FFB300","timestamp":"2026-09-15T12:00:01Z"}';

// DataLoader.ts, lines 276-279: the handler's parameter is annotated, then asserted to be a GovernanceNode
const data: { nodeId: string; health: unknown; healthStatus: string; color: string } = JSON.parse(message);
const asserted = updateNodeHealth(scene, [data as unknown as GovernanceNode]);
show('updated (asserted)', asserted);
show('scene[0].health.resilienceScore', scene[0]?.health?.resilienceScore);

// A schema checks the same payload at the border, and says what is wrong
const HealthMetricsSchema = z.object({
  resilienceScore: z.number().min(0).max(1),
  lolliCount: z.int().nonnegative(),
  ergolCount: z.int().nonnegative(),
});
const GovernanceNodeSchema = z.object({
  id: z.string().min(1),
  name: z.string(),
  health: HealthMetricsSchema.optional(),
});
const asNode = GovernanceNodeSchema.safeParse(JSON.parse(message));
if (!asNode.success) console.log(z.prettifyError(asNode.error));

// The schema of what the hub really sends, and the conversion to a node written once
const NodeChangedSchema = z.object({
  nodeId: z.string().min(1),
  health: HealthMetricsSchema,
  healthStatus: z.enum(['error', 'warning', 'healthy', 'unknown', 'contradictory']),
  color: z.string().regex(/^#[0-9A-F]{6}$/i),
  timestamp: z.iso.datetime(),
});
const changed = NodeChangedSchema.parse(JSON.parse(message));
const updated = updateNodeHealth(scene, [{ id: changed.nodeId, name: '', health: changed.health }]);
show('updated (validated)', updated);
show('scene[0].health.resilienceScore', scene[0]?.health?.resilienceScore);
