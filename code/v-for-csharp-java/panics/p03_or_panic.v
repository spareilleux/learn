import os

fn main() {
	text := os.read_file('missing.csv') or { panic(err) }
	println(text)
}
