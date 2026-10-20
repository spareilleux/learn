#!/usr/bin/env node
// Copy the Streeling course source from a GuitarAlchemist/Demerzel checkout into streeling/, when the source moves
// to this repository. sync-streeling.mjs then generates the pages from streeling/.
//
// Usage:
//   node scripts/streeling-copy-source.mjs --from <Demerzel checkout> [--out <root>]
//
// Copied from state/streeling/: university.json, curriculum-references.json, departments/*.department.json, and
// courses/<dept>/ (its README.md and the en, fr and es folders). The de, it and pt translations, the department
// weights, the research and the fixtures stay in Demerzel. A relative link from a module to a file that is not
// copied becomes a link to that file in Demerzel at the copied commit, which is what the pages already showed.
// streeling/source.json records the commit, and streeling/LICENSE is Demerzel's.

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { englishModuleKeys, linkTarget, mapRelativeLinks, moduleKey, readText } from './streeling-lib.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DEMERZEL = 'GuitarAlchemist/Demerzel';
const FROM = 'state/streeling';
const TO = 'streeling';
const LANGS = ['en', 'fr', 'es'];
const DATA_FILES = ['university.json', 'curriculum-references.json'];

const git = (cwd, ...args) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();

function parseArgs(argv) {
	const args = { from: null, out: ROOT };
	for (let i = 0; i < argv.length; i++) {
		if (argv[i] === '--from') args.from = path.resolve(argv[++i]);
		else if (argv[i] === '--out') args.out = path.resolve(argv[++i]);
		else throw new Error(`Unknown argument: ${argv[i]}`);
	}
	if (!args.from) throw new Error('Usage: node scripts/streeling-copy-source.mjs --from <Demerzel checkout> [--out <root>]');
	return args;
}

function copy(src, dest, transform) {
	fs.mkdirSync(path.dirname(dest), { recursive: true });
	if (transform) fs.writeFileSync(dest, transform(readText(src)));
	else fs.copyFileSync(src, dest);
}

function main() {
	const { from, out } = parseArgs(process.argv.slice(2));
	// source.json names the commit; files that are not in it would make that attribution false.
	const changes = git(from, 'status', '--porcelain=v1', '--untracked-files=all', '--ignored=matching', '--', FROM);
	if (changes) throw new Error(`Streeling source has local changes under ${FROM}. Copy from a clean checkout so streeling/source.json names the commit the files come from.\n${changes}`);
	const commit = git(from, 'rev-parse', 'HEAD');
	const commitDate = git(from, 'log', '-1', '--format=%cI');
	const license = git(from, 'show', 'HEAD:LICENSE');

	const srcCourses = path.join(from, FROM, 'courses');
	const modules = englishModuleKeys(srcCourses);
	const dest = path.join(out, TO);
	for (const entry of ['courses', 'departments', ...DATA_FILES, 'source.json', 'LICENSE']) {
		fs.rmSync(path.join(dest, entry), { recursive: true, force: true });
	}

	let files = 0;
	let converted = 0;
	const toDemerzel = (repoPath) => (href, anchor, match) => {
		const target = linkTarget(repoPath, href);
		if (target.startsWith(`${FROM}/courses/`) && modules.has(moduleKey(target))) return match;
		converted++;
		return `](https://github.com/${DEMERZEL}/blob/${commit}/${target}${anchor})`;
	};

	for (const name of DATA_FILES) {
		copy(path.join(from, FROM, name), path.join(dest, name));
		files++;
	}
	for (const file of fs.readdirSync(path.join(from, FROM, 'departments')).sort()) {
		if (!file.endsWith('.department.json')) continue;
		copy(path.join(from, FROM, 'departments', file), path.join(dest, 'departments', file));
		files++;
	}
	for (const dept of fs.readdirSync(srcCourses).sort()) {
		const deptDir = path.join(srcCourses, dept);
		if (!fs.statSync(deptDir).isDirectory()) continue;
		fs.mkdirSync(path.join(dest, 'courses', dept), { recursive: true });
		if (fs.existsSync(path.join(deptDir, 'README.md'))) {
			copy(path.join(deptDir, 'README.md'), path.join(dest, 'courses', dept, 'README.md'));
			files++;
		}
		for (const lang of LANGS) {
			const langDir = path.join(deptDir, lang);
			if (!fs.existsSync(langDir)) continue;
			for (const file of fs.readdirSync(langDir).sort()) {
				if (!file.endsWith('.md')) continue;
				const repoPath = `${FROM}/courses/${dept}/${lang}/${file}`;
				// Department READMEs reach the pages unchanged (the generator copies them into the catalog section).
				const transform = file === 'README.md' ? null : (text) => mapRelativeLinks(text, toDemerzel(repoPath));
				copy(path.join(langDir, file), path.join(dest, 'courses', dept, lang, file), transform);
				files++;
			}
		}
	}

	const origin = { repo: DEMERZEL, path: FROM, commit, commit_date: commitDate };
	fs.writeFileSync(path.join(dest, 'source.json'), JSON.stringify(origin, null, 2) + '\n');
	fs.writeFileSync(path.join(dest, 'LICENSE'), license.replace(/\r\n/g, '\n') + '\n');
	console.log(`Copied ${files} files from ${DEMERZEL} ${FROM} at ${commit.slice(0, 7)} (${commitDate}) into ${TO}/`);
	console.log(`  ${converted} relative links to files left in Demerzel now point at that commit`);
}

main();
