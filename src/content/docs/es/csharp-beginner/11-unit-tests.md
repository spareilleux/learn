---
title: 11. Pruebas unitarias
description: Mover métodos a una biblioteca, probarlos con xUnit y dotnet test, leer el mensaje de una prueba que falla, dar a una prueba varias filas de datos, probar excepciones y doubles, y ver lo que dejan pasar las propias pruebas de Guitar Alchemist.
sidebar:
  order: 11
---

Hasta ahora, `check.sh` comprobaba los programas de este curso comparando toda su salida con un archivo. Una **prueba unitaria** comprueba un método directamente: lo llama con argumentos conocidos y compara el resultado con el valor que debería devolver. Una prueba también es un pequeño programa. Un **framework de pruebas** encuentra las pruebas, ejecuta cada una, cuenta los fallos y dice qué prueba falló y por qué. Esta lección usa [xUnit](https://xunit.net/), el framework de la plantilla `dotnet new xunit`, para probar métodos de las lecciones 4, 8 y 10.

El código de esta lección está en [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner): `examples/l11_by_hand.cs`, y la carpeta `l11-tests` con tres proyectos. `Fretboard` es una biblioteca, `Fretboard.Tests` contiene sus pruebas y las soluciones de los ejercicios, y las pruebas de `Pitfalls.Tests` fallan a propósito. `check.sh` ejecuta [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test) sobre los dos proyectos de pruebas y compara un resumen con los archivos de `expected/`.

## Una prueba a mano

Una prueba no necesita framework. Este programa llama cuatro veces al `FretFrequency` de la lección 4 y compara cada resultado con el valor que espera:

```csharp
// Una prueba a mano: llamar a un método, comparar su resultado con el valor esperado, y decir qué comprobación falló
int failed = 0;
Check("fret 12 of A2", FretFrequency(110.0, 12), 220.0);
Check("fret 7 of A2", FretFrequency(110.0, 7), 164.81);
Check("fret 5 of E2", FretFrequency(82.41, 5), 110.0);
Check("fret 1 of B3", FretFrequency(246.94, 1), 261.63);   // C4 en una tabla de frecuencias de notas
Console.WriteLine($"{failed} failed");

void Check(string name, double actual, double expected)
{
    if (actual == expected)
    {
        Console.WriteLine($"ok   {name}");
    }
    else
    {
        Console.WriteLine($"FAIL {name}: expected {expected}, got {actual}");
        failed++;
    }
}

// El método de la lección 4
double FretFrequency(double openString, int fret)
{
    double frequency = openString * Math.Pow(2, fret / 12.0);
    return Math.Round(frequency, 2);
}
```

```text
ok   fret 12 of A2
ok   fret 7 of A2
ok   fret 5 of E2
FAIL fret 1 of B3: expected 261.63, got 261.62
1 failed
```

La última comprobación falla, y el método no está mal. El valor esperado, 261.63 Hz, es el do central (do4) en una tabla de frecuencias. El método parte de 246.94, la cuerda Si al aire ya redondeada a dos decimales, y un traste por encima da 261.62. Una prueba que falla solo dice que dos valores difieren: puede estar mal el código, o el valor esperado, y tienes que averiguar cuál.

El programa también termina con el código de salida 0, como si todo hubiera pasado: un script que lo ejecuta no puede saber que una comprobación falló. `check.sh` también funciona así, con sus líneas `ok` y `FAIL`, pero fija su propio código de salida. Un framework de pruebas hace este trabajo por ti.

## Una biblioteca y un proyecto de pruebas

Un proyecto de pruebas no puede llamar a los métodos de una aplicación basada en archivos. Los métodos van a una **biblioteca de clases**, un proyecto sin instrucciones de nivel superior que usan otros proyectos, y las pruebas van a un segundo proyecto que la referencia. Tres comandos crean los dos a partir de una carpeta vacía, con las [plantillas del SDK](https://learn.microsoft.com/dotnet/core/tools/dotnet-new-sdk-templates):

```sh
dotnet new classlib -n Fretboard
dotnet new xunit -n Fretboard.Tests
dotnet add Fretboard.Tests reference Fretboard
```

Los dos primeros muestran `The template "Class Library" was created successfully.` y `The template "xUnit Test Project" was created successfully.`, y después restauran los paquetes; el tercero muestra ``Reference `..\Fretboard\Fretboard.csproj` added to the project.`` en Windows. Cada plantilla añade también un archivo de relleno, `Class1.cs` y `UnitTest1.cs`, que esta lección borró.

La biblioteca contiene los métodos de lecciones anteriores, sin cambios, como métodos `public static` de una clase en el espacio de nombres `Fretboard`:

```csharp
namespace Fretboard;

// Métodos de lecciones anteriores, movidos a una biblioteca para que un proyecto de pruebas pueda llamarlos
public static class Guitar
{
    static readonly string[] Chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

    // Lección 4: la frecuencia de un traste, redondeada a dos decimales
    public static double FretFrequency(double openString, int fret)
    {
        double frequency = openString * Math.Pow(2, fret / 12.0);
        return Math.Round(frequency, 2);
    }

    // Lección 4, ejercicio 2: una lista nueva con cada nota desplazada un número de semitonos
    public static List<string> Transpose(List<string> notes, int semitones)
    {
        List<string> result = [];
        foreach (string note in notes)
        {
            int index = Array.IndexOf(Chromatic, note);
            int moved = ((index + semitones) % 12 + 12) % 12;   // + 12 mantiene los pasos negativos en 0..11
            result.Add(Chromatic[moved]);
        }
        return result;
    }

    // Lección 8, ejercicio 2: un número de traste leído de un texto, de 0 a 24
    public static int ParseFret(string text)
    {
        int fret = int.Parse(text);
        ArgumentOutOfRangeException.ThrowIfNegative(fret);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(fret, 24);
        return fret;
    }
}
```

Un segundo archivo, `Project.cs`, contiene el record `Project` de la lección 10 con un método `Parse` para una línea de `data/ga-projects.csv`. El archivo del proyecto de pruebas, `Fretboard.Tests.csproj`, lista lo que eligió la plantilla con el SDK 10.0.112:

```xml
<ItemGroup>
  <PackageReference Include="coverlet.collector" Version="6.0.4" />
  <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
  <PackageReference Include="xunit" Version="2.9.3" />
  <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4" />
</ItemGroup>

<ItemGroup>
  <Using Include="Xunit" />
</ItemGroup>

<ItemGroup>
  <ProjectReference Include="..\Fretboard\Fretboard.csproj" />
</ItemGroup>
```

- `xunit` trae los atributos y `Assert`, y `<Using Include="Xunit" />` los hace disponibles en todos los archivos del proyecto sin un `using`.
- `xunit.runner.visualstudio` y `Microsoft.NET.Test.Sdk` permiten que `dotnet test` y los editores encuentren y ejecuten las pruebas; `coverlet.collector` mide qué líneas ejecutaron las pruebas, cuando se lo pides.
- `ProjectReference` es la línea que escribió `dotnet add reference`: las pruebas ya pueden usar las clases públicas de la biblioteca.

La plantilla crea un proyecto xUnit **v2**. El [sitio de xUnit](https://xunit.net/docs/getting-started/v2/netcore/cmdline) dice que v2 está en modo de mantenimiento, y anima a usar v3 para el trabajo nuevo; esta lección se queda con lo que da la plantilla.

## Una primera prueba

Una prueba es un método `public` con el atributo `[Fact]`, en una clase `public`:

```csharp
    // Un hecho (Fact): un solo caso, sin parámetro
    [Fact]
    public void FretFrequency_TwelfthFret_DoublesTheFrequency()
    {
        // Preparar: la cuerda La al aire
        double openA = 110.0;

        // Actuar
        double result = Guitar.FretFrequency(openA, 12);

        // Afirmar: el valor esperado va primero, el valor real después
        Assert.Equal(220.0, result);
    }
```

La mayoría de las pruebas tienen tres pasos: **preparar** los datos (*arrange*), **actuar** llamando al método (*act*), **afirmar** que el resultado es el esperado (*assert*). [`Assert.Equal`](https://xunit.net/docs/getting-started/v2/netcore/cmdline) lanza una excepción cuando sus dos valores difieren, y xUnit cuenta la prueba como fallida. El nombre de la prueba dice qué comprueba, en qué situación y qué debería pasar: cuando falla, el nombre basta para saber qué se ha roto.

`dotnet test` compila la biblioteca y el proyecto de pruebas, y después ejecuta todas las pruebas:

```sh
dotnet test l11-tests/Fretboard.Tests
```

Muestra las líneas de la restauración y de la compilación, y después una línea por proyecto de pruebas. `check.sh` conserva esa última línea, sin su duración, que cambia en cada ejecución:

```text
Passed!  - Failed:     0, Passed:    26, Skipped:     0, Total:    26 - Fretboard.Tests.dll (net10.0)
```

Las 26 pruebas son las de esta lección y las soluciones de sus ejercicios. El comando termina con el código de salida 0, y con 1 en cuanto falla una prueba: un script o un trabajo de CI ve el fallo sin leer el texto.

Los records se comparan por valor (lección 6), así que un solo `Assert.Equal` comprueba los cuatro campos que lee `Project.Parse`, y [`Assert.Throws`](https://xunit.net/docs/getting-started/v2/netcore/cmdline) comprueba que un método lanza una excepción:

```csharp
    [Fact]
    public void Parse_ReadsTheFourFields()
    {
        Project project = Project.Parse("GA.Core,C#,67,0");

        // Los records se comparan por valor: un solo Assert comprueba los cuatro campos
        Assert.Equal(new Project("GA.Core", "C#", 67, 0), project);
    }

    [Fact]
    public void Parse_RefusesALineWithoutNumbers()
    {
        Assert.Throws<FormatException>(() => Project.Parse("GA.Core,C#,many,0"));
    }
```

La lambda, `() => Project.Parse(...)`, le da a `Assert.Throws` la llamada que debe hacer en lugar de hacerla: la excepción ocurre dentro de `Assert.Throws`, que la captura y comprueba su tipo.

## Varios casos en una prueba

Una teoría, `[Theory]`, es una prueba con parámetros, y cada atributo `[InlineData]` le da una fila de argumentos:

```csharp
    // Una teoría: la misma prueba con varias filas de datos, cada fila una prueba aparte
    [Theory]
    [InlineData(110.0, 0, 110.0)]
    [InlineData(110.0, 7, 164.81)]
    [InlineData(82.41, 5, 110.0)]
    [InlineData(110.0, 12, 220.0)]
    public void FretFrequency_RoundsToTwoDecimals(double openString, int fret, double expected)
    {
        Assert.Equal(expected, Guitar.FretFrequency(openString, fret));
    }
```

xUnit cuenta cada fila como una prueba propia: con esta teoría, la primera versión del proyecto tenía 15 pruebas, no 12. Una fila que falla se informa con sus argumentos, como muestra la sección siguiente, y las demás filas se ejecutan igualmente.

## Cuando una prueba falla

Las cuatro pruebas de `Pitfalls.Tests` fallan a propósito. Cada una comete un error típico de principiante, y `dotnet test` lo explica:

```csharp
    // 0.1 + 0.2 no es exactamente 0.3 en un double
    [Fact]
    public void Doubles_ComparedBitForBit()
    {
        Assert.Equal(0.3, 0.1 + 0.2);
    }

    // ParseFret lanza ArgumentOutOfRangeException, un tipo derivado de ArgumentException
    [Fact]
    public void Throws_WithTheBaseType()
    {
        Assert.Throws<ArgumentException>(() => Guitar.ParseFret("25"));
    }

    // Los argumentos están intercambiados: el mensaje llama "Expected" al resultado del método
    [Fact]
    public void Equal_WithTheArgumentsSwapped()
    {
        Assert.Equal(Guitar.FretFrequency(110.0, 7), 164.8);
    }

    // Una fila de la teoría está mal: E subido un semitono es F
    [Theory]
    [InlineData("C", 2, "D")]
    [InlineData("B", 1, "C")]
    [InlineData("E", 1, "F#")]
    public void Transpose_OneNote(string note, int semitones, string expected)
    {
        Assert.Equal([expected], Guitar.Transpose([note], semitones));
    }
```

`check.sh` conserva las advertencias de la compilación, el mensaje de cada prueba fallida y la última línea. Quita las rutas, las duraciones y la *pila de llamadas* (*stack trace*), la lista de llamadas a métodos que llevaron al fallo, y ordena las pruebas fallidas por nombre: xUnit no las informa en el orden del archivo.

```text
PitfallTests.cs(26,9): warning xUnit2000: The literal or constant value 164.8 should be passed as the 'expected' argument in the call to 'Assert.Equal(expected, actual)' in method 'Equal_WithTheArgumentsSwapped' on type 'PitfallTests'. Swap the parameter values. (https://xunit.net/xunit.analyzers/rules/xUnit2000)
  Failed Pitfalls.Tests.PitfallTests.Doubles_ComparedBitForBit
  Error Message:
   Assert.Equal() Failure: Values differ
Expected: 0.29999999999999999
Actual:   0.30000000000000004
  Failed Pitfalls.Tests.PitfallTests.Equal_WithTheArgumentsSwapped
  Error Message:
   Assert.Equal() Failure: Values differ
Expected: 164.81
Actual:   164.80000000000001
  Failed Pitfalls.Tests.PitfallTests.Throws_WithTheBaseType
  Error Message:
   Assert.Throws() Failure: Exception type was not an exact match
Expected: typeof(System.ArgumentException)
Actual:   typeof(System.ArgumentOutOfRangeException)
---- System.ArgumentOutOfRangeException : fret ('25') must be less than or equal to '24'. (Parameter 'fret')
Actual value was 25.
  Failed Pitfalls.Tests.PitfallTests.Transpose_OneNote(note: "E", semitones: 1, expected: "F#")
  Error Message:
   Assert.Equal() Failure: Collections differ
           ↓ (pos 0)
Expected: ["F#"]
Actual:   ["F"]
           ↑ (pos 0)
Failed!  - Failed:     4, Passed:     2, Skipped:     0, Total:     6 - Pitfalls.Tests.dll (net10.0)
```

Las 2 pruebas que pasan son las dos primeras filas de la teoría. Lee cada mensaje desde arriba:

- **Doubles.** Un `double` no puede guardar exactamente 0.1, 0.2 ni 0.3, así que `0.1 + 0.2` y `0.3` son dos números ligeramente distintos. xUnit muestra los dos con 17 cifras para enseñar la diferencia: incluso `0.3` se convierte en `0.29999999999999999`. Compara los doubles con un número de decimales, `Assert.Equal(0.3, 0.1 + 0.2, 10)`, que pasa. Las pruebas de `FretFrequency` no lo necesitan: el método redondea con `Math.Round`, y el resultado redondeado es el mismo `double` que el literal `164.81` de la prueba.
- **Tipos de excepción.** `Assert.Throws<ArgumentException>` quiere exactamente ese tipo. `ParseFret` lanza [`ArgumentOutOfRangeException`](https://learn.microsoft.com/dotnet/api/system.argumentoutofrangeexception), una clase derivada de `ArgumentException` (lección 8): el mensaje muestra los dos tipos, y la excepción que se lanzó. Indica el tipo exacto, o usa `Assert.ThrowsAny<ArgumentException>`, que también acepta los tipos derivados.
- **Argumentos intercambiados.** El valor esperado va primero. Aquí el literal va segundo, así que el mensaje llama «Expected» al resultado del método, 164.81, y «Actual» al valor incorrecto, 164.8: lo contrario de la verdad. El compilador avisó antes de que se ejecutaran las pruebas: [xUnit2000](https://xunit.net/xunit.analyzers/rules/xUnit2000) viene de un *analizador*, una comprobación que el paquete `xunit` añade al compilador.
- **Una fila incorrecta.** El nombre de la prueba muestra los argumentos de la fila fallida, y las flechas señalan el primer elemento que difiere. Esta vez el código está bien y la prueba está mal: mi (E) subido un semitono es fa (F).

Las correcciones de las dos primeras están en `Fretboard.Tests`; las dos últimas son el ejercicio 3:

```csharp
    // Assert.ThrowsAny también acepta un tipo derivado: ArgumentOutOfRangeException es una ArgumentException
    [Fact]
    public void ParseFret_RefusesANegativeFret()
    {
        Assert.ThrowsAny<ArgumentException>(() => Guitar.ParseFret("-1"));
    }

    // Aquí se comparan dos doubles con 10 decimales, no bit a bit
    [Fact]
    public void Doubles_CompareWithAPrecision()
    {
        Assert.Equal(0.3, 0.1 + 0.2, 10);
    }
```

## Un objeto por prueba

xUnit crea un objeto nuevo de la clase de pruebas para cada prueba. Un campo no lleva nada de una prueba a la siguiente:

```csharp
// xUnit crea un objeto nuevo de la clase de pruebas para cada prueba, así que un campo empieza en 0 en cada prueba
public class InstanceTests
{
    int _count;

    [Fact]
    public void FirstTest()
    {
        _count++;
        Assert.Equal(1, _count);
    }

    [Fact]
    public void SecondTest()
    {
        _count++;
        Assert.Equal(1, _count);
    }
}
```

Las dos pruebas pasan: cada una ve `_count` en 0. Una prueba no puede contar con que otra se haya ejecutado antes, y no lo necesita: cada prueba prepara sus propios datos.

## Probar lo que la biblioteca hace público

El proyecto de pruebas es otro programa: llama a la biblioteca desde fuera, y solo ve sus miembros `public`. Un miembro sin `public` es privado de su clase, como en este fragmento, donde las instrucciones de nivel superior hacen el papel de la prueba:

```csharp
// Una prueba llama a la biblioteca desde fuera: solo ve lo que la biblioteca hace público
Console.WriteLine(Guitar.Chromatic.Length);

static class Guitar
{
    static readonly string[] Chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
}
```

```text
l11_private.cs(2,26): error CS0122: 'Guitar.Chromatic' is inaccessible due to its protection level
```

[CS0122](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/cs0122) dice que el miembro existe pero no se puede alcanzar desde aquí. Desde un proyecto de pruebas, un miembro marcado `internal`, visible solo dentro de su propio proyecto, da otro error: en un par de proyectos de borrador, el compilador respondió [CS0117](https://learn.microsoft.com/dotnet/csharp/misc/cs0117), `'Lab' does not contain a definition for 'Secret'`, como si el método no existiera. El atributo [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute) puede abrir los miembros internos de una biblioteca a sus pruebas. Probar a través de los métodos públicos suele ser mejor: las pruebas comprueban entonces lo que usan los demás proyectos, y siguen pasando cuando reescribes el interior de un método.

## En Guitar Alchemist

En el commit `5c3a52a`, Guitar Alchemist tiene 18 proyectos de pruebas. 16 archivos de proyecto referencian [NUnit](https://docs.nunit.org/), otro framework de pruebas, y 3 referencian xUnit. Las ideas son las mismas, con otros nombres: `[Test]` por `[Fact]`, `[TestCase]` por `[InlineData]`, `Assert.That(actual, Is.EqualTo(expected))` por `Assert.Equal(expected, actual)`, y `[Ignore("reason")]` para omitir una prueba.

**Las pruebas de los archivos YAML.** La lección 9 encontró que tres de los cuatro archivos YAML de los servicios de conocimiento musical de GA no se cargan, lo que ahora es la [issue #797 de GA](https://github.com/GuitarAlchemist/ga/issues/797). GA tiene pruebas para estos servicios, en [`MusicalKnowledgeServiceTests.cs`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs). Tres de sus ocho pruebas se omiten con [`[Ignore("Configuration files not loaded in test environment")]`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs#L108-L110), y de las otras cinco, tres solo comprueban que un recuento es [mayor que cero](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs#L28-L33) o que una lista no está vacía. Una [sonda](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner/ga-probes/knowledge-tests) compiló este archivo sin cambios, con los servicios de GA y los mismos paquetes NUnit, y lo ejecutó: 5 pruebas pasaron, 3 se omitieron, ninguna falló. La búsqueda de «jazz» pasó con un resultado: la progresión de acordes por defecto que el cargador conserva tras su fallo. Una prueba que comprueba «más que cero» no puede ver un cargador que falla y devuelve un elemento por defecto; una prueba que comprobara el número real de elementos, o que la carga no informa de ningún error, sí podría.

**Una preparación que nunca se ejecuta.** El mismo proyecto de pruebas tiene una clase, [`TestEnvironment`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/TestBootstrap/TestEnvironment.cs#L1-L14), marcada `[SetUpFixture]`, que mueve el directorio actual a la raíz del repositorio. Su comentario dice que «ensures configuration-backed services can locate their YAML/JSON inputs during tests» (garantiza que los servicios basados en la configuración puedan encontrar sus entradas YAML/JSON durante las pruebas): el problema de la lección 10, resuelto para las pruebas. Pero NUnit ejecuta un *setup fixture* solo antes de las pruebas [de su propio espacio de nombres](https://docs.nunit.org/articles/nunit/writing-tests/attributes/setupfixture.html), y este está solo en `GA.Business.Core.Tests.TestBootstrap`. Una prueba de la sonda, colocada junto a las pruebas YAML, vio el directorio actual todavía en su carpeta `bin`, y `GA_TEST_MODE`, que la preparación define, sin definir. Los archivos YAML se encuentran de todos modos, junto al programa, donde los copia la compilación.

**Pruebas que no se compilan.** El archivo de proyecto [quita 35 archivos de la compilación](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/GA.Business.Core.Tests.csproj#L39-L75), bajo el comentario «Exclude test files with missing service implementations» (excluir los archivos de prueba cuyos servicios no tienen implementación). Cinco de los nombres ya no corresponden a ningún archivo; los otros 30 archivos contienen 333 líneas que empiezan por `[Test]` o `[TestCase]`. Una prueba que no se compila nunca falla, y `dotnet test` no la menciona.

La [tabla QA del diario](../journal/#qa) registra estas mediciones.

## Ejercicios

Las soluciones son pruebas de `Fretboard.Tests`, en `ExerciseTests.cs`: `dotnet test` las ejecuta con las demás.

### Ejercicio 1 — transponer hacia abajo

Escribe una prueba que compruebe que `Guitar.Transpose(["A", "C", "E"], -3)` devuelve F#, A y C#.

<details>
<summary>Solución</summary>

```csharp
    // Ejercicio 1: transponer hacia abajo
    [Fact]
    public void Transpose_MovesEachNoteDown()
    {
        List<string> result = Guitar.Transpose(["A", "C", "E"], -3);

        Assert.Equal(["F#", "A", "C#"], result);
    }
```

`Assert.Equal` compara dos listas elemento a elemento; la expresión de colección `["F#", "A", "C#"]` toma el tipo del otro argumento.

</details>

### Ejercicio 2 — los límites de `ParseFret`

Los bugs se esconden en los límites. Prueba que `ParseFret` acepta `"0"` y `"24"`, rechaza `"-1"` y `"25"` con `ArgumentOutOfRangeException`, y rechaza `"seven"` con `FormatException`. Usa teorías donde una prueba tenga varias filas.

<details>
<summary>Solución</summary>

```csharp
    // Ejercicio 2: los límites de ParseFret
    [Theory]
    [InlineData("0", 0)]
    [InlineData("24", 24)]
    public void ParseFret_AcceptsTheFirstAndLastFret(string text, int expected)
    {
        Assert.Equal(expected, Guitar.ParseFret(text));
    }

    [Theory]
    [InlineData("-1")]
    [InlineData("25")]
    public void ParseFret_RefusesTheFretsJustOutside(string text)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Guitar.ParseFret(text));
    }

    [Fact]
    public void ParseFret_RefusesAWord()
    {
        Assert.Throws<FormatException>(() => Guitar.ParseFret("seven"));
    }
```

Cada límite tiene un valor justo dentro, 0 y 24, y un valor justo fuera, -1 y 25. Si alguien escribe `ThrowIfGreaterThan(fret, 23)` por error, la fila `"24"` falla.

</details>

### Ejercicio 3 — corregir las dos pruebas incorrectas

Dos pruebas de `Pitfalls.Tests` esperan el valor equivocado: `Equal_WithTheArgumentsSwapped` y la fila `"E", 1, "F#"` de `Transpose_OneNote`. Escribe versiones correctas de las dos.

<details>
<summary>Solución</summary>

```csharp
    // Ejercicio 3: las dos trampas cuyo valor esperado estaba mal, corregidas
    [Fact]
    public void Equal_WithTheExpectedValueFirst()
    {
        Assert.Equal(164.81, Guitar.FretFrequency(110.0, 7));
    }

    [Theory]
    [InlineData("C", 2, "D")]
    [InlineData("B", 1, "C")]
    [InlineData("E", 1, "F")]
    public void Transpose_OneNote(string note, int semitones, string expected)
    {
        Assert.Equal([expected], Guitar.Transpose([note], semitones));
    }
```

La primera corrección pone el literal primero y usa el valor correcto, 164.81: la advertencia xUnit2000 también desaparece. En la segunda, el código estaba bien: la corrección está en la prueba.

</details>

### Ejercicio 4 — una prueba que lee un archivo

Escribe una prueba que lea `data/ga-projects.csv` con `Project.Parse` y compruebe que contiene 12 proyectos y 632 archivos fuente, `.cs` y `.fs` juntos. Aquí importan dos cosas de la lección 10: el archivo debe copiarse junto a las pruebas compiladas, y una prueba no debería depender del directorio actual.

<details>
<summary>Solución</summary>

Un [elemento `None`](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#none) en `Fretboard.Tests.csproj` copia el archivo en la carpeta de salida, bajo `data`:

```xml
<ItemGroup>
  <None Include="..\..\data\ga-projects.csv" Link="data\ga-projects.csv" CopyToOutputDirectory="PreserveNewest" />
</ItemGroup>
```

La prueba construye la ruta a partir de [`AppContext.BaseDirectory`](https://learn.microsoft.com/dotnet/api/system.appcontext.basedirectory), la carpeta de las pruebas compiladas:

```csharp
    // Ejercicio 4: una prueba que lee data/ga-projects.csv, copiado junto a las pruebas por Fretboard.Tests.csproj
    [Fact]
    public void GaProjects_HoldSixHundredThirtyTwoSourceFiles()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "data", "ga-projects.csv");

        List<Project> projects = File.ReadLines(path).Skip(1).Select(Project.Parse).ToList();

        Assert.Equal(12, projects.Count);
        Assert.Equal(632, projects.Sum(p => p.SourceFiles));
    }
```

`Select(Project.Parse)` le da a LINQ el propio método, como `Count(IsFSharp)` en la lección 9. 632 son los 557 archivos C# y los 75 archivos F# de la lección 10.

</details>

## Lo que debes recordar

- Una prueba unitaria llama a un método con argumentos conocidos y compara su resultado con el valor esperado. Un framework de pruebas ejecuta todas las pruebas, cuenta los fallos y fija el código de salida.
- Las pruebas van en un proyecto de pruebas que referencia una biblioteca de clases: `dotnet new classlib`, `dotnet new xunit`, `dotnet add reference`. `dotnet test` compila los dos y ejecuta las pruebas.
- `[Fact]` marca una prueba; `[Theory]` con `[InlineData]` ejecuta la misma prueba una vez por fila, y cada fila cuenta como una prueba.
- `Assert.Equal(expected, actual)`: el valor esperado primero. Compara los doubles con un número de decimales. `Assert.Throws<T>` quiere el tipo exacto; `Assert.ThrowsAny<T>` acepta los tipos derivados.
- Una prueba que falla dice que dos valores difieren: comprueba si está mal el código o la prueba antes de cambiar uno u otra.
- xUnit crea un objeto nuevo para cada prueba, y no promete ningún orden. Un proyecto de pruebas solo ve los miembros públicos de la biblioteca.
- Una prueba que se omite, que no se compila o que solo comprueba «más que cero» puede pasar mientras el código está roto.

La siguiente lección, [un pequeño proyecto](../#plan): una solución con esta biblioteca, una aplicación de consola y estas pruebas, un paquete NuGet, y un primer vistazo a `async`.

## Fuentes

- xUnit: [primeros pasos con xUnit.net v2](https://xunit.net/docs/getting-started/v2/netcore/cmdline), [regla del analizador xUnit2000](https://xunit.net/xunit.analyzers/rules/xUnit2000)
- .NET: [pruebas unitarias de C# con xUnit](https://learn.microsoft.com/dotnet/core/testing/unit-testing-csharp-with-xunit), [procedimientos recomendados para pruebas unitarias](https://learn.microsoft.com/dotnet/core/testing/unit-testing-best-practices), [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test), [plantillas de `dotnet new`](https://learn.microsoft.com/dotnet/core/tools/dotnet-new-sdk-templates), [`dotnet add reference`](https://learn.microsoft.com/dotnet/core/tools/dotnet-reference-add), [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute), [`ArgumentOutOfRangeException`](https://learn.microsoft.com/dotnet/api/system.argumentoutofrangeexception), [`AppContext.BaseDirectory`](https://learn.microsoft.com/dotnet/api/system.appcontext.basedirectory), [elementos de MSBuild](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#none)
- NUnit: [documentación](https://docs.nunit.org/), [`SetUpFixture`](https://docs.nunit.org/articles/nunit/writing-tests/attributes/setupfixture.html)
- Errores del compilador [CS0122](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/cs0122), [CS0117](https://learn.microsoft.com/dotnet/csharp/misc/cs0117)
