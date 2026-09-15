import { useState } from 'react';

// Three calls with the value of this render, then three calls with an updater function
export function Snapshot() {
  const [capo, setCapo] = useState(0);

  function raiseThreeTimes() {
    setCapo(capo + 1);
    setCapo(capo + 1);
    setCapo(capo + 1);
    console.log('in the handler, capo is still', capo);
  }

  function raiseThreeTimesWithUpdaters() {
    setCapo((c) => c + 1);
    setCapo((c) => c + 1);
    setCapo((c) => c + 1);
  }

  return (
    <section>
      <p>Capo on fret {capo}</p>
      <button type="button" onClick={raiseThreeTimes}>
        +3 with values
      </button>
      <button type="button" onClick={raiseThreeTimesWithUpdaters}>
        +3 with updaters
      </button>
    </section>
  );
}
