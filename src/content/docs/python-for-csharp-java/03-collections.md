---
title: 3. Built-in types and collections
description: Numbers that don't overflow and round half to even, strings and f-strings, list, tuple, dict and set, slicing and unpacking, comprehensions where C# writes LINQ and Java writes streams, grouping, hashing and the pitfalls of shared rows — compared with .NET and Java collections.
sidebar:
  order: 3
---

Code: the files [`examples/l03_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples) and [`errors/l03_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/errors), and the C# and Java sides in [`compare/l03_numbers.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l03_numbers.cs), [`compare/L03Numbers.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Numbers.java), [`compare/l03_linq.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l03_linq.cs), [`compare/L03Streams.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Streams.java), [`compare/l03_modify.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l03_modify.cs) and [`compare/L03Modify.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Modify.java).

## Numbers

Python has three numeric types built in: `int`, of unlimited size, `float`, a 64-bit IEEE 754 double like C#'s `double`, and `complex`. The standard library adds [`decimal.Decimal`](https://docs.python.org/3.14/library/decimal.html) and [`fractions.Fraction`](https://docs.python.org/3.14/library/fractions.html). The arithmetic operators hold a few surprises for a C# or Java developer:

```python
# examples/l03_numbers.py
import math
from decimal import ROUND_HALF_UP, Decimal

# Integer division rounds toward negative infinity, and % takes the sign of the divisor
print(7 // 2, -7 // 2, -7 % 2)
print(int(-7 / 2), math.fmod(-7, 2))  # truncation, as C# and Java divide
print(7 / 2, 6 / 2)  # / always gives a float

print(2**64, (2**64).bit_length())
print(0.1 + 0.2, 0.1 + 0.2 == 0.3, math.isclose(0.1 + 0.2, 0.3))

# round() rounds half to even, and a float literal is rarely the decimal it looks like
print(round(2.5), round(3.5), round(2.675, 2), Decimal(2.675))

# Lesson 1's picks: 50 at 0.50, plus 15% tax, minus 10%
total = (0.50 + 0.50 * 0.15) * 50 * 0.9  # the formula of lesson 1
print(total, f"{total:.2f}")
exact = (Decimal("0.50") + Decimal("0.50") * Decimal("0.15")) * 50 * Decimal("0.9")
print(exact, exact.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP), Decimal("0.1") + Decimal("0.2"))
```

```text
> uv run python examples/l03_numbers.py
3 -4 1
-3 -1.0
3.5 3.0
18446744073709551616 65
0.30000000000000004 False True
2 4 2.67 2.67499999999999982236431605997495353221893310546875
25.874999999999996 25.87
25.87500 25.88 0.3
```

```cs
// compare/l03_numbers.cs
// Integer division truncates toward zero, and % takes the sign of the dividend
Console.WriteLine($"{7 / 2} {-7 / 2} {-7 % 2}");

// Math.Round rounds half to even by default too; decimal is exact for decimal fractions
Console.WriteLine($"{Math.Round(2.5)} {Math.Round(3.5)} {Math.Round(2.5, MidpointRounding.AwayFromZero)}");
Console.WriteLine($"{0.1 + 0.2} {0.1m + 0.2m}");

// int has 32 bits: without checked, it wraps around
int max = int.MaxValue;
Console.WriteLine(max + 1);
```

```text
> dotnet run l03_numbers.cs
3 -3 -1
2 4 3
0.30000000000000004 0.3
-2147483648
> java L03Numbers.java
3 -3 -1 -4 1
3 4 2.0
0.30000000000000004
-2147483648
```

| | C# | Java | Python |
|---|---|---|---|
| `-7 / 2` on integers | `-3`, truncated | `-3`, truncated | `-3.5`: `/` is always true division |
| Integer division | `/` | `/`, or `Math.floorDiv` | `//`, rounded toward negative infinity: `-4` |
| `-7 % 2` | `-1`, the sign of the dividend | `-1`, or `Math.floorMod`: `1` | `1`, the sign of the divisor |
| `int.MaxValue + 1` | wraps to `-2147483648` | wraps | no maximum: `2**64` is exact |
| Rounding 2.5 | `Math.Round`: `2`, half to even | `Math.round`: `3`, half up | `round`: `2`, half to even |
| Exact decimal | `decimal`, a keyword and a literal `0.1m` | `BigDecimal` | `Decimal("0.1")`, from a string |

`//` and `%` are consistent with each other: `(a // b) * b + a % b == a` always holds, and `-7 % 12` is `5`, which is the right answer for a pitch class seven semitones below C. Java added `Math.floorDiv` and `Math.floorMod` for the same reason.

`round(2.675, 2)` gives `2.67` because the literal `2.675` is the binary float `2.67499999999999982…`, which `Decimal(2.675)` shows digit by digit. Lesson 1's picks printed `25.87` for the same reason: the float computation gives `25.874999999999996`, and the exact total, `25.875`, only exists as a `Decimal`. A `Decimal` must be built from a string, not from a float that has already lost the value, and `quantize` rounds it to cents with the rule you choose. Money is `Decimal`, as it is `decimal` in C#.

## Strings

A `str` is an immutable sequence of Unicode code points. Unlike C#'s `string`, which holds UTF-16 code units, `len` counts code points, and indexing returns a string of length one, since there is no `char` type:

```python
# examples/l03_strings.py
import re

chord = "Cmaj7"
print(chord[0], chord[-1], chord[1:4], len(chord))  # a str is a sequence of characters
print("maj" in chord, chord.startswith("C"), chord.upper())

notes = "C,E,G,B".split(",")
print(notes, " - ".join(notes))

price, quantity = 9.99, 2
print(f"{quantity} x {price:.2f} = {price * quantity:>8.2f}")
print(f"{quantity=}, {price * quantity=:.3f}")  # = prints the expression too

# A raw string keeps backslashes as they are, which is what a regular expression needs
version = re.compile(r"^v(\d+)\.(\d+)$")
match = version.match("v3.14")
print(match.groups() if match else None)
```

```text
> uv run python examples/l03_strings.py
C 7 maj 5
True True CMAJ7
['C', 'E', 'G', 'B'] C - E - G - B
2 x 9.99 =    19.98
quantity=2, price * quantity=19.980
('3', '14')
```

An [f-string](https://docs.python.org/3.14/reference/lexical_analysis.html#f-strings) is C#'s interpolated string: `f"{price:.2f}"` is `$"{price:F2}"`, and the format specification after the colon follows Python's [format mini-language](https://docs.python.org/3.14/library/string.html#format-specification-mini-language), where `>8` aligns right in eight characters. `{quantity=}` prints the expression and its value, which is handy for debugging. `join` is a method of the separator, not of the list: `" - ".join(notes)` is `string.Join(" - ", notes)`.

The prefix `r` makes a *raw string*, where a backslash is an ordinary character, as in C#'s verbatim `@"…"`. Without it, Python interprets escape sequences, and an unknown one is kept but reported:

```python
# errors/l03_escape.py
import re

pattern = "^https?://.*/(api|v\d+)/"  # \d is not an escape sequence of a Python string
print(pattern)
print(bool(re.match(pattern, "https://example.com/v2/chords")))

text = "C:\new\tabs"  # \n and \t are escape sequences: a newline and a tab
print(text)
```

```text
> uv run python errors/l03_escape.py
errors/l03_escape.py:4: SyntaxWarning: "\d" is an invalid escape sequence. Such sequences will not work in the future. Did you mean "\\d"? A raw string is also an option.
  pattern = "^https?://.*/(api|v\d+)/"  # \d is not an escape sequence of a Python string
^https?://.*/(api|v\d+)/
True
C:
ew	abs
```

The pattern still works today, since Python keeps an unknown escape as a backslash and a letter, but the warning says it will become an error. The Windows path shows the opposite trap, where `\n` and `\t` are valid escapes and silently change the text. C# refuses an unknown escape at compile time (`CS1009`). mypy reports nothing for either.

## The four collections

| Python | C# | Java | Literal | Mutable | Ordered |
|---|---|---|---|---|---|
| `list` | `List<T>` | `ArrayList<E>` | `["E", "A"]` | yes | by position |
| `tuple` | `ValueTuple`, `ImmutableArray<T>` | `List.of`, records | `("C", "E", "G")` | no | by position |
| `dict` | `Dictionary<K, V>` | `LinkedHashMap<K, V>` | `{"C": 0, "E": 4}` | yes | by insertion |
| `set` | `HashSet<T>` | `HashSet<E>` | `{"E", "A"}` | yes | no |
| `frozenset` | `ImmutableHashSet<T>` | `Set.of` | `frozenset(...)` | no | no |

A single list can hold objects of different types, since the list stores references to objects; an annotation such as `list[str]` states what it holds, for mypy. `{}` is an empty `dict`, not an empty set, which is `set()`.

```python
# examples/l03_collections.py
tuning = ["E", "A", "D", "G", "B", "E"]  # list: a growable array, like List<T> and ArrayList
c_major = ("C", "E", "G")  # tuple: a fixed sequence that can't be changed
intervals = {"C": 0, "E": 4, "G": 7}  # dict: a hash table that keeps insertion order
open_notes = set(tuning)  # set: a hash set, without duplicates

tuning.append("A")
print(tuning, len(tuning), tuning.count("E"))
print(c_major[1], "G" in c_major, c_major + ("B",))

intervals["B"] = 11
print(intervals, intervals.get("D"), intervals.get("D", -1))
for note, semitones in intervals.items():
    print(f"{note}: {semitones}", end="  ")
print()

print(len(open_notes), sorted(open_notes), "B" in open_notes)
print(sorted(open_notes & {"C", "E", "G"}), sorted(open_notes - {"E"}))

# Collections compare by value
print([1, 2] == [1, 2], (1, 2) == (1, 2), {"a": 1, "b": 2} == {"b": 2, "a": 1})

# Unpacking
first, *middle, last = tuning
print(first, middle, last)
root, third, fifth = c_major
third, fifth = fifth, third  # a swap, through a tuple
print(root, third, fifth)
```

```text
> uv run python examples/l03_collections.py
['E', 'A', 'D', 'G', 'B', 'E', 'A'] 7 2
E True ('C', 'E', 'G', 'B')
{'C': 0, 'E': 4, 'G': 7, 'B': 11} None -1
C: 0  E: 4  G: 7  B: 11
5 ['A', 'B', 'D', 'E', 'G'] True
['E', 'G'] ['A', 'B', 'D', 'G']
True True True
E ['A', 'D', 'G', 'B', 'E'] A
C G E
```

`in` works on every collection: position by position for a list or a tuple, by hash for a dict (its keys) or a set. A `dict` keeps the order in which keys were inserted, a guarantee of the language since Python 3.7, so it plays the role of both `Dictionary` and `LinkedHashMap`. Sets have operators, `&` for the intersection, `|` for the union and `-` for the difference, where C# calls `IntersectWith`.

Unpacking assigns the items of any sequence to several names at once, and `*middle` collects the rest into a list. `third, fifth = fifth, third` builds the tuple on the right, then unpacks it, which is how Python swaps without a temporary variable, like C#'s `(a, b) = (b, a)`.

### A set's order changes between runs

The set above was printed through `sorted`, and not by accident. The hash of a `str` is salted with a random value chosen when the interpreter starts, to make denial-of-service attacks through hash collisions harder, so the order of a set of strings changes from one process to the next. The environment variable [`PYTHONHASHSEED`](https://docs.python.org/3.14/using/cmdline.html#envvar-PYTHONHASHSEED) fixes the salt, which makes the effect visible:

```text
> PYTHONHASHSEED=1 uv run python -c "print({'E', 'A', 'D', 'G', 'B'})"
{'G', 'B', 'A', 'D', 'E'}
> PYTHONHASHSEED=2 uv run python -c "print({'E', 'A', 'D', 'G', 'B'})"
{'D', 'G', 'E', 'B', 'A'}
```

Without the variable, each run prints one of those orders or another. .NET randomizes [`string.GetHashCode`](https://learn.microsoft.com/dotnet/api/system.string.gethashcode) per process too, and its documentation warns against persisting hash codes. Don't print a set, or iterate over it, where the order matters: sort it. A `dict` doesn't have this problem, since its order is the insertion order.

## Slicing

`sequence[start:stop:step]` takes a part of a list, a tuple or a string. The start is included, the stop excluded, negative indices count from the end, and any part can be omitted:

```python
# examples/l03_slicing.py
tuning = ["E", "A", "D", "G", "B", "E"]
print(tuning[1:3], tuning[:2], tuning[4:], tuning[-2:], tuning[::2], tuning[::-1])
print(tuning[10:], tuning[-100:2])  # a slice outside the list is empty or shortened, never an error

bass = tuning[:3]  # a slice is a new list
bass[0] = "D"
print(bass, tuning)

tuning[3:] = ["G", "A", "D"]  # slice assignment replaces part of the list in place
print(tuning)
del tuning[0]
print(tuning)
```

```text
> uv run python examples/l03_slicing.py
['A', 'D'] ['E', 'A'] ['B', 'E'] ['B', 'E'] ['E', 'D', 'B'] ['E', 'B', 'G', 'D', 'A', 'E']
[] ['E', 'A']
['D', 'A', 'D'] ['E', 'A', 'D', 'G', 'B', 'E']
['E', 'A', 'D', 'G', 'A', 'D']
['A', 'D', 'G', 'A', 'D']
```

C#'s ranges, `tuning[1..3]` and `tuning[^2..]`, borrowed this syntax, and like Python they copy an array or a list. Java's [`subList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#subList(int,int)) is a view instead, where writing to the part writes to the list; the last line of `L03Modify.java` below shows it. An index outside a list raises `IndexError`, but a slice outside it is quietly shortened.

## Comprehensions instead of LINQ

A **comprehension** builds a list, a dict or a set from an iterable, with an expression, one or more `for` clauses and optional `if` clauses. It is the Python counterpart of a LINQ query or a stream pipeline, written in the order of the loops it replaces:

```python
# examples/l03_comprehensions.py
CHORDS = [
    ("C", "major", ["C", "E", "G"]),
    ("A", "minor", ["A", "C", "E"]),
    ("G", "dominant 7", ["G", "B", "D", "F"]),
    ("E", "minor", ["E", "G", "B"]),
    ("D", "major", ["D", "F#", "A"]),
    ("F", "major 7", ["F", "A", "C", "E"]),
]

# Where + Select, filter + map
minor = [f"{root}m" for root, quality, _ in CHORDS if quality == "minor"]
print(minor)

# ToDictionary, Collectors.toMap
sizes = {root: len(notes) for root, _, notes in CHORDS}
print(sizes)

# SelectMany + Distinct, flatMap + distinct: two for clauses, in the order of nested loops
all_notes = sorted({note for _, _, notes in CHORDS for note in notes})
print(all_notes)

# Any, All, Sum, Max: functions that consume a generator expression
print(any(len(notes) == 4 for _, _, notes in CHORDS), all("E" in notes for _, _, notes in CHORDS))
print(sum(len(notes) for _, _, notes in CHORDS))
print(max(CHORDS, key=lambda chord: len(chord[2])))  # the first of the largest

# OrderByDescending + ThenBy: one key, a tuple, compared item by item
for root, quality, notes in sorted(CHORDS, key=lambda chord: (-len(chord[2]), chord[0])):
    print(f"{root:<2} {quality:<11} {' '.join(notes)}")

# zip pairs items up, and enumerate numbers them
tuning = ["E", "A", "D", "G", "B", "E"]
for number, (string, note) in enumerate(zip([6, 5, 4, 3, 2, 1], tuning, strict=True), start=1):
    print(f"{number}:{string}{note}", end=" ")
print()
```

```text
> uv run python examples/l03_comprehensions.py
['Am', 'Em']
{'C': 3, 'A': 3, 'G': 4, 'E': 3, 'D': 3, 'F': 4}
['A', 'B', 'C', 'D', 'E', 'F', 'F#', 'G']
True False
20
('G', 'dominant 7', ['G', 'B', 'D', 'F'])
F  major 7     F A C E
G  dominant 7  G B D F
A  minor       A C E
C  major       C E G
D  major       D F# A
E  minor       E G B
1:6E 2:5A 3:4D 4:3G 5:2B 6:1E
```

The same queries with LINQ, and with streams in [`compare/L03Streams.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Streams.java), give the same results:

```cs
// compare/l03_linq.cs
Chord[] chords =
[
    new("C", "major", ["C", "E", "G"]),
    new("A", "minor", ["A", "C", "E"]),
    new("G", "dominant 7", ["G", "B", "D", "F"]),
    new("E", "minor", ["E", "G", "B"]),
    new("D", "major", ["D", "F#", "A"]),
    new("F", "major 7", ["F", "A", "C", "E"]),
];

var minor = chords.Where(c => c.Quality == "minor").Select(c => $"{c.Root}m");
Console.WriteLine(string.Join(", ", minor));

var sizes = chords.ToDictionary(c => c.Root, c => c.Notes.Length);
Console.WriteLine(string.Join(", ", sizes.Select(pair => $"{pair.Key}: {pair.Value}")));

var allNotes = chords.SelectMany(c => c.Notes).Distinct().Order(StringComparer.Ordinal);
Console.WriteLine(string.Join(", ", allNotes));

Console.WriteLine($"{chords.Any(c => c.Notes.Length == 4)} {chords.All(c => c.Notes.Contains("E"))}");
Console.WriteLine(chords.Sum(c => c.Notes.Length));
var largest = chords.MaxBy(c => c.Notes.Length)!;
Console.WriteLine($"{largest.Root} {largest.Quality}"); // the first of the largest

foreach (var c in chords.OrderByDescending(c => c.Notes.Length).ThenBy(c => c.Root, StringComparer.Ordinal))
{
    Console.WriteLine($"{c.Root,-2} {c.Quality,-11} {string.Join(" ", c.Notes)}");
}

// GroupBy keeps the order in which each key first appears, and doesn't need sorted data
foreach (var group in chords.GroupBy(c => c.Quality))
{
    Console.Write($"{group.Key}: {string.Join(" ", group.Select(c => c.Root))}; ");
}
Console.WriteLine();

record Chord(string Root, string Quality, string[] Notes);
```

```text
> dotnet run l03_linq.cs
Am, Em
C: 3, A: 3, G: 4, E: 3, D: 3, F: 4
A, B, C, D, E, F, F#, G
True False
20
G dominant 7
F  major 7     F A C E
G  dominant 7  G B D F
A  minor       A C E
C  major       C E G
D  major       D F# A
E  minor       E G B
major: C D; minor: A E; dominant 7: G; major 7: F;
> java L03Streams.java
[Am, Em]
[A, B, C, D, E, F, F#, G]
true false
20
Chord[root=G, quality=dominant 7, notes=[G, B, D, F]]
F  major 7     F A C E
G  dominant 7  G B D F
A  minor       A C E
C  major       C E G
D  major       D F# A
E  minor       E G B
{minor=[A, E], major=[C, D], major 7=[F], dominant 7=[G]}
```

| LINQ | Streams | Python |
|---|---|---|
| `Where(c => …)` | `filter` | `if` clause |
| `Select(c => …)` | `map` | the expression before `for` |
| `SelectMany` | `flatMap` | a second `for` clause |
| `ToDictionary`, `ToHashSet` | `Collectors.toMap`, `toSet` | `{k: v for …}`, `{x for …}` |
| `Any`, `All`, `Sum`, `Count(pred)` | `anyMatch`, `allMatch`, `sum`, `count` | `any(…)`, `all(…)`, `sum(…)`, `sum(1 for … if …)` |
| `MaxBy`, `MinBy` | `max(Comparator)` | `max(…, key=…)`, `min(…, key=…)` |
| `OrderBy`, `ThenByDescending` | `sorted(Comparator…thenComparing)` | `sorted(…, key=…, reverse=…)`, with a tuple as key |
| `Zip`, `Select((x, i) => …)` | — | `zip`, `enumerate` |
| `GroupBy` | `Collectors.groupingBy` | `defaultdict(list)`, or `itertools.groupby` on sorted data (below) |
| `Aggregate` | `reduce` | `functools.reduce`, usually a loop |

Four things differ from LINQ:

- A list, dict or set comprehension runs **at once** and builds the whole collection, where a LINQ query runs when it is enumerated. The lazy form is a **generator expression**, the same syntax in parentheses, which `any`, `sum` and `max` consume without building a list. Lesson 10 covers generators.
- `sorted` takes a `key` function, which returns the value to compare, rather than a comparer. A tuple compares item by item, so `(-len(notes), root)` means "most notes first, then by root". The sort is stable, like `OrderBy` and unlike `List<T>.Sort`.
- `zip(..., strict=True)` raises `ValueError` when the sequences don't have the same length; without `strict`, it stops silently at the shortest, like LINQ's `Zip`.
- The underscore `_` is only a name, used by convention for a value that is ignored.

A comprehension longer than one line or with nested conditions reads worse than the loop it replaces. PEP 8 doesn't set a limit; the usual rule is two `for` clauses or one `if` at most.

## Grouping and counting

```python
# examples/l03_grouping.py
from collections import Counter, defaultdict
from itertools import groupby

CHORDS = [
    ("C", "major"),
    ("A", "minor"),
    ("G", "dominant 7"),
    ("E", "minor"),
    ("D", "major"),
    ("F", "major 7"),
]

# GroupBy with a dict of lists: defaultdict creates the list the first time a key is used
by_quality: defaultdict[str, list[str]] = defaultdict(list)
for root, quality in CHORDS:
    by_quality[quality].append(root)
print(dict(by_quality))

# Count per key
counts = Counter(quality for _, quality in CHORDS)
print(counts.most_common(2), counts["minor"], counts["diminished"])

# itertools.groupby groups consecutive items only, so the data must be sorted by the same key first
print([(quality, len(list(group))) for quality, group in groupby(CHORDS, key=lambda chord: chord[1])])
ordered = sorted(CHORDS, key=lambda chord: chord[1])
print([(quality, [root for root, _ in group]) for quality, group in groupby(ordered, key=lambda chord: chord[1])])

# A comprehension runs at once; a generator expression runs when it is consumed, and only once
roots = (root for root, _ in CHORDS)
print(list(roots), list(roots))
```

```text
> uv run python examples/l03_grouping.py
{'major': ['C', 'D'], 'minor': ['A', 'E'], 'dominant 7': ['G'], 'major 7': ['F']}
[('major', 2), ('minor', 2)] 2 0
[('major', 1), ('minor', 1), ('dominant 7', 1), ('minor', 1), ('major', 1), ('major 7', 1)]
[('dominant 7', ['G']), ('major', ['C', 'D']), ('major 7', ['F']), ('minor', ['A', 'E'])]
['C', 'A', 'G', 'E', 'D', 'F'] []
```

[`defaultdict(list)`](https://docs.python.org/3.14/library/collections.html#collections.defaultdict) calls `list()` to create the value of a missing key, so the loop never checks whether the key exists; the result keeps the order in which qualities first appeared, as LINQ's `GroupBy` does, while Java's `groupingBy` returned a `HashMap` in hash order. [`Counter`](https://docs.python.org/3.14/library/collections.html#collections.Counter) counts, and returns `0` for a key it has never seen instead of raising `KeyError`.

[`itertools.groupby`](https://docs.python.org/3.14/library/itertools.html#itertools.groupby) has the name of LINQ's operator and the behavior of the Unix command `uniq`: it groups *consecutive* items with the same key. On the unsorted chords it made six groups of one. Sorted first, it gives the real groups.

The last line is the Java stream rule in Python: a generator expression can be consumed once, and the second `list(roots)` finds it empty, without an error.

## Hashing, and changing a collection while iterating

A dict key and a set item must be **hashable**: their hash must never change. Immutable built-in types are hashable, a tuple is if its items are, and a list isn't:

```python
# errors/l03_unhashable.py
voicings = {("x", 3, 2, 0, 1, 0): "C major"}  # a tuple of hashable items can be a key
print(voicings[("x", 3, 2, 0, 1, 0)])

names = {["x", 3, 2, 0, 1, 0]: "C major"}  # a list can't: it could change after being stored
```

```text
> uv run python errors/l03_unhashable.py
C major
Traceback (most recent call last):
  File "errors/l03_unhashable.py", line 5, in <module>
    names = {["x", 3, 2, 0, 1, 0]: "C major"}  # a list can't: it could change after being stored
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TypeError: cannot use 'list' as a dict key (unhashable type: 'list')
```

The message is new in 3.14; older versions only said `unhashable type: 'list'`. C# would accept a `List<T>` as a key, hashed by reference, and find nothing when looking up an equal list; Python refuses a key whose value equality could change. mypy 2.3.1 accepted this file.

Changing the size of a dict while iterating over it is detected:

```python
# errors/l03_changed_size.py
stock = {"capo": 2, "strings": 0, "picks": 50, "tuner": 0}

print({name: count for name, count in stock.items() if count > 0})  # build a new dict instead

for name, count in stock.items():
    if count == 0:
        del stock[name]
```

```text
> uv run python errors/l03_changed_size.py
{'capo': 2, 'picks': 50}
Traceback (most recent call last):
  File "errors/l03_changed_size.py", line 6, in <module>
    for name, count in stock.items():
                       ~~~~~~~~~~~^^
RuntimeError: dictionary changed size during iteration
```

```cs
// compare/l03_modify.cs
var stock = new Dictionary<string, int> { ["capo"] = 2, ["strings"] = 0, ["picks"] = 50, ["tuner"] = 0 };

// Since .NET Core 3.0, Remove during the enumeration of a Dictionary is allowed
foreach (var (name, count) in stock)
{
    if (count == 0) stock.Remove(name);
}
Console.WriteLine(string.Join(", ", stock.Keys));

var tuning = new List<string> { "E", "A", "D", "G", "B", "E" };
try
{
    foreach (var note in tuning)
    {
        if (note == "E") tuning.Remove(note);
    }
}
catch (InvalidOperationException e)
{
    Console.WriteLine($"{e.GetType().Name}: {e.Message}");
}

// GetRange copies, like a Python slice
var bass = tuning.GetRange(0, 3);
bass[0] = "D";
Console.WriteLine($"{string.Join(" ", bass)} | {string.Join(" ", tuning)}");
```

```text
> dotnet run l03_modify.cs
capo, picks
InvalidOperationException: Collection was modified; enumeration operation may not execute.
D D G | A D G B E
> java L03Modify.java
ConcurrentModificationException
{capo=2, picks=50}
[D, A, D] [D, A, D, G, B, E]
```

The three platforms disagree more than expected. Java throws for the map, and offers `values().removeIf`. .NET throws for the list, but not for the dictionary: since .NET Core 3.0, [`Dictionary.Remove`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2.remove) can be called during an enumeration. Python raises for the dict; the comprehension on the first line, which builds a new dict, is the idiomatic answer, or a loop over `list(stock.items())`, a copy. For a list, Python raises nothing at all and skips items, which is worse: iterate over a copy, or build a new list.

## Shared rows

The multiplication of a sequence, `[0] * 4`, repeats its items, and the items are references. With a list of lists, all the rows are the same list:

```python
# examples/l03_grid.py
# A fretboard of 3 strings and 4 frets, where 1 marks a finger
shared = [[0] * 4] * 3  # the outer * copies the reference to one inner list three times
shared[0][2] = 1
print(shared)

grid = [[0] * 4 for _ in range(3)]  # the comprehension builds a new inner list each time
grid[0][2] = 1
print(grid)
print(shared[0] is shared[1], grid[0] is grid[1])
```

```text
> uv run python examples/l03_grid.py
[[0, 0, 1, 0], [0, 0, 1, 0], [0, 0, 1, 0]]
[[0, 0, 1, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
True False
```

It is [lesson 2](../02-execution-model/#names-not-boxes)'s rule again: nothing is copied unless something copies it. `[0] * 4` is safe because `0` is immutable. The same applies to `list(tuning)`, `tuning[:]` and `dict(stock)`, which make **shallow** copies: a new outer collection holding the same inner objects. [`copy.deepcopy`](https://docs.python.org/3.14/library/copy.html) copies all the way down.

## In real projects

**GA's governance agent** counts belief configurations by hand in [`src/agents/epistemic_agent.py`, lines 86-100](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L86-L100), with `tensor_summary[config] = tensor_summary.get(config, 0) + 1` in a loop, then `tensor_summary.get("C_T", 0)` for each count: the work of a `Counter` (exercise 1). The `where` filter of the same file, [lines 36-69](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L36-L69), is a chain of six `if`/`elif` that each append to a list, and swallows conversion errors with `except (ValueError, TypeError): continue` (exercise 3).

**IX's** coverage script imports `Dict`, `List` and `Optional` from `typing` ([`optick_coverage.py`, line 29](https://github.com/GuitarAlchemist/ix/blob/2190c685e3664488c9a3d0c1388c96b868a178cb/crates/ix-optick-sae/python/optick_coverage.py#L29)). Since Python 3.9 and [PEP 585](https://peps.python.org/pep-0585/), the built-in `dict[str, list[int]]` works in annotations, and since 3.10 `int | None` replaces `Optional[int]`; the old names still work, and Ruff can rewrite them (lesson 13).

**TARS** has tools that generate code from templates held in ordinary Python strings, and the regular expressions inside those templates trigger the warning. The pattern of `errors/l03_escape.py` comes from [`tools/python/implementation-starter.py`, line 184](https://github.com/GuitarAlchemist/tars/blob/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python/implementation-starter.py#L184), where compiling the file with Python 3.14.7 prints `SyntaxWarning: "\d" is an invalid escape sequence`; [`tools/python/meta-programming-demo.py`](https://github.com/GuitarAlchemist/tars/blob/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python/meta-programming-demo.py#L497) prints the same warning for `\w` at line 497, a raw string `r'…'` written inside a template that isn't raw. The generated text is still correct, since Python keeps the backslash, until the version where the warning becomes an error.

## Key takeaways

- `int` doesn't overflow, `/` always gives a float, `//` and `%` round toward negative infinity, and `round` rounds half to even. Money is `Decimal`, built from strings.
- Use a raw string, `r"…"`, for regular expressions and Windows paths.
- `list`, `tuple`, `dict` and `set` cover `List<T>`, immutable sequences, `Dictionary` and `HashSet`. A dict keeps insertion order; a set of strings changes order from one run to the next.
- Slices copy, and never raise for an out-of-range bound.
- Comprehensions replace `Where`, `Select`, `SelectMany` and `ToDictionary`, and run at once; generator expressions are the lazy form, consumed once. `sorted` takes a `key`.
- Group with `defaultdict(list)`, count with `Counter`, and sort before `itertools.groupby`.
- Dict keys must be hashable. Don't change a dict or a list while iterating over it: build a new one.
- `[[0] * n] * m` repeats one row; build rows in a comprehension.

## Exercises

1. Rewrite the tensor summary of GA's [`epistemic_agent.py`, lines 86-100](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L86-L100) as a function that takes a list of beliefs and returns the same dictionary, where a belief without `tensorConfig` counts as `U_U`.

<details>
<summary>Solution</summary>

[`solutions/l03_ex1_tensor.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l03_ex1_tensor.py):

```python
# solutions/l03_ex1_tensor.py
from collections import Counter


def tensor_summary(beliefs: list[dict[str, str]]) -> dict[str, object]:
    # A Counter counts in one pass, and returns 0 for a key it has never seen
    distribution = Counter(belief.get("tensorConfig", "U_U") for belief in beliefs)
    return {
        "total_beliefs": len(beliefs),
        "tensor_distribution": dict(distribution),
        "wisdom_count": distribution["C_T"],
        "hunch_count": distribution["T_C"],
        "blindspot_count": distribution["U_F"],
    }


if __name__ == "__main__":
    beliefs = [{"tensorConfig": "C_T"}, {"tensorConfig": "T_C"}, {}, {"tensorConfig": "C_T"}]
    print(tensor_summary(beliefs))
```

```text
> uv run python solutions/l03_ex1_tensor.py
{'total_beliefs': 4, 'tensor_distribution': {'C_T': 2, 'T_C': 1, 'U_U': 1}, 'wisdom_count': 2, 'hunch_count': 1, 'blindspot_count': 0}
```

`dict(distribution)` turns the `Counter`, a subclass of `dict`, into a plain dict before it goes into JSON, which accepts both anyway. The return type `dict[str, object]` is honest but not precise; lesson 6 replaces it with a `TypedDict`, whose keys each have a type.

</details>

2. Translate this LINQ query into Python, with the `CHORDS` of [`examples/l03_comprehensions.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples/l03_comprehensions.py): the roots of the three-note chords, grouped by quality, with the qualities in alphabetical order.

```cs
var triads = chords
    .Where(c => c.Notes.Length == 3)
    .GroupBy(c => c.Quality)
    .OrderBy(g => g.Key)
    .ToDictionary(g => g.Key, g => g.Select(c => c.Root).ToList());
```

<details>
<summary>Solution</summary>

[`solutions/l03_ex2_triads.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l03_ex2_triads.py):

```python
# solutions/l03_ex2_triads.py
from collections import defaultdict

type Chord = tuple[str, str, list[str]]

CHORDS: list[Chord] = [
    ("C", "major", ["C", "E", "G"]),
    ("A", "minor", ["A", "C", "E"]),
    ("G", "dominant 7", ["G", "B", "D", "F"]),
    ("E", "minor", ["E", "G", "B"]),
    ("D", "major", ["D", "F#", "A"]),
    ("F", "major 7", ["F", "A", "C", "E"]),
]


def triad_roots_by_quality(chords: list[Chord]) -> dict[str, list[str]]:
    groups: defaultdict[str, list[str]] = defaultdict(list)
    for root, quality, notes in chords:
        if len(notes) == 3:
            groups[quality].append(root)
    return {quality: groups[quality] for quality in sorted(groups)}


if __name__ == "__main__":
    print(triad_roots_by_quality(CHORDS))
```

```text
> uv run python solutions/l03_ex2_triads.py
{'major': ['C', 'D'], 'minor': ['A', 'E']}
```

A plain loop for the grouping, and a dict comprehension for the order: iterating over `sorted(groups)` sorts the keys, and the new dict keeps that order. A single comprehension would need `itertools.groupby` over data sorted by quality, which is shorter and harder to read. `type Chord = …` declares a type alias, the syntax of Python 3.12 ([PEP 695](https://peps.python.org/pep-0695/)), like C#'s `using Chord = …`.

</details>

3. Rewrite the `where` filter of GA's [`epistemic_agent.py`, lines 36-69](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L36-L69) as a function `where(beliefs, clause)` that returns the matching beliefs, without an `if`/`elif` per operator. `=` and `!=` compare text, the other operators compare numbers, and a belief whose field is missing or not a number doesn't match.

<details>
<summary>Solution</summary>

A dict from operator to function, taken from the [`operator`](https://docs.python.org/3.14/library/operator.html) module, and a list comprehension. [`solutions/l03_ex3_where.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l03_ex3_where.py):

```python
# solutions/l03_ex3_where.py
import operator
from collections.abc import Callable
from typing import Any

# One entry per operator, longest first, so that ">=" is found before ">"
NUMERIC: dict[str, Callable[[float, float], bool]] = {
    ">=": operator.ge,
    "<=": operator.le,
    ">": operator.gt,
    "<": operator.lt,
}
TEXT: dict[str, Callable[[str, str], bool]] = {"!=": operator.ne, "=": operator.eq}


def parse_where(clause: str) -> tuple[str, str, str]:
    for op in [*NUMERIC, *TEXT]:
        if op in clause:
            field, value = clause.split(op, 1)
            return field.strip(), op, value.strip().strip("'\"")
    raise ValueError(f"no operator in {clause!r}")


def matches(actual: Any, op: str, value: str) -> bool:
    if actual is None:
        return False
    if op in TEXT:
        return TEXT[op](str(actual), value)
    try:
        return NUMERIC[op](float(actual), float(value))
    except (ValueError, TypeError):
        return False


def where(beliefs: list[dict[str, Any]], clause: str) -> list[dict[str, Any]]:
    field, op, value = parse_where(clause)
    return [belief for belief in beliefs if matches(belief.get(field), op, value)]


if __name__ == "__main__":
    beliefs: list[dict[str, Any]] = [
        {"name": "a", "confidence": 0.9, "truth": "T"},
        {"name": "b", "confidence": 0.4, "truth": "U"},
        {"name": "c", "truth": "C"},
        {"name": "d", "confidence": "high", "truth": "T"},
    ]
    for clause in ["confidence >= 0.5", "truth != T", "truth = 'T'"]:
        print(clause, "->", [belief["name"] for belief in where(beliefs, clause)])
```

```text
> uv run python solutions/l03_ex3_where.py
confidence >= 0.5 -> ['a']
truth != T -> ['b', 'c']
truth = 'T' -> ['a', 'd']
```

`[*NUMERIC, *TEXT]` unpacks the keys of both dicts into one list, in insertion order, which is why `>=` comes before `>` and `!=` before `=`: GA's list relies on the same order. Belief `d`, whose confidence is `"high"`, doesn't match a numeric clause: the `except` is still there, but it now returns a clear `False` in a function whose purpose is to decide, instead of `continue` in the middle of a loop. [`tests/test_l03.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/tests/test_l03.py) runs four clauses through one test with `pytest.mark.parametrize`, the equivalent of xUnit's `[Theory]`.

</details>

## Sources

- [Python — Built-in types](https://docs.python.org/3.14/library/stdtypes.html): numeric types, sequence types, text sequence type, set types, mapping types
- [Python tutorial — Data structures](https://docs.python.org/3.14/tutorial/datastructures.html), [Floating-point arithmetic: issues and limitations](https://docs.python.org/3.14/tutorial/floatingpoint.html)
- [`decimal`](https://docs.python.org/3.14/library/decimal.html), [`collections`](https://docs.python.org/3.14/library/collections.html), [`itertools`](https://docs.python.org/3.14/library/itertools.html), [`operator`](https://docs.python.org/3.14/library/operator.html), [`copy`](https://docs.python.org/3.14/library/copy.html)
- [Python — Lexical analysis: f-strings and escape sequences](https://docs.python.org/3.14/reference/lexical_analysis.html#escape-sequences), [Displays for lists, sets and dictionaries](https://docs.python.org/3.14/reference/expressions.html#displays-for-lists-sets-and-dictionaries)
- [PEP 585 — Type hinting generics in standard collections](https://peps.python.org/pep-0585/), [PEP 695 — Type parameter syntax](https://peps.python.org/pep-0695/)
- [Microsoft — `String.GetHashCode`](https://learn.microsoft.com/dotnet/api/system.string.gethashcode), [`Dictionary.Remove`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2.remove), [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/)
- [Java — `java.util.stream`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html), [`List.subList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#subList(int,int)), [`Math.floorMod`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Math.html#floorMod(int,int))
