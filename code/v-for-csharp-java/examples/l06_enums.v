// Lesson 6: enums and match on the projects of GuitarAlchemist/ga
import os

enum Sdk {
	library
	web
}

// An enum can have methods
fn (s Sdk) msbuild_name() string {
	return match s {
		.library { 'Microsoft.NET.Sdk' }
		.web { 'Microsoft.NET.Sdk.Web' }
	}
}

fn parse_sdk(name string) !Sdk {
	return match name {
		'Microsoft.NET.Sdk' { .library }
		'Microsoft.NET.Sdk.Web' { .web }
		else { error('unknown SDK: ${name}') }
	}
}

// A flag enum: a set of values in one integer
@[flag]
enum Traits {
	web
	fsharp
	in_solution
}

fn traits(fields []string) Traits {
	mut t := Traits.zero()
	if fields[3] == 'Microsoft.NET.Sdk.Web' {
		t.set(.web)
	}
	if fields[2] == 'F#' {
		t.set(.fsharp)
	}
	if fields[5] == 'true' {
		t.set(.in_solution)
	}
	return t
}

fn size(references int) string {
	return match references {
		0 { 'none' }
		1...3 { 'few' }
		4, 5, 6 { 'some' }
		else { 'many' }
	}
}

fn main() {
	sdk := parse_sdk('Microsoft.NET.Sdk.Web')!
	println('${sdk} ${int(sdk)} ${sdk.msbuild_name()}')
	println(Sdk.from('library')!)
	println(Sdk.from(1)!)
	parse_sdk('Microsoft.NET.Sdk.Razor') or { println(err.msg()) }

	mut by_sdk := map[Sdk]int{}
	mut web_outside := []string{}
	for line in os.read_lines('data/ga/projects.csv')![1..] {
		f := line.split(',')
		by_sdk[parse_sdk(f[3])!]++
		t := traits(f)
		if t.has(.web) && !t.has(.in_solution) {
			web_outside << f[1]
		}
	}
	println(by_sdk)
	println('web projects outside the solution: ${web_outside}')
	println(Traits.web | Traits.in_solution)

	for n in [0, 2, 5, 23] {
		println('${n}: ${size(n)}')
	}
}
