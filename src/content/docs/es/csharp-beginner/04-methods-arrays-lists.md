---
title: 4. Métodos, arrays y listas
description: Divide un programa en métodos con parámetros y valores de retorno, guarda muchos valores en arrays y en List<T>, y da un primer vistazo a null, el valor que significa «nada».
sidebar:
  order: 4
---

Código: los ejemplos [`examples/l04_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/examples), los fragmentos rechazados [`compile_fail/l04_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/compile_fail) y las soluciones [`exercises/l04_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises).

Los programas de la lección 3 repetían los mismos doce nombres de notas en varios sitios. Esta lección elimina esa repetición dos veces: un **método** da nombre a un trabajo, para que lo escribas una vez y lo llames muchas, y un **array** o una **lista** guarda muchos valores bajo un solo nombre.

## Métodos

Llevas llamando a métodos desde la lección 1: `Console.WriteLine`, `Math.Pow`, `int.TryParse`. Ahora escribes los tuyos.

```csharp
// Llamada a los métodos declarados más abajo
PrintTitle("Methods");
Console.WriteLine(Square(12));
Console.WriteLine(FretFrequency(110.0, 7));
Console.WriteLine(FretFrequency(82.41, 5));
Console.WriteLine(Describe(0));
Console.WriteLine(Describe(12));
Console.WriteLine(Repeat("la"));                 // valor por defecto para times
Console.WriteLine(Repeat("la", 3));
Console.WriteLine(Repeat(times: 2, text: "do")); // argumentos con nombre, en cualquier orden

// Un método sin resultado: su tipo de retorno es void
void PrintTitle(string title)
{
    Console.WriteLine($"== {title} ==");
}

// Un método que devuelve un int
int Square(int x)
{
    return x * x;
}

// Un método con dos parámetros, redondeado a dos decimales
double FretFrequency(double openString, int fret)
{
    double frequency = openString * Math.Pow(2, fret / 12.0);
    return Math.Round(frequency, 2);
}

// return sale del método de inmediato
string Describe(int fret)
{
    if (fret == 0)
    {
        return "open string";
    }
    return $"fret {fret}";
}

// Un parámetro opcional, y un cuerpo escrito como una sola expresión con =>
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

La declaración de un método tiene cuatro partes:

```text
double  FretFrequency  (double openString, int fret)  { … return …; }
  │          │                    │                         │
return     name              parameters                   body
 type
```

- El **tipo de retorno** (*return type*) es el tipo del resultado: `int`, `double`, `string`… o `void` cuando el método no devuelve nada y solo hace algo, como imprimir.
- El **nombre** (*name*) empieza por mayúscula, por convención, y normalmente por un verbo: `PrintTitle`, `Describe`.
- Los **parámetros** (*parameters*) son variables que reciben los valores que da quien llama, los *argumentos*. `FretFrequency(110.0, 7)` pone `110.0` en `openString` y `7` en `fret`, en ese orden.
- El **cuerpo** (*body*) hace el trabajo. [`return`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/jump-statements#the-return-statement) devuelve el resultado a quien llama y sale del método de inmediato: en `Describe(0)`, nunca se llega al segundo `return`.

El traste 5 de la cuerda Mi grave, a 82.41 Hz, es un La a 110 Hz: la nota de la cuerda La al aire. Así afinan los guitarristas la quinta cuerda a partir de la sexta.

Tres comodidades:

- Un parámetro con **valor por defecto**, `int times = 2`, se puede omitir: `Repeat("la")` usa 2.
- Los **argumentos con nombre**, `times: 2, text: "do"`, indican qué parámetro recibe qué valor, en cualquier orden.
- Cuando el cuerpo es una sola expresión, `=>` sustituye a las llaves y al `return`: es un [miembro con cuerpo de expresión](https://learn.microsoft.com/dotnet/csharp/programming-guide/statements-expressions-operators/expression-bodied-members). `Enumerable.Repeat(text, times)` crea una secuencia de `times` copias de `text`, y `string.Concat` las une.

En un archivo con instrucciones de nivel superior, los métodos pueden declararse después de las líneas que los llaman, como aquí. La documentación de C# los llama [funciones locales](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/local-functions): pertenecen al código de nivel superior del programa. La [lección 5](../#plan) pone los métodos dentro de clases, su lugar habitual en los programas más grandes.

### Lo que comprueba el compilador

El compilador comprueba cada llamada contra la declaración. Un argumento que falta:

```csharp
Console.WriteLine(FretFrequency(110.0));

double FretFrequency(double openString, int fret)
```

```text
l04_missing_argument.cs(1,19): error CS7036: There is no argument given that corresponds to the required parameter 'fret' of 'FretFrequency(double, int)'
```

Un argumento del tipo equivocado:

```csharp
Console.WriteLine(Square("12"));

int Square(int x)
```

```text
l04_wrong_argument_type.cs(1,26): error CS1503: Argument 1: cannot convert from 'string' to 'int'
```

Usar el resultado de un método `void`:

```csharp
string title = PrintTitle("Methods");

void PrintTitle(string text)
```

```text
l04_void_result.cs(1,16): error CS0029: Cannot implicitly convert type 'void' to 'string'
```

Y un método que puede terminar sin devolver un valor. Aquí, un `fret` negativo pasa de largo los dos `return`:

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

El compilador no intenta adivinar que `fret` nunca es negativo: todos los caminos del método deben terminar con un `return` o una excepción.

### Los argumentos son copias

```csharp
int fret = 5;
AddOctave(fret);
Console.WriteLine($"After AddOctave: {fret}");       // sin cambios: el método recibió una copia

int[] frets = [0, 2, 2, 1, 0, 0];                    // un acorde de mi mayor
AddOctaveToAll(frets);
Console.WriteLine($"After AddOctaveToAll: {string.Join(" ", frets)}");  // cambiado: el método recibió el mismo array

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

Un parámetro recibe una **copia** del argumento. Cambiar `value` dentro de `AddOctave` no cambia `fret`. Pero una variable de tipo array no guarda el array en sí: guarda una *referencia*, la dirección donde vive el array. La copia es una copia de la dirección, así que `values` y `frets` apuntan al mismo array, y el método lo cambia. El acorde de mi mayor subió una octava, al traste 12. Los tipos que se comportan como `int` son **tipos de valor**; los que se comportan como los arrays son **tipos de referencia**. La [lección 6](../#plan) vuelve sobre la diferencia.

## Arrays

Un **array** guarda un número fijo de valores del mismo tipo, uno tras otro, cada uno en una posición numerada, su **índice**.

```csharp
// Un array: un número fijo de valores del mismo tipo
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];

Console.WriteLine(strings.Length);
Console.WriteLine(strings[0]);          // los índices empiezan en 0
Console.WriteLine(strings[5]);          // el último índice es Length - 1
Console.WriteLine(strings[^1]);         // ^1: el primero desde el final
Console.WriteLine(string.Join(", ", strings[1..3]));   // un rango: índices 1 y 2

strings[0] = "D2";                      // afinación drop D: los valores pueden cambiar
Console.WriteLine(string.Join(" ", strings));

// new int[4]: cuatro int, todos a 0 al principio
int[] minutes = new int[4];
minutes[1] = 30;
Console.WriteLine(string.Join(" ", minutes));

// Recorrer los valores
int[] practice = [30, 45, 0, 60, 20];
int total = 0;
foreach (int m in practice)
{
    total += m;
}
Console.WriteLine($"Total: {total} minutes over {practice.Length} days");

// Sort cambia el propio array
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

- `string[]`, que se lee *array de string*, es el tipo «array de cadenas». `["E2", "A2", …]` es una [expresión de colección](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/collection-expressions): los valores entre corchetes. `new int[4]` crea un array de cuatro `int`, todos a `0`.
- **Los índices empiezan en 0**: un array de seis elementos va de `strings[0]` a `strings[5]`. `strings[^1]`, con un acento circunflejo, cuenta desde el final, y `strings[1..3]` es un array nuevo con los elementos desde el índice 1 hasta el índice 3, sin incluirlo. Consulta [índices y rangos](https://learn.microsoft.com/dotnet/csharp/tutorials/ranges-indexes).
- `Length` da el número de elementos. No puede cambiar: un array no tiene `Add`.
- [`string.Join`](https://learn.microsoft.com/dotnet/api/system.string.join) construye una cadena con todos los elementos, con un separador entre ellos, y [`Array.Sort`](https://learn.microsoft.com/dotnet/api/system.array.sort) ordena el array en su sitio.

Pasarse del final es el error más común con los arrays. El compilador no puede verlo, porque el índice solo se conoce mientras el programa se ejecuta:

```csharp
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];
for (int i = 0; i <= strings.Length; i++)     // <= va un paso demasiado lejos
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

Con *menor o igual*, `<=`, el bucle también se ejecuta con `i` igual a 6, y no existe `strings[6]`. La condición del bucle de un array es casi siempre *i menor que la longitud del array*, `i < array.Length`, o mejor, un `foreach`, que no puede pasarse.

Y el tamaño de un array es fijo:

```csharp
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];
strings.Add("B1");
```

```text
l04_array_fixed_size.cs(2,9): error CS1061: 'string[]' does not contain a definition for 'Add' and no accessible extension method 'Add' accepting a first argument of type 'string[]' could be found (are you missing a using directive or an assembly reference?)
```

Para una colección que crece, usa una lista.

## Listas

Una [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1) es como un array que puede crecer y encogerse. La `T` representa el tipo de sus elementos, escrito entre corchetes angulares: `List<string>` es una lista de cadenas, `List<int>` una lista de enteros.

```csharp
// Una List<string> crece y se encoge; el tipo entre < > es el tipo de sus elementos
List<string> chord = ["C", "E", "G"];
Console.WriteLine($"{chord.Count} notes: {string.Join(" ", chord)}");

chord.Add("B");                         // Cmaj7
Console.WriteLine(string.Join(" ", chord));

chord.Insert(1, "D");                   // en el índice 1, los demás se desplazan
Console.WriteLine(string.Join(" ", chord));

chord.Remove("D");                      // quita el primer "D" que encuentra
Console.WriteLine(string.Join(" ", chord));

Console.WriteLine(chord.Contains("G"));
Console.WriteLine(chord.IndexOf("B"));
Console.WriteLine(chord.IndexOf("F#"));  // -1: no está en la lista

chord[3] = "Bb";                         // C7
Console.WriteLine(string.Join(" ", chord));

chord.RemoveAt(chord.Count - 1);
Console.WriteLine(string.Join(" ", chord));

// Una lista vacía, llenada en un bucle
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

| | Array `string[]` | Lista `List<string>` |
|---|---|---|
| Tamaño | fijo al crearlo | crece y se encoge |
| Número de elementos | `Length` | `Count` |
| Leer y cambiar un elemento | `a[i]`, `a[i] = x` | `list[i]`, `list[i] = x` |
| Añadir, insertar, quitar | no | `Add`, `Insert`, `Remove`, `RemoveAt` |
| Buscar | `Array.IndexOf(a, x)` | `list.IndexOf(x)`, `list.Contains(x)` |
| Úsalo cuando | el número de elementos se conoce y no cambia | los elementos van y vienen |

Un acorde de do mayor es C, E y G (do, mi y sol). Añadir B (si) forma un acorde de *séptima mayor*, Cmaj7; con B♭ (escrito `Bb`) es una *séptima de dominante*, C7. `IndexOf` devuelve `-1` cuando el elemento no está.

La lista comprueba el tipo de lo que añades:

```csharp
List<int> frets = [0, 2, 2];
frets.Add("1");
```

```text
l04_list_wrong_type.cs(2,11): error CS1503: Argument 1: cannot convert from 'string' to 'int'
```

## Métodos, arrays y listas juntos: los proyectos de Guitar Alchemist

Guitar Alchemist está dividido en más de cien proyectos. El [curso de LadybugDB](../../ladybugdb/05-csharp/) extrajo su lista a [`projects.csv`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/ladybugdb/data/ga/projects.csv), a partir del commit `a26a7893` de GA. Doce de los proyectos de su carpeta `Common`, copiados a mano en dos arrays, bastan para practicar:

```csharp
// Doce proyectos de la carpeta Common de GuitarAlchemist/ga, y sus lenguajes,
// copiados de code/ladybugdb/data/ga/projects.csv
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

// Los dos arrays van juntos: names[i] está escrito en languages[i]
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

Cada método hace una sola cosa y tiene un nombre que dice cuál: contar, filtrar, encontrar el más largo. `ProjectsIn` usa un `for` en lugar de un `foreach` porque necesita el índice `i` para leer la misma posición en los dos arrays. Dos arrays que deben ir a la par son frágiles: añade un nombre, olvida su lenguaje, y todos los lenguajes siguientes quedan mal. La [lección 5](../#plan) los sustituye por una sola lista de proyectos, cada uno con un nombre y un lenguaje. La [lección 10](../#plan) lee el archivo CSV completo en lugar de copiarlo a mano.

## `null`: ningún valor

Algunas variables necesitan una forma de decir «aquí no hay nada»: ninguna cejilla en la guitarra, ninguna línea más que leer. C# usa [`null`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/null) para eso. Un tipo seguido de un signo de interrogación, como `string?`, una cadena o null, acepta `null`; un `string` sin más no debería contenerlo.

```csharp
// string? : una cadena, o null (ninguna cadena)
string? capo = null;
Console.WriteLine(capo == null);
Console.WriteLine(capo is null);

// ?. da null en lugar de leer un miembro de null; ?? da un valor que usar en lugar de null
Console.WriteLine(capo?.Length);
Console.WriteLine(capo ?? "no capo");
Console.WriteLine(capo?.Length ?? 0);

capo ??= "fret 2";                       // asigna solo si capo es null
Console.WriteLine(capo);
Console.WriteLine(capo.Length);          // el compilador sabe que capo no es null aquí

// Console.ReadLine devuelve null cuando no queda nada que leer
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

Con las líneas `Am`, una línea vacía, `  F  `, `C`, una línea de espacios y `G` como entrada ([`input/l04_null.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l04_null.txt)):

```text
True
True

no capo
0
fret 2
6
4 non-empty lines: Am | F | C | G
```

| Escribe | Significa |
|---|---|
| `x == null`, `x is null` | ¿es `x` null? |
| `x?.Length` | `null` si `x` es null, si no `x.Length` |
| `x ?? other` | `x`, u `other` si `x` es null |
| `x ??= value` | pon `value` en `x` solo si `x` es null |

La tercera línea de la salida está vacía: `capo?.Length` es `null`, y `WriteLine` no imprime nada para él. En el bucle, `(line = Console.ReadLine()) != null` lee una línea, la guarda en `line` y luego la compara con `null`: el bucle se detiene al final de la entrada. [`string.IsNullOrWhiteSpace`](https://learn.microsoft.com/dotnet/api/system.string.isnullorwhitespace) es `true` para `null`, una cadena vacía o solo espacios, y `Trim` quita los espacios alrededor del texto.

### El compilador vigila `null`

Leer un miembro de `null`, como su `Length`, es imposible: no hay ninguna cadena que medir. El compilador sigue de dónde puede venir `null` y **avisa** antes de que ocurra. Esta función se llama [tipos de referencia que aceptan valores null](https://learn.microsoft.com/dotnet/csharp/nullable-references) (*nullable reference types*), activada por el `<Nullable>enable</Nullable>` que viste en el archivo de proyecto de la lección 1, y por defecto en las aplicaciones basadas en archivos.

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
Console.WriteLine(tuning.Length);   // advertencia CS8602, y luego una NullReferenceException en ejecución
```

```text
l04_null_warning.cs(11,19): warning CS8602: Dereference of a possibly null reference.
Unhandled exception. System.NullReferenceException: Object reference not set to an instance of an object.
   at Program.<Main>$(String[] args) in C:\Users\spare\source\repos\learn\code\csharp-beginner\examples\l04_null_warning.cs:line 11
```

Es solo una advertencia, así que el programa se ejecuta, y falla en la línea 11. La solución es tratar el caso `null`, por ejemplo `tuning?.Length ?? 0`, o un `if (tuning is null)` antes de usarla. En el primer ejemplo, `capo.Length` después de `capo ??= "fret 2"` no recibe advertencia: el compilador entendió que `capo` ya no puede ser `null`. La [lección 8](../#plan) trata a fondo las excepciones y la seguridad frente a null.

## Puntos clave

- Un método tiene un tipo de retorno (`void` si no devuelve nada), un nombre, parámetros y un cuerpo; `return` devuelve el resultado y sale del método.
- El compilador comprueba el número y los tipos de los argumentos, y que todos los caminos de un método no `void` devuelvan un valor.
- Los argumentos son copias: un método no puede cambiar una variable `int` de quien lo llama, pero sí los elementos de un array que recibe, porque la copia es una referencia al mismo array.
- Un array tiene un tamaño fijo, `Length`, e índices de `0` a `Length - 1`; pasarse del final lanza `IndexOutOfRangeException`.
- `List<T>` crece y se encoge con `Add`, `Insert`, `Remove` y `RemoveAt`, y tiene un `Count`.
- `string?` puede ser `null`; `?.`, `??` y `??=` lo gestionan, y el compilador avisa cuando podrías usar un `null`.

## Ejercicios

1. Escribe un método `Average` que reciba un `int[]` y devuelva su media como `double`, o `null` cuando el array está vacío. Llámalo con una semana de tiempos de práctica, `30, 45, 0, 60, 20, 0, 90`, y con un array vacío.

<details>
<summary>Solución</summary>

[`exercises/l04_ex_average.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l04_ex_average.cs):

```csharp
// Ejercicio 1: la media de un array, o null cuando el array está vacío
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

`double?` es un `double` que también puede ser `null`: el `?` funciona también con los tipos de valor. `(double)total / values.Length` convierte antes de dividir; `total / values.Length` sería una división entera. La división por cero se evita con el `return null` del principio. La última línea usa el *operador condicional* `condition ? a : b`, un `if`/`else` corto que da un valor.

</details>

2. Guarda los doce nombres de notas (`C`, `C#`, … `B`) en un array, una sola vez. Escribe un método `Transpose` que reciba una `List<string>` de nombres de notas y un número de semitonos, positivo o negativo, y devuelva una lista **nueva** con cada nota desplazada. Comprueba que la lista original no cambia.

<details>
<summary>Solución</summary>

[`exercises/l04_ex_transpose.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l04_ex_transpose.cs):

```csharp
// Ejercicio 2: transportar un acorde, una lista de nombres de notas, un número de semitonos
string[] chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

List<string> cMajor = ["C", "E", "G"];
Console.WriteLine(string.Join(" ", Transpose(cMajor, 2)));
Console.WriteLine(string.Join(" ", Transpose(cMajor, 7)));
Console.WriteLine(string.Join(" ", Transpose(["A", "C", "E"], -3)));
Console.WriteLine(string.Join(" ", cMajor));        // sin cambios: Transpose devuelve una lista nueva

List<string> Transpose(List<string> notes, int semitones)
{
    List<string> result = [];
    foreach (string note in notes)
    {
        int index = Array.IndexOf(chromatic, note);
        int moved = ((index + semitones) % 12 + 12) % 12;   // + 12 mantiene los pasos negativos en 0..11
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

Do mayor subido 2 semitonos es re mayor, subido 7 es sol mayor; la menor bajado 3 es fa♯ menor. En C#, `%` conserva el signo del número de la izquierda: bajar C (índice 0) 3 semitonos da `(0 - 3) % 12`, que vale `-3`, un índice no válido. Sumar 12 y volver a aplicar `% 12` siempre da un índice de 0 a 11: aquí, 9, el A (la).

`Transpose` lee `chromatic`, una variable del código de nivel superior, sin recibirla como parámetro: una función local puede hacerlo. Aquí es cómodo, pero oculta de qué depende el método. La lección 5 muestra cómo una clase guarda esos datos compartidos. Una nota que no está en el array, como `Bb`, da `-1` con `Array.IndexOf` y un resultado incorrecto: mejorar eso es un buen ejercicio adicional.

</details>

3. Lee todas las líneas de la entrada hasta su final, guárdalas en una lista y luego imprime el número de líneas y la más larga, o `(no lines)` si no había ninguna. Escribe la búsqueda de la línea más larga como un método que devuelve `string?`.

<details>
<summary>Solución</summary>

[`exercises/l04_ex_longest_line.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l04_ex_longest_line.cs):

```csharp
// Ejercicio 3: leer todas las líneas hasta el final de la entrada, luego imprimir cuántas hay y la más larga
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

Con cuatro afinaciones como entrada ([`input/l04_ex_longest_line.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l04_ex_longest_line.txt)):

```text
4 lines
Longest: Standard: E2 A2 D3 G3 B3 E4
```

`best` empieza en `null`, que significa «todavía no se ha visto ninguna línea». `best == null || value.Length > best.Length` nunca lee `best.Length` cuando `best` es `null`, porque `||` se detiene en el primer `true`; el compilador lo sabe y no avisa. Con una entrada vacía, el método devuelve `null`, y `??` imprime `(no lines)`.

</details>

## Fuentes

- [Métodos](https://learn.microsoft.com/dotnet/csharp/methods), [funciones locales](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/local-functions), [parámetros de métodos](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/method-parameters), [argumentos opcionales y con nombre](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments)
- [Arrays](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/arrays), [expresiones de colección](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/collection-expressions), [índices y rangos](https://learn.microsoft.com/dotnet/csharp/tutorials/ranges-indexes)
- [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1), [colecciones](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/collections)
- [Tipos de referencia que aceptan valores null](https://learn.microsoft.com/dotnet/csharp/nullable-references), [operadores de acceso a miembros `?.`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/member-access-operators#null-conditional-operators--and-), [`??` y `??=`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/null-coalescing-operator)
- [Tipos de valor](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/value-types) y [tipos de referencia](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/reference-types)
