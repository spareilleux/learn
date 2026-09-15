import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { Progression } from './Progression.tsx';

test('next and previous wrap around', async () => {
  render(<Progression chords={['Am', 'F', 'C', 'G']} />);
  const bar = () => screen.getByRole('paragraph').textContent;
  console.log(bar());
  await userEvent.click(screen.getByRole('button', { name: 'Previous' }));
  console.log(bar());
  await userEvent.click(screen.getByRole('button', { name: 'Next' }));
  await userEvent.click(screen.getByRole('button', { name: 'Next' }));
  console.log(bar());
  expect(bar()).toBe('Bar 2 of 4: F, then C');
});
