---
title: "5. Interfaces and generics"
description: Interfaces that a type implements without saying so, and generics without constraints — tried on the 111 .NET projects of GuitarAlchemist/ga.
sidebar:
  order: 5
---

Code: [`examples/l05_interfaces.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v) and [`examples/l05_generics.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v) — `v run examples/l05_generics.v` from `code/v-for-csharp-java`.

## New data: the projects of a .NET solution

From this lesson on, the examples read the .NET projects of [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), a music theory application, at commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893). The [LadybugDB course](../../ladybugdb/05-csharp/) extracted them from the `.csproj` and `.fsproj` files; [`data/ga`](https://github.com/spareilleux/learn/tree/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/data/ga) holds a copy of its three CSV files:

| File | Rows | Columns |
|---|---|---|
| `projects.csv` | 111 | `path,name,language,sdk,frameworks,in_solution` |
| `project_refs.csv` | 266 | `from,to`: a `ProjectReference`, from project path to project path |
| `package_refs.csv` | 478 | `project,package,version`: a `PackageReference` |

No field contains a comma, so `line.split(',')` is enough here, unlike the page titles of [lesson 3](../03-errors-option-result/).

## Interfaces

| | C# | Java | V |
|---|---|---|---|
| A type implements an interface | by declaring it: `class Package : INamed` | by declaring it: `implements Named` | by having its methods and fields |
| The declaration | required | required | optional: `struct Package implements Named` |
| Members | methods, properties, [default implementations](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/default-interface-methods-versions) | methods, [default methods](https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html) | methods and fields |
| Test the type | `if (n is Project p)` | `if (n instanceof Project p)` | `if n is Project { }` |

Source: [Interfaces](https://docs.vlang.io/type-declarations.html#interfaces).

An interface lists methods, and fields too. [`Project` and `Package`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v#L4-L38) both have a `name` field and a `kind()` method, so both are `Named`, without a word about it in their declarations:

```v
interface Named {
	name string
	kind() string
}

fn (p Project) kind() string {
	return 'project'
}

fn (p Package) kind() string {
	return 'package'
}

fn describe(n Named) string {
	return '${n.kind()} ${n.name}'
}
```

An array of interface values holds different types, as a `List<INamed>` would. `is` tests the type and casts the variable inside the `if`, like the error types of lesson 3:

```v
items := [Named(project), package, Language{'F#'}]
for item in items {
	println(describe(item))
	println('  ${item.label()}')
	if item is Project {
		println('  sdk: ${item.sdk}')
	}
}
```

```text
project AllProjects.AppHost
  [project] AllProjects.AppHost
  sdk: Microsoft.NET.Sdk
package Aspire.Dashboard.Sdk.win-x64
  [package] Aspire.Dashboard.Sdk.win-x64
language F#
  [language] F#
```

`Named(project)` converts the first element; V then converts the others to the element type of the array.

### A missing method is reported where the value is converted

C# reports a missing member on the class declaration (`error CS0535: 'Package' does not implement interface member 'INamed.Kind()'`), and javac too (`Package is not abstract and does not override abstract method kind() in Named`). In V, `Package` declares nothing, so the error appears where a `Package` becomes a `Named`:

```v
struct Package {
	name    string
	version string
}

fn main() {
	println(describe(Package{'Aspire.Hosting.AppHost', '9.5.1'}))
}
```

```text
e05_missing_method.v:16:19: error: `Package` doesn't implement method `kind` of interface `Named`
   14 | 
   15 | fn main() {
   16 |     println(describe(Package{'Aspire.Hosting.AppHost', '9.5.1'}))
      |                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   17 | }
```

A struct that is never converted is never checked. The optional `implements` moves the check to the declaration, as in C# and Java:

```v
struct Package implements Named {
	name    string
	version string
}
```

```text
e05_implements.v:6:1: error: `Package` doesn't implement method `kind` of interface `Named`
    4 | }
    5 | 
    6 | struct Package implements Named {
      | ~~~~~~~~~~~~~~
    7 |     name    string
    8 |     version string
```

The example's [`Language`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v#L73-L79) uses it.

### Methods on the interface are not default implementations

`fn (n Named) label()` declares a method on the interface itself. Every `Named` value has it, and the types don't implement it. The documentation warns that this is "NOT a 'default implementation' like in C#": if `Project` had its own `label()`, calling `label()` on a `Named` would still run the interface's method, and `Project`'s only after `is Project`. It behaves like a C# extension method on `INamed`, written as a method.

### `mut:` methods

A method that changes its receiver goes in the `mut:` section of the interface. [`Counter` and `Distinct`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_interfaces.v#L40-L71) count the package references in two ways:

```v
interface Tally {
mut:
	add(key string)
	total() int
}
```

```v
lines := os.read_lines('data/ga/package_refs.csv')![1..]
mut tallies := [Tally(Counter{}), Distinct{}]
for mut t in tallies {
	for line in lines {
		t.add(line.split(',')[1])
	}
}
println('package references: ${tallies[0].total()}, distinct packages: ${tallies[1].total()}')
```

```text
package references: 478, distinct packages: 136
```

`for mut t` is needed to call `add`. Outside `mut:`, an interface method is called on an immutable value, and a type whose method has a `mut` receiver doesn't implement it:

```v
interface Tally {
	add(key string)
}

fn (mut c Counter) add(_ string) {
	c.n++
}

fn main() {
	t := Tally(Counter{})
	t.add('Aspire.Hosting.AppHost')
}
```

```text
e05_mut_receiver.v:15:7: error: `Counter` incorrectly implements method `add` of interface `Tally`: expected `Tally` which is immutable, not `mut &Counter`
   13 | 
   14 | fn main() {
   15 |     t := Tally(Counter{})
      |          ~~~~~~~~~~~~~~~~
   16 |     t.add('Aspire.Hosting.AppHost')
   17 | }
Details: main.Tally has `fn add(x main.Tally, key string)`
         main.Counter has `fn add(mut c main.Counter, _ string)`
e05_mut_receiver.v:15:7: error: `Counter` does not implement interface `Tally`, cannot cast `Counter` to interface `Tally`
   13 | 
   14 | fn main() {
   15 |     t := Tally(Counter{})
      |          ~~~~~~~~~~~~~~~~
   16 |     t.add('Aspire.Hosting.AppHost')
   17 | }
```

The reverse is accepted: `total()` is in the `mut:` section, and `Counter` implements it with an immutable receiver. The documentation of 0.5.2 says the opposite (a type with `fn (s MyStruct) write` "implements the interface Foo, but *not* interface Bar", whose `write` is in `mut:`); the compiler only rejects a `mut` receiver for a method outside `mut:` (see the [journal](../journal/)).

### A struct is copied into an interface

```v
mut counter := Counter{}
mut copied := Tally(counter)
copied.add('Aspire.Hosting.AppHost')
println('copied: counter.n = ${counter.n}, copied.total() = ${copied.total()}')
mut shared_counter := &Counter{}
mut through_ref := Tally(shared_counter)
through_ref.add('Aspire.Hosting.AppHost')
println('reference: shared_counter.n = ${shared_counter.n}')
```

```text
copied: counter.n = 0, copied.total() = 1
reference: shared_counter.n = 1
```

Converting a struct value to an interface copies it, like [boxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing) a C# `struct`: with `struct Counter : ITally`, `ITally copied = counter;` also leaves `counter.N` at 0, which I checked with .NET 11. Converting a reference (`&Counter`) shares the struct, like converting a C# class or any Java object.

Interfaces can also embed other interfaces, like structs embed structs: `interface ReaderWriter { Reader Writer }` ([Embedded interface](https://docs.vlang.io/type-declarations.html#embedded-interface)).

## Generics

| | C# | Java | V |
|---|---|---|---|
| Generic function | `Dictionary<string, int> CountBy<T>(…)` | `<T> Map<String, Integer> countBy(…)` | `fn count_by[T](…) map[string]int` |
| Type arguments | inferred, or `CountBy<Project>(…)` | inferred, or `Util.<Project>countBy(…)` | inferred, or `count_by[Project](…)` |
| Constraints | [`where T : IComparable<T>`](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters) | [`<T extends Comparable<T>>`](https://docs.oracle.com/javase/tutorial/java/generics/bounded.html) | none: each use is checked with the concrete type |
| At run time | one version per value type, shared code for references | [erased](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html) to `Object` or the bound | one copy of the function per type used |

Source: [Generics](https://docs.vlang.io/type-declarations.html#generics).

### Generic functions

[`count_by`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v#L35-L47) groups items by a key, like `GroupBy(key).ToDictionary(g => g.Key, g => g.Count())` in LINQ or `Collectors.groupingBy(key, Collectors.counting())` in Java:

```v
fn count_by[T](items []T, key fn (T) string) map[string]int {
	mut counts := map[string]int{}
	for item in items {
		counts[key(item)]++
	}
	return counts
}

// No constraint: T only needs a `name` field at each call
fn names[T](items []T) []string {
	return items.map(it.name)
}
```

```v
println(count_by(projects, fn (p Project) string {
	return p.language
}))
println(count_by[Project](projects, fn (p Project) string {
	return p.sdk
}))
println(names(projects[..2]))
println(names(packages[..2]))
```

```text
{'C#': 105, 'F#': 6}
{'Microsoft.NET.Sdk': 95, 'Microsoft.NET.Sdk.Web': 16}
['AllProjects.AppHost', 'AllProjects.ServiceDefaults']
['Aspire.Dashboard.Sdk.win-x64', 'Aspire.Hosting.AppHost']
```

ga has 105 C# projects and 6 F# projects, 16 of them web projects. V infers `T` from the arguments. When no argument has type `T`, it must be given:

```v
fn parse[T](field string) T {
	return field.int()
}

fn main() {
	println(parse('111'))
}
```

```text
e05_infer.v:6:10: error: could not infer generic type `T` in call to `parse`
    4 | 
    5 | fn main() {
    6 |     println(parse('111'))
      |             ~~~~~~~~~~~~
    7 | }
```

`names` reads `it.name` on a `T` that nothing constrains. C# would refuse to compile the function itself; V checks the body again for every type it is called with, like a C++ template. `Project` and `Package` both have a `name`. A type without one fails, and the error points into the generic function, not at the call:

```v
struct Package {
	id      string
	version string
}

fn names[T](items []T) []string {
	return items.map(it.name)
}

fn main() {
	println(names([Package{'Aspire.Hosting.AppHost', '9.5.1'}]))
}
```

```text
e05_generic_field.v:7:22: error: type `Package` has no field named `name`.
2 possibilities: `id`, `version`.
    5 | 
    6 | fn names[T](items []T) []string {
    7 |     return items.map(it.name)
      |                         ~~~~
    8 | }
    9 |
e05_generic_field.v:7:15: error: cannot use `[]void` as type `[]string` in return argument
    5 | 
    6 | fn names[T](items []T) []string {
    7 |     return items.map(it.name)
      |                  ~~~~~~~~~~~~
    8 | }
    9 |
```

### Generic structs

[`Index[T]`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v#L49-L61) is a map from a key to a `T`, with methods. `get` returns an option, where C# would have `TryGetValue` and Java `Optional<T>`:

```v
struct Index[T] {
mut:
	by_key map[string]T
}

fn (mut ix Index[T]) add(key string, value T) {
	ix.by_key[key] = value
}

fn (ix Index[T]) get(key string) ?T {
	return ix.by_key[key] or { return none }
}
```

```v
mut ix := Index[Project]{}
for p in projects {
	ix.add(p.name, p)
}
println(ix.get('GaApi') or { Project{} }.path)
if p := ix.get('GaServer') {
	println(p.path)
} else {
	println('GaServer: not found')
}
println(typeof(ix).name)
```

```text
Apps/ga-server/GaApi/GaApi.csproj
GaServer: not found
Index[Project]
```

The name is a poor key for ga: two projects are called `GaApi.Tests`, in `Tests/Apps/GaApi.Tests` and `Tests/GaApi.Tests`, so the second `add` replaces the first, and the index holds 110 projects. The path is unique.

### Operators in a generic function

[`largest`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l05_generics.v#L63-L84) compares with `>`. C# rejects that in the generic method itself (`error CS0019: Operator '>' cannot be applied to operands of type 'T' and 'T'`) unless `T` has a constraint. V accepts it for numbers and strings, and for a struct that defines `<`: V generates `>`, `<=` and `>=` from it ([operator overloading](https://docs.vlang.io/limited-operator-overloading.html#implicitly-generated-overloads)).

```v
fn largest[T](items []T) ?T {
	if items.len == 0 {
		return none
	}
	mut best := items[0]
	for x in items[1..] {
		if x > best {
			best = x
		}
	}
	return best
}

struct Usage {
	package  string
	projects int
}

fn (a Usage) < (b Usage) bool {
	return a.projects < b.projects
}
```

```v
println(largest(usages) or { Usage{} })
println(largest(by_package.values()) or { 0 })
println(largest(by_package.keys()) or { '' })
println(largest([]int{}) or { -1 })
```

```text
Usage{
    package: 'Spectre.Console'
    projects: 20
}
20
xunit.runner.visualstudio
-1
```

[Spectre.Console](https://spectreconsole.net/) is the package that the most ga projects reference, 20 of them. Without `<`, the error is again inside the function, and its wording is odd:

```v
fn main() {
	println(largest([20, 12, 9]))
	println(largest([Usage{'Spectre.Console', 20}, Usage{'xunit', 12}]))
}
```

```text
e05_generic_operator.v:9:6: error: cannot use `>` as `<=` operator method is not defined
    7 |     mut best := items[0]
    8 |     for x in items[1..] {
    9 |         if x > best {
      |            ~~~~~~~~
   10 |             best = x
   11 |         }
```

The message doesn't name `Usage`, and doesn't mention line 18, the call that asks for it. Nor does it name `<`, the operator to define: `>` is generated from `<`. In a program with several calls to `largest`, you have to find the one with a struct yourself.

### A compile-time test instead of a constraint

Without constraints, a generic function can test its type argument at compile time with `$if T is …` ([compile-time types](https://docs.vlang.io/conditional-compilation.html#compile-time-types)), and `T.name` gives the type's name:

```v
interface Named {
	name string
}

fn label[T](x T) string {
	$if T is Named {
		return '${T.name} named ${x.name}'
	} $else {
		return 'a ${T.name}'
	}
}
```

```v
println(label(projects[0]))
println(label(usages[0]))
println(label(42))
```

```text
Project named AllProjects.AppHost
a Usage
a int
```

Only the branch that matches `T` is compiled, so `x.name` isn't checked for `int`. Unlike a C# `where`, the test doesn't reject a call: it picks the code for each type.

## Key takeaways

- A type implements an interface by having its methods and fields; the check happens where a value is converted, or at the declaration with the optional `implements`.
- Interfaces can require fields. Methods declared on the interface are not default implementations.
- A method in the `mut:` section needs a mutable interface value; a `mut` receiver can't implement a method outside it.
- Converting a struct value to an interface copies the struct, like boxing in C#; converting a reference shares it.
- Generics have no constraints: the body is checked for each type used, and errors point into the generic function rather than at the call. `$if T is` chooses code at compile time.

## Exercises

1. Write `fn group_by[T](items []T, key fn (T) string) map[string][]T`, and print the names of the F# projects of ga.

<details>
<summary>Solution</summary>

[`examples/s05_group_by.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/s05_group_by.v#L10-L16):

```v
fn group_by[T](items []T, key fn (T) string) map[string][]T {
	mut groups := map[string][]T{}
	for item in items {
		groups[key(item)] << item
	}
	return groups
}
```

```v
groups := group_by(projects, fn (p Project) string {
	return p.language
})
println(groups.keys())
println(groups['F#'].map(it.name))
```

```text
['C#', 'F#']
['GaCli', 'GaMusicTheoryLsp', 'GA.Business.Config', 'GA.Business.Core.Generated', 'GA.Business.DSL', 'GA.Business.ProbabilisticGrammar']
```

`groups[key(item)] << item` works on a missing key: indexing a map for a change creates the empty array, as `counts[key]++` creates the 0 in `count_by`.

</details>

2. Call `largest` on the F# projects of exercise 1, so that it returns the last one by name.

<details>
<summary>Solution</summary>

`Project` needs `<` ([`s05_group_by.v`, lines 31-34](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/s05_group_by.v#L31-L34)):

```v
fn (a Project) < (b Project) bool {
	return a.name < b.name
}
```

```v
println(largest(groups['F#']) or { Project{} }.name)
```

```text
GaMusicTheoryLsp
```

String comparison is ordinal, like `string.CompareOrdinal` in C# and `compareTo` in Java: `'a'` comes after `'A'`, so `GaMusicTheoryLsp` comes after `GA.Business.ProbabilisticGrammar`.

</details>

3. In the copy example, `copied.total()` is 1 and `counter.n` is 0. What would print `copied: counter.n = 1`, and what is the equivalent in C#?

<details>
<summary>Solution</summary>

Converting a reference instead of a value: `mut counter := &Counter{}`, then `Tally(counter)`, as the example does with `shared_counter`. In C#, the interface would have to refer to the same object: make `Counter` a `class` instead of a `struct`. With a `struct`, `ITally copied = counter;` boxes a copy.

</details>

## Sources

- [V documentation — Interfaces](https://docs.vlang.io/type-declarations.html#interfaces), [Generics](https://docs.vlang.io/type-declarations.html#generics), [Limited operator overloading](https://docs.vlang.io/limited-operator-overloading.html), [Compile-time types](https://docs.vlang.io/conditional-compilation.html#compile-time-types); the documentation of 0.5.2: [`doc/docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- [C# — Interfaces](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces), [Constraints on type parameters](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters), [Boxing and unboxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing)
- [Java — Default methods](https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html), [Bounded type parameters](https://docs.oracle.com/javase/tutorial/java/generics/bounded.html), [Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html)
- [GuitarAlchemist/ga at `a26a7893`](https://github.com/GuitarAlchemist/ga/tree/a26a7893), extracted by the [LadybugDB course](../../ladybugdb/05-csharp/)
