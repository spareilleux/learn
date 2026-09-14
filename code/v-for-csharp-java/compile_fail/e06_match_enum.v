enum Sdk {
	library
	web
	worker
}

fn default_port(sdk Sdk) int {
	return match sdk {
		.library { 0 }
		.web { 8080 }
	}
}

fn main() {
	println(default_port(.web))
}
