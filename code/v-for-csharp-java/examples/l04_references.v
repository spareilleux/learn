// Lesson 4: structs on the stack, references and the heap
struct Page {
	title string
}

// V moves `p` to the heap because its address leaves the function
fn newest() &Page {
	p := Page{'Journal'}
	return &p
}

// @[heap]: every Visit is allocated on the heap, so a reference to it can be kept
@[heap]
struct Visit {
	page string
}

struct History {
mut:
	last &Visit = unsafe { nil }
}

fn (mut h History) visit(v &Visit) {
	h.last = v
}

fn main() {
	println(newest().title)

	mut history := History{}
	visit := Visit{'Mission'}
	history.visit(&visit)
	println(history.last.page)

	// & on a literal allocates on the heap and gives a reference, like `new` in C# and Java
	lesson := &Page{'4. Arrays, maps, slices and memory'}
	println(typeof(lesson).name)
	println(lesson.title)
}
