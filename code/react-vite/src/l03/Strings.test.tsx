import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { MutatedStrings, ReplacedStrings } from './Strings.tsx';

test('push, then set the same array: nothing on screen', async () => {
  render(<MutatedStrings />);
  await userEvent.click(screen.getByRole('button'));
  console.log(screen.getByRole('paragraph').textContent);
  expect(screen.getByRole('paragraph').textContent).toBe('Muted strings: none');
});

test('a new array: React renders again', async () => {
  render(<ReplacedStrings />);
  await userEvent.click(screen.getByRole('button'));
  console.log(screen.getByRole('paragraph').textContent);
  expect(screen.getByRole('paragraph').textContent).toBe('Muted strings: 6');
});
