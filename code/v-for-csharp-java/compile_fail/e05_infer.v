fn parse[T](field string) T {
	return field.int()
}

fn main() {
	println(parse('111'))
}
