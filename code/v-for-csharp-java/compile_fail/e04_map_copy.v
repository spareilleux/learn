fn main() {
	mut status := {
		'ladybugdb': 'lesson 8'
	}
	next := status
	status['ladybugdb'] = 'done'
	println(next)
}
