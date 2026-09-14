struct Release {
	parts []int
}

struct Floating {
	pattern string
}

type Version = Floating | Release

fn main() {
	v := Version(Floating{'0.*'})
	r := v as Release
	println(r.parts)
}
