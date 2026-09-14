// The text of a page for the narration player: blocks read in order, cut into sentences, and each sentence into parts
// read by the page's voice or by an English voice (inline code and English terms), with the page range of each word.
import { englishRanges, sayCode, sayEnglish, type Segment } from './english';

const BLOCKS = 'h1, h2, h3, h4, h5, h6, p, li, dt, dd, blockquote, figcaption, summary';
// exercise solutions (<details>) are read too: the player opens them
export const SKIP = 'pre, .expressive-code, table, script, style, .sl-anchor-link, .speech-from-here, [role="tablist"], [hidden], .sr-only';
const NESTED = `${BLOCKS}, ${SKIP}, ul, ol`;
const MAX_SENTENCE = 180; // Chrome cuts utterances after ~15 s

// One block of the page: its normalised text, the text node and offset of each character, and which characters are code
export type Block = { el: HTMLElement; text: string; at: [Text, number][]; code: boolean[] };

// One part of a sentence, read by one voice; from/to is the whole sentence, for the highlight
export type Part = { block: Block; from: number; to: number; english: boolean; spoken: string; segments: Segment[] };

function readBlock(el: HTMLElement): Block {
	let text = '';
	const at: [Text, number][] = [];
	const code: boolean[] = [];
	const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, {
		acceptNode: (n) => (n.parentElement?.closest(NESTED) === el ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT),
	});
	for (let node = walker.nextNode() as Text | null; node; node = walker.nextNode() as Text | null) {
		const inCode = Boolean(node.parentElement?.closest('code, kbd, samp'));
		const data = node.data;
		for (let i = 0; i < data.length; i++) {
			if (/\s/.test(data[i])) {
				if (!text || text.endsWith(' ')) continue;
				text += ' ';
			} else text += data[i];
			at.push([node, i]);
			code.push(inCode);
		}
	}
	if (text.endsWith(' ')) {
		text = text.slice(0, -1);
		at.pop();
		code.pop();
	}
	return { el, text, at, code };
}

export function pageBlocks(): Block[] {
	const blocks: Block[] = [];
	const title = document.querySelector<HTMLElement>('main h1');
	if (title) blocks.push(readBlock(title));
	const content = document.querySelector('main .sl-markdown-content');
	if (!content) return blocks;
	for (const el of content.querySelectorAll<HTMLElement>(BLOCKS)) {
		if (el.closest(SKIP)) continue;
		const block = readBlock(el);
		if (block.text) blocks.push(block);
	}
	return blocks;
}

export function pageSections(): HTMLElement[] {
	const title = document.querySelector<HTMLElement>('main h1');
	const headings = [...document.querySelectorAll<HTMLElement>('main .sl-markdown-content :is(h2, h3)')].filter((h) => !h.closest(SKIP));
	return title ? [title, ...headings] : headings;
}

// Sentences, long ones cut at commas then spaces, short ones merged up to MAX_SENTENCE characters
export function sentences(text: string): [number, number][] {
	const pieces: [number, number][] = [];
	let start = 0;
	const ends = [...text.matchAll(/(?<=[.!?;:…])\s+/g)].map((m) => [m.index!, m.index! + m[0].length]);
	for (const [end, next] of [...ends, [text.length, text.length]]) {
		let from = start;
		while (end - from > MAX_SENTENCE) {
			const window = text.slice(from, from + MAX_SENTENCE);
			const cut = Math.max(window.lastIndexOf(', '), window.lastIndexOf(' '));
			const at = cut > 0 ? from + cut + 1 : from + MAX_SENTENCE;
			pieces.push([from, at]);
			from = at;
		}
		if (end > from) pieces.push([from, end]);
		start = next;
	}
	const merged: [number, number][] = [];
	for (const [from, to] of pieces) {
		const last = merged[merged.length - 1];
		if (last && to - last[0] <= MAX_SENTENCE) last[1] = to;
		else merged.push([from, to]);
	}
	return merged.map(([from, to]) => {
		while (to > from && text[to - 1] === ' ') to--;
		while (from < to && text[from] === ' ') from++;
		return [from, to];
	});
}

type Run = { from: number; to: number; kind: 'code' | 'english' | 'page' };

// A sentence as runs of code, English and page-language text; punctuation between two runs goes with the one before
function runs(block: Block, from: number, to: number, englishPage: boolean): Run[] {
	const out: Run[] = [];
	for (let i = from; i < to; ) {
		const isCode = block.code[i];
		let j = i;
		while (j < to && block.code[j] === isCode) j++;
		if (isCode) out.push({ from: i, to: j, kind: 'code' });
		else if (englishPage) out.push({ from: i, to: j, kind: 'english' });
		else {
			let k = i;
			for (const [s, e] of englishRanges(block.text, i, j)) {
				if (s > k) out.push({ from: k, to: s, kind: 'page' });
				out.push({ from: s, to: e, kind: 'english' });
				k = e;
			}
			if (k < j) out.push({ from: k, to: j, kind: 'page' });
		}
		i = j;
	}
	return out;
}

// switchVoice false: the page's voice reads everything (code and English terms still said the English way), with no pause between voices
export function parts(blocks: Block[], englishPage: boolean, switchVoice = true): Part[] {
	const out: Part[] = [];
	for (const block of blocks) {
		for (const [from, to] of sentences(block.text)) {
			const groups: { english: boolean; runs: Run[] }[] = [];
			for (const run of runs(block, from, to, englishPage)) {
				const english = englishPage || (switchVoice && run.kind !== 'page');
				const last = groups[groups.length - 1];
				const wordless = !/[\p{L}\p{N}]/u.test(block.text.slice(run.from, run.to));
				if (last && (last.english === english || (wordless && !english))) last.runs.push(run);
				else groups.push({ english, runs: [run] });
			}
			for (const group of groups) {
				const segments = group.runs.flatMap((run) => {
					const text = block.text.slice(run.from, run.to);
					if (run.kind === 'code') return sayCode(text, run.from);
					if (run.kind === 'english') return sayEnglish(text, run.from);
					return [{ text, from: run.from, to: run.to, respelled: false }];
				});
				let spoken = segments.map((s) => s.text).join('');
				const last = group === groups[groups.length - 1];
				if (last && to === block.text.length && !/[.!?:;…]\s*$/.test(spoken)) spoken += '.';
				if (/[\p{L}\p{N}]/u.test(spoken)) out.push({ block, from, to, english: group.english, spoken, segments });
			}
		}
	}
	return out;
}

// Page text offset of a character of the spoken text
export function pageOffset(part: Part, spokenIndex: number, end: boolean): number {
	let pos = 0;
	for (const seg of part.segments) {
		if (spokenIndex < pos + seg.text.length || (end && spokenIndex === pos + seg.text.length)) {
			if (seg.respelled) return end ? seg.to : seg.from;
			return seg.from + (spokenIndex - pos);
		}
		pos += seg.text.length;
	}
	return part.segments.length ? part.segments[part.segments.length - 1].to : part.to;
}

export function textRange(block: Block, from: number, to: number): Range | undefined {
	while (to > from && block.text[to - 1] === ' ') to--;
	while (from < to && block.text[from] === ' ') from++;
	if (to <= from || !block.at[from] || !block.at[to - 1]) return undefined;
	const r = document.createRange();
	r.setStart(...block.at[from]);
	r.setEnd(block.at[to - 1][0], block.at[to - 1][1] + 1);
	return r;
}
