// Lesson 7: channels, a pool of workers on the project references of GuitarAlchemist/ga
// Lines starting with "# " depend on timing: check.sh prints them without comparing them.
import os
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

struct Result {
	worker  int
	project string
	count   int
}

// Receives until the channel is closed and empty
fn worker(id int, g Graph, jobs chan string, results chan Result) {
	for {
		project := <-jobs or { break }
		results <- Result{id, project, g.reachable(project)}
	}
}

fn main() {
	g := load_graph()!
	projects := os.read_lines('data/ga/projects.csv')![1..].map(it.split(',')[0])

	jobs := chan string{cap: projects.len}
	results := chan Result{cap: projects.len}
	mut workers := []thread{}
	for id in 0 .. 4 {
		workers << spawn worker(id, g, jobs, results)
	}
	for p in projects {
		jobs <- p
	}
	jobs.close()
	workers.wait()
	results.close()

	mut all := []Result{}
	mut per_worker := [0, 0, 0, 0]
	for {
		r := <-results or { break }
		all << r
		per_worker[r.worker]++
	}
	println('# results per worker: ${per_worker}')
	println('${all.len} results')
	println('# same order as the jobs: ${all.map(it.project) == projects}')
	all.sort_with_compare(fn (a &Result, b &Result) int {
		if a.count != b.count {
			return b.count - a.count
		}
		return compare_strings(a.project, b.project)
	})
	for r in all[..3] {
		println('${r.count} ${r.project.all_after_last('/')}')
	}

	// An unbuffered channel: the send waits for the receiver
	ch := chan string{}
	spawn fn (ch chan string) {
		time.sleep(20 * time.millisecond)
		ch <- 'GaApi'
	}(ch)
	println('unbuffered: ${<-ch}')

	// select: the first channel ready, or a timeout
	slow := chan int{}
	fast := chan int{}
	spawn fn (c chan int) {
		time.sleep(500 * time.millisecond)
		c <- 1
	}(slow)
	spawn fn (c chan int) {
		c <- 2
	}(fast)
	select {
		n := <-slow {
			println('# slow ${n}')
		}
		n := <-fast {
			println('select: fast ${n}')
		}
		2 * time.second {
			println('select: timeout')
		}
	}

	// A closed channel
	closed := chan string{cap: 2}
	closed <- 'GaApi'
	closed.close()
	closed <- 'GaCli'
	closed <- 'GaCli' or { println('send with or: ${err.msg()}') }
	println('buffered after close: ${<-closed}')
	empty := <-closed
	println('receive without or: "${empty}"')
	println('receive with or: ${<-closed or { 'closed' }}')
}
