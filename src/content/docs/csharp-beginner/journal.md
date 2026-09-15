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
- [ ] Lesson 5: classes and objects

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

## To verify

- The installation commands for Linux and macOS: only the CI's `setup-dotnet` ran on those OSes.
- The debugger walkthrough of lesson 3 in VS Code, Visual Studio and Rider, for a file-based app and for a project. VS Code 1.118 and Rider are installed on my machine; Visual Studio isn't.
- The license terms of the three editors, at the time of reading.
