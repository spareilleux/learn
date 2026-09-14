fn double(mut n int) {
	n *= 2
}

fn main() {
	mut x := 2
	double(mut x)
	println(x)
}
