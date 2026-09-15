// errors/l02_props.tsx
import { TuningCard } from '../src/l02/TuningCard.tsx';

export function Examples() {
  return (
    <>
      <TuningCard notes={['E', 'A', 'D', 'G', 'B', 'E']} />
      <TuningCard name="Drop D" notes={['D', 'A', 'D', 'G', 'B', 'E']} capo="2" />
      <TuningCard name="Open G" notes="D G D G B D" />
      <TuningCard name="DADGAD" notes={['D', 'A', 'D', 'G', 'A', 'D']} strings={6} />
    </>
  );
}
