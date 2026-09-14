struct Page {
	title string
}

struct History {
mut:
	last &Page = unsafe { nil }
}

fn (mut h History) visit(p &Page) {
	h.last = p
}

fn main() {
	mut history := History{}
	page := Page{'Mission'}
	history.visit(&page)
	println(history.last.title)
}
