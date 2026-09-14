// Lesson 7: spawn and wait, on the project references of GuitarAlchemist/ga
// Lines starting with "# " depend on the machine or on timing: check.sh prints them without comparing them.
import os
import runtime
import time

struct Graph {
	refs map[string][]string
}

fn load_graph() !Graph {
	mut refs := map[string][]string{}
	for line in os.read_lines('data/ga/project_refs.csv')![1..] {
		f := line.split(',')
		refs[f[0]] << f[1]
	}
	return Graph{refs}
}

// The projects a project references, directly or not
fn (g Graph) reachable(from string) int {
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
	return seen.len
}

fn short(path string) string {
	return path.all_after_last('/').all_before_last('.')
}

fn main() {
	g := load_graph()!
	projects := os.read_lines('data/ga/projects.csv')![1..].map(it.split(',')[0])
	println('${projects.len} projects, ${g.refs.len} with references')
	println('# ${runtime.nr_cpus()} logical CPUs')

	// One thread, one result
	h := spawn g.reachable('Apps/GaCli/GaCli.fsproj')
	println('GaCli: ${h.wait()} projects')

	// One thread per project: wait() returns the results in the order of the threads
	mut sw := time.new_stopwatch()
	mut threads := []thread int{}
	for p in projects {
		threads << spawn g.reachable(p)
	}
	counts := threads.wait()
	parallel := sw.elapsed()
	mut best := 0
	for i, c in counts {
		if c > counts[best] {
			best = i
		}
	}
	println('${counts.len} results, the most: ${short(projects[best])} with ${counts[best]}')

	sw.restart()
	mut sequential := []int{}
	for p in projects {
		sequential << g.reachable(p)
	}
	println('# ${projects.len} threads: ${parallel.microseconds()} us, one thread: ${sw.elapsed().microseconds()} us')
	println('same results: ${counts == sequential}')

	// A function that returns a result: wait() returns ![]int
	mut checks := []thread !int{}
	for p in ['GaCli/GaCli.fsproj', 'Apps/GaCli/GaCli.fsproj'] {
		checks << spawn find(g, p)
	}
	found := checks.wait() or {
		println('wait: ${err.msg()}')
		[]int{}
	}
	println('found: ${found}')
}

fn find(g Graph, path string) !int {
	if path !in g.refs {
		return error('no references from ${path}')
	}
	return g.refs[path].len
}
