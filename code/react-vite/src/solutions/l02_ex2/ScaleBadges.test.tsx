import { render } from '@testing-library/react';
import { test } from 'vitest';
import { showHtml } from '../../testing/show.ts';
import { ScaleBadges } from './ScaleBadges.tsx';

test('renders the scales and the child content', () => {
  const { container } = render(
    <ScaleBadges
      title="Pentatonic and blues"
      scales={[
        { name: 'Minor pentatonic', notes: ['A', 'C', 'D', 'E', 'G'] },
        { name: 'Blues', notes: ['A', 'C', 'D', 'D#', 'E', 'G'] },
      ]}
    >
      <p>Both fit over an A minor chord.</p>
    </ScaleBadges>,
  );
  showHtml('<ScaleBadges>', container);
});
