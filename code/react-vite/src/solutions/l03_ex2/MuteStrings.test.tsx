import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { MuteStrings } from './MuteStrings.tsx';

test('toggle strings 5, 6, then 5 again', async () => {
  render(<MuteStrings />);
  for (const name of ['String 5', 'String 6', 'String 5']) {
    await userEvent.click(screen.getByRole('button', { name }));
    console.log(`after ${name}:`, screen.getByRole('paragraph').textContent);
  }
  expect(screen.getByRole('button', { name: 'String 6' }).getAttribute('aria-pressed')).toBe('true');
});
