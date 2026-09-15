import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { StrictMode } from 'react';
import { test } from 'vitest';
import { ChordHistory, ChordPicker } from './RenderLog.tsx';

test('a state change renders the component and its children again', async () => {
  render(<ChordPicker />);
  console.log('--- click');
  await userEvent.click(screen.getByRole('button', { name: 'Change chord' }));
});

test('without StrictMode, the impure component renders once', () => {
  const history: string[] = [];
  render(<ChordHistory chord="G" history={history} />);
  console.log(screen.getByRole('paragraph').textContent, history);
});

test('in StrictMode, React renders it twice in development, and the output shows the impurity', () => {
  const history: string[] = [];
  render(
    <StrictMode>
      <ChordHistory chord="G" history={history} />
    </StrictMode>,
  );
  console.log(screen.getByRole('paragraph').textContent, history);
});
