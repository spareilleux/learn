// Missing translations in the Streeling generator: run sync-streeling.mjs on a small made-up Demerzel tree
// and check every link it writes, in the three locales.
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

const moduleFile = (id, title, prerequisites, body) =>
	`---\nmodule_id: ${id}\ncourse: Fixture\nlevel: beginner\nprerequisites: [${prerequisites.join(', ')}]\n---\n\n# ${title}\n\n${body}\n`;

// alp-001 exists in the three languages, alp-002 in English only, bet-001 in English and French.
const FIXTURE = {
	'state/streeling/university.json': JSON.stringify({ mandate: 'A made-up university for the tests.' }),
	'state/streeling/departments/alpha.department.json': JSON.stringify({ full_name: 'Department of Alpha', domain: 'fixture' }),
	'state/streeling/courses/alpha/en/alp-001-first.md': moduleFile('alp-001', 'First', [], 'Next: [the second](alp-002-second.md) and [beta](../../beta/en/bet-001-other.md#part).'),
	'state/streeling/courses/alpha/fr/alp-001-first.fr.md': moduleFile('alp-001', 'Premier', [], 'Suite : [le deuxième](../en/alp-002-second.md) et [bêta](../../beta/fr/bet-001-other.fr.md).'),
	'state/streeling/courses/alpha/es/alp-001-first.es.md': moduleFile('alp-001', 'Primero', [], 'Sigue: [el segundo](../en/alp-002-second.md) y [beta](../../beta/en/bet-001-other.md#part).'),
	'state/streeling/courses/alpha/en/alp-002-second.md': moduleFile('alp-002', 'Second', ['alp-001'], 'Back to [the first](alp-001-first.md).'),
	'state/streeling/courses/beta/en/bet-001-other.md': moduleFile('bet-001', 'Other', ['alp-002'], '## Part\n\nSee [the second](../../alpha/en/alp-002-second.md).'),
	'state/streeling/courses/beta/fr/bet-001-other.fr.md': moduleFile('bet-001', 'Autre', ['alp-002'], '## Partie\n\nVoir [le deuxième](../../alpha/en/alp-002-second.md).'),
};
const HAS_PAGE = { en: ['alp-001', 'alp-002', 'bet-001'], fr: ['alp-001', 'bet-001'], es: ['alp-001'] };
const SITES = ['kept', 'fresh'];

function write(file, text) {
	fs.mkdirSync(path.dirname(file), { recursive: true });
	fs.writeFileSync(file, text);
}

// Two syncs of the same tree: `kept` already has hand-written journals, `fresh` gets new ones from the template.
const out = {};
const localeRoot = (site, lang) => path.join(out[site], DOCS[lang]);

before(() => {
	const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'streeling-test-'));
	const src = path.join(tmp, 'demerzel');
	for (const [file, text] of Object.entries(FIXTURE)) write(path.join(src, file), text);
	const env = { ...process.env, GIT_AUTHOR_DATE: '2026-01-01T00:00:00Z', GIT_COMMITTER_DATE: '2026-01-01T00:00:00Z' };
	const git = (...args) => execFileSync('git', args, { cwd: src, env, stdio: 'ignore' });
	git('init', '-q');
	git('add', '.');
	git('-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'fixture');
	for (const site of SITES) out[site] = path.join(tmp, site);
	for (const lang of LANGS) write(path.join(localeRoot('kept', lang), 'journal.md'), `hand-written ${lang} journal\n`);
	for (const site of SITES) execFileSync(process.execPath, [SCRIPT, '--source', src, '--out', out[site]], { stdio: 'pipe' });
});

/** Every generated page of a locale in both syncs, with its route relative to that locale's streeling/ folder. */
function pages(lang) {
	return SITES.flatMap((site) =>
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
		for (const page of pages(lang)) {
			for (const { href, target } of links(page)) {
				// A translated URL with no page of its own is served by Starlight with the English page.
				const served = hasPage(page.site, lang, target) || (lang !== 'en' && hasPage(page.site, 'en', target));
				if (!served) broken.push(`${page.site} ${lang} ${page.route}: ${href}`);
			}
		}
	}
	assert.deepEqual(broken, []);
});

test('a link to a module with no page in the reader’s language says it is in English', () => {
	const wrong = [];
	let englishOnlyLinks = 0;
	for (const lang of LANGS) {
		for (const page of pages(lang)) {
			for (const { href, target, label } of links(page)) {
				const englishOnly = lang !== 'en' && !hasPage(page.site, lang, target);
				englishOnlyLinks += englishOnly;
				const expected = englishOnly ? ENGLISH_ONLY[lang] : undefined;
				if (label !== expected) wrong.push(`${page.site} ${lang} ${page.route}: ${href} → ${label ?? 'no label'}, expected ${expected ?? 'no label'}`);
			}
		}
	}
	assert.ok(englishOnlyLinks > 0, 'the fixture must produce links to English-only modules');
	assert.deepEqual(wrong, []);
});

test('translations are neither invented nor hidden', () => {
	for (const site of SITES) {
		for (const lang of LANGS) {
			const modules = pages(lang)
				.filter((p) => p.site === site && /^[a-z]+\/[a-z]+-\d+\/$/.test(p.route))
				.map((p) => p.route.split('/')[1])
				.sort();
			assert.deepEqual(modules, HAS_PAGE[lang], `${site} ${lang} module pages`);
			for (const [dept, ids] of [['alpha', ['alp-001', 'alp-002']], ['beta', ['bet-001']]]) {
				const index = fs.readFileSync(path.join(localeRoot(site, lang), dept, 'index.md'), 'utf8');
				for (const id of ids) assert.ok(index.includes(`](${id}/)`), `${site} ${lang} ${dept} index lists ${id}`);
			}
		}
	}
});

test('hand-written journals are left alone', () => {
	for (const lang of LANGS) {
		assert.equal(fs.readFileSync(path.join(localeRoot('kept', lang), 'journal.md'), 'utf8'), `hand-written ${lang} journal\n`);
	}
});
