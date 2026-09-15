import { render } from '@testing-library/react';
import { expect, test } from 'vitest';
import { ScaleSelector } from './NotesSelector.tsx';

test("GA's two selectors render each other in a loop", () => {
  expect(() => render(<ScaleSelector />)).toThrow('stopped after 60 renders');
});
