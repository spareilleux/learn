import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { Capo } from './Capo.tsx';
import { transpose } from './chords.ts';

test('transpose', () => {
  expect(transpose('Em', 2)).toBe('F#m');
  expect(transpose('B', 1)).toBe('C');
});

test('each click changes the state, and React renders the component again', async () => {
  render(<Capo />);
  const texts = () => screen.getAllByRole('paragraph').map((p) => p.textContent);
  console.log(texts());
  await userEvent.click(screen.getByRole('button', { name: 'Raise' }));
  await userEvent.click(screen.getByRole('button', { name: 'Raise' }));
  console.log(texts());
  expect(screen.getByRole<HTMLButtonElement>('button', { name: 'Lower' }).disabled).toBe(false);
});
