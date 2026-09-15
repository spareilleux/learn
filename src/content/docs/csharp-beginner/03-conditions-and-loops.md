---
title: 3. Conditions and loops
description: Make decisions with if, else and switch, repeat work with while, for and foreach, stop or skip with break and continue, and follow a program line by line in a debugger.
sidebar:
  order: 3
---

Code: the examples [`examples/l03_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/examples), the rejected snippets [`compile_fail/l03_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/compile_fail) and the solutions [`exercises/l03_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises).

Until now, programs ran every line once, from top to bottom. This lesson changes that: a **condition** runs some lines only in some cases, and a **loop** runs lines several times.

## Comparisons and `bool`

A comparison asks a question whose answer is a `bool`: `true` or `false`.

```csharp
int fret = 12;

// A comparison gives a bool: true or false
Console.WriteLine(fret == 12);
Console.WriteLine(fret != 12);
Console.WriteLine(fret > 5 && fret < 10);   // && : both must be true
Console.WriteLine(fret < 1 || fret > 11);   // || : at least one must be true
Console.WriteLine(!(fret > 5));             // !  : the opposite
```

```text
True
False
False
True
False
```

| Operator | Meaning | | Operator | Meaning |
|---|---|---|---|---|
| `==` | equal to | | `&&` | and |
| `!=` | not equal to | | `\|\|` | or |
| `<`, `<=` | less than, or equal | | `!` | not |
| `>`, `>=` | greater than, or equal | | | |

Be careful with `==`, two equal signs, which compares, and `=`, one sign, which assigns. The [comparison operators](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/comparison-operators) and [boolean logical operators](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/boolean-logical-operators) pages have the complete rules. *And* and *or* stop as soon as they know the answer: in `fret > 5 && fret < 10`, when the first comparison is `false`, the second one isn't even computed.

## `if`, `else if`, `else`

[`if`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#the-if-statement) runs a **block**, the lines between braces, only when its condition is `true`:

```csharp
// if runs a block only when the condition is true
if (fret == 0)
{
    Console.WriteLine("Open string");
}
else if (fret == 12)
{
    Console.WriteLine("One octave above the open string");
}
else
{
    Console.WriteLine("Somewhere else on the neck");
}

// Strings are compared by their content
string tuning = "E A D G B E";
if (tuning == "E A D G B E")
{
    Console.WriteLine("Standard tuning");
}

// A variable declared inside a block only exists in that block
if (fret > 7)
{
    int distance = fret - 7;
    Console.WriteLine($"{distance} frets above the 7th");
}
```

```text
One octave above the open string
Standard tuning
5 frets above the 7th
```

The conditions are checked in order, and only the first block whose condition is `true` runs. `else` catches every other case. Both `else if` and `else` are optional.

The condition must be a `bool`. Two classic mistakes are rejected. Writing one equal sign instead of two:

```csharp
int fret = 5;
if (fret = 12)
{
    Console.WriteLine("Octave");
}
```

```text
l03_assign_in_if.cs(2,5): error CS0029: Cannot implicitly convert type 'int' to 'bool'
l03_assign_in_if.cs(1,5): warning CS0219: The variable 'fret' is assigned but its value is never used
```

`fret = 12` is an assignment, whose value is the `int` 12, not a `bool`. In some other languages this compiles and silently changes `fret`. A string is not a condition either:

```csharp
string answer = "yes";
if (answer)
```

```text
l03_string_condition.cs(2,5): error CS0029: Cannot implicitly convert type 'string' to 'bool'
```

Write `if (answer == "yes")`.

### Scope

A variable declared inside a block exists only in that block, and in the blocks inside it. That area is its **scope**:

```csharp
int fret = 9;
if (fret > 7)
{
    int distance = fret - 7;
}
Console.WriteLine(distance);
```

```text
l03_out_of_scope.cs(6,19): error CS0103: The name 'distance' does not exist in the current context
```

To use `distance` after the `if`, declare it before the `if`.

## `switch`

When a value is compared with a list of possible values, a [`switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#the-switch-statement) is easier to read than a chain of `else if`.

```csharp
int semitone = 7;

// The switch statement: one case per value, each case ends with break
switch (semitone)
{
    case 0:
        Console.WriteLine("Unison");
        break;
    case 7:
        Console.WriteLine("Perfect fifth");
        break;
    case 12:
        Console.WriteLine("Octave");
        break;
    default:
        Console.WriteLine("Another interval");
        break;
}
```

```text
Perfect fifth
```

The **switch statement** jumps to the `case` that matches, or to `default` when none does. Each section must end with `break` (or `return`, [lesson 4](../04-methods-arrays-lists/)). In C and JavaScript, a missing `break` lets the program fall into the next case; C# refuses it:

```csharp
switch (semitone)
{
    case 7:
        Console.WriteLine("Perfect fifth");
    case 12:
        Console.WriteLine("Octave");
        break;
}
```

```text
l03_fall_through.cs(4,5): error CS0163: Control cannot fall through from one case label ('case 7:') to another
```

### The `switch` expression

Often, each case only computes a value. The [**switch expression**](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) says it in fewer lines: the value, `switch`, then one *arm* per case, `pattern => result`, separated by commas.

```csharp
// The switch expression computes a value: one arm per pattern, _ matches everything else
string name = semitone switch
{
    0 => "C",
    1 => "C#",
    2 => "D",
    3 => "D#",
    4 => "E",
    5 => "F",
    6 => "F#",
    7 => "G",
    8 => "G#",
    9 => "A",
    10 => "A#",
    11 => "B",
    _ => "not a semitone between 0 and 11",
};
Console.WriteLine($"Semitone {semitone} above C is {name}");

// Patterns can compare: the first arm that matches wins
foreach (int fret in new[] { 0, 3, 7, 12, 17, 30 })
{
    string zone = fret switch
    {
        0 => "open string",
        < 5 => "first position",
        < 12 => "middle of the neck",
        12 => "octave",
        <= 24 => "high on the neck",
        _ => "no such fret",
    };
    Console.WriteLine($"Fret {fret}: {zone}");
}
```

```text
Semitone 7 above C is G
Fret 0: open string
Fret 3: first position
Fret 7: middle of the neck
Fret 12: octave
Fret 17: high on the neck
Fret 30: no such fret
```

- The arms are tried **from top to bottom**, and the first one that matches gives the value. Fret 3 matches the arm `< 5`, less than 5, before the arm less than 12 is tried.
- A *pattern* can be a value, such as `12`, or a comparison, such as `< 5`, less than 5. The [patterns page](https://learn.microsoft.com/dotnet/csharp/fundamentals/functional/pattern-matching) shows the others: `and`, `or`, `not`, and many more.
- `_`, the *discard*, matches everything: it's the `default` of a switch expression.
- The loop `foreach (int fret in new[] { … })` runs the block once for each number; loops come [next](#loops).

Without `_`, a value that no arm matches has nothing to produce. The compiler warns, and the program fails when it happens:

```csharp
int stringNumber = 7;

// No arm for 7, and no _ arm: the compiler warns, and the program fails at run time
string open = stringNumber switch
{
    1 => "E4",
    2 => "B3",
    3 => "G3",
    4 => "D3",
    5 => "A2",
    6 => "E2",
};
Console.WriteLine(open);
```

```text
l03_switch_warning.cs(4,28): warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern '0' is not covered.
Unhandled exception. System.Runtime.CompilerServices.SwitchExpressionException: Non-exhaustive switch expression failed to match its input.
Unmatched value was 7.
   at <PrivateImplementationDetails>.ThrowSwitchExpressionException(Object unmatchedValue)
   at Program.<Main>$(String[] args) in C:\Users\spare\source\repos\learn\code\csharp-beginner\examples\l03_switch_warning.cs:line 4
```

A **warning**, unlike an error, doesn't stop the build: the program runs, and here it stops with an **exception**, an error that happens while the program runs. The lines starting with `at` are the *stack trace*: where the program was. The last one points to line 4 of the file. [Lesson 8](../#outline) is about exceptions.

Two things to know about warnings. First, read them: this one announced the crash. Second, `dotnet run` shows them only when it compiles; if you run the same unchanged file again, it doesn't compile, and the warning isn't printed again. `dotnet clean l03_switch_warning.cs` forgets the compiled program, and the next run shows the warning again. The course's `check.sh` does that before every run.

## Loops

A loop repeats a block. C# has four [iteration statements](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/iteration-statements):

```csharp
// while: repeats as long as the condition is true
int countdown = 3;
while (countdown > 0)
{
    Console.WriteLine($"{countdown}...");
    countdown--;                   // same as countdown = countdown - 1
}
Console.WriteLine("Play!");

// for: start; condition; step
for (int fret = 0; fret <= 12; fret += 3)
{
    Console.Write($"{fret} ");
}
Console.WriteLine();

// foreach: every item of a collection, here every character of a string
foreach (char letter in "EADGBE")
{
    Console.Write($"[{letter}]");
}
Console.WriteLine();

// break leaves the loop, continue goes to the next turn
for (int i = 1; i <= 10; i++)
{
    if (i % 2 == 0)
    {
        continue;                  // skip even numbers
    }
    if (i > 7)
    {
        break;                     // stop after 7
    }
    Console.Write($"{i} ");
}
Console.WriteLine();

// do-while: the block runs at least once, the condition is checked after
int tries = 0;
do
{
    tries++;
    Console.WriteLine($"Try {tries}");
} while (tries < 2);
```

```text
3...
2...
1...
Play!
0 3 6 9 12 
[E][A][D][G][B][E]
1 3 5 7 
Try 1
Try 2
```

| Loop | Use it when | Checks the condition |
|---|---|---|
| `while (condition)` | you don't know in advance how many turns | before each turn |
| `do { … } while (condition);` | the block must run at least once | after each turn |
| `for (start; condition; step)` | you count: from 0 to 12, by 3 | before each turn |
| `foreach (type item in collection)` | you visit every item of a collection | — |

- `countdown--` subtracts 1, `i++` adds 1, and `fret += 3` adds 3: short forms of `countdown = countdown - 1` and `fret = fret + 3`.
- A `for` has three parts separated by semicolons: what to do **once** at the start (`int fret = 0`), the condition checked **before each turn** (`fret <= 12`), and what to do **after each turn** (`fret += 3`). Its variable `fret` exists only inside the loop.
- `foreach` takes each item in turn. A string is a collection of `char`; arrays and lists, in [lesson 4](../04-methods-arrays-lists/), are collections too.
- `continue` skips the rest of the block and starts the next turn; `break` leaves the loop at once.

A `while` whose condition never becomes `false` runs forever. If a program seems stuck, press <kbd>Ctrl</kbd>+<kbd>C</kbd> in the terminal to stop it.

### Loops inside loops: the fretboard

A loop can contain another loop. For each string, the inner loop visits each fret. This program prints the notes of the first five frets of a guitar in standard tuning, the `Tuning.Default` of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs#L20-L23):

```csharp
// The first five frets of a guitar in standard tuning (E2 A2 D3 G3 B3 E4, Tuning.Default in GA).
// Each note is a number of semitones: C is 0, C# is 1, ... B is 11, and the next C is 12 again.
for (int stringNumber = 6; stringNumber >= 1; stringNumber--)
{
    // Semitones of the open string above C
    int open = stringNumber switch
    {
        6 => 4,    // E
        5 => 9,    // A
        4 => 2,    // D
        3 => 7,    // G
        2 => 11,   // B
        _ => 4,    // E (string 1)
    };

    Console.Write($"String {stringNumber}:");
    for (int fret = 0; fret <= 5; fret++)
    {
        int semitone = (open + fret) % 12;     // % 12 folds 12 back to 0: the octave
        string name = semitone switch
        {
            0 => "C", 1 => "C#", 2 => "D", 3 => "D#", 4 => "E", 5 => "F",
            6 => "F#", 7 => "G", 8 => "G#", 9 => "A", 10 => "A#", _ => "B",
        };
        Console.Write($" {name,-2}");
    }
    Console.WriteLine();
}
```

```text
String 6: E  F  F# G  G# A 
String 5: A  A# B  C  C# D 
String 4: D  D# E  F  F# G 
String 3: G  G# A  A# B  C 
String 2: B  C  C# D  D# E 
String 1: E  F  F# G  G# A 
```

Guitarists number the strings from the highest, string 1, to the lowest, string 6; the outer loop counts down so that string 6 is printed first. On the B string, fret 1 is `(11 + 1) % 12`, which is `0`: C. The `%` operator makes the numbers go round like the hours on a clock, which is exactly how note names repeat every octave. The [music theory course](../../music-theory-ga/01-notes-and-the-fretboard/) goes much further with the same idea.

### Reading until the answer is right

A `while` loop can keep asking for input until it gets what it needs:

```csharp
// Guess the fret: the loop reads answers until one is right
int secret = 7;
int tries = 0;
bool found = false;

while (!found)
{
    Console.Write("Which fret? ");
    string? line = Console.ReadLine();
    if (line == null)
    {
        Console.WriteLine("No more input.");
        break;
    }
    if (!int.TryParse(line, out int guess))
    {
        Console.WriteLine($"\"{line}\" is not a number.");
        continue;
    }

    tries++;
    if (guess < secret)
    {
        Console.WriteLine("Higher.");
    }
    else if (guess > secret)
    {
        Console.WriteLine("Lower.");
    }
    else
    {
        found = true;
        Console.WriteLine($"Found in {tries} tries.");
    }
}
```

Typing `12`, `five`, `5` and `7`:

```text
Which fret? 12
Lower.
Which fret? five
"five" is not a number.
Which fret? 5
Higher.
Which fret? 7
Found in 3 tries.
```

`continue` goes back to the question without counting the bad answer as a try. When the input ends, `ReadLine` returns `null` and `break` leaves the loop: without it, a program whose input comes from a file, as in the CI, would ask forever. On a keyboard, <kbd>Ctrl</kbd>+<kbd>Z</kbd> then <kbd>Enter</kbd> on Windows, or <kbd>Ctrl</kbd>+<kbd>D</kbd> on Linux and macOS, ends the input.

## Finding a mistake with the debugger

When a program gives a wrong result, you need to see what it does, line by line. The simplest way is to add `Console.WriteLine` calls that print the variables, run again, and remove them afterwards. It works everywhere.

A **debugger** does better: it pauses the program on a line you choose, a **breakpoint**, shows the value of every variable, and lets you run one line at a time. The three editors of [lesson 1](../01-first-program/#choose-an-editor) have one:

| Action | Visual Studio Code | Visual Studio | Rider |
|---|---|---|---|
| Set or remove a breakpoint | <kbd>F9</kbd>, or click left of the line number | <kbd>F9</kbd> | click left of the line |
| Start with the debugger | <kbd>F5</kbd> | <kbd>F5</kbd> | the bug icon |
| Run the next line | <kbd>F10</kbd> (step over) | <kbd>F10</kbd> | step over |
| Go into a method called on this line | <kbd>F11</kbd> (step into) | <kbd>F11</kbd> | step into |
| Continue to the next breakpoint | <kbd>F5</kbd> | <kbd>F5</kbd> | resume |

Try it on the fretboard program: put a breakpoint on the line `int semitone = (open + fret) % 12;`, start with the debugger, and look at `stringNumber`, `open` and `fret` in the *Variables* or *Locals* panel. Each time you continue, the program stops again at the next fret. You can also type an expression such as `(open + fret) % 12` in the *Watch* panel to see its value.

The keys in this table are the defaults of each editor on Windows and Linux; the Rider keymap on macOS differs. See [debugging in VS Code](https://code.visualstudio.com/docs/csharp/debugging), [the Visual Studio debugger for beginners](https://learn.microsoft.com/visualstudio/debugger/debugger-feature-tour), and [debugging in Rider](https://www.jetbrains.com/help/rider/Debugging_Code.html). *To verify*: I haven't yet debugged these examples in each of the three editors, neither as single-file apps nor inside a project made with [`dotnet new console`](../01-first-program/#a-project).

## Key takeaways

- A comparison gives a `bool`; *and* (`&&`), *or* (`||`) and *not* (`!`) combine them. Two equal signs compare, one equal sign assigns.
- `if`, `else if` and `else` run the first block whose condition is `true`; a variable declared in a block exists only in that block.
- A `switch` statement needs a `break` at the end of each case; a `switch` expression computes a value, tries its arms from top to bottom, and should end with `_`.
- `while` repeats while a condition is true, `for` counts, `foreach` visits every item of a collection; `break` leaves the loop and `continue` skips to the next turn.
- A warning doesn't stop the build, but often announces a problem; an unhandled exception stops the program and prints where it happened.
- A debugger pauses on breakpoints and shows the variables, one line at a time.

## Exercises

1. Print the numbers from 1 to 15 on one line, but print `Fizz` instead of multiples of 3, `Buzz` instead of multiples of 5, and `FizzBuzz` for multiples of both. Hint: a switch expression can look at two values at once, written `(a, b) switch`.

<details>
<summary>Solution</summary>

[`exercises/l03_ex_fizzbuzz.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l03_ex_fizzbuzz.cs):

```csharp
// Exercise 1: FizzBuzz from 1 to 15, with a switch expression on two remainders
for (int i = 1; i <= 15; i++)
{
    string text = (i % 3, i % 5) switch
    {
        (0, 0) => "FizzBuzz",
        (0, _) => "Fizz",
        (_, 0) => "Buzz",
        _ => i.ToString(),
    };
    Console.Write($"{text} ");
}
Console.WriteLine();
```

```text
1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz 
```

`(i % 3, i % 5)` groups the two remainders in a *tuple*, and each arm checks both. `(0, _)` means "divisible by 3, whatever the second remainder". The order matters: `(0, 0)` must come first, or 15 would print `Fizz`. With `if`, you'd write `if (i % 3 == 0 && i % 5 == 0)` first, then `else if (i % 3 == 0)`, and so on.

</details>

2. Ask for a note name (`C`, `C#`, … `B`) and print the 13 notes of the chromatic scale from that note up to the same note one octave higher. Print a message if the note is unknown.

<details>
<summary>Solution</summary>

[`exercises/l03_ex_chromatic.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l03_ex_chromatic.cs):

```csharp
// Exercise 2: read a note name and print the 13 notes of the chromatic scale from it, up to its octave
Console.Write("Starting note? ");
string? input = Console.ReadLine();

int start = input switch
{
    "C" => 0, "C#" => 1, "D" => 2, "D#" => 3, "E" => 4, "F" => 5,
    "F#" => 6, "G" => 7, "G#" => 8, "A" => 9, "A#" => 10, "B" => 11,
    _ => -1,
};

if (start == -1)
{
    Console.WriteLine($"Unknown note: {input}");
}
else
{
    for (int step = 0; step <= 12; step++)
    {
        string name = ((start + step) % 12) switch
        {
            0 => "C", 1 => "C#", 2 => "D", 3 => "D#", 4 => "E", 5 => "F",
            6 => "F#", 7 => "G", 8 => "G#", 9 => "A", 10 => "A#", _ => "B",
        };
        Console.Write($"{name} ");
    }
    Console.WriteLine();
}
```

With `A`:

```text
Starting note? A
A A# B C C# D D# E F F# G G# A 
```

The first switch expression turns the name into a number, with `-1` meaning "unknown": a switch expression works on strings too. The loop runs 13 times, `step` from 0 to 12, and `% 12` brings the numbers above 11 back to the start. Typing the same note names twice isn't great: [lesson 4](../04-methods-arrays-lists/) stores them once, in an array.

</details>

3. Read practice times in minutes, one per line, until an empty line or the end of the input. Skip lines that aren't whole numbers or that are negative, saying so. Then print the number of valid days, the total in minutes, and the total in hours and minutes.

<details>
<summary>Solution</summary>

[`exercises/l03_ex_total.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l03_ex_total.cs):

```csharp
// Exercise 3: add up the practice minutes typed one per line; an empty line ends the input
int total = 0;
int days = 0;
while (true)
{
    string? line = Console.ReadLine();
    if (line == null || line == "")
    {
        break;
    }
    if (!int.TryParse(line, out int minutes) || minutes < 0)
    {
        Console.WriteLine($"Skipped: {line}");
        continue;
    }
    total += minutes;
    days++;
}
Console.WriteLine($"{days} days, {total} minutes, {total / 60} h {total % 60} min");
```

With the lines `30`, `45`, `forty`, `-5`, `60`, an empty line, then `90` ([`input/l03_ex_total.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l03_ex_total.txt)), the output is:

```text
Skipped: forty
Skipped: -5
3 days, 135 minutes, 2 h 15 min
```

`while (true)` never stops by itself: the `break` inside decides. The `90` after the empty line is never read. In `!int.TryParse(line, out int minutes) || minutes < 0`, the `||` computes `minutes < 0` only when `TryParse` succeeded, so `minutes` always holds the parsed value when it's compared.

</details>

## Sources

- [Selection statements: `if`, `else` and `switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements), [the `switch` expression](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [patterns](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns)
- [Iteration statements: `for`, `foreach`, `do` and `while`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/iteration-statements), [jump statements: `break` and `continue`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/jump-statements)
- [Comparison operators](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/comparison-operators), [boolean logical operators](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/boolean-logical-operators)
- [Compiler warning CS8509](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/pattern-matching-warnings), [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception)
- [Debugging C# in VS Code](https://code.visualstudio.com/docs/csharp/debugging), [Visual Studio debugger feature tour](https://learn.microsoft.com/visualstudio/debugger/debugger-feature-tour), [Rider: debug code](https://www.jetbrains.com/help/rider/Debugging_Code.html)
