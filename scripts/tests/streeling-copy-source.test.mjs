// The one-time copy of the Streeling source from Demerzel: run streeling-copy-source.mjs on a made-up Demerzel
// repository, check what it copies and how it rewrites links, then generate pages from the copy.
//
//   node --test scripts/tests/streeling-copy-source.test.mjs

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { before, test } from 'node:test';
import { fileURLToPath } from 'node:url';

const SCRIPTS = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const COPY = path.join(SCRIPTS, 'streeling-copy-source.mjs');
const SYNC = path.join(SCRIPTS, 'sync-streeling.mjs');

const moduleFile = (id, title, body) => `---\nmodule_id: ${id}\ncourse: Fixture\n---\n\n# ${title}\n\n${body}\n`;

const FIRST_BODY = [
	'Next: [the second](alp-002-second.md#start).',
	'Data: [scenarios](../../../fixtures/alpha/alp-001/scenarios.json), program: [analyze.py](../../../../../scripts/streeling_fixtures/alpha/alp-001/analyze.py#L10).',
	'Background: [a governance note](../../../../../logic/note.md).',
	'```markdown',
	'[inside a fence](../../../fixtures/alpha/alp-001/scenarios.json)',
	'```',
].join('\n');

const DEMERZEL = {
	LICENSE: 'MIT License\n\nCopyright (c) fixture\n',
	'logic/note.md': '# Note\n',
	'scripts/streeling_fixtures/alpha/alp-001/analyze.py': 'print(1)\n',
	'state/streeling/university.json': JSON.stringify({ mandate: 'A made-up university.' }),
	'state/streeling/curriculum-references.json': '{}',
	'state/streeling/departments/alpha.department.json': JSON.stringify({ full_name: 'Department of Alpha' }),
	'state/streeling/departments/alpha.weights.json': '{}',
	'state/streeling/fixtures/alpha/alp-001/scenarios.json': '{}',
	'state/streeling/research-cycles/cycle.md': '# Cycle\n',
	'state/streeling/courses/README.md': '# All courses\n',
	'state/streeling/courses/alpha/README.md': '# Alpha catalog\n\nSee [the data](../../fixtures/alpha/alp-001/scenarios.json).\n',
	'state/streeling/courses/alpha/en/alp-001-first.md': moduleFile('alp-001', 'First', FIRST_BODY),
	'state/streeling/courses/alpha/en/alp-002-second.md': moduleFile('alp-002', 'Second', '## Start\n\nBack to [the first](alp-001-first.md).'),
	'state/streeling/courses/alpha/fr/alp-001-first.fr.md': moduleFile('alp-001', 'Premier', 'Suite : [le deuxième](../en/alp-002-second.md).'),
	'state/streeling/courses/alpha/de/alp-001-first.de.md': moduleFile('alp-001', 'Erstes', 'Weiter.'),
};

const EXPECTED_FILES = [
	'LICENSE',
	'courses/alpha/README.md',
	'courses/alpha/en/alp-001-first.md',
	'courses/alpha/en/alp-002-second.md',
	'courses/alpha/fr/alp-001-first.fr.md',
	'curriculum-references.json',
	'departments/alpha.department.json',
	'source.json',
	'university.json',
];

function write(file, text) {
	fs.mkdirSync(path.dirname(file), { recursive: true });
	fs.writeFileSync(file, text);
}

function demerzelRepo(dir, change) {
	for (const [file, text] of Object.entries(DEMERZEL)) write(path.join(dir, file), text);
	const env = { ...process.env, GIT_AUTHOR_DATE: '2026-01-01T00:00:00Z', GIT_COMMITTER_DATE: '2026-01-01T00:00:00Z' };
	const git = (...args) => execFileSync('git', args, { cwd: dir, env, stdio: 'ignore' });
	git('init', '-q');
	git('add', '.');
	git('-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'fixture');
	if (change === 'tracked') write(path.join(dir, 'state/streeling/courses/alpha/en/alp-001-first.md'), moduleFile('alp-001', 'Changed locally', 'Not in HEAD.'));
	if (change === 'ignored') write(path.join(dir, '.gitignore'), 'state/streeling/courses/alpha/en/alp-003-local.md\n');
	if (change === 'untracked' || change === 'ignored') write(path.join(dir, 'state/streeling/courses/alpha/en/alp-003-local.md'), moduleFile('alp-003', 'Local only', 'Not in HEAD.'));
	return execFileSync('git', ['rev-parse', 'HEAD'], { cwd: dir, encoding: 'utf8' }).trim();
}

let tmp;
let commit;
let copied;
const read = (rel) => fs.readFileSync(path.join(copied, 'streeling', rel), 'utf8');

before(() => {
	tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'streeling-copy-'));
	commit = demerzelRepo(path.join(tmp, 'demerzel'));
	copied = path.join(tmp, 'learn');
	execFileSync(process.execPath, [COPY, '--from', path.join(tmp, 'demerzel'), '--out', copied], { stdio: 'pipe' });
});

test('copies the course description and leaves the rest in Demerzel', () => {
	const files = fs.readdirSync(path.join(copied, 'streeling'), { recursive: true })
		.filter((f) => fs.statSync(path.join(copied, 'streeling', f)).isFile())
		.map((f) => f.split(path.sep).join('/'))
		.sort();
	assert.deepEqual(files, EXPECTED_FILES);
});

test('links between modules stay relative; links to files left in Demerzel point at the copied commit', () => {
	const first = read('courses/alpha/en/alp-001-first.md');
	const blob = `https://github.com/GuitarAlchemist/Demerzel/blob/${commit}`;
	assert.ok(first.includes('[the second](alp-002-second.md#start)'));
	assert.ok(first.includes(`[scenarios](${blob}/state/streeling/fixtures/alpha/alp-001/scenarios.json)`));
	assert.ok(first.includes(`[analyze.py](${blob}/scripts/streeling_fixtures/alpha/alp-001/analyze.py#L10)`));
	assert.ok(first.includes(`[a governance note](${blob}/logic/note.md)`));
	assert.ok(first.includes('[inside a fence](../../../fixtures/alpha/alp-001/scenarios.json)'), 'code blocks are copied as they are');
	assert.ok(read('courses/alpha/fr/alp-001-first.fr.md').includes('[le deuxième](../en/alp-002-second.md)'));
	assert.equal(read('courses/alpha/README.md'), DEMERZEL['state/streeling/courses/alpha/README.md']);
});

test('source.json and LICENSE record where the files come from', () => {
	assert.deepEqual(JSON.parse(read('source.json')), { repo: 'GuitarAlchemist/Demerzel', path: 'state/streeling', commit, commit_date: '2026-01-01T00:00:00Z' });
	assert.equal(read('LICENSE'), DEMERZEL.LICENSE);
});

test('pages generated from the copy keep the links the Demerzel import gave them', () => {
	const site = path.join(tmp, 'site');
	execFileSync(process.execPath, [SYNC, '--source', copied, '--out', site], { stdio: 'pipe' });
	const page = fs.readFileSync(path.join(site, 'src/content/docs/streeling/alpha/alp-001.md'), 'utf8');
	assert.ok(page.includes('[the second](../../alpha/alp-002/#start)'));
	assert.ok(page.includes(`[scenarios](https://github.com/GuitarAlchemist/Demerzel/blob/${commit}/state/streeling/fixtures/alpha/alp-001/scenarios.json)`));
});

test('a dirty Demerzel checkout is refused and nothing is copied', () => {
	for (const change of ['tracked', 'untracked', 'ignored']) {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), `streeling-copy-dirty-${change}-`));
		demerzelRepo(path.join(dir, 'demerzel'), change);
		const dest = path.join(dir, 'learn');
		write(path.join(dest, 'streeling', 'source.json'), 'keep existing source\n');
		assert.throws(
			() => execFileSync(process.execPath, [COPY, '--from', path.join(dir, 'demerzel'), '--out', dest], { stdio: 'pipe' }),
			(error) => error.stderr.toString().includes('Streeling source has local changes'),
			`${change} source must be rejected`,
		);
		assert.equal(fs.readFileSync(path.join(dest, 'streeling', 'source.json'), 'utf8'), 'keep existing source\n');
	}
});
