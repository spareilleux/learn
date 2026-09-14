// Lesson 1: script mode, no `fn main`; definitions come first, then the code
fn greeting(name string) string {
	return 'Hello, ${name}!'
}

println(greeting('C#'))
println(greeting('Java'))
