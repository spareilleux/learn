// The reader's bookmarks and notes, kept in this browser's localStorage and nowhere else.
// A page bookmark and a page note are keyed by the page's path without its locale, so they follow the reader from the
// English page to the French or Spanish one. A section bookmark keeps its locale: heading ids differ between languages.

export type Bookmark = {
	/** Page key, or the locale, the page key, '#' and the heading id for a section */
	key: string;
	/** Path the bookmark was added on, base included */
	path: string;
	/** Heading id, '' for the whole page */
	hash: string;
	/** Heading text for a section, '' for the whole page */
	section: string;
	page: string;
	course: string;
	added: string;
};

export type Note = { text: string; path: string; page: string; course: string; updated: string };

export type ReaderData = { version: 1; bookmarks: Record<string, Bookmark>; notes: Record<string, Note> };

const STORAGE_KEY = 'learn-reader';
const CHANGE_EVENT = 'learn-reader-change';
const LOCALES = ['fr', 'es'];
const BASE = import.meta.env.BASE_URL.replace(/\/$/, '');

const empty = (): ReaderData => ({ version: 1, bookmarks: {}, notes: {} });

/** Null when the browser refuses localStorage (private window, blocked site data) */
export function load(): ReaderData | null {
	try {
		const raw = localStorage.getItem(STORAGE_KEY);
		return raw ? (sanitize(JSON.parse(raw)) ?? empty()) : empty();
	} catch {
		return null;
	}
}

export function save(data: ReaderData): boolean {
	try {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
	} catch {
		return false;
	}
	window.dispatchEvent(new CustomEvent(CHANGE_EVENT));
	return true;
}

/** Calls back when this tab or another one changes the data */
export function onChange(callback: () => void) {
	window.addEventListener(CHANGE_EVENT, callback);
	window.addEventListener('storage', (event) => {
		if (event.key === STORAGE_KEY || event.key === null) callback();
	});
}

/** '/learn/fr/ga-lab/journal/' → { locale: 'fr', key: '/ga-lab/journal/' } */
export function splitPath(pathname: string): { locale: string; key: string } {
	let rest = pathname.startsWith(BASE) ? pathname.slice(BASE.length) : pathname;
	if (!rest.endsWith('/')) rest += '/';
	const first = rest.split('/')[1];
	return LOCALES.includes(first) ? { locale: first, key: rest.slice(first.length + 1) } : { locale: '', key: rest };
}

/** The page of a key in the reader's current language */
export function localHref(key: string, locale: string): string {
	return `${BASE}${locale ? `/${locale}` : ''}${key}`;
}

export function sectionKey(pathname: string, hash: string): string {
	const { locale, key } = splitPath(pathname);
	return `${locale}:${key}#${hash}`;
}

const isText = (value: unknown): value is string => typeof value === 'string' && value.length <= 100_000;

/** Keeps only well-formed entries, so an edited or foreign file can't break the pages */
export function sanitize(input: unknown): ReaderData | null {
	if (!input || typeof input !== 'object') return null;
	const { bookmarks, notes } = input as Partial<ReaderData>;
	if ((bookmarks !== undefined && typeof bookmarks !== 'object') || (notes !== undefined && typeof notes !== 'object')) return null;
	const data = empty();
	for (const [key, b] of Object.entries(bookmarks ?? {})) {
		if (b && isText(b.path) && isText(b.hash) && isText(b.section) && isText(b.page) && isText(b.course) && isText(b.added))
			data.bookmarks[key] = { key, path: b.path, hash: b.hash, section: b.section, page: b.page, course: b.course, added: b.added };
	}
	for (const [key, n] of Object.entries(notes ?? {})) {
		if (n && isText(n.text) && isText(n.path) && isText(n.page) && isText(n.course) && isText(n.updated))
			data.notes[key] = { text: n.text, path: n.path, page: n.page, course: n.course, updated: n.updated };
	}
	return data;
}

/** Adds the imported bookmarks, and for a note on the same page keeps the more recent one */
export function merge(into: ReaderData, from: ReaderData): { bookmarks: number; notes: number } {
	let bookmarks = 0;
	let notes = 0;
	for (const [key, b] of Object.entries(from.bookmarks)) {
		if (!into.bookmarks[key]) {
			into.bookmarks[key] = b;
			bookmarks++;
		}
	}
	for (const [key, n] of Object.entries(from.notes)) {
		const mine = into.notes[key];
		if (!mine || (mine.text !== n.text && n.updated > mine.updated)) {
			into.notes[key] = n;
			notes++;
		}
	}
	return { bookmarks, notes };
}
