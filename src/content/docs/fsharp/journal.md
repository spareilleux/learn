---
title: Journal
description: Dated progress notes for the F# course — the SDK and F# Interactive, how the checks work, and what the lessons found in TARS and Guitar Alchemist, with the items still to verify.
sidebar:
  order: 99
---

## Progress

- [x] Course code: scripts, F# Interactive sessions, rejected snippets, exercise solutions and three small projects, compared with their expected output by `check.sh`
- [ ] CI on Linux, Windows and macOS: the workflow is written but not pushed yet (see below)
- [x] Lesson 1: scripts, F# Interactive and projects
- [x] Lesson 2: values, functions and type inference
- [x] Lesson 3: tuples, records, unions and options
- [x] Lesson 4: pattern matching
- [x] Lesson 5: lists, arrays and sequences
- [x] Lesson 6: modules, namespaces and project organization
- [x] Lesson 7: errors with `Result`
- [x] Lesson 8: computation expressions applied to a DSL parser
- [x] Lesson 14: CSV and JSON type providers with FSharp.Data 8.2.0

## Experiments

| Question | Hypothesis | Measured result | Verdict | Evidence |
|---|---|---|---|---|
| Can a minimal computation expression make a DSL grammar readable without hiding failures? | `Bind` and `Return` are enough for the sequential note grammar. | Four cases passed, including rejection of an invalid letter and of trailing input. | Confirmed | [2026-09-20 entry](#2026-09-20--computation-expressions-and-type-providers), [`l08_parser_ce.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l08_parser_ce.fsx) |
| Does FSharp.Data infer useful CSV and nested JSON members from local samples on .NET 10? | FSharp.Data 8.2.0 will expose typed columns and nested properties in F# 10. | Two CSV rows and one nested JSON document compiled and printed the expected typed values. | Confirmed | [2026-09-20 entry](#2026-09-20--computation-expressions-and-type-providers), [`l14_type_providers.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l14_type_providers.fsx) |

## 2026-09-15 — The SDK and F# Interactive

- My machine has the .NET SDKs 10.0.112 and 11.0.100-preview.3.26207.106. The course's [`global.json`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/global.json) pins `10.0.100` with `rollForward: latestFeature`, which selects 10.0.112: F# Interactive 14.0.112.0 for F# 10.0, and FSharp.Core with the assembly version 10.0.0.0.
- The examples are `.fsx` scripts run with `dotnet fsi`, rather than projects: a script starts in about 2 seconds on my machine, needs no build, and can `#load` GA's files and reference FParsec with `#r "nuget: …"`. Only lesson 1 builds projects, three small ones, each in about 2 seconds.
- **A script is type-checked completely before it runs**: in `l01_format_type.fsx`, the `printfn` above the error prints nothing.
- **F# Interactive reported one error per run** in the scripts of this lot: lesson 2's exercise 3 has three independent mistakes and needs four runs. I haven't checked whether `dotnet build` reports more of them at once in a project.
- Compiler messages of a script show the file name without its folder, even when the script is run from another folder. `dotnet build` shows the full path, appends ` [project.fsproj]`, and prints each error twice (once as it happens, once in the summary): [`check.sh`](https://github.com/spareilleux/learn/blob/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/check.sh) keeps the `error FS`/`warning FS` lines, removes the path and the suffix, and removes the duplicates. Multi-line messages such as FS0001's "expected to have type" end some lines with spaces, which `check.sh` also removes.
- An unhandled exception in a script prints the stack trace with full paths, then `Stopped due to error`, and `dotnet fsi` exits with code 1. `check.sh` drops the `   at …` lines.
- F# Interactive sessions are checked by typing a file into `dotnet fsi --nologo`: the output contains the `>` prompts and the answers, without the typed lines. The lessons show the input next to the answers, as a person sees them.
- An equality used as a statement (`strings = 7`) gets warning FS0020 inside a function, but no warning at the top level of a script: I tried it outside the course code, and lesson 2 only shows the function.
- Indentation with a tab is rejected: `error FS1161: TABs are not allowed in F# code unless the #indent "off" option is used` (tried outside the course code).
- A C# check behind lesson 4, compiled on the side with SDK 10.0.112: see [2026-09-15 — C# comparisons](#2026-09-15--c-comparisons).

## 2026-09-15 — CI

- The workflow `.github/workflows/fsharp-examples.yml` runs `check.sh` on `ubuntu-latest`, `windows-latest` and `macos-latest`, like the other courses. It isn't pushed: the token used to push this repository can't create workflow files (it lacks the `workflow` scope). Until it is, the outputs have only been checked on Windows, and everything specific to Linux and macOS is marked *to verify*.
- Two outputs contain non-ASCII characters: `EbΔ9` and FParsec's quotes `‘…’` in `l04_ga_parse`. They are correct in Git Bash on my machine; the Windows runner may print them in another encoding (*to verify*).

## 2026-09-15 — Dogfooding: TARS

TARS at commit [`87464ce`](https://github.com/GuitarAlchemist/tars/tree/87464ce583c42cd11c3d76836e05842377455b24).

- **What is live.** The README says that all active development is in `v2/`. The CI workflow [`dotnet.yml`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/.github/workflows/dotnet.yml#L19-L30) restores, builds and tests `v2` only, and `v2/Tars.sln` contains 17 projects under `v2/src` and one test project. The top level of the repository keeps dozens of older folders (`TarsEngine.FSharp.*`, `backup_fake_elimination_*`…) that no workflow builds: the lessons don't cite them.
- **Nine `.fs` files that nothing compiles.** `v2/src` itself contains `Fibonacci.fs`, `FSharp.ReverseList.fs`, `LintRunner.fs`, `Main.fs`, `OllamaClient.fs`, `PalindromeChecker.fs`, `Program.fs`, `StaticAnalysisRunner.fs` and `ToolFactory.fs`. No `.fsproj` lists them (projects with the same file names list their own copies, such as `Tars.Llm/OllamaClient.fs`), and two of them are almost empty (95 and 3 bytes). `v2/src/Tars.LSP` has a project, `Tars.LSP.fsproj`, that `Tars.sln` doesn't include, so CI doesn't build it either. Lesson 1 uses this to show that an F# project compiles only the files it lists.
- **No license file.** The README shows a "License: MIT" badge that links to `./LICENSE`, but the repository has no `LICENSE` file at this commit, so the link is broken. The course links and quotes TARS's code but doesn't copy its files; `examples/l02_tars_normalize.fsx` retypes one eight-line function to run it.
- **Union cases that hide `Result`.** [`Domain.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Domain.fs#L62-L78) declares `PartialFailure.Error` and `ExecutionOutcome.Failure` without `[<RequireQualifiedAccess>]`. Every file compiled after it that means `Result.Error` must qualify it: `v2/src` has 342 occurrences of `Result.Error`, and `ArcTypes.fs` writes `FSharp.Core.Result.Error`. Files compiled before it, such as `Budget.fs`, write a plain `Error`. Adding the attribute would be a breaking change inside TARS (every `Warning`, `Error`, `Success`, `Failure` of these unions would need its type name). Reproduced in `compile_fail/l03_case_shadowing.fsx`; shown in lesson 3.
- **`TextNormalizer.normalize` keeps ASCII only.** The regular expression `[^a-z0-9\s]` of [`TextNormalizer.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/TextNormalizer.fs#L51-L58) removes `#` (`"learn F#"` gives the keywords `learn` and `f`) and every accented letter (`café` gives `caf`). Its tests use English sentences only, and I found no caller in `v2/src` besides its tests (`grep` at this commit). Shown in lesson 2.
- For lesson 16: `BudgetGovernor` in [`Budget.fs`](https://github.com/GuitarAlchemist/tars/blob/87464ce583c42cd11c3d76836e05842377455b24/v2/src/Tars.Core/Budget.fs#L133-L150) calls itself thread-safe and reads its `mutable consumed` under a lock in `Remaining`, but its `Consumed` property returns the field without the lock.

## 2026-09-15 — Dogfooding: Guitar Alchemist

GA at commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381). Six files are copied in [`code/fsharp/external/ga`](https://github.com/spareilleux/learn/tree/14eebfd073566c52654d9f5671d893d392308871/code/fsharp/external/ga), unchanged except for their line endings.

- **`ChordParser.parse` drops the end of the input.** `pChord` isn't followed by `eof`, so the parser stops at the first character it doesn't recognize and returns `Ok` with what it read: `C7sus4` is normalized to `C7`, and `Am(maj7)` to `Am` (`examples/l04_ga_parse.fsx`, lesson 4). `ChordDslService.Parse` and `Normalize` inherit it, and the C# `ResponseValidator` of the chatbot, which only checks whether `Parse` succeeded, accepts any word that starts like a chord and matches its regular expression. A possible fix is `run (pChord .>> eof) chordStr`, with `C7sus4` and `Am(maj7)` added to [`ChordDslTests.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs#L11-L18); a real `sus4` after an extension would then need a parser rule too.
- **`HarmonicTransformationService.GetNormalForm` depends on the transposition.** For the set `{0, 4, 7, 8}` it returns `[0; 4; 7; 8]`, and for the same set transposed by 8 semitones it returns `[0; 3; 4; 8]`: two rotations have the same span, and `List.minBy fst` keeps the first one instead of comparing the inner intervals as the normal order does (`examples/l02_ga_transformations.fsx`, lesson 2). GitHub's code search found no caller of `GetNormalForm` in GA on 2026-09-15, and GA's `HarmonicTransformationTests.cs` doesn't test it. In the same file, `Invert` and `ApplyNegativeHarmony` compute the same formula (`2 * axis - pc` and `sumAxis - pc`), and the comment of `ApplyNegativeHarmony` still asks "axis = 3.5 semitones?".
- **`Scripts/BinObj.fsx` selects too much and runs nothing.** `isObjOrBinFolder` tests whether a full path *ends with* `bin` or `obj`, ignoring case, so folders named `cabin` or `Robin` are selected, and their subfolders aren't visited. The script defines its functions and never calls them (`examples/l04_ga_binobj.fsx`, lesson 4).
- **`Scripts/ModesConfig.fsx` doesn't run.** Run as it is with `dotnet fsi` from the `Scripts` folder, it stops on line 21 with two `error FS3373: Invalid interpolated string` (at columns 57 and 59): a string literal `", "` inside a `$"…"` interpolation. With a triple-quoted string, the same line gets `FS0039: The value, constructor, namespace or type 'Join' is not defined`, since the script has no `open System` (reproduced in lesson 1's exercise 2). Beyond that, `#r "nuget: GA.Business.Config, 1.0.0"` names a package that nuget.org doesn't have (its package index answered `BlobNotFound` on 2026-09-15), and `#I` adds a folder to search for assemblies, not a package source. A different `ModesConfig.fsx` exists at the root of the repository.
- **Two trees for one chord.** `ChordAst` can write `Bbmaj7` as `Quality = None` with `Extension "maj7"` (what the parser produces) or as `Quality = Some Major` with `Extension "7"`; both render the same text and compare as different (lesson 3's exercise 3).

## 2026-09-15 — C# comparisons

Lesson 4 compares F#'s exhaustiveness check with C#'s. The two C# files below were compiled on the side with `dotnet run` and SDK 10.0.112, not in the course's CI:

- A record hierarchy `abstract record Fingering` with three `sealed` subclasses, and a `switch` expression with one arm per subclass:

  ```text
  hierarchy.cs(3,42): warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern '_' is not covered.
  ```

- An `enum Accidental { Natural, Sharp, Flat }` and a `switch` expression with one arm per named value:

  ```text
  enumswitch.cs(3,41): warning CS8524: The switch expression does not handle some values of its input type (it is not exhaustive) involving an unnamed enum value. For example, the pattern '(Accidental)3' is not covered.
  ```

Both programs still ran and printed their result.

## 2026-09-20 — Collections, modules and `Result`

- Added lesson 5 with executable comparisons of eager `List` and `Array` transformations against a lazy `Seq` pipeline.
- Added lesson 6 with nested modules, explicit visibility and a small organization example that keeps the public surface narrow.
- Added lesson 7 with a `Result` validation pipeline, explicit error composition and the boundary between expected failures and exceptions.
- `dotnet fsi` reproduced the stored outputs for `l05_collections.fsx`, `l06_modules.fsx` and `l07_result.fsx` on .NET SDK 10.0.112.

## 2026-09-20 — Computation expressions and type providers

- Added lesson 8 around a real `Parser<'T>` builder. The harness executes success, invalid-token and trailing-input cases; the last one keeps the end-of-input invariant explicit.
- Added lesson 14 with FSharp.Data 8.2.0, pinned from NuGet. The CSV and JSON samples are local strings, so type checking does not depend on a remote schema.
- `dotnet fsi` produced the outputs stored in `expected/l08_parser_ce.txt` and `expected/l14_type_providers.txt` on .NET SDK 10.0.112.

## To verify

- The whole course on Linux and macOS, and on the Windows runner, once the workflow is pushed.
- The build output folders of lesson 1 on Linux and macOS (`Hello` executable, resource folders).
- <kbd>Alt</kbd>+<kbd>Enter</kbd> to send code to F# Interactive in VS Code with Ionide, Rider and Visual Studio.
- Whether `dotnet build` reports several independent errors of one file in a single run, where F# Interactive reported one.
