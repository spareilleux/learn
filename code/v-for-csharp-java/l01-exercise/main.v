module main

import os
import greet
import stats

fn main() {
	text := os.args[1..].join(' ')
	println(greet.hello('reader'))
	println('${stats.word_count(text)} words')
}
