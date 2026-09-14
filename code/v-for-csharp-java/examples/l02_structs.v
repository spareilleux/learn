// Lesson 2: structs, methods and value semantics, with pages of this site
struct Page {
	url    string
	locale string = 'en'
	title  string
	lines  int
}

// A method: the receiver comes before the name, there is no `this`
fn (p Page) is_lesson() bool {
	return p.title.len > 0 && p.title[0].is_digit()
}

// `str` is V's `ToString()`/`toString()`: println and interpolation use it
fn (p Page) str() string {
	return '${p.title} (${p.locale}, ${p.lines} lines)'
}

// A static method: V has no constructors, only functions that return a struct
fn Page.translation(p Page, locale string, title string) Page {
	// Struct update syntax, like `with` on a C# record
	return Page{
		...p
		url:    '/${locale}${p.url}'
		locale: locale
		title:  title
	}
}

// Trailing struct arguments with @[params] stand in for named and optional arguments
@[params]
struct ListOptions {
	only_lessons bool
	max          int = 10
}

fn list(pages []Page, opts ListOptions) {
	mut shown := 0
	for p in pages {
		if shown == opts.max {
			break
		}
		if opts.only_lessons && !p.is_lesson() {
			continue
		}
		println('  ${p}')
		shown++
	}
}

// A struct with a mutable field and a method that changes it
struct Progress {
mut:
	done int
pub:
	total int
}

fn (mut p Progress) complete() {
	p.done++
}

fn main() {
	mission := Page{
		url:   '/v-for-csharp-java/'
		title: 'Mission'
		lines: 80
	}
	lesson :=
		Page{'/v-for-csharp-java/02-types-structs-methods/', 'en', '2. Types, structs and methods', 300}
	println(mission)
	println(lesson.is_lesson())

	french := Page.translation(lesson, 'fr', '2. Types, structs et méthodes')
	println(french.url)

	pages := [mission, lesson, french]
	println('all, at most 2:')
	list(pages, max: 2)
	println('lessons:')
	list(pages, only_lessons: true)

	// Structs are values: assignment copies, and == compares the fields
	copy := lesson
	println(copy == lesson)
	mut p1 := Progress{
		total: 4
	}
	mut p2 := p1
	p2.complete()
	p1.complete()
	p1.complete()
	println('p1 ${p1.done}/${p1.total}, p2 ${p2.done}/${p2.total}')

	// A struct without a custom str() prints all its fields
	println(p1)
}
