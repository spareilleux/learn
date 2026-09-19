import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { test } from 'node:test';
import { runInNewContext } from 'node:vm';
import { transform } from '@astrojs/compiler-rs';

test('a dynamically inserted demo iframe receives full-size styles without an Astro scope class', async () => {
  const source = readFileSync(new URL('../../src/components/LazyDemo.astro', import.meta.url), 'utf8');
  const compiled = await transform(source, { filename: 'LazyDemo.astro', scopedStyleStrategy: 'where' });
  let click;
  let inserted;
  const figure = {
    dataset: { src: '/learn/ga-lab/p1/', title: 'Voicing explorer' },
    querySelector: (selector) => selector === 'button'
      ? { addEventListener: (event, handler) => { assert.equal(event, 'click'); click = handler; } }
      : { replaceChildren: (child) => { inserted = child; } },
  };
  const document = {
    querySelectorAll: () => [figure],
    createElement: (tag) => { assert.equal(tag, 'iframe'); return {}; },
  };
  for (const script of compiled.scripts) {
    runInNewContext(stripTypeScriptTypes(script.code), { document });
  }
  assert.equal(inserted, undefined, 'do not load the demo before the reader clicks');
  click();
  assert.equal(inserted.src, figure.dataset.src);
  assert.equal(inserted.title, figure.dataset.title);
  assert.equal(inserted.className, undefined, 'the runtime iframe has no compiler-generated scope class');
  const css = compiled.css.join('\n');
  const rule = css.match(/\.lazy-demo-frame[^{}]*\siframe\s*\{([^}]+)\}/);
  assert.ok(rule, 'the compiled iframe selector must not require an Astro class on the runtime element');
  assert.match(rule[1], /width:\s*100%/);
  assert.match(rule[1], /height:\s*100%/);
  assert.match(rule[1], /border:\s*0/);
});
