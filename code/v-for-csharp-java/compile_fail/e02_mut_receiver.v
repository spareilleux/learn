struct Progress {
mut:
	done int
}

fn (mut p Progress) complete() {
	p.done++
}

fn main() {
	p := Progress{}
	p.complete()
	println(p.done)
}
