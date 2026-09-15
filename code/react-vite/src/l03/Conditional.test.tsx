import { render } from '@testing-library/react';
import { test } from 'vitest';
import { showHtml } from '../testing/show.ts';
import { VoicingCard } from './Conditional.tsx';

test('capo 2, and capo 0 with &&', () => {
  const { container, rerender } = render(<VoicingCard voicing={{ chord: 'D', frets: [null, null, 0, 2, 3, 2], capo: 2 }} />);
  showHtml('capo 2', container);
  rerender(<VoicingCard voicing={{ chord: 'G', frets: [3, 2, 0, 0, 0, 3], capo: 0 }} />);
  showHtml('capo 0', container);
  rerender(<VoicingCard voicing={{ chord: 'G', frets: [3, 2, 0], capo: 0 }} />);
  showHtml('three frets', container);
});
