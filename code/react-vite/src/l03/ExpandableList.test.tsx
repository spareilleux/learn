import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import type { ComponentType } from 'react';
import { expect, test } from 'vitest';
import { ExpandedById, ExpandedByIndex, type Item } from './ExpandableList.tsx';

const items: Item[] = [
  { id: 'p1', title: 'policy-1', detail: 'healthy' },
  { id: 'p2', title: 'policy-2', detail: 'warning' },
  { id: 'p3', title: 'policy-3', detail: 'error' },
];

// What the user sees: each row's title, and its detail when it is expanded
function rows() {
  return screen.getAllByRole('listitem').map((row) => {
    const detail = row.querySelector('p');
    return detail ? `${row.querySelector('button')?.textContent}: ${detail.textContent}` : row.querySelector('button')?.textContent;
  });
}

async function expandThenFilter(List: ComponentType<{ items: readonly Item[] }>) {
  const { rerender } = render(<List items={items} />);
  await userEvent.click(screen.getByRole('button', { name: 'policy-2' }));
  console.log('expanded policy-2:', rows());
  // The parent filters the data, as DynamicPanel does with its chips and its search box
  rerender(<List items={items.filter((item) => item.id !== 'p1')} />);
  console.log('filtered out policy-1:', rows());
}

test('by index: after filtering, another row is expanded', async () => {
  await expandThenFilter(ExpandedByIndex);
  expect(rows()).toEqual(['policy-2', 'policy-3: error']);
});

test('by id: the expanded row stays expanded', async () => {
  await expandThenFilter(ExpandedById);
  expect(rows()).toEqual(['policy-2: warning', 'policy-3']);
});
