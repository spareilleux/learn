// bundle/arktype.ts: the same schema with ArkType, whose definitions are strings in TypeScript's own syntax
import { type } from 'arktype';

const HealthMetrics = type({ resilienceScore: '0 <= number <= 1', lolliCount: 'number.integer >= 0', ergolCount: 'number.integer >= 0' });
const GovernanceNode = type({ id: 'string > 0', name: 'string', 'healthStatus?': "'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory'", 'health?': HealthMetrics });

export const parseNode = (value: unknown) => !(GovernanceNode(value) instanceof type.errors);
