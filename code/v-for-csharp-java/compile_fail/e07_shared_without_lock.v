struct Usage {
mut:
	by_package map[string]int
}

fn count(shared usage Usage, package string) {
	usage.by_package[package]++
}

fn main() {
	shared usage := Usage{}
	spawn count(shared usage, 'Spectre.Console').wait()
}
