// V 0.5.2 accepts this program, then generates C code that doesn't compile:
// the `return` of the anonymous function unlocks `usage`, a variable of main
struct Usage {
mut:
	by_package map[string]int
}

fn main() {
	shared usage := Usage{}
	rlock usage {
		count := fn () int {
			return 1
		}
		println(count())
	}
}
