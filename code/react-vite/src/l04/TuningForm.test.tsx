import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test, vi } from 'vitest';
import { parseNotes } from './notes.ts';
import { TuningForm } from './TuningForm.tsx';

test('parseNotes', () => {
  for (const text of ['E A D G B E', 'd a d g a d', 'Eb Ab Db Gb Bb Eb', 'E A D G B', 'E A D G H E']) {
    console.log(JSON.stringify(text).padEnd(21), parseNotes(text));
  }
});

function alerts() {
  return screen.queryAllByRole('alert').map((alert) => alert.textContent);
}

test('the form validates as you type, and on submit', async () => {
  const onAdd = vi.fn();
  render(<TuningForm onAdd={onAdd} />);
  const notes = screen.getByLabelText('Notes');
  await userEvent.clear(notes);
  await userEvent.type(notes, 'D A D G');
  console.log('typed "D A D G":', alerts());
  await userEvent.type(notes, ' A D');
  console.log('typed " A D":', alerts());
  await userEvent.click(screen.getByRole('button', { name: 'Add tuning' }));
  console.log('submitted without a name:', alerts(), 'onAdd calls:', onAdd.mock.calls.length);
  await userEvent.type(screen.getByLabelText('Name'), 'DADGAD');
  await userEvent.selectOptions(screen.getByLabelText('Capo'), '2');
  await userEvent.click(screen.getByRole('button', { name: 'Add tuning' }));
  console.log('submitted:', alerts(), JSON.stringify(onAdd.mock.calls));
  expect(screen.getByLabelText<HTMLInputElement>('Name').value).toBe('');
});
