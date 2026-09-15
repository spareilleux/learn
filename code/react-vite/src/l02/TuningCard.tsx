import type { ReactNode } from 'react';

// The props of a component are one object, described by a type
export interface TuningCardProps {
  name: string;
  notes: readonly string[];
  capo?: number;
  children?: ReactNode;
}

// A component is a function that takes its props and returns what to render
export function TuningCard({ name, notes, capo = 0, children }: TuningCardProps) {
  return (
    <article className="tuning-card">
      <h2>{name}</h2>
      <p>
        {notes.join(' ')}, capo {capo}
      </p>
      {children}
    </article>
  );
}
