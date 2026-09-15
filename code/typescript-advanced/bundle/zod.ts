// bundle/zod.ts: the node schema of lesson 4, with Zod's classic API
import * as z from 'zod';

const HealthMetrics = z.object({ resilienceScore: z.number().min(0).max(1), lolliCount: z.int().nonnegative(), ergolCount: z.int().nonnegative() });
const GovernanceNode = z.object({ id: z.string().min(1), name: z.string(), healthStatus: z.enum(['error', 'warning', 'healthy', 'unknown', 'contradictory']).optional(), health: HealthMetrics.optional() });

export const parseNode = (value: unknown) => GovernanceNode.safeParse(value).success;
