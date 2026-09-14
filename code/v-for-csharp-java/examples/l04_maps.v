// Lesson 4: maps, with the pages of this site
import encoding.csv
import os

struct CourseLines {
	course string
	lines  int
}

fn main() {
	mut reader := csv.new_reader(os.read_file('data/pages.csv')!)
	reader.read()! // the header: url,locale,course,title,lines
	mut pages_per_locale := map[string]int{}
	mut lines_per_course := map[string]int{}
	for {
		row := reader.read() or { break }
		// A missing key reads as the zero value, so ++ and += work on new keys
		pages_per_locale[row[1]]++
		if row[1] == 'en' {
			lines_per_course[row[2]] += row[4].int()
		}
	}
	// Maps keep the insertion order, like LinkedHashMap
	println(pages_per_locale)

	// A missing key: 0, not KeyNotFoundException or null
	println(pages_per_locale['de'])
	println('de' in pages_per_locale)
	// or { } and if unwrapping tell a missing key from a zero value
	println(pages_per_locale['de'] or { -1 })
	if n := pages_per_locale['fr'] {
		println('fr: ${n} pages')
	}

	// To sort the entries, copy them to an array: a sort expression only sees a and b
	mut totals := []CourseLines{}
	for course, lines in lines_per_course {
		totals << CourseLines{course, lines}
	}
	totals.sort(a.lines > b.lines)
	println('English lines per course:')
	for t in totals[..5] {
		println('  ${t.course:-22} ${t.lines:5}')
	}

	// A map literal, delete, and a copy with clone()
	mut status := {
		'duckdb':            'done'
		'ladybugdb':         'lesson 8'
		'v-for-csharp-java': 'lesson 4'
	}
	status.delete('duckdb')
	mut next := status.clone()
	next['v-for-csharp-java'] = 'lesson 5'
	println(status)
	println(next)
}
