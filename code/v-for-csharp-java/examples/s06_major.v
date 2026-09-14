// Lesson 6, exercise 1: the major version of each variant
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

fn (v Version) major() ?int {
	return match v {
		Release { v.parts[0] }
		Prerelease { v.release.parts[0] }
		Floating { strconv.atoi(v.pattern.all_before('.')) or { return none } }
	}
}

fn main() {
	versions := [
		Version(Release{[9, 5, 1]}),
		Prerelease{Release{[1, 0, 0]}, 'beta.24164.1'},
		Floating{'8.*-*'},
		Floating{'*'},
	]
	for v in versions {
		if m := v.major() {
			println('${v.type_name()}: ${m}')
		} else {
			println('${v.type_name()}: no major version')
		}
	}
}
