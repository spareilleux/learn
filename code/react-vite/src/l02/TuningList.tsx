import { TuningCard } from './TuningCard.tsx';

export interface Tuning {
  id: string;
  name: string;
  notes: readonly string[];
}

// One card per tuning: the key tells React which card is which from one render to the next
export function TuningList({ tunings }: { tunings: readonly Tuning[] }) {
  return (
    <section>
      {tunings.map((tuning) => (
        <TuningCard key={tuning.id} name={tuning.name} notes={tuning.notes} />
      ))}
    </section>
  );
}
