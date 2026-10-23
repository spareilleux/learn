// Module parsing and link handling for sync-streeling.mjs, which generates the pages from streeling/.

import fs from 'node:fs';
import path from 'node:path';
import YAML from 'yaml';

export const readText = (file) => fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');

/** Split frontmatter, extract the first H1 outside code fences, and return the remaining body. */
export function parseModule(file) {
	let raw = readText(file);
	let meta = {};
	const fm = raw.match(/^---\n([\s\S]*?)\n---\n/);
	if (fm) {
		meta = YAML.parse(fm[1]) ?? {};
		raw = raw.slice(fm[0].length);
	}
	const lines = raw.split('\n');
	let fence = null;
	let title = null;
	for (let i = 0; i < lines.length; i++) {
		const marker = lines[i].trimStart().match(/^(```|~~~)/)?.[1];
		if (marker) {
			if (!fence) fence = marker;
			else if (marker === fence) fence = null;
			continue;
		}
		if (!fence && lines[i].startsWith('# ')) {
			title = lines[i].slice(2).trim();
			lines.splice(i, 1);
			break;
		}
	}
	const body = lines.join('\n').replace(/^\n+/, '');
	// Research-cycle modules (e.g. CYB-*) carry metadata as bold fields instead of frontmatter.
	const field = (name) => body.match(new RegExp(`^\\*\\*${name}:\\*\\*\\s*(.+)$`, 'm'))?.[1].trim();
	meta.date ??= field('Date');
	return { meta, title, body };
}

/**
 * Call `replace(href, anchor, match)` for each relative Markdown link `](href#anchor)` outside code fences and put
 * its return value in place of the link; `match` keeps it as it is.
 */
export function mapRelativeLinks(text, replace) {
	let fence = null;
	return text
		.split('\n')
		.map((line) => {
			const marker = line.trimStart().match(/^(```|~~~)/)?.[1];
			if (marker) {
				if (!fence) fence = marker;
				else if (marker === fence) fence = null;
				return line;
			}
			if (fence) return line;
			return line.replace(/\]\(([^)\s#]+)(#[^)\s]*)?\)/g, (match, href, anchor = '') =>
				/^[a-z]+:/i.test(href) ? match : replace(href, anchor, match),
			);
		})
		.join('\n');
}

/** Resolve a link of the file at `fromRepoPath` to a repository path. */
export const linkTarget = (fromRepoPath, href) => path.posix.normalize(path.posix.join(path.posix.dirname(fromRepoPath), href));

/** The key a link target has in the module index: its file name without the language suffix and `.md`. */
export const moduleKey = (target) => path.posix.basename(target).replace(/(\.[a-z]{2})?\.md$/i, '').toLowerCase();
