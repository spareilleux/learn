struct Release {
	parts []int
}

struct Floating {
	pattern string
}

type Version = Floating | Release

fn main() {
	v := Version(Floating{'0.*'})
	println(v.parts)
}
