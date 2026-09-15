import { render } from '@testing-library/react';
import { expect, test } from 'vitest';
import { showHtml } from '../testing/show.ts';
import { TuningList } from './TuningList.tsx';
import { TuningListNoKey } from './TuningListNoKey.tsx';
import { dropD, standard } from './tunings.ts';

test('renders one card per tuning', () => {
  const { container } = render(<TuningList tunings={[standard, dropD]} />);
  showHtml('<TuningList>', container);
  expect(container.querySelectorAll('article')).toHaveLength(2);
});

test('without a key, the list renders and React warns', () => {
  const { container } = render(<TuningListNoKey tunings={[standard, dropD]} />);
  showHtml('<TuningListNoKey>', container);
  expect(container.querySelectorAll('li')).toHaveLength(2);
});
