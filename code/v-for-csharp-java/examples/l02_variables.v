// Lesson 2: variables, immutability and the primitive types
fn main() {
	// := declares and initializes; the type is inferred, like `var` in C# and Java
	course := 'V for C#/Java developers'
	lessons := 4
	// Variables are immutable unless declared with `mut`
	mut done := 0
	done = 2
	println('${course}: ${done}/${lessons} lessons')

	// `int` is always 32 bits, like `int` in C# and Java; `i64` is `long`
	big := i64(3_000_000_000)
	println('${typeof(lessons).name} ${typeof(big).name}')

	// A small type is promoted to a bigger one, never the other way round
	total := big + lessons
	println('${typeof(total).name} ${total}')

	// Integer arithmetic wraps around, as in C# (unchecked) and Java
	max := 2147483647
	println(max + 1)
	println(i8(127) + 1)

	// Integer division truncates toward zero, as in C# and Java
	println('${7 / 2} ${-7 / 2} ${-7 % 2}')

	// Strings are immutable UTF-8 byte sequences: `len` counts bytes, not characters
	word := 'journée'
	println('${word.len} bytes, ${word.runes().len} runes')
	// Indexing a string gives a byte (u8); a rune literal uses backquotes
	println('${word[0]} ${typeof(word[0]).name} ${`é`} ${typeof(`é`).name}')

	// `if` and `match` are expressions: there is no ternary operator
	status := if done == lessons { 'finished' } else { 'in progress' }
	println(status)
	label := match done {
		0 { 'not started' }
		1, 2, 3 { 'started' }
		else { 'done' }
	}

	println(label)
}
