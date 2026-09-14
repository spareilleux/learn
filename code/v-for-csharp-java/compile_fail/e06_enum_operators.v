enum Sdk {
	library
	web
}

fn main() {
	sdk := Sdk.library
	if sdk < Sdk.web {
		println('library')
	}
	println(sdk + 1)
}
