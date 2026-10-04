---
title: 11. Unit tests
description: Move methods into a library, test them with xUnit and dotnet test, read the message of a failing test, give a test several rows of data, test exceptions and doubles, and see what Guitar Alchemist's own tests let through.
sidebar:
  order: 11
---

Until now, `check.sh` checked the programs of this course by comparing their whole output with a file. A **unit test** checks one method directly: it calls it with known arguments and compares the result with the value it should return. A test is a small program too. A **test framework** finds the tests, runs each one, counts the failures and says which test failed and why. This lesson uses [xUnit](https://xunit.net/), the framework of the `dotnet new xunit` template, to test methods from lessons 4, 8 and 10.

The code of this lesson is in [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner): `examples/l11_by_hand.cs`, and the folder `l11-tests` with three projects. `Fretboard` is a library, `Fretboard.Tests` holds its tests and the solutions of the exercises, and the tests of `Pitfalls.Tests` fail on purpose. `check.sh` runs [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test) on both test projects and compares a summary with the files in `expected/`.

## A test by hand

A test needs no framework. This program calls lesson 4's `FretFrequency` four times and compares each result with the value it expects:

```csharp
// A test by hand: call a method, compare its result with the expected value, and say which check failed
int failed = 0;
Check("fret 12 of A2", FretFrequency(110.0, 12), 220.0);
Check("fret 7 of A2", FretFrequency(110.0, 7), 164.81);
Check("fret 5 of E2", FretFrequency(82.41, 5), 110.0);
Check("fret 1 of B3", FretFrequency(246.94, 1), 261.63);   // C4 in a table of note frequencies
Console.WriteLine($"{failed} failed");

void Check(string name, double actual, double expected)
{
    if (actual == expected)
    {
        Console.WriteLine($"ok   {name}");
    }
    else
    {
        Console.WriteLine($"FAIL {name}: expected {expected}, got {actual}");
        failed++;
    }
}

// Lesson 4's method
double FretFrequency(double openString, int fret)
{
    double frequency = openString * Math.Pow(2, fret / 12.0);
    return Math.Round(frequency, 2);
}
```

```text
ok   fret 12 of A2
ok   fret 7 of A2
ok   fret 5 of E2
FAIL fret 1 of B3: expected 261.63, got 261.62
1 failed
```

The last check fails, and the method isn't wrong. The expected value, 261.63 Hz, is middle C in a table of frequencies. The method starts from 246.94, the open B string already rounded to two decimals, and one fret above it gives 261.62. A failing test only says that two values differ: the code may be wrong, or the expected value, and you have to find out which.

The program also ends with exit code 0, as if everything had passed: a script that runs it can't tell that a check failed. `check.sh` works this way too, with its `ok` and `FAIL` lines, but it sets its own exit code. A test framework does this work for you.

## A library and a test project

A test project can't call the methods of a file-based app. The methods go into a **class library**, a project with no top-level statements that other projects use, and the tests go into a second project that references it. Three commands create both from an empty folder, with the [templates of the SDK](https://learn.microsoft.com/dotnet/core/tools/dotnet-new-sdk-templates):

```sh
dotnet new classlib -n Fretboard
dotnet new xunit -n Fretboard.Tests
dotnet add Fretboard.Tests reference Fretboard
```

The first two print `The template "Class Library" was created successfully.` and `The template "xUnit Test Project" was created successfully.`, then restore the packages; the third one prints ``Reference `..\Fretboard\Fretboard.csproj` added to the project.`` on Windows. Each template also adds a placeholder file, `Class1.cs` and `UnitTest1.cs`, that this lesson deleted.

The library holds the methods of earlier lessons, unchanged, as `public static` methods of a class in the namespace `Fretboard`:

```csharp
namespace Fretboard;

// Methods from earlier lessons, moved into a library so that a test project can call them
public static class Guitar
{
    static readonly string[] Chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

    // Lesson 4: the frequency of a fret, rounded to two decimals
    public static double FretFrequency(double openString, int fret)
    {
        double frequency = openString * Math.Pow(2, fret / 12.0);
        return Math.Round(frequency, 2);
    }

    // Lesson 4, exercise 2: a new list with each note moved by a number of semitones
    public static List<string> Transpose(List<string> notes, int semitones)
    {
        List<string> result = [];
        foreach (string note in notes)
        {
            int index = Array.IndexOf(Chromatic, note);
            int moved = ((index + semitones) % 12 + 12) % 12;   // + 12 keeps negative steps in 0..11
            result.Add(Chromatic[moved]);
        }
        return result;
    }

    // Lesson 8, exercise 2: a fret number read from text, from 0 to 24
    public static int ParseFret(string text)
    {
        int fret = int.Parse(text);
        ArgumentOutOfRangeException.ThrowIfNegative(fret);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(fret, 24);
        return fret;
    }
}
```

A second file, `Project.cs`, holds lesson 10's `Project` record with a `Parse` method for one line of `data/ga-projects.csv`. The test project's file, `Fretboard.Tests.csproj`, lists what the template chose with SDK 10.0.112:

```xml
<ItemGroup>
  <PackageReference Include="coverlet.collector" Version="6.0.4" />
  <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
  <PackageReference Include="xunit" Version="2.9.3" />
  <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4" />
</ItemGroup>

<ItemGroup>
  <Using Include="Xunit" />
</ItemGroup>

<ItemGroup>
  <ProjectReference Include="..\Fretboard\Fretboard.csproj" />
</ItemGroup>
```

- `xunit` brings the attributes and `Assert`, and `<Using Include="Xunit" />` makes them available in every file of the project without a `using`.
- `xunit.runner.visualstudio` and `Microsoft.NET.Test.Sdk` let `dotnet test` and the editors find and run the tests; `coverlet.collector` measures which lines the tests ran, when you ask for it.
- `ProjectReference` is the line that `dotnet add reference` wrote: the tests can now use the library's public classes.

The template creates an xUnit **v2** project. The [xUnit site](https://xunit.net/docs/getting-started/v2/netcore/cmdline) says that v2 is in maintenance mode, and encourages new work to use v3; this lesson keeps what the template gives.

## A first test

A test is a `public` method with the attribute `[Fact]`, in a `public` class:

```csharp
    // A fact: one case, with no parameter
    [Fact]
    public void FretFrequency_TwelfthFret_DoublesTheFrequency()
    {
        // Arrange: the open A string
        double openA = 110.0;

        // Act
        double result = Guitar.FretFrequency(openA, 12);

        // Assert: the expected value comes first, the actual value second
        Assert.Equal(220.0, result);
    }
```

Most tests have three steps: **arrange** the data, **act** by calling the method, **assert** that the result is the expected one. [`Assert.Equal`](https://xunit.net/docs/getting-started/v2/netcore/cmdline) throws an exception when its two values differ, and xUnit counts the test as failed. Its name says what it tests, in what situation, and what should happen: when it fails, the name alone tells you what broke.

`dotnet test` builds the library and the test project, then runs every test:

```sh
dotnet test l11-tests/Fretboard.Tests
```

It prints the restore and build lines, then one line per test project. `check.sh` keeps that last line, without its duration, which changes on every run:

```text
Passed!  - Failed:     0, Passed:    26, Skipped:     0, Total:    26 - Fretboard.Tests.dll (net10.0)
```

The 26 tests are those of this lesson and the solutions of its exercises. The command ends with exit code 0, and with 1 as soon as one test fails: a script or a CI job sees the failure without reading the text.

Records compare by value (lesson 6), so one `Assert.Equal` checks the four fields that `Project.Parse` reads, and [`Assert.Throws`](https://xunit.net/docs/getting-started/v2/netcore/cmdline) checks that a method throws:

```csharp
    [Fact]
    public void Parse_ReadsTheFourFields()
    {
        Project project = Project.Parse("GA.Core,C#,67,0");

        // Records compare by value: one Assert checks the four fields
        Assert.Equal(new Project("GA.Core", "C#", 67, 0), project);
    }

    [Fact]
    public void Parse_RefusesALineWithoutNumbers()
    {
        Assert.Throws<FormatException>(() => Project.Parse("GA.Core,C#,many,0"));
    }
```

The lambda, `() => Project.Parse(...)`, gives `Assert.Throws` the call to make instead of making it: the exception happens inside `Assert.Throws`, which catches it and checks its type.

## Several cases in one test

A `[Theory]` is a test with parameters, and each `[InlineData]` attribute gives it one row of arguments:

```csharp
    // A theory: the same test with several rows of data, each row a separate test
    [Theory]
    [InlineData(110.0, 0, 110.0)]
    [InlineData(110.0, 7, 164.81)]
    [InlineData(82.41, 5, 110.0)]
    [InlineData(110.0, 12, 220.0)]
    public void FretFrequency_RoundsToTwoDecimals(double openString, int fret, double expected)
    {
        Assert.Equal(expected, Guitar.FretFrequency(openString, fret));
    }
```

xUnit counts each row as a test of its own: with this theory, the project's first version had 15 tests, not 12. A row that fails is reported with its arguments, as the next section shows, and the other rows still run.

## When a test fails

The four tests of `Pitfalls.Tests` fail on purpose. Each one makes a mistake that beginners make, and `dotnet test` explains it:

```csharp
    // 0.1 + 0.2 is not exactly 0.3 in a double
    [Fact]
    public void Doubles_ComparedBitForBit()
    {
        Assert.Equal(0.3, 0.1 + 0.2);
    }

    // ParseFret throws ArgumentOutOfRangeException, a type derived from ArgumentException
    [Fact]
    public void Throws_WithTheBaseType()
    {
        Assert.Throws<ArgumentException>(() => Guitar.ParseFret("25"));
    }

    // The arguments are swapped: the message calls the method's result "Expected"
    [Fact]
    public void Equal_WithTheArgumentsSwapped()
    {
        Assert.Equal(Guitar.FretFrequency(110.0, 7), 164.8);
    }

    // One row of the theory is wrong: E moved up one semitone is F
    [Theory]
    [InlineData("C", 2, "D")]
    [InlineData("B", 1, "C")]
    [InlineData("E", 1, "F#")]
    public void Transpose_OneNote(string note, int semitones, string expected)
    {
        Assert.Equal([expected], Guitar.Transpose([note], semitones));
    }
```

`check.sh` keeps the warnings of the build, the message of each failed test and the last line. It drops the paths, the durations and the *stack trace*, the list of method calls that led to the failure, and it sorts the failed tests by name: xUnit doesn't report them in the order of the file.

```text
PitfallTests.cs(26,9): warning xUnit2000: The literal or constant value 164.8 should be passed as the 'expected' argument in the call to 'Assert.Equal(expected, actual)' in method 'Equal_WithTheArgumentsSwapped' on type 'PitfallTests'. Swap the parameter values. (https://xunit.net/xunit.analyzers/rules/xUnit2000)
  Failed Pitfalls.Tests.PitfallTests.Doubles_ComparedBitForBit
  Error Message:
   Assert.Equal() Failure: Values differ
Expected: 0.29999999999999999
Actual:   0.30000000000000004
  Failed Pitfalls.Tests.PitfallTests.Equal_WithTheArgumentsSwapped
  Error Message:
   Assert.Equal() Failure: Values differ
Expected: 164.81
Actual:   164.80000000000001
  Failed Pitfalls.Tests.PitfallTests.Throws_WithTheBaseType
  Error Message:
   Assert.Throws() Failure: Exception type was not an exact match
Expected: typeof(System.ArgumentException)
Actual:   typeof(System.ArgumentOutOfRangeException)
---- System.ArgumentOutOfRangeException : fret ('25') must be less than or equal to '24'. (Parameter 'fret')
Actual value was 25.
  Failed Pitfalls.Tests.PitfallTests.Transpose_OneNote(note: "E", semitones: 1, expected: "F#")
  Error Message:
   Assert.Equal() Failure: Collections differ
           ↓ (pos 0)
Expected: ["F#"]
Actual:   ["F"]
           ↑ (pos 0)
Failed!  - Failed:     4, Passed:     2, Skipped:     0, Total:     6 - Pitfalls.Tests.dll (net10.0)
```

The 2 tests that pass are the first two rows of the theory. Read each message from the top:

- **Doubles.** A `double` can't hold 0.1, 0.2 or 0.3 exactly, so `0.1 + 0.2` and `0.3` are two slightly different numbers. xUnit prints both with 17 digits to show the difference: even `0.3` becomes `0.29999999999999999`. Compare doubles to a number of decimal places, `Assert.Equal(0.3, 0.1 + 0.2, 10)`, which passes. The tests of `FretFrequency` don't need it: the method rounds with `Math.Round`, and the rounded result is the same `double` as the literal `164.81` in the test.
- **Exception types.** `Assert.Throws<ArgumentException>` wants exactly that type. `ParseFret` throws [`ArgumentOutOfRangeException`](https://learn.microsoft.com/dotnet/api/system.argumentoutofrangeexception), a class derived from `ArgumentException` (lesson 8): the message shows both types, and the exception that was thrown. Name the exact type, or use `Assert.ThrowsAny<ArgumentException>`, which accepts derived types too.
- **Swapped arguments.** The expected value comes first. Here the literal is second, so the message calls the method's result, 164.81, "Expected", and the wrong value, 164.8, "Actual": the opposite of the truth. The compiler warned before the tests ran: [xUnit2000](https://xunit.net/xunit.analyzers/rules/xUnit2000) comes from an *analyzer*, a check that the `xunit` package adds to the compiler.
- **A wrong row.** The test name shows the arguments of the failed row, and the arrows point to the first item that differs. This time the code is right and the test is wrong: E moved up one semitone is F.

The fixes of the first two are in `Fretboard.Tests`; the last two are exercise 3:

```csharp
    // Assert.ThrowsAny also accepts a type derived from it: ArgumentOutOfRangeException is an ArgumentException
    [Fact]
    public void ParseFret_RefusesANegativeFret()
    {
        Assert.ThrowsAny<ArgumentException>(() => Guitar.ParseFret("-1"));
    }

    // Two doubles are compared here to 10 decimal places, not bit for bit
    [Fact]
    public void Doubles_CompareWithAPrecision()
    {
        Assert.Equal(0.3, 0.1 + 0.2, 10);
    }
```

## One object per test

xUnit creates a new object of the test class for each test. A field doesn't carry anything from one test to the next:

```csharp
// xUnit creates a new object of the test class for each test, so a field starts from 0 in every test
public class InstanceTests
{
    int _count;

    [Fact]
    public void FirstTest()
    {
        _count++;
        Assert.Equal(1, _count);
    }

    [Fact]
    public void SecondTest()
    {
        _count++;
        Assert.Equal(1, _count);
    }
}
```

Both tests pass: each one sees `_count` at 0. A test can't rely on another one having run before it, and it doesn't need to: each test arranges its own data.

## Test what the library makes public

The test project is another program: it calls the library from outside, and sees only its `public` members. A member without `public` is private to its class, as in this snippet, where the top-level statements play the part of the test:

```csharp
// A test calls the library from outside: it sees only what the library makes public
Console.WriteLine(Guitar.Chromatic.Length);

static class Guitar
{
    static readonly string[] Chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
}
```

```text
l11_private.cs(2,26): error CS0122: 'Guitar.Chromatic' is inaccessible due to its protection level
```

[CS0122](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/cs0122) says the member exists but can't be reached from here. From a test project, a member marked `internal`, visible only inside its own project, gives another error: in a scratch pair of projects, the compiler answered [CS0117](https://learn.microsoft.com/dotnet/csharp/misc/cs0117), `'Lab' does not contain a definition for 'Secret'`, as if the method didn't exist. The attribute [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute) can open a library's internal members to its tests. Testing through the public methods is usually better: the tests then check what the other projects use, and they still pass when you rewrite the inside of a method.

## In Guitar Alchemist

At commit `5c3a52a`, Guitar Alchemist has 18 test projects. 16 project files reference [NUnit](https://docs.nunit.org/), another test framework, and 3 reference xUnit. The ideas are the same, with other names: `[Test]` for `[Fact]`, `[TestCase]` for `[InlineData]`, `Assert.That(actual, Is.EqualTo(expected))` for `Assert.Equal(expected, actual)`, and `[Ignore("reason")]` to skip a test.

**The tests of the YAML files.** Lesson 9 found that three of the four YAML files of GA's music knowledge services don't load, which is now [GA issue #797](https://github.com/GuitarAlchemist/ga/issues/797). GA has tests for these services, in [`MusicalKnowledgeServiceTests.cs`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs). Three of its eight tests are skipped with [`[Ignore("Configuration files not loaded in test environment")]`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs#L108-L110), and of the five others, three only check that a count is [greater than zero](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs#L28-L33) or that a list isn't empty. A [probe](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner/ga-probes/knowledge-tests) compiled this file unchanged, with GA's services and the same NUnit packages, and ran it: 5 tests passed, 3 were skipped, none failed. The search for "jazz" passed with one result: the default chord progression that the loader keeps after its failure. A test that checks "more than zero" can't see a loader that fails and returns one default item; a test that checks the real number of items, or that loading reports no error, could.

**A setup that never runs.** The same test project has a class, [`TestEnvironment`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/TestBootstrap/TestEnvironment.cs#L1-L14), marked `[SetUpFixture]`, which moves the current directory to the root of the repository. Its comment says it "ensures configuration-backed services can locate their YAML/JSON inputs during tests": lesson 10's problem, solved for the tests. But NUnit runs a setup fixture only before the tests [of its own namespace](https://docs.nunit.org/articles/nunit/writing-tests/attributes/setupfixture.html), and this one is alone in `GA.Business.Core.Tests.TestBootstrap`. A test of the probe, placed next to the YAML tests, saw the current directory still in its `bin` folder, and `GA_TEST_MODE`, which the setup sets, not set. The YAML files are found anyway, next to the program, where the build copies them.

**Tests that aren't compiled.** The project file [removes 35 files from the build](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/GA.Business.Core.Tests.csproj#L39-L75), under the comment "Exclude test files with missing service implementations". Five of the names no longer match a file; the other 30 files hold 333 lines that start with `[Test]` or `[TestCase]`. A test that isn't compiled never fails, and `dotnet test` doesn't mention it.

The [QA table of the journal](../journal/#qa) records these measurements.

## Exercises

The solutions are tests of `Fretboard.Tests`, in `ExerciseTests.cs`: `dotnet test` runs them with the others.

### Exercise 1 — transpose down

Write a test that checks that `Guitar.Transpose(["A", "C", "E"], -3)` returns F#, A and C#.

<details>
<summary>Solution</summary>

```csharp
    // Exercise 1: transpose down
    [Fact]
    public void Transpose_MovesEachNoteDown()
    {
        List<string> result = Guitar.Transpose(["A", "C", "E"], -3);

        Assert.Equal(["F#", "A", "C#"], result);
    }
```

`Assert.Equal` compares two lists item by item; the collection expression `["F#", "A", "C#"]` becomes the type of the other argument.

</details>

### Exercise 2 — the edges of `ParseFret`

Bugs hide at the edges. Test that `ParseFret` accepts `"0"` and `"24"`, refuses `"-1"` and `"25"` with `ArgumentOutOfRangeException`, and refuses `"seven"` with `FormatException`. Use theories where a test has several rows.

<details>
<summary>Solution</summary>

```csharp
    // Exercise 2: the edges of ParseFret
    [Theory]
    [InlineData("0", 0)]
    [InlineData("24", 24)]
    public void ParseFret_AcceptsTheFirstAndLastFret(string text, int expected)
    {
        Assert.Equal(expected, Guitar.ParseFret(text));
    }

    [Theory]
    [InlineData("-1")]
    [InlineData("25")]
    public void ParseFret_RefusesTheFretsJustOutside(string text)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Guitar.ParseFret(text));
    }

    [Fact]
    public void ParseFret_RefusesAWord()
    {
        Assert.Throws<FormatException>(() => Guitar.ParseFret("seven"));
    }
```

Each edge has a value just inside, 0 and 24, and a value just outside, -1 and 25. If someone writes `ThrowIfGreaterThan(fret, 23)` by mistake, the row `"24"` fails.

</details>

### Exercise 3 — fix the two wrong tests

Two tests of `Pitfalls.Tests` expect the wrong value: `Equal_WithTheArgumentsSwapped` and the row `"E", 1, "F#"` of `Transpose_OneNote`. Write correct versions of both.

<details>
<summary>Solution</summary>

```csharp
    // Exercise 3: the two pitfalls whose expected value was wrong, fixed
    [Fact]
    public void Equal_WithTheExpectedValueFirst()
    {
        Assert.Equal(164.81, Guitar.FretFrequency(110.0, 7));
    }

    [Theory]
    [InlineData("C", 2, "D")]
    [InlineData("B", 1, "C")]
    [InlineData("E", 1, "F")]
    public void Transpose_OneNote(string note, int semitones, string expected)
    {
        Assert.Equal([expected], Guitar.Transpose([note], semitones));
    }
```

The first fix puts the literal first and uses the right value, 164.81: the warning xUnit2000 goes away too. In the second, the code was right: the fix is in the test.

</details>

### Exercise 4 — a test that reads a file

Write a test that reads `data/ga-projects.csv` with `Project.Parse` and checks that it holds 12 projects and 632 source files, `.cs` and `.fs` together. Two things from lesson 10 matter here: the file must be copied next to the compiled tests, and a test shouldn't depend on the current directory.

<details>
<summary>Solution</summary>

A [`None` item](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#none) in `Fretboard.Tests.csproj` copies the file into the output folder, under `data`:

```xml
<ItemGroup>
  <None Include="..\..\data\ga-projects.csv" Link="data\ga-projects.csv" CopyToOutputDirectory="PreserveNewest" />
</ItemGroup>
```

The test builds the path from [`AppContext.BaseDirectory`](https://learn.microsoft.com/dotnet/api/system.appcontext.basedirectory), the folder of the compiled tests:

```csharp
    // Exercise 4: a test that reads data/ga-projects.csv, copied next to the tests by Fretboard.Tests.csproj
    [Fact]
    public void GaProjects_HoldSixHundredThirtyTwoSourceFiles()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "data", "ga-projects.csv");

        List<Project> projects = File.ReadLines(path).Skip(1).Select(Project.Parse).ToList();

        Assert.Equal(12, projects.Count);
        Assert.Equal(632, projects.Sum(p => p.SourceFiles));
    }
```

`Select(Project.Parse)` gives LINQ the method itself, as `Count(IsFSharp)` in lesson 9. 632 is lesson 10's 557 C# files and 75 F# files.

</details>

## Check your understanding

- A unit test calls one method with known arguments and compares its result with the expected value. A test framework runs all the tests, counts the failures and sets the exit code.
- Tests go in a test project that references a class library: `dotnet new classlib`, `dotnet new xunit`, `dotnet add reference`. `dotnet test` builds both and runs the tests.
- `[Fact]` marks a test; `[Theory]` with `[InlineData]` runs the same test once per row, and each row counts as a test.
- `Assert.Equal(expected, actual)`: the expected value first. Compare doubles to a number of decimal places. `Assert.Throws<T>` wants the exact type; `Assert.ThrowsAny<T>` accepts derived types.
- A failing test says that two values differ: check whether the code or the test is wrong before you change either.
- xUnit creates a new object for each test, and doesn't promise an order. A test project sees only the library's public members.
- A test that is skipped, that isn't compiled or that only checks "more than zero" can pass while the code is broken.

Next: [a small project](../#outline), a solution with this library, a console app and these tests, a NuGet package, and a first look at `async`.

## Sources

- xUnit: [getting started with xUnit.net v2](https://xunit.net/docs/getting-started/v2/netcore/cmdline), [analyzer rule xUnit2000](https://xunit.net/xunit.analyzers/rules/xUnit2000)
- .NET: [unit testing C# with xUnit](https://learn.microsoft.com/dotnet/core/testing/unit-testing-csharp-with-xunit), [unit testing best practices](https://learn.microsoft.com/dotnet/core/testing/unit-testing-best-practices), [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test), [`dotnet new` templates](https://learn.microsoft.com/dotnet/core/tools/dotnet-new-sdk-templates), [`dotnet add reference`](https://learn.microsoft.com/dotnet/core/tools/dotnet-reference-add), [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute), [`ArgumentOutOfRangeException`](https://learn.microsoft.com/dotnet/api/system.argumentoutofrangeexception), [`AppContext.BaseDirectory`](https://learn.microsoft.com/dotnet/api/system.appcontext.basedirectory), [MSBuild items](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#none)
- NUnit: [documentation](https://docs.nunit.org/), [`SetUpFixture`](https://docs.nunit.org/articles/nunit/writing-tests/attributes/setupfixture.html)
- Compiler errors [CS0122](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/cs0122), [CS0117](https://learn.microsoft.com/dotnet/csharp/misc/cs0117)
