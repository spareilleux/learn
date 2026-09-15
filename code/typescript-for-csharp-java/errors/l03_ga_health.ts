// errors/l03_ga_health.ts
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
interface GovernanceNode {
  id: string;
  healthStatus?: GovernanceHealthStatus;
}

function prediction(node: GovernanceNode): string {
  const status = node.healthStatus ?? 'unknown';
  if (status === 'healthy' || status === 'ok') return 'stable';
  if (status === 'warning') return 'at risk';
  if (status === 'error' || status === 'critical') return 'failing';
  return 'uncertain';
}

console.log(prediction({ id: 'policy-7' }));
