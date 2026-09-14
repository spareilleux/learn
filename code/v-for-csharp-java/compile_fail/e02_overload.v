fn describe(lines int) string {
	return '${lines} lines'
}

fn describe(title string) string {
	return 'title: ${title}'
}

fn main() {
	println(describe('Mission'))
}
