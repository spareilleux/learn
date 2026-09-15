import { render, screen } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
import { Profiler } from 'react';
import { expect, test } from 'vitest';
import { ScaleSelector } from './ScaleSelector.tsx';

test('one commit per keystroke, and the scale follows the notes', async () => {
  let commits = 0;
  render(
    // Profiler calls onRender each time React commits the tree inside it
    <Profiler id="scale" onRender={() => commits++}>
      <ScaleSelector />
    </Profiler>,
  );
  await userEvent.type(screen.getByLabelText('Notes'), 'C E G');
  console.log(screen.getByRole('paragraph').textContent, `after ${commits} commits`);
  expect(commits).toBe(6);
});
