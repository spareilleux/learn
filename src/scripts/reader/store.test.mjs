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

test('an imported note dated in the future or malformed never wins a merge', () => {
  const now = Date.parse('2026-11-16T12:00:00Z');
  const path = '/learn/course/lesson/';
  const key = store.splitPath(path).key;
  const mine = () => ({ bookmarks: {}, notes: { [key]: { ...note(path), text: 'Mine' } } });
  for (const updated of ['9999', '9999-12-31T23:59:59Z', '2026-11-18T00:00:00Z', '2026-11-16', 'tomorrow', '']) {
    const from = store.sanitize({ notes: { [key]: { ...note(path), text: 'Imported', updated } } });
    const into = mine();
    assert.deepEqual(store.merge(into, from, now), { bookmarks: 0, notes: 0 }, updated);
    assert.equal(into.notes[key].text, 'Mine', updated);
    // A new note is kept, but stamped now, so it can't block the reader's later edits either
    const fresh = { bookmarks: {}, notes: {} };
    assert.deepEqual(store.merge(fresh, from, now), { bookmarks: 0, notes: 1 }, updated);
    assert.equal(fresh.notes[key].text, 'Imported', updated);
    assert.equal(fresh.notes[key].updated, '2026-11-16T12:00:00.000Z', updated);
  }
});

test('notes compare by time, allow a day of clock skew, and a valid note replaces a future-dated one', () => {
  const now = Date.parse('2026-11-16T12:00:00Z');
  const path = '/learn/course/lesson/';
  const key = store.splitPath(path).key;
  const merged = (mineUpdated, importedUpdated) => {
    const into = { bookmarks: {}, notes: { [key]: { ...note(path), text: 'Mine', updated: mineUpdated } } };
    store.merge(into, { bookmarks: {}, notes: { [key]: { ...note(path), text: 'Imported', updated: importedUpdated } } }, now);
    return into.notes[key].text;
  };
  // Milliseconds or not, the later time wins: as strings, '...00.500Z' sorts before '...00Z'
  assert.equal(merged('2026-11-01T00:00:00Z', '2026-11-01T00:00:00.500Z'), 'Imported');
  assert.equal(merged('2026-11-01T00:00:00.500Z', '2026-11-01T00:00:00Z'), 'Mine');
  // Another device's clock a few hours ahead
  assert.equal(merged('2026-11-16T11:00:00Z', '2026-11-16T20:00:00Z'), 'Imported');
  // A note stored before this check with a date in the future gives way to a valid one
  assert.equal(merged('9999', '2026-11-16T11:00:00Z'), 'Imported');
  assert.equal(merged('9999-12-31T23:59:59Z', '2026-11-16T11:00:00Z'), 'Imported');
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

test('page and section bookmarks refuse encoded, Unicode and attribute-breaking path variants', () => {
  const paths = [
    '/learn/%2E%2E/other/', '/learn/.%2e/other/', '/learn/x/..', '/learn/x/%2e', '/learn/fr/..',
    '/learn/%c0%ae%c0%ae/other/', '/learn/x%2F..%2F..%2Fevil/', '/learn/%2f%2fevil.com/', '/learn/%5c%5cevil/',
    '/learn//evil.com/', '/learn/fr//evil.com/', '/learn/\\\\evil/', '/learn/x%3Ay/', '/learn/x%23y/', '/learn/x%3Fy/',
    '/learn/..%00/', '/learn/%00/', '/learn/%09/', '/learn/\t/', '/learn/x\r/', '/learn/%20/', '/learn/%25/',
    '/learn/x" onmouseover=alert(1)/', '/learn/x"onmouseover=alert(1)/', '/learn/<script>/', '/learn/x`y/', '/learn/{x}/',
    '/learn/javascript：alert(1)/', '/learn/ /', '/learn/ /', '/learn/é/', '/learn',
    `/learn/${'a'.repeat(100_001)}/`,
  ];
  for (const path of paths) {
    for (const hash of ['', 'section']) {
      const b = bookmark(path, hash);
      const imported = store.sanitize({ bookmarks: { [b.key]: b }, notes: { [store.splitPath(path).key]: note(path) } });
      assert.deepEqual(Object.keys(imported.bookmarks), [], JSON.stringify(path).slice(0, 80));
      assert.deepEqual(Object.keys(imported.notes), [], JSON.stringify(path).slice(0, 80));
    }
  }
});

test('every link built from an accepted entry stays on this site under /learn/', () => {
  // Characters the path check lets through, and fragments a hostile file could carry; the library assigns
  // these links to a.href, so only the resolved URL matters, not quoting.
  const paths = ["/learn/x'onmouseover=alert(1)/", '/learn/x;y/', '/learn/x@evil.com/', '/learn/x|y/', '/learn/x(y)/',
    '/learn/%E2%80%AE/', '/learn/%C3%A9/', '/learn/%66r/', '/learn/', '/learn/fr/', '/learn/es/course/lesson/'];
  const hashes = ['', 'sec', '"><img src=x onerror=alert(1)>', 'javascript:alert(1)', "x'y", '%2e', '‮'];
  const site = 'https://spareilleux.github.io';
  let accepted = 0;
  for (const path of paths) {
    for (const hash of hashes) {
      const b = { ...bookmark(path, hash), section: '<img src=x onerror=alert(1)>', page: '<script>alert(1)</script>' };
      const imported = store.sanitize({ bookmarks: { [b.key]: b }, notes: { [store.splitPath(path).key]: { ...note(path), text: '<script>alert(1)</script>' } } });
      const kept = imported.bookmarks[b.key];
      if (!kept) continue;
      accepted++;
      // Display fields are data: kept as typed, and drawn with textContent by the components
      assert.equal(kept.page, '<script>alert(1)</script>');
      for (const locale of ['', 'fr', 'es']) {
        const links = [
          [kept.hash ? `${kept.path}#${encodeURIComponent(kept.hash)}` : store.localHref(store.splitPath(kept.path).key, locale), kept.hash],
          ...Object.keys(imported.notes).map((key) => [`${store.localHref(key, locale)}#reader-notes`, 'reader-notes']),
        ];
        for (const [href, fragment] of links) {
          assert.ok(href.startsWith('/learn/'), href);
          const url = new URL(href, `${site}/learn/my-notes/`);
          assert.equal(url.origin, site, href);
          assert.ok(url.pathname.startsWith('/learn/'), href);
          assert.equal(decodeURIComponent(url.hash.slice(1)), fragment, href);
        }
      }
    }
  }
  assert.ok(accepted >= paths.length * 5, `only ${accepted} accepted`);
});

test('the reader components never write stored values as HTML', () => {
  // Every bookmark and note field reaches the page through textContent, value, href or setAttribute; the only
  // HTML string is the constant bookmark icon.
  for (const name of ['ReaderLibrary.astro', 'ReaderTools.astro']) {
    const code = readFileSync(new URL(`../../components/${name}`, import.meta.url), 'utf8');
    const sinks = code.match(/\.(innerHTML|outerHTML)\s*=[^;]*|insertAdjacentHTML|document\.write|\.srcdoc\b|new Function|\beval\(/g) ?? [];
    for (const sink of sinks) assert.match(sink, /^\.innerHTML =\s*'<svg [^'$`]*<\/svg>'$/, `${name}: ${sink}`);
  }
});
