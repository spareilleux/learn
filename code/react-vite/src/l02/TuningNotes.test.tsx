import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { TuningNotesById, TuningNotesByIndex } from './TuningNotes.tsx';
import { dropD, openG, standard } from './tunings.ts';

// The text of each row's input, as the user sees it
function rows() {
  return screen.getAllByRole('listitem').map((row) => `${row.textContent?.trim()}: "${row.querySelector('input')?.value}"`);
}

test('key={index}: the typed text stays at its position when a tuning is added first', async () => {
  const { rerender } = render(<TuningNotesByIndex tunings={[standard, dropD]} />);
  await userEvent.type(screen.getByLabelText('Note for Drop D'), 'capo 2');
  rerender(<TuningNotesByIndex tunings={[openG, standard, dropD]} />);
  console.log('key={index}', rows());
  expect(screen.getByLabelText<HTMLInputElement>('Note for Drop D').value).toBe('');
});

test('key={tuning.id}: the typed text follows its tuning', async () => {
  const { rerender } = render(<TuningNotesById tunings={[standard, dropD]} />);
  await userEvent.type(screen.getByLabelText('Note for Drop D'), 'capo 2');
  rerender(<TuningNotesById tunings={[openG, standard, dropD]} />);
  console.log('key={tuning.id}', rows());
  expect(screen.getByLabelText<HTMLInputElement>('Note for Drop D').value).toBe('capo 2');
});
