import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { TuningBook } from './TuningBook.tsx';

test('a tuning added with the form appears in the list', async () => {
  render(<TuningBook />);
  await userEvent.type(screen.getByLabelText('Name'), 'Open D');
  await userEvent.clear(screen.getByLabelText('Notes'));
  await userEvent.type(screen.getByLabelText('Notes'), 'D A D F# A D');
  await userEvent.click(screen.getByRole('button', { name: 'Add tuning' }));
  const names = screen.getAllByRole('heading', { level: 2 }).map((heading) => heading.textContent);
  console.log(names);
  expect(names).toEqual(['Standard', 'Drop D', 'Open D']);
});
