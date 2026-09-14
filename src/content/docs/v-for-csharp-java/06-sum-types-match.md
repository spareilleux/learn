---
title: "6. Enums, sum types and match"
description: Enums without arithmetic, sum types instead of sealed hierarchies, and a match that must cover every case — tried on the package versions of GuitarAlchemist/ga.
sidebar:
  order: 6
---

Code: [`examples/l06_enums.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v) and [`examples/l06_versions.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_versions.v) — `v run examples/l06_versions.v` from `code/v-for-csharp-java`. The data is the ga projects of [lesson 5](../05-interfaces-generics/#new-data-the-projects-of-a-net-solution).

## Enums

| | C# | Java | V |
|---|---|---|---|
| Declaration | `enum Sdk { Library, Web }` | `enum Sdk { LIBRARY, WEB }` | `enum Sdk { library web }` |
| Underlying value | `int`, converted with a cast | an object, with `ordinal()` | `int` by default, `enum Sdk as u8` |
| Methods | extension methods | yes | yes |
| `<`, `+ 1` | allowed | `compareTo`, no `+` | refused: `int(sdk)` first |
| From a string | `Enum.Parse<Sdk>("Web")` | `Sdk.valueOf("WEB")` | `Sdk.from('web')!` |
| Set of flags | [`[Flags]`](https://learn.microsoft.com/dotnet/api/system.flagsattribute) | [`EnumSet`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/EnumSet.html) | `@[flag]` |

Source: [Enums](https://docs.vlang.io/type-declarations.html#enums).

In ga, the `sdk` column has two values. [`Sdk`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v#L4-L23) names them, with a method, and a function that reads the MSBuild name:

```v
enum Sdk {
	library
	web
}

// An enum can have methods
fn (s Sdk) msbuild_name() string {
	return match s {
		.library { 'Microsoft.NET.Sdk' }
		.web { 'Microsoft.NET.Sdk.Web' }
	}
}

fn parse_sdk(name string) !Sdk {
	return match name {
		'Microsoft.NET.Sdk' { .library }
		'Microsoft.NET.Sdk.Web' { .web }
		else { error('unknown SDK: ${name}') }
	}
}
```

Where the type is known, `.web` is enough: `Sdk.web` in full elsewhere. `match` is an expression, like a C# [switch expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) or a Java `switch` with `->`.

```v
sdk := parse_sdk('Microsoft.NET.Sdk.Web')!
println('${sdk} ${int(sdk)} ${sdk.msbuild_name()}')
println(Sdk.from('library')!)
println(Sdk.from(1)!)
parse_sdk('Microsoft.NET.Sdk.Razor') or { println(err.msg()) }
```

```text
web 1 Microsoft.NET.Sdk.Web
library
web
unknown SDK: Microsoft.NET.Sdk.Razor
```

An enum prints its name, and `int(sdk)` gives its value. An enum is not a number, though:

```v
fn main() {
	sdk := Sdk.library
	if sdk < Sdk.web {
		println('library')
	}
	println(sdk + 1)
}
```

```text
e06_enum_operators.v:8:9: error: only `==` and `!=` are defined on `enum`, use an explicit cast to `int` if needed
    6 | fn main() {
    7 |     sdk := Sdk.library
    8 |     if sdk < Sdk.web {
      |            ^
    9 |         println('library')
   10 |     }
e06_enum_operators.v:11:10: error: infix expr: cannot use `int literal` (right expression) as `Sdk`
    9 |         println('library')
   10 |     }
   11 |     println(sdk + 1)
      |             ~~~~~~~
   12 | }
```

C# accepts both lines. The second message is less helpful than the first: it says `1` isn't an `Sdk`, not that `+` is refused.

### `match` must cover every value

`msbuild_name` has no `else`: it names both values. Add a third value to the enum, and every such `match` stops compiling:

```v
enum Sdk {
	library
	web
	worker
}

fn default_port(sdk Sdk) int {
	return match sdk {
		.library { 0 }
		.web { 8080 }
	}
}
```

```text
e06_match_enum.v:8:9: error: match must be exhaustive (add match branches for: `.worker` or `else {}` at the end)
    6 | 
    7 | fn default_port(sdk Sdk) int {
    8 |     return match sdk {
      |            ~~~~~~~~~~~
    9 |         .library { 0 }
   10 |         .web { 8080 }
```

C# only warns: with .NET 11, a switch expression on an enum without `Worker` gives `warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern 'Sdk.Worker' is not covered.`, and throws a [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception) at run time if the value comes. A `match` on strings or numbers can't list every value, so it always needs `else`:

```v
fn sdk_kind(name string) string {
	return match name {
		'Microsoft.NET.Sdk' { 'library' }
		'Microsoft.NET.Sdk.Web' { 'web' }
	}
}
```

```text
e06_match_string.v:2:9: error: match must be exhaustive (add `else {}` at the end)
    1 | fn sdk_kind(name string) string {
    2 |     return match name {
      |            ~~~~~~~~~~~~
    3 |         'Microsoft.NET.Sdk' { 'library' }
    4 |         'Microsoft.NET.Sdk.Web' { 'web' }
```

A branch can list several values, or an inclusive range with three dots ([`size`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v#L47-L54)); the slices of lesson 4 use two dots, and exclude the end:

```v
fn size(references int) string {
	return match references {
		0 { 'none' }
		1...3 { 'few' }
		4, 5, 6 { 'some' }
		else { 'many' }
	}
}
```

```text
0: none
2: few
5: some
23: many
```

### Flags

A `@[flag]` enum gives each value a bit, like `[Flags]` in C#. [`traits`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_enums.v#L25-L45) sets the flags of a project from its CSV fields:

```v
@[flag]
enum Traits {
	web
	fsharp
	in_solution
}

fn traits(fields []string) Traits {
	mut t := Traits.zero()
	if fields[3] == 'Microsoft.NET.Sdk.Web' {
		t.set(.web)
	}
	if fields[2] == 'F#' {
		t.set(.fsharp)
	}
	if fields[5] == 'true' {
		t.set(.in_solution)
	}
	return t
}
```

```v
mut by_sdk := map[Sdk]int{}
mut web_outside := []string{}
for line in os.read_lines('data/ga/projects.csv')![1..] {
	f := line.split(',')
	by_sdk[parse_sdk(f[3])!]++
	t := traits(f)
	if t.has(.web) && !t.has(.in_solution) {
		web_outside << f[1]
	}
}
println(by_sdk)
println('web projects outside the solution: ${web_outside}')
println(Traits.web | Traits.in_solution)
```

```text
{library: 95, web: 16}
web projects outside the solution: ['FloorManager', 'GA.DocumentProcessing.Service', 'ScenesService', 'GA.Business.AI', 'FretboardExplorer', 'GA.WebBlazorApp']
Traits{.web | .in_solution}
```

Six of ga's 16 web projects are not listed in `AllProjects.slnx`, the solution file.

## Sum types

A NuGet version isn't always three numbers. ga's `package_refs.csv` has releases (`9.5.1`), prereleases (`1.0.0-beta.24164.1`) and [floating versions](https://learn.microsoft.com/nuget/concepts/dependency-resolution#floating-versions) (`8.*-*`, the latest 8.x, prereleases included). Each form has its own data. C# and Java model that with a hierarchy of classes or records; V has a type for it:

| | C# | Java 21+ | V |
|---|---|---|---|
| Declaration | an abstract `record Version`, and `record Release(…) : Version` | [`sealed interface Version permits …`](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) and records | `type Version = Floating \| Prerelease \| Release` |
| Closed | no: any assembly can derive | yes | yes |
| Test and cast | `if (v is Release r)` | `if (v instanceof Release r)` | `if v is Release { }` |
| A case forgotten in a `switch` | warning CS8509, then an exception at run time | a compile error | a compile error |

Source: [Sum types](https://docs.vlang.io/type-declarations.html#sum-types).

[`Version`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_versions.v#L5-L53) is one of three structs. A function that returns `!Version` returns any of them:

```v
struct Release {
	parts []int
}

struct Prerelease {
	release Release
	label   string
}

struct Floating {
	pattern string
}

type Version = Floating | Prerelease | Release

fn parse_version(s string) !Version {
	if s.contains('*') {
		return Floating{s}
	}
	if dash := s.index('-') {
		return Prerelease{parse_release(s[..dash])!, s[dash + 1..]}
	}
	return parse_release(s)!
}
```

`match` on a sum type has one branch per variant; inside each branch, `v` has the variant's type, as with `is`:

```v
fn (v Version) describe() string {
	return match v {
		Release { 'release ${v}' }
		Prerelease { 'prerelease ${v.label} of ${v.release}' }
		Floating { 'floating ${v.pattern}' }
	}
}

fn (v Version) is_stable() bool {
	return v is Release
}
```

```v
for s in ['9.5.1', '1.0.0-beta.24164.1', '8.*-*', '1.x'] {
	v := parse_version(s) or {
		println('${s}: ${err.msg()}')
		continue
	}
	println('${s}: ${v.describe()}, stable: ${v.is_stable()}, type: ${v.type_name()}')
}
```

```text
9.5.1: release 9.5.1, stable: true, type: Release
1.0.0-beta.24164.1: prerelease beta.24164.1 of 1.0.0, stable: false, type: Prerelease
8.*-*: floating 8.*-*, stable: false, type: Floating
1.x: strconv.atoi: parsing "x": invalid radix 10 character
```

`${v}` in the `Release` branch uses `Release.str()`, which joins the parts with dots. `type_name()` gives the variant at run time.

A forgotten variant is an error, like a forgotten enum value:

```v
fn describe(v Version) string {
	return match v {
		Release { 'release' }
		Prerelease { 'prerelease ${v.label}' }
	}
}
```

```text
e06_match_variant.v:16:9: error: match must be exhaustive (add match branches for: `Floating` or `else {}` at the end)
   14 | 
   15 | fn describe(v Version) string {
   16 |     return match v {
      |            ~~~~~~~~~
   17 |         Release { 'release' }
   18 |         Prerelease { 'prerelease ${v.label}' }
```

The same code in Java 25, with a `sealed interface` and three records, gives `error: the switch expression does not cover all possible input values`. An `else {}` branch silences the check, and with it the reminder when a variant is added.

### The versions of ga

```v
mut kinds := map[string]int{}
for line in os.read_lines('data/ga/package_refs.csv')![1..] {
	f := line.split(',')
	v := parse_version(f[2])!
	kinds[v.type_name()]++
	match v {
		Floating {
			println('${f[1]} ${v.pattern} in ${short(f[0])}')
		}
		Release {
			if v.parts.len != 3 {
				println('${f[1]} ${v} has ${v.parts.len} parts, in ${short(f[0])}')
			}
		}
		else {}
	}
}
println(kinds)
```

```text
ModelContextProtocol 0.* in DemerzelBridge
Microsoft.AspNetCore.SpaProxy 8.*-* in ReactApp1.Server
Microsoft.KernelMemory.Core 0.91.241101.1 has 4 parts, in GaCLI
{'Release': 443, 'Prerelease': 33, 'Floating': 2}
```

All 478 versions parse. Two are floating: each restore of `DemerzelBridge` and `ReactApp1.Server` can pick a newer package, so two builds of the same commit may differ, unless the project uses a [lock file](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies). `0.91.241101.1` has four parts, which NuGet accepts ([normalized version numbers](https://learn.microsoft.com/nuget/concepts/package-versioning#normalized-version-numbers)).

### `as`, and a field that only one variant has

`as` casts to a variant, and panics on the wrong one:

```v
fn main() {
	v := Version(Floating{'0.*'})
	r := v as Release
	println(r.parts)
}
```

```text
V panic: as cast: cannot cast `main.Floating` to `main.Release`
```

Prefer `is` or `match`, which can't fail. A trap: V 0.5.2 also accepts `v.parts` directly on a `Version`, without `as`, because only `Release` has a field named `parts`. It compiles, and panics with the same message:

```v
fn main() {
	v := Version(Floating{'0.*'})
	println(v.parts)
}
```

```text
V panic: as cast: cannot cast `main.Floating` to `main.Release`
```

The checker rewrites a field that exists in exactly one variant into an `as` cast ([`checker.v`, lines 3180-3201](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/checker.v#L3180-L3201)). The documentation doesn't mention it. A field that every variant has, with the same type, can be read without a cast ([`table.v`, lines 878-925](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/ast/table.v#L878-L925)).

### A recursive sum type

A variant can contain the sum type itself. [`Tree`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/l06_versions.v#L55-L106) is a project and the projects it references, down to the projects that reference nothing:

```v
struct Leaf {
	name string
}

struct Branch {
	name     string
	children []Tree
}

type Tree = Branch | Leaf

fn (t Tree) count() int {
	return match t {
		Leaf {
			1
		}
		Branch {
			mut n := 1
			for c in t.children {
				n += c.count()
			}
			n
		}
	}
}
```

A branch of a `match` expression can hold statements; its last expression, `n`, is its value. `print` walks the tree the same way:

```text
GaCli (1)
  GA.Business.DSL (3)
    GA.Core
    GA.Domain.Core (2)
      GA.Business.Config
      GA.Core
    GA.Domain.Services (5)
      GA.Business.Config
      GA.Business.Core (1)
        GA.Domain.Core (2)
          GA.Business.Config
          GA.Core
      GA.Core
      GA.Domain.Core (2)
        GA.Business.Config
        GA.Core
      GA.Domain.Repositories (1)
        GA.Domain.Core (2)
          GA.Business.Config
          GA.Core
20 nodes
```

The tree has 20 nodes for 8 projects: `GA.Domain.Core` appears four times, once under each of the four projects that reference it. The references form a graph, not a tree; [lesson 7](../07-concurrency/) counts each project once.

## Key takeaways

- An enum has methods and prints its name; only `==` and `!=` work on it, `int(e)` gives the number, `Sdk.from` reads a name or a value, `@[flag]` makes a set of bits.
- A sum type lists its variants: it is closed, like a Java sealed interface, and needs no base class.
- `match` must cover every enum value or variant, or have `else`; on strings and numbers, `else` is required. An `else` also hides the variants added later.
- `is` and `match` cast safely; `as` panics on the wrong variant, and so does a field that only one variant has, which V 0.5.2 accepts without `as`.

## Exercises

1. Add `fn (v Version) major() ?int`, which returns the first number of a release or a prerelease, and of a floating version when it starts with a number (`8.*-*` gives 8, `*` gives `none`).

<details>
<summary>Solution</summary>

[`examples/s06_major.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/examples/s06_major.v#L19-L25):

```v
fn (v Version) major() ?int {
	return match v {
		Release { v.parts[0] }
		Prerelease { v.release.parts[0] }
		Floating { strconv.atoi(v.pattern.all_before('.')) or { return none } }
	}
}
```

```text
Release: 9
Prerelease: 1
Floating: 8
Floating: no major version
```

The `Floating` branch returns from the function with `none` when the pattern doesn't start with a number; the other branches give an `int`, which becomes the option.

</details>

2. ga adds a worker service, and `Sdk` gets a third value, `worker`, for `Microsoft.NET.Sdk.Worker`. Which functions of `l06_enums.v` does the compiler make you change, and what happens to the others?

<details>
<summary>Solution</summary>

`msbuild_name` stops compiling, with the error of `e06_match_enum.v`: its `match` on the enum has no `else`. `parse_sdk` still compiles: it matches strings, with an `else` that returns an error, so a `Microsoft.NET.Sdk.Worker` project would fail at run time, in `by_sdk[parse_sdk(f[3])!]++`, with `unknown SDK: Microsoft.NET.Sdk.Worker`. `traits` doesn't change, and would count a worker as neither `web` nor anything else.

</details>

3. Why is `if v is Release { v.parts }` safe, while `v.parts` alone can panic, although both compile?

<details>
<summary>Solution</summary>

Inside `if v is Release`, the compiler knows the variant and reads the field directly. `v.parts` alone is rewritten into `(v as Release).parts`, a cast checked at run time, which panics when `v` holds another variant. In C# terms, the first is `if (v is Release r) { r.Parts }`, the second is `((Release)v).Parts`, which throws an `InvalidCastException`, except that in V nothing in the source shows the cast.

</details>

## Sources

- [V documentation — Enums](https://docs.vlang.io/type-declarations.html#enums), [Sum types](https://docs.vlang.io/type-declarations.html#sum-types), [Smart casting](https://docs.vlang.io/type-declarations.html#smart-casting), [Matching sum types](https://docs.vlang.io/type-declarations.html#matching-sum-types); the documentation of 0.5.2: [`doc/docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- [C# — Switch expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [Enumeration types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/enum), [`FlagsAttribute`](https://learn.microsoft.com/dotnet/api/system.flagsattribute)
- [Java — Sealed classes and interfaces](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html), [Pattern matching for switch](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html), [`EnumSet`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/EnumSet.html)
- [NuGet — Package versioning](https://learn.microsoft.com/nuget/concepts/package-versioning), [Floating versions](https://learn.microsoft.com/nuget/concepts/dependency-resolution#floating-versions)
