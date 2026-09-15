import { useState } from 'react';

export interface Item {
  id: string;
  title: string;
  detail: string;
}

// Reduced from GA's DynamicPanel.tsx (ListDetailLayout): the expanded rows are remembered by their position
export function ExpandedByIndex({ items }: { items: readonly Item[] }) {
  const [expanded, setExpanded] = useState<ReadonlySet<number>>(new Set());
  const toggle = (index: number) => {
    const next = new Set(expanded);
    if (next.has(index)) next.delete(index);
    else next.add(index);
    setExpanded(next);
  };
  return (
    <ul>
      {items.map((item, index) => (
        <li key={index}>
          <button type="button" onClick={() => toggle(index)}>
            {item.title}
          </button>
          {expanded.has(index) && <p>{item.detail}</p>}
        </li>
      ))}
    </ul>
  );
}

// The same list, with the expanded rows remembered by the identity of their item
export function ExpandedById({ items }: { items: readonly Item[] }) {
  const [expanded, setExpanded] = useState<ReadonlySet<string>>(new Set());
  const toggle = (id: string) => {
    const next = new Set(expanded);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    setExpanded(next);
  };
  return (
    <ul>
      {items.map((item) => (
        <li key={item.id}>
          <button type="button" onClick={() => toggle(item.id)}>
            {item.title}
          </button>
          {expanded.has(item.id) && <p>{item.detail}</p>}
        </li>
      ))}
    </ul>
  );
}
