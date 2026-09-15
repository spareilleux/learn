---
title: 3. Tipos integrados y colecciones
description: Números que no desbordan y redondean al par más cercano, cadenas y f-strings, list, tuple, dict y set, slices y desempaquetado, comprensiones donde C# escribe LINQ y Java escribe streams, agrupación, hashing y las trampas de las filas compartidas — comparado con las colecciones de .NET y Java.
sidebar:
  order: 3
---

Código: los archivos [`examples/l03_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples) y [`errors/l03_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/errors), y los equivalentes en C# y Java en [`compare/l03_numbers.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l03_numbers.cs), [`compare/L03Numbers.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Numbers.java), [`compare/l03_linq.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l03_linq.cs), [`compare/L03Streams.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Streams.java), [`compare/l03_modify.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l03_modify.cs) y [`compare/L03Modify.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Modify.java).

## Números

Python tiene tres tipos numéricos integrados: `int`, de tamaño ilimitado, `float`, un double IEEE 754 de 64 bits como el `double` de C#, y `complex`. La biblioteca estándar añade [`decimal.Decimal`](https://docs.python.org/3.14/library/decimal.html) y [`fractions.Fraction`](https://docs.python.org/3.14/library/fractions.html). Los operadores aritméticos guardan algunas sorpresas para un desarrollador C# o Java:

```python
# examples/l03_numbers.py
import math
from decimal import ROUND_HALF_UP, Decimal

# La división entera redondea hacia menos infinito, y % toma el signo del divisor
print(7 // 2, -7 // 2, -7 % 2)
print(int(-7 / 2), math.fmod(-7, 2))  # truncamiento, como dividen C# y Java
print(7 / 2, 6 / 2)  # / siempre da un float

print(2**64, (2**64).bit_length())
print(0.1 + 0.2, 0.1 + 0.2 == 0.3, math.isclose(0.1 + 0.2, 0.3))

# round() redondea al par más cercano, y un literal float rara vez es el decimal que parece
print(round(2.5), round(3.5), round(2.675, 2), Decimal(2.675))

# Las púas de la lección 1: 50 a 0.50, más un 15 % de impuestos, menos un 10 %
total = (0.50 + 0.50 * 0.15) * 50 * 0.9  # la fórmula de la lección 1
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
// La división entera trunca hacia cero, y % toma el signo del dividendo
Console.WriteLine($"{7 / 2} {-7 / 2} {-7 % 2}");

// Math.Round también redondea al par más cercano por defecto; decimal es exacto para las fracciones decimales
Console.WriteLine($"{Math.Round(2.5)} {Math.Round(3.5)} {Math.Round(2.5, MidpointRounding.AwayFromZero)}");
Console.WriteLine($"{0.1 + 0.2} {0.1m + 0.2m}");

// int tiene 32 bits: sin checked, da la vuelta
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
| `-7 / 2` sobre enteros | `-3`, truncado | `-3`, truncado | `-3.5`: `/` siempre es la división real |
| División entera | `/` | `/`, o `Math.floorDiv` | `//`, redondeado hacia menos infinito: `-4` |
| `-7 % 2` | `-1`, el signo del dividendo | `-1`, o `Math.floorMod`: `1` | `1`, el signo del divisor |
| `int.MaxValue + 1` | da la vuelta a `-2147483648` | da la vuelta | sin máximo: `2**64` es exacto |
| Redondear 2.5 | `Math.Round`: `2`, al par más cercano | `Math.round`: `3`, hacia arriba | `round`: `2`, al par más cercano |
| Decimal exacto | `decimal`, una palabra clave y un literal `0.1m` | `BigDecimal` | `Decimal("0.1")`, a partir de una cadena |

`//` y `%` son coherentes entre sí: `(a // b) * b + a % b == a` siempre se cumple, y `-7 % 12` vale `5`, que es la respuesta correcta para la clase de altura situada siete semitonos por debajo de do. Java añadió `Math.floorDiv` y `Math.floorMod` por la misma razón.

`round(2.675, 2)` da `2.67` porque el literal `2.675` es el float binario `2.67499999999999982…`, que `Decimal(2.675)` muestra cifra a cifra. Las púas de la lección 1 imprimieron `25.87` por la misma razón: el cálculo en float da `25.874999999999996`, y el total exacto, `25.875`, solo existe como `Decimal`. Un `Decimal` debe construirse a partir de una cadena, no de un float que ya ha perdido el valor, y `quantize` lo redondea a céntimos con la regla que elijas. El dinero es `Decimal`, como es `decimal` en C#.

## Cadenas

Un `str` es una secuencia inmutable de puntos de código Unicode. A diferencia del `string` de C#, que contiene unidades de código UTF-16, `len` cuenta puntos de código, y el acceso por índice devuelve una cadena de longitud uno, ya que no hay tipo `char`:

```python
# examples/l03_strings.py
import re

chord = "Cmaj7"
print(chord[0], chord[-1], chord[1:4], len(chord))  # un str es una secuencia de caracteres
print("maj" in chord, chord.startswith("C"), chord.upper())

notes = "C,E,G,B".split(",")
print(notes, " - ".join(notes))

price, quantity = 9.99, 2
print(f"{quantity} x {price:.2f} = {price * quantity:>8.2f}")
print(f"{quantity=}, {price * quantity=:.3f}")  # = imprime también la expresión

# Una cadena sin procesar conserva las barras invertidas tal cual, que es lo que necesita una expresión regular
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

Una [f-string](https://docs.python.org/3.14/reference/lexical_analysis.html#f-strings) es la cadena interpolada de C#: `f"{price:.2f}"` es `$"{price:F2}"`, y la especificación de formato después de los dos puntos sigue el [minilenguaje de formato](https://docs.python.org/3.14/library/string.html#format-specification-mini-language) de Python, donde `>8` alinea a la derecha en ocho caracteres. `{quantity=}` imprime la expresión y su valor, lo que resulta práctico para depurar. `join` es un método del separador, no de la lista: `" - ".join(notes)` es `string.Join(" - ", notes)`.

El prefijo `r` crea una *cadena sin procesar* (*raw string*), donde una barra invertida es un carácter normal, como en la cadena literal `@"…"` de C#. Sin él, Python interpreta las secuencias de escape, y una desconocida se conserva pero se señala:

```python
# errors/l03_escape.py
import re

pattern = "^https?://.*/(api|v\d+)/"  # \d no es una secuencia de escape de una cadena Python
print(pattern)
print(bool(re.match(pattern, "https://example.com/v2/chords")))

text = "C:\new\tabs"  # \n y \t son secuencias de escape: un salto de línea y una tabulación
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

El patrón todavía funciona hoy, ya que Python conserva un escape desconocido como una barra invertida y una letra, pero la advertencia dice que se convertirá en un error. La ruta de Windows muestra la trampa contraria, donde `\n` y `\t` son escapes válidos y cambian el texto en silencio. C# rechaza un escape desconocido en tiempo de compilación (`CS1009`). mypy no informa de nada en ninguno de los dos casos.

## Las cuatro colecciones

| Python | C# | Java | Literal | Mutable | Ordenada |
|---|---|---|---|---|---|
| `list` | `List<T>` | `ArrayList<E>` | `["E", "A"]` | sí | por posición |
| `tuple` | `ValueTuple`, `ImmutableArray<T>` | `List.of`, records | `("C", "E", "G")` | no | por posición |
| `dict` | `Dictionary<K, V>` | `LinkedHashMap<K, V>` | `{"C": 0, "E": 4}` | sí | por inserción |
| `set` | `HashSet<T>` | `HashSet<E>` | `{"E", "A"}` | sí | no |
| `frozenset` | `ImmutableHashSet<T>` | `Set.of` | `frozenset(...)` | no | no |

Una misma lista puede contener objetos de tipos distintos, ya que la lista guarda referencias a objetos; una anotación como `list[str]` indica lo que contiene, para mypy. `{}` es un `dict` vacío, no un set vacío, que es `set()`.

```python
# examples/l03_collections.py
tuning = ["E", "A", "D", "G", "B", "E"]  # list: un array que puede crecer, como List<T> y ArrayList
c_major = ("C", "E", "G")  # tuple: una secuencia fija que no se puede modificar
intervals = {"C": 0, "E": 4, "G": 7}  # dict: una tabla hash que conserva el orden de inserción
open_notes = set(tuning)  # set: un conjunto hash, sin duplicados

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

# Las colecciones se comparan por valor
print([1, 2] == [1, 2], (1, 2) == (1, 2), {"a": 1, "b": 2} == {"b": 2, "a": 1})

# Desempaquetado
first, *middle, last = tuning
print(first, middle, last)
root, third, fifth = c_major
third, fifth = fifth, third  # un intercambio, a través de una tupla
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

`in` funciona sobre todas las colecciones: posición por posición para una lista o una tupla, por hash para un dict (sus claves) o un set. Un `dict` conserva el orden en que se insertaron las claves, una garantía del lenguaje desde Python 3.7, así que desempeña a la vez el papel de `Dictionary` y de `LinkedHashMap`. Los sets tienen operadores, `&` para la intersección, `|` para la unión y `-` para la diferencia, donde C# llama a `IntersectWith`.

El desempaquetado asigna los elementos de cualquier secuencia a varios nombres a la vez, y `*middle` recoge el resto en una lista. `third, fifth = fifth, third` construye la tupla de la derecha y luego la desempaqueta, que es como Python intercambia valores sin variable temporal, como `(a, b) = (b, a)` en C#.

### El orden de un set cambia de una ejecución a otra

El set de arriba se imprimió a través de `sorted`, y no por casualidad. El hash de un `str` se sala con un valor aleatorio elegido al arrancar el intérprete, para dificultar los ataques de denegación de servicio mediante colisiones de hash, así que el orden de un set de cadenas cambia de un proceso a otro. La variable de entorno [`PYTHONHASHSEED`](https://docs.python.org/3.14/using/cmdline.html#envvar-PYTHONHASHSEED) fija la sal, lo que hace visible el efecto:

```text
> PYTHONHASHSEED=1 uv run python -c "print({'E', 'A', 'D', 'G', 'B'})"
{'G', 'B', 'A', 'D', 'E'}
> PYTHONHASHSEED=2 uv run python -c "print({'E', 'A', 'D', 'G', 'B'})"
{'D', 'G', 'E', 'B', 'A'}
```

Sin la variable, cada ejecución imprime uno de esos órdenes u otro. .NET también aleatoriza [`string.GetHashCode`](https://learn.microsoft.com/dotnet/api/system.string.gethashcode) por proceso, y su documentación advierte contra la persistencia de los códigos hash. No imprimas un set, ni lo recorras, donde el orden importa: ordénalo. Un `dict` no tiene este problema, ya que su orden es el de inserción.

## Slices

`sequence[start:stop:step]` toma una parte de una lista, una tupla o una cadena. El inicio se incluye, el final se excluye, los índices negativos cuentan desde el final, y cualquier parte se puede omitir:

```python
# examples/l03_slicing.py
tuning = ["E", "A", "D", "G", "B", "E"]
print(tuning[1:3], tuning[:2], tuning[4:], tuning[-2:], tuning[::2], tuning[::-1])
print(tuning[10:], tuning[-100:2])  # un slice fuera de la lista está vacío o acortado, nunca es un error

bass = tuning[:3]  # un slice es una lista nueva
bass[0] = "D"
print(bass, tuning)

tuning[3:] = ["G", "A", "D"]  # la asignación a un slice sustituye una parte de la lista en el sitio
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

Los rangos de C#, `tuning[1..3]` y `tuning[^2..]`, tomaron prestada esta sintaxis, y como en Python copian un array o una lista. El [`subList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#subList(int,int)) de Java es en cambio una vista, donde escribir en la parte escribe en la lista; la última línea de `L03Modify.java`, más abajo, lo muestra. Un índice fuera de una lista lanza `IndexError`, pero un slice fuera de ella se acorta sin decir nada.

## Comprensiones en lugar de LINQ

Una **comprensión** construye una lista, un dict o un set a partir de un iterable, con una expresión, una o varias cláusulas `for` y cláusulas `if` opcionales. Es el equivalente en Python de una consulta LINQ o de un pipeline de streams, escrito en el orden de los bucles que sustituye:

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

# SelectMany + Distinct, flatMap + distinct: dos cláusulas for, en el orden de los bucles anidados
all_notes = sorted({note for _, _, notes in CHORDS for note in notes})
print(all_notes)

# Any, All, Sum, Max: funciones que consumen una expresión generadora
print(any(len(notes) == 4 for _, _, notes in CHORDS), all("E" in notes for _, _, notes in CHORDS))
print(sum(len(notes) for _, _, notes in CHORDS))
print(max(CHORDS, key=lambda chord: len(chord[2])))  # el primero de los más grandes

# OrderByDescending + ThenBy: una sola clave, una tupla, comparada elemento a elemento
for root, quality, notes in sorted(CHORDS, key=lambda chord: (-len(chord[2]), chord[0])):
    print(f"{root:<2} {quality:<11} {' '.join(notes)}")

# zip empareja los elementos, y enumerate los numera
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

Las mismas consultas con LINQ, y con streams en [`compare/L03Streams.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/L03Streams.java), dan los mismos resultados:

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
Console.WriteLine($"{largest.Root} {largest.Quality}"); // el primero de los más grandes

foreach (var c in chords.OrderByDescending(c => c.Notes.Length).ThenBy(c => c.Root, StringComparer.Ordinal))
{
    Console.WriteLine($"{c.Root,-2} {c.Quality,-11} {string.Join(" ", c.Notes)}");
}

// GroupBy conserva el orden en que aparece cada clave por primera vez, y no necesita datos ordenados
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
| `Where(c => …)` | `filter` | cláusula `if` |
| `Select(c => …)` | `map` | la expresión antes de `for` |
| `SelectMany` | `flatMap` | una segunda cláusula `for` |
| `ToDictionary`, `ToHashSet` | `Collectors.toMap`, `toSet` | `{k: v for …}`, `{x for …}` |
| `Any`, `All`, `Sum`, `Count(pred)` | `anyMatch`, `allMatch`, `sum`, `count` | `any(…)`, `all(…)`, `sum(…)`, `sum(1 for … if …)` |
| `MaxBy`, `MinBy` | `max(Comparator)` | `max(…, key=…)`, `min(…, key=…)` |
| `OrderBy`, `ThenByDescending` | `sorted(Comparator…thenComparing)` | `sorted(…, key=…, reverse=…)`, con una tupla como clave |
| `Zip`, `Select((x, i) => …)` | — | `zip`, `enumerate` |
| `GroupBy` | `Collectors.groupingBy` | `defaultdict(list)`, o `itertools.groupby` sobre datos ordenados (más abajo) |
| `Aggregate` | `reduce` | `functools.reduce`, normalmente un bucle |

Cuatro cosas difieren de LINQ:

- Una comprensión de lista, de dict o de set se ejecuta **de inmediato** y construye toda la colección, donde una consulta LINQ se ejecuta cuando se enumera. La forma perezosa es una **expresión generadora**, la misma sintaxis entre paréntesis, que `any`, `sum` y `max` consumen sin construir una lista. La lección 10 trata los generadores.
- `sorted` recibe una función `key`, que devuelve el valor que se compara, en lugar de un comparador. Una tupla se compara elemento a elemento, así que `(-len(notes), root)` significa "primero las que tienen más notas, luego por fundamental". La ordenación es estable, como `OrderBy` y a diferencia de `List<T>.Sort`.
- `zip(..., strict=True)` lanza `ValueError` cuando las secuencias no tienen la misma longitud; sin `strict`, se detiene sin decir nada en la más corta, como el `Zip` de LINQ.
- El guion bajo `_` es solo un nombre, usado por convención para un valor que se ignora.

Una comprensión de más de una línea o con condiciones anidadas se lee peor que el bucle que sustituye. PEP 8 no fija un límite; la regla habitual es dos cláusulas `for` o un `if` como mucho.

## Agrupar y contar

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

# GroupBy con un dict de listas: defaultdict crea la lista la primera vez que se usa una clave
by_quality: defaultdict[str, list[str]] = defaultdict(list)
for root, quality in CHORDS:
    by_quality[quality].append(root)
print(dict(by_quality))

# Recuento por clave
counts = Counter(quality for _, quality in CHORDS)
print(counts.most_common(2), counts["minor"], counts["diminished"])

# itertools.groupby solo agrupa elementos consecutivos, así que los datos deben ordenarse antes por la misma clave
print([(quality, len(list(group))) for quality, group in groupby(CHORDS, key=lambda chord: chord[1])])
ordered = sorted(CHORDS, key=lambda chord: chord[1])
print([(quality, [root for root, _ in group]) for quality, group in groupby(ordered, key=lambda chord: chord[1])])

# Una comprensión se ejecuta de inmediato; una expresión generadora se ejecuta cuando se consume, y solo una vez
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

[`defaultdict(list)`](https://docs.python.org/3.14/library/collections.html#collections.defaultdict) llama a `list()` para crear el valor de una clave que falta, así que el bucle nunca comprueba si la clave existe; el resultado conserva el orden en que aparecieron por primera vez las cualidades, como hace el `GroupBy` de LINQ, mientras que el `groupingBy` de Java devolvió un `HashMap` en orden de hash. [`Counter`](https://docs.python.org/3.14/library/collections.html#collections.Counter) cuenta, y devuelve `0` para una clave que nunca ha visto en lugar de lanzar `KeyError`.

[`itertools.groupby`](https://docs.python.org/3.14/library/itertools.html#itertools.groupby) tiene el nombre del operador de LINQ y el comportamiento del comando Unix `uniq`: agrupa elementos *consecutivos* con la misma clave. Sobre los acordes sin ordenar hizo seis grupos de uno. Ordenados antes, da los grupos reales.

La última línea es la regla de los streams de Java en Python: una expresión generadora solo se puede consumir una vez, y el segundo `list(roots)` la encuentra vacía, sin error.

## Hashing, y modificar una colección mientras se recorre

Una clave de dict y un elemento de set deben ser **hashables**: su hash no debe cambiar nunca. Los tipos integrados inmutables son hashables, una tupla lo es si sus elementos lo son, y una lista no:

```python
# errors/l03_unhashable.py
voicings = {("x", 3, 2, 0, 1, 0): "C major"}  # una tupla de elementos hashables puede ser una clave
print(voicings[("x", 3, 2, 0, 1, 0)])

names = {["x", 3, 2, 0, 1, 0]: "C major"}  # una lista no: podría cambiar después de guardarse
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

El mensaje es nuevo en la 3.14; las versiones anteriores solo decían `unhashable type: 'list'`. C# aceptaría un `List<T>` como clave, con hash por referencia, y no encontraría nada al buscar una lista igual; Python rechaza una clave cuya igualdad de valor podría cambiar. mypy 2.3.1 aceptó este archivo.

Cambiar el tamaño de un dict mientras se recorre se detecta:

```python
# errors/l03_changed_size.py
stock = {"capo": 2, "strings": 0, "picks": 50, "tuner": 0}

print({name: count for name, count in stock.items() if count > 0})  # construir un dict nuevo en su lugar

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

// Desde .NET Core 3.0, se permite Remove durante la enumeración de un Dictionary
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

// GetRange copia, como un slice de Python
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

Las tres plataformas discrepan más de lo esperado. Java lanza una excepción para el map, y ofrece `values().removeIf`. .NET lanza una excepción para la lista, pero no para el diccionario: desde .NET Core 3.0, [`Dictionary.Remove`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2.remove) se puede llamar durante una enumeración. Python lanza una excepción para el dict; la comprensión de la primera línea, que construye un dict nuevo, es la respuesta idiomática, o un bucle sobre `list(stock.items())`, una copia. Para una lista, Python no lanza nada y se salta elementos, lo que es peor: recorre una copia, o construye una lista nueva.

## Filas compartidas

La multiplicación de una secuencia, `[0] * 4`, repite sus elementos, y los elementos son referencias. Con una lista de listas, todas las filas son la misma lista:

```python
# examples/l03_grid.py
# Un diapasón de 3 cuerdas y 4 trastes, donde 1 marca un dedo
shared = [[0] * 4] * 3  # el * exterior copia tres veces la referencia a una única lista interior
shared[0][2] = 1
print(shared)

grid = [[0] * 4 for _ in range(3)]  # la comprensión construye una lista interior nueva cada vez
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

Es otra vez la regla de la [lección 2](../02-execution-model/#nombres-no-cajas): no se copia nada a menos que algo lo copie. `[0] * 4` no tiene riesgo porque `0` es inmutable. Lo mismo vale para `list(tuning)`, `tuning[:]` y `dict(stock)`, que hacen copias **superficiales**: una colección exterior nueva que contiene los mismos objetos interiores. [`copy.deepcopy`](https://docs.python.org/3.14/library/copy.html) copia hasta el fondo.

## En proyectos reales

**El agente de gobernanza de GA** cuenta configuraciones de creencias a mano en [`src/agents/epistemic_agent.py`, líneas 86-100](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L86-L100), con `tensor_summary[config] = tensor_summary.get(config, 0) + 1` en un bucle, y luego `tensor_summary.get("C_T", 0)` para cada recuento: el trabajo de un `Counter` (ejercicio 1). El filtro `where` del mismo archivo, [líneas 36-69](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L36-L69), es una cadena de seis `if`/`elif` que añaden cada uno a una lista, y se traga los errores de conversión con `except (ValueError, TypeError): continue` (ejercicio 3).

**El script de cobertura de IX** importa `Dict`, `List` y `Optional` de `typing` ([`optick_coverage.py`, línea 29](https://github.com/GuitarAlchemist/ix/blob/2190c685e3664488c9a3d0c1388c96b868a178cb/crates/ix-optick-sae/python/optick_coverage.py#L29)). Desde Python 3.9 y [PEP 585](https://peps.python.org/pep-0585/), el `dict[str, list[int]]` integrado funciona en las anotaciones, y desde la 3.10 `int | None` sustituye a `Optional[int]`; los nombres antiguos siguen funcionando, y Ruff puede reescribirlos (lección 13).

**TARS** tiene herramientas que generan código a partir de plantillas guardadas en cadenas Python normales, y las expresiones regulares dentro de esas plantillas provocan la advertencia. El patrón de `errors/l03_escape.py` viene de [`tools/python/implementation-starter.py`, línea 184](https://github.com/GuitarAlchemist/tars/blob/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python/implementation-starter.py#L184), donde compilar el archivo con Python 3.14.7 imprime `SyntaxWarning: "\d" is an invalid escape sequence`; [`tools/python/meta-programming-demo.py`](https://github.com/GuitarAlchemist/tars/blob/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python/meta-programming-demo.py#L497) imprime la misma advertencia para `\w` en la línea 497, una cadena sin procesar `r'…'` escrita dentro de una plantilla que no lo es. El texto generado sigue siendo correcto, ya que Python conserva la barra invertida, hasta la versión en que la advertencia se convierta en un error.

## Puntos clave

- `int` no desborda, `/` siempre da un float, `//` y `%` redondean hacia menos infinito, y `round` redondea al par más cercano. El dinero es `Decimal`, construido a partir de cadenas.
- Usa una cadena sin procesar, `r"…"`, para las expresiones regulares y las rutas de Windows.
- `list`, `tuple`, `dict` y `set` cubren `List<T>`, las secuencias inmutables, `Dictionary` y `HashSet`. Un dict conserva el orden de inserción; un set de cadenas cambia de orden de una ejecución a otra.
- Los slices copian, y nunca lanzan una excepción por un límite fuera de rango.
- Las comprensiones sustituyen a `Where`, `Select`, `SelectMany` y `ToDictionary`, y se ejecutan de inmediato; las expresiones generadoras son la forma perezosa, consumida una sola vez. `sorted` recibe una `key`.
- Agrupa con `defaultdict(list)`, cuenta con `Counter`, y ordena antes de `itertools.groupby`.
- Las claves de un dict deben ser hashables. No modifiques un dict ni una lista mientras los recorres: construye uno nuevo.
- `[[0] * n] * m` repite una sola fila; construye las filas en una comprensión.

## Ejercicios

1. Reescribe el resumen de tensores de [`epistemic_agent.py`, líneas 86-100](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L86-L100) de GA como una función que recibe una lista de creencias y devuelve el mismo diccionario, donde una creencia sin `tensorConfig` cuenta como `U_U`.

<details>
<summary>Solución</summary>

[`solutions/l03_ex1_tensor.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l03_ex1_tensor.py):

```python
# solutions/l03_ex1_tensor.py
from collections import Counter


def tensor_summary(beliefs: list[dict[str, str]]) -> dict[str, object]:
    # Un Counter cuenta en una sola pasada, y devuelve 0 para una clave que nunca ha visto
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

`dict(distribution)` convierte el `Counter`, una subclase de `dict`, en un dict simple antes de que vaya a JSON, que de todos modos acepta los dos. El tipo de retorno `dict[str, object]` es honesto pero no preciso; la lección 6 lo sustituye por un `TypedDict`, cuyas claves tienen cada una un tipo.

</details>

2. Traduce esta consulta LINQ a Python, con los `CHORDS` de [`examples/l03_comprehensions.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples/l03_comprehensions.py): las fundamentales de los acordes de tres notas, agrupadas por cualidad, con las cualidades en orden alfabético.

```cs
var triads = chords
    .Where(c => c.Notes.Length == 3)
    .GroupBy(c => c.Quality)
    .OrderBy(g => g.Key)
    .ToDictionary(g => g.Key, g => g.Select(c => c.Root).ToList());
```

<details>
<summary>Solución</summary>

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

Un bucle simple para la agrupación, y una comprensión de dict para el orden: recorrer `sorted(groups)` ordena las claves, y el dict nuevo conserva ese orden. Una única comprensión necesitaría `itertools.groupby` sobre datos ordenados por cualidad, lo que es más corto y más difícil de leer. `type Chord = …` declara un alias de tipo, la sintaxis de Python 3.12 ([PEP 695](https://peps.python.org/pep-0695/)), como `using Chord = …` en C#.

</details>

3. Reescribe el filtro `where` de [`epistemic_agent.py`, líneas 36-69](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L36-L69) de GA como una función `where(beliefs, clause)` que devuelve las creencias que coinciden, sin un `if`/`elif` por operador. `=` y `!=` comparan texto, los demás operadores comparan números, y una creencia cuyo campo falta o no es un número no coincide.

<details>
<summary>Solución</summary>

Un dict de operador a función, con las funciones del módulo [`operator`](https://docs.python.org/3.14/library/operator.html), y una comprensión de lista. [`solutions/l03_ex3_where.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l03_ex3_where.py):

```python
# solutions/l03_ex3_where.py
import operator
from collections.abc import Callable
from typing import Any

# Una entrada por operador, las más largas primero, para que ">=" se encuentre antes que ">"
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

`[*NUMERIC, *TEXT]` desempaqueta las claves de los dos dicts en una sola lista, en orden de inserción, y por eso `>=` va antes de `>` y `!=` antes de `=`: la lista de GA depende del mismo orden. La creencia `d`, cuya confianza es `"high"`, no coincide con una cláusula numérica: el `except` sigue ahí, pero ahora devuelve un `False` claro en una función cuyo propósito es decidir, en lugar de un `continue` en medio de un bucle. [`tests/test_l03.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/tests/test_l03.py) pasa cuatro cláusulas por una sola prueba con `pytest.mark.parametrize`, el equivalente del `[Theory]` de xUnit.

</details>

## Fuentes

- [Python — Built-in types](https://docs.python.org/3.14/library/stdtypes.html): tipos numéricos, tipos secuencia, tipo secuencia de texto, tipos set, tipos mapping
- [Tutorial de Python — Data structures](https://docs.python.org/3.14/tutorial/datastructures.html), [Floating-point arithmetic: issues and limitations](https://docs.python.org/3.14/tutorial/floatingpoint.html)
- [`decimal`](https://docs.python.org/3.14/library/decimal.html), [`collections`](https://docs.python.org/3.14/library/collections.html), [`itertools`](https://docs.python.org/3.14/library/itertools.html), [`operator`](https://docs.python.org/3.14/library/operator.html), [`copy`](https://docs.python.org/3.14/library/copy.html)
- [Python — Lexical analysis: f-strings and escape sequences](https://docs.python.org/3.14/reference/lexical_analysis.html#escape-sequences), [Displays for lists, sets and dictionaries](https://docs.python.org/3.14/reference/expressions.html#displays-for-lists-sets-and-dictionaries)
- [PEP 585 — Type hinting generics in standard collections](https://peps.python.org/pep-0585/), [PEP 695 — Type parameter syntax](https://peps.python.org/pep-0695/)
- [Microsoft — `String.GetHashCode`](https://learn.microsoft.com/dotnet/api/system.string.gethashcode), [`Dictionary.Remove`](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2.remove), [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/)
- [Java — `java.util.stream`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html), [`List.subList`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/List.html#subList(int,int)), [`Math.floorMod`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Math.html#floorMod(int,int))
