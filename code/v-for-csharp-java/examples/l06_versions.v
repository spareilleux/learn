// Lesson 6: a sum type for the package versions of GuitarAlchemist/ga
import os
import strconv

struct Release {
	parts []int
}

struct Prerelease {
	release Release
	label   string
}

struct Floating {
	pattern string
}

type Version = Floating | Prerelease | Release

fn parse_release(s string) !Release {
	mut parts := []int{}
	for p in s.split('.') {
		parts << strconv.atoi(p)!
	}
	return Release{parts}
}

fn parse_version(s string) !Version {
	if s.contains('*') {
		return Floating{s}
	}
	if dash := s.index('-') {
		return Prerelease{parse_release(s[..dash])!, s[dash + 1..]}
	}
	return parse_release(s)!
}

fn (r Release) str() string {
	return r.parts.map(it.str()).join('.')
}

// match on a sum type: one branch per variant, and v has the variant's type inside
fn (v Version) describe() string {
	return match v {
		Release { 'release ${v}' }
		Prerelease { 'prerelease ${v.label} of ${v.release}' }
		Floating { 'floating ${v.pattern}' }
	}
}

fn (v Version) is_stable() bool {
	return v is Release
}

// A recursive sum type
struct Leaf {
	name string
}

struct Branch {
	name     string
	children []Tree
}

type Tree = Branch | Leaf

fn (t Tree) count() int {
	return match t {
		Leaf {
			1
		}
		Branch {
			mut n := 1
			for c in t.children {
				n += c.count()
			}
			n
		}
	}
}

fn short(path string) string {
	return path.all_after_last('/').all_before_last('.')
}

fn build(refs map[string][]string, path string, depth int) Tree {
	children := refs[path]
	if children.len == 0 || depth == 0 {
		return Leaf{short(path)}
	}
	return Branch{short(path), children.map(build(refs, it, depth - 1))}
}

fn (t Tree) print(indent string) {
	match t {
		Leaf {
			println('${indent}${t.name}')
		}
		Branch {
			println('${indent}${t.name} (${t.children.len})')
			for c in t.children {
				c.print(indent + '  ')
			}
		}
	}
}

fn main() {
	for s in ['9.5.1', '1.0.0-beta.24164.1', '8.*-*', '1.x'] {
		v := parse_version(s) or {
			println('${s}: ${err.msg()}')
			continue
		}
		println('${s}: ${v.describe()}, stable: ${v.is_stable()}, type: ${v.type_name()}')
	}

	mut kinds := map[string]int{}
	for line in os.read_lines('data/ga/package_refs.csv')![1..] {
		f := line.split(',')
		v := parse_version(f[2])!
		kinds[v.type_name()]++
		match v {
			Floating {
				println('${f[1]} ${v.pattern} in ${short(f[0])}')
			}
			Release {
				if v.parts.len != 3 {
					println('${f[1]} ${v} has ${v.parts.len} parts, in ${short(f[0])}')
				}
			}
			else {}
		}
	}
	println(kinds)

	// as: a cast that panics on the wrong variant
	w := Version(Prerelease{Release{[2, 2, 0]}, 'beta.1'})
	p := w as Prerelease
	println(p.label)

	mut refs := map[string][]string{}
	for line in os.read_lines('data/ga/project_refs.csv')![1..] {
		f := line.split(',')
		refs[f[0]] << f[1]
	}
	tree := build(refs, 'Apps/GaCli/GaCli.fsproj', 10)
	tree.print('')
	println('${tree.count()} nodes')
}
