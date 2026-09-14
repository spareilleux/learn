struct Package {
	id      string
	version string
}

fn names[T](items []T) []string {
	return items.map(it.name)
}

fn main() {
	println(names([Package{'Aspire.Hosting.AppHost', '9.5.1'}]))
}
