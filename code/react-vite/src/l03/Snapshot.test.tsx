import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { Snapshot } from './Snapshot.tsx';

test('state is a snapshot: setCapo(capo + 1) three times adds 1', async () => {
  render(<Snapshot />);
  await userEvent.click(screen.getByRole('button', { name: '+3 with values' }));
  console.log(screen.getByRole('paragraph').textContent);
  await userEvent.click(screen.getByRole('button', { name: '+3 with updaters' }));
  console.log(screen.getByRole('paragraph').textContent);
  expect(screen.getByRole('paragraph').textContent).toBe('Capo on fret 4');
});
