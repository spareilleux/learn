---
title: 7. Interfaces and inheritance
description: Build a class on another with inheritance, replace virtual methods with override, require them with an abstract class, and share a contract across unrelated types with an interface.
sidebar:
  order: 7
---

The classes of lessons 5 and 6 were all `sealed`: nothing could be built on them. Yet a guitar and a ukulele are both string instruments, with the same kind of data, a name and a tuning, and almost the same behavior. C# lets a class [**inherit**](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/inheritance) from another and change only what differs. This lesson covers inheritance, `virtual` and `override`, abstract classes and interfaces. One idea links them, [**polymorphism**](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/polymorphism): the same call, `instrument.Describe()`, runs different code depending on the object.

Every program of this lesson is in [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner); run one with [`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) followed by its path, such as `examples/l07_inheritance.cs`. `check.sh` compares their outputs, and the compiler errors of the rejected snippets, with the files in `expected/`.

## Inheritance: a class built on another

```csharp
// Guitar and Ukulele derive from StringInstrument: they inherit its members
List<StringInstrument> instruments = [new Guitar(), new Ukulele()];

foreach (StringInstrument instrument in instruments)
{
    // The variable's type is StringInstrument; the object's class picks the Describe that runs
    Console.WriteLine(instrument.Describe());
}

Guitar guitar = new Guitar();
Console.WriteLine($"{guitar.Name} has {guitar.StringCount} strings and {guitar.FretCount} frets");
Console.WriteLine(guitar);                  // Console.WriteLine calls the ToString override

class StringInstrument
{
    public string Name { get; }
    public string[] Tuning { get; }

    public StringInstrument(string name, string[] tuning)
    {
        Name = name;
        Tuning = tuning;
    }

    public int StringCount => Tuning.Length;

    public virtual string Describe() => $"{Name}: {string.Join(" ", Tuning)}";

    public override string ToString() => $"{Name} ({StringCount} strings)";
}

sealed class Guitar : StringInstrument
{
    public int FretCount => 22;

    public Guitar() : base("Guitar", ["E2", "A2", "D3", "G3", "B3", "E4"])
    {
    }
}

sealed class Ukulele : StringInstrument
{
    public Ukulele() : base("Ukulele", ["G4", "C4", "E4", "A4"])
    {
    }

    public override string Describe() => base.Describe() + ", re-entrant: G4 is above C4";
}
```

```text
Guitar: E2 A2 D3 G3 B3 E4
Ukulele: G4 C4 E4 A4, re-entrant: G4 is above C4
Guitar has 6 strings and 22 frets
Guitar (6 strings)
```

`class Guitar : StringInstrument` says that `Guitar` **derives** from `StringInstrument`, its **base class**. A `Guitar` has everything a `StringInstrument` has, `Name`, `Tuning`, `StringCount`, `Describe` and `ToString`, plus its own `FretCount`. Constructors are the exception: they aren't inherited. The `Guitar()` constructor calls the base class's constructor with [`base(...)`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/base), and gives it the name and the tuning it needs.

[`virtual`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/virtual) marks a method that derived classes may replace, and [`override`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/override) replaces it. `Ukulele` overrides `Describe`, and calls the version it replaces with `base.Describe()`, so it adds to the text instead of writing it all again. `Guitar` doesn't override it and keeps the base version.

The loop shows polymorphism. Its variable is a `StringInstrument`, yet for the ukulele, `instrument.Describe()` runs `Ukulele`'s version: the class of the object decides, not the type of the variable. A `List<StringInstrument>` can hold a `Guitar` and a `Ukulele` because each of them *is* a `StringInstrument`.

Every class derives from [`object`](https://learn.microsoft.com/dotnet/api/system.object), even when it names no base class. `object` has a virtual [`ToString`](https://learn.microsoft.com/dotnet/api/system.object.tostring), which by default returns the type's name and which `Console.WriteLine` calls to print an object. `StringInstrument` overrides it, so `Console.WriteLine(guitar)` prints `Guitar (6 strings)`. The records of lesson 6 write such an override for you.

`Guitar` and `Ukulele` stay [`sealed`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/sealed): nothing derives from them. `StringInstrument` isn't, since deriving from it is the point.

### Three mistakes with inheritance

`override` only works on a method that the base class allows to be replaced. Without `virtual`, the rejected snippet `compile_fail/l07_override_not_virtual.cs` fails:

```csharp
class StringInstrument
{
    public string Describe() => "a string instrument";
}

sealed class Ukulele : StringInstrument
{
    public override string Describe() => "a ukulele";
}
```

```text
l07_override_not_virtual.cs(11,28): error CS0506: 'Ukulele.Describe()': cannot override inherited member 'StringInstrument.Describe()' because it is not marked virtual, abstract, or override
```

The opposite mistake compiles, with only a warning. In `examples/l07_hiding_warning.cs`, the base method is `virtual`, but `Ukulele` forgets `override`:

```csharp
StringInstrument uke = new Ukulele();
Console.WriteLine(uke.Describe());   // the base version runs: Ukulele's method only hides it

Ukulele sameKind = new Ukulele();
Console.WriteLine(sameKind.Describe());   // a Ukulele variable finds the hiding method

class StringInstrument
{
    public virtual string Describe() => "a string instrument";
}

sealed class Ukulele : StringInstrument
{
    public string Describe() => "a ukulele";   // override is missing
}
```

```text
l07_hiding_warning.cs(14,19): warning CS0114: 'Ukulele.Describe()' hides inherited member 'StringInstrument.Describe()'. To make the current member override that implementation, add the override keyword. Otherwise add the new keyword.
a string instrument
a ukulele
```

Without `override`, `Ukulele`'s method doesn't replace the base one; it **hides** it, and only a variable of type `Ukulele` finds it. Through a `StringInstrument` variable, the program prints `a string instrument`: polymorphism is lost, without an error. The [`new` modifier](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/new-modifier) the warning mentions makes the hiding deliberate; the guide [knowing when to use override and new](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/knowing-when-to-use-override-and-new-keywords) compares both. As a beginner, when you see [CS0114](https://learn.microsoft.com/dotnet/csharp/misc/cs0114), you almost always forgot `override`.

Last, a `sealed` class refuses to be a base class. `compile_fail/l07_sealed_base.cs` derives `TwelveString` from a sealed `Guitar`:

```text
l07_sealed_base.cs(8,22): error CS0509: 'TwelveString': cannot derive from sealed type 'Guitar'
```

## Abstract classes: a base that is never an object

What does "an instrument" play? Nothing: a guitar plucks, a piano strikes keys, a violin bows. An [**abstract class**](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/abstract) describes such a general idea, which only its derived classes make concrete:

```csharp
// Instrument is abstract: an object is a Guitar, a Piano or a Violin, never just an Instrument
Instrument[] band = [new Guitar(), new Piano(), new Violin()];

foreach (Instrument instrument in band)
{
    Console.WriteLine(instrument.Play("A4"));
}

abstract class Instrument
{
    public string Name { get; }

    protected Instrument(string name) => Name = name;

    // Each derived class must say how it plays a note
    public abstract string Play(string note);
}

sealed class Guitar : Instrument
{
    public Guitar() : base("Guitar")
    {
    }

    public override string Play(string note) => $"{Name}: pluck {note}";
}

sealed class Piano : Instrument
{
    public Piano() : base("Piano")
    {
    }

    public override string Play(string note) => $"{Name}: strike the {note} key";
}

sealed class Violin : Instrument
{
    public Violin() : base("Violin")
    {
    }

    public override string Play(string note) => $"{Name}: bow {note}";
}
```

```text
Guitar: pluck A4
Piano: strike the A4 key
Violin: bow A4
```

`public abstract string Play(string note);` has no body, only a semicolon. An abstract method is implicitly virtual, and every derived class that isn't itself abstract must override it. `Name` and the constructor, on the other hand, are written once, in `Instrument`, and shared by the three instruments. The constructor is [`protected`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/protected): only derived classes can call it.

The compiler holds both ends of the rule. `compile_fail/l07_new_abstract.cs` tries `new Instrument("Kazoo")`:

```text
l07_new_abstract.cs(1,20): error CS0144: Cannot create an instance of the abstract type or interface 'Instrument'
```

And `compile_fail/l07_missing_override.cs` declares a `Flute` that forgets `Play`:

```text
l07_missing_override.cs(9,14): error CS0534: 'Flute' does not implement inherited abstract member 'Instrument.Play(string)'
```

Guitar Alchemist's chord templates follow this pattern, with a record. At commit `5c3a52a`, [`ChordTemplate`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L15-L18) is a `public abstract record` with an `abstract string Name`, and its two derived records, [`TonalModal`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L44-L46) and [`Analytical`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L66-L68), each override `Name`.

## Interfaces: a contract any type can sign

An instrument and a singer have nothing in common as classes, but both have a range, from a lowest to a highest note. An [**interface**](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces) states such a contract, without code, and any type can sign it:

```csharp
// An interface is a contract: a class and a record sign it, with no common base class
List<IHasRange> performers =
[
    new FrettedInstrument("Guitar", 40, 64, 22),    // open strings E2 to E4, 22 frets
    new FrettedInstrument("Ukulele", 60, 69, 12),   // open strings C4 to A4, 12 frets
    new Voice("Alto", 53, 77),                      // F3 to F5
];

foreach (IHasRange performer in performers)
{
    Console.WriteLine($"{performer.Name}: MIDI {performer.LowestMidi} to {performer.HighestMidi}");
}

foreach (int midi in new[] { 40, 55, 69, 84 })
{
    List<string> names = [];
    foreach (IHasRange performer in performers)
    {
        if (CanPlay(performer, midi))
        {
            names.Add(performer.Name);
        }
    }
    Console.WriteLine($"MIDI {midi}: {string.Join(", ", names)}");
}

bool CanPlay(IHasRange performer, int midi) => midi >= performer.LowestMidi && midi <= performer.HighestMidi;

interface IHasRange
{
    string Name { get; }
    int LowestMidi { get; }
    int HighestMidi { get; }
}

sealed class FrettedInstrument : IHasRange
{
    public string Name { get; }
    public int LowestMidi { get; }
    public int HighestMidi { get; }

    public FrettedInstrument(string name, int lowestOpen, int highestOpen, int frets)
    {
        Name = name;
        LowestMidi = lowestOpen;
        HighestMidi = highestOpen + frets;
    }
}

record Voice(string Name, int LowestMidi, int HighestMidi) : IHasRange;
```

```text
Guitar: MIDI 40 to 86
Ukulele: MIDI 60 to 81
Alto: MIDI 53 to 77
MIDI 40: Guitar
MIDI 55: Guitar, Alto
MIDI 69: Guitar, Ukulele, Alto
MIDI 84: Guitar
```

[`interface IHasRange`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/interface) lists three properties and no code. A type that writes `: IHasRange` after its name **implements** the interface: it must provide each member. `FrettedInstrument` computes its highest note from its highest open string and its number of frets. `Voice`'s positional properties already have the right names and types, so the record needs nothing more. The two types share no base class besides `object`, yet a `List<IHasRange>` holds both, and `CanPlay` accepts either: it only relies on the contract. MIDI numbers count semitones, 12 per octave, like the C notes of lesson 4; the comments give the note names.

A class derives from one base class only, but it can implement as many interfaces as it wants, separated by commas. Guitar Alchemist's [`PositionLocation`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Positions/PositionLocation.cs#L5), the record struct of lesson 6, implements three: `IStr` and `IFret`, two one-property interfaces of GA (for example, [`IStr`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Primitives/IStr.cs#L3-L6) only asks for a `Str Str { get; }`), and .NET's [`IComparable<T>`](https://learn.microsoft.com/dotnet/api/system.icomparable-1), which lets positions be sorted. Interface names start with `I`, a convention of the [.NET naming guidelines](https://learn.microsoft.com/dotnet/standard/design-guidelines/names-of-classes-structs-and-interfaces).

The compiler checks the contract. In `compile_fail/l07_missing_interface_member.cs`, `record Voice(string Name, int LowestMidi) : IHasRange;` has no `HighestMidi`:

```text
l07_missing_interface_member.cs(11,45): error CS0535: 'Voice' does not implement interface member 'IHasRange.HighestMidi'
```

So, an abstract class or an interface? An abstract class shares code and data: `Name` and its constructor exist once, in `Instrument`, and a class can have only that one base. An interface shares a contract only, but types that have nothing else in common, records included, can all sign it, along with other interfaces.

## Exercises

### Exercise 1 — which method runs?

Without running it, predict the four lines that `exercises/l07_ex_predict.cs` prints.

```csharp
StringInstrument a = new Ukulele();
Ukulele b = new Ukulele();
StringInstrument c = new StringInstrument();

Console.WriteLine(a.Describe());
Console.WriteLine(b.Describe());
Console.WriteLine(c.Describe());
Console.WriteLine(a.Family());

class StringInstrument
{
    public virtual string Describe() => "strings";

    public string Family() => "chordophone";
}

sealed class Ukulele : StringInstrument
{
    public override string Describe() => "ukulele, " + base.Describe();
}
```

<details>
<summary>Solution</summary>

```text
ukulele, strings
ukulele, strings
strings
chordophone
```

`a` and `b` refer to `Ukulele` objects: the override runs in both cases, whatever the type of the variable, and adds to the base text through `base.Describe()`. `c` is a plain `StringInstrument`. `Family` isn't virtual and isn't replaced: every object uses the base version.

</details>

### Exercise 2 — a pedalboard

Write an abstract class `Effect` with a `Name` and an abstract `string Apply(string sound)`, and two effects: `Distortion`, which turns `E2` into `distortion(E2)`, and `Delay`, which receives a number of repeats and turns `E2` into `delay(E2, 3)`. Then write a method that runs a sound through a `List<Effect>`, in order, and returns the names of the effects and the result. Try both orders. The tested solution is `exercises/l07_ex_pedals.cs`.

<details>
<summary>Solution</summary>

```csharp
List<Effect> distortionFirst = [new Distortion(), new Delay(3)];
List<Effect> delayFirst = [new Delay(3), new Distortion()];

Console.WriteLine(Run(distortionFirst, "E2"));
Console.WriteLine(Run(delayFirst, "E2"));

string Run(List<Effect> pedalboard, string sound)
{
    List<string> names = [];
    foreach (Effect effect in pedalboard)
    {
        sound = effect.Apply(sound);
        names.Add(effect.Name);
    }
    return $"{string.Join(" -> ", names)}: {sound}";
}

abstract class Effect
{
    public string Name { get; }

    protected Effect(string name) => Name = name;

    public abstract string Apply(string sound);
}

sealed class Distortion : Effect
{
    public Distortion() : base("Distortion")
    {
    }

    public override string Apply(string sound) => $"distortion({sound})";
}

sealed class Delay : Effect
{
    private readonly int _repeats;

    public Delay(int repeats) : base("Delay") => _repeats = repeats;

    public override string Apply(string sound) => $"delay({sound}, {_repeats})";
}
```

```text
Distortion -> Delay: delay(distortion(E2), 3)
Delay -> Distortion: distortion(delay(E2, 3))
```

`Run` knows nothing about distortion or delay: it calls `Apply` on each `Effect`, and each object's override does the work. Adding a third effect means writing one more class, without touching `Run`. `Delay` keeps its number of repeats in a private field, as in lesson 5.

</details>

### Exercise 3 — a keyboard signs the contract

Copy `IHasRange` and `Voice` from the interfaces example, and add a record `MidiKeyboard(int Keys, int LowestMidi)` that implements `IHasRange`: its `Name` is `Keyboard (25 keys)` for 25 keys, and its `HighestMidi` is computed from the other two. Print the ranges of an alto (53 to 77) and of a 25-key keyboard starting at C3 (48), then who can play MIDI 50, 60 and 75. The tested solution is `exercises/l07_ex_keyboard.cs`.

<details>
<summary>Solution</summary>

```csharp
List<IHasRange> performers =
[
    new Voice("Alto", 53, 77),
    new MidiKeyboard(25, 48),       // 25 keys from C3
];

foreach (IHasRange performer in performers)
{
    Console.WriteLine($"{performer.Name}: MIDI {performer.LowestMidi} to {performer.HighestMidi}");
}

foreach (int midi in new[] { 50, 60, 75 })
{
    List<string> names = [];
    foreach (IHasRange performer in performers)
    {
        if (midi >= performer.LowestMidi && midi <= performer.HighestMidi)
        {
            names.Add(performer.Name);
        }
    }
    Console.WriteLine($"MIDI {midi}: {string.Join(", ", names)}");
}

interface IHasRange
{
    string Name { get; }
    int LowestMidi { get; }
    int HighestMidi { get; }
}

record Voice(string Name, int LowestMidi, int HighestMidi) : IHasRange;

record MidiKeyboard(int Keys, int LowestMidi) : IHasRange
{
    public string Name => $"Keyboard ({Keys} keys)";
    public int HighestMidi => LowestMidi + Keys - 1;
}
```

```text
Alto: MIDI 53 to 77
Keyboard (25 keys): MIDI 48 to 72
MIDI 50: Keyboard (25 keys)
MIDI 60: Alto, Keyboard (25 keys)
MIDI 75: Alto
```

`LowestMidi` comes from the record's parentheses, `Name` and `HighestMidi` from computed properties between its braces: the interface doesn't care how a member is written, only that it exists. 25 keys from 48 end at 72, not 73, because the first key counts.

</details>

## Check your understanding

- A derived class inherits the members of its base class, except constructors; it calls the base constructor with `base(...)`.
- `virtual` allows a derived class to replace a method, `override` replaces it, and `base.Method()` calls the replaced version.
- The class of the object, not the type of the variable, decides which override runs: that's polymorphism.
- Forgetting `override` hides the method instead of replacing it (warning CS0114).
- An abstract class can't be instantiated, and its abstract members must be overridden.
- An interface is a contract without code; a class has one base class but can implement several interfaces.

Next: [exceptions and null safety](../#outline), for when a method can't do what it's asked.

## Sources

- [Inheritance](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/inheritance), [polymorphism](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/polymorphism), [`System.Object`](https://learn.microsoft.com/dotnet/api/system.object), [`Object.ToString`](https://learn.microsoft.com/dotnet/api/system.object.tostring)
- Keywords: [`virtual`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/virtual), [`override`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/override), [`base`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/base), [`abstract`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/abstract), [`sealed`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/sealed), [`protected`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/protected), [`interface`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/interface), [the `new` modifier](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/new-modifier)
- [Abstract and sealed classes](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/abstract-and-sealed-classes-and-class-members), [knowing when to use override and new](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/knowing-when-to-use-override-and-new-keywords), [interfaces](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces), [`IComparable<T>`](https://learn.microsoft.com/dotnet/api/system.icomparable-1)
- [Names of classes, structs and interfaces](https://learn.microsoft.com/dotnet/standard/design-guidelines/names-of-classes-structs-and-interfaces), [compiler warning CS0114](https://learn.microsoft.com/dotnet/csharp/misc/cs0114)
