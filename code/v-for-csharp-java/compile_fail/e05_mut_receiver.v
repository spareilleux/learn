interface Tally {
	add(key string)
}

struct Counter {
mut:
	n int
}

fn (mut c Counter) add(_ string) {
	c.n++
}

fn main() {
	t := Tally(Counter{})
	t.add('Aspire.Hosting.AppHost')
}
