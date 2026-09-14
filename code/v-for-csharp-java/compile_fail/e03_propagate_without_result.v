import strconv

fn parse_lines(field string) int {
	return strconv.atoi(field)!
}

fn main() {
	println(parse_lines('474'))
}
