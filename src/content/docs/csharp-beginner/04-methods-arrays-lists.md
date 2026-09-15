---
title: 4. Methods, arrays and lists
description: Split a program into methods with parameters and return values, store many values in arrays and List<T>, and take a first look at null, the value that means "nothing".
sidebar:
  order: 4
---

Code: the examples [`examples/l04_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/examples), the rejected snippets [`compile_fail/l04_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/compile_fail) and the solutions [`exercises/l04_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises).

The programs of lesson 3 repeated the same twelve note names in several places. This lesson removes that repetition twice: a **method** gives a name to a piece of work, so you write it once and call it many times, and an **array** or a **list** holds many values under one name.

## Methods

You've been calling methods since lesson 1: `Console.WriteLine`, `Math.Pow`, `int.TryParse`. Now you write your own.

```csharp
// Calling the methods declared below
PrintTitle("Methods");
Console.WriteLine(Square(12));
Console.WriteLine(FretFrequency(110.0, 7));
Console.WriteLine(FretFrequency(82.41, 5));
Console.WriteLine(Describe(0));
Console.WriteLine(Describe(12));
Console.WriteLine(Repeat("la"));                 // default value for times
Console.WriteLine(Repeat("la", 3));
Console.WriteLine(Repeat(times: 2, text: "do")); // named arguments, in any order

// A method with no result: its return type is void
void PrintTitle(string title)
{
    Console.WriteLine($"== {title} ==");
}

// A method that returns an int
int Square(int x)
{
    return x * x;
}

// A method with two parameters, rounded to two decimals
double FretFrequency(double openString, int fret)
{
    double frequency = openString * Math.Pow(2, fret / 12.0);
    return Math.Round(frequency, 2);
}

// return leaves the method at once
string Describe(int fret)
{
    if (fret == 0)
    {
        return "open string";
    }
    return $"fret {fret}";
}

// An optional parameter, and a body written as one expression with =>
string Repeat(string text, int times = 2) => string.Concat(Enumerable.Repeat(text, times));
```

```text
== Methods ==
144
164.81
110
open string
fret 12
lala
lalala
dodo
```

A method declaration has four parts:

```text
double  FretFrequency  (double openString, int fret)  { … return …; }
  │          │                    │                         │
return     name              parameters                   body
 type
```

- The **return type** is the type of the result: `int`, `double`, `string`… or `void` when the method returns nothing and only does something, like printing.
- The **name** starts with a capital letter, by convention, and usually with a verb: `PrintTitle`, `Describe`.
- The **parameters** are variables that receive the values given by the caller, the *arguments*. `FretFrequency(110.0, 7)` puts `110.0` in `openString` and `7` in `fret`, in that order.
- The **body** does the work. [`return`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/jump-statements#the-return-statement) gives the result back to the caller and leaves the method at once: in `Describe(0)`, the second `return` is never reached.

Fret 5 of the low E string, at 82.41 Hz, is an A at 110 Hz: the note of the open A string. That's how guitarists tune the fifth string from the sixth.

Three conveniences:

- A parameter with a **default value**, `int times = 2`, can be left out: `Repeat("la")` uses 2.
- **Named arguments**, `times: 2, text: "do"`, say which parameter gets which value, in any order.
- When the body is a single expression, `=>` replaces the braces and the `return`: that's an [expression-bodied member](https://learn.microsoft.com/dotnet/csharp/programming-guide/statements-expressions-operators/expression-bodied-members). `Enumerable.Repeat(text, times)` makes a sequence of `times` copies of `text`, and `string.Concat` joins them.

In a file with top-level statements, the methods can be declared after the lines that call them, as here. The C# documentation calls them [local functions](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/local-functions): they belong to the program's top-level code. [Lesson 5](../#outline) puts methods inside classes, the usual place in larger programs.

### What the compiler checks

The compiler checks every call against the declaration. A missing argument:

```csharp
Console.WriteLine(FretFrequency(110.0));

double FretFrequency(double openString, int fret)
```

```text
l04_missing_argument.cs(1,19): error CS7036: There is no argument given that corresponds to the required parameter 'fret' of 'FretFrequency(double, int)'
```

An argument of the wrong type:

```csharp
Console.WriteLine(Square("12"));

int Square(int x)
```

```text
l04_wrong_argument_type.cs(1,26): error CS1503: Argument 1: cannot convert from 'string' to 'int'
```

Using the result of a `void` method:

```csharp
string title = PrintTitle("Methods");

void PrintTitle(string text)
```

```text
l04_void_result.cs(1,16): error CS0029: Cannot implicitly convert type 'void' to 'string'
```

And a method that may end without returning a value. Here, a negative `fret` goes past both `return` statements:

```csharp
string Describe(int fret)
{
    if (fret == 0)
    {
        return "open string";
    }
    else if (fret > 0)
    {
        return $"fret {fret}";
    }
}
```

```text
l04_not_all_paths.cs(3,8): error CS0161: 'Describe(int)': not all code paths return a value
```

The compiler doesn't try to guess that `fret` is never negative: every path through the method must end with a `return` or an exception.

### Arguments are copies

```csharp
int fret = 5;
AddOctave(fret);
Console.WriteLine($"After AddOctave: {fret}");       // unchanged: the method got a copy

int[] frets = [0, 2, 2, 1, 0, 0];                    // an E major chord
AddOctaveToAll(frets);
Console.WriteLine($"After AddOctaveToAll: {string.Join(" ", frets)}");  // changed: the method got the same array

void AddOctave(int value)
{
    value += 12;
    Console.WriteLine($"Inside AddOctave: {value}");
}

void AddOctaveToAll(int[] values)
{
    for (int i = 0; i < values.Length; i++)
    {
        values[i] += 12;
    }
}
```

```text
Inside AddOctave: 17
After AddOctave: 5
After AddOctaveToAll: 12 14 14 13 12 12
```

A parameter receives a **copy** of the argument. Changing `value` inside `AddOctave` doesn't change `fret`. But an array variable doesn't hold the array itself: it holds a *reference*, the address where the array lives. The copy is a copy of the address, so `values` and `frets` point to the same array, and the method changes it. The E major chord moved up an octave, to the 12th fret. Types that behave like `int` are **value types**; types that behave like arrays are **reference types**. [Lesson 6](../#outline) comes back to the difference.

## Arrays

An **array** holds a fixed number of values of the same type, one after the other, each at a numbered position, its **index**.

```csharp
// An array: a fixed number of values of the same type
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];

Console.WriteLine(strings.Length);
Console.WriteLine(strings[0]);          // indexes start at 0
Console.WriteLine(strings[5]);          // the last index is Length - 1
Console.WriteLine(strings[^1]);         // ^1: the first from the end
Console.WriteLine(string.Join(", ", strings[1..3]));   // a range: indexes 1 and 2

strings[0] = "D2";                      // drop D tuning: the values can change
Console.WriteLine(string.Join(" ", strings));

// new int[4]: four ints, all 0 to start with
int[] minutes = new int[4];
minutes[1] = 30;
Console.WriteLine(string.Join(" ", minutes));

// Loop over the values
int[] practice = [30, 45, 0, 60, 20];
int total = 0;
foreach (int m in practice)
{
    total += m;
}
Console.WriteLine($"Total: {total} minutes over {practice.Length} days");

// Sort changes the array itself
Array.Sort(practice);
Console.WriteLine(string.Join(" ", practice));
```

```text
6
E2
E4
E4
A2, D3
D2 A2 D3 G3 B3 E4
0 30 0 0
Total: 155 minutes over 5 days
0 20 30 45 60
```

- `string[]`, said *string array*, is the type "array of strings". `["E2", "A2", …]` is a [collection expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/collection-expressions): the values between square brackets. `new int[4]` makes an array of four `int`, all `0`.
- **Indexes start at 0**: a six-item array goes from `strings[0]` to `strings[5]`. `strings[^1]`, with a caret, counts from the end, and `strings[1..3]` is a new array with the items from index 1 up to, but not including, index 3. See [indices and ranges](https://learn.microsoft.com/dotnet/csharp/tutorials/ranges-indexes).
- `Length` gives the number of items. It can't change: an array has no `Add`.
- [`string.Join`](https://learn.microsoft.com/dotnet/api/system.string.join) builds one string from all the items, with a separator between them, and [`Array.Sort`](https://learn.microsoft.com/dotnet/api/system.array.sort) sorts the array in place.

Going past the end is the most common mistake with arrays. The compiler can't see it, because the index is only known while the program runs:

```csharp
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];
for (int i = 0; i <= strings.Length; i++)     // <= goes one step too far
{
    Console.WriteLine($"{i}: {strings[i]}");
}
```

```text
0: E2
1: A2
2: D3
3: G3
4: B3
5: E4
Unhandled exception. System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Program.<Main>$(String[] args) in C:\Users\spare\source\repos\learn\code\csharp-beginner\examples\l04_index_out_of_range.cs:line 4
```

With *less than or equal*, `<=`, the loop also runs with `i` equal to 6, and there is no `strings[6]`. The loop condition of an array is almost always *i less than the length of the array*, `i < array.Length`, or better, a `foreach`, which can't go too far.

And the size of an array is fixed:

```csharp
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];
strings.Add("B1");
```

```text
l04_array_fixed_size.cs(2,9): error CS1061: 'string[]' does not contain a definition for 'Add' and no accessible extension method 'Add' accepting a first argument of type 'string[]' could be found (are you missing a using directive or an assembly reference?)
```

For a collection that grows, use a list.

## Lists

A [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1) is like an array that can grow and shrink. The `T` stands for the type of its items, written between angle brackets: `List<string>` is a list of strings, `List<int>` a list of integers.

```csharp
// A List<string> grows and shrinks; the type between < > is the type of its items
List<string> chord = ["C", "E", "G"];
Console.WriteLine($"{chord.Count} notes: {string.Join(" ", chord)}");

chord.Add("B");                         // Cmaj7
Console.WriteLine(string.Join(" ", chord));

chord.Insert(1, "D");                   // at index 1, the others move up
Console.WriteLine(string.Join(" ", chord));

chord.Remove("D");                      // removes the first "D" it finds
Console.WriteLine(string.Join(" ", chord));

Console.WriteLine(chord.Contains("G"));
Console.WriteLine(chord.IndexOf("B"));
Console.WriteLine(chord.IndexOf("F#"));  // -1: not in the list

chord[3] = "Bb";                         // C7
Console.WriteLine(string.Join(" ", chord));

chord.RemoveAt(chord.Count - 1);
Console.WriteLine(string.Join(" ", chord));

// An empty list, filled in a loop
List<int> octaves = [];
for (int midi = 12; midi <= 60; midi += 12)
{
    octaves.Add(midi);
}
Console.WriteLine($"The C notes in MIDI numbers: {string.Join(", ", octaves)}");
```

```text
3 notes: C E G
C E G B
C D E G B
C E G B
True
3
-1
C E G Bb
C E G
The C notes in MIDI numbers: 12, 24, 36, 48, 60
```

| | Array `string[]` | List `List<string>` |
|---|---|---|
| Size | fixed when created | grows and shrinks |
| Number of items | `Length` | `Count` |
| Read and change an item | `a[i]`, `a[i] = x` | `list[i]`, `list[i] = x` |
| Add, insert, remove | no | `Add`, `Insert`, `Remove`, `RemoveAt` |
| Search | `Array.IndexOf(a, x)` | `list.IndexOf(x)`, `list.Contains(x)` |
| Use it when | the number of items is known and doesn't change | items come and go |

A C major chord is C, E and G. Adding B makes a *major seventh* chord, Cmaj7; with B♭ (written `Bb`) it's a *dominant seventh*, C7. `IndexOf` returns `-1` when the item isn't there.

The list checks the type of what you add:

```csharp
List<int> frets = [0, 2, 2];
frets.Add("1");
```

```text
l04_list_wrong_type.cs(2,11): error CS1503: Argument 1: cannot convert from 'string' to 'int'
```

## Methods, arrays and lists together: Guitar Alchemist's projects

Guitar Alchemist is split into more than a hundred projects. The [LadybugDB course](../../ladybugdb/05-csharp/) extracted their list to [`projects.csv`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/ladybugdb/data/ga/projects.csv), from GA's commit `a26a7893`. Twelve of the projects of its `Common` folder, copied by hand into two arrays, are enough to practise:

```csharp
// Twelve projects of the Common folder of GuitarAlchemist/ga, and their languages,
// copied from code/ladybugdb/data/ga/projects.csv
string[] names =
[
    "GA.Core", "GA.Domain.Core", "GA.Business.Config", "GA.Business.Core",
    "GA.Business.DSL", "GA.Business.AI", "GA.Business.ML", "GA.Business.ProbabilisticGrammar",
    "GA.Business.Core.Generated", "GA.Infrastructure", "GA.Presentation", "GA.Testing.Semantic",
];
string[] languages = ["C#", "C#", "F#", "C#", "F#", "C#", "C#", "F#", "F#", "C#", "C#", "C#"];

Console.WriteLine($"{CountStartingWith(names, "GA.Business.")} projects start with GA.Business.");

List<string> fsharp = ProjectsIn(names, languages, "F#");
Console.WriteLine($"{fsharp.Count} F# projects:");
foreach (string name in fsharp)
{
    Console.WriteLine($"  {name}");
}

Console.WriteLine($"Longest name: {Longest(names)}");

int CountStartingWith(string[] values, string prefix)
{
    int count = 0;
    foreach (string value in values)
    {
        if (value.StartsWith(prefix))
        {
            count++;
        }
    }
    return count;
}

// The two arrays go together: names[i] is written in languages[i]
List<string> ProjectsIn(string[] projectNames, string[] projectLanguages, string language)
{
    List<string> result = [];
    for (int i = 0; i < projectNames.Length; i++)
    {
        if (projectLanguages[i] == language)
        {
            result.Add(projectNames[i]);
        }
    }
    return result;
}

string Longest(string[] values)
{
    string longest = values[0];
    foreach (string value in values)
    {
        if (value.Length > longest.Length)
        {
            longest = value;
        }
    }
    return longest;
}
```

```text
7 projects start with GA.Business.
4 F# projects:
  GA.Business.Config
  GA.Business.DSL
  GA.Business.ProbabilisticGrammar
  GA.Business.Core.Generated
Longest name: GA.Business.ProbabilisticGrammar
```

Each method does one thing and has a name that says what: count, filter, find the longest. `ProjectsIn` uses a `for` instead of a `foreach` because it needs the index `i` to read the same position in both arrays. Two arrays that must stay in step are fragile: add a name and forget its language, and every language after it is wrong. [Lesson 5](../#outline) replaces them with one list of projects, each with a name and a language. [Lesson 10](../#outline) reads the whole CSV file instead of copying it by hand.

## `null`: no value at all

Some variables need a way to say "there is nothing here": no capo on the guitar, no more lines to read. C# uses [`null`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/null) for that. A type followed by a question mark, such as `string?`, a string or null, accepts `null`; a plain `string` isn't supposed to hold it.

```csharp
// string? : a string, or null (no string at all)
string? capo = null;
Console.WriteLine(capo == null);
Console.WriteLine(capo is null);

// ?. gives null instead of reading a member of null; ?? gives a value to use instead of null
Console.WriteLine(capo?.Length);
Console.WriteLine(capo ?? "no capo");
Console.WriteLine(capo?.Length ?? 0);

capo ??= "fret 2";                       // assigns only if capo is null
Console.WriteLine(capo);
Console.WriteLine(capo.Length);          // the compiler knows capo isn't null here

// Console.ReadLine returns null when there is nothing left to read
List<string> lines = [];
string? line;
while ((line = Console.ReadLine()) != null)
{
    if (!string.IsNullOrWhiteSpace(line))
    {
        lines.Add(line.Trim());
    }
}
Console.WriteLine($"{lines.Count} non-empty lines: {string.Join(" | ", lines)}");
```

With the lines `Am`, an empty line, `  F  `, `C`, a line of spaces, and `G` as input ([`input/l04_null.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l04_null.txt)):

```text
True
True

no capo
0
fret 2
6
4 non-empty lines: Am | F | C | G
```

| Write | Means |
|---|---|
| `x == null`, `x is null` | is `x` null? |
| `x?.Length` | `null` if `x` is null, else `x.Length` |
| `x ?? other` | `x`, or `other` if `x` is null |
| `x ??= value` | put `value` in `x` only if `x` is null |

The third line of the output is empty: `capo?.Length` is `null`, and `WriteLine` prints nothing for it. In the loop, `(line = Console.ReadLine()) != null` reads a line, stores it in `line`, then compares it with `null`: the loop stops at the end of the input. [`string.IsNullOrWhiteSpace`](https://learn.microsoft.com/dotnet/api/system.string.isnullorwhitespace) is `true` for `null`, an empty string, or only spaces, and `Trim` removes the spaces around the text.

### The compiler watches for `null`

Reading a member of `null`, such as its `Length`, is impossible: there is no string to measure. The compiler follows where `null` can come from and **warns** before it happens. This feature is called [nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references), turned on by the `<Nullable>enable</Nullable>` you saw in the project file of lesson 1, and by default in file-based apps.

```csharp
string? FindTuning(string name)
{
    if (name == "standard")
    {
        return "E A D G B E";
    }
    return null;
}

string? tuning = FindTuning("drop D");
Console.WriteLine(tuning.Length);   // warning CS8602, then a NullReferenceException at run time
```

```text
l04_null_warning.cs(11,19): warning CS8602: Dereference of a possibly null reference.
Unhandled exception. System.NullReferenceException: Object reference not set to an instance of an object.
   at Program.<Main>$(String[] args) in C:\Users\spare\source\repos\learn\code\csharp-beginner\examples\l04_null_warning.cs:line 11
```

It's only a warning, so the program runs, and crashes on line 11. The fix is to handle the `null` case, for example `tuning?.Length ?? 0`, or an `if (tuning is null)` before using it. In the first example, `capo.Length` after `capo ??= "fret 2"` gets no warning: the compiler understood that `capo` can't be `null` any more. [Lesson 8](../#outline) covers exceptions and null safety in depth.

## Key takeaways

- A method has a return type (`void` for none), a name, parameters and a body; `return` gives back the result and leaves the method.
- The compiler checks the number and the types of the arguments, and that every path of a non-`void` method returns a value.
- Arguments are copies: a method can't change an `int` variable of the caller, but it can change the items of an array it receives, because the copy is a reference to the same array.
- An array has a fixed size, `Length`, and indexes from `0` to `Length - 1`; going past the end throws `IndexOutOfRangeException`.
- `List<T>` grows and shrinks with `Add`, `Insert`, `Remove` and `RemoveAt`, and has a `Count`.
- `string?` can be `null`; `?.`, `??` and `??=` handle it, and the compiler warns when you may use a `null`.

## Exercises

1. Write a method `Average` that takes an `int[]` and returns its average as a `double`, or `null` when the array is empty. Call it on a week of practice times, `30, 45, 0, 60, 20, 0, 90`, and on an empty array.

<details>
<summary>Solution</summary>

[`exercises/l04_ex_average.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l04_ex_average.cs):

```csharp
// Exercise 1: the average of an array, or null when the array is empty
int[] week = [30, 45, 0, 60, 20, 0, 90];
int[] nothing = [];

Console.WriteLine(Average(week));
Console.WriteLine(Average(nothing) ?? -1);
Console.WriteLine(Average(nothing) is null ? "no practice recorded" : "some practice");

double? Average(int[] values)
{
    if (values.Length == 0)
    {
        return null;
    }
    int total = 0;
    foreach (int value in values)
    {
        total += value;
    }
    return (double)total / values.Length;
}
```

```text
35
-1
no practice recorded
```

`double?` is a `double` that can also be `null`: the `?` works on value types too. `(double)total / values.Length` converts before dividing; `total / values.Length` would be an integer division. Dividing by zero is avoided by the `return null` at the start. The last line uses the *conditional operator* `condition ? a : b`, a short `if`/`else` that gives a value.

</details>

2. Store the twelve note names (`C`, `C#`, … `B`) in an array, once. Write a method `Transpose` that takes a `List<string>` of note names and a number of semitones, positive or negative, and returns a **new** list with every note moved. Check that the original list doesn't change.

<details>
<summary>Solution</summary>

[`exercises/l04_ex_transpose.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l04_ex_transpose.cs):

```csharp
// Exercise 2: transpose a chord, a list of note names, by a number of semitones
string[] chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

List<string> cMajor = ["C", "E", "G"];
Console.WriteLine(string.Join(" ", Transpose(cMajor, 2)));
Console.WriteLine(string.Join(" ", Transpose(cMajor, 7)));
Console.WriteLine(string.Join(" ", Transpose(["A", "C", "E"], -3)));
Console.WriteLine(string.Join(" ", cMajor));        // unchanged: Transpose returns a new list

List<string> Transpose(List<string> notes, int semitones)
{
    List<string> result = [];
    foreach (string note in notes)
    {
        int index = Array.IndexOf(chromatic, note);
        int moved = ((index + semitones) % 12 + 12) % 12;   // + 12 keeps negative steps in 0..11
        result.Add(chromatic[moved]);
    }
    return result;
}
```

```text
D F# A
G B D
F# A C#
C E G
```

C major moved up 2 semitones is D major, up 7 is G major; A minor moved down 3 is F♯ minor. In C#, `%` keeps the sign of the left number: moving C (index 0) down 3 semitones gives `(0 - 3) % 12`, which is `-3`, not a valid index. Adding 12 then taking `% 12` again always gives an index from 0 to 11: here, 9, the A.

`Transpose` reads `chromatic`, a variable of the top-level code, without receiving it as a parameter: a local function can. It's convenient here, but it hides what the method depends on. Lesson 5 shows how a class holds such shared data. A note that isn't in the array, such as `Bb`, gives `-1` from `Array.IndexOf` and a wrong result: improving that is a good extra exercise.

</details>

3. Read all the lines of the input until its end, store them in a list, then print the number of lines and the longest one, or `(no lines)` if there were none. Write the search for the longest line as a method that returns `string?`.

<details>
<summary>Solution</summary>

[`exercises/l04_ex_longest_line.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l04_ex_longest_line.cs):

```csharp
// Exercise 3: read every line until the end of the input, then print the count and the longest line
List<string> lines = [];
string? line;
while ((line = Console.ReadLine()) != null)
{
    lines.Add(line);
}

string? longest = Longest(lines);
Console.WriteLine($"{lines.Count} lines");
Console.WriteLine($"Longest: {longest ?? "(no lines)"}");

string? Longest(List<string> values)
{
    string? best = null;
    foreach (string value in values)
    {
        if (best == null || value.Length > best.Length)
        {
            best = value;
        }
    }
    return best;
}
```

With four tunings as input ([`input/l04_ex_longest_line.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l04_ex_longest_line.txt)):

```text
4 lines
Longest: Standard: E2 A2 D3 G3 B3 E4
```

`best` starts at `null`, meaning "no line seen yet". `best == null || value.Length > best.Length` never reads `best.Length` when `best` is `null`, because `||` stops at the first `true`; the compiler knows it, and doesn't warn. With an empty input, the method returns `null`, and `??` prints `(no lines)`.

</details>

## Sources

- [Methods](https://learn.microsoft.com/dotnet/csharp/methods), [local functions](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/local-functions), [method parameters](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/method-parameters), [named and optional arguments](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments)
- [Arrays](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/arrays), [collection expressions](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/collection-expressions), [indices and ranges](https://learn.microsoft.com/dotnet/csharp/tutorials/ranges-indexes)
- [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1), [collections](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/collections)
- [Nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references), [member access operators `?.`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/member-access-operators#null-conditional-operators--and-), [`??` and `??=`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/null-coalescing-operator)
- [Value types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/value-types) and [reference types](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/reference-types)
