// bundle/valibot.ts: the same schema with Valibot
import * as v from 'valibot';

const HealthMetrics = v.object({ resilienceScore: v.pipe(v.number(), v.minValue(0), v.maxValue(1)), lolliCount: v.pipe(v.number(), v.integer(), v.minValue(0)), ergolCount: v.pipe(v.number(), v.integer(), v.minValue(0)) });
const GovernanceNode = v.object({ id: v.pipe(v.string(), v.minLength(1)), name: v.string(), healthStatus: v.optional(v.picklist(['error', 'warning', 'healthy', 'unknown', 'contradictory'])), health: v.optional(HealthMetrics) });

export const parseNode = (value: unknown) => v.safeParse(GovernanceNode, value).success;
