import { useState } from 'react';

// Exercise 1: one piece of state, the position; the current and the next chord are computed from it
export function Progression({ chords }: { chords: readonly string[] }) {
  const [position, setPosition] = useState(0);
  const current = chords[position];
  const next = chords[(position + 1) % chords.length];

  return (
    <section>
      <p>
        Bar {position + 1} of {chords.length}: {current}, then {next}
      </p>
      <button type="button" onClick={() => setPosition((p) => (p + chords.length - 1) % chords.length)}>
        Previous
      </button>
      <button type="button" onClick={() => setPosition((p) => (p + 1) % chords.length)}>
        Next
      </button>
    </section>
  );
}
