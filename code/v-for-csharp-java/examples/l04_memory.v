// Lesson 4: how much memory a loop of short-lived arrays keeps, under each memory mode
// The resident size depends on the OS and the C compiler: check.sh prints it without comparing
import runtime

fn make_lines(n int) []string {
	mut lines := []string{cap: n}
	for i in 0 .. n {
		lines << 'line ${i} of this page'
	}
	return lines
}

fn main() {
	println('GC enabled: ${gc_is_enabled()}')
	mut total := 0
	for round in 1 .. 51 {
		lines := make_lines(100_000)
		total += lines.len
		if round % 25 == 0 {
			println('round ${round}: ${runtime.used_memory()! / 1024 / 1024} MB resident')
		}
	}
	println('${total} strings')
}
