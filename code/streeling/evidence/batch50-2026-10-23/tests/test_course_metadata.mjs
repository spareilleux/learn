import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import { parseModule } from '../../../../../scripts/streeling-lib.mjs';

const root = new URL('../../../../../', import.meta.url);
const plan = JSON.parse(readFileSync(new URL('../batch-plan.json', import.meta.url), 'utf8'));

assert.equal(plan.courses.length, 50, 'This batch must contain 50 courses.');
assert.equal(new Set(plan.courses.map(course => course.code)).size, 50);
assert.equal(new Set(plan.courses.map(course => course.module_id)).size, 50);
for (const course of plan.courses) {
  assert.deepEqual(Object.keys(course.source_paths).sort(), ['en', 'es', 'fr']);
}
const paths = plan.courses.flatMap(course => Object.values(course.source_paths));
assert.equal(new Set(paths).size, 150, 'Each locale needs a distinct source path.');

// The generator uses meta.course in the description and the body H1 as the
// page title. Both must describe the same localized course.
for (const course of plan.courses) {
  for (const [locale, relative] of Object.entries(course.source_paths)) {
    test(`${course.code} ${locale}: description uses the localized course title`, () => {
      const parsed = parseModule(fileURLToPath(new URL(relative, root)));
      assert.equal(parsed.meta.course, parsed.title);
    });
  }
}
