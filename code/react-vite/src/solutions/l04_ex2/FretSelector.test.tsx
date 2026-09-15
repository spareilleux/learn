import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { FretSelector } from './FretSelector.tsx';

test('arrows, bounds and Home', async () => {
  render(<FretSelector frets={2} />);
  const slider = screen.getByRole('slider', { name: 'Fret' });
  slider.focus();
  for (const keys of ['{ArrowLeft}', '{ArrowRight}{ArrowRight}{ArrowRight}', '{Home}']) {
    await userEvent.keyboard(keys);
    console.log(keys.padEnd(36), slider.textContent);
  }
  expect(slider.getAttribute('aria-valuenow')).toBe('0');
});
