import type { Tuning } from './TuningList.tsx';

// Each row has an input that the component doesn't control: the text typed in it lives in the DOM
function NoteRow({ tuning }: { tuning: Tuning }) {
  return (
    <li>
      <label>
        {tuning.name} <input aria-label={`Note for ${tuning.name}`} />
      </label>
    </li>
  );
}

export function TuningNotesByIndex({ tunings }: { tunings: readonly Tuning[] }) {
  return (
    <ul>
      {tunings.map((tuning, index) => (
        <NoteRow key={index} tuning={tuning} />
      ))}
    </ul>
  );
}

export function TuningNotesById({ tunings }: { tunings: readonly Tuning[] }) {
  return (
    <ul>
      {tunings.map((tuning) => (
        <NoteRow key={tuning.id} tuning={tuning} />
      ))}
    </ul>
  );
}
