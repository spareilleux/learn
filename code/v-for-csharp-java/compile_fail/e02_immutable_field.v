struct Page {
	title string
	lines int
}

fn main() {
	mut p := Page{'Mission', 80}
	p.lines = 81
	println(p)
}
