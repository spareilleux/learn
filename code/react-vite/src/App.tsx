import { useState } from 'react';
import { TuningBook } from './TuningBook.tsx';

export default function App() {
  const [count, setCount] = useState(0);

  return (
    <main>
      <h1>React (Vite) course</h1>
      <button type="button" onClick={() => setCount((count) => count + 1)}>
        Count is {count}
      </button>
      <TuningBook />
    </main>
  );
}
