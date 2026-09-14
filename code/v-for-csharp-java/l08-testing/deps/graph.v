module deps

// Graph holds the project references, from a project to the projects it references.
pub struct Graph {
mut:
	refs map[string][]string
}

// Graph.parse reads the lines of project_refs.csv, header included.
pub fn Graph.parse(lines []string) !Graph {
	if lines.len == 0 || lines[0] != 'from,to' {
		return error('expected the header from,to')
	}
	mut g := Graph{}
	for i, line in lines[1..] {
		f := line.split(',')
		if f.len != 2 {
			return error('line ${i + 2}: expected 2 fields, got ${f.len}')
		}
		g.refs[f[0]] << f[1]
	}
	return g
}

// reachable returns the projects that a project references, directly or not, sorted.
pub fn (g Graph) reachable(from string) []string {
	mut seen := map[string]bool{}
	mut stack := [from]
	for stack.len > 0 {
		p := stack.pop()
		for to in g.refs[p] {
			if to !in seen {
				seen[to] = true
				stack << to
			}
		}
	}
	mut result := seen.keys()
	result.sort()
	return result
}
