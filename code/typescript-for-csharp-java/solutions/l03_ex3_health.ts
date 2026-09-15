// solutions/l03_ex3_health.ts
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';

// The border: every string the server may send becomes one of the statuses the front end knows
function toHealthStatus(text: string): GovernanceHealthStatus {
  switch (text) {
    case 'healthy':
    case 'ok':
      return 'healthy';
    case 'warning':
      return 'warning';
    case 'error':
    case 'critical':
      return 'error';
    case 'contradictory':
      return 'contradictory';
    default:
      return 'unknown';
  }
}

// Inside, the union is true, and a Record keyed by it must list every status
const predictions: Record<GovernanceHealthStatus, string> = {
  healthy: 'stable',
  warning: 'at risk',
  error: 'failing',
  contradictory: 'uncertain',
  unknown: 'uncertain',
};

for (const text of ['ok', 'critical', 'warning', 'purple']) {
  const status = toHealthStatus(text);
  console.log(text.padEnd(9), status.padEnd(8), predictions[status]);
}
