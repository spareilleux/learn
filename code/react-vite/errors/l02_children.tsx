// errors/l02_children.tsx
import { dropD, standard } from '../src/l02/tunings.ts';

export function Favorite() {
  return <p>Favorite tuning: {standard}</p>;
}

export function Count({ tunings }: { tunings: readonly (typeof dropD)[] }) {
  return tunings.length > 0 ? tunings.map((tuning) => tuning.name) : undefined;
}

export function Nothing() {
  return;
}

export function Wrong() {
  return { name: 'Standard' };
}

export const Examples = () => (
  <>
    <Favorite />
    <Count tunings={[standard, dropD]} />
    <Nothing />
    <Wrong />
  </>
);
