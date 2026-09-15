import { useState } from 'react';
import { TuningList, type Tuning } from './l02/TuningList.tsx';
import { dropD, standard } from './l02/tunings.ts';
import { Capo } from './l03/Capo.tsx';
import { TuningForm, type NewTuning } from './l04/TuningForm.tsx';

// Lessons 2 to 4 together: the book owns the list, the form reports a new tuning, the list renders it
export function TuningBook() {
  const [tunings, setTunings] = useState<readonly Tuning[]>([standard, dropD]);

  function handleAdd(tuning: NewTuning) {
    const id = `${tuning.name.toLowerCase().replaceAll(/\W+/g, '-')}-${tunings.length + 1}`;
    setTunings([...tunings, { id, name: tuning.capo ? `${tuning.name}, capo ${tuning.capo}` : tuning.name, notes: tuning.notes }]);
  }

  return (
    <>
      <TuningForm onAdd={handleAdd} />
      <TuningList tunings={tunings} />
      <Capo />
    </>
  );
}
