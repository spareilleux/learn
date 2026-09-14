// Lesson 3: Option (?T) and Result (!T) instead of null and exceptions
import strconv

const courses = ['duckdb', 'ladybugdb', 'rust-for-csharp-java', 'v-for-csharp-java']

// ?string: a string or `none`, like `string?` in C# or `Optional<String>` in Java
fn find_course(prefix string) ?string {
	for c in courses {
		if c.starts_with(prefix) {
			return c
		}
	}
	return none
}

// !int: an int or an error, where C# and Java would throw
fn parse_lines(field string) !int {
	n := strconv.atoi(field)!
	if n < 0 {
		return error('negative line count: ${n}')
	}
	return n
}

// ! propagates the error to the caller, like an exception that isn't caught
fn total_lines(fields []string) !int {
	mut total := 0
	for f in fields {
		total += parse_lines(f)!
	}
	return total
}

fn main() {
	// or { } gives a default value
	println(find_course('lady') or { 'no course' })
	println(find_course('zig') or { 'no course' })

	// if unwrapping: the variable only exists when there is a value
	if c := find_course('rust') {
		println('found ${c}')
	}

	// In an or block, `err` is the error; for an option it is `none`
	find_course('java') or { println('java: ${err}') }

	println(parse_lines('474') or { -1 })
	parse_lines('12abc') or { println(err) }
	parse_lines('-3') or { println(err) }

	// or blocks can also leave the function, or the loop
	for fields in [['474', '341'], ['474', 'x', '341']] {
		total := total_lines(fields) or {
			println('${fields}: ${err}')
			continue
		}
		println('${fields}: ${total} lines')
	}

	// The shortcuts that don't fail: the string methods return 0 or saturate
	println('${'12abc'.int()} ${'abc'.int()} ${'99999999999'.int()}')

	// An array index with or { } instead of a panic
	println(courses[10] or { 'index out of range' })
}
