---
title: "8. Tests, v fmt, v vet and v doc"
description: Test functions found by name, assert instead of Assert.Equal, and the formatter, linter and documentation generator that come with the compiler — on a module that parses the dependencies of GuitarAlchemist/ga.
sidebar:
  order: 8
---

Code: [`l08-testing`](https://github.com/spareilleux/learn/tree/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing), a module and its tests, and [`l08-failing`](https://github.com/spareilleux/learn/tree/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-failing), tests that fail on purpose — `v test .` from `code/v-for-csharp-java/l08-testing`.

## Tests

| | C# with xUnit | Java with JUnit 5 | V |
|---|---|---|---|
| Framework | a package: [xUnit](https://xunit.net/), NUnit, MSTest | a dependency: [JUnit](https://docs.junit.org/current/user-guide/) | built in |
| A test | a method with `[Fact]` | a method with `@Test` | a function named `test_…` in a file named `…_test.v` |
| Check | `Assert.Equal(expected, actual)` | `assertEquals(expected, actual)` | `assert actual == expected` |
| Before and after all tests | a fixture, `IClassFixture<T>` | `@BeforeAll`, `@AfterAll` | `testsuite_begin()`, `testsuite_end()` |
| Test private code | [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute) | a test in the same package | a test in the same module |
| Run | [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test) | `mvn test`, `gradle test` | `v test .`, or `v file_test.v` |

Source: [Testing](https://docs.vlang.io/testing.html).

### A module and its tests

`l08-testing` is a project with one module, `deps`, which gathers the version parser of lesson 6 and a graph of project references:

```text
l08-testing/
├── v.mod
├── deps/
│   ├── version.v          module deps: Version, parse_version
│   ├── graph.v            module deps: Graph, Graph.parse, reachable
│   ├── version_test.v     internal tests
│   ├── graph_test.v       internal tests
│   └── s08_cycle_test.v   the solution of exercise 1
└── tests/
    └── ga_test.v          external tests, on the ga CSV files
```

A test file whose first line is `module deps` is an **internal** test: it belongs to the module, and can call its private functions, such as `parse_release` ([`version_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/version_test.v)):

```v
// An internal test: same module, so it can call the private parse_release
module deps

fn test_parse_release() {
	r := parse_release('9.5.1')!
	assert r.parts == [9, 5, 1]
}

fn test_parse_release_rejects_letters() {
	parse_release('1.x') or {
		assert err.msg() == 'strconv.atoi: parsing "x": invalid radix 10 character'
		return
	}
	assert false, 'expected an error'
}

fn test_prerelease() ! {
	v := parse_version('1.0.0-beta.24164.1')!
	assert v is Prerelease
	if v is Prerelease {
		assert v.label == 'beta.24164.1'
		assert v.release.parts == [1, 0, 0]
	}
	assert !v.is_stable()
}
```

There is no assertion library: `assert` takes any boolean expression, and on failure prints both sides of the comparison. A test function can return `!`, and `!` after a call then fails the test with the error, where an xUnit test would let the exception escape. An expected error is checked with `or`, where xUnit has `Assert.Throws` and JUnit `assertThrows`.

A test file that imports the module instead is an **external** test, and sees only what `deps` makes `pub`. [`tests/ga_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/tests/ga_test.v) runs the module on ga's real files:

```v
// An external test: it imports the module, and sees only its public API
import deps
import os

const data = os.join_path(@VMODROOT, '..', 'data', 'ga')

fn testsuite_begin() {
	assert os.exists(data)
}

fn test_every_version_parses() ! {
	lines := os.read_lines(os.join_path(data, 'package_refs.csv'))!
	mut floating := []string{}
	for line in lines[1..] {
		f := line.split(',')
		v := deps.parse_version(f[2])!
		if v is deps.Floating {
			floating << f[1]
		}
	}
	assert floating == ['ModelContextProtocol', 'Microsoft.AspNetCore.SpaProxy']
}

fn test_gacli_references() ! {
	g := deps.Graph.parse(os.read_lines(os.join_path(data, 'project_refs.csv'))!)!
	reachable := g.reachable('Apps/GaCli/GaCli.fsproj')
	assert reachable.len == 7
	assert 'Common/GA.Core/GA.Core.csproj' in reachable
}
```

`@VMODROOT` is the folder of the nearest `v.mod`, known at compile time: the test finds its data wherever it is run from.

### `v test`

`v test .` finds every `_test.v` file under the folder, compiles each one as a separate program, and runs them in parallel:

```text
---- Testing... ----------------------------------------------------------------
OK    [1/4] C:   594.6 ms, R:    83.349 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/deps/graph_test.v
OK    [2/4] C:   593.6 ms, R:    84.106 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/deps/s08_cycle_test.v
OK    [3/4] C:   594.1 ms, R:    84.014 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/tests/ga_test.v
OK    [4/4] C:   593.8 ms, R:    84.440 ms C:/Users/spare/source/repos/learn/code/v-for-csharp-java/l08-testing/deps/version_test.v
--------------------------------------------------------------------------------
Summary for all V _test.v files: 4 passed, 4 total. Elapsed time: 787 ms, on 4 parallel jobs. Comptime: 2376 ms. Runtime: 335 ms.
```

`C:` is the compile time and `R:` the run time of each file: 0.6 s of compilation for 0.08 s of tests. The summary counts files, not tests. The order of the files, the times and the paths change from one run to the next and from one OS to another, so [`check.sh`](https://github.com/spareilleux/learn/blob/f6c34f637df430c031060cb89fb903e7c15be266/code/v-for-csharp-java/check.sh#L99-L108) sorts the `OK` lines and keeps only the path inside the project before comparing.

One more difference in CI: when the `CI` or `GITHUB_JOB` environment variable is set, `v test` hides the `OK` lines, and prints only the failures and the summary ([`common.v`, lines 37-43](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/cmd/tools/modules/testing/common.v#L37-L43)). The first CI run of this lesson failed on that; `VTEST_HIDE_OK=0` brings them back.

### When a test fails

[`l08-failing/failing_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-failing/failing_test.v) fails in four ways:

```v
import strconv

fn testsuite_begin() {
	println('testsuite_begin')
}

fn testsuite_end() {
	println('testsuite_end')
}

fn test_values() {
	parts := '9.5'.split('.').map(strconv.atoi(it) or { -1 })
	assert parts == [9, 5, 1]
	println('not printed: the test stops at the first failed assert')
}

fn test_message() {
	for s in ['9.5.1', '9.5', '1.0.0-beta.1'] {
		assert s.split('.').len == 3, 'version ${s}'
	}
}

fn test_propagated_error() ! {
	lines := strconv.atoi('n/a')!
	assert lines > 0
}

@[assert_continues]
fn test_continues() {
	for s in ['9.5.1', '0.*', '8.*-*'] {
		assert !s.contains('*'), s
	}
	println('printed: assert_continues goes on after a failure')
}

fn test_passes() {
	assert '9.5.1'.split('.').len == 3
}
```

`v failing_test.v`, from its folder, runs one file:

```text
testsuite_begin
failing_test.v:14: fn test_values
   > assert parts == [9, 5, 1]
     Left value (len: 6): `[9, 5]`
    Right value (len: 9): `[9, 5, 1]`

failing_test.v:20: fn test_message
   > assert s.split('.').len == 3, 'version ${s}'
     Left value (len: 1): `2`
    Right value (len: 1): `3`
        Message: version 9.5

failing_test.v:25: fn test_propagated_error failed propagation with error: strconv.atoi: parsing "n/a": invalid radix 10 character
   25 | 	lines := strconv.atoi('n/a')!
failing_test.v:32: fn test_continues
    assert !s.contains('*'), s
        Message: 0.*

failing_test.v:32: fn test_continues
    assert !s.contains('*'), s
        Message: 8.*-*

printed: assert_continues goes on after a failure
testsuite_end
```

The exit code is 1. What the report shows:

- `assert` prints the expression and the value of each side, as `Assert.Equal` prints *Expected* and *Actual*. The `len` in parentheses is the length of the printed text, not of the array: `[9, 5]` has 6 characters.
- A failed `assert` ends its test function, like a failed `Assert` in xUnit or JUnit: `not printed` isn't printed. The other tests still run.
- The message after the comma is the only way to know which iteration of a loop failed. V has no `[Theory]` or `@ParameterizedTest`: a loop over cases with a message does that job.
- An error propagated with `!` fails the test, with the line of the call.
- `@[assert_continues]` reports each failure and goes on, like JUnit's `assertAll`. `-assert continues` on the command line does it for every function.

`-stats` lists each test function:

```text
     OK    [1/7] ms    NO asserts | main.testsuite_begin()
     FAIL  [2/7] ms     1 assert  | main.test_values()
     FAIL  [3/7] ms     2 asserts | main.test_message()
     FAIL  [4/7] ms     0 asserts | main.test_propagated_error()
     OK    [5/7] ms     1 assert  | main.test_continues()
     OK    [6/7] ms     1 assert  | main.test_passes()
     OK    [7/7] ms    NO asserts | main.testsuite_end()
     Summary for running V tests in "failing_test.v": 3 failed, 3 passed, 6 total. Elapsed time: ms.
```

(`check.sh` removes the times, which change with each run.) Two things don't add up. `test_continues` is `OK`, with `1 assert`, although two of its three asserts failed: the file still fails, but this line hides it. And the summary counts asserts, not tests: `test_message` counts as 1 passed and 1 failed.

`assert` also works outside tests, in any function: a failure there is a panic, `V panic: Assertion failed...`. With `-prod`, asserts are removed, as the documentation says: on my machine, `v -prod run` of a program whose `assert 1 + 1 == 3` fails without `-prod` prints the next line and exits with 0. `Debug.Assert` in C# disappears the same way from a Release build.

## `v fmt`

`v fmt` is the formatter, the equivalent of [`dotnet format`](https://learn.microsoft.com/dotnet/core/tools/dotnet-format); Java has none in the JDK. It has no options for style: tabs, spacing and line breaks are V's. [`vet/v08_vet.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/vet/v08_vet.v) is badly formatted on purpose:

```v
module main

// Counts the references of a project
pub fn count(refs []string) int {
    return refs.len
}

fn main() {
	println(count( ['GA.Core','GA.Domain.Core'] ))
}
```

`v fmt -verify` checks without writing, for CI, like `dotnet format --verify-no-changes`:

```text
v08_vet.v is not vfmt'ed
Encountered a total of: 1 formatting errors.
```

The exit code is 1, and the real message starts with the absolute path of the file. `v fmt v08_vet.v` prints the formatted file, and `v fmt -w` rewrites it:

```v
module main

// Counts the references of a project
pub fn count(refs []string) int {
	return refs.len
}

fn main() {
	println(count(['GA.Core', 'GA.Domain.Core']))
}
```

The course's `check.sh` runs `v fmt -verify` on all its folders except the rejected snippets, which `v fmt` type-checks and refuses ([journal](../journal/)).

## `v vet`

`v vet` reports suspicious code, a small counterpart of the [.NET analyzers](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview):

```text
v08_vet.v:4: warning: A function name is missing from the documentation of "pub fn count(refs []string) int".
v08_vet.v:5: error: Looks like you are using spaces for indentation.
Note: You can run `v fmt -w v08_vet.v` to fix these errors automatically
```

The exit code is 1, because of the error; `-W` turns warnings into errors too. The warning is about the comment: V expects the documentation of a public function to start with its name, `// count returns …`, as Go does. `v fmt -w` fixes the indentation, not the comment.

## `v doc`

`v doc` builds the documentation of a module from the comments above its public declarations, like `javadoc` or the [XML documentation comments](https://learn.microsoft.com/dotnet/csharp/language-reference/xmldoc/) of C#, without tags. [`version.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/version.v) and [`graph.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/graph.v) follow the rule of `v vet`. From `l08-testing`, `v doc -comments deps` prints:

```text
module deps
    Package versions, as written in the project files of GuitarAlchemist/ga.

fn parse_version(s string) !Version
    parse_version reads a version, or returns an error when a part isn't a number.
fn Graph.parse(lines []string) !Graph
    Graph.parse reads the lines of project_refs.csv, header included.
type Version = Floating | Prerelease | Release
    Version is one of the three forms.
fn (v Version) is_stable() bool
    is_stable tells whether a version is a release.
struct Floating {
pub:
	pattern string
}
    Floating is a version with a wildcard, such as 8.*-*, that NuGet resolves at restore time.
struct Graph {
mut:
	refs map[string][]string
}
    Graph holds the project references, from a project to the projects it references.
fn (g Graph) reachable(from string) []string
    reachable returns the projects that a project references, directly or not, sorted.
struct Prerelease {
pub:
	release Release
	label   string
}
    Prerelease is a release followed by a label, such as 1.0.0-beta.1.
struct Release {
pub:
	parts []int
}
    Release is a version made of numbers only, such as 9.5.1.
```

The private functions, such as `parse_release`, are left out, but the private field `refs` of `Graph` is shown. `-f html` or `-f md` write other formats.

## Key takeaways

- A test is a `test_` function in a `_test.v` file; `module x` makes it internal, `import x` external. `v test .` compiles each file as a separate program and runs them in parallel.
- `assert` prints both sides of a failed comparison, plus an optional message; it ends the test unless `@[assert_continues]`, and disappears with `-prod`.
- Test functions can return `!`; an expected error is checked with `or`.
- `-stats` and the summaries count asserts, and report a test with continued failures as `OK`: read the failure lines, and the exit code.
- In CI, `v test` hides the passing files unless `VTEST_HIDE_OK=0`.
- `v fmt -verify`, `v vet` and `v doc` come with the compiler; `v vet` wants documentation comments that start with the name.

## Exercises

1. `Graph.reachable` must not loop on a cycle of references. Write a test for `A → B → A`: what should `reachable('A')` return?

<details>
<summary>Solution</summary>

[`l08-testing/deps/s08_cycle_test.v`](https://github.com/spareilleux/learn/blob/bb5c13f2e8e9b85d3a3613d2df53726465afb4ab/code/v-for-csharp-java/l08-testing/deps/s08_cycle_test.v):

```v
// Lesson 8, exercise 1: a cycle of references
module deps

fn test_cycle() ! {
	g := Graph.parse(['from,to', 'A,B', 'B,A'])!
	assert g.reachable('A') == ['A', 'B']
	assert g.reachable('B') == ['A', 'B']
}
```

`v deps/s08_cycle_test.v` prints nothing and exits with 0. The set `seen` stops the walk. `A` is in its own result, because `B` references it: `reachable` returns every project reached from `A`, and `A` is one of them. Whether that is right is a decision the test now records. `v test .` finds the file with the others: the summary above has 4 files.

</details>

2. In `failing_test.v`, `test_message` stops at `9.5` and never checks `1.0.0-beta.1`, which has 4 parts once split on dots. How do you see both failures without changing the loop?

<details>
<summary>Solution</summary>

Put `@[assert_continues]` above `fn test_message()`, or run `v -assert continues failing_test.v` for every function of the file. The report then has one block for `9.5`, with `` Left value (len: 1): `2` ``, and one for `1.0.0-beta.1`, with `` `4` ``: `'1.0.0-beta.1'.split('.')` gives `['1', '0', '0-beta', '1']`. With `@[assert_continues]`, `-stats` then reports `test_message` as `OK`, like `test_continues`.

</details>

3. Fix `vet/v08_vet.v` so that `v vet` reports nothing.

<details>
<summary>Solution</summary>

`v fmt -w v08_vet.v` fixes the indentation. The warning needs a comment that starts with the function's name:

```v
// count returns the number of references of a project.
pub fn count(refs []string) int {
	return refs.len
}
```

The files of `l08-testing` follow that rule: `v vet .` reports nothing there.

</details>

## Sources

- [V documentation — Testing](https://docs.vlang.io/testing.html): [Asserts](https://docs.vlang.io/testing.html#asserts), [Asserts that do not abort your program](https://docs.vlang.io/testing.html#asserts-that-do-not-abort-your-program), [Test files](https://docs.vlang.io/testing.html#test-files), [Running tests](https://docs.vlang.io/testing.html#running-tests); [Tools — v fmt](https://docs.vlang.io/tools.html#v-fmt); [Writing documentation](https://docs.vlang.io/writing-documentation.html); the documentation of 0.5.2: [`doc/docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md)
- `v help test`, `v help vet`, `v help doc` and `v help fmt`, printed by V 0.5.2
- [xUnit](https://xunit.net/), [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test), [`dotnet format`](https://learn.microsoft.com/dotnet/core/tools/dotnet-format), [Code analysis in .NET](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview)
- [JUnit 5 User Guide](https://docs.junit.org/current/user-guide/)
