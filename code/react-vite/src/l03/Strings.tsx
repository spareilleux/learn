import { useState } from 'react';

// An array in state: mutating it changes nothing on screen, replacing it renders again
export function MutatedStrings() {
  const [muted, setMuted] = useState<number[]>([]);
  return (
    <section>
      <button
        type="button"
        onClick={() => {
          muted.push(6); // changes the array that React already has
          setMuted(muted); // the same array: Object.is says nothing changed, and React skips the render
        }}
      >
        Mute string 6
      </button>
      <p>Muted strings: {muted.join(', ') || 'none'}</p>
    </section>
  );
}

export function ReplacedStrings() {
  const [muted, setMuted] = useState<readonly number[]>([]);
  return (
    <section>
      <button type="button" onClick={() => setMuted([...muted, 6])}>
        Mute string 6
      </button>
      <p>Muted strings: {muted.join(', ') || 'none'}</p>
    </section>
  );
}
