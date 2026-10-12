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
	`---\nmodule_id: ${id}\ncourse: Fixture\nlevel: beginner\nestimated_duration: "35 minutes"\nprerequisites: [${prerequisites.join(', ')}]\n---\n\n# ${title}\n\n${body}\n`;

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
	write(path.join(src, 'unrelated-local-file.txt'), 'Outside the imported tree.\n');
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

test('generated course banners localize the duration unit', () => {
	for (const site of SITES) {
		for (const [lang, duration] of Object.entries({ en: '35 minutes', fr: '35 minutes', es: '35 minutos' })) {
			const page = fs.readFileSync(path.join(localeRoot(site, lang), 'alpha', 'alp-001.md'), 'utf8');
			assert.ok(page.includes(` · ${duration}`), `${site} ${lang} banner should contain ${duration}`);
			assert.match(page, { en: /English subject review: pending/, fr: /Relecture du contenu anglais: en attente/, es: /Revisión del contenido inglés: pendiente/ }[lang]);
		}
	}
});

test('a dirty source cannot produce pages attributed to its HEAD commit', () => {
	for (const change of ['tracked', 'untracked', 'ignored']) {
		const tmp = fs.mkdtempSync(path.join(os.tmpdir(), `streeling-dirty-${change}-`));
		const src = path.join(tmp, 'demerzel');
		const dest = path.join(tmp, 'site');
		for (const [file, text] of Object.entries(FIXTURE)) write(path.join(src, file), text);
		const git = (...args) => execFileSync('git', args, { cwd: src, stdio: 'ignore' });
		git('init', '-q');
		git('add', '.');
		git('-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'fixture');
		if (change === 'tracked') {
			write(path.join(src, 'state/streeling/courses/alpha/en/alp-001-first.md'), moduleFile('alp-001', 'Changed locally', [], 'Not in HEAD.'));
		} else {
			if (change === 'ignored') write(path.join(src, '.gitignore'), 'state/streeling/courses/alpha/en/alp-003-local.md\n');
			write(path.join(src, 'state/streeling/courses/alpha/en/alp-003-local.md'), moduleFile('alp-003', 'Local only', [], 'Not in HEAD.'));
		}
		write(path.join(dest, 'streeling.lock.json'), 'keep existing output\n');
		assert.throws(
			() => execFileSync(process.execPath, [SCRIPT, '--source', src, '--out', dest], { stdio: 'pipe' }),
			(error) => error.stderr.toString().includes('Streeling source has local changes'),
			`${change} source must be rejected`,
		);
		assert.equal(fs.readFileSync(path.join(dest, 'streeling.lock.json'), 'utf8'), 'keep existing output\n');
		assert.ok(!fs.existsSync(path.join(dest, 'src/content/docs/streeling')), `${change} source must not generate pages`);
	}
});

test('human review display follows exact source and translation blobs', () => {
	const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'streeling-reviews-'));
	const src = path.join(tmp, 'demerzel');
	for (const [file, text] of Object.entries(FIXTURE)) write(path.join(src, file), text);
	const runGit = (...args) => execFileSync('git', args, { cwd: src, encoding: 'utf8' }).trim();
	runGit('init', '-q');
	runGit('add', '.');
	runGit('-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'source');
	const sourceCommit = runGit('rev-parse', 'HEAD');
	const blob = (file) => runGit('rev-parse', `HEAD:${file}`);
	const english = blob('state/streeling/courses/alpha/en/alp-001-first.md');
	const french = blob('state/streeling/courses/alpha/fr/alp-001-first.fr.md');
	const receipt = (locale, kind, sourceBlob, extra = {}) => ({
		schema_version: '0.1.0', module_id: 'alp-001', locale, kind, source_blob: sourceBlob,
		reviewed_commit: sourceCommit, reviewer: 'fixture-reviewer', reviewed_at: '2026-10-12T00:00:00Z',
		verdict: 'approved', evidence: 'https://example.invalid/review', ...extra,
	});
	const receipts = 'state/streeling/review-receipts';
	write(path.join(src, receipts, 'alp-001.en.subject.json'), JSON.stringify(receipt('en', 'subject', english)));
	write(path.join(src, receipts, 'alp-001.fr.language.json'), JSON.stringify(receipt('fr', 'language', french, { source_english_blob: english })));
	write(path.join(src, receipts, 'alp-001.es.language.json'), JSON.stringify(receipt('es', 'language', english, { source_english_blob: english })));
	write(path.join(src, receipts, 'bet-001.en.subject.json'), JSON.stringify({ ...receipt('en', 'subject', blob('state/streeling/courses/beta/en/bet-001-other.md')), module_id: 'bet-001', verdict: 'changes_requested' }));
	runGit('add', '.');
	runGit('-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'receipts');
	const synced = path.join(tmp, 'synced');
	execFileSync(process.execPath, [SCRIPT, '--source', src, '--out', synced], { stdio: 'pipe' });
	const page = (root, lang) => fs.readFileSync(path.join(root, DOCS[lang], 'alpha', 'alp-001.md'), 'utf8');
	assert.match(page(synced, 'en'), /English subject review: \[approved receipt\]/);
	assert.match(page(synced, 'fr'), /Relecture de la traduction: \[approbation consignée\]/);
	assert.match(page(synced, 'es'), /Revisión de la traducción: pendiente/);
	assert.match(fs.readFileSync(path.join(synced, DOCS.en, 'beta', 'bet-001.md'), 'utf8'), /English subject review: \[changes requested\]/);
	assert.match(fs.readFileSync(path.join(synced, DOCS.fr, 'index.md'), 'utf8'), /1 une relecture de traduction/);

	write(path.join(src, 'state/streeling/courses/alpha/en/alp-001-first.md'), moduleFile('alp-001', 'First', [], 'The English source changed after review.'));
	runGit('add', '.');
	runGit('-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'changed source');
	const changed = path.join(tmp, 'changed');
	execFileSync(process.execPath, [SCRIPT, '--source', src, '--out', changed], { stdio: 'pipe' });
	assert.match(page(changed, 'en'), /English subject review: pending/);
	assert.match(page(changed, 'fr'), /Relecture du contenu anglais: en attente/);
	assert.match(page(changed, 'fr'), /Relecture de la traduction: en attente/);
	write(path.join(src, 'state/streeling/courses/alpha/en/alp-001-first.md'), FIXTURE['state/streeling/courses/alpha/en/alp-001-first.md']);
	write(path.join(src, 'state/streeling/courses/alpha/fr/alp-001-first.fr.md'), moduleFile('alp-001', 'Premier modifié', [], 'La traduction a changé après la relecture.'));
	runGit('add', '.');
	runGit('-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'changed translation');
	const translatedChanged = path.join(tmp, 'translated-changed');
	execFileSync(process.execPath, [SCRIPT, '--source', src, '--out', translatedChanged], { stdio: 'pipe' });
	assert.match(page(translatedChanged, 'fr'), /Relecture du contenu anglais: \[approbation consignée\]/);
	assert.match(page(translatedChanged, 'fr'), /Relecture de la traduction: en attente/);

	write(path.join(src, receipts, 'bad.json'), JSON.stringify({ ...receipt('en', 'subject', english), extra_field: true }));
	runGit('add', '.');
	runGit('-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'bad receipt');
	const sentinel = path.join(changed, 'streeling.lock.json');
	const before = fs.readFileSync(sentinel, 'utf8');
	assert.throws(
		() => execFileSync(process.execPath, [SCRIPT, '--source', src, '--out', changed], { stdio: 'pipe' }),
		(error) => error.stderr.toString().includes('Invalid Streeling review receipt bad.json'),
	);
	assert.equal(fs.readFileSync(sentinel, 'utf8'), before, 'malformed receipt must not overwrite generated output');
});
