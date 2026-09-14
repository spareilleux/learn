// Lesson 5, exercises 1 and 2: a generic group_by, and largest on a struct
import os

struct Project {
	path     string
	name     string
	language string
}

fn group_by[T](items []T, key fn (T) string) map[string][]T {
	mut groups := map[string][]T{}
	for item in items {
		groups[key(item)] << item
	}
	return groups
}

fn largest[T](items []T) ?T {
	if items.len == 0 {
		return none
	}
	mut best := items[0]
	for x in items[1..] {
		if x > best {
			best = x
		}
	}
	return best
}

// Exercise 2: with `<`, V generates `>` too
fn (a Project) < (b Project) bool {
	return a.name < b.name
}

fn main() {
	mut projects := []Project{}
	for line in os.read_lines('data/ga/projects.csv')![1..] {
		f := line.split(',')
		projects << Project{f[0], f[1], f[2]}
	}
	groups := group_by(projects, fn (p Project) string {
		return p.language
	})
	println(groups.keys())
	println(groups['F#'].map(it.name))
	println(largest(groups['F#']) or { Project{} }.name)
}
