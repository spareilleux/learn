import { useState } from 'react';
import { transpose } from './chords.ts';

const chords = ['G', 'C', 'D', 'Em'];

export function Capo() {
  // State: a value that React keeps between renders, and a function that changes it and schedules a new render
  const [capo, setCapo] = useState(0);

  // Everything else is computed from the state during the render
  const sounding = chords.map((chord) => transpose(chord, capo));

  return (
    <section>
      <p>Capo on fret {capo}</p>
      <button type="button" onClick={() => setCapo(capo - 1)} disabled={capo === 0}>
        Lower
      </button>
      <button type="button" onClick={() => setCapo(capo + 1)} disabled={capo === 11}>
        Raise
      </button>
      <p>Shapes {chords.join(' ')} sound {sounding.join(' ')}</p>
    </section>
  );
}
