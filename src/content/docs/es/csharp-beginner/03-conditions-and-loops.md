---
title: 3. Condiciones y bucles
description: Toma decisiones con if, else y switch, repite trabajo con while, for y foreach, detén o salta vueltas con break y continue, y sigue un programa línea a línea en un depurador.
sidebar:
  order: 3
---

Código: los ejemplos [`examples/l03_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/examples), los fragmentos rechazados [`compile_fail/l03_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/compile_fail) y las soluciones [`exercises/l03_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises).

Hasta ahora, los programas ejecutaban cada línea una vez, de arriba abajo. Esta lección cambia eso: una **condición** ejecuta algunas líneas solo en algunos casos, y un **bucle** ejecuta líneas varias veces.

## Comparaciones y `bool`

Una comparación hace una pregunta cuya respuesta es un `bool`: `true` (verdadero) o `false` (falso).

```csharp
int fret = 12;

// Una comparación da un bool: true o false
Console.WriteLine(fret == 12);
Console.WriteLine(fret != 12);
Console.WriteLine(fret > 5 && fret < 10);   // && : las dos deben ser verdaderas
Console.WriteLine(fret < 1 || fret > 11);   // || : al menos una debe ser verdadera
Console.WriteLine(!(fret > 5));             // !  : lo contrario
```

```text
True
False
False
True
False
```

| Operador | Significado | | Operador | Significado |
|---|---|---|---|---|
| `==` | igual a | | `&&` | y |
| `!=` | distinto de | | `\|\|` | o |
| `<`, `<=` | menor que, o igual | | `!` | no |
| `>`, `>=` | mayor que, o igual | | | |

Cuidado con `==`, dos signos igual, que compara, y `=`, un solo signo, que asigna. Las páginas de [operadores de comparación](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/comparison-operators) y de [operadores lógicos booleanos](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/boolean-logical-operators) tienen las reglas completas. El *y* y el *o* se detienen en cuanto conocen la respuesta: en `fret > 5 && fret < 10`, cuando la primera comparación es `false`, la segunda ni siquiera se calcula.

## `if`, `else if`, `else`

[`if`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#the-if-statement) ejecuta un **bloque**, las líneas entre llaves, solo cuando su condición es `true`:

```csharp
// if ejecuta un bloque solo cuando la condición es verdadera
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

// Las cadenas se comparan por su contenido
string tuning = "E A D G B E";
if (tuning == "E A D G B E")
{
    Console.WriteLine("Standard tuning");
}

// Una variable declarada dentro de un bloque solo existe en ese bloque
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

Las condiciones se comprueban en orden, y solo se ejecuta el primer bloque cuya condición es `true`. `else` recoge todos los demás casos. Tanto `else if` como `else` son opcionales.

La condición debe ser un `bool`. Se rechazan dos errores clásicos. Escribir un solo signo igual en lugar de dos:

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

`fret = 12` es una asignación, cuyo valor es el `int` 12, no un `bool`. En algunos otros lenguajes esto compila y cambia `fret` en silencio. Una cadena tampoco es una condición:

```csharp
string answer = "yes";
if (answer)
```

```text
l03_string_condition.cs(2,5): error CS0029: Cannot implicitly convert type 'string' to 'bool'
```

Escribe `if (answer == "yes")`.

### Ámbito

Una variable declarada dentro de un bloque solo existe en ese bloque, y en los bloques que contiene. Esa zona es su **ámbito**:

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

Para usar `distance` después del `if`, declárala antes del `if`.

## `switch`

Cuando un valor se compara con una lista de valores posibles, un [`switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#the-switch-statement) se lee mejor que una cadena de `else if`.

```csharp
int semitone = 7;

// La instrucción switch: un case por valor, cada case termina con break
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

La **instrucción switch** salta al `case` que coincide, o a `default` cuando ninguno coincide. Cada sección debe terminar con `break` (o `return`, [lección 4](../04-methods-arrays-lists/)). En C y JavaScript, un `break` que falta deja que el programa caiga en el caso siguiente; C# lo rechaza:

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

### La expresión `switch`

A menudo, cada caso solo calcula un valor. La [**expresión switch**](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) lo dice en menos líneas: el valor, `switch`, y luego un *brazo* por caso, `pattern => result` (patrón y resultado), separados por comas.

```csharp
// La expresión switch calcula un valor: un brazo por patrón, _ coincide con todo lo demás
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

// Los patrones pueden comparar: gana el primer brazo que coincide
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

- Los brazos se prueban **de arriba abajo**, y el primero que coincide da el valor. El traste 3 coincide con el brazo `< 5`, menor que 5, antes de probar el brazo menor que 12.
- Un *patrón* puede ser un valor, como `12`, o una comparación, como `< 5`, menor que 5. La [página de patrones](https://learn.microsoft.com/dotnet/csharp/fundamentals/functional/pattern-matching) muestra los demás: `and`, `or`, `not` y muchos más.
- `_`, el *descarte*, coincide con todo: es el `default` de una expresión switch.
- El bucle `foreach (int fret in new[] { … })` ejecuta el bloque una vez por cada número; los bucles vienen [a continuación](#bucles).

Sin `_`, un valor con el que no coincide ningún brazo no tiene nada que producir. El compilador avisa, y el programa falla cuando ocurre:

```csharp
int stringNumber = 7;

// Ningún brazo para 7, y ningún brazo _: el compilador avisa y el programa falla en ejecución
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

Una **advertencia** (*warning*), a diferencia de un error, no detiene la compilación: el programa se ejecuta, y aquí se detiene con una **excepción**, un error que ocurre mientras el programa se ejecuta. Las líneas que empiezan por `at` son la *pila de llamadas* (*stack trace*): dónde estaba el programa. La última apunta a la línea 4 del archivo. La [lección 8](../#plan) trata de las excepciones.

Dos cosas que saber sobre las advertencias. Primero, léelas: esta anunciaba el fallo. Segundo, `dotnet run` solo las muestra cuando compila; si vuelves a ejecutar el mismo archivo sin cambios, no compila, y la advertencia no se imprime otra vez. `dotnet clean l03_switch_warning.cs` olvida el programa compilado, y la siguiente ejecución vuelve a mostrar la advertencia. El `check.sh` del curso hace eso antes de cada ejecución.

## Bucles

Un bucle repite un bloque. C# tiene cuatro [instrucciones de iteración](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/iteration-statements):

```csharp
// while: repite mientras la condición sea verdadera
int countdown = 3;
while (countdown > 0)
{
    Console.WriteLine($"{countdown}...");
    countdown--;                   // lo mismo que countdown = countdown - 1
}
Console.WriteLine("Play!");

// for: inicio; condición; paso
for (int fret = 0; fret <= 12; fret += 3)
{
    Console.Write($"{fret} ");
}
Console.WriteLine();

// foreach: cada elemento de una colección, aquí cada carácter de una cadena
foreach (char letter in "EADGBE")
{
    Console.Write($"[{letter}]");
}
Console.WriteLine();

// break sale del bucle, continue pasa a la vuelta siguiente
for (int i = 1; i <= 10; i++)
{
    if (i % 2 == 0)
    {
        continue;                  // salta los números pares
    }
    if (i > 7)
    {
        break;                     // para después de 7
    }
    Console.Write($"{i} ");
}
Console.WriteLine();

// do-while: el bloque se ejecuta al menos una vez, la condición se comprueba después
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

| Bucle | Úsalo cuando | Comprueba la condición |
|---|---|---|
| `while (condition)` | no sabes de antemano cuántas vueltas | antes de cada vuelta |
| `do { … } while (condition);` | el bloque debe ejecutarse al menos una vez | después de cada vuelta |
| `for (start; condition; step)` | cuentas: de 0 a 12, de 3 en 3 | antes de cada vuelta |
| `foreach (type item in collection)` | recorres cada elemento de una colección | — |

- `countdown--` resta 1, `i++` suma 1, y `fret += 3` suma 3: formas cortas de `countdown = countdown - 1` y `fret = fret + 3`.
- Un `for` tiene tres partes separadas por punto y coma: lo que se hace **una vez** al principio (`int fret = 0`), la condición comprobada **antes de cada vuelta** (`fret <= 12`), y lo que se hace **después de cada vuelta** (`fret += 3`). Su variable `fret` solo existe dentro del bucle.
- `foreach` toma cada elemento por turno. Una cadena es una colección de `char`; los arrays y las listas, en la [lección 4](../04-methods-arrays-lists/), también son colecciones.
- `continue` salta el resto del bloque y empieza la vuelta siguiente; `break` sale del bucle de inmediato.

Un `while` cuya condición nunca pasa a `false` se ejecuta para siempre. Si un programa parece atascado, pulsa <kbd>Ctrl</kbd>+<kbd>C</kbd> en la terminal para detenerlo.

### Bucles dentro de bucles: el mástil

Un bucle puede contener otro bucle. Para cada cuerda, el bucle interior recorre cada traste. Este programa imprime las notas de los cinco primeros trastes de una guitarra con afinación estándar, el `Tuning.Default` de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs#L20-L23):

```csharp
// Los cinco primeros trastes de una guitarra con afinación estándar (E2 A2 D3 G3 B3 E4, Tuning.Default en GA).
// Cada nota es un número de semitonos: C es 0, C# es 1, ... B es 11, y el C siguiente vuelve a ser 12.
for (int stringNumber = 6; stringNumber >= 1; stringNumber--)
{
    // Semitonos de la cuerda al aire por encima de C
    int open = stringNumber switch
    {
        6 => 4,    // E
        5 => 9,    // A
        4 => 2,    // D
        3 => 7,    // G
        2 => 11,   // B
        _ => 4,    // E (cuerda 1)
    };

    Console.Write($"String {stringNumber}:");
    for (int fret = 0; fret <= 5; fret++)
    {
        int semitone = (open + fret) % 12;     // % 12 devuelve 12 a 0: la octava
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

Los guitarristas numeran las cuerdas de la más aguda, la cuerda 1, a la más grave, la cuerda 6; el bucle exterior cuenta hacia atrás para que la cuerda 6 se imprima primero. En la cuerda Si (B), el traste 1 es `(11 + 1) % 12`, que vale `0`: C, es decir, do. El operador `%` hace que los números den la vuelta como las horas de un reloj, que es exactamente como se repiten los nombres de las notas en cada octava. El [curso de teoría musical](../../music-theory-ga/01-notes-and-the-fretboard/) va mucho más lejos con la misma idea.

### Leer hasta que la respuesta sea correcta

Un bucle `while` puede seguir pidiendo datos hasta obtener lo que necesita:

```csharp
// Adivina el traste: el bucle lee respuestas hasta que una es correcta
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

Tecleando `12`, `five`, `5` y `7`:

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

`continue` vuelve a la pregunta sin contar la respuesta incorrecta como intento. Cuando la entrada termina, `ReadLine` devuelve `null` y `break` sale del bucle: sin él, un programa cuya entrada viene de un archivo, como en la CI, preguntaría para siempre. Con el teclado, <kbd>Ctrl</kbd>+<kbd>Z</kbd> y luego <kbd>Enter</kbd> en Windows, o <kbd>Ctrl</kbd>+<kbd>D</kbd> en Linux y macOS, terminan la entrada.

## Encontrar un error con el depurador

Cuando un programa da un resultado incorrecto, necesitas ver lo que hace, línea a línea. La forma más sencilla es añadir llamadas a `Console.WriteLine` que impriman las variables, volver a ejecutar y quitarlas después. Funciona en todas partes.

Un **depurador** lo hace mejor: pausa el programa en una línea que eliges, un **punto de interrupción**, muestra el valor de cada variable y te deja ejecutar una línea cada vez. Los tres editores de la [lección 1](../01-first-program/#elegir-un-editor) tienen uno:

| Acción | Visual Studio Code | Visual Studio | Rider |
|---|---|---|---|
| Poner o quitar un punto de interrupción | <kbd>F9</kbd>, o clic a la izquierda del número de línea | <kbd>F9</kbd> | clic a la izquierda de la línea |
| Iniciar con el depurador | <kbd>F5</kbd> | <kbd>F5</kbd> | el icono del insecto |
| Ejecutar la línea siguiente | <kbd>F10</kbd> (step over) | <kbd>F10</kbd> | step over |
| Entrar en un método llamado en esta línea | <kbd>F11</kbd> (step into) | <kbd>F11</kbd> | step into |
| Continuar hasta el siguiente punto de interrupción | <kbd>F5</kbd> | <kbd>F5</kbd> | resume |

Pruébalo con el programa del mástil: pon un punto de interrupción en la línea `int semitone = (open + fret) % 12;`, inicia con el depurador y mira `stringNumber`, `open` y `fret` en el panel *Variables* o *Locals*. Cada vez que continúas, el programa vuelve a detenerse en el traste siguiente. También puedes escribir una expresión como `(open + fret) % 12` en el panel *Watch* para ver su valor.

Las teclas de esta tabla son las predeterminadas de cada editor en Windows y Linux; el mapa de teclas de Rider en macOS es distinto. Consulta [la depuración en VS Code](https://code.visualstudio.com/docs/csharp/debugging), [el depurador de Visual Studio para principiantes](https://learn.microsoft.com/visualstudio/debugger/debugger-feature-tour) y [la depuración en Rider](https://www.jetbrains.com/help/rider/Debugging_Code.html). *Por verificar*: todavía no he depurado estos ejemplos en cada uno de los tres editores, ni como aplicaciones de un solo archivo ni dentro de un proyecto creado con [`dotnet new console`](../01-first-program/#un-proyecto).

## Puntos clave

- Una comparación da un `bool`; *y* (`&&`), *o* (`||`) y *no* (`!`) las combinan. Dos signos igual comparan, un solo signo igual asigna.
- `if`, `else if` y `else` ejecutan el primer bloque cuya condición es `true`; una variable declarada en un bloque solo existe en ese bloque.
- Una instrucción `switch` necesita un `break` al final de cada caso; una expresión `switch` calcula un valor, prueba sus brazos de arriba abajo y debería terminar con `_`.
- `while` repite mientras una condición es verdadera, `for` cuenta, `foreach` recorre cada elemento de una colección; `break` sale del bucle y `continue` salta a la vuelta siguiente.
- Una advertencia no detiene la compilación, pero a menudo anuncia un problema; una excepción no controlada detiene el programa e imprime dónde ocurrió.
- Un depurador se detiene en los puntos de interrupción y muestra las variables, una línea cada vez.

## Ejercicios

1. Imprime los números del 1 al 15 en una línea, pero imprime `Fizz` en lugar de los múltiplos de 3, `Buzz` en lugar de los múltiplos de 5, y `FizzBuzz` para los múltiplos de ambos. Pista: una expresión switch puede mirar dos valores a la vez, escrita `(a, b) switch`.

<details>
<summary>Solución</summary>

[`exercises/l03_ex_fizzbuzz.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l03_ex_fizzbuzz.cs):

```csharp
// Ejercicio 1: FizzBuzz de 1 a 15, con una expresión switch sobre dos restos
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

`(i % 3, i % 5)` agrupa los dos restos en una *tupla*, y cada brazo comprueba ambos. `(0, _)` significa «divisible por 3, sea cual sea el segundo resto». El orden importa: `(0, 0)` debe ir primero, o 15 imprimiría `Fizz`. Con `if`, escribirías primero `if (i % 3 == 0 && i % 5 == 0)`, luego `else if (i % 3 == 0)`, y así sucesivamente.

</details>

2. Pide el nombre de una nota (`C`, `C#`, … `B`) e imprime las 13 notas de la escala cromática desde esa nota hasta la misma nota una octava más arriba. Imprime un mensaje si la nota es desconocida.

<details>
<summary>Solución</summary>

[`exercises/l03_ex_chromatic.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l03_ex_chromatic.cs):

```csharp
// Ejercicio 2: leer el nombre de una nota e imprimir las 13 notas de la escala cromática desde ella hasta su octava
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

Con `A`:

```text
Starting note? A
A A# B C C# D D# E F F# G G# A 
```

La primera expresión switch convierte el nombre en un número, donde `-1` significa «desconocida»: una expresión switch también funciona con cadenas. El bucle se ejecuta 13 veces, `step` de 0 a 12, y `% 12` devuelve al principio los números mayores que 11. Escribir dos veces los mismos nombres de notas no es ideal: la [lección 4](../04-methods-arrays-lists/) los guarda una sola vez, en un array.

</details>

3. Lee tiempos de práctica en minutos, uno por línea, hasta una línea vacía o el final de la entrada. Salta las líneas que no sean números enteros o que sean negativas, indicándolo. Después imprime el número de días válidos, el total en minutos y el total en horas y minutos.

<details>
<summary>Solución</summary>

[`exercises/l03_ex_total.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l03_ex_total.cs):

```csharp
// Ejercicio 3: sumar los minutos de práctica escritos uno por línea; una línea vacía termina la entrada
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

Con las líneas `30`, `45`, `forty`, `-5`, `60`, una línea vacía y luego `90` ([`input/l03_ex_total.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l03_ex_total.txt)), la salida es:

```text
Skipped: forty
Skipped: -5
3 days, 135 minutes, 2 h 15 min
```

`while (true)` nunca se detiene por sí solo: decide el `break` de dentro. El `90` después de la línea vacía nunca se lee. En `!int.TryParse(line, out int minutes) || minutes < 0`, el `||` calcula `minutes < 0` solo cuando `TryParse` tuvo éxito, así que `minutes` siempre contiene el valor leído cuando se compara.

</details>

## Fuentes

- [Instrucciones de selección: `if`, `else` y `switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements), [la expresión `switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [patrones](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns)
- [Instrucciones de iteración: `for`, `foreach`, `do` y `while`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/iteration-statements), [instrucciones de salto: `break` y `continue`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/jump-statements)
- [Operadores de comparación](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/comparison-operators), [operadores lógicos booleanos](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/boolean-logical-operators)
- [Advertencia del compilador CS8509](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/pattern-matching-warnings), [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception)
- [Depurar C# en VS Code](https://code.visualstudio.com/docs/csharp/debugging), [recorrido por las características del depurador de Visual Studio](https://learn.microsoft.com/visualstudio/debugger/debugger-feature-tour), [Rider: depurar código](https://www.jetbrains.com/help/rider/Debugging_Code.html)
