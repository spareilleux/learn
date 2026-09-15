import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { StringOrder } from './StringOrder.tsx';

test('the checkbox reverses the order', async () => {
  render(<StringOrder notes={['D', 'A', 'D', 'G', 'A', 'E']} />);
  console.log(screen.getByRole('paragraph').textContent);
  await userEvent.click(screen.getByLabelText('High string first'));
  console.log(screen.getByRole('paragraph').textContent);
  expect(screen.getByRole<HTMLInputElement>('checkbox').checked).toBe(true);
});
