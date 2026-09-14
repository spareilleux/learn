const courses = ['duckdb', 'ladybugdb']

fn find_course(prefix string) ?string {
	for c in courses {
		if c.starts_with(prefix) {
			return c
		}
	}
	return none
}

fn main() {
	name := find_course('rust')
	println(name.to_upper())
}
