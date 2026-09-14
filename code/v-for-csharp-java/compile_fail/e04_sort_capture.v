fn main() {
	lines := {
		'duckdb':         3177
		'github-actions': 2785
	}
	mut courses := lines.keys()
	courses.sort(lines[a] > lines[b])
	println(courses)
}
