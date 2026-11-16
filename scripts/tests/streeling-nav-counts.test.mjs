import assert from 'node:assert/strict';
import { test } from 'node:test';
import { countDepartmentCourses, streelingLinkIdentity, updateStreelingNavCounts } from '../../src/scripts/streeling-nav-counts.mjs';

const options = { baseUrl: '/learn/', pageUrl: 'https://example.test/learn/fr/streeling/' };

test('published course identities handle base paths, locales, relative links and URL suffixes', () => {
  assert.deepEqual(streelingLinkIdentity('/learn/es/streeling/music/mus-001/?from=nav#task', options), { department: 'music', course: 'mus-001' });
  assert.deepEqual(streelingLinkIdentity('music/mus-001/', options), { department: 'music', course: 'mus-001' });
  assert.deepEqual(streelingLinkIdentity('/campus/docs/en/streeling/music/mus-001/', { baseUrl: '/campus/docs/', pageUrl: 'https://example.test/campus/docs/' }), { department: 'music', course: 'mus-001' });
  assert.deepEqual(streelingLinkIdentity('/streeling/music/', { baseUrl: '/', pageUrl: 'https://example.test/' }), { department: 'music', course: null });
});

test('each department counts unique published course URLs and retains empty departments', () => {
  const counts = countDepartmentCourses([
    '/learn/fr/streeling/music/', '/learn/fr/streeling/music/mus-001/',
    '/learn/fr/streeling/music/mus-001/#exercise', '/learn/es/streeling/music/mus-001/',
    '/learn/fr/streeling/music/mus-002/', '/learn/fr/streeling/empty/',
    '/learn/fr/streeling/', '/learn/fr/streeling/journal/',
    '/learn/fr/streeling/music/journal/', '/learn/fr/streeling/music/overview/',
    '/learn/fr/streeling/music/index/', '/learn/fr/streeling/music/mus-003/lesson/',
    '/learn/fr/streeling/music/resources/', '/learn/fr/streeling/music/mus-0010/',
    '/learn/fr/method/', 'https://external.test/learn/fr/streeling/music/mus-004/',
    '/another-base/fr/streeling/music/mus-005/', 'mailto:music@example.test',
  ], options);
  assert.deepEqual([...counts], [['music', 2], ['empty', 0]]);
});

// A small DOM fixture keeps these tests dependency-free while exercising the production updater.
function navigationFixture(lang = 'en') {
  const document = {
    baseURI: options.pageUrl,
    documentElement: { lang },
    createElement: () => ({ setAttribute(name, value) { this[name] = value; } }),
  };
  function group(hrefs) {
    const badges = [];
    const label = { append: (badge) => badges.push(badge), querySelector: () => badges[0] ?? null };
    const summary = { querySelector: () => label };
    const details = { querySelector: () => summary, querySelectorAll: () => links };
    const links = hrefs.map((href) => ({ getAttribute: () => href, closest: () => details }));
    return { details, links, badges };
  }
  function tree(groups) {
    return {
      ownerDocument: document,
      dataset: { streelingBase: '/learn/' },
      querySelectorAll: (selector) => selector === 'a[href]' ? groups.flatMap((group) => group.links) : groups.map((group) => group.details),
    };
  }
  const music = group(['/learn/fr/streeling/music/', '/learn/fr/streeling/music/mus-001/', '/learn/fr/streeling/music/mus-001/#task']);
  const empty = group(['/learn/fr/streeling/empty/']);
  const dialogMusic = group(['/learn/fr/streeling/music/', '/learn/fr/streeling/music/mus-001/']);
  const trees = [tree([music, empty]), tree([dialogMusic])];
  const root = { querySelectorAll: (selector) => { assert.equal(selector, '[data-streeling-nav]'); return trees; } };
  return { root, music, empty, dialogMusic };
}

test('initialization scopes counts to each nav tree, retains zero and reuses its badge', () => {
  const fixture = navigationFixture('fr');
  updateStreelingNavCounts(fixture.root);
  updateStreelingNavCounts(fixture.root);
  assert.equal(fixture.music.badges.length, 1);
  assert.equal(fixture.music.badges[0].textContent, '(1)');
  assert.equal(fixture.music.badges[0]['aria-label'], '1 cours publié');
  assert.equal(fixture.empty.badges[0].textContent, '(0)');
  assert.equal(fixture.dialogMusic.badges[0].textContent, '(1)');
  fixture.music.links.push({ getAttribute: () => '/learn/fr/streeling/music/mus-002/', closest: () => fixture.music.details });
  updateStreelingNavCounts(fixture.root);
  assert.equal(fixture.music.badges.length, 1);
  assert.equal(fixture.music.badges[0].textContent, '(2)');
  assert.equal(fixture.music.badges[0]['aria-label'], '2 cours publiés');
  assert.equal(fixture.dialogMusic.badges[0].textContent, '(1)');
});

test('badge descriptions follow the document language', () => {
  for (const [lang, label] of [['en', '1 published course'], ['es', '1 curso publicado']]) {
    const fixture = navigationFixture(lang);
    updateStreelingNavCounts(fixture.root);
    assert.equal(fixture.music.badges[0]['aria-label'], label);
  }
});
