---
title: 3. Types intégrés et collections
description: Des nombres qui ne débordent pas et arrondissent au pair le plus proche, les chaînes et les f-strings, list, tuple, dict et set, le slicing et le déballage, les compréhensions là où C# écrit du LINQ et Java des streams, le regroupement, le hachage et les pièges des lignes partagées — comparés aux collections de .NET et de Java.
sidebar:
  order: 3
---

Code : les fichiers [`examples/l03_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples) et [`errors/l03_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/errors), et les côtés C# et Java dans [`compare/l03_numbers.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l03_numbers.cs), [`compare/L03Numbers.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Numbers.java), [`compare/l03_linq.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l03_linq.cs), [`compare/L03Streams.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Streams.java), [`compare/l03_modify.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l03_modify.cs) et [`compare/L03Modify.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Modify.java).

## Les nombres

Python a trois types numériques intégrés : `int`, de taille illimitée, `float`, un double IEEE 754 sur 64 bits comme le `double` de C#, et `complex`. La bibliothèque standard ajoute [`decimal.Decimal`](https://docs.python.org/3.14/library/decimal.html) et [`fractions.Fraction`](https://docs.python.org/3.14/library/fractions.html). Les opérateurs arithmétiques réservent quelques surprises à un développeur C# ou Java :

```python
# examples/l03_numbers.py
import math
from decimal import ROUND_HALF_UP, Decimal

# La division entière arrondit vers moins l'infini, et % prend le signe du diviseur
print(7 // 2, -7 // 2, -7 % 2)
print(int(-7 / 2), math.fmod(-7, 2))  # troncature, comme divisent C# et Java
print(7 / 2, 6 / 2)  # / donne toujours un float

print(2**64, (2**64).bit_length())
print(0.1 + 0.2, 0.1 + 0.2 == 0.3, math.isclose(0.1 + 0.2, 0.3))

# round() arrondit au pair le plus proche, et un littéral float est rarement le décimal qu'il semble être
print(round(2.5), round(3.5), round(2.675, 2), Decimal(2.675))

# Les médiators de la leçon 1 : 50 à 0.50, plus 15 % de taxe, moins 10 %
total = (0.50 + 0.50 * 0.15) * 50 * 0.9  # la formule de la leçon 1
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
// La division entière tronque vers zéro, et % prend le signe du dividende
Console.WriteLine($"{7 / 2} {-7 / 2} {-7 % 2}");

// Math.Round arrondit aussi au pair le plus proche par défaut ; decimal est exact pour les fractions décimales
Console.WriteLine($"{Math.Round(2.5)} {Math.Round(3.5)} {Math.Round(2.5, MidpointRounding.AwayFromZero)}");
Console.WriteLine($"{0.1 + 0.2} {0.1m + 0.2m}");

// int a 32 bits : sans checked, il déborde en revenant au début
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
| `-7 / 2` sur des entiers | `-3`, tronqué | `-3`, tronqué | `-3.5` : `/` est toujours une vraie division |
| Division entière | `/` | `/`, ou `Math.floorDiv` | `//`, arrondie vers moins l'infini : `-4` |
| `-7 % 2` | `-1`, le signe du dividende | `-1`, ou `Math.floorMod` : `1` | `1`, le signe du diviseur |
| `int.MaxValue + 1` | revient à `-2147483648` | déborde en boucle | pas de maximum : `2**64` est exact |
| Arrondir 2.5 | `Math.Round` : `2`, au pair le plus proche | `Math.round` : `3`, vers le haut | `round` : `2`, au pair le plus proche |
| Décimal exact | `decimal`, un mot-clé et un littéral `0.1m` | `BigDecimal` | `Decimal("0.1")`, à partir d'une chaîne |

`//` et `%` sont cohérents entre eux : `(a // b) * b + a % b == a` est toujours vrai, et `-7 % 12` vaut `5`, ce qui est la bonne réponse pour une classe de hauteur sept demi-tons sous do. Java a ajouté `Math.floorDiv` et `Math.floorMod` pour la même raison.

`round(2.675, 2)` donne `2.67` parce que le littéral `2.675` est le flottant binaire `2.67499999999999982…`, que `Decimal(2.675)` montre chiffre par chiffre. Les médiators de la leçon 1 ont affiché `25.87` pour la même raison : le calcul en flottants donne `25.874999999999996`, et le total exact, `25.875`, n'existe que sous forme de `Decimal`. Un `Decimal` doit être construit à partir d'une chaîne, pas d'un flottant qui a déjà perdu la valeur, et `quantize` l'arrondit au centime avec la règle que tu choisis. L'argent, c'est `Decimal`, comme c'est `decimal` en C#.

## Les chaînes

Un `str` est une séquence immuable de points de code Unicode. Contrairement au `string` de C#, qui contient des unités de code UTF-16, `len` compte des points de code, et l'indexation renvoie une chaîne de longueur un, puisqu'il n'y a pas de type `char` :

```python
# examples/l03_strings.py
import re

chord = "Cmaj7"
print(chord[0], chord[-1], chord[1:4], len(chord))  # un str est une séquence de caractères
print("maj" in chord, chord.startswith("C"), chord.upper())

notes = "C,E,G,B".split(",")
print(notes, " - ".join(notes))

price, quantity = 9.99, 2
print(f"{quantity} x {price:.2f} = {price * quantity:>8.2f}")
print(f"{quantity=}, {price * quantity=:.3f}")  # = affiche aussi l'expression

# Une raw string garde les barres obliques inverses telles quelles, ce dont une expression régulière a besoin
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

Une [f-string](https://docs.python.org/3.14/reference/lexical_analysis.html#f-strings) est la chaîne interpolée de C# : `f"{price:.2f}"` correspond à `$"{price:F2}"`, et la spécification de format après le deux-points suit le [mini-langage de format](https://docs.python.org/3.14/library/string.html#format-specification-mini-language) de Python, où `>8` aligne à droite sur huit caractères. `{quantity=}` affiche l'expression et sa valeur, ce qui est pratique pour déboguer. `join` est une méthode du séparateur, pas de la liste : `" - ".join(notes)` correspond à `string.Join(" - ", notes)`.

Le préfixe `r` crée une *raw string*, où une barre oblique inverse est un caractère ordinaire, comme dans la chaîne verbatim `@"…"` de C#. Sans lui, Python interprète les séquences d'échappement, et une séquence inconnue est conservée mais signalée :

```python
# errors/l03_escape.py
import re

pattern = "^https?://.*/(api|v\d+)/"  # \d n'est pas une séquence d'échappement d'une chaîne Python
print(pattern)
print(bool(re.match(pattern, "https://example.com/v2/chords")))

text = "C:\new\tabs"  # \n et \t sont des séquences d'échappement : un saut de ligne et une tabulation
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

Le motif fonctionne encore aujourd'hui, puisque Python garde une séquence inconnue sous forme de barre oblique inverse suivie d'une lettre, mais l'avertissement dit qu'elle deviendra une erreur. Le chemin Windows montre le piège inverse, où `\n` et `\t` sont des séquences valides et changent le texte en silence. C# refuse une séquence d'échappement inconnue à la compilation (`CS1009`). mypy ne signale ni l'un ni l'autre.

## Les quatre collections

| Python | C# | Java | Littéral | Mutable | Ordonné |
|---|---|---|---|---|---|
| `list` | `List<T>` | `ArrayList<E>` | `["E", "A"]` | oui | par position |
| `tuple` | `ValueTuple`, `ImmutableArray<T>` | `List.of`, records | `("C", "E", "G")` | non | par position |
| `dict` | `Dictionary<K, V>` | `LinkedHashMap<K, V>` | `{"C": 0, "E": 4}` | oui | par insertion |
| `set` | `HashSet<T>` | `HashSet<E>` | `{"E", "A"}` | oui | non |
| `frozenset` | `ImmutableHashSet<T>` | `Set.of` | `frozenset(...)` | non | non |

Une même liste peut contenir des objets de types différents, puisque la liste stocke des références à des objets ; une annotation comme `list[str]` indique ce qu'elle contient, pour mypy. `{}` est un `dict` vide, pas un set vide, qui s'écrit `set()`.

```python
# examples/l03_collections.py
tuning = ["E", "A", "D", "G", "B", "E"]  # list : un tableau extensible, comme List<T> et ArrayList
c_major = ("C", "E", "G")  # tuple : une séquence fixe qui ne peut pas être modifiée
intervals = {"C": 0, "E": 4, "G": 7}  # dict : une table de hachage qui garde l'ordre d'insertion
open_notes = set(tuning)  # set : un ensemble haché, sans doublons

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

# Les collections se comparent par valeur
print([1, 2] == [1, 2], (1, 2) == (1, 2), {"a": 1, "b": 2} == {"b": 2, "a": 1})

# Déballage
first, *middle, last = tuning
print(first, middle, last)
root, third, fifth = c_major
third, fifth = fifth, third  # un échange, via un tuple
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

`in` fonctionne sur toutes les collections : position par position pour une liste ou un tuple, par hachage pour un dict (ses clés) ou un set. Un `dict` garde l'ordre dans lequel les clés ont été insérées, une garantie du langage depuis Python 3.7, donc il joue à la fois le rôle de `Dictionary` et de `LinkedHashMap`. Les sets ont des opérateurs, `&` pour l'intersection, `|` pour l'union et `-` pour la différence, là où C# appelle `IntersectWith`.

Le déballage (*unpacking*) assigne les éléments de n'importe quelle séquence à plusieurs noms à la fois, et `*middle` rassemble le reste dans une liste. `third, fifth = fifth, third` construit le tuple de droite, puis le déballe : c'est ainsi que Python échange deux valeurs sans variable temporaire, comme le `(a, b) = (b, a)` de C#.

### L'ordre d'un set change d'une exécution à l'autre

Le set ci-dessus a été affiché via `sorted`, et ce n'est pas un hasard. Le hachage d'un `str` est salé avec une valeur aléatoire choisie au démarrage de l'interpréteur, pour rendre plus difficiles les attaques par déni de service fondées sur les collisions de hachage, donc l'ordre d'un set de chaînes change d'un processus à l'autre. La variable d'environnement [`PYTHONHASHSEED`](https://docs.python.org/3.14/using/cmdline.html#envvar-PYTHONHASHSEED) fixe le sel, ce qui rend l'effet visible :

```text
> PYTHONHASHSEED=1 uv run python -c "print({'E', 'A', 'D', 'G', 'B'})"
{'G', 'B', 'A', 'D', 'E'}
> PYTHONHASHSEED=2 uv run python -c "print({'E', 'A', 'D', 'G', 'B'})"
{'D', 'G', 'E', 'B', 'A'}
```

Sans la variable, chaque exécution affiche l'un de ces ordres ou un autre. .NET rend lui aussi [`string.GetHashCode`](https://learn.microsoft.com/dotnet/api/system.string.gethashcode) aléatoire par processus, et sa documentation déconseille de persister les codes de hachage. N'affiche pas un set, et ne le parcours pas, là où l'ordre compte : trie-le. Un `dict` n'a pas ce problème, puisque son ordre est l'ordre d'insertion.

## Le slicing

`sequence[start:stop:step]` prend une partie d'une liste, d'un tuple ou d'une chaîne. Le début est inclus, la fin exclue, les index négatifs comptent à partir de la fin, et chaque partie peut être omise :

```python
# examples/l03_slicing.py
tuning = ["E", "A", "D", "G", "B", "E"]
print(tuning[1:3], tuning[:2], tuning[4:], tuning[-2:], tuning[::2], tuning[::-1])
print(tuning[10:], tuning[-100:2])  # une tranche hors de la liste est vide ou raccourcie, jamais une erreur

bass = tuning[:3]  # une tranche est une nouvelle liste
bass[0] = "D"
print(bass, tuning)

tuning[3:] = ["G", "A", "D"]  # l'assignation à une tranche remplace une partie de la liste en place
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

Les plages de C#, `tuning[1..3]` et `tuning[^2..]`, ont emprunté cette syntaxe, et comme en Python elles copient un tableau ou une liste. Le [`subList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#subList(int,int)) de Java est au contraire une vue, où écrire dans la partie écrit dans la liste ; la dernière ligne de `L03Modify.java`, plus bas, le montre. Un index hors d'une liste lève `IndexError`, mais une tranche qui en déborde est raccourcie sans bruit.

## Des compréhensions au lieu de LINQ

Une **compréhension** construit une liste, un dict ou un set à partir d'un itérable, avec une expression, une ou plusieurs clauses `for` et des clauses `if` optionnelles. C'est l'équivalent Python d'une requête LINQ ou d'un pipeline de streams, écrit dans l'ordre des boucles qu'il remplace :

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

# SelectMany + Distinct, flatMap + distinct : deux clauses for, dans l'ordre des boucles imbriquées
all_notes = sorted({note for _, _, notes in CHORDS for note in notes})
print(all_notes)

# Any, All, Sum, Max : des fonctions qui consomment une expression génératrice
print(any(len(notes) == 4 for _, _, notes in CHORDS), all("E" in notes for _, _, notes in CHORDS))
print(sum(len(notes) for _, _, notes in CHORDS))
print(max(CHORDS, key=lambda chord: len(chord[2])))  # le premier des plus grands

# OrderByDescending + ThenBy : une seule clé, un tuple, comparé élément par élément
for root, quality, notes in sorted(CHORDS, key=lambda chord: (-len(chord[2]), chord[0])):
    print(f"{root:<2} {quality:<11} {' '.join(notes)}")

# zip associe les éléments deux à deux, et enumerate les numérote
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

Les mêmes requêtes avec LINQ, et avec des streams dans [`compare/L03Streams.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Streams.java), donnent les mêmes résultats :

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
Console.WriteLine($"{largest.Root} {largest.Quality}"); // le premier des plus grands

foreach (var c in chords.OrderByDescending(c => c.Notes.Length).ThenBy(c => c.Root, StringComparer.Ordinal))
{
    Console.WriteLine($"{c.Root,-2} {c.Quality,-11} {string.Join(" ", c.Notes)}");
}

// GroupBy garde l'ordre de première apparition de chaque clé, et n'a pas besoin de données triées
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
| `Where(c => …)` | `filter` | clause `if` |
| `Select(c => …)` | `map` | l'expression avant `for` |
| `SelectMany` | `flatMap` | une seconde clause `for` |
| `ToDictionary`, `ToHashSet` | `Collectors.toMap`, `toSet` | `{k: v for …}`, `{x for …}` |
| `Any`, `All`, `Sum`, `Count(pred)` | `anyMatch`, `allMatch`, `sum`, `count` | `any(…)`, `all(…)`, `sum(…)`, `sum(1 for … if …)` |
| `MaxBy`, `MinBy` | `max(Comparator)` | `max(…, key=…)`, `min(…, key=…)` |
| `OrderBy`, `ThenByDescending` | `sorted(Comparator…thenComparing)` | `sorted(…, key=…, reverse=…)`, avec un tuple comme clé |
| `Zip`, `Select((x, i) => …)` | — | `zip`, `enumerate` |
| `GroupBy` | `Collectors.groupingBy` | `defaultdict(list)`, ou `itertools.groupby` sur des données triées (plus bas) |
| `Aggregate` | `reduce` | `functools.reduce`, généralement une boucle |

Quatre choses diffèrent de LINQ :

- Une compréhension de liste, de dict ou de set s'exécute **immédiatement** et construit toute la collection, là où une requête LINQ s'exécute quand on l'énumère. La forme paresseuse est une **expression génératrice**, la même syntaxe entre parenthèses, que `any`, `sum` et `max` consomment sans construire de liste. La leçon 10 couvre les générateurs.
- `sorted` prend une fonction `key`, qui renvoie la valeur à comparer, plutôt qu'un comparateur. Un tuple se compare élément par élément, donc `(-len(notes), root)` signifie « le plus de notes d'abord, puis par fondamentale ». Le tri est stable, comme `OrderBy` et contrairement à `List<T>.Sort`.
- `zip(..., strict=True)` lève `ValueError` quand les séquences n'ont pas la même longueur ; sans `strict`, il s'arrête en silence à la plus courte, comme le `Zip` de LINQ.
- Le tiret bas `_` n'est qu'un nom, utilisé par convention pour une valeur ignorée.

Une compréhension de plus d'une ligne ou avec des conditions imbriquées se lit moins bien que la boucle qu'elle remplace. La PEP 8 ne fixe pas de limite ; la règle habituelle est deux clauses `for` ou un `if` au plus.

## Grouper et compter

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

# GroupBy avec un dict de listes : defaultdict crée la liste la première fois qu'une clé est utilisée
by_quality: defaultdict[str, list[str]] = defaultdict(list)
for root, quality in CHORDS:
    by_quality[quality].append(root)
print(dict(by_quality))

# Compte par clé
counts = Counter(quality for _, quality in CHORDS)
print(counts.most_common(2), counts["minor"], counts["diminished"])

# itertools.groupby ne regroupe que les éléments consécutifs, donc les données doivent d'abord être triées par la même clé
print([(quality, len(list(group))) for quality, group in groupby(CHORDS, key=lambda chord: chord[1])])
ordered = sorted(CHORDS, key=lambda chord: chord[1])
print([(quality, [root for root, _ in group]) for quality, group in groupby(ordered, key=lambda chord: chord[1])])

# Une compréhension s'exécute immédiatement ; une expression génératrice s'exécute quand elle est consommée, et une seule fois
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

[`defaultdict(list)`](https://docs.python.org/3.14/library/collections.html#collections.defaultdict) appelle `list()` pour créer la valeur d'une clé manquante, donc la boucle ne vérifie jamais si la clé existe ; le résultat garde l'ordre dans lequel les qualités sont apparues pour la première fois, comme le fait le `GroupBy` de LINQ, alors que le `groupingBy` de Java a renvoyé une `HashMap` dans l'ordre des hachages. [`Counter`](https://docs.python.org/3.14/library/collections.html#collections.Counter) compte, et renvoie `0` pour une clé qu'il n'a jamais vue au lieu de lever `KeyError`.

[`itertools.groupby`](https://docs.python.org/3.14/library/itertools.html#itertools.groupby) a le nom de l'opérateur de LINQ et le comportement de la commande Unix `uniq` : il regroupe les éléments *consécutifs* qui ont la même clé. Sur les accords non triés, il a formé six groupes d'un élément. Après un tri, il donne les vrais groupes.

La dernière ligne est la règle des streams Java appliquée à Python : une expression génératrice ne peut être consommée qu'une fois, et le second `list(roots)` la trouve vide, sans erreur.

## Le hachage, et modifier une collection pendant l'itération

Une clé de dict et un élément de set doivent être **hachables** : leur hachage ne doit jamais changer. Les types intégrés immuables sont hachables, un tuple l'est si ses éléments le sont, et une liste ne l'est pas :

```python
# errors/l03_unhashable.py
voicings = {("x", 3, 2, 0, 1, 0): "C major"}  # un tuple d'éléments hachables peut être une clé
print(voicings[("x", 3, 2, 0, 1, 0)])

names = {["x", 3, 2, 0, 1, 0]: "C major"}  # une liste ne le peut pas : elle pourrait changer après avoir été stockée
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

Le message est nouveau en 3.14 ; les versions précédentes disaient seulement `unhashable type: 'list'`. C# accepterait une `List<T>` comme clé, hachée par référence, et ne trouverait rien en cherchant une liste égale ; Python refuse une clé dont l'égalité de valeur pourrait changer. mypy 2.3.1 a accepté ce fichier.

Modifier la taille d'un dict pendant qu'on le parcourt est détecté :

```python
# errors/l03_changed_size.py
stock = {"capo": 2, "strings": 0, "picks": 50, "tuner": 0}

print({name: count for name, count in stock.items() if count > 0})  # construire plutôt un nouveau dict

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

// Depuis .NET Core 3.0, Remove pendant l'énumération d'un Dictionary est autorisé
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

// GetRange copie, comme une tranche Python
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

Les trois plateformes divergent plus que prévu. Java lève une exception pour la map, et propose `values().removeIf`. .NET lève une exception pour la liste, mais pas pour le dictionnaire : depuis .NET Core 3.0, [`Dictionary.Remove`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2.remove) peut être appelé pendant une énumération. Python lève une exception pour le dict ; la compréhension de la première ligne, qui construit un nouveau dict, est la réponse idiomatique, ou une boucle sur `list(stock.items())`, une copie. Pour une liste, Python ne lève rien du tout et saute des éléments, ce qui est pire : parcours une copie, ou construis une nouvelle liste.

## Des lignes partagées

La multiplication d'une séquence, `[0] * 4`, répète ses éléments, et les éléments sont des références. Avec une liste de listes, toutes les lignes sont la même liste :

```python
# examples/l03_grid.py
# Un manche de 3 cordes et 4 cases, où 1 marque un doigt
shared = [[0] * 4] * 3  # le * externe copie trois fois la référence à une même liste interne
shared[0][2] = 1
print(shared)

grid = [[0] * 4 for _ in range(3)]  # la compréhension construit une nouvelle liste interne à chaque fois
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

C'est encore la règle de la [leçon 2](../02-execution-model/#des-noms-pas-des-boîtes) : rien n'est copié tant que quelque chose ne le copie pas. `[0] * 4` est sans danger parce que `0` est immuable. Il en va de même pour `list(tuning)`, `tuning[:]` et `dict(stock)`, qui font des copies **superficielles** : une nouvelle collection externe qui contient les mêmes objets internes. [`copy.deepcopy`](https://docs.python.org/3.14/library/copy.html) copie jusqu'au bout.

## Dans de vrais projets

**L'agent de gouvernance de GA** compte les configurations de croyances à la main dans [`src/agents/epistemic_agent.py`, lignes 86-100](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L86-L100), avec `tensor_summary[config] = tensor_summary.get(config, 0) + 1` dans une boucle, puis `tensor_summary.get("C_T", 0)` pour chaque compte : le travail d'un `Counter` (exercice 1). Le filtre `where` du même fichier, [lignes 36-69](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L36-L69), est une chaîne de six `if`/`elif` qui ajoutent chacun à une liste, et avale les erreurs de conversion avec `except (ValueError, TypeError): continue` (exercice 3).

**Le script de couverture d'IX** importe `Dict`, `List` et `Optional` depuis `typing` ([`optick_coverage.py`, ligne 29](https://github.com/GuitarAlchemist/ix/blob/2190c685e3664488c9a3d0c1388c96b868a178cb/crates/ix-optick-sae/python/optick_coverage.py#L29)). Depuis Python 3.9 et la [PEP 585](https://peps.python.org/pep-0585/), le type intégré `dict[str, list[int]]` fonctionne dans les annotations, et depuis 3.10 `int | None` remplace `Optional[int]` ; les anciens noms fonctionnent toujours, et Ruff peut les réécrire (leçon 13).

**TARS** a des outils qui génèrent du code à partir de modèles contenus dans des chaînes Python ordinaires, et les expressions régulières à l'intérieur de ces modèles déclenchent l'avertissement. Le motif d'`errors/l03_escape.py` vient de [`tools/python/implementation-starter.py`, ligne 184](https://github.com/GuitarAlchemist/tars/blob/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python/implementation-starter.py#L184), où compiler le fichier avec Python 3.14.7 affiche `SyntaxWarning: "\d" is an invalid escape sequence` ; [`tools/python/meta-programming-demo.py`](https://github.com/GuitarAlchemist/tars/blob/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python/meta-programming-demo.py#L497) affiche le même avertissement pour `\w` à la ligne 497, une raw string `r'…'` écrite à l'intérieur d'un modèle qui n'est pas lui-même une raw string. Le texte généré reste correct, puisque Python garde la barre oblique inverse, jusqu'à la version où l'avertissement deviendra une erreur.

## À retenir

- `int` ne déborde pas, `/` donne toujours un float, `//` et `%` arrondissent vers moins l'infini, et `round` arrondit au pair le plus proche. L'argent, c'est `Decimal`, construit à partir de chaînes.
- Utilise une raw string, `r"…"`, pour les expressions régulières et les chemins Windows.
- `list`, `tuple`, `dict` et `set` couvrent `List<T>`, les séquences immuables, `Dictionary` et `HashSet`. Un dict garde l'ordre d'insertion ; un set de chaînes change d'ordre d'une exécution à l'autre.
- Les tranches copient, et ne lèvent jamais d'exception pour une borne hors limites.
- Les compréhensions remplacent `Where`, `Select`, `SelectMany` et `ToDictionary`, et s'exécutent immédiatement ; les expressions génératrices en sont la forme paresseuse, consommée une seule fois. `sorted` prend une `key`.
- Regroupe avec `defaultdict(list)`, compte avec `Counter`, et trie avant `itertools.groupby`.
- Les clés d'un dict doivent être hachables. Ne modifie pas un dict ou une liste pendant que tu le parcours : construis-en un nouveau.
- `[[0] * n] * m` répète une seule ligne ; construis les lignes dans une compréhension.

## Exercices

1. Réécris le résumé des tenseurs de [`epistemic_agent.py`, lignes 86-100](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L86-L100), dans GA, sous forme d'une fonction qui prend une liste de croyances et renvoie le même dictionnaire, où une croyance sans `tensorConfig` compte comme `U_U`.

<details>
<summary>Solution</summary>

[`solutions/l03_ex1_tensor.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l03_ex1_tensor.py) :

```python
# solutions/l03_ex1_tensor.py
from collections import Counter


def tensor_summary(beliefs: list[dict[str, str]]) -> dict[str, object]:
    # Un Counter compte en une passe, et renvoie 0 pour une clé qu'il n'a jamais vue
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

`dict(distribution)` transforme le `Counter`, une sous-classe de `dict`, en dict ordinaire avant qu'il parte en JSON, qui accepte de toute façon les deux. Le type de retour `dict[str, object]` est honnête mais pas précis ; la leçon 6 le remplace par un `TypedDict`, dont chaque clé a un type.

</details>

2. Traduis cette requête LINQ en Python, avec les `CHORDS` d'[`examples/l03_comprehensions.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples/l03_comprehensions.py) : les fondamentales des accords de trois notes, regroupées par qualité, avec les qualités dans l'ordre alphabétique.

```cs
var triads = chords
    .Where(c => c.Notes.Length == 3)
    .GroupBy(c => c.Quality)
    .OrderBy(g => g.Key)
    .ToDictionary(g => g.Key, g => g.Select(c => c.Root).ToList());
```

<details>
<summary>Solution</summary>

[`solutions/l03_ex2_triads.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l03_ex2_triads.py) :

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

Une simple boucle pour le regroupement, et une compréhension de dict pour l'ordre : parcourir `sorted(groups)` trie les clés, et le nouveau dict garde cet ordre. Une compréhension unique demanderait `itertools.groupby` sur des données triées par qualité, ce qui est plus court et plus difficile à lire. `type Chord = …` déclare un alias de type, la syntaxe de Python 3.12 ([PEP 695](https://peps.python.org/pep-0695/)), comme le `using Chord = …` de C#.

</details>

3. Réécris le filtre `where` de [`epistemic_agent.py`, lignes 36-69](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L36-L69), dans GA, sous forme d'une fonction `where(beliefs, clause)` qui renvoie les croyances correspondantes, sans un `if`/`elif` par opérateur. `=` et `!=` comparent du texte, les autres opérateurs comparent des nombres, et une croyance dont le champ est absent ou n'est pas un nombre ne correspond pas.

<details>
<summary>Solution</summary>

Un dict qui associe à chaque opérateur une fonction, tirée du module [`operator`](https://docs.python.org/3.14/library/operator.html), et une compréhension de liste. [`solutions/l03_ex3_where.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l03_ex3_where.py) :

```python
# solutions/l03_ex3_where.py
import operator
from collections.abc import Callable
from typing import Any

# Une entrée par opérateur, la plus longue d'abord, pour que ">=" soit trouvé avant ">"
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

`[*NUMERIC, *TEXT]` déballe les clés des deux dicts dans une seule liste, dans l'ordre d'insertion, c'est pourquoi `>=` vient avant `>` et `!=` avant `=` : la liste de GA repose sur le même ordre. La croyance `d`, dont la confiance vaut `"high"`, ne correspond pas à une clause numérique : le `except` est toujours là, mais il renvoie maintenant un `False` clair dans une fonction dont le but est de décider, au lieu d'un `continue` au milieu d'une boucle. [`tests/test_l03.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/tests/test_l03.py) fait passer quatre clauses par un seul test avec `pytest.mark.parametrize`, l'équivalent du `[Theory]` de xUnit.

</details>

## Sources

- [Python — Types intégrés](https://docs.python.org/3.14/library/stdtypes.html) : types numériques, types séquence, type séquence de texte, types ensemble, types de correspondance
- [Tutoriel Python — Structures de données](https://docs.python.org/3.14/tutorial/datastructures.html), [Arithmétique en virgule flottante : problèmes et limites](https://docs.python.org/3.14/tutorial/floatingpoint.html)
- [`decimal`](https://docs.python.org/3.14/library/decimal.html), [`collections`](https://docs.python.org/3.14/library/collections.html), [`itertools`](https://docs.python.org/3.14/library/itertools.html), [`operator`](https://docs.python.org/3.14/library/operator.html), [`copy`](https://docs.python.org/3.14/library/copy.html)
- [Python — Analyse lexicale : f-strings et séquences d'échappement](https://docs.python.org/3.14/reference/lexical_analysis.html#escape-sequences), [Affichages de listes, d'ensembles et de dictionnaires](https://docs.python.org/3.14/reference/expressions.html#displays-for-lists-sets-and-dictionaries)
- [PEP 585 — Génériques dans les collections standard pour les annotations de type](https://peps.python.org/pep-0585/), [PEP 695 — Syntaxe des paramètres de type](https://peps.python.org/pep-0695/)
- [Microsoft — `String.GetHashCode`](https://learn.microsoft.com/dotnet/api/system.string.gethashcode), [`Dictionary.Remove`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2.remove), [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/)
- [Java — `java.util.stream`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html), [`List.subList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#subList(int,int)), [`Math.floorMod`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Math.html#floorMod(int,int))
