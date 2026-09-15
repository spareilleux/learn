// bundle/zod-mini.ts: the same schema with zod/mini, Zod's functional API for smaller bundles
import * as z from 'zod/mini';

const HealthMetrics = z.object({ resilienceScore: z.number().check(z.minimum(0), z.maximum(1)), lolliCount: z.int().check(z.minimum(0)), ergolCount: z.int().check(z.minimum(0)) });
const GovernanceNode = z.object({ id: z.string().check(z.minLength(1)), name: z.string(), healthStatus: z.optional(z.enum(['error', 'warning', 'healthy', 'unknown', 'contradictory'])), health: z.optional(HealthMetrics) });

export const parseNode = (value: unknown) => GovernanceNode.safeParse(value).success;
