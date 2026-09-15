export interface Voicing {
  chord: string;
  frets: readonly (number | null)[];
  capo: number;
}

// Three ways to render something or nothing
export function VoicingCard({ voicing }: { voicing: Voicing }) {
  if (voicing.frets.length !== 6) return null; // nothing at all
  const muted = voicing.frets.filter((fret) => fret === null).length;
  return (
    <article>
      <h2>{voicing.chord}</h2>
      {voicing.capo && <p>Capo on fret {voicing.capo}</p>}
      {muted > 0 ? <p>{muted} muted strings</p> : <p>All six strings</p>}
    </article>
  );
}
