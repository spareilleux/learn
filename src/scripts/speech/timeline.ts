// The pre-generated narration of a page, word by word: the words Whisper heard in the MP3 (scripts/audio-timings.py)
// matched to the words of the page, so the player can highlight what is being said and seek to a section or a sentence.
// The narration skips code, tables, solutions and the sources, and says some words differently ("Cargo point lock"):
// each block is anchored on its first words, then its words are matched in order, with small gaps.
import { sentences, type Block } from './text';

// A word of the page and the time it is said, in seconds; from/to is its sentence
export type TimedWord = { block: Block; from: number; to: number; sentenceFrom: number; sentenceTo: number; time: number };

type Token = { text: string; from: number; to: number };

const normalise = (s: string) => s.toLowerCase().normalize('NFD').replace(/\p{M}/gu, '');

function tokenize(text: string): Token[] {
	return [...text.matchAll(/[\p{L}\p{N}]+/gu)].map((m) => ({ text: normalise(m[0]), from: m.index!, to: m.index! + m[0].length }));
}

// "rustup" and "rust up", "créez" and "créer", "CargoCheck" and "cargo": equal, or the same first 4 letters or more,
// all but the last 2 letters of the shorter word
function same(a: string, b: string): boolean {
	if (a === b) return true;
	let n = 0;
	while (n < a.length && n < b.length && a[n] === b[n]) n++;
	return n >= 4 && n >= Math.min(a.length, b.length) - 2;
}

const LOOK = 150; // how far a block may start after the end of the previous one, in heard words
const HEAD = 8; // words of a block used to anchor it
const GAP = 4; // heard words a page word may skip (words said differently)

// how many of the page words [i0, i1) are heard in order from heard word j
function score(page: Token[], i0: number, i1: number, heard: string[], j: number): number {
	let n = 0;
	for (let i = i0; i < i1 && j < heard.length; i++) {
		for (let k = j; k < Math.min(j + GAP + 1, heard.length); k++) {
			if (same(page[i].text, heard[k])) {
				n++;
				j = k + 1;
				break;
			}
		}
	}
	return n;
}

// the page words of a block matched in order from heard word j: pairs [page index, heard index];
// after three words not heard, a word and the next one are looked for further (words said at more length)
function match(page: Token[], heard: string[], j: number): [number, number][] {
	const pairs: [number, number][] = [];
	let misses = 0;
	for (let i = 0; i < page.length && j < heard.length; i++) {
		let at = -1;
		for (let k = j; k < Math.min(j + GAP + 1, heard.length); k++) {
			if (same(page[i].text, heard[k])) {
				at = k;
				break;
			}
		}
		if (at < 0 && ++misses >= 3 && i + 1 < page.length && page[i].text.length + page[i + 1].text.length >= 6) {
			for (let s = j; s < Math.min(j + 40, heard.length); s++) {
				if (same(page[i].text, heard[s]) && score(page, i + 1, i + 2, heard, s + 1)) {
					at = s;
					break;
				}
			}
		}
		if (at < 0) continue;
		pairs.push([i, at]);
		j = at + 1;
		misses = 0;
	}
	return pairs;
}

export function timeline(blocks: Block[], words: [number, string][]): TimedWord[] {
	// one heard token per letter or digit run: "l'objet," -> "l", "objet"
	const heard: string[] = [];
	const times: number[] = [];
	for (const [cs, word] of words) {
		for (const t of tokenize(word)) {
			heard.push(t.text);
			times.push(cs / 100);
		}
	}
	const out: TimedWord[] = [];
	let cursor = 0;
	for (const block of blocks) {
		const page = tokenize(block.text);
		if (!page.length) continue;
		const head = Math.min(HEAD, page.length);
		const need = page.length === 1 ? 1 : Math.max(2, Math.ceil(head / 2));
		const look = page.length === 1 ? 40 : LOOK;
		let start = -1;
		for (let s = cursor; s < Math.min(cursor + look, heard.length); s++) {
			if (!same(page[0].text, heard[s]) && !(page.length > 1 && same(page[1].text, heard[s]))) continue;
			if (score(page, 0, head, heard, s) >= need) {
				start = s;
				break;
			}
		}
		if (start < 0) continue; // not narrated
		const ranges = sentences(block.text);
		const sentence = (at: number): [number, number] => ranges.find((r) => at < r[1]) ?? ranges[ranges.length - 1];
		const pairs = match(page, heard, start);
		for (const [pi, hi] of pairs) {
			const [sentenceFrom, sentenceTo] = sentence(page[pi].from);
			out.push({ block, from: page[pi].from, to: page[pi].to, sentenceFrom, sentenceTo, time: times[hi] });
		}
		if (pairs.length) cursor = pairs[pairs.length - 1][1] + 1;
	}
	return out;
}
