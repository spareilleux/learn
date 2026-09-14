// Lesson 3: parse data/pages.csv, the pages of this site, with a custom error type
import encoding.csv
import os
import strconv

struct Page {
	url    string
	locale string
	course string
	title  string
	lines  int
}

// A custom error: embed Error, then override msg() and, if useful, code()
struct ParseError {
	Error
	line_no int
	reason  string
}

fn (e ParseError) msg() string {
	return 'line ${e.line_no}: ${e.reason}'
}

fn (e ParseError) code() int {
	return e.line_no
}

// A first, naive parser: split on commas
fn parse_page(line_no int, line string) !Page {
	fields := line.split(',')
	if fields.len != 5 {
		return ParseError{
			line_no: line_no
			reason:  'expected 5 fields, got ${fields.len}'
		}
	}
	lines := strconv.atoi(fields[4]) or {
		return ParseError{
			line_no: line_no
			reason:  err.msg()
		}
	}
	return Page{fields[0], fields[1], fields[2], fields[3], lines}
}

fn main() {
	// ! in main: if the file can't be read, the program stops with a panic
	lines := os.read_lines('data/pages.csv')!
	mut pages := []Page{}
	mut errors := []IError{}
	for i, line in lines[1..] {
		page := parse_page(i + 2, line) or {
			errors << err
			continue
		}
		pages << page
	}
	println('naive split: ${pages.len} pages, ${errors.len} errors')
	for e in errors[..3] {
		// `is` tests the concrete type of the error, like `catch (ParseError e)`
		if e is ParseError {
			println('  code ${e.code()}: ${e.msg()}')
		}
	}

	// The fix: encoding.csv understands quoted fields
	mut reader := csv.new_reader(os.read_file('data/pages.csv')!)
	reader.read()! // the header
	mut parsed := []Page{}
	for {
		row := reader.read() or {
			if err is csv.EndOfFileError {
				break
			}
			panic(err)
		}
		parsed << Page{row[0], row[1], row[2], row[3], strconv.atoi(row[4])!}
	}
	println('encoding.csv: ${parsed.len} pages')
	for p in parsed {
		if p.url == '/duckdb/08-persistence/' {
			println('  ${p.title}: ${p.lines} lines')
		}
	}
}
