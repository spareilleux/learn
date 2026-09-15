// solutions/l04_ex1_health_status.ts
import * as z from 'zod';

// The five statuses of GA's GovernanceHealthStatus; ForceRadiant.tsx also compares with 'ok' and 'critical'
const HealthStatus = z.enum(['error', 'warning', 'healthy', 'unknown', 'contradictory']);

// Strict: an unknown status rejects the whole node
const StrictNode = z.object({ id: z.string(), healthStatus: HealthStatus });
// Tolerant: an unknown status becomes 'unknown', and the rest of the node is kept
const TolerantNode = z.object({ id: z.string(), healthStatus: HealthStatus.catch('unknown') });

// Tolerant and visible: the replaced value is reported, so a new status on the server doesn't go unnoticed
const replaced: string[] = [];
const ReportingNode = z.object({
  id: z.string(),
  healthStatus: HealthStatus.catch((ctx) => {
    replaced.push(String(ctx.value));
    return 'unknown';
  }),
});

const nodes = JSON.parse('[{"id":"policy-7","healthStatus":"healthy"},{"id":"policy-8","healthStatus":"critical"},{"id":"policy-9","healthStatus":"ok"}]');
console.log('strict:  ', z.array(StrictNode).safeParse(nodes).error?.issues.map((i) => `${i.path.join('.')}: ${i.message}`));
console.log('tolerant:', z.array(TolerantNode).parse(nodes).map((n) => n.healthStatus));
console.log('reported:', z.array(ReportingNode).parse(nodes).map((n) => n.healthStatus), 'replaced', replaced);
