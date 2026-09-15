import { render } from '@testing-library/react';
import { expect, test } from 'vitest';
import { showHtml } from '../testing/show.ts';
import { TuningCard } from './TuningCard.tsx';

test('renders the props and the children', () => {
  const { container } = render(
    <TuningCard name="Drop D" notes={['D', 'A', 'D', 'G', 'B', 'E']} capo={2}>
      <p>Lower the sixth string by a whole tone.</p>
    </TuningCard>,
  );
  showHtml('<TuningCard>', container);
  expect(container.querySelector('h2')?.textContent).toBe('Drop D');
});

test('a JSX expression is an object that describes the element', () => {
  const element = <TuningCard name="Standard" notes={['E', 'A', 'D', 'G', 'B', 'E']} />;
  console.log(element.type === TuningCard, element.props, element.key);
});
