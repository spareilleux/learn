// Exact-source review receipts for generated Streeling pages.
// A matching JSON record reports a human verdict; repository review must still authenticate it.

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const RECEIPTS = 'state/streeling/review-receipts';
const COURSES = 'state/streeling/courses';
const SHA = /^[0-9a-f]{40}$/;
const MODULE = /^[a-z0-9]+-[0-9]{3}(?:-[a-z0-9-]+)?$/;
const LOCALES = new Set(['en', 'fr', 'es', 'pt', 'it', 'de']);
const KINDS = new Set(['subject', 'language', 'learner']);
const VERDICTS = new Set(['approved', 'changes_requested', 'not_assessed']);
const FIELDS = new Set(['schema_version', 'module_id', 'locale', 'kind', 'source_blob', 'source_english_blob', 'reviewed_commit', 'reviewer', 'reviewed_at', 'verdict', 'evidence']);

function courseBlobsAt(src, commit) {
	const blobs = new Map();
	const tree = execFileSync('git', ['ls-tree', '-r', '--full-tree', commit, COURSES], { cwd: src, encoding: 'utf8' });
	for (const line of tree.split('\n')) {
		const match = /^100644 blob ([0-9a-f]{40})\t(.+)$/.exec(line);
		if (match) blobs.set(match[2], match[1]);
	}
	return blobs;
}

function validateReceipt(receipt, name) {
	const invalid = (reason) => { throw new Error(`Invalid Streeling review receipt ${name}: ${reason}`); };
	if (!receipt || typeof receipt !== 'object' || Array.isArray(receipt)) invalid('expected object');
	if (Object.keys(receipt).some((key) => !FIELDS.has(key))) invalid('unknown field');
	if (receipt.schema_version !== '0.1.0') invalid('schema_version must be 0.1.0');
	if (!MODULE.test(receipt.module_id ?? '')) invalid('invalid module_id');
	if (!LOCALES.has(receipt.locale)) invalid('invalid locale');
	if (!KINDS.has(receipt.kind)) invalid('invalid kind');
	if (!SHA.test(receipt.source_blob ?? '')) invalid('invalid source_blob');
	if (!SHA.test(receipt.reviewed_commit ?? '')) invalid('invalid reviewed_commit');
	if (typeof receipt.reviewer !== 'string' || !receipt.reviewer.trim()) invalid('reviewer is required');
	const timestamp = typeof receipt.reviewed_at === 'string' && /^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.\d+)?Z$/.exec(receipt.reviewed_at);
	if (!timestamp || Number.isNaN(Date.parse(receipt.reviewed_at))) invalid('reviewed_at must be a UTC date-time');
	const parsed = new Date(receipt.reviewed_at);
	if ([parsed.getUTCFullYear(), parsed.getUTCMonth() + 1, parsed.getUTCDate(), parsed.getUTCHours(), parsed.getUTCMinutes(), parsed.getUTCSeconds()].some((value, i) => value !== Number(timestamp[i + 1]))) invalid('reviewed_at is not a real UTC date-time');
	if (!VERDICTS.has(receipt.verdict)) invalid('invalid verdict');
	if (typeof receipt.evidence !== 'string' || !receipt.evidence.trim()) invalid('evidence is required');
	if (receipt.kind === 'subject' && receipt.locale !== 'en') invalid('subject review must bind English source');
	if (receipt.kind === 'language') {
		if (receipt.locale === 'en') invalid('language review must bind a translation');
		if (!SHA.test(receipt.source_english_blob ?? '')) invalid('source_english_blob is required for language review');
	} else if ('source_english_blob' in receipt) invalid('source_english_blob is only for language review');
	const expected = `${receipt.module_id}.${receipt.locale}.${receipt.kind}.json`;
	if (name !== expected) invalid(`filename must be ${expected}`);
}

export function loadReviewIndex(src, sha) {
	const blobByPath = courseBlobsAt(src, sha);
	const receipts = new Map();
	const dir = path.join(src, RECEIPTS);
	if (fs.existsSync(dir)) {
		for (const name of fs.readdirSync(dir).filter((name) => name.endsWith('.json')).sort()) {
			let receipt;
			try { receipt = JSON.parse(fs.readFileSync(path.join(dir, name), 'utf8')); }
			catch (error) { throw new Error(`Invalid Streeling review receipt ${name}: ${error.message}`); }
			validateReceipt(receipt, name);
			const key = `${receipt.module_id}.${receipt.locale}.${receipt.kind}`;
			if (receipts.has(key)) throw new Error(`Duplicate Streeling review receipt ${key}`);
			receipts.set(key, { ...receipt, path: `${RECEIPTS}/${name}` });
		}
	}
	return { src, blobByPath, reviewedTrees: new Map([[sha, blobByPath]]), receipts };
}

function assertReviewedSource(index, receipt, sourcePath, englishPath) {
	let reviewed = index.reviewedTrees.get(receipt.reviewed_commit);
	if (!reviewed) {
		try { reviewed = courseBlobsAt(index.src, receipt.reviewed_commit); }
		catch { throw new Error(`Streeling review receipt ${receipt.path} references an unavailable reviewed_commit`); }
		index.reviewedTrees.set(receipt.reviewed_commit, reviewed);
	}
	if (reviewed.get(sourcePath) !== receipt.source_blob ||
		(receipt.kind === 'language' && reviewed.get(englishPath) !== receipt.source_english_blob)) {
		throw new Error(`Streeling review receipt ${receipt.path} does not match its reviewed_commit`);
	}
}

export function reviewStatus(index, moduleId, locale, sourcePath, englishPath) {
	const ownBlob = index.blobByPath.get(sourcePath);
	const englishBlob = index.blobByPath.get(englishPath);
	if (!ownBlob || !englishBlob) throw new Error(`Missing Streeling source blob for ${moduleId} ${locale}`);
	const matching = (lang, kind, blob) => {
		const receipt = index.receipts.get(`${moduleId}.${lang}.${kind}`);
		if (receipt?.source_blob !== blob || (kind === 'language' && receipt.source_english_blob !== englishBlob)) return null;
		assertReviewedSource(index, receipt, kind === 'subject' ? englishPath : sourcePath, englishPath);
		return receipt;
	};
	return {
		subject: matching('en', 'subject', englishBlob),
		language: locale === 'en' ? null : matching(locale, 'language', ownBlob),
		learner: matching(locale, 'learner', ownBlob),
	};
}
