---
title: 2. Types, immutable variables, structs and methods
description: Immutable variables by default, V's primitive types, and structs with methods instead of classes — compared with C# and Java, with the compiler's real errors.
sidebar:
  order: 2
---

Code: [`examples/l02_variables.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l02_variables.v) and [`examples/l02_structs.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l02_structs.v) — `v run examples/l02_structs.v` from `code/v-for-csharp-java`.

## Variables

```v
course := 'V for C#/Java developers'
lessons := 4
mut done := 0
done = 2
println('${course}: ${done}/${lessons} lessons')
```

```text
V for C#/Java developers: 2/4 lessons
```

| | C# | Java | V |
|---|---|---|---|
| Declare, type inferred | `var lessons = 4;` | `var lessons = 4;` | `lessons := 4` |
| Declare, type given | `long big = 3_000_000_000;` | `long big = 3_000_000_000L;` | `big := i64(3_000_000_000)` |
| Can't be reassigned | `const`, `readonly` field | `final var` | the default |
| Can be reassigned | the default | the default | `mut done := 0` |
| Assign | `done = 2;` | `done = 2;` | `done = 2` |

[`:=`](https://docs.vlang.io/variables.html) is the only way to declare a variable, so a variable always has a value. `=` only assigns, and only to a `mut` variable:

```v
fn main() {
	done := 0
	done = 2
	println(done)
}
```

```text
e02_immutable.v:3:2: error: `done` is immutable, declare it with `mut` to make it mutable
    1 | fn main() {
    2 |     done := 0
    3 |     done = 2
      |     ~~~~
    4 |     println(done)
    5 | }
```

A variable can't reuse the name of a variable of an enclosing block. C# ([CS0136](https://learn.microsoft.com/dotnet/csharp/misc/cs0136)) and Java reject this too:

```v
fn main() {
	total := 10
	if total > 5 {
		total := 20
		println(total)
	}
}
```

```text
e02_shadowing.v:4:3: error: redefinition of `total`
    2 |     total := 10
    3 |     if total > 5 {
    4 |         total := 20
      |         ~~~~~
    5 |         println(total)
    6 |     }
```

An unused variable is a warning, like C#'s [CS0219](https://learn.microsoft.com/dotnet/csharp/misc/cs0219), where `javac` says nothing:

```text
w02_unused.v:2:2: warning: unused variable: `count`
    1 | fn main() {
    2 |     count := 3
      |     ~~~~~
    3 |     println('done')
    4 | }
done
```

The same file with `v -prod` doesn't compile: the [warnings become errors](https://docs.vlang.io/variables.html#warnings-and-declaration-errors) in production builds.

```text
e02_unused_prod.v:3:2: error: unused variable: `count`
    1 | // flags: -prod
    2 | fn main() {
    3 |     count := 3
      |     ~~~~~
    4 |     println('done')
    5 | }
```

## Primitive types

| V | C# | Java | Notes |
|---|---|---|---|
| `bool` | `bool` | `boolean` | |
| `i8`, `i16`, `int`, `i64` | `sbyte`, `short`, `int`, `long` | `byte`, `short`, `int`, `long` | `int` is always 32 bits |
| `u8`, `u16`, `u32`, `u64` | `byte`, `ushort`, `uint`, `ulong` | — | Java has no unsigned types |
| `f32`, `f64` | `float`, `double` | `float`, `double` | |
| `isize`, `usize` | `nint`, `nuint` | — | the size of a pointer |
| `rune` | `int` holding a code point, [`Rune`](https://learn.microsoft.com/dotnet/api/system.text.rune) | `int` holding a code point | a Unicode code point; `char` in C# and Java is a UTF-16 unit |
| `string` | `string` (UTF-16) | `String` (UTF-16) | UTF-8, immutable |

Source: [V types](https://docs.vlang.io/v-types.html). An integer literal is an `int`, a float literal an `f64`, and a conversion is written like a call: `i64(3_000_000_000)`.

```v
big := i64(3_000_000_000)
println('${typeof(lessons).name} ${typeof(big).name}')
total := big + lessons
println('${typeof(total).name} ${total}')
```

```text
int i64
i64 3000000004
```

V promotes a smaller type to a larger one when no value can be lost: `int` to `i64` or `f64`, `u8` to `int`. It never mixes signed and unsigned, where C# would silently convert `uint + int` to `long`:

```v
fn main() {
	offset := -1
	size := u32(5)
	println(size + offset)
}
```

```text
e02_mixed_signs.v:4:10: error: mismatched types `u32` and `int`
    2 |     offset := -1
    3 |     size := u32(5)
    4 |     println(size + offset)
      |             ~~~~~~~~~~~~~
    5 | }
e02_mixed_signs.v:4:2: error: `println` can not print void expressions
    2 |     offset := -1
    3 |     size := u32(5)
    4 |     println(size + offset)
      |     ~~~~~~~~~~~~~~~~~~~~~~
    5 | }
```

The second error is a consequence of the first: once the addition has no type, `println` has nothing to print. Read the first error first.

Nor does V convert a number to a string. `"lessons: " + 4` is valid C# and Java; in V, use interpolation:

```v
fn main() {
	lessons := 4
	println('lessons: ' + lessons)
}
```

```text
e02_string_plus_int.v:3:10: error: infix expr: cannot use `int` (right expression) as `string`
    1 | fn main() {
    2 |     lessons := 4
    3 |     println('lessons: ' + lessons)
      |             ~~~~~~~~~~~~~~~~~~~~~
    4 | }
```

Arithmetic behaves like C# in an `unchecked` context and like Java: integers wrap around, and integer division truncates toward zero.

```v
max := 2147483647
println(max + 1)
println(i8(127) + 1)
println('${7 / 2} ${-7 / 2} ${-7 % 2}')
```

```text
-2147483648
-128
3 -3 -1
```

### Strings are UTF-8 bytes

```v
word := 'journée'
println('${word.len} bytes, ${word.runes().len} runes')
println('${word[0]} ${typeof(word[0]).name} ${`é`} ${typeof(`é`).name}')
```

```text
8 bytes, 7 runes
106 u8 é rune
```

In C# and Java, `"journée".Length` and `"journée".length()` are 7: they count UTF-16 units. In V, [`len`](https://modules.vlang.io/builtin.html#string) counts the bytes of the UTF-8 encoding, and `é` takes two. Indexing a string gives a byte (`u8`), not a character: `word[0]` is 106, the code of `j`. [`runes()`](https://modules.vlang.io/builtin.html#string.runes) decodes the code points; a rune literal uses backquotes.

### `if` and `match` are expressions

V has no ternary operator: `if` returns a value. [`match`](https://docs.vlang.io/statements-&-expressions.html#match) is the equivalent of a C# `switch` expression or a Java `switch` with arrows, and must cover every case, here with `else`:

```v
status := if done == lessons { 'finished' } else { 'in progress' }
label := match done {
	0 { 'not started' }
	1, 2, 3 { 'started' }
	else { 'done' }
}
```

```text
in progress
started
```

## Structs instead of classes

V has no classes, no inheritance and no constructors. A [struct](https://docs.vlang.io/structs.html) holds the data, and methods are declared next to it:

```v
struct Page {
	url    string
	locale string = 'en'
	title  string
	lines  int
}
```

```v
mission := Page{
	url:   '/v-for-csharp-java/'
	title: 'Mission'
	lines: 80
}
lesson :=
	Page{'/v-for-csharp-java/02-types-structs-methods/', 'en', '2. Types, structs and methods', 300}
```

- A struct literal names the fields, or gives them all in order.
- A field that isn't given takes its default value: `locale` is `'en'`, and the zero value otherwise (`0`, `''`, an empty array).
- There is no `null`: a `string` field is never missing, only empty.

`@[required]` makes a field mandatory in every literal, like the [`required`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/required) modifier in C# 11:

```v
struct Page {
	url   string @[required]
	title string
}

fn main() {
	p := Page{
		title: 'Mission'
	}
	println(p)
}
```

```text
e02_required_field.v:7:7: error: field `Page.url` must be initialized
    5 | 
    6 | fn main() {
    7 |     p := Page{
      |          ~~~~~
    8 |         title: 'Mission'
    9 |     }
```

### Fields are private and immutable by default

```v
struct Page {
	title string
	lines int
}

fn main() {
	mut p := Page{'Mission', 80}
	p.lines = 81
	println(p)
}
```

```text
e02_immutable_field.v:8:4: error: field `lines` of struct `Page` is immutable
    6 | fn main() {
    7 |     mut p := Page{'Mission', 80}
    8 |     p.lines = 81
      |       ~~~~~
    9 |     println(p)
   10 | }
```

`mut p` makes the variable mutable, not its fields. [Access modifiers](https://docs.vlang.io/structs.html#access-modifiers) are sections of the struct:

| V section | Read from another module | Write in the module | Write from another module | Closest C# | Closest Java |
|---|---|---|---|---|---|
| (none) | no | no | no | `private readonly` | `private final` |
| `mut:` | no | yes | no | `private` | `private` |
| `pub:` | yes | no | no | `public` + `init` | `public final` |
| `pub mut:` | yes | yes | no | `public` + `private set` | public getter, private setter |
| `__global:` | yes | yes | yes | `public` | `public` |

The course code uses one module, so it only needs `mut:`:

```v
struct Progress {
mut:
	done int
pub:
	total int
}
```

## Methods

```v
fn (p Page) is_lesson() bool {
	return p.title.len > 0 && p.title[0].is_digit()
}

fn (mut p Progress) complete() {
	p.done++
}
```

A [method](https://docs.vlang.io/structs.html#methods) is a function with a **receiver** between `fn` and its name. There is no `this`: the receiver has a name, by convention one letter. The receiver is immutable unless declared `mut`, and a `mut` method can only be called on a mutable variable:

```v
fn main() {
	p := Progress{}
	p.complete()
	println(p.done)
}
```

```text
e02_mut_receiver.v:12:2: error: `p` is immutable, declare it with `mut` to make it mutable
   10 | fn main() {
   11 |     p := Progress{}
   12 |     p.complete()
      |     ^
   13 |     println(p.done)
   14 | }
```

The same rule applies to parameters: `fn f(mut pages []Page)` is called as `f(mut pages)`, so the call site shows what can change. But V refuses `mut` for a number, where C# has `ref int`:

```v
fn double(mut n int) {
	n *= 2
}
```

```text
e02_mut_int_param.v:1:17: error: mutable arguments are only allowed for arrays, interfaces, maps, pointers, structs or their aliases
return values instead: `fn foo(mut n int) {` => `fn foo(n int) int {`
    1 | fn double(mut n int) {
      |                 ~~~
    2 |     n *= 2
    3 | }
```

### `str()`, static methods and struct update

```v
fn (p Page) str() string {
	return '${p.title} (${p.locale}, ${p.lines} lines)'
}

fn Page.translation(p Page, locale string, title string) Page {
	return Page{
		...p
		url:    '/${locale}${p.url}'
		locale: locale
		title:  title
	}
}
```

- `str()` plays the role of `ToString()` and `toString()`: `println` and `${…}` call it.
- `fn Page.translation` is a [static method](https://docs.vlang.io/structs.html#static-type-methods), called `Page.translation(…)`. It is the V way to write a factory, since there are no constructors.
- `...p` copies the fields of `p` and replaces the ones listed, like a C# [`with` expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/with-expression) on a record.

```v
println(mission)
println(lesson.is_lesson())
french := Page.translation(lesson, 'fr', '2. Types, structs et méthodes')
println(french.url)
```

```text
Mission (en, 80 lines)
true
/fr/v-for-csharp-java/02-types-structs-methods/
```

### Named and optional arguments

V has no overloading, no default arguments and no named arguments. Two functions with the same name are rejected, whatever their parameters:

```v
fn describe(lines int) string {
	return '${lines} lines'
}

fn describe(title string) string {
	return 'title: ${title}'
}
```

```text
builder error: redefinition of function `describe`
e02_overload.v:1:1: conflicting declaration: fn describe(lines int) string
    1 | fn describe(lines int) string {
      | ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    2 |     return '${lines} lines'
    3 | }
e02_overload.v:5:1: conflicting declaration: fn describe(title string) string
    3 | }
    4 | 
    5 | fn describe(title string) string {
      | ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    6 |     return 'title: ${title}'
    7 | }
```

A struct marked [`@[params]`](https://docs.vlang.io/structs.html#trailing-struct-literal-arguments), as the last parameter, gives the same comfort as named and optional arguments in C#, or a builder in Java:

```v
@[params]
struct ListOptions {
	only_lessons bool
	max          int = 10
}

fn list(pages []Page, opts ListOptions) {
	// …
}

list(pages, max: 2)
list(pages, only_lessons: true)
list(pages)
```

The call lists the fields without braces; the ones left out keep their default value.

## Structs are values

```v
copy := lesson
println(copy == lesson)
mut p1 := Progress{
	total: 4
}
mut p2 := p1
p2.complete()
p1.complete()
p1.complete()
println('p1 ${p1.done}/${p1.total}, p2 ${p2.done}/${p2.total}')
println(p1)
```

```text
true
p1 2/4, p2 1/4
Progress{
    done: 2
    total: 4
}
```

A V struct behaves like a C# `struct` or `record struct`, not like a class: assignment copies it, and `==` compares the fields, like the equality of a C# record or a Java record. `mut p2 := p1` makes a second `Progress`. A struct without `str()` prints all its fields.

Behind the scenes, V passes an immutable struct argument by value or by reference, as it sees fit ([references](https://docs.vlang.io/references.html)); since the callee can't change it, the difference doesn't show. Lesson 4 comes back to references, `&Page`, and to what is shared: arrays and maps don't follow the same rule as structs.

## Key takeaways

- `x := 1` declares an immutable variable; `mut` is needed to reassign it, to change a field, or to call a `mut` method.
- `int` is 32 bits everywhere; V never mixes signed and unsigned types, and never converts a number to a string implicitly.
- A string is UTF-8: `len` counts bytes, indexing gives a `u8`, `runes()` gives the code points.
- A struct has fields that are private and immutable by default, methods with an explicit receiver, and no constructor: static methods and `...p` replace them.
- No overloading, no default or named arguments: an `@[params]` struct replaces them.
- Structs are values, copied on assignment and compared field by field.

## Exercises

1. Write a struct `Course` with a name, a number of lessons and a mutable counter `done`, a method `finish_lesson()` that never goes past the number of lessons, and a `str()` that prints `V: 2/2`. Call `finish_lesson()` three times on a course of two lessons.

<details>
<summary>Solution</summary>

[`examples/s02_course.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s02_course.v#L1-L28):

```v
struct Course {
	name    string
	lessons int
mut:
	done int
}

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
}
```

```text
V: 2/2
```

`for _ in 0 .. 3` repeats three times; `_` ignores the counter, and `0 .. 3` excludes 3.

</details>

2. What does this print? Would a C# `class Course` print the same?

```v
mut a := Course{
	name:    'Rust'
	lessons: 15
}
mut b := a
b.finish_lesson()
println('${a} | ${b}')
```

<details>
<summary>Solution</summary>

```text
Rust: 0/15 | Rust: 1/15
```

`mut b := a` copies the struct: `a` doesn't change. With a C# class, `b` and `a` would be the same object and both would print `Rust: 1/15`; with a C# `struct`, the output would be the same as in V.

</details>

3. `fn double(mut n int)` doesn't compile. Write the function V expects instead, and call it.

<details>
<summary>Solution</summary>

Return the new value, as the error message suggests:

```v
fn double(n int) int {
	return n * 2
}

x := double(2)
```

V allows `mut` parameters only for arrays, maps, structs, interfaces and pointers. The [documentation](https://docs.vlang.io/functions-2.html#mutable-arguments) even prefers returning values for those, and keeps changing an argument in place for the parts of a program where copies cost too much.

</details>

## Sources

- [V documentation — Variables](https://docs.vlang.io/variables.html), [V Types](https://docs.vlang.io/v-types.html), [Structs](https://docs.vlang.io/structs.html), [Functions 2](https://docs.vlang.io/functions-2.html), [References](https://docs.vlang.io/references.html)
- [V standard library — `string`](https://modules.vlang.io/builtin.html#string)
- [C# — Built-in types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/built-in-types), [Records](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record), [Structure types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/struct)
- [Java Language Specification — Types, values and variables](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html), [Record classes](https://docs.oracle.com/en/java/javase/25/language/records.html)
