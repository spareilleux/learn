// Lesson 4: arrays and slices
fn main() {
	// An array grows with <<, like List<T>.Add or ArrayList.add
	mut lines := [474, 341, 326]
	lines << 394
	lines << [120, 88]
	println('${lines} len=${lines.len}')

	// Array initialization with len, cap and init (`index` is the position)
	squares := []int{len: 5, init: index * index}
	println(squares)

	// filter, map, any and all take an expression with `it`, or a function
	long := lines.filter(it > 300)
	println(long)
	println(lines.map(it / 10))
	println(lines.filter(fn (n int) bool {
		return n < 100
	}))
	println('${lines.any(it > 400)} ${lines.all(it > 100)}')
	println('${326 in lines} ${lines.index(394)}')

	// sort sorts in place; sorted returns a copy; a and b name the elements
	mut sorted := lines.sorted()
	println(sorted)
	sorted.sort(a > b)
	println(sorted)
	titles := ['Mission', 'Journal', '1. Install']
	println(titles.sorted(a.len < b.len))

	// A slice of an immutable array shares its memory; negative indexes need #[]
	counts := [474, 341, 326, 394, 120, 88]
	first := counts[..2]
	println('${first} ${counts[4..]} ${counts#[-2..]}')

	// Arrays are not copied on assignment: an immutable alias sees the changes...
	mut original := [1, 2, 3]
	alias := original
	original[0] = 100
	println('original ${original}, alias ${alias}')
	// ...until the array grows past its capacity and moves to a new block
	println('cap ${original.cap}')
	original << 4
	original[1] = 200
	println('original ${original}, alias ${alias}')

	// clone() makes an independent copy, like new List<T>(list) or List.copyOf
	mut copy := original.clone()
	copy[0] = -1
	println('original ${original}, copy ${copy}')
}
