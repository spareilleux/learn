import { render } from '@testing-library/react';
import type { ComponentType } from 'react';
import { test } from 'vitest';
import { TrendBarsByIndex, TrendBarsByTime, type Score } from './TrendBars.tsx';

const history: Score[] = [
  { at: '10:00', value: 60 },
  { at: '10:05', value: 70 },
  { at: '10:10', value: 65 },
];

// After a new score arrives, which DOM element shows the score of 10:10, and is it the one that showed it before?
function slide(Bars: ComponentType<{ history: readonly Score[] }>) {
  const { container, rerender } = render(<Bars history={history} />);
  const titles = () => [...container.querySelectorAll('span')].map((span) => span.title);
  const elements = [...container.querySelectorAll('span')];
  console.log('before:', titles());
  rerender(<Bars history={[...history, { at: '10:15', value: 80 }]} />);
  console.log('after: ', titles());
  // Where did each element of the first render go?
  console.log('elements of the first render now show:', elements.map((span) => (span.isConnected ? span.title : 'removed')));
}

test('key={i}: every element gets a new score', () => slide(TrendBarsByIndex));
test('key={score.at}: the element follows its score', () => slide(TrendBarsByTime));
