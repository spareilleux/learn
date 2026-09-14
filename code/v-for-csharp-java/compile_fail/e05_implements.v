interface Named {
	name string
	kind() string
}

struct Package implements Named {
	name    string
	version string
}

fn main() {
	println(Package{'Aspire.Hosting.AppHost', '9.5.1'})
}
