---
title: "3. Errors: ?, ! and or { }"
description: No null and no exceptions — options, results, or blocks, panics and custom error types, tried on the CSV file of this site's pages.
sidebar:
  order: 3
---

Code: [`examples/l03_errors.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l03_errors.v) and [`examples/l03_pages.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l03_pages.v) — `v run examples/l03_pages.v` from `code/v-for-csharp-java`.

## Two things V doesn't have

V has no `null` and no exceptions. A function that may have no value returns an **option**, `?T`; a function that may fail returns a **result**, `!T`. Both are part of the return type, and the compiler refuses to let you use the value without deciding what happens in the other case.

| Situation | C# | Java | V |
|---|---|---|---|
| A value may be absent | `null`, [nullable types](https://learn.microsoft.com/dotnet/csharp/nullable-references) (warnings) | `null`, [`Optional<T>`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html) | `?T`, `return none` |
| An operation may fail | [exceptions](https://learn.microsoft.com/dotnet/csharp/fundamentals/exceptions/), all unchecked | [checked and unchecked exceptions](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html) | `!T`, `return error('…')` |
| Handle it | `??`, `try`/`catch` | `orElse`, `try`/`catch` | `or { }`, `if x := f() { }` |
| Pass it to the caller | nothing to write | `throws` in the signature | `!` or `?` after the call |
| A bug, the program stops | unhandled exception, [`Environment.FailFast`](https://learn.microsoft.com/dotnet/api/system.environment.failfast) | unhandled exception, [`Error`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Error.html) | `panic()` |

Source: [Option/Result types and error handling](https://docs.vlang.io/type-declarations.html#optionresult-types-and-error-handling).

## Options: `?T` and `none`

```v
const courses = ['duckdb', 'ladybugdb', 'rust-for-csharp-java', 'v-for-csharp-java']

fn find_course(prefix string) ?string {
	for c in courses {
		if c.starts_with(prefix) {
			return c
		}
	}
	return none
}
```

`return c` returns a `string`: V wraps it in the option. The caller can't use the result as a `string` directly:

```v
fn main() {
	name := find_course('rust')
	println(name.to_upper())
}
```

```text
e03_option_in_expression.v:14:10: error: Option type `string` cannot be called directly, you should unwrap it first
   12 | fn main() {
   13 |     name := find_course('rust')
   14 |     println(name.to_upper())
      |             ~~~~
   15 | }
e03_option_in_expression.v:14:2: error: `println` can not print void expressions
   12 | fn main() {
   13 |     name := find_course('rust')
   14 |     println(name.to_upper())
      |     ~~~~~~~~~~~~~~~~~~~~~~~~
   15 | }
```

C# with [nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references) would only warn (CS8602), and Java would compile and throw a `NullPointerException` at run time. Two ways to unwrap:

```v
// or { } gives a default value, like ?? in C# or orElse in Java
println(find_course('lady') or { 'no course' })
println(find_course('zig') or { 'no course' })

// if unwrapping: the variable only exists when there is a value
if c := find_course('rust') {
	println('found ${c}')
}

// In an or block, `err` is the error; for an option it is `none`
find_course('java') or { println('java: ${err}') }
```

```text
ladybugdb
no course
found rust-for-csharp-java
java: none
```

## Results: `!T` and `error()`

[`strconv.atoi`](https://modules.vlang.io/strconv.html#atoi) returns `!int`: an `int`, or an error where `int.Parse` would throw a `FormatException` and `Integer.parseInt` a `NumberFormatException`. A result must be handled at every call:

```v
import strconv

fn main() {
	lines := strconv.atoi('474')
	println(lines)
}
```

```text
e03_unhandled_result.v:4:19: error: strconv.atoi() returns `!int`, so it should have either an `or {}` block, or `!` at the end
    2 | 
    3 | fn main() {
    4 |     lines := strconv.atoi('474')
      |                      ~~~~~~~~~~~
    5 |     println(lines)
    6 | }
```

Even a function that returns nothing but can fail, `!` alone, can't be called and forgotten. [`os.write_file`](https://modules.vlang.io/os.html#write_file) is one:

```v
import os

fn main() {
	os.write_file('journal.md', '## 2026-09-14')
	println('saved')
}
```

```text
e03_unhandled_void.v:4:5: error: os.write_file() returns `!void`, so it should have either an `or {}` block, or `!` at the end
    2 | 
    3 | fn main() {
    4 |     os.write_file('journal.md', '## 2026-09-14')
      |        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    5 |     println('saved')
    6 | }
```

This is stricter than Java's checked exceptions, which only apply to the exceptions a method declares: in V, every call that may fail says so.

### Four ways to handle a result

```v
// 1. ! passes the error to the caller, which must itself return a result
fn parse_lines(field string) !int {
	n := strconv.atoi(field)!
	if n < 0 {
		return error('negative line count: ${n}')
	}
	return n
}

fn total_lines(fields []string) !int {
	mut total := 0
	for f in fields {
		total += parse_lines(f)!
	}
	return total
}
```

```v
// 2. A default value
println(parse_lines('474') or { -1 })
// 3. Do something with `err`
parse_lines('12abc') or { println(err) }
parse_lines('-3') or { println(err) }
// 4. Leave the loop, or the function, from the or block
for fields in [['474', '341'], ['474', 'x', '341']] {
	total := total_lines(fields) or {
		println('${fields}: ${err}')
		continue
	}
	println('${fields}: ${total} lines')
}
```

```text
474
strconv.atoi: parsing "12abc": invalid radix 10 character
negative line count: -3
['474', '341']: 815 lines
['474', 'x', '341']: strconv.atoi: parsing "x": invalid radix 10 character
```

`if x := f() { } else { }` works for results too, with `err` in the `else` branch. [`error()`](https://modules.vlang.io/builtin.html#error) creates an error from a message; `error_with_code()` adds a number.

`!` after a call is the visible equivalent of letting an exception propagate. It needs a function that returns a result:

```v
import strconv

fn parse_lines(field string) int {
	return strconv.atoi(field)!
}
```

```text
e03_propagate_without_result.v:4:28: error: to propagate the Result call, `parse_lines` must return a Result
    2 | 
    3 | fn parse_lines(field string) int {
    4 |     return strconv.atoi(field)!
      |                               ^
    5 | }
    6 | 
Details: e03_propagate_without_result.v:3:30: details: prepend ! before the declaration of the return type of `parse_lines`
    1 | import strconv
    2 | 
    3 | fn parse_lines(field string) int {
      |                              ~~~
    4 |     return strconv.atoi(field)!
    5 | }
```

For an option, the same operator is `?`: `dot := title.index('. ')?` returns `none` from the current function when there is no match.

:::caution[The shortcuts that don't fail]
The string methods [`int()`](https://modules.vlang.io/builtin.html#string.int), `i64()` or `f64()` return a plain number, without an option or a result, and never report an error:

```v
println('${'12abc'.int()} ${'abc'.int()} ${'99999999999'.int()}')
```

```text
12 0 2147483647
```

`'12abc'` gives 12, `'abc'` gives 0, and a number too large gives the maximum `int`. Where C# and Java would throw, V returns a value. Use `strconv.atoi` when the input can be wrong.
:::

## Panics

A panic stops the program: it prints `V panic:` and a message, then a backtrace, and exits with code 1. There is no `catch`.

An array index out of range panics, like an `IndexOutOfRangeException` that nothing catches:

```v
fn main() {
	courses := ['duckdb', 'ladybugdb']
	i := 2
	println(courses[i])
}
```

```text
V panic: array.get: index out of range (i,a.len):2, 2
```

`or { }` after an index turns the panic into a value: `courses[10] or { 'index out of range' }`.

`!` in `main`, which can't pass the error further, panics:

```v
import strconv

fn main() {
	lines := strconv.atoi('forty-two')!
	println(lines)
}
```

```text
V panic: result not set (strconv.atoi: parsing "forty-two": invalid radix 10 character)
```

`or { panic(err) }` does the same with the error's own message:

```v
import os

fn main() {
	text := os.read_file('missing.csv') or { panic(err) }
	println(text)
}
```

```text
V panic: failed to open file "missing.csv"; code: 2
```

The first line is the same on the three OSes. On Windows, the lines that follow give the commit of V, the process and thread IDs, and a backtrace in the generated C file, such as `C://Users//spare//AppData//Local//Temp//v_0//P03_OR~1.C:4689: at builtin___v_panic: Backtrace`; its content depends on the OS and the C compiler, and the course's CI only compares the first line.

## Custom error types

An error is any type that implements the [`IError`](https://modules.vlang.io/builtin.html#IError) interface, with `msg() string` and `code() int`. Embedding the built-in `Error` struct provides both, and you override what you need:

```v
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
```

`data/pages.csv` has one line per page of this site. A first parser splits each line on commas, and returns a `ParseError` when a line doesn't have five fields:

```v
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
```

`return ParseError{…}` in a function that returns `!Page` is an error, not a page: V converts the struct to `IError`. The caller collects the errors, then tests their type with `is`, the equivalent of `catch (ParseError e)`:

```v
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
	if e is ParseError {
		println('  code ${e.code()}: ${e.msg()}')
	}
}
```

```text
naive split: 269 pages, 50 errors
  code 10: line 10: expected 5 fields, got 6
  code 21: line 21: expected 5 fields, got 6
  code 26: line 26: expected 5 fields, got 6
```

Inside `if e is ParseError`, `e` is a `ParseError` with its `line_no` field: V casts it automatically, like a [pattern](https://learn.microsoft.com/dotnet/csharp/fundamentals/functional/pattern-matching) `if (e is ParseError pe)` in C#. Line 10 of the file shows why the naive parser fails:

```text
/duckdb/08-persistence/,en,duckdb,"8. Persistence, transactions and concurrency",394
```

The title is quoted because it contains commas. [`encoding.csv`](https://modules.vlang.io/encoding.csv.html) handles quotes; its reader returns `![]string` for each row, and an error at the end of the file:

```v
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
```

```text
encoding.csv: 319 pages
  8. Persistence, transactions and concurrency: 394 lines
```

One trap with a smart-cast error: `${err}` then prints the struct with all its fields, not `msg()`, so call `err.msg()` explicitly (see the [journal](../journal/)).

`csv.EndOfFileError` is declared without `pub` in [`reader.v`, lines 25-31](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/encoding/csv/reader.v#L25-L31), yet V 0.5.2 accepts it after `is` in another module. Reaching the end of the file is reported as an error, like Go's `io.EOF`, not as an option.

## Key takeaways

- `?T` is a value or `none`; `!T` is a value or an error. The compiler refuses a call whose option or result isn't handled, even for a function that returns nothing.
- `or { }` gives a default value, or leaves with `return`, `continue`, `break` or `panic`; `if x := f() { }` unwraps; `!` and `?` pass the error or the `none` to the caller.
- `string.int()` and its siblings never fail: they return 0 or saturate. Parse untrusted input with `strconv`.
- A panic stops the program with code 1, and can't be caught. An index out of range panics unless it has `or { }`.
- A custom error embeds `Error`, overrides `msg()` and `code()`, and is recognized with `is`.

## Exercises

1. Write `fn lesson_number(title string) ?int`, which returns the number before `'. '` in a title such as `'8. Persistence, transactions and concurrency'`, and `none` for `'Mission'` or `'v2. Draft'`. [`string.index`](https://modules.vlang.io/builtin.html#string.index) returns `?int`.

<details>
<summary>Solution</summary>

[`examples/s03_lesson_number.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s03_lesson_number.v#L4-L8):

```v
fn lesson_number(title string) ?int {
	dot := title.index('. ')?
	return strconv.atoi(title[..dot]) or { return none }
}
```

```text
8: 8. Persistence, transactions and concurrency
-: Mission
-: v2. Draft
12: 12. Cross-compilation
```

`?` passes on the `none` of `index`. `strconv.atoi` returns a result, not an option: `or { return none }` turns its error into `none`, and `'v2'` gives `none`.

</details>

2. Change `total_lines` so that its error says which field is wrong: `field 2: strconv.atoi: parsing "x": invalid radix 10 character`.

<details>
<summary>Solution</summary>

[`examples/s03_lesson_number.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s03_lesson_number.v#L10-L17):

```v
fn total_lines(fields []string) !int {
	mut total := 0
	for i, f in fields {
		total += strconv.atoi(f) or { return error('field ${i + 1}: ${err.msg()}') }
	}
	return total
}
```

```text
815
field 2: strconv.atoi: parsing "x": invalid radix 10 character
```

`return` in an `or` block leaves the function with a new error, which wraps the message of the original one: the equivalent of throwing a new exception with the original one as its inner exception, without the chain.

</details>

3. A colleague reads the `lines` column with `row[4].int()`, and a line says `n/a`. What happens in V, and what would happen with `int.Parse` in C# and `Integer.parseInt` in Java?

<details>
<summary>Solution</summary>

In V, `'n/a'.int()` returns 0: the page counts zero lines and nothing reports the problem. `int.Parse("n/a")` throws a `FormatException`, and `Integer.parseInt("n/a")` a `NumberFormatException`. `strconv.atoi(row[4])` restores an error that must be handled. [Lesson 4](../04-arrays-maps-memory/) still uses `row[4].int()` on `pages.csv`, a file whose `lines` column this lesson's parser has checked.

</details>

## Sources

- [V documentation — Option/Result types and error handling](https://docs.vlang.io/type-declarations.html#optionresult-types-and-error-handling), [Custom error types](https://docs.vlang.io/type-declarations.html#custom-error-types), [If unwrapping](https://docs.vlang.io/statements-&-expressions.html#if-unwrapping)
- [V standard library — `builtin` (`IError`, `error`, `panic`)](https://modules.vlang.io/builtin.html), [`strconv`](https://modules.vlang.io/strconv.html), [`encoding.csv`](https://modules.vlang.io/encoding.csv.html)
- [C# — Exceptions and exception handling](https://learn.microsoft.com/dotnet/csharp/fundamentals/exceptions/), [Nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references)
- [Java — Checked and unchecked exceptions](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html), [`Optional`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html)
