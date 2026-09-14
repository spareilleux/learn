struct Page {
	url   string @[required]
	title string
}

fn main() {
	p := Page{
		title: 'Mission'
	}
	println(p)
}
