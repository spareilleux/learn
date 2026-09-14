struct Usage {
mut:
	by_package map[string]int
}

fn main() {
	shared usage := Usage{}
	rlock usage {
		usage.by_package['Spectre.Console']++
	}
}
