import type { ReactNode } from 'react';

// Exercise 2: ScaleBadges.razor in React. [Parameter] properties become props, ChildContent becomes children,
// @foreach becomes map with a key, and class becomes className
export interface Scale {
  name: string;
  notes: readonly string[];
}

export function ScaleBadges({ title, scales, children }: { title: string; scales: readonly Scale[]; children?: ReactNode }) {
  return (
    <section className="scales">
      <h2>{title}</h2>
      <ul>
        {scales.map((scale) => (
          <li key={scale.name} className="badge">
            {`${scale.name} (${scale.notes.length} notes)`}
          </li>
        ))}
      </ul>
      {children}
    </section>
  );
}
