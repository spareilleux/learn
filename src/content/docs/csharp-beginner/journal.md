---
title: Journal
description: Dated progress notes for the C# for beginners course — the SDK and file-based apps, the checks on three OSes, surprises met while writing the examples, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Course code: file-based apps, rejected snippets and exercise solutions, compared with their expected output by `check.sh`
- [x] CI on Linux, Windows and macOS
- [x] Lesson 1: install .NET and run your first program
- [x] Lesson 2: variables, types and input
- [x] Lesson 3: conditions and loops
- [x] Lesson 4: methods, arrays and lists
- [x] Lesson 5: classes and objects
- [x] Lesson 6: records, structs and enums
- [x] Lesson 7: interfaces and inheritance (local; cross-OS CI still to verify)

## QA

| Expected | What happens | Where | Measurement | Status |
|---|---|---|---|---|
| Printing a GA chord template shows its `Name`, as the base record's `ToString() => Name` intends | The derived records `TonalModal` and `Analytical` each synthesize their own `ToString`, which lists every property: `TonalModal { Name = Major 7th, PitchClassSet = 0 4 7 E, … }`. A derived record keeps the base's `ToString` only when it is `sealed` ([records, built-in formatting](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record#built-in-formatting-for-display)) | [ChordTemplate.cs:84](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L84); one caller, [ContextualChordsController.cs:301](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Apps/ga-server/GA.Fretboard.Service/Controllers/ContextualChordsController.cs#L301), passes `template.ToString()` to a service that logs it ([FretboardServices.cs:536](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Apps/ga-server/GA.Fretboard.Service/Services/FretboardServices.cs#L536)) | A console probe referencing GA.Domain.Core at `5c3a52a`, SDK 10.0.112: the dump for `ToString()` and `$"{template}"` on both records; a replica with `sealed` printed `maj7` ([entry](#2026-10-01--interfaces-and-inheritance)) | Reproduced; not reported to GA |

## 2026-09-14 — The SDK and file-based apps

- My machine has two SDKs: 10.0.112 and 11.0.100-preview.3.26207.106. Without a [`global.json`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/global.json), `dotnet` picks the preview. The course folder pins `10.0.100` with `rollForward: latestFeature`, which selects 10.0.112 here.
- WinGet offers `Microsoft.DotNet.SDK.10` in version 10.0.401 on the same day: a newer feature band than mine. The [file-based apps page](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps) marks `#:include` as available from SDK 10.0.300, so lesson 1 says that a file-based app is one file by default, and that `#:include` adds others from that SDK on. I haven't tried `#:include`: my SDK is older.
- The examples are file-based apps rather than one project per lesson: a beginner types one file and runs it, with nothing to set up. A single `dotnet run app.cs` took 0.9 s the first time and 0.2 s the next.
- Other `.cs` files in the same folder are not compiled with the app: `hello.cs` ran fine next to a file full of errors.
- **Warnings are printed only when the SDK compiles.** A second `dotnet run` of an unchanged file prints no warning, and `dotnet run --no-cache` doesn't help either: it skips the up-to-date check of the file-based app, but MSBuild still finds the compiled output up to date and skips the compiler. `dotnet clean app.cs` before each run brings the warnings back; [`check.sh`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/check.sh#L25-L50) does that, and lesson 3 tells the reader.
- Compiler errors go to standard output, with the full path of the file; `The build failed. Fix the build errors and run again.` goes to standard error. `check.sh` merges both and keeps only the file name, so that the expected files are the same on every machine.
- Syntax errors hide the others: in the broken program of lesson 1's exercise 2, the misspelled `Writeline` (CS0117) is only reported once the missing `;` and quote are fixed. The exercise is built on that.
- Standard input: when the input comes from a file, the typed text doesn't appear in the output, so the expected files contain the prompts followed directly by the answers. The lessons show the terminal as a person sees it, with the typed lines, and say so.
- Culture: my Windows culture is `en-CA`. With `es-ES`, `double.TryParse("1.5")` returns `true` and 15, since the dot is the thousands separator in Spanish; with `fr-FR`, it returns `false`. The example sets each culture explicitly, so the output is the same on every OS. The other examples only use formats that print the same in `en-CA`, `en-US` and the invariant culture of the Linux runner.

## 2026-09-14 — CI

- Commit [`b19a296`](https://github.com/spareilleux/learn/commit/b19a296), run [34914488934](https://github.com/spareilleux/learn/actions/runs/34914488934): green on the three OSes. `actions/setup-dotnet` with the course's `global.json` installed SDK **10.0.401** on all three runners, while the outputs were captured with 10.0.112: every compiler message is identical. Jobs took 54 s on Linux, 1 min 36 s on macOS and 2 min 18 s on Windows, with a `dotnet clean` and a build for each of the 58 file-based apps.
- `Math.Pow(2, 7 / 12.0)` printed with all its digits, `164.81377845643496`, is the same on the three OSes.
- The shebang line `#!/usr/bin/env -S dotnet --` works on the Linux and macOS runners after `chmod +x`, and `dotnet run` ignores it on Windows.
- Exit codes of an unhandled exception differ, so `check.sh` prints them and compares only `exit crash`:
  - Linux and macOS: 134 (the process aborts, `SIGABRT`) for all three crashing examples;
  - Windows, seen from Git Bash: 127 for `IndexOutOfRangeException` and `SwitchExpressionException`, and 139 with a "Segmentation fault" message for `NullReferenceException`;
  - Windows, seen from PowerShell: `0xE0434352` (-532462766), the code of a .NET exception, for `IndexOutOfRangeException`, but `0xC0000005` (-1073741819), an access violation, for `NullReferenceException`.

## 2026-09-14 — Dogfooding

- The examples use Guitar Alchemist as small data: the standard tuning of [`Tuning.Default`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs#L20-L23) at commit `a826864`, and twelve project names of `code/ladybugdb/data/ga/projects.csv`, extracted at commit `a26a7893`. Nothing in these lessons revealed a problem in GA.

## 2026-09-29 — Classes and objects

- Lesson 5 now teaches construction, instance identity, private fields, public properties, methods and a shared `static` count, then asks the reader to build a `PracticeSession` class. The English, French and Spanish pages share the same tested C# snippets and compiler output.
- On Windows, SDK 10.0.112, `C:/Program Files/Git/bin/bash.exe check.sh` passed the course's examples, exercise solutions and rejected snippets, including the new `l05_*` files. The two new rejected snippets produced CS0122 and CS0200, respectively. The host's default `bash` was WSL and could not find the Windows `dotnet`; that first run failed because of the test environment, not the source.
- This local result is not a new three-OS CI run and is not proof that the lesson is publicly deployed. Lessons 6–12 remain only in the outline.

## 2026-09-30 — Lesson 5 in CI on three OSes

- [Run 36664604662](https://github.com/spareilleux/learn/actions/runs/36664604662) of the *C# for beginners examples* workflow, on commit `669d42a` of [PR #60](https://github.com/spareilleux/learn/pull/60), passed on `ubuntu-latest`, `windows-latest` and `macos-latest`. In each job's output, `check.sh` prints `ok` for `l05_objects`, `l05_ex_practice`, `l05_get_only_property` and `l05_private_field`: the outputs and the CS0122 and CS0200 diagnostics match `expected/` on the three OSes.

## 2026-10-01 — Records, structs and enums

- Lesson 6 contrasts a struct with a class (copy on assignment, copy as an argument, `Equals`), then records (`==` on the data, `ToString`, `with`, `readonly record struct`) and enums (numbered from 0, default value, casts, `Enum.IsDefined`, `Enum.Parse`). It has four examples, three exercises and five rejected snippets, whose diagnostics are CS0019, CS1612, CS8852 (three times in two files) and CS0266. A script checked that the three locales share the same code blocks, comments aside, and that each block matches its file in `code/csharp-beginner` and `expected/`.
- On Windows, SDK 10.0.112, under Git Bash, `check.sh` exited 0 with 75 `ok` lines, the 12 `l06_*` files included. This is not yet a three-OS CI run.
- Then in CI: [run 36865237779](https://github.com/spareilleux/learn/actions/runs/36865237779) of the *C# for beginners examples* workflow, on commit `114b5ed` of [PR #93](https://github.com/spareilleux/learn/pull/93), passed on `ubuntu-latest`, `windows-latest` and `macos-latest`. Each job prints `ok` for the 12 `l06_*` files; the jobs count 76 `ok` lines on Linux and macOS and 75 on Windows, because `check.sh` runs the shebang example with `./` only on Linux and macOS.
- Surprises, each kept in the lesson: CS8524 warns about a `switch` expression that has an arm for every name, and its example is `(ChordQuality)5` while the program fails on 7; the literal `0` converts to an enum without a cast, while `2` gives CS0266; a `List<T>` of mutable structs rejects `shape[0].Fret = 5` with CS1612.
- A draft of exercise 3 said that `shape[i].Fret += 2` on a list of `readonly record struct` gives the same CS1612. A probe compiled before publishing gave CS8852 instead; the text was corrected, and `compile_fail/l06_readonly_position.cs` now keeps both CS8852 lines. Two other sentences rest on probes that stayed out of the course code: storing a modified copy back with `shape[0] = position;` printed 5, and `List<T>.Contains` on a class without its own equality answered `False`.
- Dogfooding: at GA commit `5c3a52a`, [`ChordQuality`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordQuality.cs#L10-L23) starts with `Other`, and `PositionLocation`, `Str` and `Fret` are `readonly record struct` types. Nothing in this lesson revealed a problem in GA.

## 2026-10-01 — Interfaces and inheritance

- Lesson 7 builds `Guitar` and `Ukulele` on a `StringInstrument` base class (`base(...)`, `virtual`, `override`, `base.Describe()`, `ToString`), then an abstract `Instrument` with an abstract `Play`, then an `IHasRange` interface that a class and a record both implement. It has four examples, one of which compiles with warning CS0114, three exercises and five rejected snippets, whose diagnostics are CS0506, CS0509, CS0144, CS0534 and CS0535. The script used for lesson 6 checked the 20 code blocks of the three locales against `code/csharp-beginner` and `expected/`.
- On Windows, SDK 10.0.112, under Git Bash, `check.sh` exited 0 with 87 `ok` lines, the 12 `l07_*` files included. This is not yet a three-OS CI run.
- Two sentences of the draft had no run behind them and changed before publishing. That only a variable of type `Ukulele` finds a hiding method is now a line of `examples/l07_hiding_warning.cs`, which prints `a ukulele`. "The MIDI numbers are those of lesson 4, where C4 is 60" was wrong, since lesson 4 gives no MIDI number; the sentence now says that MIDI numbers count semitones, 12 per octave.
- Dogfooding: at GA commit `5c3a52a`, [`ChordTemplate`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L15-L18) is an abstract record whose derived records `TonalModal` and `Analytical` override `Name`, and whose own [`ToString() => Name`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L84) is not `sealed`. The records page says that a `sealed` `ToString` stops the compiler from synthesizing one in derived records ([built-in formatting for display](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/record#built-in-formatting-for-display)), so this one should be shadowed. A probe confirmed it: a console project referencing GA.Domain.Core and GA.Domain.Services at `5c3a52a`, built with SDK 10.0.112, printed `TonalModal { Name = Major 7th, PitchClassSet = 0 4 7 E, … }` for `ToString()` and for `$"{template}"` on a `TonalModal`, on an `Analytical` and on `ChordTemplateFactory.CreateModalChords(...).First()`, and reflection named the derived record as the type that declares `ToString`. A replica of the same shape with `public sealed override string ToString() => Name` printed `maj7`. One call site depends on it: [ContextualChordsController.cs:301](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Apps/ga-server/GA.Fretboard.Service/Controllers/ContextualChordsController.cs#L301) passes `template.ToString()` to `GetVoicingsForChordAsync`, which logs it ([FretboardServices.cs:536](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Apps/ga-server/GA.Fretboard.Service/Services/FretboardServices.cs#L536)); the HTTP response takes the chord name from the route, not from this string. The finding is in the QA table; it has not been reported to GA.

## To verify

- Lesson 7's examples and diagnostics in CI on Linux, Windows and macOS, after a PR is opened.
- The installation commands for Linux and macOS: only the CI's `setup-dotnet` ran on those OSes.
- The debugger walkthrough of lesson 3 in VS Code, Visual Studio and Rider, for a file-based app and for a project. VS Code 1.118 and Rider are installed on my machine; Visual Studio isn't.
- The license terms of the three editors, at the time of reading.

## Open questions

- GA's `Str` and `Fret` each declare an implicit conversion from `int` ([Str.cs:45](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Primitives/Str.cs#L45), [Fret.cs:72](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Primitives/Fret.cs#L72)). Does `new PositionLocation(3, 5)`, with the string and the fret swapped as plain numbers, compile without a warning? Not run.
