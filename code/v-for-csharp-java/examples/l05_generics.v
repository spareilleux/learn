// Lesson 5: generic functions, structs and methods on the projects of GuitarAlchemist/ga
import os

struct Project {
	path     string
	name     string
	language string
	sdk      string
}

struct Package {
	project string
	name    string
	version string
}

fn load_projects() ![]Project {
	mut projects := []Project{}
	for line in os.read_lines('data/ga/projects.csv')![1..] {
		f := line.split(',')
		projects << Project{f[0], f[1], f[2], f[3]}
	}
	return projects
}

fn load_packages() ![]Package {
	mut packages := []Package{}
	for line in os.read_lines('data/ga/package_refs.csv')![1..] {
		f := line.split(',')
		packages << Package{f[0], f[1], f[2]}
	}
	return packages
}

// A generic function: T is inferred from the arguments
fn count_by[T](items []T, key fn (T) string) map[string]int {
	mut counts := map[string]int{}
	for item in items {
		counts[key(item)]++
	}
	return counts
}

// No constraint: T only needs a `name` field at each call
fn names[T](items []T) []string {
	return items.map(it.name)
}

// A generic struct, and its methods
struct Index[T] {
mut:
	by_key map[string]T
}

fn (mut ix Index[T]) add(key string, value T) {
	ix.by_key[key] = value
}

fn (ix Index[T]) get(key string) ?T {
	return ix.by_key[key] or { return none }
}

// `>` works for numbers and strings, and for a struct that defines `<`
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

struct Usage {
	package  string
	projects int
}

fn (a Usage) < (b Usage) bool {
	return a.projects < b.projects
}

interface Named {
	name string
}

// A compile-time check on T
fn label[T](x T) string {
	$if T is Named {
		return '${T.name} named ${x.name}'
	} $else {
		return 'a ${T.name}'
	}
}

fn main() {
	projects := load_projects()!
	packages := load_packages()!

	println(count_by(projects, fn (p Project) string {
		return p.language
	}))
	println(count_by[Project](projects, fn (p Project) string {
		return p.sdk
	}))
	println(names(projects[..2]))
	println(names(packages[..2]))

	mut ix := Index[Project]{}
	for p in projects {
		ix.add(p.name, p)
	}
	println(ix.get('GaApi') or { Project{} }.path)
	if p := ix.get('GaServer') {
		println(p.path)
	} else {
		println('GaServer: not found')
	}
	println(typeof(ix).name)

	by_package := count_by(packages, fn (p Package) string {
		return p.name
	})
	mut usages := []Usage{}
	for name, n in by_package {
		usages << Usage{name, n}
	}
	println(largest(usages) or { Usage{} })
	println(largest(by_package.values()) or { 0 })
	println(largest(by_package.keys()) or { '' })
	println(largest([]int{}) or { -1 })

	println(label(projects[0]))
	println(label(usages[0]))
	println(label(42))
}
