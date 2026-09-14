// Lesson 2, exercises 1 and 2
struct Course {
	name    string
	lessons int
mut:
	done int
}

// Exercise 1: a mut method that stops at the number of lessons, and str()
fn (mut c Course) finish_lesson() {
	if c.done < c.lessons {
		c.done++
	}
}

fn (c Course) str() string {
	return '${c.name}: ${c.done}/${c.lessons}'
}

fn main() {
	mut v := Course{
		name:    'V'
		lessons: 2
	}
	for _ in 0 .. 3 {
		v.finish_lesson()
	}
	println(v)

	// Exercise 2: assignment copies the struct
	mut a := Course{
		name:    'Rust'
		lessons: 15
	}
	mut b := a
	b.finish_lesson()
	println('${a} | ${b}')
}
