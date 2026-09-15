import { useEffect, useState } from 'react';

const allNotes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

// Reduced from GA's NotesSelector.tsx and ScaleSelector.tsx (without Material UI): the child reports its notes
// from an effect that depends on the parent's callback, and the parent creates a new callback on every render
export function NotesSelector({ onNotesChange }: { onNotesChange: (notes: string[]) => void }) {
  const [textNotes, setTextNotes] = useState('C E G');

  useEffect(() => {
    const notes = textNotes.split(' ').filter((note) => allNotes.includes(note));
    onNotesChange(notes);
  }, [textNotes, onNotesChange]);

  return <input aria-label="Notes" value={textNotes} onChange={(event) => setTextNotes(event.target.value)} />;
}

// Not in GA: a guard for the test, which would otherwise never end
let renders = 0;

export function ScaleSelector() {
  const [selectedNotes, setSelectedNotes] = useState<string[]>([]);
  const [scale, setScale] = useState(0);
  if (++renders > 60) throw new Error('stopped after 60 renders');

  const handleNotesChange = (notes: string[]) => {
    setSelectedNotes(notes);
    setScale(notes.reduce((bits, note) => bits | (1 << allNotes.indexOf(note)), 0));
  };

  return (
    <section>
      <NotesSelector onNotesChange={handleNotesChange} />
      <p>
        {selectedNotes.join(' ')}: scale {scale}
      </p>
    </section>
  );
}
