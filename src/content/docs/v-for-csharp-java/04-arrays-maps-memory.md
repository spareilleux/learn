---
title: 4. Arrays, maps, slices and memory
description: Arrays and maps compared with List, Dictionary, ArrayList and HashMap, what an assignment shares, and V's four ways to manage memory, measured on three OSes.
sidebar:
  order: 4
---

Code: [`examples/l04_arrays.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_arrays.v), [`examples/l04_maps.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_maps.v), [`examples/l04_references.v`](https://github.com/spareilleux/learn/blob/391a0c46439cb27c820aae4238475d9f3bec5a10/code/v-for-csharp-java/examples/l04_references.v) and [`examples/l04_memory.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_memory.v) — `v run examples/l04_maps.v` from `code/v-for-csharp-java`.

## Arrays

A V array, `[]int`, grows like a `List<int>` or an `ArrayList<Integer>`; there is no separate fixed-size array type in everyday code (`[3]int` exists, for buffers).

```v
mut lines := [474, 341, 326]
lines << 394
lines << [120, 88]
println('${lines} len=${lines.len}')

squares := []int{len: 5, init: index * index}
println(squares)
```

```text
[474, 341, 326, 394, 120, 88] len=6
[0, 1, 4, 9, 16]
```

| | C# | Java | V |
|---|---|---|---|
| Type | `List<int>` | `ArrayList<Integer>` | `[]int` |
| Literal | `[474, 341]` (C# 12) | `List.of(474, 341)` (immutable) | `[474, 341]` |
| Empty, with capacity | `new List<int>(100)` | `new ArrayList<>(100)` | `[]int{cap: 100}` |
| Add | `Add(x)`, `AddRange(xs)` | `add(x)`, `addAll(xs)` | `a << x`, `a << xs` |
| Count | `Count` | `size()` | `len` |
| Contains | `Contains(x)` | `contains(x)` | `x in a` |
| Index out of range | `ArgumentOutOfRangeException` | `IndexOutOfBoundsException` | panic, or `a[i] or { }` |

Sources: [V arrays](https://docs.vlang.io/v-types.html#arrays), [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1), [`ArrayList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ArrayList.html).

`init` is evaluated for each element, with `index` as the position. Elements are always initialized: `[]int{len: 5}` is five zeros.

### `filter`, `map` and sorting

```v
long := lines.filter(it > 300)
println(long)
println(lines.map(it / 10))
println(lines.filter(fn (n int) bool {
	return n < 100
}))
println('${lines.any(it > 400)} ${lines.all(it > 100)}')
println('${326 in lines} ${lines.index(394)}')
```

```text
[474, 341, 326, 394]
[47, 34, 32, 39, 12, 8]
[88]
true false
true 3
```

`filter`, `map`, `any` and `all` take an expression in which `it` is the element, or a function. They return a new array at once: they are not lazy like LINQ or streams.

| LINQ | Streams | V |
|---|---|---|
| `Where(n => n > 300)` | `filter(n -> n > 300)` | `filter(it > 300)` |
| `Select(n => n / 10)` | `map(n -> n / 10)` | `map(it / 10)` |
| `Any(…)`, `All(…)` | `anyMatch(…)`, `allMatch(…)` | `any(…)`, `all(…)` |
| `OrderBy(n => n)` | `sorted()` | `sorted()` |
| `OrderByDescending(n => n)` | `sorted(Comparator.reverseOrder())` | `sorted(a > b)` |

```v
mut sorted := lines.sorted()
println(sorted)
sorted.sort(a > b)
println(sorted)
titles := ['Mission', 'Journal', '1. Install']
println(titles.sorted(a.len < b.len))
```

```text
[88, 120, 326, 341, 394, 474]
[474, 394, 341, 326, 120, 88]
['Mission', 'Journal', '1. Install']
```

`sort` sorts in place, `sorted` returns a copy. The sort expression names the two elements `a` and `b`, and can use nothing else: a variable of the enclosing function is out of reach.

```v
fn main() {
	lines := {
		'duckdb':         3177
		'github-actions': 2785
	}
	mut courses := lines.keys()
	courses.sort(lines[a] > lines[b])
	println(courses)
}
```

```text
e04_sort_capture.v:7:15: error: can not access external variable `lines`
    5 |     }
    6 |     mut courses := lines.keys()
    7 |     courses.sort(lines[a] > lines[b])
      |                  ~~~~~~~~~~~~~~~~
    8 |     println(courses)
    9 | }
e04_sort_capture.v:7:10: error: `.sort()` can only use `a` or `b` as argument, e.g. `arr.sort(a < b)`
    5 |     }
    6 |     mut courses := lines.keys()
    7 |     courses.sort(lines[a] > lines[b])
      |             ~~~~~~~~~~~~~~~~~~~~~~~~~
    8 |     println(courses)
    9 | }
e04_sort_capture.v:7:20: error: invalid key: expected `string`, not `&string`; did you mean `lines[*a]`?
    5 |     }
    6 |     mut courses := lines.keys()
    7 |     courses.sort(lines[a] > lines[b])
      |                       ~~~
    8 |     println(courses)
    9 | }
e04_sort_capture.v:7:31: error: invalid key: expected `string`, not `&string`; did you mean `lines[*b]`?
    5 |     }
    6 |     mut courses := lines.keys()
    7 |     courses.sort(lines[a] > lines[b])
      |                                  ~~~
    8 |     println(courses)
    9 | }
```

The third and fourth errors show how `sort` works: `a` and `b` are references (`&string`) to the elements. [`sort_with_compare`](https://modules.vlang.io/builtin.html#array.sort_with_compare) takes a comparison function instead; the [maps section](#maps) below sorts an array of structs by a field.

## Slices

```v
counts := [474, 341, 326, 394, 120, 88]
first := counts[..2]
println('${first} ${counts[4..]} ${counts#[-2..]}')
```

```text
[474, 341] [120, 88] [120, 88]
```

`a[start..end]` excludes `end`, like C#'s ranges `a[..2]`. A negative index counts from the end, but only with `#[…]`: `counts#[-2..]` is `counts[^2..]` in C#. In V, a slice is an ordinary array (`[]int`), not a separate type like `Span<int>` or a `subList` view.

Whether a slice shares the memory of its array depends on mutability ([array slices](https://docs.vlang.io/v-types.html#array-slices)):

- If the array and the slice are both immutable, the slice shares the array's memory: neither can change it.
- If either is `mut`, V clones the slice, and says so with a notice:

```text
w04_implicit_clone.v:3:16: notice: an implicit clone of the slice was done here
    1 | fn main() {
    2 |     mut lines := [474, 341, 326]
    3 |     first := lines[..2]
      |                   ~~~~~
    4 |     lines[0] = 0
    5 |     println('${lines} ${first}')
Details: w04_implicit_clone.v:3:16: details: To silence this notice, use either an explicit `a[..].clone()`,
or use an explicit `unsafe{ a[..] }`, if you do not want a copy of the slice.
    1 | fn main() {
    2 |     mut lines := [474, 341, 326]
    3 |     first := lines[..2]
      |                   ~~~~~
    4 |     lines[0] = 0
    5 |     println('${lines} ${first}')
[0, 341, 326] [474, 341]
```

`first` kept `[474, 341]` after `lines[0] = 0`: it is a copy.

## What an assignment shares

A struct is copied on assignment ([lesson 2](../02-types-structs-methods/#structs-are-values)). An array isn't. The checker in [`assign.v`, lines 845-855](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/assign.v#L845-L855) only clones *slices* (`a[..]`); a whole array assigned to another variable shares its memory:

```v
mut original := [1, 2, 3]
alias := original
original[0] = 100
println('original ${original}, alias ${alias}')
println('cap ${original.cap}')
original << 4
original[1] = 200
println('original ${original}, alias ${alias}')

mut copy := original.clone()
copy[0] = -1
println('original ${original}, copy ${copy}')
```

```text
original [100, 2, 3], alias [100, 2, 3]
cap 3
original [100, 200, 3, 4], alias [100, 2, 3]
original [100, 200, 3, 4], copy [-1, 200, 3, 4]
```

1. `alias := original` shares the memory: the immutable `alias` sees `original[0] = 100`, without a notice.
2. `original << 4` exceeds the capacity of 3: V moves `original` to a larger block. `alias` still points to the old one, and no longer sees `original[1] = 200`.
3. `clone()` makes an independent copy, like `new List<int>(list)` or `new ArrayList<>(list)`.

A C# `List<int>` or a Java `ArrayList` assigned to another variable is the same object for good; a V array is shared until it grows, like a slice in Go. Being immutable, `alias` protects nothing: the array it reads can still change through `original`.

V refuses the opposite direction, a mutable variable that would share an immutable array:

```v
fn main() {
	lines := [474, 341, 326]
	mut copy := lines
	copy[0] = 0
	println(copy)
}
```

```text
e04_mut_alias.v:3:14: notice: left-side of assignment expects a mutable reference, but variable `lines` is immutable, declare it with `mut` to make it mutable or clone it
    1 | fn main() {
    2 |     lines := [474, 341, 326]
    3 |     mut copy := lines
      |                 ~~~~~
    4 |     copy[0] = 0
    5 |     println(copy)
e04_mut_alias.v:3:11: error: use `mut array2 := array1.clone()` instead of `mut array2 := array1` (or use `unsafe`)
    1 | fn main() {
    2 |     lines := [474, 341, 326]
    3 |     mut copy := lines
      |              ~~
    4 |     copy[0] = 0
    5 |     println(copy)
e04_mut_alias.v:4:2: error: `copy` aliases mutable data from an immutable value, clone it first (or use `unsafe`)
    2 |     lines := [474, 341, 326]
    3 |     mut copy := lines
    4 |     copy[0] = 0
      |     ~~~~
    5 |     println(copy)
    6 | }
```

## Maps

`data/pages.csv` has one line per page of this site. [`encoding.csv`](https://modules.vlang.io/encoding.csv.html) reads it ([lesson 3](../03-errors-option-result/#custom-error-types)), and two maps count the pages per locale and the English lines per course:

```v
mut reader := csv.new_reader(os.read_file('data/pages.csv')!)
reader.read()! // the header: url,locale,course,title,lines
mut pages_per_locale := map[string]int{}
mut lines_per_course := map[string]int{}
for {
	row := reader.read() or { break }
	pages_per_locale[row[1]]++
	if row[1] == 'en' {
		lines_per_course[row[2]] += row[4].int()
	}
}
println(pages_per_locale)
```

```text
{'en': 117, 'es': 101, 'fr': 101}
```

`pages_per_locale[row[1]]++` works the first time a locale appears: a missing key reads as the zero value of the type. That is the main difference with C# and Java:

```v
println(pages_per_locale['de'])
println('de' in pages_per_locale)
println(pages_per_locale['de'] or { -1 })
if n := pages_per_locale['fr'] {
	println('fr: ${n} pages')
}
```

```text
0
false
-1
fr: 101 pages
```

| | C# `Dictionary` | Java `HashMap` | V `map` |
|---|---|---|---|
| Type | `Dictionary<string, int>` | `HashMap<String, Integer>` | `map[string]int` |
| Missing key, `m[k]` | `KeyNotFoundException` | `get` returns `null` | the zero value, `0` |
| Missing key, explicit | `TryGetValue`, `GetValueOrDefault` | `getOrDefault` | `m[k] or { … }`, `if v := m[k] { }` |
| Contains the key | `ContainsKey(k)` | `containsKey(k)` | `k in m` |
| Remove | `Remove(k)` | `remove(k)` | `m.delete(k)` |
| Iteration order | undefined | undefined (`LinkedHashMap`: insertion) | insertion |

Sources: [V maps](https://docs.vlang.io/v-types.html#maps), [`Dictionary<TKey,TValue>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2), [`HashMap`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/HashMap.html).

The zero value hides typos: `m['fr ']` quietly returns 0. A module can opt out of it with `@[strict_map_index]`, which makes every index without `or { }` an error:

```v
@[strict_map_index]
module main

fn main() {
	pages := {
		'en': 117
	}
	println(pages['de'])
}
```

```text
e04_strict_map_index.v:8:15: error: `@[strict_map_index]` requires handling missing map keys with `or {}` or `if value := map[key] {}`
    6 |         'en': 117
    7 |     }
    8 |     println(pages['de'])
      |                  ~~~~~~
    9 | }
```

To sort the entries, the example copies them into an array of structs, since a sort expression only sees `a` and `b`:

```v
struct CourseLines {
	course string
	lines  int
}

mut totals := []CourseLines{}
for course, lines in lines_per_course {
	totals << CourseLines{course, lines}
}
totals.sort(a.lines > b.lines)
println('English lines per course:')
for t in totals[..5] {
	println('  ${t.course:-22} ${t.lines:5}')
}
```

```text
English lines per course:
  streeling               9225
  java-for-csharp         6251
  rust-for-csharp-java    5652
  duckdb                  3177
  github-actions          2785
```

`${t.course:-22}` pads to 22 characters on the right, `${t.lines:5}` to 5 on the left, like `{t.Course,-22}` and `{t.Lines,5}` in C#.

Unlike an array, a map can't be assigned to another variable, mutable or not:

```v
fn main() {
	mut status := {
		'ladybugdb': 'lesson 8'
	}
	next := status
	status['ladybugdb'] = 'done'
	println(next)
}
```

```text
e04_map_copy.v:5:10: error: cannot copy map: call `move` or `clone` method (or use a reference)
    3 |         'ladybugdb': 'lesson 8'
    4 |     }
    5 |     next := status
      |             ~~~~~~
    6 |     status['ladybugdb'] = 'done'
    7 |     println(next)
```

`clone()` makes the copy explicit:

```v
mut status := {
	'duckdb':            'done'
	'ladybugdb':         'lesson 8'
	'v-for-csharp-java': 'lesson 4'
}
status.delete('duckdb')
mut next := status.clone()
next['v-for-csharp-java'] = 'lesson 5'
println(status)
println(next)
```

```text
{'ladybugdb': 'lesson 8', 'v-for-csharp-java': 'lesson 4'}
{'ladybugdb': 'lesson 8', 'v-for-csharp-java': 'lesson 5'}
```

## Memory

### The stack, the heap and references

V puts structs on the stack when it can, and on the heap when their address escapes ([stack and heap](https://docs.vlang.io/memory-management.html#stack-and-heap)). Arrays and maps keep their elements on the heap. You don't choose with a keyword such as C#'s `class` and `struct`: the compiler decides from what the code does with the address.

```v
struct Page {
	title string
}

fn newest() &Page {
	p := Page{'Journal'}
	return &p
}
```

`&Page` is a reference to a `Page`, and `&p` takes the address of `p`. Returning it is allowed: V sees the address leave `newest` and allocates `p` on the heap. `&Page{…}` allocates on the heap directly, like `new` in C# and Java:

```v
lesson := &Page{'4. Arrays, maps, slices and memory'}
println(typeof(lesson).name)
println(lesson.title)
```

```text
&Page
4. Arrays, maps, slices and memory
```

Inside a function that receives a reference, the compiler can't know where the struct lives. It refuses to store the reference, because the struct may be on the caller's stack:

```v
struct Page {
	title string
}

struct History {
mut:
	last &Page = unsafe { nil }
}

fn (mut h History) visit(p &Page) {
	h.last = p
}
```

```text
e04_stack_reference.v:11:11: error: `p` cannot be assigned outside `unsafe` blocks as it might refer to an object stored on stack. Consider declaring `Page` as `@[heap]`.
    9 | 
   10 | fn (mut h History) visit(p &Page) {
   11 |     h.last = p
      |              ^
   12 | }
   13 | 
```

As the message says, `@[heap]` on the struct allocates every instance on the heap, and the same code compiles ([`l04_references.v`, lines 13-26](https://github.com/spareilleux/learn/blob/391a0c46439cb27c820aae4238475d9f3bec5a10/code/v-for-csharp-java/examples/l04_references.v#L13-L26)). A null reference is written `unsafe { nil }`: outside `unsafe`, a reference can't be null.

### The default: a garbage collector

The [documentation](https://docs.vlang.io/memory-management.html) lists four ways to manage memory:

| Mode | Flag | What frees the memory |
|---|---|---|
| Garbage collector | the default | the [Boehm-Demers-Weiser](https://github.com/bdwgc/bdwgc) conservative collector, shipped in `thirdparty/libgc` |
| Autofree | `-autofree` | `free()` calls inserted by the compiler; the documentation calls it a work in progress and advises against it |
| Manual | `-gc none` | nothing: you call `free()` in `unsafe` code, or leak |
| Arena | `-prealloc` | an arena allocator, for short-lived, single-threaded, batch-like programs |

[`l04_memory.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/l04_memory.v#L5-L24) builds 50 arrays of 100,000 strings, one after the other, and keeps none of them. [`runtime.used_memory`](https://modules.vlang.io/runtime.html#used_memory) gives the resident memory of the process, on the three OSes:

```v
for round in 1 .. 51 {
	lines := make_lines(100_000)
	total += lines.len
	if round % 25 == 0 {
		println('round ${round}: ${runtime.used_memory()! / 1024 / 1024} MB resident')
	}
}
```

Resident memory after round 50, as printed by the course's CI and on my machine:

| Build | Windows (my machine) | Windows runner | Linux runner | macOS runner |
|---|---|---|---|---|
| `v run` (GC) | 20 MB | 20 MB | 18 MB | 36 MB |
| `v -gc none run` | 540 MB | 540 MB | 383 MB | 384 MB |
| `v -autofree run` | 10 MB | 9 MB | 6 MB | 6 MB |
| `v -prod run` | 542 MB (MSVC) | | | |
| `v -prod -gc boehm run` | 30 MB (MSVC) | | | |

- With the GC, memory stays flat, like a .NET or Java program: the arrays of the previous rounds are collected.
- With `-gc none`, nothing is freed: memory grows by 8 to 11 MB per round.
- `-autofree` frees each array at the end of its round, and uses the least memory here. It also *disables* the GC: `-autofree` sets `gc_mode = .no_gc` in [`pref.v`, lines 807-811](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/pref.v#L807-L811), so whatever autofree misses leaks, where the documentation says the GC frees it.
- On Windows, a `-prod` build compiled by MSVC turns the GC off without a word: [`default.v`, lines 369-381](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/default.v#L369-L381) switches to `no_gc` when the C compiler is MSVC and no `-gc` flag is given. The same program that stays at 20 MB in development grows to 542 MB in production. `-gc boehm` brings the GC back.

`gc_is_enabled()` tells which case you are in: the example prints it on its first line, `GC enabled: false` with `-gc none`, `-autofree`, and `-prod` compiled by MSVC.

## Key takeaways

- `[]T` is a growable array with `<<`, `filter`, `map`, `sort`; the functional methods are eager, and a sort expression only sees `a` and `b`.
- A slice of an immutable array shares its memory; with `mut` on either side, V clones it and prints a notice.
- Assigning a whole array shares it until it grows past its capacity; `clone()` makes a real copy. A map can't be assigned without `clone()`.
- A missing map key returns the zero value; use `or { }`, `if v := m[k]`, `in`, or `@[strict_map_index]`.
- The compiler chooses the stack or the heap; `&T{}` and `@[heap]` force the heap.
- The GC is the default, `-gc none` leaks what you don't free, and `-autofree` turns the GC off. On Windows, `-prod` with MSVC turns it off too.

## Exercises

1. Count the French lessons of each course in `data/pages.csv` (the titles that start with a digit), and print the courses sorted by name.

<details>
<summary>Solution</summary>

[`examples/s04_lessons_per_course.v`](https://github.com/spareilleux/learn/blob/4fcc7d65f74976bbcb8aafbbf6773219e617f486/code/v-for-csharp-java/examples/s04_lessons_per_course.v#L5-L20):

```v
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
```

```text
duckdb: 8
github-actions: 10
java-for-csharp: 12
rust-for-csharp-java: 15
wsl-containers: 5
```

The map keeps the order in which the courses first appear in the file; `keys()` and `sort()` give the alphabetical order. I checked the counts with `awk` on the same file.

</details>

2. What does this print?

```v
mut a := [1, 2, 3]
b := a
a << 4
a[0] = 9
println('a ${a}, b ${b}')
```

<details>
<summary>Solution</summary>

```text
a [9, 2, 3, 4], b [1, 2, 3]
```

`b := a` shares the array, but `a << 4` exceeds its capacity of 3 and moves `a` to a new block before `a[0] = 9`. Swap the two lines, `a[0] = 9` then `a << 4`, and `b` prints `[9, 2, 3]`.

</details>

3. A long-running V service is built with `v -prod` on a Windows machine with the Visual Studio Build Tools, and its memory grows steadily. What do you check first?

<details>
<summary>Solution</summary>

Whether the GC is on: print `gc_is_enabled()`, or build with `v -showcc -prod` and look for MSVC's `cl.exe`. With MSVC and no `-gc` flag, V 0.5.2 builds without a GC, and every allocation leaks. Build with `-prod -gc boehm`, or with another C compiler (`-cc gcc`, *to verify* on a machine that has both).

</details>

## Sources

- [V documentation — Arrays, Maps](https://docs.vlang.io/v-types.html), [Memory management](https://docs.vlang.io/memory-management.html), [References](https://docs.vlang.io/references.html)
- [V standard library — `array` and `map`](https://modules.vlang.io/builtin.html), [`runtime`](https://modules.vlang.io/runtime.html), [`encoding.csv`](https://modules.vlang.io/encoding.csv.html)
- [C# — `List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1), [`Dictionary<TKey,TValue>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2), [Fundamentals of garbage collection](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals)
- [Java — `ArrayList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ArrayList.html), [`HashMap`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/HashMap.html), [Garbage collection tuning](https://docs.oracle.com/en/java/javase/25/gctuning/)
- [Boehm-Demers-Weiser garbage collector](https://github.com/bdwgc/bdwgc)
