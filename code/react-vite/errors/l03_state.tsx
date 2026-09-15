// errors/l03_state.tsx
import { useState } from 'react';

type Status = 'idle' | 'tuning' | 'in tune';

export function Tuner() {
  const [capo, setCapo] = useState(0);
  const [muted, setMuted] = useState([]);
  const [status, setStatus] = useState<Status>('idle');
  const [note] = useState<string>();

  function reset() {
    setCapo('0');
    setMuted([...muted, 6]);
    setStatus('out of tune');
    capo = 0;
  }

  return (
    <button type="button" onClick={reset}>
      {status}, capo {capo}, {note.toUpperCase()}
    </button>
  );
}
