struct Usage {
	package  string
	projects int
}

fn largest[T](items []T) T {
	mut best := items[0]
	for x in items[1..] {
		if x > best {
			best = x
		}
	}
	return best
}

fn main() {
	println(largest([20, 12, 9]))
	println(largest([Usage{'Spectre.Console', 20}, Usage{'xunit', 12}]))
}
