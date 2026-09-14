// Lesson 3, exercises 1 and 2
import strconv

// Exercise 1: the number before '. ' in a title, or none
fn lesson_number(title string) ?int {
	dot := title.index('. ')?
	return strconv.atoi(title[..dot]) or { return none }
}

// Exercise 2: say which field is wrong
fn total_lines(fields []string) !int {
	mut total := 0
	for i, f in fields {
		total += strconv.atoi(f) or { return error('field ${i + 1}: ${err.msg()}') }
	}
	return total
}

fn main() {
	for title in ['8. Persistence, transactions and concurrency', 'Mission', 'v2. Draft',
		'12. Cross-compilation'] {
		if n := lesson_number(title) {
			println('${n}: ${title}')
		} else {
			println('-: ${title}')
		}
	}
	println(total_lines(['474', '341']) or { -1 })
	total_lines(['474', 'x', '341']) or { println(err) }
}
