#!/usr/bin/env node
// Generate the Streeling University pages from the course source in streeling/.
//
// Usage:
//   npm run sync:streeling                                      # read streeling/ in this repository
//   node scripts/sync-streeling.mjs --source <dir> --out <dir>   # another root with streeling/ (the tests do)
//
// The source was copied once from GuitarAlchemist/Demerzel, at the commit streeling/source.json names, and is
// written here since. Change a module in streeling/courses/, then run this script and commit both: the pages are
// never edited by hand.
//
// Generated (overwritten on every run): src/content/docs/{,fr/,es/}streeling/** except journal.md,
// src/streeling-sidebar.json and streeling.lock.json. Journals are created once and never touched again.
//
// A module page says a review happened only when streeling/review-receipts/ holds a receipt for that very file, in
// that language, at its current Git blob. Edit the file and the verdict stops showing until someone reviews the
// new text. See streeling/review-receipts/README.md.

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import YAML from 'yaml';
import { linkTarget, mapRelativeLinks, moduleKey, parseModule, readText } from './streeling-lib.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SITE_REPO = 'spareilleux/learn';
const DEMERZEL = 'GuitarAlchemist/Demerzel';
const STREELING = 'streeling';
const COURSES = `${STREELING}/courses`;
const RECEIPTS = `${STREELING}/review-receipts`;
const KINDS = ['subject', 'language', 'learner'];
const VERDICTS = ['approved', 'changes_requested', 'not_assessed'];
// Links on the pages lead to the source on main, which is also the revision the site is built from.
const blobUrl = (repoPath) => `https://github.com/${SITE_REPO}/blob/main/${repoPath}`;
const editUrl = (repoPath) => `https://github.com/${SITE_REPO}/edit/main/${repoPath}`;

const outDirs = (root) => ({
	en: path.join(root, 'src/content/docs/streeling'),
	fr: path.join(root, 'src/content/docs/fr/streeling'),
	es: path.join(root, 'src/content/docs/es/streeling'),
});
let OUT = outDirs(ROOT);

// English is the source; each translation is read from `<dept>/<lang>/<stem>.<lang>.md` when Demerzel provides it.
const LANGS = ['en', 'fr', 'es'];
const TRANSLATIONS = LANGS.filter((lang) => lang !== 'en');

const FR_DEPARTMENTS = {
	'audio-engineering': 'Ingénierie audio',
	'cognitive-science': 'Sciences cognitives',
	'computer-science': 'Informatique',
	cybernetics: 'Cybernétique',
	'data-visualization': 'Visualisation de données',
	futurology: 'Futurologie',
	'guitar-acoustics': 'Acoustique de la guitare et synthèse sonore',
	'guitar-alchemist-academy': 'Guitar Alchemist Academy',
	'guitar-studies': 'Études de guitare',
	'information-theory': "Théorie de l'information",
	'ix-research': 'Recherche sur IX',
	mathematics: 'Mathématiques',
	music: 'Musique',
	musicology: 'Musicologie',
	'network-science': 'Science des réseaux',
	philosophy: 'Philosophie',
	physics: 'Physique',
	'product-management': 'Gestion de produit et de projet',
	psychohistory: 'Psychohistoire',
	semiotics: 'Sémiotique',
	'visual-computing': 'Informatique visuelle',
	'world-music-languages': 'Musiques et langues du monde',
};

const ES_DEPARTMENTS = {
	'audio-engineering': 'Ingeniería de audio',
	'cognitive-science': 'Ciencia cognitiva',
	'computer-science': 'Ciencias de la computación',
	cybernetics: 'Cibernética',
	'data-visualization': 'Visualización de datos',
	futurology: 'Futurología',
	'guitar-acoustics': 'Acústica de la guitarra y síntesis sonora',
	'guitar-alchemist-academy': 'Guitar Alchemist Academy',
	'guitar-studies': 'Estudios de guitarra',
	'information-theory': 'Teoría de la información',
	'ix-research': 'Investigación sobre IX',
	mathematics: 'Matemáticas',
	music: 'Música',
	musicology: 'Musicología',
	'network-science': 'Ciencia de redes',
	philosophy: 'Filosofía',
	physics: 'Física',
	'product-management': 'Gestión de productos y proyectos',
	psychohistory: 'Psicohistoria',
	semiotics: 'Semiótica',
	'visual-computing': 'Computación visual',
	'world-music-languages': 'Músicas y lenguas del mundo',
};

const DEPARTMENTS = { fr: FR_DEPARTMENTS, es: ES_DEPARTMENTS };

const LEVELS = {
	fr: { beginner: 'débutant', intermediate: 'intermédiaire', advanced: 'avancé' },
	es: { beginner: 'principiante', intermediate: 'intermedio', advanced: 'avanzado' },
};

const DURATION_UNITS = {
	fr: { minute: 'minute', minutes: 'minutes', hour: 'heure', hours: 'heures' },
	es: { minute: 'minuto', minutes: 'minutos', hour: 'hora', hours: 'horas' },
};

function localizedDuration(lang, value) {
	if (typeof value !== 'string') return value;
	return value.replace(/\b(minutes?|hours?)\b/gi, (unit) => DURATION_UNITS[lang]?.[unit.toLowerCase()] ?? unit);
}

const T = {
	en: {
		overview: 'Overview',
		journal: 'Journal',
		generated: (dept) => `Generated by the Demerzel *${dept}* department.`,
		review: {
			kinds: { subject: 'Subject review', language: 'Language review', learner: 'Learner trial' },
			verdicts: { approved: 'approved', changes_requested: 'changes requested', not_assessed: 'not assessed' },
			colon: ': ',
			evidence: 'evidence',
			none: 'No review of this text is recorded yet.',
			noOther: 'No other review of this text is recorded.',
			stale: (n) => (n === 1 ? 'One was recorded for an earlier version, which has changed since.' : `${n} were recorded for earlier versions, which have changed since.`),
		},
		caution: (pages, reviewed, stale) =>
			(reviewed === 0
				? `These modules were written by AI departments, and no review is recorded for any of their **${pages}** lesson pages yet.`
				: `These modules were written by AI departments. A review is recorded for **${reviewed}** of their **${pages}** lesson pages, and ${reviewed === 1 ? 'that page says' : 'each of those pages says'} which review and its verdict` +
					(pages > reviewed ? `; the other **${pages - reviewed}** have none.` : '.')) +
			(stale === 0 ? '' : stale === 1 ? ' One older review no longer applies: its text has changed.' : ` ${stale} older reviews no longer apply: their text has changed.`),
		source: 'View source',
		myJournal: 'My journal',
		prerequisites: 'Prerequisites',
		modules: 'Modules',
		noModules: 'No modules produced yet.',
		catalog: 'Course catalog (planned)',
		domain: 'Domain',
	},
	fr: {
		overview: 'Présentation',
		journal: 'Journal',
		generated: (dept) => `Généré par le département *${dept}* de Demerzel.`,
		review: {
			kinds: { subject: 'Relecture du fond', language: 'Relecture de la langue', learner: "Mise à l'essai par un apprenant" },
			verdicts: { approved: 'approuvée', changes_requested: 'modifications demandées', not_assessed: 'non évaluée' },
			colon: ' : ',
			evidence: 'preuve',
			none: "Aucune relecture de ce texte n'est encore consignée.",
			noOther: "Aucune autre relecture de ce texte n'est consignée.",
			stale: (n) => (n === 1 ? 'Une relecture avait été consignée pour une version antérieure, qui a changé depuis.' : `${n} relectures avaient été consignées pour des versions antérieures, qui ont changé depuis.`),
		},
		caution: (pages, reviewed, stale) =>
			(reviewed === 0
				? `Ces modules ont été écrits par des départements IA, et aucune relecture n'est encore consignée pour leurs **${pages}** pages de cours.`
				: `Ces modules ont été écrits par des départements IA. Une relecture est consignée pour **${reviewed}** de leurs **${pages}** pages de cours, et ${reviewed === 1 ? 'cette page dit' : 'chacune de ces pages dit'} laquelle et son verdict` +
					(pages > reviewed ? ` ; les **${pages - reviewed}** autres n'en ont aucune.` : '.')) +
			(stale === 0 ? '' : stale === 1 ? ' Une relecture plus ancienne ne vaut plus : son texte a changé.' : ` ${stale} relectures plus anciennes ne valent plus : leur texte a changé.`),
		source: 'Voir la source',
		myJournal: 'Mon journal',
		prerequisites: 'Prérequis',
		modules: 'Modules',
		noModules: "Aucun module produit pour l'instant.",
		catalog: 'Catalogue de cours (prévu)',
		domain: 'Domaine',
		englishOnly: 'en anglais',
	},
	es: {
		overview: 'Presentación',
		journal: 'Diario',
		generated: (dept) => `Generado por el departamento *${dept}* de Demerzel.`,
		review: {
			kinds: { subject: 'Revisión del contenido', language: 'Revisión del idioma', learner: 'Prueba con un estudiante' },
			verdicts: { approved: 'aprobada', changes_requested: 'cambios solicitados', not_assessed: 'no evaluada' },
			colon: ': ',
			evidence: 'evidencia',
			none: 'Todavía no hay ninguna revisión registrada de este texto.',
			noOther: 'No hay ninguna otra revisión registrada de este texto.',
			stale: (n) => (n === 1 ? 'Se registró una para una versión anterior, que ha cambiado desde entonces.' : `Se registraron ${n} para versiones anteriores, que han cambiado desde entonces.`),
		},
		caution: (pages, reviewed, stale) =>
			(reviewed === 0
				? `Estos módulos fueron escritos por departamentos de IA, y todavía no hay ninguna revisión registrada para sus **${pages}** páginas de cursos.`
				: `Estos módulos fueron escritos por departamentos de IA. Hay una revisión registrada para **${reviewed}** de sus **${pages}** páginas de cursos, y ${reviewed === 1 ? 'esa página dice' : 'cada una de esas páginas dice'} cuál y su veredicto` +
					(pages > reviewed ? `; las otras **${pages - reviewed}** no tienen ninguna.` : '.')) +
			(stale === 0 ? '' : stale === 1 ? ' Una revisión más antigua ya no vale: su texto ha cambiado.' : ` ${stale} revisiones más antiguas ya no valen: su texto ha cambiado.`),
		source: 'Ver la fuente',
		myJournal: 'Mi diario',
		prerequisites: 'Requisitos previos',
		modules: 'Módulos',
		noModules: 'Todavía no se ha producido ningún módulo.',
		catalog: 'Catálogo de cursos (previsto)',
		domain: 'Dominio',
		englishOnly: 'en inglés',
	},
};

// ---------------------------------------------------------------------------
// Arguments

function parseArgs(argv) {
	const args = { source: null, out: null };
	for (let i = 0; i < argv.length; i++) {
		if (argv[i] === '--source') args.source = path.resolve(argv[++i]);
		else if (argv[i] === '--out') args.out = path.resolve(argv[++i]);
		else if (argv[i] === '--ref') throw new Error('--ref is gone: the source lives in streeling/ now, copied once from GuitarAlchemist/Demerzel at the commit streeling/source.json names. Write courses in streeling/courses/.');
		else throw new Error(`Unknown argument: ${argv[i]}`);
	}
	return args;
}

// ---------------------------------------------------------------------------
// Parsing

function moduleCode(id) {
	const m = id.match(/^([a-z]+)-(\d+)/i);
	return m ? `${m[1].toUpperCase()}-${m[2]}` : id.toUpperCase();
}

function shortTitle(title, code) {
	return title
		.replace(new RegExp(`^${code}\\s*:\\s*`, 'i'), '')
		.split(/:\s| — /)[0]
		.trim();
}

// ---------------------------------------------------------------------------
// Link rewriting

// A module with no page in `lang` keeps its URL in that locale: Starlight serves the English page there, with its own
// "not translated" notice. Every link to it carries this label, so the reader knows before clicking.
function englishOnlyLabel(lang, mod) {
	return lang !== 'en' && !mod[lang] ? ` *(${T[lang].englishOnly})*` : '';
}

// A link to another module becomes a link to its page. A link to any other file of this repository (a fixture, a
// script) leads to that file on GitHub. Anything else is a broken link, reported in `problems`.
function rewriteLinks(body, { src, srcRepoPath, moduleIndex, lang, problems }) {
	const stats = { internal: 0, github: 0 };
	const out = mapRelativeLinks(body, (href, anchor, match) => {
		const target = linkTarget(srcRepoPath, href);
		const known = target.startsWith(`${COURSES}/`) && moduleIndex.get(moduleKey(target));
		if (known) {
			stats.internal++;
			return `](../../${known.dept}/${known.id}/${anchor})${englishOnlyLabel(lang, known)}`;
		}
		if (!target.startsWith('../') && fs.existsSync(path.join(src, target))) {
			stats.github++;
			return `](${blobUrl(target)}${anchor})`;
		}
		problems.push(`${srcRepoPath}: ${href} (${target} is not a file of this repository)`);
		return match;
	});
	return { body: out, stats };
}

// ---------------------------------------------------------------------------
// Rendering

function frontmatter(data) {
	return `---\n${YAML.stringify(data, { lineWidth: 0 }).trimEnd()}\n---\n\n`;
}

function write(file, content) {
	fs.mkdirSync(path.dirname(file), { recursive: true });
	fs.writeFileSync(file, content);
}

// Module and department pages, kept in memory until every link has been checked.
const pending = [];
const stage = (file, content) => pending.push([file, content]);

function cleanOutput(dir) {
	if (!fs.existsSync(dir)) return;
	for (const entry of fs.readdirSync(dir)) {
		if (entry === 'journal.md') continue;
		fs.rmSync(path.join(dir, entry), { recursive: true, force: true });
	}
}

// ---------------------------------------------------------------------------
// Review receipts

/** The Git blob id of a text with LF line endings, which is how .gitattributes has Git store every course file. */
function gitBlob(text) {
	const bytes = Buffer.from(text, 'utf8');
	return crypto.createHash('sha1').update(`blob ${bytes.length}\0`).update(bytes).digest('hex');
}

// Only a complete receipt can say a review happened. An incomplete one leaves the page pending here, and
// check-streeling-records.py fails it, so it cannot reach main unnoticed.
function complete(r) {
	return (
		r !== null &&
		typeof r === 'object' &&
		typeof r.source === 'string' &&
		typeof r.blob === 'string' &&
		/^[0-9a-f]{40}$/.test(r.blob) &&
		KINDS.includes(r.kind) &&
		typeof r.reviewer === 'string' &&
		r.reviewer.trim() !== '' &&
		typeof r.date === 'string' &&
		/^\d{4}-\d{2}-\d{2}$/.test(r.date) &&
		VERDICTS.includes(r.verdict) &&
		typeof r.evidence === 'string' &&
		/^https:\/\/[^\s()]+$/.test(r.evidence)
	);
}

function loadReceipts(src) {
	const dir = path.join(src, RECEIPTS);
	if (!fs.existsSync(dir)) return [];
	const receipts = [];
	for (const file of fs.readdirSync(dir).sort()) {
		if (!file.endsWith('.json')) continue;
		let receipt;
		try {
			receipt = JSON.parse(readText(path.join(dir, file)));
		} catch {
			continue;
		}
		if (complete(receipt)) receipts.push({ ...receipt, file });
	}
	return receipts;
}

/**
 * What the receipts say about one file at one blob: the latest verdict of each kind given on exactly this text, and
 * how many verdicts were given on earlier texts of the file, for a kind with no verdict on this one.
 */
function reviewState(receipts, source, blob) {
	const mine = receipts.filter((r) => r.source === source);
	const current = KINDS.map((kind) =>
		mine
			.filter((r) => r.kind === kind && r.blob === blob)
			.sort((a, b) => a.date.localeCompare(b.date) || a.file.localeCompare(b.file))
			.at(-1),
	).filter(Boolean);
	const stale = mine.filter((r) => r.blob !== blob && !current.some((c) => c.kind === r.kind)).length;
	return { current, stale };
}

const escapeMarkdown = (text) => text.trim().replace(/[\\`*_[\]<>|]/g, '\\$&');

function reviewText(lang, { current, stale }) {
	const r = T[lang].review;
	const said = current.map(
		(c) => `${r.kinds[c.kind]}${r.colon}${r.verdicts[c.verdict]} (${escapeMarkdown(c.reviewer)}, ${c.date}, [${r.evidence}](${c.evidence})).`,
	);
	if (current.length < KINDS.length) said.push(current.length ? r.noOther : r.none);
	if (stale) said.push(r.stale(stale));
	return said.join(' ');
}

function banner(lang, mod, dept, sourceUrl, moduleIndex, review) {
	const t = T[lang];
	const level = mod.meta.level && (LEVELS[lang]?.[mod.meta.level] ?? mod.meta.level);
	const facts = [`**${mod.code}**`, mod.meta.course, level, localizedDuration(lang, mod.meta.estimated_duration), mod.meta.date]
		.filter(Boolean)
		.join(' · ');
	const lines = [
		':::note[Streeling University]',
		facts,
		'',
		`${t.generated(dept.label[lang])} ${reviewText(lang, review)} [${t.source}](${sourceUrl}) · [${t.myJournal}](../../journal/)`,
	];
	const prereqs = [].concat(mod.meta.prerequisites ?? []);
	if (prereqs.length) {
		const items = prereqs.map((p) => {
			const known = moduleIndex.get(String(p).toLowerCase());
			return known ? `[${moduleCode(known.id)}](../../${known.dept}/${known.id}/)${englishOnlyLabel(lang, known)}` : String(p);
		});
		lines.push('', `${t.prerequisites}: ${items.join(', ')}`);
	}
	lines.push(':::', '');
	return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Main

function main() {
	const args = parseArgs(process.argv.slice(2));
	const outRoot = args.out ?? ROOT;
	OUT = outDirs(outRoot);
	const src = args.source ?? ROOT;
	const origin = JSON.parse(readText(path.join(src, STREELING, 'source.json')));
	const university = JSON.parse(readText(path.join(src, STREELING, 'university.json')));

	// Discover departments and modules.
	const departments = [];
	const moduleIndex = new Map();
	for (const deptId of fs.readdirSync(path.join(src, COURSES)).sort()) {
		const deptDir = path.join(src, COURSES, deptId);
		if (!fs.statSync(deptDir).isDirectory()) continue;
		const deptJson = path.join(src, STREELING, 'departments', `${deptId}.department.json`);
		const info = fs.existsSync(deptJson) ? JSON.parse(readText(deptJson)) : {};
		const enLabel = (info.full_name ?? deptId.replace(/(^|-)(\w)/g, (_, s, c) => (s ? ' ' : '') + c.toUpperCase()))
			.replace(/^Department of /, '');
		const dept = {
			id: deptId,
			info,
			label: { en: enLabel, ...Object.fromEntries(TRANSLATIONS.map((lang) => [lang, DEPARTMENTS[lang][deptId] ?? enLabel])) },
			modules: [],
			catalog: null,
		};
		const enDir = path.join(deptDir, 'en');
		const readmes = [path.join(enDir, 'README.md'), path.join(deptDir, 'README.md')].filter(fs.existsSync);
		if (readmes.length) {
			const { body } = parseModule(readmes[0]);
			if (!/no courses produced yet/i.test(body)) dept.catalog = body;
		}
		if (fs.existsSync(enDir)) {
			for (const file of fs.readdirSync(enDir).sort()) {
				if (!file.endsWith('.md') || file === 'README.md') continue;
				const stem = file.replace(/\.md$/, '');
				const parsed = parseModule(path.join(enDir, file));
				const id = String(parsed.meta.module_id ?? stem).toLowerCase();
				const mod = { id, stem, code: moduleCode(id), dept: deptId, en: parsed };
				for (const lang of TRANSLATIONS) {
					const file = path.join(deptDir, lang, `${stem}.${lang}.md`);
					mod[lang] = fs.existsSync(file) ? parseModule(file) : null;
				}
				mod.meta = parsed.meta;
				dept.modules.push(mod);
				moduleIndex.set(id, mod);
				moduleIndex.set(stem.toLowerCase(), mod);
			}
		}
		departments.push(dept);
	}

	const receipts = loadReceipts(src);
	const problems = [];
	const totals = { ...Object.fromEntries(LANGS.map((lang) => [lang, 0])), internal: 0, github: 0, reviewed: 0, stale: 0 };
	for (const dept of departments) {
		dept.modules.forEach((mod, i) => {
			for (const lang of LANGS) {
				const parsed = mod[lang];
				if (!parsed) continue;
				const srcFile = lang === 'en' ? `${mod.stem}.md` : `${mod.stem}.${lang}.md`;
				const srcRepoPath = `${COURSES}/${dept.id}/${lang}/${srcFile}`;
				const { body, stats } = rewriteLinks(parsed.body, { src, srcRepoPath, moduleIndex, lang, problems });
				totals.internal += stats.internal;
				totals.github += stats.github;
				const review = reviewState(receipts, srcRepoPath, gitBlob(readText(path.join(src, srcRepoPath))));
				totals.reviewed += review.current.length > 0;
				totals.stale += review.stale;
				const title = parsed.title ?? mod.en.title ?? mod.code;
				const page =
					frontmatter({
						title,
						description: [parsed.meta.course ?? mod.meta.course, dept.label[lang]].filter(Boolean).join(' — '),
						sidebar: { label: `${mod.code} · ${shortTitle(title, mod.code)}`, order: i + 1 },
						editUrl: editUrl(srcRepoPath),
					}) +
					banner(lang, { ...mod, meta: { ...mod.meta, ...parsed.meta } }, dept, blobUrl(srcRepoPath), moduleIndex, review) +
					'\n' +
					body;
				stage(path.join(OUT[lang], dept.id, `${mod.id}.md`), page);
				totals[lang]++;
			}
		});

		for (const lang of LANGS) {
			const t = T[lang];
			const parts = [
				frontmatter({
					title: dept.label[lang],
					description: dept.info.domain ?? `Streeling University — ${dept.label[lang]}`,
					sidebar: { label: t.overview, order: 0 },
				}),
			];
			if (dept.info.domain) parts.push(`**${t.domain}:** ${dept.info.domain}\n`);
			parts.push(`## ${t.modules}\n`);
			if (dept.modules.length) {
				for (const mod of dept.modules) {
					const title = (lang !== 'en' && mod[lang]?.title) || mod.en.title || mod.code;
					parts.push(`- [${mod.code} · ${title}](${mod.id}/)${englishOnlyLabel(lang, mod)}`);
				}
				parts.push('');
			} else {
				parts.push(`${t.noModules}\n`);
			}
			if (dept.catalog) parts.push(`## ${t.catalog}\n`, dept.catalog);
			stage(path.join(OUT[lang], dept.id, 'index.md'), parts.join('\n'));
		}
	}

	// Nothing is written while a link is broken, so a failed run leaves the previous pages in place.
	if (problems.length) throw new Error(`Relative links must lead to a module or to a file of this repository:\n${problems.join('\n')}`);
	for (const lang of LANGS) cleanOutput(OUT[lang]);
	for (const [file, content] of pending) write(file, content);

	writeOverview(university, departments, origin, totals);
	writeJournals(departments);
	writeSidebar(departments, outRoot);

	// No timestamp: the same source must give the same files, so that a check can regenerate and compare them.
	const lock = {
		source: STREELING,
		copied_from: origin,
		departments: departments.length,
		modules: Object.fromEntries(LANGS.map((lang) => [lang, totals[lang]])),
	};
	write(path.join(outRoot, 'streeling.lock.json'), JSON.stringify(lock, null, 2) + '\n');

	console.log(`Streeling from ${STREELING}/ (copied from ${origin.repo} at ${origin.commit.slice(0, 7)})`);
	console.log(`  departments: ${departments.length}, modules: ${LANGS.map((lang) => `${totals[lang]} ${lang}`).join(' / ')}`);
	console.log(`  links: ${totals.internal} rewritten to site pages, ${totals.github} pointed at GitHub`);
	console.log(`  reviews: ${receipts.length} complete receipts, a current one on ${totals.reviewed} pages, ${totals.stale} on earlier texts`);
}

function writeOverview(university, departments, origin, totals) {
	const research = departments.find((department) => department.id === 'ix-research');
	const extra = research?.modules.length ?? 0;
	const core = totals.en - extra;
	const target = (departments.length - Number(Boolean(research))) * 25;
	const localizedPages = LANGS.reduce((sum, lang) => sum + totals[lang], 0);
	const caution = (lang) => T[lang].caution(localizedPages, totals.reviewed, totals.stale);
	const totalRow = `| **Total** | **${totals.en}** | **${totals.fr}** | **${totals.es}** |`;
	const short = origin.commit.slice(0, 7);
	const date = origin.commit_date.slice(0, 10);
	const sourceLink = `[\`${SITE_REPO}\` → \`${COURSES}\`](https://github.com/${SITE_REPO}/tree/main/${COURSES})`;
	const originLink = `[\`${origin.repo}\` → \`${origin.path}/courses\`](https://github.com/${origin.repo}/tree/${origin.commit}/${origin.path}/courses)`;
	const supplementLinks = (label) => (origin.supplements ?? []).map((manifest) => `- [${label}](${blobUrl(manifest)})\n`).join('');
	const rows = (lang) =>
		departments
			.map((d) => {
				const translated = TRANSLATIONS.map((t) => d.modules.filter((m) => m[t]).length);
				return `| [${d.label[lang]}](${d.id}/) | ${d.modules.length} | ${translated.join(' | ')} |`;
			})
			.join('\n');

	write(
		path.join(OUT.en, 'index.md'),
		frontmatter({
			title: 'Streeling University',
			description: 'Modules produced by the Demerzel departments, imported to study them and keep a learning journal.',
			sidebar: { label: 'Overview', order: 0 },
		}) +
			`## Published course count\n\n**${core} / ${target}** core curriculum modules. Additional IX Research modules: **${extra}**.\n\n**${totals.en}** distinct course modules: English **${totals.en}**, French **${totals.fr}**, Spanish **${totals.es}** — **${localizedPages}** localized lesson pages. Translations are not additional distinct courses.\n\n` +
			`> ${university.mandate}\n\n` +
			`Streeling University is the knowledge layer of [Demerzel](https://github.com/${DEMERZEL}), the governance framework of the GuitarAlchemist ecosystem. Each department is an agent persona that researches its discipline and writes course modules.\n\n` +
			`:::caution[Generated content]\n${caution('en')} Unlike the other courses on this site, nothing here has been tested on my machine yet — my [journal](journal/) tracks what I have actually studied and verified.\n:::\n\n` +
			`## Departments\n\n| Department | Modules | French | Spanish |\n|---|---|---|---|\n${rows('en')}\n${totalRow}\n\n` +
			`## Provenance\n\n- Initial source copy: ${sourceLink}, copied from ${originLink} at commit \`${short}\` (${date}), MIT license.\n` +
			supplementLinks('Additional source provenance') +
			`- Generated with \`npm run sync:streeling\` from \`${STREELING}/\`: change a module there, not on these pages — only \`journal.md\` is kept between syncs.\n`,
	);

	write(
		path.join(OUT.fr, 'index.md'),
		frontmatter({
			title: 'Streeling University',
			description: 'Modules produits par les départements de Demerzel, importés pour les étudier et tenir un journal.',
			sidebar: { label: 'Présentation', order: 0 },
		}) +
			`## Nombre de cours publiés\n\n**${core} / ${target}** modules du programme. Modules IX Research hors quota : **${extra}**.\n\n**${totals.en}** cours distincts : anglais **${totals.en}**, français **${totals.fr}**, espagnol **${totals.es}** — **${localizedPages}** pages de cours au total. Les traductions ne sont pas des cours supplémentaires.\n\n` +
			`> ${university.mandate}\n\n` +
			`Streeling University est la couche de connaissances de [Demerzel](https://github.com/${DEMERZEL}), le cadre de gouvernance de l'écosystème GuitarAlchemist. Chaque département est une persona d'agent qui étudie sa discipline et rédige des modules de cours.\n\n` +
			`:::caution[Contenu généré]\n${caution('fr')} Contrairement aux autres cours du site, rien ici n'a encore été testé sur ma machine — mon [journal](journal/) suit ce que j'ai réellement étudié et vérifié.\n:::\n\n` +
			`## Départements\n\n| Département | Modules | En français | En espagnol |\n|---|---|---|---|\n${rows('fr')}\n${totalRow}\n\n` +
			`## Provenance\n\n- Copie initiale des sources : ${sourceLink}, copiée depuis ${originLink} au commit \`${short}\` (${date}), licence MIT.\n` +
			supplementLinks('Provenance des sources supplémentaires') +
			`- Généré avec \`npm run sync:streeling\` depuis \`${STREELING}/\` : on modifie un module là, pas sur ces pages — seul \`journal.md\` est conservé entre deux synchronisations.\n`,
	);

	write(
		path.join(OUT.es, 'index.md'),
		frontmatter({
			title: 'Streeling University',
			description: 'Módulos producidos por los departamentos de Demerzel, importados para estudiarlos y llevar un diario de aprendizaje.',
			sidebar: { label: 'Presentación', order: 0 },
		}) +
			`## Recuento de cursos publicados\n\n**${core} / ${target}** módulos del programa. Módulos adicionales de IX Research: **${extra}**.\n\n**${totals.en}** cursos distintos: inglés **${totals.en}**, francés **${totals.fr}**, español **${totals.es}** — **${localizedPages}** páginas de cursos en total. Las traducciones no son cursos adicionales.\n\n` +
			`> ${university.mandate}\n\n` +
			`Streeling University es la capa de conocimiento de [Demerzel](https://github.com/${DEMERZEL}), el marco de gobernanza del ecosistema GuitarAlchemist. Cada departamento es una persona de agente que investiga su disciplina y redacta módulos de curso.\n\n` +
			`:::caution[Contenido generado]\n${caution('es')} A diferencia de los demás cursos del sitio, nada de lo que hay aquí se ha probado todavía en mi máquina — mi [diario](journal/) registra lo que realmente he estudiado y verificado.\n:::\n\n` +
			`## Departamentos\n\n| Departamento | Módulos | En francés | En español |\n|---|---|---|---|\n${rows('es')}\n${totalRow}\n\n` +
			`## Procedencia\n\n- Copia inicial de las fuentes: ${sourceLink}, copiada de ${originLink} en el commit \`${short}\` (${date}), licencia MIT.\n` +
			supplementLinks('Procedencia de las fuentes adicionales') +
			`- Generado con \`npm run sync:streeling\` desde \`${STREELING}/\`: se modifica un módulo allí, no en estas páginas — solo \`journal.md\` se conserva entre sincronizaciones.\n`,
	);
}

function writeJournals(departments) {
	const all = departments.flatMap((d) => d.modules);
	const checklist = (lang) =>
		departments
			.filter((d) => d.modules.length)
			.map((d) => {
				const items = d.modules.map((m) => {
					const title = (lang !== 'en' && m[lang]?.title) || m.en.title || m.code;
					return `- [ ] [${m.code} · ${shortTitle(title, m.code)}](../${d.id}/${m.id}/)${englishOnlyLabel(lang, m)} <!-- ${m.id} -->`;
				});
				return `### ${d.label[lang]}\n\n${items.join('\n')}`;
			})
			.join('\n\n');

	const templates = {
		en:
			frontmatter({ title: 'Streeling journal', description: 'What I studied in Streeling University, what I verified, and what I found wrong.', sidebar: { label: 'Journal', order: 1 } }) +
			`Tick a module once studied. Under **Notes**, add a dated entry: what I understood, what I tested, and any error found in the module (with a source).\n\n## Progress\n\n${checklist('en')}\n\n## Notes\n\n<!-- ## YYYY-MM-DD — CODE · Title -->\n`,
		fr:
			frontmatter({ title: 'Journal Streeling', description: "Ce que j'ai étudié à Streeling University, ce que j'ai vérifié et ce que j'ai trouvé d'erroné.", sidebar: { label: 'Journal', order: 1 } }) +
			`Coche un module une fois étudié. Sous **Notes**, ajoute une entrée datée : ce que j'ai compris, ce que j'ai testé, et toute erreur trouvée dans le module (avec une source).\n\n## Progression\n\n${checklist('fr')}\n\n## Notes\n\n<!-- ## AAAA-MM-JJ — CODE · Titre -->\n`,
		es:
			frontmatter({ title: 'Diario Streeling', description: 'Lo que estudié en Streeling University, lo que verifiqué y los errores que encontré.', sidebar: { label: 'Diario', order: 1 } }) +
			`Marca un módulo una vez estudiado. En **Notas**, añade una entrada fechada: lo que entendí, lo que probé y cualquier error encontrado en el módulo (con una fuente).\n\n## Progreso\n\n${checklist('es')}\n\n## Notas\n\n<!-- ## AAAA-MM-DD — CÓDIGO · Título -->\n`,
	};

	for (const lang of LANGS) {
		const file = path.join(OUT[lang], 'journal.md');
		if (!fs.existsSync(file)) {
			write(file, templates[lang]);
			continue;
		}
		const text = readText(file);
		const missing = all.filter((m) => !text.includes(m.id));
		if (missing.length) console.warn(`  ${lang} journal is missing new modules: ${missing.map((m) => m.id).join(', ')}`);
	}
}

function writeSidebar(departments, outRoot) {
	const sidebar = [
		{ label: 'Overview', translations: { fr: T.fr.overview, es: T.es.overview }, slug: 'streeling' },
		{ label: 'Journal', translations: { es: T.es.journal }, slug: 'streeling/journal' },
		...departments.map((d) => ({
			label: d.label.en,
			translations: Object.fromEntries(TRANSLATIONS.map((lang) => [lang, d.label[lang]])),
			collapsed: true,
			items: [{ autogenerate: { directory: `streeling/${d.id}` } }],
		})),
	];
	write(path.join(outRoot, 'src/streeling-sidebar.json'), JSON.stringify(sidebar, null, 2) + '\n');
}

main();
