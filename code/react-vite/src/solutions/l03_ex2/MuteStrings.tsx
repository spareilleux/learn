import { useState } from 'react';

// Exercise 2: every update builds a new array, so React sees a new value and renders again
export function MuteStrings() {
  const [muted, setMuted] = useState<readonly number[]>([]);

  function toggle(string: number) {
    setMuted((current) =>
      current.includes(string) ? current.filter((s) => s !== string) : [...current, string].sort((a, b) => b - a),
    );
  }

  return (
    <section>
      {[6, 5, 4, 3, 2, 1].map((string) => (
        <button key={string} type="button" aria-pressed={muted.includes(string)} onClick={() => toggle(string)}>
          String {string}
        </button>
      ))}
      <p>Muted strings: {muted.join(', ') || 'none'}</p>
    </section>
  );
}
