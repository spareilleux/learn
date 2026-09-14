// Lesson 4, exercises 1 and 2
import encoding.csv
import os

fn main() {
	// Exercise 1: French lessons per course, sorted by course name
	mut reader := csv.new_reader(os.read_file('data/pages.csv')!)
	reader.read()!
	mut lessons := map[string]int{}
	for {
		row := reader.read() or { break }
		if row[1] == 'fr' && row[3].len > 0 && row[3][0].is_digit() {
			lessons[row[2]]++
		}
	}
	mut courses := lessons.keys()
	courses.sort()
	for course in courses {
		println('${course}: ${lessons[course]}')
	}

	// Exercise 2: the alias stops seeing the changes once the array grows
	mut a := [1, 2, 3]
	b := a
	a << 4
	a[0] = 9
	println('a ${a}, b ${b}')
}
