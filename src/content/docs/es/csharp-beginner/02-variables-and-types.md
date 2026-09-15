---
title: 2. Variables, tipos y entrada
description: Guarda valores en variables de tipo int, double, decimal, string y bool, convierte entre tipos, da formato al texto con interpolación y lee lo que escribe el usuario con Console.ReadLine.
sidebar:
  order: 2
---

Código: los ejemplos [`examples/l02_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/examples), los fragmentos rechazados [`compile_fail/l02_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/compile_fail) y las soluciones [`exercises/l02_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises). Ejecuta un ejemplo desde la carpeta `code/csharp-beginner` con `dotnet run examples/l02_variables.cs`.

## Variables

Una **variable** es una caja con nombre que guarda un valor. En C#, cada caja tiene además un **tipo**, fijado al crearla: la clase de valores que acepta.

```csharp
// Una variable es una caja con nombre que guarda un valor de un tipo
int strings = 6;
string tuning = "E A D G B E";
double scaleLength = 64.8;     // centímetros, un tiro de escala habitual en guitarra
bool isAcoustic = true;
char lowest = 'E';

Console.WriteLine(strings);
Console.WriteLine(tuning);
Console.WriteLine(scaleLength);
Console.WriteLine(isAcoustic);
Console.WriteLine(lowest);

// El valor puede cambiar; el tipo no
strings = 7;
Console.WriteLine(strings);

// var: el compilador deduce el tipo a partir del valor
var frets = 22;                // int
var name = "Stratocaster";     // string
Console.WriteLine(frets.GetType());
Console.WriteLine(name.GetType());

// const: un valor que nunca cambia
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

`int strings = 6;` es una **declaración**: el tipo, el nombre, `=` y luego el primer valor. Se lee «crea una caja llamada `strings` para un `int` y pon 6 dentro». Más tarde, `strings = 7;` es una **asignación**: sustituye el valor de la caja. El signo `=` significa «poner en», no «es igual a».

Los nombres siguen unas pocas reglas: letras, dígitos y `_`, sin empezar por un dígito, y sin ser una palabra clave del lenguaje como `int` o `if`. Por convención, una variable local empieza en minúscula y cada palabra siguiente en mayúscula: `scaleLength`. Ese estilo se llama *camelCase*; las [reglas de nomenclatura de identificadores de C#](https://learn.microsoft.com/dotnet/csharp/fundamentals/coding-style/identifier-names) enumeran los demás.

## Los tipos básicos

| Tipo | Guarda | Ejemplos | Rango y precisión |
|---|---|---|---|
| `int` | números enteros | `6`, `-12`, `2_000_000` | de unos -2100 millones a 2100 millones |
| `long` | enteros más grandes | `9_000_000_000` | unos ±9,2 trillones |
| `double` | números con decimales, aproximados | `64.8`, `1e-3` | de 15 a 17 cifras significativas |
| `decimal` | números con decimales, exactos | `19.99m` | de 28 a 29 cifras significativas |
| `bool` | verdadero o falso | `true`, `false` | |
| `char` | un carácter | `'E'`, `'#'` | entre comillas simples |
| `string` | texto | `"E A D G B E"`, `""` | entre comillas dobles |

Las páginas de [tipos numéricos enteros](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/integral-numeric-types) y de [tipos numéricos de punto flotante](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types) enumeran los demás, como `byte`, `short` o `float`. Como principiante los necesitarás poco. El `_` de `2_000_000` solo hace que el número sea más fácil de leer.

`GetType()` imprimió `System.Int32` y `System.String`: `int` es la palabra clave de C# para el tipo .NET `Int32`, un entero de 32 bits, y `string` es la palabra clave para `String`. Ambos nombres designan exactamente el mismo tipo.

### `var`

Con [`var`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/declarations#implicitly-typed-local-variables), el compilador lee el valor y le da a la variable su tipo: `var frets = 22;` crea un `int`. La variable sigue teniendo un solo tipo durante toda su vida. `var` ahorra escritura cuando el tipo es evidente por el valor; escribe el tipo cuando ayude a quien lee.

### `const`

Una [`const`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/const) es un valor fijado al escribir el programa: 12 semitonos por octava no cambiarán nunca. Su nombre empieza por mayúscula.

### Lo que el compilador rechaza

Cada uno de estos pequeños programas es rechazado. El tipo de una variable no puede cambiar, así que una cadena no cabe en una caja `int`:

```csharp
var frets = 22;
frets = "twenty-two";
```

```text
l02_type_change.cs(2,9): error CS0029: Cannot implicitly convert type 'string' to 'int'
```

Una variable debe tener un valor antes de leerla:

```csharp
int strings;
Console.WriteLine(strings);
```

```text
l02_unassigned.cs(2,19): error CS0165: Use of unassigned local variable 'strings'
```

`var` necesita un valor para encontrar el tipo:

```csharp
var tuning;
tuning = "E A D G B E";
```

```text
l02_var_without_value.cs(1,5): error CS0818: Implicitly-typed variables must be initialized
```

Y una constante sigue siendo constante:

```csharp
const int SemitonesPerOctave = 12;
SemitonesPerOctave = 13;
```

```text
l02_const_change.cs(2,1): error CS0131: The left-hand side of an assignment must be a variable, property or indexer
```

## Números y aritmética

`+`, `-`, `*` y `/` funcionan como en matemáticas, y `%` da el resto de una división. El tipo de los números cambia el resultado:

```csharp
// Enteros: la división descarta los decimales
Console.WriteLine(7 / 2);
Console.WriteLine(7 % 2);      // el resto
Console.WriteLine(7 / 2.0);    // un double en la operación: el resultado es un double

// Cada tipo entero tiene un rango; int va de unos -2100 millones a 2100 millones
Console.WriteLine(int.MaxValue);
int big = int.MaxValue;
big = big + 1;                 // da la vuelta sin ningún error
Console.WriteLine(big);
Console.WriteLine(long.MaxValue);

// double es rápido pero aproximado: 0.1 no tiene forma binaria exacta
Console.WriteLine(0.1 + 0.2);
Console.WriteLine(0.1 + 0.2 == 0.3);

// decimal es exacto para las fracciones decimales: úsalo para el dinero
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

Tres sorpresas para un principiante:

1. **`7 / 2` es `3`.** Cuando los dos números son enteros, la división es una división entera: los decimales se descartan, no se redondean. `7 % 2` da lo que sobra, `1`. Si uno de los números es un `double`, como `2.0`, el resultado es un `double`: `3.5`.
2. **Un `int` que pasa de su máximo da la vuelta** hasta el valor más negativo, sin ningún error. El compilador solo lo detecta cuando todo el cálculo está hecho de constantes:

   ```csharp
   int big = int.MaxValue + 1;
   ```

   ```text
   l02_overflow_constant.cs(1,11): error CS0220: The operation overflows at compile time in checked mode
   ```

   La palabra clave [`checked`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked) hace que el programa falle en lugar de dar la vuelta, cuando los números solo se conocen durante la ejecución.
3. **`0.1 + 0.2` no es exactamente `0.3` con `double`.** Un `double` guarda los números en binario, donde 0.1 no tiene forma exacta, igual que 1/3 no tiene forma decimal exacta. Para el dinero, usa `decimal`, donde `0.1m + 0.2m` es exactamente `0.3`. La `m` tras el número lo convierte en `decimal`; sin ella, el compilador se niega:

   ```csharp
   decimal price = 19.99;
   ```

   ```text
   l02_decimal_literal.cs(1,17): error CS0664: Literal of type double cannot be implicitly converted to type 'decimal'; use an 'M' suffix to create a literal of this type
   ```

### Un cálculo real: la frecuencia de un traste

Cada traste de una guitarra sube la nota un semitono, lo que multiplica la frecuencia de la cuerda por la raíz duodécima de 2, más o menos 1.0595. Doce trastes duplican la frecuencia: una octava. [`Math.Pow(x, y)`](https://learn.microsoft.com/dotnet/api/system.math.pow) calcula x elevado a y:

```csharp
// La cuerda La al aire vibra a 110 Hz. Cada traste sube la nota un semitono,
// lo que multiplica la frecuencia por la raíz duodécima de 2.
double openA = 110.0;
int fret = 7;

double wrong = openA * Math.Pow(2, fret / 12);     // 7 / 12 es una división entera: 0
double right = openA * Math.Pow(2, fret / 12.0);   // 7 / 12.0 es 0.5833...

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

`fret / 12` es `0`, porque los dos son `int`, y 2 elevado a 0 es 1: la frecuencia «incorrecta» es la de la cuerda al aire. Este error no da ni error ni advertencia, solo un resultado incorrecto. Escribir `12.0` la convierte en una división `double`. El traste 7 de la cuerda La es un Mi (E), a unos 164.81 Hz.

## Conversiones

Algunas conversiones ocurren solas; otras hay que pedirlas.

```csharp
// Conversión implícita: no se puede perder información
int semitones = 7;
double asDouble = semitones;
Console.WriteLine(asDouble);

// Conversión explícita (un cast): los decimales se cortan, no se redondean
double hertz = 164.81;
int truncated = (int)hertz;
Console.WriteLine(truncated);

// Redondeo: por defecto, los valores a mitad de camino van al número par más cercano
Console.WriteLine(Math.Round(2.5));
Console.WriteLine(Math.Round(3.5));
Console.WriteLine(Math.Round(2.5, MidpointRounding.AwayFromZero));

// Del texto al número
int frets = int.Parse("22");
Console.WriteLine(frets + 2);

// TryParse no falla con un texto incorrecto: devuelve false
bool ok = int.TryParse("twenty-two", out int parsed);
Console.WriteLine($"{ok} {parsed}");
ok = int.TryParse("24", out parsed);
Console.WriteLine($"{ok} {parsed}");

// Del número al texto
string text = frets.ToString();
Console.WriteLine(text + "2");   // + entre cadenas las une
Console.WriteLine(frets + 2);    // + entre números los suma
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

### Entre tipos numéricos

Todo `int` cabe en un `double`, así que el compilador convierte por ti: es una **conversión implícita**. En sentido contrario, un `double` puede tener decimales que un `int` no puede guardar, así que el compilador se niega a convertir en silencio:

```csharp
double hertz = 164.81;
int rounded = hertz;
```

```text
l02_double_to_int.cs(2,15): error CS0266: Cannot implicitly convert type 'double' to 'int'. An explicit conversion exists (are you missing a cast?)
```

El mensaje sugiere un **cast** (conversión explícita): el tipo entre paréntesis delante del valor, `(int)hertz`. Le dice al compilador «sé que puedo perder algo». Un cast a `int` corta los decimales: 164.81 se convierte en 164.

Para redondear, usa [`Math.Round`](https://learn.microsoft.com/dotnet/api/system.math.round). Por defecto, redondea un valor que está exactamente a mitad de camino al número **par** más cercano: `2.5` da `2` y `3.5` da `4`. Se llama redondeo bancario, y evita empujar hacia arriba todos los valores intermedios. `MidpointRounding.AwayFromZero` da el redondeo que se enseña en la escuela.

### Del texto al número

Una cadena que contiene dígitos sigue siendo texto: `"22"` no puede ir en una caja `int`.

```csharp
int frets = "22";
```

```text
l02_string_to_int.cs(1,13): error CS0029: Cannot implicitly convert type 'string' to 'int'
```

[`int.Parse`](https://learn.microsoft.com/dotnet/api/system.int32.parse) lee el número de una cadena, y detiene el programa con un error si el texto no es un número. [`int.TryParse`](https://learn.microsoft.com/dotnet/api/system.int32.tryparse) nunca detiene el programa: devuelve `true` o `false`, y entrega el número mediante su parámetro `out`. `out int parsed` declara la variable `parsed` ahí mismo, en la llamada. Cuando el texto no es un número, `parsed` vale `0` y el resultado es `false`. Usa `TryParse` para todo lo que escribe una persona: las personas se equivocan al teclear.

`double.Parse`, `decimal.Parse` y sus versiones `TryParse` funcionan igual para los demás tipos.

### Del número al texto

`ToString()` convierte cualquier valor en texto. Entonces `+` significa otra cosa: entre dos cadenas, `+` las **une**. `"22" + "2"` es `"222"`, mientras que `22 + 2` es `24`. Cuando un lado es una cadena y el otro un número, C# convierte el número en texto y los une, de izquierda a derecha: por eso `"Frets played: " + 3 + 2 + 1` da `Frets played: 321`.

## Cadenas e interpolación

Unir cadenas con `+` se vuelve difícil de leer enseguida. La **interpolación de cadenas** pone los valores directamente dentro del texto: un `$` antes de las comillas de apertura, y cada expresión entre llaves.

```csharp
string note = "A";
int octave = 4;
double frequency = 440;

// Interpolación: $ antes de las comillas, expresiones entre llaves
Console.WriteLine($"{note}{octave} vibrates at {frequency} Hz");
Console.WriteLine($"One octave higher: {frequency * 2} Hz");

// Formato y alineación: {valor,ancho:formato}
Console.WriteLine($"[{note,-5}] [{octave,5}] [{frequency,8:F1}]");
Console.WriteLine($"{1234567.891:N2}");

// Algunos métodos de las cadenas
string model = "Les Paul";
Console.WriteLine(model.Length);
Console.WriteLine(model.ToUpper());
Console.WriteLine(model.Contains("Paul"));
Console.WriteLine(model.Replace("Paul", "Standard"));
Console.WriteLine(model[0]);          // el primer carácter: un char

// Caracteres especiales
Console.WriteLine("Tab:\tafter\nNew line, and a quote: \"");
Console.WriteLine(@"C:\Users\ada\music");     // literal (verbatim): \ es solo un carácter
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

- Dentro de las llaves sirve cualquier expresión: `frequency * 2` se calcula y luego se inserta.
- Tras una coma, un **ancho**: `{octave,5}` ocupa 5 caracteres, alineado a la derecha; un ancho negativo, `{note,-5}`, alinea a la izquierda. Tras dos puntos, un **formato**: `F1` muestra un decimal, `N2` dos decimales con separadores de miles. Las [cadenas de formato numérico estándar](https://learn.microsoft.com/dotnet/standard/base-types/standard-numeric-format-strings) los enumeran todos.
- Una cadena conoce su longitud, `Length`, y tiene métodos como `ToUpper`, `Contains` o `Replace`. Ninguno cambia `model`: devuelven una cadena nueva. `model[0]` es el carácter en la posición 0, el primero: las posiciones empiezan en 0.
- Una barra invertida empieza una **secuencia de escape**: `\t` es un tabulador, `\n` un salto de línea, `\"` unas comillas dentro de la cadena. Con `@` delante de la cadena, una barra invertida es solo una barra invertida, práctico para las rutas de Windows. Entre tres comillas, un [literal de cadena sin formato](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/reference-types#string-literals) (*raw string literal*) conserva comillas y saltos de línea tal cual, y quita la sangría de las `"""` de cierre.

El [tutorial de interpolación de cadenas](https://learn.microsoft.com/dotnet/csharp/tutorials/string-interpolation) va más allá.

## Leer lo que escribe el usuario

[`Console.ReadLine()`](https://learn.microsoft.com/dotnet/api/system.console.readline) espera a que el usuario escriba una línea y pulse <kbd>Enter</kbd>, y luego devuelve esa línea como cadena, sin el <kbd>Enter</kbd>.

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

Cuando escribo `Ada` y `3`, la terminal muestra:

```text
> dotnet run examples/l02_input.cs
What is your name? Ada
How many years have you played the guitar? 3
Hello Ada, 3 years is 36 months of practice.
```

La CI no puede teclear: `check.sh` envía al programa las líneas de [`input/l02_input.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l02_input.txt), con una redirección de su entrada:

```text
dotnet run examples/l02_input.cs < input/l02_input.txt
```

El texto tecleado no se muestra entonces, y la salida esperada es una sola línea: `What is your name? How many years have you played the guitar? Hello Ada, 3 years is 36 months of practice.`

Dos cosas nuevas en este programa:

- El tipo es `string?`, con un signo de interrogación: `ReadLine` devuelve una cadena, o `null` cuando no queda nada que leer. La [lección 4](../04-methods-arrays-lists/#null-ningún-valor) explica `null`. `int.TryParse` acepta un `null` y devuelve `false`.
- `if` y `else` eligen entre dos bloques, según el `bool` que devuelve `TryParse`. La [lección 3](../03-conditions-and-loops/) trata de ellos.

## Los números y el idioma del usuario

`1.5` es uno y medio en inglés, pero quien habla francés o español escribe `1,5`. .NET sigue la **cultura** del ordenador, su configuración de idioma y región, cuando imprime y lee números:

```csharp
using System.Globalization;

// El formato de los números depende de la cultura: el idioma y la región del usuario
double frequency = 1234.5;
foreach (string name in new[] { "en-US", "fr-FR", "es-ES" })
{
    CultureInfo.CurrentCulture = new CultureInfo(name);
    bool ok = double.TryParse("1.5", out double parsed);
    Console.WriteLine($"{name}: {frequency:F1}  \"1.5\" read as {parsed} ({ok})");
}

// La cultura invariable da el mismo resultado en todas partes: úsala para archivos y datos
CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine(double.Parse("1.5"));
```

```text
en-US: 1234.5  "1.5" read as 1.5 (True)
fr-FR: 1234,5  "1.5" read as 0 (False)
es-ES: 1234,5  "1.5" read as 15 (True)
1.5
```

Con la cultura francesa, `"1.5"` no es un número. Con la cultura española es peor: el punto separa los miles en español, así que `"1.5"` se lee como **15**, sin ningún error. Las salidas de este curso se capturaron con una cultura inglesa; en un ordenador con cultura francesa o española, tus números decimales pueden imprimirse con coma. Para los datos que intercambian los programas, como los archivos, usa [`CultureInfo.InvariantCulture`](https://learn.microsoft.com/dotnet/api/system.globalization.cultureinfo.invariantculture), que es igual en todos los ordenadores. La [guía de globalización](https://learn.microsoft.com/dotnet/core/extensions/globalization) tiene los detalles.

`using System.Globalization;` al principio permite usar los nombres de ese *espacio de nombres* (*namespace*), un grupo de tipos relacionados, sin su largo prefijo. `Console` y `Math` no necesitan `using`: las aplicaciones basadas en archivos y los proyectos nuevos activan los [usings implícitos](https://learn.microsoft.com/dotnet/core/project-sdk/overview#implicit-using-directives) para los espacios de nombres más comunes.

## Puntos clave

- Una variable tiene un nombre, un tipo y un valor; `=` pone un valor en ella. El tipo nunca cambia, y `var` solo le pide al compilador que lo encuentre.
- `int` y `long` guardan números enteros, `double` decimales aproximados, `decimal` decimales exactos (para el dinero), `bool` verdadero o falso, `char` un carácter, `string` texto.
- Dividir dos enteros descarta los decimales; escribe `12.0` para obtener una división `double`.
- Las conversiones que amplían son automáticas; las que reducen necesitan un cast, como `(int)hertz`, que corta los decimales.
- `int.TryParse` convierte texto en número sin detener el programa cuando la entrada es incorrecta.
- Una cadena interpolada, `$"…{value,width:format}…"`, construye texto a partir de valores; `Console.ReadLine()` lee una línea escrita por el usuario.
- La cultura cambia cómo se imprimen y leen los números: usa la cultura invariable para los datos.

## Ejercicios

1. Una canción dura 3725 segundos. Usando solo enteros, `/` y `%`, imprime su duración como `1 h 02 min 05 s`. El formato `D2` imprime un entero con al menos dos dígitos.

<details>
<summary>Solución</summary>

[`exercises/l02_ex_duration.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l02_ex_duration.cs):

```csharp
// Ejercicio 1: una canción de 3725 segundos, en horas, minutos y segundos
int total = 3725;
int hours = total / 3600;
int minutes = total % 3600 / 60;
int seconds = total % 60;
Console.WriteLine($"{hours} h {minutes:D2} min {seconds:D2} s");
```

```text
1 h 02 min 05 s
```

`total / 3600` cuenta las horas completas. `total % 3600` es lo que queda después de ellas, 125 segundos, y `/ 60` cuenta sus minutos completos. `%` y `/` tienen la misma prioridad y se calculan de izquierda a derecha, así que `total % 3600 / 60` es `(total % 3600) / 60`.

</details>

2. Pide al usuario el precio de un juego de cuerdas y un número de juegos. Imprime el subtotal, un impuesto del 15 % redondeado al céntimo y el total, con dos decimales. Si alguna respuesta no es válida, imprime un mensaje en su lugar. ¿Qué tipo usas para el precio?

<details>
<summary>Solución</summary>

`decimal`, porque es dinero. [`exercises/l02_ex_order.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l02_ex_order.cs):

```csharp
// Ejercicio 2: leer un precio y una cantidad, imprimir el total con un 15 % de impuesto
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

Con `12.49` y `3`:

```text
Price of a set of strings? 12.49
How many sets? 3
Subtotal: 37.47
Tax: 5.62
Total: 43.09
```

`&&` significa «y»: las dos conversiones deben tener éxito. `Math.Round(…, 2)` redondea a dos decimales; el 15 % de 37.47 es 5.6205, redondeado a 5.62. En un ordenador con cultura francesa o española, escribe el precio con coma: `12,49`.

</details>

3. El traste 7 está una *quinta* por encima de la cuerda al aire. En la afinación de los instrumentos antiguos, una quinta multiplicaba la frecuencia exactamente por 3/2. ¿A qué distancia está la razón moderna, 2 elevado a 7/12, de 3/2? Imprime las dos con cinco decimales, y la diferencia como porcentaje de 3/2.

<details>
<summary>Solución</summary>

[`exercises/l02_ex_fifth.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l02_ex_fifth.cs):

```csharp
// Ejercicio 3: el traste 7 está una quinta por encima de la cuerda al aire. ¿Qué tan cerca está 2^(7/12) de 3/2?
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

Dos trampas: `7 / 12` sería `0`, y `3 / 2` sería `1`. Escribir `12.0` y `3.0` convierte ambas divisiones en divisiones `double`. La afinación moderna, el *temperamento igual*, hace que todos los semitonos tengan el mismo tamaño, para que una guitarra suene afinada en todas las tonalidades, a costa de quintas un 0,1 % demasiado estrechas.

</details>

## Fuentes

- [Tipos (fundamentos de C#)](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/), [tipos integrados](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/built-in-types)
- [Tipos numéricos enteros](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/integral-numeric-types), [tipos numéricos de punto flotante](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types), [operadores aritméticos](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/arithmetic-operators)
- [Conversiones de tipos y casts](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/conversions), [`Math.Round`](https://learn.microsoft.com/dotnet/api/system.math.round)
- [Interpolación de cadenas](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/interpolated), [cadenas de formato numérico estándar](https://learn.microsoft.com/dotnet/standard/base-types/standard-numeric-format-strings)
- [`Console.ReadLine`](https://learn.microsoft.com/dotnet/api/system.console.readline), [globalización](https://learn.microsoft.com/dotnet/core/extensions/globalization)
