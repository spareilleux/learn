// The Streeling generator: run sync-streeling.mjs on a small made-up streeling/ tree and check the pages it writes,
// in the three locales: every link, the links back to the source, and what a broken link does.
//
//   node --test scripts/tests/sync-streeling.test.mjs

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { before, test } from 'node:test';
import { fileURLToPath } from 'node:url';

const SCRIPT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'sync-streeling.mjs');
const LANGS = ['en', 'fr', 'es'];
const DOCS = { en: 'src/content/docs/streeling', fr: 'src/content/docs/fr/streeling', es: 'src/content/docs/es/streeling' };
const ENGLISH_ONLY = { fr: '*(en anglais)*', es: '*(en inglés)*' };
const SITE_REPO = 'https://github.com/spareilleux/learn';

const moduleFile = (id, title, prerequisites, body) =>
	`---\nmodule_id: ${id}\ncourse: Fixture\nlevel: beginner\nestimated_duration: "35 minutes"\nprerequisites: [${prerequisites.join(', ')}]\n---\n\n# ${title}\n\n${body}\n`;

// alp-001 exists in the three languages, alp-002 in English only, bet-001 in English and French.
const FIXTURE = {
	'streeling/source.json': JSON.stringify({ repo: 'GuitarAlchemist/Demerzel', path: 'state/streeling', commit: 'f'.repeat(40), commit_date: '2026-01-01T00:00:00Z' }),
	'streeling/university.json': JSON.stringify({ mandate: 'A made-up university for the tests.' }),
	'streeling/departments/alpha.department.json': JSON.stringify({ full_name: 'Department of Alpha', domain: 'fixture' }),
	'streeling/courses/alpha/en/alp-001-first.md': moduleFile('alp-001', 'First', [], 'Next: [the second](alp-002-second.md) and [beta](../../beta/en/bet-001-other.md#part). Data: [scenarios](../../../../code/alpha/alp-001/scenarios.json#L2).'),
	'streeling/courses/alpha/fr/alp-001-first.fr.md': moduleFile('alp-001', 'Premier', [], 'Suite : [le deuxième](../en/alp-002-second.md) et [bêta](../../beta/fr/bet-001-other.fr.md).'),
	'streeling/courses/alpha/es/alp-001-first.es.md': moduleFile('alp-001', 'Primero', [], 'Sigue: [el segundo](../en/alp-002-second.md) y [beta](../../beta/en/bet-001-other.md#part).'),
	'streeling/courses/alpha/en/alp-002-second.md': moduleFile('alp-002', 'Second', ['alp-001'], 'Back to [the first](alp-001-first.md).'),
	'streeling/courses/beta/en/bet-001-other.md': moduleFile('bet-001', 'Other', ['alp-002'], '## Part\n\nSee [the second](../../alpha/en/alp-002-second.md).'),
	'streeling/courses/beta/fr/bet-001-other.fr.md': moduleFile('bet-001', 'Autre', ['alp-002'], '## Partie\n\nVoir [le deuxième](../../alpha/en/alp-002-second.md).'),
	'code/alpha/alp-001/scenarios.json': '{}\n',
};
const HAS_PAGE = { en: ['alp-001', 'alp-002', 'bet-001'], fr: ['alp-001', 'bet-001'], es: ['alp-001'] };
// `kept` already has hand-written journals; `fresh` and `again` get new ones from the template.
const SITES = ['kept', 'fresh', 'again'];

function write(file, text) {
	fs.mkdirSync(path.dirname(file), { recursive: true });
	fs.writeFileSync(file, text);
}

const sync = (src, dest) => execFileSync(process.execPath, [SCRIPT, '--source', src, '--out', dest], { stdio: 'pipe' });

function makeSource(dir, extra = {}) {
	for (const [file, text] of Object.entries({ ...FIXTURE, ...extra })) write(path.join(dir, file), text);
	return dir;
}

const out = {};
let tmp;
const localeRoot = (site, lang) => path.join(out[site], DOCS[lang]);
const page = (site, lang, file) => fs.readFileSync(path.join(localeRoot(site, lang), file), 'utf8');

before(() => {
	tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'streeling-test-'));
	const src = makeSource(path.join(tmp, 'source'));
	for (const site of SITES) out[site] = path.join(tmp, site);
	for (const lang of LANGS) write(path.join(localeRoot('kept', lang), 'journal.md'), `hand-written ${lang} journal\n`);
	for (const site of SITES) sync(src, out[site]);
});

/** Every generated page of a locale in the `kept` and `fresh` syncs, with its route relative to that locale's streeling/ folder. */
function pages(lang) {
	return ['kept', 'fresh'].flatMap((site) =>
		fs.readdirSync(localeRoot(site, lang), { recursive: true })
			.filter((f) => f.endsWith('.md'))
			.map((f) => {
				const rel = f.split(path.sep).join('/');
				const route = rel === 'index.md' ? '' : rel.endsWith('/index.md') ? rel.slice(0, -'index.md'.length) : rel.replace(/\.md$/, '/');
				return { site, route, file: path.join(localeRoot(site, lang), f) };
			}),
	);
}

function hasPage(site, lang, route) {
	const root = localeRoot(site, lang);
	const r = route.replace(/\/$/, '');
	return [path.join(root, `${r}.md`), path.join(root, r, 'index.md')].some((f) => fs.existsSync(f));
}

/** Relative links of a page, resolved to routes, with the label that follows each one, if any. */
function links({ route, file }) {
	const text = fs.readFileSync(file, 'utf8');
	return [...text.matchAll(/\]\(([^)\s]+)\)( \*\([^)]*\)\*)?/g)]
		.filter(([, href]) => !/^[a-z]+:/i.test(href) && !href.startsWith('#'))
		.map(([, href, label]) => {
			const url = new URL(href, `http://site/streeling/${route}`);
			assert.ok(url.pathname.startsWith('/streeling/'), `${route}: ${href} leaves streeling/`);
			return { href, target: decodeURIComponent(url.pathname.slice('/streeling/'.length)), label: label?.trim() };
		});
}

test('every link leads to a page the site serves', () => {
	const broken = [];
	for (const lang of LANGS) {
		for (const p of pages(lang)) {
			for (const { href, target } of links(p)) {
				// A translated URL with no page of its own is served by Starlight with the English page.
				const served = hasPage(p.site, lang, target) || (lang !== 'en' && hasPage(p.site, 'en', target));
				if (!served) broken.push(`${p.site} ${lang} ${p.route}: ${href}`);
			}
		}
	}
	assert.deepEqual(broken, []);
});

test('a link to a module with no page in the reader’s language says it is in English', () => {
	const wrong = [];
	let englishOnlyLinks = 0;
	for (const lang of LANGS) {
		for (const p of pages(lang)) {
			for (const { href, target, label } of links(p)) {
				const englishOnly = lang !== 'en' && !hasPage(p.site, lang, target);
				englishOnlyLinks += englishOnly;
				const expected = englishOnly ? ENGLISH_ONLY[lang] : undefined;
				if (label !== expected) wrong.push(`${p.site} ${lang} ${p.route}: ${href} → ${label ?? 'no label'}, expected ${expected ?? 'no label'}`);
			}
		}
	}
	assert.ok(englishOnlyLinks > 0, 'the fixture must produce links to English-only modules');
	assert.deepEqual(wrong, []);
});

test('translations are neither invented nor hidden', () => {
	for (const site of ['kept', 'fresh']) {
		for (const lang of LANGS) {
			const modules = pages(lang)
				.filter((p) => p.site === site && /^[a-z]+\/[a-z]+-\d+\/$/.test(p.route))
				.map((p) => p.route.split('/')[1])
				.sort();
			assert.deepEqual(modules, HAS_PAGE[lang], `${site} ${lang} module pages`);
			for (const [dept, ids] of [['alpha', ['alp-001', 'alp-002']], ['beta', ['bet-001']]]) {
				const index = page(site, lang, path.join(dept, 'index.md'));
				for (const id of ids) assert.ok(index.includes(`](${id}/)`), `${site} ${lang} ${dept} index lists ${id}`);
			}
		}
	}
});

test('the public overview shows distinct modules and actual translation totals', () => {
	const headings = { en: 'Published course count', fr: 'Nombre de cours publiés', es: 'Recuento de cursos publicados' };
	for (const lang of LANGS) {
		const overview = page('fresh', lang, 'index.md');
		assert.ok(overview.includes(`## ${headings[lang]}`), `${lang} visible count heading`);
		assert.ok(overview.includes('**3 / 50**'), `${lang} three core modules across two departments`);
		assert.ok(overview.includes('**3**'), `${lang} distinct modules`);
		assert.ok(overview.includes('| **Total** | **3** | **2** | **1** |'), `${lang} counts actual translations, not English fallbacks`);
		assert.ok(overview.includes('**6**'), `${lang} six localized lesson pages, not six courses`);
	}
});

test('IX Research is published but stays outside the departmental quota', () => {
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'streeling-extra-'));
	const source = makeSource(path.join(dir, 'source'), {
		'streeling/departments/ix-research.department.json': JSON.stringify({ full_name: 'IX Research' }),
		'streeling/courses/ix-research/en/ixr-001-extra.md': moduleFile('ixr-001', 'Extra research', [], 'An optional research module.'),
	});
	const destination = path.join(dir, 'site');
	sync(source, destination);
	for (const lang of LANGS) {
		const overview = fs.readFileSync(path.join(destination, DOCS[lang], 'index.md'), 'utf8');
		assert.ok(overview.includes('**3 / 50**'), `${lang} optional research does not enlarge the quota`);
		assert.ok(overview.includes('| **Total** | **4** | **2** | **1** |'), `${lang} optional module is still included in published totals`);
		assert.ok(overview.includes('**7**'), `${lang} seven actual localized pages`);
	}
});

test('hand-written journals are left alone', () => {
	for (const lang of LANGS) {
		assert.equal(page('kept', lang, 'journal.md'), `hand-written ${lang} journal\n`);
	}
});

test('generated course banners localize the duration unit', () => {
	for (const [lang, duration] of Object.entries({ en: '35 minutes', fr: '35 minutes', es: '35 minutos' })) {
		assert.ok(page('fresh', lang, 'alpha/alp-001.md').includes(` · ${duration}`), `${lang} banner should contain ${duration}`);
	}
});

test('View source and Edit page lead to the module’s own source file on main', () => {
	const cases = { en: 'en/alp-001-first.md', fr: 'fr/alp-001-first.fr.md', es: 'es/alp-001-first.es.md' };
	for (const [lang, file] of Object.entries(cases)) {
		const text = page('fresh', lang, 'alpha/alp-001.md');
		assert.ok(text.includes(`](${SITE_REPO}/blob/main/streeling/courses/alpha/${file})`), `${lang} View source`);
		assert.ok(text.includes(`\neditUrl: ${SITE_REPO}/edit/main/streeling/courses/alpha/${file}\n`), `${lang} editUrl`);
	}
});

test('a link to another file of the repository leads to that file on GitHub, anchor kept', () => {
	assert.ok(page('fresh', 'en', 'alpha/alp-001.md').includes(`[scenarios](${SITE_REPO}/blob/main/code/alpha/alp-001/scenarios.json#L2)`));
});

test('the overview and the lock name the Demerzel commit the source was copied from', () => {
	const lock = JSON.parse(fs.readFileSync(path.join(out.fresh, 'streeling.lock.json'), 'utf8'));
	assert.equal(lock.source, 'streeling');
	assert.equal(lock.copied_from.commit, 'f'.repeat(40));
	assert.deepEqual(lock.modules, { en: 3, fr: 2, es: 1 });
	for (const lang of LANGS) assert.ok(page('fresh', lang, 'index.md').includes('`fffffff` (2026-01-01)'), `${lang} overview`);
});

test('overviews distinguish the initial source copy from supplemental source provenance', () => {
	const manifest = 'code/streeling/evidence/craft-2026-10-22/import.json';
	const origin = { ...JSON.parse(FIXTURE['streeling/source.json']), supplements: [manifest] };
	const src = makeSource(path.join(tmp, 'supplemental-source'), { 'streeling/source.json': JSON.stringify(origin) });
	const dest = path.join(tmp, 'supplemental-site');
	sync(src, dest);
	const wording = {
		en: ['Initial source copy:', 'Additional source provenance'],
		fr: ['Copie initiale des sources :', 'Provenance des sources supplémentaires'],
		es: ['Copia inicial de las fuentes:', 'Procedencia de las fuentes adicionales'],
	};
	for (const lang of LANGS) {
		const text = fs.readFileSync(path.join(dest, DOCS[lang], 'index.md'), 'utf8');
		assert.ok(text.includes(wording[lang][0]), `${lang} must identify the initial copy`);
		assert.ok(text.includes(`[${wording[lang][1]}](${SITE_REPO}/blob/main/${manifest})`), `${lang} must link the supplemental provenance`);
		assert.ok(text.includes('`fffffff` (2026-01-01)'), `${lang} must preserve the initial commit`);
		assert.ok(page('fresh', lang, 'index.md').includes(wording[lang][0]), `${lang} must identify the initial copy without supplements`);
		assert.ok(!page('fresh', lang, 'index.md').includes(wording[lang][1]), `${lang} must omit absent supplements`);
	}
	const lock = JSON.parse(fs.readFileSync(path.join(dest, 'streeling.lock.json'), 'utf8'));
	assert.deepEqual(lock.copied_from, origin);
});

test('the same source gives the same files', () => {
	const files = (root) => fs.readdirSync(root, { recursive: true }).filter((f) => fs.statSync(path.join(root, f)).isFile()).sort();
	assert.deepEqual(files(out.again), files(out.fresh));
	for (const f of files(out.fresh)) assert.equal(fs.readFileSync(path.join(out.again, f), 'utf8'), fs.readFileSync(path.join(out.fresh, f), 'utf8'), f);
});

test('a broken relative link stops the sync before any page changes', () => {
	for (const href of ['../../../../code/alpha/alp-001/missing.json', '../../../../../outside-the-repository.md']) {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'streeling-broken-'));
		const src = makeSource(path.join(dir, 'source'), {
			'streeling/courses/alpha/en/alp-002-second.md': moduleFile('alp-002', 'Second', ['alp-001'], `See [the data](${href}).`),
		});
		const dest = path.join(dir, 'site');
		write(path.join(dest, 'streeling.lock.json'), 'keep existing output\n');
		write(path.join(dest, DOCS.en, 'alpha', 'alp-001.md'), 'previous page\n');
		assert.throws(
			() => sync(src, dest),
			(error) => error.stderr.toString().includes(`alp-002-second.md: ${href}`),
			`${href} must be rejected`,
		);
		assert.equal(fs.readFileSync(path.join(dest, 'streeling.lock.json'), 'utf8'), 'keep existing output\n');
		assert.equal(fs.readFileSync(path.join(dest, DOCS.en, 'alpha', 'alp-001.md'), 'utf8'), 'previous page\n');
	}
});

test('the old Demerzel import option says where the source went', () => {
	assert.throws(
		() => execFileSync(process.execPath, [SCRIPT, '--ref', 'HEAD', '--out', path.join(tmp, 'ref')], { stdio: 'pipe' }),
		(error) => error.stderr.toString().includes('the source lives in streeling/ now'),
	);
});
