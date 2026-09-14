struct Release {
	parts []int
}

struct Prerelease {
	label string
}

struct Floating {
	pattern string
}

type Version = Floating | Prerelease | Release

fn describe(v Version) string {
	return match v {
		Release { 'release' }
		Prerelease { 'prerelease ${v.label}' }
	}
}

fn main() {
	println(describe(Floating{'0.*'}))
}
