// Exercise 3: the last quality scores as bars, as in GA's DemerzelCriticOverlay.tsx, with two choices of key
export interface Score {
  at: string; // when the score was computed: unique, and it doesn't change
  value: number;
}

export function TrendBarsByIndex({ history }: { history: readonly Score[] }) {
  return (
    <div>
      {history.slice(-3).map((score, i) => (
        <span key={i} title={score.at} style={{ height: `${score.value}%` }} />
      ))}
    </div>
  );
}

export function TrendBarsByTime({ history }: { history: readonly Score[] }) {
  return (
    <div>
      {history.slice(-3).map((score) => (
        <span key={score.at} title={score.at} style={{ height: `${score.value}%` }} />
      ))}
    </div>
  );
}
