import type { Tuning } from './TuningList.tsx';

// The same list without a key: it renders, and React warns in development
export function TuningListNoKey({ tunings }: { tunings: readonly Tuning[] }) {
  return (
    <ul>
      {tunings.map((tuning) => (
        <li>{tuning.name}</li>
      ))}
    </ul>
  );
}
