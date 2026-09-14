// English for the narration player: which words of a French or Spanish page are English, how to say them,
// and how to read inline code aloud with the words a software engineer uses ("count star", "p dot url").

// A piece of spoken text and the range of page text it stands for
export type Segment = { text: string; from: number; to: number; respelled: boolean };

// Names and acronyms, matched with their case
const NAMES = [
	'GitHub Actions', 'GitHub', 'GitLab', 'DuckDB.NET', 'ADO.NET', 'ASP.NET', '.NET', 'C#', 'F#', 'C++', 'DuckDB', 'LadybugDB', 'Kuzu', 'Neo4j',
	'Cypher', 'Starlight', 'Astro', 'Docker Desktop', 'Docker', 'Podman', 'Kubernetes', 'Nginx', 'Windows', 'Linux', 'macOS', 'Ubuntu', 'WSL',
	'PowerShell', 'Bash', 'Git Bash', 'Git', 'JSON', 'YAML', 'CSV', 'SQL Server', 'SQL', 'PostgreSQL', 'SQLite', 'API', 'CLI', 'CI/CD', 'CI', 'IDE',
	'JVM', 'JDK', 'SDK', 'URL', 'HTTPS', 'HTTP', 'UTF-8', 'Maven', 'Gradle', 'NuGet', 'Cargo', 'Node.js', 'TypeScript', 'JavaScript', 'Python',
	'Java', 'Rust', 'rustc', 'Tokio', 'Dapper', 'JDBC', 'Visual Studio Code', 'Visual Studio', 'VS Code', 'Claude Code', 'Claude', 'Codex', 'Copilot',
	'Apple Silicon', 'Web Speech', 'OpenJDK', 'Spring Boot', 'Spring', 'Reactor', 'Streeling', 'Demerzel', 'Microsoft Edge', 'Chrome', 'Firefox', 'Safari',
];

// Software engineering words left in English in French and Spanish prose, any case, with their plural
const WORDS = [
	'pull request', 'borrow checker', 'reverse proxy', 'load balancer', 'commit', 'push', 'merge', 'rebase', 'checkout', 'fork', 'upstream',
	'workflow', 'runner', 'job', 'step', 'build', 'release', 'pipeline', 'artifact', 'token', 'thread', 'runtime', 'framework', 'backend',
	'frontend', 'snapshot', 'benchmark', 'crate', 'trait', 'ownership', 'lifetime', 'closure', 'async', 'await', 'sniffer', 'walk', 'trail',
	'binding', 'driver', 'plugin', 'shell', 'prompt', 'bug', 'debugger', 'endpoint', 'dashboard', 'container', 'cluster', 'pod', 'ingress',
	'middleware', 'callback', 'hook', 'query', 'hash', 'timeout', 'overhead', 'scope', 'matrix', 'issue', 'mock', 'stub', 'feature', 'flag',
	'tag', 'deploy', 'staging', 'rollback', 'cache hit', 'cache miss', 'lock', 'deadlock', 'boilerplate', 'getter', 'setter', 'record',
];

const escape = (s: string) => s.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&');
const byLength = (a: string, b: string) => b.length - a.length;
const EDGE_BEFORE = '(?<![\\p{L}\\p{N}_])';
const EDGE_AFTER = '(?![\\p{L}\\p{N}_#+])';
const NAMES_RX = new RegExp(`${EDGE_BEFORE}(?:${[...NAMES].sort(byLength).map(escape).join('|')})${EDGE_AFTER}`, 'gu');
const WORDS_RX = new RegExp(`${EDGE_BEFORE}(?:${[...WORDS].sort(byLength).map(escape).join('|')})(?:e?s)?${EDGE_AFTER}`, 'giu');

// Ranges of [from, to) that are English, inside text[from, to)
export function englishRanges(text: string, from: number, to: number): [number, number][] {
	const slice = text.slice(from, to);
	const found = [...slice.matchAll(NAMES_RX), ...slice.matchAll(WORDS_RX)]
		.map((m): [number, number] => [from + m.index!, from + m.index! + m[0].length])
		.sort((a, b) => a[0] - b[0] || b[1] - a[1]);
	const out: [number, number][] = [];
	for (const r of found) if (!out.length || r[0] >= out[out.length - 1][1]) out.push(r);
	return out;
}

// How an English voice should say names it would spell or misread
const SAY: [RegExp, string][] = [
	[/\bASP(?=\.NET\b)/g, 'A S P '],
	[/\bADO(?=\.NET\b)/g, 'A D O '],
	[/(?<=\S)\.NET\b/g, ' dot net'],
	[/\.NET\b/g, 'dot net'],
	[/\bC#(?![\w#])/g, 'C sharp'],
	[/\bF#(?![\w#])/g, 'F sharp'],
	[/\bC\+\+(?!\w)/g, 'C plus plus'],
	[/\bCI\/CD\b/g, 'C I C D'],
	[/\bUTF-8\b/g, 'U T F 8'],
	[/\bmacOS\b/g, 'mac O S'],
	[/\brustc\b/g, 'rust C'],
	[/\bnpm\b/g, 'N P M'],
];

export function sayEnglish(text: string, from: number): Segment[] {
	let segments: Segment[] = [{ text, from, to: from + text.length, respelled: false }];
	for (const [rx, say] of SAY) {
		segments = segments.flatMap((seg) => {
			if (seg.respelled) return [seg];
			const out: Segment[] = [];
			let last = 0;
			for (const m of seg.text.matchAll(rx)) {
				const start = m.index!;
				if (start > last) out.push({ text: seg.text.slice(last, start), from: seg.from + last, to: seg.from + start, respelled: false });
				out.push({ text: say, from: seg.from + start, to: seg.from + start + m[0].length, respelled: true });
				last = start + m[0].length;
			}
			if (last < seg.text.length) out.push({ text: seg.text.slice(last), from: seg.from + last, to: seg.to, respelled: false });
			return out;
		});
	}
	return segments;
}

// Operators and symbols in inline code, as said aloud
const OPERATORS: [string, string][] = [
	['->', 'arrow'], ['=>', 'arrow'], ['<-', 'arrow'], ['::', 'colon colon'], ['==', 'equals'], ['!=', 'not equal'], ['<>', 'not equal'],
	['<=', 'less than or equal'], ['>=', 'greater than or equal'], ['&&', 'and'], ['||', 'or'], ['..', 'dot dot'],
	['*', 'star'], ['/', 'slash'], ['\\', 'backslash'], ['#', 'hash'], ['$', 'dollar'], ['@', 'at'], ['%', 'percent'], ['&', 'and'],
	['|', 'pipe'], ['~', 'tilde'], ['^', 'caret'], ['=', 'equals'], ['+', 'plus'],
];
const SILENT = new Set([...'()[]{}<>;,\'"`!?_']);
const alnum = (c: string | undefined) => c !== undefined && /[\p{L}\p{N}]/u.test(c);

export function sayCode(text: string, from: number): Segment[] {
	const out: Segment[] = [];
	const push = (said: string, start: number, end: number, respelled: boolean) => {
		const last = out[out.length - 1];
		if (!respelled && last && !last.respelled && last.to === from + start) {
			last.text += said;
			last.to = from + end;
		} else out.push({ text: said, from: from + start, to: from + end, respelled });
	};
	let i = 0;
	while (i < text.length) {
		const c = text[i];
		const before = text[i - 1];
		const after = text[i + 1];
		// identifiers: CamelCase and snake_case read as words
		const word = /^[A-Za-z][A-Za-z0-9]*/.exec(text.slice(i))?.[0];
		if (word) {
			const split = word.replace(/(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])/g, ' ');
			push(split, i, i + word.length, split !== word);
			i += word.length;
			continue;
		}
		if (c === '-' && text[i + 1] === '-' && alnum(text[i + 2]) && !alnum(before)) {
			push(' dash dash ', i, i + 2, true);
			i += 2;
			continue;
		}
		const operator = OPERATORS.find(([op]) => text.startsWith(op, i));
		if (operator) {
			push(` ${operator[1]} `, i, i + operator[0].length, true);
			i += operator[0].length;
			continue;
		}
		if (c === '.') {
			// 0.20.4 stays a number, p.url is "p dot url"
			if (/\d/.test(before ?? '') && /\d/.test(after ?? '')) push(c, i, i + 1, false);
			else push(' dot ', i, i + 1, true);
			i++;
		} else if (c === '-') {
			if (alnum(before) && alnum(after)) push(' ', i, i + 1, true); // hyphenated-name
			else if (alnum(after) && (i === 0 || before === ' ')) push(' dash ', i, i + 1, true); // -b
			else if (before === ' ' && after === ' ') push(' minus ', i, i + 1, true); // a - b
			else push(' ', i, i + 1, true); // (a)-[:R]
			i++;
		} else if (c === ':') {
			push(i === 0 || before === ' ' ? ' colon ' : ' ', i, i + 1, true); // :schema, but e:LINKS_TO
			i++;
		} else if (SILENT.has(c)) {
			push(' ', i, i + 1, true);
			i++;
		} else {
			push(c, i, i + 1, false);
			i++;
		}
	}
	return out;
}
