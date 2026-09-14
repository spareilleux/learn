// Lesson 7, exercise 1: package references per project, counted by a pool of workers into a shared map
import os
import runtime

struct Counts {
mut:
	by_project map[string]int
}

fn worker(jobs chan string, shared counts Counts) {
	for {
		line := <-jobs or { break }
		project := line.all_before(',')
		lock counts {
			counts.by_project[project]++
		}
	}
}

fn main() {
	lines := os.read_lines('data/ga/package_refs.csv')![1..]
	jobs := chan string{cap: 16}
	shared counts := Counts{}
	mut workers := []thread{}
	for _ in 0 .. runtime.nr_cpus() {
		workers << spawn worker(jobs, shared counts)
	}
	for line in lines {
		jobs <- line
	}
	jobs.close()
	workers.wait()

	// A copy of the map, so that the sort needs no lock
	by_project := rlock counts {
		counts.by_project.clone()
	}
	mut sorted := by_project.keys()
	sorted.sort_with_compare(fn [by_project] (a &string, b &string) int {
		if by_project[*a] != by_project[*b] {
			return by_project[*b] - by_project[*a]
		}
		return compare_strings(*a, *b)
	})
	println('${sorted.len} projects with packages, ${lines.len} references')
	for p in sorted[..3] {
		println('${by_project[p]} ${p.all_after_last('/')}')
	}
}
