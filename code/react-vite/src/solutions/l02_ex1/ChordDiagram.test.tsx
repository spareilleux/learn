import { render } from '@testing-library/react';
import { expect, test } from 'vitest';
import { showHtml } from '../../testing/show.ts';
import { ChordDiagram } from './ChordDiagram.tsx';

test('renders D major with two muted strings', () => {
  const { container } = render(<ChordDiagram name="D" frets={[null, null, 0, 2, 3, 2]} />);
  showHtml('<ChordDiagram>', container);
  expect(container.querySelectorAll('li')).toHaveLength(6);
});
