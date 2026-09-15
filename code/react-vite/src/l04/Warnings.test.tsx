import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { expect, test } from 'vitest';
import { LateCapo, ReadOnlyCapo } from './Warnings.tsx';

test('value without onChange: typing changes nothing', async () => {
  render(<ReadOnlyCapo />);
  await userEvent.type(screen.getByLabelText('Capo'), '5');
  console.log('value after typing 5:', screen.getByLabelText<HTMLInputElement>('Capo').value);
  expect(screen.getByLabelText<HTMLInputElement>('Capo').value).toBe('2');
});

test('undefined, then a number: React warns on the first keystroke', async () => {
  render(<LateCapo />);
  await userEvent.type(screen.getByLabelText('Capo'), '3');
  console.log('value after typing 3:', screen.getByLabelText<HTMLInputElement>('Capo').value);
});
