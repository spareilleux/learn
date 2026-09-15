import { useState } from 'react';

// Pure: the same props give the same output, and nothing outside the component changes
export function ChordName({ chord }: { chord: string }) {
  console.log(`ChordName renders ${chord}`);
  return <p>{chord}</p>;
}

export function ChordPicker() {
  const [chord, setChord] = useState('G');
  console.log(`ChordPicker renders with ${chord}`);
  return (
    <section>
      <button type="button" onClick={() => setChord(chord === 'G' ? 'C' : 'G')}>
        Change chord
      </button>
      <ChordName chord={chord} />
      <ChordName chord="D" />
    </section>
  );
}

// Impure on purpose: the component changes an array that it received, while it renders
export function ChordHistory({ chord, history }: { chord: string; history: string[] }) {
  history.push(chord);
  return <p>Played so far: {history.join(' ')}</p>;
}
