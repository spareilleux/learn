// A chord box on a 2D canvas, ported from GA's React FretDiagram.tsx (GuitarAlchemist/ga@66bdd049,
// ReactComponents/ga-react-components/src/components/FretDiagram.tsx): same geometry, same base-fret rule.
// That component takes frets LOW E FIRST. GA's index stores diagrams HIGH E FIRST: convert with toChartOrder before drawing.

export const STRINGS = 6;
export const FRETS_SHOWN = 5;
const STRING_SPACING = 20;
const FRET_SPACING = 22;
const MARGIN_LEFT = 22;
const MARGIN_TOP = 30;

// GA's rule: the grid starts at the nut when the lowest fretted note is on fret 1 or 2, otherwise at that fret
export function baseFret(chartFrets) {
  const pressed = chartFrets.filter((f) => f > 0);
  const min = pressed.length ? Math.min(...pressed) : 1;
  return min <= 2 ? 1 : min;
}

// Where each mark goes, without drawing: string 0 is the leftmost string, the low E. Tested without a canvas.
export function layout(chartFrets) {
  const base = baseFret(chartFrets);
  const sx = (s) => MARGIN_LEFT + s * STRING_SPACING;
  const fy = (f) => MARGIN_TOP + f * FRET_SPACING;
  const marks = chartFrets.map((fret, s) => {
    if (fret < 0) return { string: s, kind: 'muted', x: sx(s), y: fy(0) - 10 };
    if (fret === 0) return { string: s, kind: 'open', x: sx(s), y: fy(0) - 10 };
    const row = fret - base + 1;
    if (row < 1 || row > FRETS_SHOWN) return { string: s, kind: 'outside', x: sx(s), y: null };
    return { string: s, kind: 'dot', x: sx(s), y: fy(row - 1) + FRET_SPACING / 2 };
  });
  return {
    width: MARGIN_LEFT + (STRINGS - 1) * STRING_SPACING + 24,
    height: MARGIN_TOP + FRETS_SHOWN * FRET_SPACING + 10,
    base,
    sx,
    fy,
    marks,
  };
}

export function drawDiagram(ctx, chartFrets, { scale = 2, ink = '#222', faint = '#999', muted = '#e53935' } = {}) {
  const l = layout(chartFrets);
  ctx.save();
  ctx.scale(scale, scale);
  ctx.lineWidth = 1;
  ctx.strokeStyle = faint;
  for (let i = 0; i <= FRETS_SHOWN; i++) line(ctx, l.sx(0), l.fy(i), l.sx(STRINGS - 1), l.fy(i));
  for (let s = 0; s < STRINGS; s++) line(ctx, l.sx(s), l.fy(0), l.sx(s), l.fy(FRETS_SHOWN));
  if (l.base === 1) {
    ctx.lineWidth = 4;
    ctx.strokeStyle = ink;
    line(ctx, l.sx(0), l.fy(0), l.sx(STRINGS - 1), l.fy(0));
  } else {
    ctx.fillStyle = ink;
    ctx.font = '9px monospace';
    ctx.fillText(`${l.base}fr`, l.sx(STRINGS - 1) + 6, l.fy(1) + 4);
  }
  for (const m of l.marks) {
    if (m.kind === 'muted') {
      ctx.fillStyle = muted;
      ctx.font = 'bold 11px monospace';
      ctx.fillText('×', m.x - 4, m.y + 2);
    } else if (m.kind === 'open') {
      ctx.strokeStyle = ink;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.arc(m.x, m.y, 5, 0, Math.PI * 2);
      ctx.stroke();
    } else if (m.kind === 'dot') {
      ctx.fillStyle = ink;
      ctx.beginPath();
      ctx.arc(m.x, m.y, 7, 0, Math.PI * 2);
      ctx.fill();
    }
  }
  ctx.restore();
  return l;
}

function line(ctx, x1, y1, x2, y2) {
  ctx.beginPath();
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
  ctx.stroke();
}
