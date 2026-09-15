import { useState } from 'react';

const allNotes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

// Exercise 3: GA's ScaleSelector keeps the notes and the scale number in two pieces of state.
// Here only the notes are state; the scale number is computed from them on every render, so it can't disagree.
export function ScaleNotes() {
  const [notes, setNotes] = useState<readonly string[]>([]);
  const scale = notes.reduce((bits, note) => bits | (1 << allNotes.indexOf(note)), 0);

  function toggle(note: string) {
    setNotes((current) => (current.includes(note) ? current.filter((n) => n !== note) : [...current, note]));
  }

  return (
    <section>
      {allNotes.map((note) => (
        <button key={note} type="button" aria-pressed={notes.includes(note)} onClick={() => toggle(note)}>
          {note}
        </button>
      ))}
      <button type="button" onClick={() => setNotes([])}>
        Clear
      </button>
      <p>
        Notes {notes.join(' ') || 'none'}, scale {scale}
      </p>
    </section>
  );
}
