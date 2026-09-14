module greet

// hello is public: other modules can call it as `greet.hello`
pub fn hello(name string) string {
	return 'Hello, ${capitalize(name)}!'
}

// capitalize is private to the module, like `internal` in C# or package-private in Java
fn capitalize(s string) string {
	return s.capitalize()
}
