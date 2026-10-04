---
title: 12. A small project
description: Put lesson 11's library, a console app and their tests in one solution, use a package from NuGet, make a package of your own, take a first look at async and await, and see what Guitar Alchemist's solution, package versions and command-line tool let through.
sidebar:
  order: 12
---

The programs of this course have been single files, and lesson 11 added a library and its tests. A real program is usually several projects: a library that holds the logic, an application that people run, and tests. This last lesson puts them together in a **solution**. It adds a package from [NuGet](https://learn.microsoft.com/nuget/what-is-nuget), the package manager of .NET, turns the library into a package of its own, and takes a first look at `async` and `await`, the way C# waits for a file or the network without blocking.

The code of this lesson is in [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner): the folder `l12-project` with the solution and its three projects, and the files `l12_*.cs` in `examples`, `exercises` and `compile_fail`. `check.sh` runs the tests, builds the solution, runs the console app with a few commands and packs the library, then compares each output with the files in `expected/`.

## A solution for three projects

A solution is a file that lists projects, so that one command builds or tests them all. From an empty folder, these commands create the solution, the three projects and the references between them:

```sh
dotnet new sln -n Fretboard
dotnet new classlib -o Fretboard
dotnet new console -o Fretboard.App
dotnet new xunit -o Fretboard.Tests
dotnet sln add Fretboard Fretboard.App Fretboard.Tests
dotnet add Fretboard.App reference Fretboard
dotnet add Fretboard.Tests reference Fretboard
```

With SDK 10, `dotnet new sln` creates `Fretboard.slnx`, a solution written in XML. Earlier SDKs created a `.sln` file in an older text format, which [`dotnet sln migrate`](https://learn.microsoft.com/dotnet/core/tools/dotnet-sln) converts. After `dotnet sln add`, the file lists the three projects:

```xml
<Solution>
  <Project Path="Fretboard.App/Fretboard.App.csproj" />
  <Project Path="Fretboard.Tests/Fretboard.Tests.csproj" />
  <Project Path="Fretboard/Fretboard.csproj" />
</Solution>
```

A solution only lists projects. Which project uses which is written in the project files, by `dotnet add reference`, as in lesson 11. In the folder of the solution, [`dotnet build`](https://learn.microsoft.com/dotnet/core/tools/dotnet-build) builds the three projects. `check.sh` keeps their names, sorted, and the counts at the end; the real output gives the path of each compiled file:

```text
Fretboard
Fretboard.App
Fretboard.Tests
0 Warning(s)
0 Error(s)
```

`dotnet test` in the same folder runs the tests of the one test project:

```text
Passed!  - Failed:     0, Passed:     6, Skipped:     0, Total:     6 - Fretboard.Tests.dll (net10.0)
```

`dotnet test` builds only what the tests need: the test project and the library. After `dotnet clean` and `dotnet test`, `check.sh` finds no compiled `Fretboard.App`. With a compile error added to the app's `Program.cs`, `dotnet test` still passed and exited with 0, while `dotnet build` failed. Passing tests don't prove that the whole solution compiles: run `dotnet build` too.

The library is lesson 11's `Fretboard`, with `Guitar` unchanged, `Project` without its `Parse` method, and a new class, `ProjectFile`, shown below. The test project holds two tests of `Guitar` and two of `ProjectFile`.

## The console app

`Fretboard.App` is a small command-line tool on top of the library. Its first argument names a command, and the others are that command's arguments:

```csharp
using System.Globalization;
using Fretboard;

// A small command-line tool on top of the library: the first argument is the command
const string Usage = "usage: fret <open-string-hz> <fret> | transpose <semitones> <notes...> | projects <file.csv>";

if (args.Length == 0)
{
    Console.Error.WriteLine(Usage);
    return 1;
}

try
{
    switch (args[0])
    {
        case "fret" when args.Length == 3:
            double openString = double.Parse(args[1], CultureInfo.InvariantCulture);
            int fret = Guitar.ParseFret(args[2]);
            Console.WriteLine(Guitar.FretFrequency(openString, fret).ToString(CultureInfo.InvariantCulture));
            return 0;

        case "transpose" when args.Length >= 3:
            List<string> notes = [.. args[2..]];
            Console.WriteLine(string.Join(" ", Guitar.Transpose(notes, int.Parse(args[1]))));
            return 0;

        case "projects" when args.Length == 2:
            List<Project> projects = await ProjectFile.ReadAsync(args[1]);
            Console.WriteLine($"{projects.Count} projects, {projects.Sum(p => p.SourceFiles)} source files");
            return 0;

        default:
            Console.Error.WriteLine(Usage);
            return 1;
    }
}
catch (Exception e) when (e is FormatException or ArgumentException or IOException)
{
    // A message and exit code 1: a script that runs the tool sees that it failed
    Console.Error.WriteLine($"error: {e.Message}");
    return 1;
}
```

[`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) runs it: `--project` names the project, and the words after `--` go to the program, in `args`. `check.sh` runs six commands from the course folder, such as `dotnet run --project l12-project/Fretboard.App -- fret 110 7`, and prints the exit code after each. It cuts the folder from the name of the missing file; the real message gives its full path:

```text
> fret 110 7
164.81
-> exit code 0
> transpose 2 C E G
D F# A
-> exit code 0
> projects data/ga-projects.csv
12 projects, 632 source files
-> exit code 0
> fret 110 25
error: fret ('25') must be less than or equal to '24'. (Parameter 'fret')
Actual value was 25.
-> exit code 1
> projects missing.csv
error: Could not find file 'missing.csv'.
-> exit code 1
> (no arguments)
usage: fret <open-string-hz> <fret> | transpose <semitones> <notes...> | projects <file.csv>
-> exit code 1
```

- The **exit code** tells the program that started this one whether it succeeded: 0 for success, anything else for a failure. Top-level statements return it with `return`, as `Main` would ([`Main` and its return value](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/main-command-line)). Bash keeps the code of the last command in `$?`, PowerShell in `$LASTEXITCODE`; scripts and CI test it, as `check.sh` does.
- Errors go to [`Console.Error`](https://learn.microsoft.com/dotnet/api/system.console.error), the standard error, so that they don't mix with the results when the output goes into a file.
- `catch (Exception e) when (...)` is an [exception filter](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements#the-try-catch-statement): it catches only the exceptions for which the condition is true. Any other exception still stops the program, with a nonzero code.
- `case "fret" when args.Length == 3` is a [case guard](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#case-guards): the case matches only if the text is `fret` and there are three arguments.

## A package from NuGet

Lesson 10 read a CSV value between quotes with `TextFieldParser`. [CsvHelper](https://joshclose.github.io/CsvHelper/) is a library for CSV files, published on [nuget.org](https://www.nuget.org/packages/CsvHelper/). A file-based app names a package with a `#:package` line, with the version after `@` ([file-based apps](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps)):

```csharp
#:package CsvHelper@33.1.0
using System.Globalization;
using CsvHelper;

// Lesson 10's line, read this time by the CsvHelper package from NuGet
string line = "\"Crosby, Stills & Nash\",Suite: Judy Blue Eyes,1969";
using var parser = new CsvParser(new StringReader(line), CultureInfo.InvariantCulture);
parser.Read();
string[] fields = parser.Record!;
Console.WriteLine($"CsvHelper: {fields.Length} fields: {string.Join(" | ", fields)}");
```

```text
CsvHelper: 3 fields: Crosby, Stills & Nash | Suite: Judy Blue Eyes | 1969
```

The first `dotnet run` downloads the package into a folder that all your projects share, the [global packages folder](https://learn.microsoft.com/nuget/consume-packages/managing-the-global-packages-and-cache-folders), `.nuget/packages` in your home folder. The version is required: without `@33.1.0`, the restore stops with [NU1015](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1015). The `.csproj` in the message is the project that the SDK builds behind a file-based app:

```text
l12_package_no_version.csproj : error NU1015: The following PackageReference item(s) do not have a version specified: CsvHelper
```

In a project, [`dotnet add package`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-add) writes a `PackageReference` into the project file. On 2026-10-03, `dotnet add Fretboard package CsvHelper` chose the latest stable version and wrote this into `Fretboard.csproj`:

```xml
<ItemGroup>
  <PackageReference Include="CsvHelper" Version="33.1.0" />
</ItemGroup>
```

The library uses it in `ProjectFile`, which reads lesson 10's `ga-projects.csv` into `Project` records:

```csharp
using System.Globalization;
using CsvHelper;

namespace Fretboard;

// Reads a CSV file of projects with the CsvHelper package, which knows about quoted values
public static class ProjectFile
{
    // From any text: a file, or a string in a test
    public static List<Project> Read(TextReader text)
    {
        using var csv = new CsvReader(text, CultureInfo.InvariantCulture);
        return csv.GetRecords<Project>().ToList();
    }

    public static List<Project> Read(string path)
    {
        using var reader = new StreamReader(path);
        return Read(reader);
    }

    // The same, but the program can do something else while the file is read
    public static async Task<List<Project>> ReadAsync(string path)
    {
        string text = await File.ReadAllTextAsync(path);
        return Read(new StringReader(text));
    }
}
```

`GetRecords<Project>()` matches the columns of the header with the parameters of the record's constructor, by name: `Name`, `Language`, `CsFiles`, `FsFiles`. It leaves the computed property `SourceFiles` alone. `Read` takes a [`TextReader`](https://learn.microsoft.com/dotnet/api/system.io.textreader), the base class of `StreamReader` and `StringReader`: the program gives it a file, and a test can give it a string. This test checks the quotes:

```csharp
    [Fact]
    public void Read_KeepsACommaInsideQuotes()
    {
        string text = """
            Name,Language,CsFiles,FsFiles
            "Demos, music theory",C#,3,0
            """;

        List<Project> projects = ProjectFile.Read(new StringReader(text));

        Assert.Equal([new Project("Demos, music theory", "C#", 3, 0)], projects);
    }
```

The text between `"""` is a raw string literal: it can hold quotes and line breaks, and its indentation up to the closing `"""` is removed ([raw string literals](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/raw-string)). Two records with the same values are equal, as lesson 6 showed, so `Assert.Equal` can compare lists of them.

**A package with a known vulnerability.** When it restores packages, NuGet checks them against a database of security advisories ([auditing packages](https://learn.microsoft.com/nuget/concepts/auditing-packages)). Version 12.0.1 of Newtonsoft.Json, a popular JSON library, has one:

```csharp
#:package Newtonsoft.Json@12.0.1
using Newtonsoft.Json;

// An old version of a popular package: the restore warns that it has a known vulnerability
Console.WriteLine(JsonConvert.SerializeObject(new { Chord = "Am7", Frets = "x02010" }));
```

```text
l12_audit.csproj : warning NU1903: Package 'Newtonsoft.Json' 12.0.1 has a known high severity vulnerability, https://github.com/advisories/GHSA-5crp-9r3c-p9vr
l12_audit.csproj : warning NU1903: Package 'Newtonsoft.Json' 12.0.1 has a known high severity vulnerability, https://github.com/advisories/GHSA-5crp-9r3c-p9vr
{"Chord":"Am7","Frets":"x02010"}
```

The warning comes twice, and the program runs. NU1903 is for a high severity; NU1901, NU1902 and NU1904 are for low, moderate and critical ([NU1901–NU1904](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1901-nu1904)). The advisory's page gives the first fixed version: the fix is to use it or a later one. In a project, [`dotnet package list --vulnerable`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-list) prints a table of such packages. It exited with 0 even when the table listed one.

## Your own package

[`dotnet pack`](https://learn.microsoft.com/dotnet/core/tools/dotnet-pack) turns a library into a package, a `.nupkg` file:

```sh
dotnet pack Fretboard
```

```text
The package Fretboard.1.0.0 is missing a readme. Go to https://aka.ms/nuget/authoring-best-practices/readme to learn why package readmes are important.
Successfully created package 'Fretboard.1.0.0.nupkg'.
```

`check.sh` cuts the folder here too: the package is in `Fretboard/bin/Release`.

- With no option, `dotnet pack` builds in Release, not Debug.
- The version is 1.0.0 because the project sets none. `<Version>` in the project file changes it, and the package takes the project's name unless `<PackageId>` gives another ([package properties](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#package-properties)).
- The message about the readme is advice, not an error: nuget.org shows a package's readme on its page.
- A `.nupkg` is a zip file. It holds `lib/net10.0/Fretboard.dll` and `Fretboard.nuspec`, which describes the package and lists CsvHelper as a dependency: a project that installs Fretboard gets CsvHelper too. Exercise 4 looks inside.

[`dotnet nuget push`](https://learn.microsoft.com/dotnet/core/tools/dotnet-nuget-push) publishes a package to nuget.org, with an account and an API key. This course doesn't publish it.

## A first look at `async`

Reading a file or calling a web service takes time, and the program only waits. With `await`, it waits without blocking its thread, which can do other work meanwhile ([asynchronous programming](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/)). A method that returns a [`Task`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task) stands for work that finishes later; `await` waits for it and gives its result:

```csharp
using System.Diagnostics;

// await: the program waits for the file without blocking its thread
string[] lines = await File.ReadAllLinesAsync(Path.Combine("data", "ga-projects.csv"));
Console.WriteLine($"{lines.Length - 1} projects");

// Two waits of half a second, one after the other
var watch = Stopwatch.StartNew();
await Task.Delay(500);
await Task.Delay(500);
Console.WriteLine($"One after the other, at least 1 s: {watch.ElapsedMilliseconds >= 1000}");

// The same two waits started together: Task.WhenAll finishes when both are done
watch.Restart();
Task first = Task.Delay(500);
Task second = Task.Delay(500);
await Task.WhenAll(first, second);
Console.WriteLine($"Together, under 0.9 s: {watch.ElapsedMilliseconds < 900}");
```

```text
12 projects
One after the other, at least 1 s: True
Together, under 0.9 s: True
```

- [`File.ReadAllLinesAsync`](https://learn.microsoft.com/dotnet/api/system.io.file.readalllinesasync) is the async twin of lesson 10's `File.ReadAllLines`; `await` gives its `string[]`.
- [`Task.Delay(500)`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.delay) is a task that finishes after 500 milliseconds, and [`Stopwatch`](https://learn.microsoft.com/dotnet/api/system.diagnostics.stopwatch) measures the time. Two delays awaited one after the other take a second. Started first and awaited together with [`Task.WhenAll`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall), they take half a second: the two waits overlap. Five runs measured 1014 to 1023 ms, then 508 to 514 ms. The program prints `True` or `False` against fixed limits, because the exact times change from run to run.
- A method that uses `await` is marked `async` and returns `Task`, or `Task<T>` for a result of type `T`, as `ProjectFile.ReadAsync` returns `Task<List<Project>>`. Top-level statements that contain `await` become async without a keyword.

The console app awaits `ReadAsync` in its `projects` command, and xUnit runs an async test, a test method that returns `Task`:

```csharp
    // An async test: xUnit waits for the Task before it reads the result
    [Fact]
    public async Task ReadAsync_GivesTheSameProjectsAsRead()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "data", "ga-projects.csv");

        List<Project> projects = await ProjectFile.ReadAsync(path);

        Assert.Equal(ProjectFile.Read(path), projects);
        Assert.Equal(12, projects.Count);
        Assert.Equal(632, projects.Sum(p => p.SourceFiles));
    }
```

**A forgotten `await`.** Calling an async method starts it, but without `await` nothing waits for it to finish:

```csharp
Console.WriteLine("Before");
WriteLater();   // no await: the program goes on without waiting
Console.WriteLine("After");

async Task WriteLater()
{
    await Task.Delay(100);
    Console.WriteLine("Later");
}
```

```text
l12_forgotten_await.cs(2,1): warning CS4014: Because this call is not awaited, execution of the current method continues before the call is completed. Consider applying the 'await' operator to the result of the call.
Before
After
```

The compiler warns with [CS4014](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/async-await-errors). `WriteLater` runs until its first `await`, then returns a task that nobody waits for. The program prints `After` and ends, and `Later` is never written. Exercise 3 fixes it.

**A constructor can't wait.** A constructor can't be `async`, so it can't contain `await`:

```csharp
var index = new VoicingIndex();

class VoicingIndex
{
    public VoicingIndex()
    {
        await Task.Delay(100);   // a constructor can't be async
    }
}
```

```text
l12_constructor_await.cs(7,9): error CS4033: The 'await' operator can only be used within an async method. Consider marking this method with the 'async' modifier and changing its return type to 'Task'.
```

Writing `public async VoicingIndex()` doesn't help: the compiler then reads `async` as a return type and `VoicingIndex()` as a method, and reports CS0246 and CS0542. The usual way out is a static async method that does the waiting and then calls a constructor that doesn't wait, such as `static async Task<VoicingIndex> CreateAsync()`.

## In Guitar Alchemist

The measurements are at commit `5c3a52a`, from a [script](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner/ga-probes) that reads the commit with `git`, and from builds of GA's projects.

**Projects outside the solution.** GA's solution, [`AllProjects.slnx`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/AllProjects.slnx), lists 75 of the 111 project files of the repository. Its CI [builds](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/ci.yml#L43) and [tests](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/ci.yml#L103) that solution. A project outside it is built only if a listed project references it, as 7 are, or if a workflow names it, and its tests run only if a workflow names it. Six test projects are outside the solution and named by no workflow; their files hold 102 lines with a test attribute. One of them, [`GA.Business.Core.Graphiti.Tests`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Graphiti.Tests/GA.Business.Core.Graphiti.Tests.csproj), doesn't compile: its tests use the namespace `GA.Business.Graphiti`, and its project file references no project. The build stops with CS0234 on its two `using GA.Business.Graphiti...` lines.

**Package versions.** Each GA project file gives its own package versions, and 35 packages appear with two or more versions; `MongoDB.Driver` has five. [`Directory.Build.props`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Directory.Build.props#L32-L58) is a file that MSBuild imports into every project below its folder ([customize the build by folder](https://learn.microsoft.com/visualstudio/msbuild/customize-by-directory)). Under the comment "Centralized package version alignment and vulnerability remediation", it tries to align some versions with lines such as `<PackageReference Update="Microsoft.Extensions.Http" Version="10.0.0"/>`. `Update` changes an item that already exists ([MSBuild items](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#items)), but `Directory.Build.props` is imported at the start of each project, before the project's own `PackageReference` items exist: there is nothing to update yet. A probe restored `GA.Business.Core.Graphiti.Tests`, whose project file asks for 9.0.10, and got 9.0.10. With the same line in `Directory.Build.targets`, which MSBuild imports at the end, it got 10.0.0. Across GA's project files, 23 declarations of these packages give another version than the aligned one, 13 of them in projects of the solution. NuGet's [central package management](https://learn.microsoft.com/nuget/consume-packages/central-package-management) keeps one version per package in one file, `Directory.Packages.props`.

**Silenced warnings.** The same file [turns off](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Directory.Build.props#L16-L17) NU1902, NU1903 and NU1904 for every project: the warning of the Newtonsoft.Json example, and its moderate and critical neighbors. The CI has a [security scan](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/ci.yml#L398-L401) that runs `dotnet list AllProjects.slnx package --vulnerable --include-transitive` with `continue-on-error: true`. Even without that line it couldn't fail, since the command exits with 0 when it lists a vulnerable package.

**The command-line tool.** GA's console app, GaCLI, isn't in the solution either. Its own workflow, [*Quality Check*](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/quality_check.yml#L26-L29), builds it and runs `benchmark-quality --limit 50`. In its `Program.cs`, 12 of the 28 commands throw `NotImplementedException`, among them [`benchmark-quality`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/GaCLI/Program.cs#L179-L182) and `analyze-chord`, the first example of its help. In GA's run [37167745677](https://github.com/GuitarAlchemist/ga/actions/runs/37167745677), on a later commit with the same workflow and `Program.cs`, the step ends with an unhandled `NotImplementedException` and exit code 134, and the run is green: the step has `continue-on-error: true`. The command `sync-mongodb` [catches its exceptions](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/GaCLI/Program.cs#L364-L368), prints `Error during sync: Unable to resolve service for type 'GA.Data.MongoDB.Services.MusicalObjectsService'...` and exits with 0, so a script can't tell that it failed. Lesson 10 noted that GaCLI reads `appsettings.yaml` from the current directory. Started from another folder, it runs, and at this commit the file changes nothing: only `sync-mongodb` reads one of its two sections, into settings that no service uses.

**Waiting on tasks.** GA has no `async void` method. Its compiled code blocks on a task with `.Wait()`, `.Result` or `GetAwaiter().GetResult()` in 11 places, 3 of them in constructors, which can't `await`: [`QdrantVectorIndex`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Embeddings/QdrantVectorIndex.cs#L16-L21) calls `InitializeCollectionAsync().Wait()`. Seven other `.Result` read tasks after `await Task.WhenAll`, when they are already finished, as in [`ProductionOrchestrator`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.Core.Orchestration/Services/ProductionOrchestrator.cs#L269-L273): that is the pattern of this lesson's example.

The [QA table](../journal/#qa) and the [Experiments table](../journal/#experiments) of the journal record these measurements.

## Exercises

The solutions are file-based apps in `exercises`; `check.sh` runs them from the course folder.

### Exercise 1 — a package in a file-based app

Print the F# projects of `data/ga-projects.csv`, with their numbers of F# and C# files, from a file-based app that reads the file with CsvHelper.

<details>
<summary>Solution</summary>

```csharp
#:package CsvHelper@33.1.0
using System.Globalization;
using CsvHelper;

// Exercise 1: the F# projects of data/ga-projects.csv, read with CsvHelper in a file-based app
using var reader = new StreamReader(Path.Combine("data", "ga-projects.csv"));
using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);
foreach (Project project in csv.GetRecords<Project>().Where(p => p.Language == "F#"))
{
    Console.WriteLine($"{project.Name}: F# {project.FsFiles}, C# {project.CsFiles}");
}

record Project(string Name, string Language, int CsFiles, int FsFiles);
```

```text
GA.Business.Config: F# 11, C# 8
GA.Business.DSL: F# 49, C# 0
GA.Business.ProbabilisticGrammar: F# 6, C# 0
GA.Business.Core.Generated: F# 1, C# 0
```

`GetRecords` reads the file lazily, one record at a time, while `foreach` asks for them: the `using` lines keep the file open until the end of the program.

</details>

### Exercise 2 — two files at once

Write an async method that returns the number of lines of a file. Call it on `data/ga-projects.csv` and on `l12-project/Fretboard/Guitar.cs`, and await both calls together with `Task.WhenAll`.

<details>
<summary>Solution</summary>

```csharp
// Exercise 2: count the lines of two files read at the same time
string csv = Path.Combine("data", "ga-projects.csv");
string guitar = Path.Combine("l12-project", "Fretboard", "Guitar.cs");

// Task.WhenAll of Task<int> gives an int[], in the order of the tasks
int[] counts = await Task.WhenAll(CountLinesAsync(csv), CountLinesAsync(guitar));
Console.WriteLine($"{Path.GetFileName(csv)}: {counts[0]} lines");
Console.WriteLine($"{Path.GetFileName(guitar)}: {counts[1]} lines");

async Task<int> CountLinesAsync(string path)
{
    string[] lines = await File.ReadAllLinesAsync(path);
    return lines.Length;
}
```

```text
ga-projects.csv: 13 lines
Guitar.cs: 36 lines
```

The two reads start before the first `await`. The results come back in the order of the tasks, whichever read finishes first.

</details>

### Exercise 3 — the forgotten `await`

Fix the program of the forgotten `await` so that it prints `Before`, `Later` and `After`, with no warning.

<details>
<summary>Solution</summary>

```csharp
// Exercise 3: the forgotten await, fixed
Console.WriteLine("Before");
await WriteLater();   // the program waits here until WriteLater has finished
Console.WriteLine("After");

async Task WriteLater()
{
    await Task.Delay(100);
    Console.WriteLine("Later");
}
```

```text
Before
Later
After
```

With `await`, the top-level statements become async themselves, and the program ends only after the last line.

</details>

### Exercise 4 — inside the package

After `dotnet pack Fretboard`, write a program that lists the files of `Fretboard.1.0.0.nupkg` with [`ZipFile`](https://learn.microsoft.com/dotnet/api/system.io.compression.zipfile), then prints the `<dependency>` lines of its `.nuspec`.

<details>
<summary>Solution</summary>

```csharp
using System.IO.Compression;

// Exercise 4: what dotnet pack put in the library's package, which is a zip file
string package = Path.Combine("l12-project", "Fretboard", "bin", "Release", "Fretboard.1.0.0.nupkg");
using ZipArchive zip = ZipFile.OpenRead(package);
foreach (ZipArchiveEntry entry in zip.Entries)
{
    // The name of this metadata file is random: print a placeholder instead
    string name = entry.FullName.EndsWith(".psmdcp") ? "package/services/metadata/core-properties/(random).psmdcp" : entry.FullName;
    Console.WriteLine(name);
}

// The packages that a project installing Fretboard gets too
using StreamReader nuspec = new StreamReader(zip.GetEntry("Fretboard.nuspec")!.Open());
foreach (string line in nuspec.ReadToEnd().Split('\n').Where(line => line.Contains("<dependency ")))
{
    Console.WriteLine(line.Trim());
}
```

```text
_rels/.rels
Fretboard.nuspec
lib/net10.0/Fretboard.dll
[Content_Types].xml
package/services/metadata/core-properties/(random).psmdcp
<dependency id="CsvHelper" version="33.1.0" exclude="Build,Analyzers" />
```

In a `.nuspec`, `version="33.1.0"` means 33.1.0 or later ([version ranges](https://learn.microsoft.com/nuget/concepts/package-versioning#version-ranges)). The other files are the packaging format's own: `_rels/.rels`, `[Content_Types].xml` and the `.psmdcp` metadata.

</details>

## Check your understanding

- A solution lists projects; project files say which project references which. `dotnet build` in the solution's folder builds them all. `dotnet test` builds only the test projects and what they reference, so a compile error in the app can hide behind passing tests.
- A console app reads its arguments in `args` and reports success with exit code 0, failure with another code. Errors go to `Console.Error`.
- A package from NuGet comes with a version: `#:package Name@version` in a file-based app, a `PackageReference` written by `dotnet add package` in a project. The restore warns about known vulnerabilities (NU1901 to NU1904).
- `dotnet pack` makes a `.nupkg`, a zip with the compiled library and a `.nuspec` that lists its dependencies.
- `await` waits for a `Task` without blocking the thread; a method that uses it is `async` and returns `Task` or `Task<T>`. `Task.WhenAll` waits for several tasks started together.
- Without `await`, an async call runs on its own, and nobody sees its end or its exceptions; the compiler warns with CS4014. A constructor can't `await`.
- In `Directory.Build.props`, a `PackageReference Update` comes before the project's items and changes nothing. A step with `continue-on-error: true` can't fail a CI run.

This is the last lesson of the course. The [outline](../#outline) lists all twelve. The [Advanced C#](../../csharp-advanced/) course continues with memory, the garbage collector, [`async` under the hood](../../csharp-advanced/03-async-under-the-hood/) and measured performance.

## Sources

- .NET CLI: [`dotnet sln`](https://learn.microsoft.com/dotnet/core/tools/dotnet-sln), [`dotnet build`](https://learn.microsoft.com/dotnet/core/tools/dotnet-build), [`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run), [`dotnet package add`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-add), [`dotnet package list`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-list), [`dotnet pack`](https://learn.microsoft.com/dotnet/core/tools/dotnet-pack), [`dotnet nuget push`](https://learn.microsoft.com/dotnet/core/tools/dotnet-nuget-push), [file-based apps](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps), [package properties](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#package-properties)
- NuGet: [what is NuGet](https://learn.microsoft.com/nuget/what-is-nuget), [global packages folder](https://learn.microsoft.com/nuget/consume-packages/managing-the-global-packages-and-cache-folders), [auditing packages](https://learn.microsoft.com/nuget/concepts/auditing-packages), [NU1015](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1015), [NU1901–NU1904](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1901-nu1904), [version ranges](https://learn.microsoft.com/nuget/concepts/package-versioning#version-ranges), [central package management](https://learn.microsoft.com/nuget/consume-packages/central-package-management); [CsvHelper](https://joshclose.github.io/CsvHelper/) on [nuget.org](https://www.nuget.org/packages/CsvHelper/)
- C#: [asynchronous programming](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/), [exception filters](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements#the-try-catch-statement), [case guards](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#case-guards), [`Main` and command-line arguments](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/main-command-line), [raw string literals](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/raw-string), [errors and warnings of async methods (CS4014, CS4033)](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/async-await-errors)
- API: [`Task`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task), [`Task.Delay`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.delay), [`Task.WhenAll`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall), [`File.ReadAllLinesAsync`](https://learn.microsoft.com/dotnet/api/system.io.file.readalllinesasync), [`Stopwatch`](https://learn.microsoft.com/dotnet/api/system.diagnostics.stopwatch), [`Console.Error`](https://learn.microsoft.com/dotnet/api/system.console.error), [`TextReader`](https://learn.microsoft.com/dotnet/api/system.io.textreader), [`ZipFile`](https://learn.microsoft.com/dotnet/api/system.io.compression.zipfile)
- MSBuild: [customize the build by folder](https://learn.microsoft.com/visualstudio/msbuild/customize-by-directory), [items of .NET SDK projects](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#items)
