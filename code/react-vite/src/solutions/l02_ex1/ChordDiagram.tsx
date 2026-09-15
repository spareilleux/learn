// Exercise 1: a chord as six strings, from the sixth (low E) to the first; null is a muted string
export interface ChordDiagramProps {
  name: string;
  frets: readonly (number | null)[];
}

const stringNames = ['E', 'A', 'D', 'G', 'B', 'e'];

export function ChordDiagram({ name, frets }: ChordDiagramProps) {
  return (
    <figure>
      <figcaption>{name}</figcaption>
      <ol>
        {frets.map((fret, string) => (
          // The six strings never move, are never filtered, and hold no state: their position is their identity
          <li key={string}>{`${stringNames[string]}: ${fret ?? 'x'}`}</li>
        ))}
      </ol>
    </figure>
  );
}
