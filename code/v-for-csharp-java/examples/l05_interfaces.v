// Lesson 5: interfaces, implemented without being declared, on the projects and packages of GuitarAlchemist/ga
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

// An interface lists methods, and fields too
interface Named {
	name string
	kind() string
}

fn (p Project) kind() string {
	return 'project'
}

fn (p Package) kind() string {
	return 'package'
}

fn describe(n Named) string {
	return '${n.kind()} ${n.name}'
}

// A method on the interface itself, not a default implementation
fn (n Named) label() string {
	return '[${n.kind()}] ${n.name}'
}

// A method in the mut: section needs a mutable interface value
interface Tally {
mut:
	add(key string)
	total() int
}

struct Counter {
mut:
	n int
}

fn (mut c Counter) add(_ string) {
	c.n++
}

fn (c Counter) total() int {
	return c.n
}

struct Distinct {
mut:
	seen map[string]bool
}

fn (mut d Distinct) add(key string) {
	d.seen[key] = true
}

fn (d Distinct) total() int {
	return d.seen.len
}

struct Language implements Named {
	name string
}

fn (l Language) kind() string {
	return 'language'
}

fn main() {
	rows := os.read_lines('data/ga/projects.csv')!
	f := rows[1].split(',')
	project := Project{f[0], f[1], f[2], f[3]}
	g := os.read_lines('data/ga/package_refs.csv')![1].split(',')
	package := Package{g[0], g[1], g[2]}

	items := [Named(project), package, Language{'F#'}]
	for item in items {
		println(describe(item))
		println('  ${item.label()}')
		if item is Project {
			println('  sdk: ${item.sdk}')
		}
	}

	// The same loop, two implementations
	lines := os.read_lines('data/ga/package_refs.csv')![1..]
	mut tallies := [Tally(Counter{}), Distinct{}]
	for mut t in tallies {
		for line in lines {
			t.add(line.split(',')[1])
		}
	}
	println('package references: ${tallies[0].total()}, distinct packages: ${tallies[1].total()}')

	// A struct value is copied into the interface, a reference is shared
	mut counter := Counter{}
	mut copied := Tally(counter)
	copied.add('Aspire.Hosting.AppHost')
	println('copied: counter.n = ${counter.n}, copied.total() = ${copied.total()}')
	mut shared_counter := &Counter{}
	mut through_ref := Tally(shared_counter)
	through_ref.add('Aspire.Hosting.AppHost')
	println('reference: shared_counter.n = ${shared_counter.n}')
}
