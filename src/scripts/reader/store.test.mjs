import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';

// Exercise the real store without an Astro build; only its build-time base is supplied here.
const source = readFileSync(new URL('./store.ts', import.meta.url), 'utf8').replace('import.meta.env.BASE_URL', JSON.stringify('/learn/'));
const store = await import('data:text/javascript;base64,' + Buffer.from(stripTypeScriptTypes(source)).toString('base64'));
const bookmark = (path, hash = '') => ({ key: hash ? store.sectionKey(path, hash) : store.splitPath(path).key, path, hash, section: hash, page: 'Lesson', course: 'Course', added: '2026-10-10T00:00:00Z' });
const note = (path) => ({ text: 'My note', path, page: 'Lesson', course: 'Course', updated: '2026-10-10T00:00:00Z' });

test('import refuses executable, external and noncanonical bookmark paths', () => {
  for (const path of ['javascript:globalThis.__readerProof=1//', 'JaVaScRiPt:alert(1)', 'data:text/html,test', '//example.invalid/learn/lesson/', '/learnish/lesson/', '/other/', '/learn/../other/', '/learn/%2e%2e/other/', '/learn/%252e%252e/other/', '/learn/%2fother/', '/learn/%5cother/', '/learn/lesson/?next=other', '/learn/lesson/#anchor', '/learn/\\other/', '/learn/line\nbreak/', '/learn//lesson/', '/learn/%zz/']) {
    const b = bookmark(path, 'section');
    const imported = store.sanitize({ bookmarks: { [b.key]: b }, notes: { [store.splitPath(path).key]: note(path) } });
    assert.deepEqual(Object.keys(imported.bookmarks), [], path);
    assert.deepEqual(Object.keys(imported.notes), [], path);
  }
});

test('import rejects inconsistent bookmark and note keys including base traversal', () => {
  for (const key of ['/../../other/', '//example.invalid/', '/other/', '__proto__', 'constructor']) {
    const b = bookmark('/learn/lesson/', 'section');
    const payload = JSON.parse(JSON.stringify({ bookmarks: { [key]: b }, notes: { [key]: note('/learn/lesson/') } }));
    const imported = store.sanitize(payload);
    assert.deepEqual(Object.keys(imported.bookmarks), [], key);
    assert.deepEqual(Object.keys(imported.notes), [], key);
  }
});

test('valid page and note keys follow the current locale while section keys keep theirs', () => {
  for (const locale of ['', 'fr', 'es']) {
    const path = `/learn/${locale ? locale + '/' : ''}course/lesson/`;
    const page = bookmark(path);
    const section = bookmark(path, 'révisions');
    const imported = store.sanitize({ bookmarks: { [page.key]: page, [section.key]: section }, notes: { '/course/lesson/': note(path) } });
    assert.equal(Object.keys(imported.bookmarks).length, 2);
    assert.equal(imported.notes['/course/lesson/'].text, 'My note');
    const pageHref = store.localHref(page.key, 'es');
    assert.equal(pageHref, '/learn/es/course/lesson/');
    const sectionHref = `${imported.bookmarks[section.key].path}#${encodeURIComponent(imported.bookmarks[section.key].hash)}`;
    const parsed = new URL(sectionHref, 'https://spareilleux.github.io');
    assert.equal(parsed.origin, 'https://spareilleux.github.io');
    assert.equal(parsed.pathname, path);
    assert.equal(decodeURIComponent(parsed.hash.slice(1)), 'révisions');
  }
});

test('valid import merge remains idempotent and keeps a newer note', () => {
  const path = '/learn/fr/course/lesson/';
  const b = bookmark(path);
  const into = store.sanitize({ bookmarks: {}, notes: { [b.key]: { ...note(path), text: 'Newer', updated: '2026-10-11T00:00:00Z' } } });
  const from = store.sanitize({ bookmarks: { [b.key]: b }, notes: { [b.key]: note(path) } });
  assert.deepEqual(store.merge(into, from), { bookmarks: 1, notes: 0 });
  assert.deepEqual(store.merge(into, from), { bookmarks: 0, notes: 0 });
  assert.equal(into.notes[b.key].text, 'Newer');
});


test('malformed Unicode section ids cannot break fragment encoding', () => {
  for (const hash of ['\ud800', '\udfff']) {
    const b = bookmark('/learn/lesson/', hash);
    const imported = store.sanitize({ bookmarks: { [b.key]: b } });
    assert.deepEqual(Object.keys(imported.bookmarks), []);
  }
});

test('a successfully saved long note survives reload unchanged', () => {
  const previousStorage = globalThis.localStorage;
  const previousWindow = globalThis.window;
  let stored = null;
  globalThis.localStorage = { getItem: () => stored, setItem: (_key, value) => { stored = value; } };
  globalThis.window = { dispatchEvent: () => true };
  try {
    const path = '/learn/lesson/';
    const text = 'x'.repeat(100_001);
    const data = { version: 1, bookmarks: {}, notes: { '/lesson/': { ...note(path), text } } };
    assert.equal(store.save(data), true);
    assert.equal(store.load().notes['/lesson/']?.text, text);
  } finally {
    if (previousStorage === undefined) delete globalThis.localStorage;
    else globalThis.localStorage = previousStorage;
    if (previousWindow === undefined) delete globalThis.window;
    else globalThis.window = previousWindow;
  }
});
