// The course catalogue the playable observatory (public/demos/observatory/) shelves in its
// library: each course of the sidebar, grouped by area as the sidebar groups it, with its title
// and description in every locale, its lesson count and its URL. The scene fetches this file at
// start-up, so a new course reaches the shelves without re-exporting the Godot build; the build
// also carries a copy (assets/courses.json in the prototype) for the desktop and offline cases.
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
// Starlight's own components read the validated user config from this module.
import config from 'virtual:starlight/user-config';

type Item = {
	label?: string;
	translations?: Record<string, string>;
	slug?: string;
	link?: string;
	autogenerate?: { directory: string };
	items?: Item[];
};

// Locale key in the docs collection ids ('' for the root locale) and the language code.
const LOCALES = Object.entries(config.locales ?? { root: { lang: 'en' } }).map(([key, value]) => ({
	prefix: key === 'root' ? '' : `${key}/`,
	lang: (value as { lang?: string }).lang?.split('-')[0] ?? key,
}));

function translate(item: Item): Record<string, string> {
	const out: Record<string, string> = {};
	for (const { lang } of LOCALES) out[lang] = item.translations?.[lang] ?? item.label ?? '';
	return out;
}

export const GET: APIRoute = async () => {
	const docs = await getCollection('docs');
	const byId = new Map(docs.map((entry) => [entry.id, entry]));
	const areas: object[] = [];

	// The directory of a course: a group that autogenerates its pages from one directory, or a group
	// that opens on an overview page whose sub-groups all live under it (Streeling University, whose
	// departments stay inside it). Anything else is an area or a sub-area.
	function courseDir(group: Item): { dir: string; auto: boolean } | null {
		const auto = group.items?.find((item) => item.autogenerate)?.autogenerate?.directory;
		if (auto) return { dir: auto, auto: true };
		const overview = group.items?.find((item) => item.slug)?.slug;
		const nested = (group.items ?? []).flatMap((item) => item.items ?? []).flatMap((item) => item.autogenerate?.directory ?? []);
		if (overview && nested.length > 0 && nested.every((dir) => dir.startsWith(`${overview}/`))) return { dir: overview, auto: false };
		return null;
	}

	function course(group: Item, { dir, auto }: { dir: string; auto: boolean }) {
		const description: Record<string, string> = {};
		const lessons: Record<string, number> = {};
		const url: Record<string, string> = {};
		for (const { prefix, lang } of LOCALES) {
			const index = byId.get(`${prefix}${dir}`) ?? byId.get(`${prefix}${dir}/index`);
			description[lang] = (index?.data.description as string | undefined) ?? '';
			lessons[lang] = docs.filter((entry) =>
				auto
					? new RegExp(`^${prefix}${dir}/[0-9]{2}-`).test(entry.id)
					: entry.id.startsWith(`${prefix}${dir}/`) && !/\/(index|journal)$/.test(entry.id),
			).length;
			url[lang] = `${prefix}${dir}/`;
		}
		// Streeling counts its imported pages, not numbered lessons.
		return { id: dir, title: translate(group), description, lessons, unit: auto ? 'lessons' : 'pages', url };
	}

	// The departments of a course that nests them (Streeling University), each one a course of its
	// own: shelved as a single course, the university was a single book in its bay. A department
	// with no module yet in English stays off the shelf rather than show "0 pages".
	function departments(group: Item) {
		return (group.items ?? []).flatMap((item) => {
			const dir = item.items?.find((sub) => sub.autogenerate)?.autogenerate?.directory;
			const found = dir ? course(item, { dir, auto: false }) : null;
			return found && found.lessons.en > 0 ? [found] : [];
		});
	}

	// Walk the sidebar: a course joins the area named by its ancestors, and a course at the top level
	// (Streeling University) is an area of its own, whose departments are its books. Plain pages
	// (Method, Artifacts, the observatory) and links are not courses.
	function walk(items: Item[], path: Item[]) {
		const courses: object[] = [];
		for (const item of items) {
			if (!item.items) continue;
			const found = courseDir(item);
			if (found && path.length === 0) {
				const nested = found.auto ? [] : departments(item);
				areas.push({ label: translate(item), courses: nested.length > 0 ? nested : [course(item, found)] });
			} else if (found) courses.push(course(item, found));
			else walk(item.items, [...path, item]);
		}
		if (courses.length === 0) return;
		const label: Record<string, string> = {};
		for (const { lang } of LOCALES) label[lang] = path.map((group) => translate(group)[lang]).join(' › ');
		areas.push({ label, courses });
	}
	walk((config.sidebar ?? []) as Item[], []);

	const catalogue = {
		site: new URL(import.meta.env.BASE_URL.replace(/\/?$/, '/'), import.meta.env.SITE).href,
		locales: LOCALES.map(({ lang }) => lang),
		areas,
	};
	return new Response(JSON.stringify(catalogue, null, '\t') + '\n', {
		headers: { 'Content-Type': 'application/json; charset=utf-8' },
	});
};
