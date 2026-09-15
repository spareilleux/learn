// solutions/l02_ex2_define_colors.ts
import type { Equal, Expect } from '../examples/type-tests.ts';

type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
type HexColor = `#${string}`;

// A const type parameter keeps the literals, and the constraint checks completeness and the format of each color
function defineStatusColors<const T extends Record<GovernanceHealthStatus, HexColor>>(colors: T): T {
  return colors;
}

const colors = defineStatusColors({
  error: '#FF4444',
  warning: '#FFB300',
  healthy: '#33CC66',
  unknown: '#888888',
  contradictory: '#FF44FF',
});
type _1 = Expect<Equal<(typeof colors)['healthy'], '#33CC66'>>;

function mistakes() {
  // @ts-expect-error: contradictory is missing
  defineStatusColors({ error: '#FF4444', warning: '#FFB300', healthy: '#33CC66', unknown: '#888888' });
  // @ts-expect-error: magenta is not a hex color
  defineStatusColors({ error: '#FF4444', warning: '#FFB300', healthy: '#33CC66', unknown: '#888888', contradictory: 'magenta' });
}
console.log(colors.healthy, typeof mistakes);
