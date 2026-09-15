import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { ScaleNotes } from './ScaleNotes.tsx';

test('C major pentatonic, then clear', async () => {
  render(<ScaleNotes />);
  for (const name of ['C', 'D', 'E', 'G', 'A']) await userEvent.click(screen.getByRole('button', { name }));
  console.log(screen.getByRole('paragraph').textContent);
  await userEvent.click(screen.getByRole('button', { name: 'Clear' }));
  console.log(screen.getByRole('paragraph').textContent);
  expect(screen.getByRole('paragraph').textContent).toBe('Notes none, scale 0');
});
