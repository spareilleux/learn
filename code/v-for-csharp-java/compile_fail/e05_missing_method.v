interface Named {
	name string
	kind() string
}

struct Package {
	name    string
	version string
}

fn describe(n Named) string {
	return '${n.kind()} ${n.name}'
}

fn main() {
	println(describe(Package{'Aspire.Hosting.AppHost', '9.5.1'}))
}
