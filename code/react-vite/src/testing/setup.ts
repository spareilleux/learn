// Unmount what each test rendered: Testing Library does it on its own only when the test functions are globals
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';

afterEach(() => {
  cleanup();
});
