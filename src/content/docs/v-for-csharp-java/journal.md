---
title: Journal
description: Dated progress notes for the V course — installing V 0.5.2, the CI on three OSes, surprises in the compiler and the documentation, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] V 0.5.2 installed on Windows, and in CI on Linux, Windows and macOS
- [x] CI: examples, rejected snippets and panics compared with their expected output on three OSes
- [x] Lesson 1: installation, `v run`, modules and projects
- [x] Lesson 2: types, immutable variables, structs and methods
- [x] Lesson 3: errors, `?`, `!` and `or { }`
- [x] Lesson 4: arrays, maps, slices and memory
- [ ] Lesson 5: interfaces and generics

## 2026-09-14 — Installing V 0.5.2

- [0.5.2](https://github.com/vlang/v/releases/tag/0.5.2) is the latest release, published on 2026-07-12; its tag points to commit [`7647ce1`](https://github.com/vlang/v/commit/7647ce1c6fad63b5578bc07883139906de74b2f8). The last weekly release is `weekly.2026.08`, from February.
- Windows: `v_windows.zip` is 23,745,972 bytes. I unzipped it into `C:\Users\spare\tools\v-0.5.2`, outside the `PATH`. `v version` prints `V 0.5.2 7647ce1`; `v doctor` prints `V 0.5.2 45ae01d23168b6372f734eeb38a77360bbcf184a.7647ce1`. I also tried the commands of lesson 1 in a scratch folder: `Invoke-WebRequest` downloaded the archive in 3 s, `Expand-Archive` took 53 s to unzip it.
- The three archives (`v_windows.zip`, `v_linux.zip`, `v_macos_arm64.zip`) all contain TCC as `thirdparty/tcc/tcc.exe`, with the `.exe` on Linux and macOS too, and keep the executable bits of `v` and `tcc.exe`.
- The first `v run hello.v` compiled and ran in 1.6 s, with TCC and no other C compiler installed.
- [docs.vlang.io](https://docs.vlang.io/introduction.html) follows `master`, not the release. Its page [The default compiler](https://docs.vlang.io/the-default-compiler.html) isn't in [0.5.2's `docs.md`](https://github.com/vlang/v/blob/0.5.2/doc/docs.md), and it doesn't even agree with `master`: the web page (built from commit `5db92f0`) says the `v` executable "contains only the experimental V3 C compiler", while [`doc/docs.md` on `master`](https://github.com/vlang/v/blob/master/doc/docs.md) now says it "contains the default compiler whose source lives in `vlib/v`". The lessons check every behavior with 0.5.2 itself.

## 2026-09-14 — The CI

- [`v-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/v-examples.yml) downloads the release archive of each OS, adds its folder to `GITHUB_PATH`, and runs [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/check.sh). The first push passed on the three OSes: the outputs and the compiler messages captured on Windows are identical on Linux and macOS.
- `check.sh` compares standard output *and* standard error of every example, so a new warning or notice fails the job. The rejected snippets are compiled from their folder, so the messages show `e02_immutable.v:3:2` rather than a path that would differ between OSes.
- A panic prints its message, then `v hash`, the process and thread IDs, and a backtrace whose lines depend on the OS and the C compiler. `check.sh` compares the first line and the exit code, 1 on the three OSes.
- `v fmt -verify` fails on the rejected snippets, because it type-checks them: `check.sh` formats every folder except `compile_fail`.
- C compilers, from `v -showcc` in the CI: TCC for development builds on Windows and Linux; `cc` (Apple clang 21) for development builds on macOS, although `v doctor` lists TCC there too; `gcc` (MinGW 15.2) for `-prod` on the Windows runner, `cc` (gcc 13.3) on Linux, `cc` on macOS.
- On my machine, `v doctor` says `msvc version N/A`, yet `v -showcc -prod` compiles with `cl.exe` from the Visual Studio 2022 Build Tools.

## 2026-09-14 — Surprises while writing lessons 1-4

**`v new` without input writes `<EOF>` in `v.mod`.** With standard input closed (`v new hello < /dev/null`), `v new` doesn't stop and writes `description: '<EOF>'`, `version: '<EOF>'` and `license: '<EOF>'`. [`os.input`](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/os/os.v#L436-L441) returns `'<EOF>'` at the end of the input, and [`vcreate.v`](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/cmd/tools/vcreate/vcreate.v#L170-L181) only replaces an empty string with the default. The CI pipes three answers.

**`-autofree` turns the garbage collector off.** The documentation says autofree frees most objects and "the remaining small percentage of objects is freed via GC". In 0.5.2, [`pref.v`, lines 807-811](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/pref.v#L807-L811) sets `gc_mode = .no_gc` for `-autofree`, and `gc_is_enabled()` returns `false` in the lesson 4 example. What autofree misses leaks.

**`-prod` with MSVC turns the garbage collector off.** [`default.v`, lines 369-381](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/default.v#L369-L381) switches to `no_gc` when the C compiler is MSVC on Windows and no `-gc` flag is given. On my machine, `v -prod run examples/l04_memory.v` prints `GC enabled: false` and reaches 542 MB after 50 rounds, against 20 MB for `v run`; `v -prod -gc boehm run` stays at 30 MB. The Windows runner uses `gcc` for `-prod`, and doesn't show this. I haven't found this rule in the documentation.

**A whole array is shared, a slice is cloned.** `alias := original` shares the memory of a `mut` array without a notice, until `original` grows past its capacity; `first := lines[..2]` on the same array is cloned, with a notice. The checker only looks for slices ([`assign.v`, lines 845-855](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/assign.v#L845-L855)). Lesson 4 shows both.

**Two functions with the same name: the error depends on the call.** With `fn describe(lines int)` and `fn describe(title string)`, calling `describe('Mission')` gives `builder error: redefinition of function describe`, the error of lesson 2. Calling `describe(474)` instead gives only `cannot use int literal as string in argument 1 to describe`: the checker reports the type error, and the build stops before the duplicate is reported.

**The type of `7.0 / 2` is `float literal`.** The documentation says a float literal becomes an `f64` when its type has to be decided. Yet:

```v
y := 7.0 / 2
println(typeof(y).name) // float literal
z := 3.5
println(typeof(z).name) // f64
```

The expression keeps the type of the literal, which [`types.v`, line 1278](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/ast/types.v#L1278) names. `println(y)` still prints `3.5`.

**A smart-cast error interpolates as a struct.** After `if err is ParseError`, `${err}` prints the whole struct instead of `msg()`:

```text
line_no 7
interpolated: &ParseError{
    Error: Error{}
    line_no: 7
}
```

Without the cast, `${err}` on an `IError` prints the message, and `error_with_code('negative', 99)` prints `negative; code: 99`. Lesson 3 calls `err.msg()` explicitly.

**A private error type can be tested from another module.** `csv.EndOfFileError` has no `pub` ([`reader.v`, lines 25-31](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/encoding/csv/reader.v#L25-L31)), yet `err is csv.EndOfFileError` compiles in `module main`.

**An option can be stored without being unwrapped.** `z := find_course('java')` compiles, and `println(z)` prints `Option(none)`. The compiler only complains when `z` is used as a `string`, as in lesson 3's `name.to_upper()`.

**`main` can't return an error.** `return err` in an `or` block of `main` gives `unexpected argument, current function does not return anything`; the lesson 3 example uses `panic(err)`.

**String to number never fails.** `'12abc'.int()` is 12, `'abc'.int()` is 0, `'99999999999'.int()` is 2147483647. `strconv.atoi` reports the three.

**A sort expression can't see local variables.** `courses.sort(lines[a] > lines[b])` gives four errors, starting with `can not access external variable lines`; the third and fourth reveal that `a` and `b` are `&string`.

**One mistake, two errors.** A type error inside `println(…)` is followed by `println can not print void expressions` on the same line (lessons 2 and 3).

**The naive CSV parser fails on 50 lines.** `pages.csv` quotes the titles that contain commas: `line.split(',')` gives 6 fields on 50 of the 319 lines. An `awk` script on the same file agrees with the lesson 4 counts: 117 English, 101 French and 101 Spanish pages, and the English lines per course.

## To verify

- `v symlink` on Windows, and whether it changes the user `PATH`.
- A minimal Linux distribution without the C headers: does TCC find what it needs?
- macOS: the quarantine attribute on an archive downloaded with a browser, and development builds with TCC instead of `cc`.
- `v -prod -cc gcc` on a Windows machine that has both MSVC and MinGW.
- [`.vvmrc`](https://docs.vlang.io/project-local-compiler-versions-with-.vvmrc.html), which pins the compiler version of a project like `global.json`: documented in 0.5.2's `docs.md`, not tried yet.
