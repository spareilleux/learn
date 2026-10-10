---
title: 5. Classes and objects
description: Give related data and behavior one name with a class; create objects, initialize them with constructors, and control access with fields and properties.
sidebar:
  order: 5
---

The methods in lesson 4 worked with separate values: a string's name, its open frequency, and a fret number. As a program grows, passing the same values together to every method becomes awkward. A [class](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/classes) groups the data and the operations that belong to it. An **object** is one concrete instance of that class. `GuitarString` below is a class; the low E string and the A string are two objects with different data.

Run the program in [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner) with [`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) `examples/l05_objects.cs`. Its output is checked by `check.sh`. The program uses [`Console.WriteLine`](https://learn.microsoft.com/dotnet/api/system.console.writeline) to print, [`Math.Pow`](https://learn.microsoft.com/dotnet/api/system.math.pow) for fret frequencies, and [`CultureInfo.InvariantCulture`](https://learn.microsoft.com/dotnet/api/system.globalization.cultureinfo.invariantculture) so the decimal point is the same on every machine.

```csharp
using System.Globalization;

GuitarString lowE = new GuitarString("E2", 82.41);
GuitarString a = new GuitarString("A2", 110.0);

Console.WriteLine($"{lowE.Name}: {lowE.FrequencyAt(12).ToString("F2", CultureInfo.InvariantCulture)} Hz");
Console.WriteLine($"Created: {GuitarString.CreatedCount}");

GuitarString sameString = lowE;
sameString.Rename("E2 (retuned)");
Console.WriteLine(lowE.Name);
Console.WriteLine(a.Name);

sealed class GuitarString
{
    private readonly double _openHz;

    public string Name { get; private set; }
    public double OpenHz => _openHz;
    public static int CreatedCount { get; private set; }

    public GuitarString(string name, double openHz)
    {
        Name = name;
        _openHz = openHz;
        CreatedCount++;
    }

    public void Rename(string name) => Name = name;

    public double FrequencyAt(int fret) => _openHz * Math.Pow(2, fret / 12.0);
}
```

```text
E2: 164.82 Hz
Created: 2
E2 (retuned)
A2
```

## From class to object

The `class` declaration defines a new type. `new GuitarString("E2", 82.41)` creates one object and calls its **constructor**. The second `new` creates another object. The constructor has the class name, no return type, and parameters that provide the object's initial state. In this example, an object has a name and an open-string frequency as soon as it exists. See the [constructor guide](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/constructors) for other ways to initialize objects.

`lowE.FrequencyAt(12)` calls an **instance method**: it uses that object's `_openHz`. `a.FrequencyAt(12)` would use the A string's 110 Hz instead. A method inside a class can read its fields and properties without receiving the whole object as a parameter.

`sameString = lowE` does **not** make a third string. Class variables hold references to objects: the two variables now refer to the same object. Renaming through `sameString` is therefore visible through `lowE`. The separate `a` object keeps its own name. This contrasts with the copied `int` parameter in lesson 4; lesson 6 explores value and reference types further.

## Fields, properties and access

The private [field](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/fields) `_openHz` stores a value inside each object. `private` means code outside `GuitarString` cannot use that name. `readonly` means the constructor can set the field, but later methods cannot assign a different value to it. The public [property](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/properties) `OpenHz` exposes its value for reading, without exposing the field for writing.

`Name` is an **auto-property**. Its `get` is public, but its `set` is private. Callers can read `lowE.Name`; they must call `Rename` to change it. This distinction lets a class decide which operations make sense, instead of letting callers change all its data directly. The `sealed` modifier says this introductory class cannot be inherited; inheritance comes in lesson 7.

Try to reach the private field from outside the class. This separate, minimal example gives `GuitarString` a one-argument constructor:

```csharp
GuitarString lowE = new GuitarString(82.41);
Console.WriteLine(lowE._openHz);
```

The rejected snippet `compile_fail/l05_private_field.cs` produces this real compiler diagnostic:

```text
l05_private_field.cs(2,24): error CS0122: 'GuitarString._openHz' is inaccessible due to its protection level
```

Assigning to the get-only property from outside also fails. The rejected snippet `compile_fail/l05_get_only_property.cs` contains `lowE.OpenHz = 110.0;` and produces:

```text
l05_get_only_property.cs(2,1): error CS0200: Property or indexer 'GuitarString.OpenHz' cannot be assigned to -- it is read only
```

These errors are useful feedback: use the class's public operations, or change the class design deliberately. Do not make every field public just to silence the compiler.

## One member shared by all objects

`CreatedCount` has the [`static` modifier](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/static). It belongs to the `GuitarString` class, not to any one string. Every constructor call increments the same count; the program reads it as `GuitarString.CreatedCount`, not `lowE.CreatedCount`. By contrast, `_openHz`, `Name`, and `FrequencyAt` belong to individual objects.

The count is a teaching example, not a lifetime tracker: it counts constructions, not how many objects remain in memory.

## Exercise 1 — predict the references

Without running the program, predict what it prints immediately after `sameString.Rename("E2 (retuned)")`: `lowE.Name`, `sameString.Name`, and `a.Name`. Which variables refer to the same object? Then run `examples/l05_objects.cs` to check.

<details>
<summary>Solution</summary>

`lowE.Name` and `sameString.Name` are both `E2 (retuned)`: they refer to one object. `a.Name` is still `A2`: it refers to a different object. The program prints the first and third of those values on its last two lines.

</details>

## Exercise 2 — a practice session

Make a `PracticeSession` class with a constructor that receives a topic, a read-only `Topic` property, a private minutes field, an `AddMinutes(int)` method, and a `Summary()` method. Create two sessions, add 20 and 15 minutes to the first and 10 to the second, then print both summaries. The first must still say 35 minutes after changing the second session. For now, assume minutes are nonnegative; lesson 8 covers how to reject invalid input. The tested solution is `exercises/l05_ex_practice.cs`.

<details>
<summary>Solution</summary>

```csharp
PracticeSession scales = new PracticeSession("Scales");
scales.AddMinutes(20);
scales.AddMinutes(15);

PracticeSession chords = new PracticeSession("Chords");
chords.AddMinutes(10);

Console.WriteLine(scales.Summary());
Console.WriteLine(chords.Summary());
Console.WriteLine(scales.Summary());

sealed class PracticeSession
{
    private int _minutes;

    public string Topic { get; }

    public PracticeSession(string topic)
    {
        Topic = topic;
    }

    public void AddMinutes(int minutes)
    {
        _minutes += minutes;
    }

    public string Summary() => $"{Topic}: {_minutes} min";
}
```

```text
Scales: 35 min
Chords: 10 min
Scales: 35 min
```

The two objects have separate `_minutes` fields. `Topic` is set by the constructor and cannot be assigned later by the caller.

</details>

## Check your understanding

- A class is the type definition; `new` makes an object of that type.
- A constructor gives each new object its initial state.
- A private field is internal storage; a public property or method is a deliberate way to expose it.
- An instance member belongs to one object; a `static` member belongs to the type.
- Assigning one class variable to another copies the reference, not the object.

Next: [records, structs and enums](../06-records-structs-enums/) will contrast classes with value-oriented types.
