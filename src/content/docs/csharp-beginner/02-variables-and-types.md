---
title: 2. Variables, types and input
description: Store values in variables of type int, double, decimal, string and bool, convert between types, format text with interpolation, and read what the user types with Console.ReadLine.
sidebar:
  order: 2
---

Code: the examples [`examples/l02_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/examples), the rejected snippets [`compile_fail/l02_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/compile_fail) and the solutions [`exercises/l02_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises). Run an example from the `code/csharp-beginner` folder with `dotnet run examples/l02_variables.cs`.

## Variables

A **variable** is a named box that holds a value. In C#, every box also has a **type**, fixed when you create it: the kind of values it accepts.

```csharp
// A variable is a named box that holds a value of one type
int strings = 6;
string tuning = "E A D G B E";
double scaleLength = 64.8;     // centimetres, a common guitar scale length
bool isAcoustic = true;
char lowest = 'E';

Console.WriteLine(strings);
Console.WriteLine(tuning);
Console.WriteLine(scaleLength);
Console.WriteLine(isAcoustic);
Console.WriteLine(lowest);

// The value can change; the type can't
strings = 7;
Console.WriteLine(strings);

// var: the compiler infers the type from the value
var frets = 22;                // int
var name = "Stratocaster";     // string
Console.WriteLine(frets.GetType());
Console.WriteLine(name.GetType());

// const: a value that never changes
const int SemitonesPerOctave = 12;
Console.WriteLine(SemitonesPerOctave * 2);
```

```text
6
E A D G B E
64.8
True
E
7
System.Int32
System.String
24
```

`int strings = 6;` is a **declaration**: the type, the name, `=`, then the first value. It reads "make a box named `strings` for an `int`, and put 6 in it". Later, `strings = 7;` is an **assignment**: it replaces the value in the box. The `=` sign means "put into", not "is equal to".

Names follow a few rules: letters, digits and `_`, not starting with a digit, and not a keyword of the language such as `int` or `if`. By convention, a local variable starts with a lower-case letter and each following word with a capital: `scaleLength`. That style is called *camelCase*; the [C# identifier naming rules](https://learn.microsoft.com/dotnet/csharp/fundamentals/coding-style/identifier-names) list the others.

## The basic types

| Type | Holds | Examples | Range and precision |
|---|---|---|---|
| `int` | whole numbers | `6`, `-12`, `2_000_000` | about -2.1 to 2.1 billion |
| `long` | larger whole numbers | `9_000_000_000` | about ±9.2 billion billion |
| `double` | numbers with decimals, approximate | `64.8`, `1e-3` | 15 to 17 significant digits |
| `decimal` | numbers with decimals, exact | `19.99m` | 28 to 29 significant digits |
| `bool` | true or false | `true`, `false` | |
| `char` | one character | `'E'`, `'#'` | between single quotes |
| `string` | text | `"E A D G B E"`, `""` | between double quotes |

The [integral numeric types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/integral-numeric-types) and [floating-point numeric types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types) pages list the others, such as `byte`, `short` or `float`. You'll rarely need them as a beginner. The `_` in `2_000_000` only makes the number easier to read.

`GetType()` printed `System.Int32` and `System.String`: `int` is the C# keyword for the .NET type `Int32`, a 32-bit integer, and `string` is the keyword for `String`. Both names mean exactly the same type.

### `var`

With [`var`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/declarations#implicitly-typed-local-variables), the compiler reads the value and gives the variable its type: `var frets = 22;` makes an `int`. The variable still has one type for its whole life. `var` saves typing when the type is obvious from the value; write the type when it helps the reader.

### `const`

A [`const`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/const) is a value fixed when you write the program: 12 semitones per octave will never change. Its name starts with a capital letter.

### What the compiler refuses

Each of these small programs is rejected. The type of a variable can't change, so a string doesn't fit in an `int` box:

```csharp
var frets = 22;
frets = "twenty-two";
```

```text
l02_type_change.cs(2,9): error CS0029: Cannot implicitly convert type 'string' to 'int'
```

A variable must have a value before it's read:

```csharp
int strings;
Console.WriteLine(strings);
```

```text
l02_unassigned.cs(2,19): error CS0165: Use of unassigned local variable 'strings'
```

`var` needs a value to find the type:

```csharp
var tuning;
tuning = "E A D G B E";
```

```text
l02_var_without_value.cs(1,5): error CS0818: Implicitly-typed variables must be initialized
```

And a constant stays constant:

```csharp
const int SemitonesPerOctave = 12;
SemitonesPerOctave = 13;
```

```text
l02_const_change.cs(2,1): error CS0131: The left-hand side of an assignment must be a variable, property or indexer
```

## Numbers and arithmetic

`+`, `-`, `*` and `/` work as in mathematics, and `%` gives the remainder of a division. The type of the numbers changes the result:

```csharp
// Integers: the division drops the decimals
Console.WriteLine(7 / 2);
Console.WriteLine(7 % 2);      // the remainder
Console.WriteLine(7 / 2.0);    // one double in the operation: the result is a double

// Each integer type has a range; int goes from about -2.1 billion to 2.1 billion
Console.WriteLine(int.MaxValue);
int big = int.MaxValue;
big = big + 1;                 // wraps around without an error
Console.WriteLine(big);
Console.WriteLine(long.MaxValue);

// double is fast but approximate: 0.1 has no exact binary form
Console.WriteLine(0.1 + 0.2);
Console.WriteLine(0.1 + 0.2 == 0.3);

// decimal is exact for decimal fractions: use it for money
Console.WriteLine(0.1m + 0.2m);
Console.WriteLine(0.1m + 0.2m == 0.3m);
decimal price = 19.99m;
Console.WriteLine(price * 3);
```

```text
3
1
3.5
2147483647
-2147483648
9223372036854775807
0.30000000000000004
False
0.3
True
59.97
```

Three surprises for a beginner:

1. **`7 / 2` is `3`.** When both numbers are integers, the division is an integer division: the decimals are dropped, not rounded. `7 % 2` gives what's left, `1`. If one of the numbers is a `double`, such as `2.0`, the result is a `double`: `3.5`.
2. **An `int` that goes past its maximum wraps around** to the most negative value, without any error. The compiler only catches it when the whole calculation is made of constants:

   ```csharp
   int big = int.MaxValue + 1;
   ```

   ```text
   l02_overflow_constant.cs(1,11): error CS0220: The operation overflows at compile time in checked mode
   ```

   The [`checked`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked) keyword makes the program fail instead of wrapping, when the numbers are only known while it runs.
3. **`0.1 + 0.2` isn't exactly `0.3` with `double`.** A `double` stores numbers in binary, where 0.1 has no exact form, just as 1/3 has no exact decimal form. For money, use `decimal`, where `0.1m + 0.2m` is exactly `0.3`. The `m` after the number makes it a `decimal`; without it, the compiler refuses:

   ```csharp
   decimal price = 19.99;
   ```

   ```text
   l02_decimal_literal.cs(1,17): error CS0664: Literal of type double cannot be implicitly converted to type 'decimal'; use an 'M' suffix to create a literal of this type
   ```

### A real calculation: the frequency of a fret

Each fret of a guitar raises the note by a semitone, which multiplies the frequency of the string by the twelfth root of 2, about 1.0595. Twelve frets double the frequency: one octave. [`Math.Pow(x, y)`](https://learn.microsoft.com/dotnet/api/system.math.pow) computes x to the power y:

```csharp
// The open A string vibrates at 110 Hz. Each fret raises the note by a semitone,
// which multiplies the frequency by the 12th root of 2.
double openA = 110.0;
int fret = 7;

double wrong = openA * Math.Pow(2, fret / 12);     // 7 / 12 is an integer division: 0
double right = openA * Math.Pow(2, fret / 12.0);   // 7 / 12.0 is 0.5833...

Console.WriteLine($"Fret {fret}, wrong: {wrong} Hz");
Console.WriteLine($"Fret {fret}, right: {right} Hz");
Console.WriteLine($"Rounded: {right:F2} Hz");
Console.WriteLine($"Fret 12: {openA * Math.Pow(2, 12 / 12.0)} Hz");
```

```text
Fret 7, wrong: 110 Hz
Fret 7, right: 164.81377845643496 Hz
Rounded: 164.81 Hz
Fret 12: 220 Hz
```

`fret / 12` is `0`, because both are `int`, and 2 to the power 0 is 1: the "wrong" frequency is the open string. This mistake gives no error and no warning, only a wrong result. Writing `12.0` makes it a `double` division. Fret 7 of the A string is an E, at about 164.81 Hz.

## Conversions

Some conversions happen by themselves; others must be asked for.

```csharp
// Implicit conversion: no information can be lost
int semitones = 7;
double asDouble = semitones;
Console.WriteLine(asDouble);

// Explicit conversion (a cast): the decimals are cut, not rounded
double hertz = 164.81;
int truncated = (int)hertz;
Console.WriteLine(truncated);

// Rounding: by default, halfway values go to the nearest even number
Console.WriteLine(Math.Round(2.5));
Console.WriteLine(Math.Round(3.5));
Console.WriteLine(Math.Round(2.5, MidpointRounding.AwayFromZero));

// From text to number
int frets = int.Parse("22");
Console.WriteLine(frets + 2);

// TryParse doesn't fail on bad text: it returns false
bool ok = int.TryParse("twenty-two", out int parsed);
Console.WriteLine($"{ok} {parsed}");
ok = int.TryParse("24", out parsed);
Console.WriteLine($"{ok} {parsed}");

// From number to text
string text = frets.ToString();
Console.WriteLine(text + "2");   // + on strings joins them
Console.WriteLine(frets + 2);    // + on numbers adds them
```

```text
7
164
2
4
3
24
False 0
True 24
222
24
```

### Between number types

Every `int` fits in a `double`, so the compiler converts for you: that's an **implicit conversion**. The other way, a `double` can hold decimals that an `int` can't, so the compiler refuses to convert silently:

```csharp
double hertz = 164.81;
int rounded = hertz;
```

```text
l02_double_to_int.cs(2,15): error CS0266: Cannot implicitly convert type 'double' to 'int'. An explicit conversion exists (are you missing a cast?)
```

The message suggests a **cast**: the type in parentheses before the value, `(int)hertz`. It tells the compiler "I know I may lose something". A cast to `int` cuts the decimals: 164.81 becomes 164.

To round instead, use [`Math.Round`](https://learn.microsoft.com/dotnet/api/system.math.round). By default it rounds a value exactly halfway to the nearest **even** number: `2.5` gives `2` and `3.5` gives `4`. This is called banker's rounding, and it avoids pushing every halfway value up. `MidpointRounding.AwayFromZero` gives the rounding taught at school.

### From text to number

A string that contains digits is still text: `"22"` can't go into an `int` box.

```csharp
int frets = "22";
```

```text
l02_string_to_int.cs(1,13): error CS0029: Cannot implicitly convert type 'string' to 'int'
```

[`int.Parse`](https://learn.microsoft.com/dotnet/api/system.int32.parse) reads the number in a string, and stops the program with an error if the text isn't a number. [`int.TryParse`](https://learn.microsoft.com/dotnet/api/system.int32.tryparse) never stops the program: it returns `true` or `false`, and gives the number through its `out` parameter. `out int parsed` declares the variable `parsed` right there, in the call. When the text isn't a number, `parsed` is `0` and the result is `false`. Use `TryParse` for anything a person types: people make typing mistakes.

`double.Parse`, `decimal.Parse` and their `TryParse` versions work the same way for the other types.

### From number to text

`ToString()` turns any value into text. Then `+` means something else: between two strings, `+` **joins** them. `"22" + "2"` is `"222"`, while `22 + 2` is `24`. When one side is a string and the other a number, C# turns the number into text and joins them, from left to right: that's why `"Frets played: " + 3 + 2 + 1` gives `Frets played: 321`.

## Strings and interpolation

Joining strings with `+` quickly gets hard to read. **String interpolation** puts values right inside the text: a `$` before the opening quote, and each expression between braces.

```csharp
string note = "A";
int octave = 4;
double frequency = 440;

// Interpolation: $ before the quotes, expressions between braces
Console.WriteLine($"{note}{octave} vibrates at {frequency} Hz");
Console.WriteLine($"One octave higher: {frequency * 2} Hz");

// Format and alignment: {value,width:format}
Console.WriteLine($"[{note,-5}] [{octave,5}] [{frequency,8:F1}]");
Console.WriteLine($"{1234567.891:N2}");

// A few string methods
string model = "Les Paul";
Console.WriteLine(model.Length);
Console.WriteLine(model.ToUpper());
Console.WriteLine(model.Contains("Paul"));
Console.WriteLine(model.Replace("Paul", "Standard"));
Console.WriteLine(model[0]);          // the first character: a char

// Special characters
Console.WriteLine("Tab:\tafter\nNew line, and a quote: \"");
Console.WriteLine(@"C:\Users\ada\music");     // verbatim: \ is just a character
Console.WriteLine("""
    A raw string literal keeps "quotes"
    and line breaks as they are.
    """);
```

```text
A4 vibrates at 440 Hz
One octave higher: 880 Hz
[A    ] [    4] [   440.0]
1,234,567.89
8
LES PAUL
True
Les Standard
L
Tab:	after
New line, and a quote: "
C:\Users\ada\music
A raw string literal keeps "quotes"
and line breaks as they are.
```

- Inside the braces, any expression works: `frequency * 2` is computed, then inserted.
- After a comma, a **width**: `{octave,5}` fills 5 characters, aligned to the right; a negative width, `{note,-5}`, aligns to the left. After a colon, a **format**: `F1` shows one decimal, `N2` two decimals with thousands separators. The [standard numeric format strings](https://learn.microsoft.com/dotnet/standard/base-types/standard-numeric-format-strings) list them all.
- A string knows its `Length`, and has methods such as `ToUpper`, `Contains` or `Replace`. None of them changes `model`: they return a new string. `model[0]` is the character at position 0, the first one: positions start at 0.
- A backslash starts an **escape sequence**: `\t` is a tab, `\n` a new line, `\"` a quote inside the string. With `@` before the string, a backslash is just a backslash, handy for Windows paths. Between three quotes, a [raw string literal](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/reference-types#string-literals) keeps quotes and line breaks as they are, and removes the indentation of the closing `"""`.

The [string interpolation tutorial](https://learn.microsoft.com/dotnet/csharp/tutorials/string-interpolation) goes further.

## Reading what the user types

[`Console.ReadLine()`](https://learn.microsoft.com/dotnet/api/system.console.readline) waits until the user types a line and presses <kbd>Enter</kbd>, then returns that line as a string, without the <kbd>Enter</kbd>.

```csharp
Console.Write("What is your name? ");
string? name = Console.ReadLine();

Console.Write("How many years have you played the guitar? ");
string? answer = Console.ReadLine();

if (int.TryParse(answer, out int years))
{
    Console.WriteLine($"Hello {name}, {years} years is {years * 12} months of practice.");
}
else
{
    Console.WriteLine($"Hello {name}, \"{answer}\" is not a whole number.");
}
```

When I type `Ada` and `3`, the terminal shows:

```text
> dotnet run examples/l02_input.cs
What is your name? Ada
How many years have you played the guitar? 3
Hello Ada, 3 years is 36 months of practice.
```

The CI can't type: `check.sh` sends the lines of [`input/l02_input.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l02_input.txt) to the program instead, with a redirection of its input:

```text
dotnet run examples/l02_input.cs < input/l02_input.txt
```

The typed text is then not shown, and the expected output is one line: `What is your name? How many years have you played the guitar? Hello Ada, 3 years is 36 months of practice.`

Two new things in this program:

- The type is `string?`, with a question mark: `ReadLine` returns a string, or `null` when there is nothing left to read. [Lesson 4](../04-methods-arrays-lists/#null-no-value-at-all) explains `null`. `int.TryParse` accepts a `null` and returns `false`.
- `if` and `else` choose between two blocks, depending on the `bool` that `TryParse` returns. [Lesson 3](../03-conditions-and-loops/) is about them.

## Numbers and the language of the user

`1.5` is one and a half in English, but a French or Spanish speaker writes `1,5`. .NET follows the **culture** of the computer, its language and region settings, when it prints and reads numbers:

```csharp
using System.Globalization;

// The format of numbers depends on the culture: the language and region of the user
double frequency = 1234.5;
foreach (string name in new[] { "en-US", "fr-FR", "es-ES" })
{
    CultureInfo.CurrentCulture = new CultureInfo(name);
    bool ok = double.TryParse("1.5", out double parsed);
    Console.WriteLine($"{name}: {frequency:F1}  \"1.5\" read as {parsed} ({ok})");
}

// The invariant culture gives the same result everywhere: use it for files and data
CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine(double.Parse("1.5"));
```

```text
en-US: 1234.5  "1.5" read as 1.5 (True)
fr-FR: 1234,5  "1.5" read as 0 (False)
es-ES: 1234,5  "1.5" read as 15 (True)
1.5
```

With the French culture, `"1.5"` isn't a number. With the Spanish culture, it's worse: the dot separates thousands in Spanish, so `"1.5"` is read as **15**, without any error. The outputs of this course were captured with an English culture; on a French or Spanish computer, your decimal numbers may print with a comma. For data that programs exchange, such as files, use [`CultureInfo.InvariantCulture`](https://learn.microsoft.com/dotnet/api/system.globalization.cultureinfo.invariantculture), which is the same on every computer. The [globalization guide](https://learn.microsoft.com/dotnet/core/extensions/globalization) has the details.

`using System.Globalization;` at the top makes the names of that *namespace*, a group of related types, usable without their long prefix. `Console` and `Math` need no `using`: file-based apps and new projects turn on [implicit usings](https://learn.microsoft.com/dotnet/core/project-sdk/overview#implicit-using-directives) for the most common namespaces.

## Key takeaways

- A variable has a name, a type and a value; `=` puts a value in it. The type never changes, and `var` only asks the compiler to find it.
- `int` and `long` hold whole numbers, `double` approximate decimals, `decimal` exact decimals (for money), `bool` true or false, `char` one character, `string` text.
- Dividing two integers drops the decimals; write `12.0` to get a `double` division.
- Widening conversions are automatic; narrowing ones need a cast, such as `(int)hertz`, which cuts the decimals.
- `int.TryParse` turns text into a number without stopping the program on bad input.
- An interpolated string, `$"…{value,width:format}…"`, builds text from values; `Console.ReadLine()` reads a line typed by the user.
- The culture changes how numbers print and parse: use the invariant culture for data.

## Exercises

1. A song lasts 3725 seconds. Using only integers, `/` and `%`, print its length as `1 h 02 min 05 s`. The format `D2` prints an integer with at least two digits.

<details>
<summary>Solution</summary>

[`exercises/l02_ex_duration.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l02_ex_duration.cs):

```csharp
// Exercise 1: a song of 3725 seconds, in hours, minutes and seconds
int total = 3725;
int hours = total / 3600;
int minutes = total % 3600 / 60;
int seconds = total % 60;
Console.WriteLine($"{hours} h {minutes:D2} min {seconds:D2} s");
```

```text
1 h 02 min 05 s
```

`total / 3600` counts the whole hours. `total % 3600` is what's left after them, 125 seconds, and `/ 60` counts its whole minutes. `%` and `/` have the same priority and are computed from left to right, so `total % 3600 / 60` is `(total % 3600) / 60`.

</details>

2. Ask the user for the price of a set of strings and a number of sets. Print the subtotal, a 15% tax rounded to the cent, and the total, with two decimals. If either answer isn't valid, print a message instead. Which type do you use for the price?

<details>
<summary>Solution</summary>

`decimal`, since it's money. [`exercises/l02_ex_order.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l02_ex_order.cs):

```csharp
// Exercise 2: read a price and a quantity, print the total with 15% tax
Console.Write("Price of a set of strings? ");
string? priceText = Console.ReadLine();
Console.Write("How many sets? ");
string? quantityText = Console.ReadLine();

bool priceOk = decimal.TryParse(priceText, out decimal price);
bool quantityOk = int.TryParse(quantityText, out int quantity);

if (priceOk && quantityOk)
{
    decimal subtotal = price * quantity;
    decimal tax = Math.Round(subtotal * 0.15m, 2);
    Console.WriteLine($"Subtotal: {subtotal:F2}");
    Console.WriteLine($"Tax: {tax:F2}");
    Console.WriteLine($"Total: {subtotal + tax:F2}");
}
else
{
    Console.WriteLine("Please type a price such as 12.49 and a whole number.");
}
```

With `12.49` and `3`:

```text
Price of a set of strings? 12.49
How many sets? 3
Subtotal: 37.47
Tax: 5.62
Total: 43.09
```

`&&` means "and": both conversions must succeed. `Math.Round(…, 2)` rounds to two decimals; 15% of 37.47 is 5.6205, rounded to 5.62. On a computer with a French or Spanish culture, type the price with a comma: `12,49`.

</details>

3. Fret 7 is a *fifth* above the open string. In the tuning of old instruments, a fifth multiplied the frequency by exactly 3/2. How far is the modern ratio, 2 to the power 7/12, from 3/2? Print both with five decimals, and the difference as a percentage of 3/2.

<details>
<summary>Solution</summary>

[`exercises/l02_ex_fifth.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l02_ex_fifth.cs):

```csharp
// Exercise 3: fret 7 is a fifth above the open string. How close is 2^(7/12) to 3/2?
double tempered = Math.Pow(2, 7 / 12.0);
double pure = 3.0 / 2.0;
Console.WriteLine($"Equal temperament: {tempered:F5}");
Console.WriteLine($"Pure fifth:        {pure:F5}");
Console.WriteLine($"Difference:        {(pure - tempered) / pure * 100:F3} %");
```

```text
Equal temperament: 1.49831
Pure fifth:        1.50000
Difference:        0.113 %
```

Two traps: `7 / 12` would be `0`, and `3 / 2` would be `1`. Writing `12.0` and `3.0` makes both divisions `double` divisions. The modern tuning, *equal temperament*, makes every semitone the same size, so that a guitar plays in tune in every key, at the cost of fifths about 0.1% too narrow.

</details>

## Sources

- [Types (C# fundamentals)](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/), [built-in types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/built-in-types)
- [Integral numeric types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/integral-numeric-types), [floating-point numeric types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types), [arithmetic operators](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/arithmetic-operators)
- [Casting and type conversions](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/conversions), [`Math.Round`](https://learn.microsoft.com/dotnet/api/system.math.round)
- [String interpolation](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/interpolated), [standard numeric format strings](https://learn.microsoft.com/dotnet/standard/base-types/standard-numeric-format-strings)
- [`Console.ReadLine`](https://learn.microsoft.com/dotnet/api/system.console.readline), [globalization](https://learn.microsoft.com/dotnet/core/extensions/globalization)
