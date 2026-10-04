---
title: 12. Un pequeño proyecto
description: Reunir en una solución la biblioteca de la lección 11, una aplicación de consola y sus pruebas, usar un paquete de NuGet, crear un paquete propio, dar un primer vistazo a async y await, y ver lo que dejan pasar la solución, las versiones de paquetes y la herramienta de línea de comandos de Guitar Alchemist.
sidebar:
  order: 12
---

Los programas de este curso eran archivos sueltos, y la lección 11 añadió una biblioteca y sus pruebas. Un programa real suele estar formado por varios proyectos: una biblioteca que contiene la lógica, una aplicación que la gente ejecuta, y pruebas. Esta última lección los reúne en una **solución**. Añade un paquete de [NuGet](https://learn.microsoft.com/nuget/what-is-nuget), el gestor de paquetes de .NET, convierte la biblioteca en un paquete propio, y da un primer vistazo a `async` y `await`, la forma que tiene C# de esperar un archivo o la red sin bloquearse.

El código de esta lección está en [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner): la carpeta `l12-project` con la solución y sus tres proyectos, y los archivos `l12_*.cs` de `examples`, `exercises` y `compile_fail`. `check.sh` ejecuta las pruebas, compila la solución, ejecuta la aplicación de consola con unos cuantos comandos y empaqueta la biblioteca, y después compara cada salida con los archivos de `expected/`.

## Una solución para tres proyectos

Una solución es un archivo que lista proyectos, para que un solo comando los compile o los pruebe todos. A partir de una carpeta vacía, estos comandos crean la solución, los tres proyectos y las referencias entre ellos:

```sh
dotnet new sln -n Fretboard
dotnet new classlib -o Fretboard
dotnet new console -o Fretboard.App
dotnet new xunit -o Fretboard.Tests
dotnet sln add Fretboard Fretboard.App Fretboard.Tests
dotnet add Fretboard.App reference Fretboard
dotnet add Fretboard.Tests reference Fretboard
```

Con el SDK 10, `dotnet new sln` crea `Fretboard.slnx`, una solución escrita en XML. Los SDK anteriores creaban un archivo `.sln` en un formato de texto más antiguo, que [`dotnet sln migrate`](https://learn.microsoft.com/dotnet/core/tools/dotnet-sln) convierte. Después de `dotnet sln add`, el archivo lista los tres proyectos:

```xml
<Solution>
  <Project Path="Fretboard.App/Fretboard.App.csproj" />
  <Project Path="Fretboard.Tests/Fretboard.Tests.csproj" />
  <Project Path="Fretboard/Fretboard.csproj" />
</Solution>
```

Una solución solo lista proyectos. Qué proyecto usa a cuál se escribe en los archivos de proyecto, con `dotnet add reference`, como en la lección 11. En la carpeta de la solución, [`dotnet build`](https://learn.microsoft.com/dotnet/core/tools/dotnet-build) compila los tres proyectos. `check.sh` conserva sus nombres, ordenados, y los recuentos del final; la salida real da la ruta de cada archivo compilado:

```text
Fretboard
Fretboard.App
Fretboard.Tests
0 Warning(s)
0 Error(s)
```

`dotnet test` en la misma carpeta ejecuta las pruebas del único proyecto de pruebas:

```text
Passed!  - Failed:     0, Passed:     6, Skipped:     0, Total:     6 - Fretboard.Tests.dll (net10.0)
```

`dotnet test` solo compila lo que necesitan las pruebas: el proyecto de pruebas y la biblioteca. Después de `dotnet clean` y `dotnet test`, `check.sh` no encuentra ningún `Fretboard.App` compilado. Con un error de compilación añadido al `Program.cs` de la aplicación, `dotnet test` siguió pasando y terminó con 0, mientras que `dotnet build` falló. Que las pruebas pasen no demuestra que toda la solución compile: ejecuta también `dotnet build`.

La biblioteca es el `Fretboard` de la lección 11, con `Guitar` sin cambios, `Project` sin su método `Parse`, y una clase nueva, `ProjectFile`, que se muestra más abajo. El proyecto de pruebas contiene dos pruebas de `Guitar` y dos de `ProjectFile`.

## La aplicación de consola

`Fretboard.App` es una pequeña herramienta de línea de comandos construida sobre la biblioteca. Su primer argumento nombra un comando, y los demás son los argumentos de ese comando:

```csharp
using System.Globalization;
using Fretboard;

// Una pequeña herramienta de línea de comandos sobre la biblioteca: el primer argumento es el comando
const string Usage = "usage: fret <open-string-hz> <fret> | transpose <semitones> <notes...> | projects <file.csv>";

if (args.Length == 0)
{
    Console.Error.WriteLine(Usage);
    return 1;
}

try
{
    switch (args[0])
    {
        case "fret" when args.Length == 3:
            double openString = double.Parse(args[1], CultureInfo.InvariantCulture);
            int fret = Guitar.ParseFret(args[2]);
            Console.WriteLine(Guitar.FretFrequency(openString, fret).ToString(CultureInfo.InvariantCulture));
            return 0;

        case "transpose" when args.Length >= 3:
            List<string> notes = [.. args[2..]];
            Console.WriteLine(string.Join(" ", Guitar.Transpose(notes, int.Parse(args[1]))));
            return 0;

        case "projects" when args.Length == 2:
            List<Project> projects = await ProjectFile.ReadAsync(args[1]);
            Console.WriteLine($"{projects.Count} projects, {projects.Sum(p => p.SourceFiles)} source files");
            return 0;

        default:
            Console.Error.WriteLine(Usage);
            return 1;
    }
}
catch (Exception e) when (e is FormatException or ArgumentException or IOException)
{
    // Un mensaje y el código de salida 1: un script que ejecuta la herramienta ve que falló
    Console.Error.WriteLine($"error: {e.Message}");
    return 1;
}
```

[`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) la ejecuta: `--project` nombra el proyecto, y las palabras que van después de `--` van al programa, en `args`. `check.sh` ejecuta seis comandos desde la carpeta del curso, como `dotnet run --project l12-project/Fretboard.App -- fret 110 7`, y muestra el código de salida después de cada uno. Quita la carpeta del nombre del archivo que falta; el mensaje real da su ruta completa:

```text
> fret 110 7
164.81
-> exit code 0
> transpose 2 C E G
D F# A
-> exit code 0
> projects data/ga-projects.csv
12 projects, 632 source files
-> exit code 0
> fret 110 25
error: fret ('25') must be less than or equal to '24'. (Parameter 'fret')
Actual value was 25.
-> exit code 1
> projects missing.csv
error: Could not find file 'missing.csv'.
-> exit code 1
> (no arguments)
usage: fret <open-string-hz> <fret> | transpose <semitones> <notes...> | projects <file.csv>
-> exit code 1
```

- El **código de salida** le dice al programa que inició este si tuvo éxito: 0 para el éxito, cualquier otro valor para un fallo. Las instrucciones de nivel superior lo devuelven con `return`, como lo haría `Main` ([`Main` y su valor de retorno](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/main-command-line)). Bash guarda el código del último comando en `$?`, PowerShell en `$LASTEXITCODE`; los scripts y la CI lo comprueban, como hace `check.sh`.
- Los errores van a [`Console.Error`](https://learn.microsoft.com/dotnet/api/system.console.error), la salida de error estándar, para que no se mezclen con los resultados cuando la salida va a un archivo.
- `catch (Exception e) when (...)` es un [filtro de excepciones](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements#the-try-catch-statement): solo captura las excepciones para las que la condición es verdadera. Cualquier otra excepción sigue deteniendo el programa, con un código distinto de cero.
- `case "fret" when args.Length == 3` es una [protección de caso](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#case-guards): el caso solo coincide si el texto es `fret` y hay tres argumentos.

## Un paquete de NuGet

La lección 10 leyó con `TextFieldParser` un valor CSV entre comillas. [CsvHelper](https://joshclose.github.io/CsvHelper/) es una biblioteca para archivos CSV, publicada en [nuget.org](https://www.nuget.org/packages/CsvHelper/). Una aplicación basada en archivos nombra un paquete con una línea `#:package`, con la versión después de `@` ([aplicaciones basadas en archivos](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps)):

```csharp
#:package CsvHelper@33.1.0
using System.Globalization;
using CsvHelper;

// La línea de la lección 10, leída esta vez por el paquete CsvHelper de NuGet
string line = "\"Crosby, Stills & Nash\",Suite: Judy Blue Eyes,1969";
using var parser = new CsvParser(new StringReader(line), CultureInfo.InvariantCulture);
parser.Read();
string[] fields = parser.Record!;
Console.WriteLine($"CsvHelper: {fields.Length} fields: {string.Join(" | ", fields)}");
```

```text
CsvHelper: 3 fields: Crosby, Stills & Nash | Suite: Judy Blue Eyes | 1969
```

El primer `dotnet run` descarga el paquete en una carpeta que comparten todos tus proyectos, la [carpeta global de paquetes](https://learn.microsoft.com/nuget/consume-packages/managing-the-global-packages-and-cache-folders), `.nuget/packages` en tu carpeta personal. La versión es obligatoria: sin `@33.1.0`, la restauración se detiene con [NU1015](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1015). El `.csproj` del mensaje es el proyecto que el SDK compila detrás de una aplicación basada en archivos:

```text
l12_package_no_version.csproj : error NU1015: The following PackageReference item(s) do not have a version specified: CsvHelper
```

En un proyecto, [`dotnet add package`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-add) escribe un `PackageReference` en el archivo de proyecto. El 3 de octubre de 2026, `dotnet add Fretboard package CsvHelper` eligió la última versión estable y escribió esto en `Fretboard.csproj`:

```xml
<ItemGroup>
  <PackageReference Include="CsvHelper" Version="33.1.0" />
</ItemGroup>
```

La biblioteca lo usa en `ProjectFile`, que lee el `ga-projects.csv` de la lección 10 y lo convierte en records `Project`:

```csharp
using System.Globalization;
using CsvHelper;

namespace Fretboard;

// Lee un archivo CSV de proyectos con el paquete CsvHelper, que entiende los valores entre comillas
public static class ProjectFile
{
    // Desde cualquier texto: un archivo, o una cadena en una prueba
    public static List<Project> Read(TextReader text)
    {
        using var csv = new CsvReader(text, CultureInfo.InvariantCulture);
        return csv.GetRecords<Project>().ToList();
    }

    public static List<Project> Read(string path)
    {
        using var reader = new StreamReader(path);
        return Read(reader);
    }

    // Lo mismo, pero el programa puede hacer otra cosa mientras se lee el archivo
    public static async Task<List<Project>> ReadAsync(string path)
    {
        string text = await File.ReadAllTextAsync(path);
        return Read(new StringReader(text));
    }
}
```

`GetRecords<Project>()` empareja las columnas de la cabecera con los parámetros del constructor del record, por nombre: `Name`, `Language`, `CsFiles`, `FsFiles`. No toca la propiedad calculada `SourceFiles`. `Read` recibe un [`TextReader`](https://learn.microsoft.com/dotnet/api/system.io.textreader), la clase base de `StreamReader` y `StringReader`: el programa le da un archivo, y una prueba puede darle una cadena. Esta prueba comprueba las comillas:

```csharp
    [Fact]
    public void Read_KeepsACommaInsideQuotes()
    {
        string text = """
            Name,Language,CsFiles,FsFiles
            "Demos, music theory",C#,3,0
            """;

        List<Project> projects = ProjectFile.Read(new StringReader(text));

        Assert.Equal([new Project("Demos, music theory", "C#", 3, 0)], projects);
    }
```

El texto entre `"""` es un literal de cadena sin formato: puede contener comillas y saltos de línea, y se le quita la sangría hasta la columna de las `"""` de cierre ([literales de cadena sin formato](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/raw-string)). Dos records con los mismos valores son iguales, como mostró la lección 6, así que `Assert.Equal` puede comparar listas de ellos.

**Un paquete con una vulnerabilidad conocida.** Cuando restaura los paquetes, NuGet los compara con una base de datos de avisos de seguridad ([auditoría de paquetes](https://learn.microsoft.com/nuget/concepts/auditing-packages)). La versión 12.0.1 de Newtonsoft.Json, una biblioteca JSON muy usada, tiene uno:

```csharp
#:package Newtonsoft.Json@12.0.1
using Newtonsoft.Json;

// Una versión antigua de un paquete muy usado: la restauración avisa de que tiene una vulnerabilidad conocida
Console.WriteLine(JsonConvert.SerializeObject(new { Chord = "Am7", Frets = "x02010" }));
```

```text
l12_audit.csproj : warning NU1903: Package 'Newtonsoft.Json' 12.0.1 has a known high severity vulnerability, https://github.com/advisories/GHSA-5crp-9r3c-p9vr
l12_audit.csproj : warning NU1903: Package 'Newtonsoft.Json' 12.0.1 has a known high severity vulnerability, https://github.com/advisories/GHSA-5crp-9r3c-p9vr
{"Chord":"Am7","Frets":"x02010"}
```

La advertencia aparece dos veces, y el programa se ejecuta. NU1903 corresponde a una gravedad alta; NU1901, NU1902 y NU1904, a una gravedad baja, moderada y crítica ([NU1901–NU1904](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1901-nu1904)). La página del aviso da la primera versión corregida: la corrección es usar esa versión o una posterior. En un proyecto, [`dotnet package list --vulnerable`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-list) muestra una tabla de esos paquetes. Terminó con 0 incluso cuando la tabla listaba uno.

## Tu propio paquete

[`dotnet pack`](https://learn.microsoft.com/dotnet/core/tools/dotnet-pack) convierte una biblioteca en un paquete, un archivo `.nupkg`:

```sh
dotnet pack Fretboard
```

```text
The package Fretboard.1.0.0 is missing a readme. Go to https://aka.ms/nuget/authoring-best-practices/readme to learn why package readmes are important.
Successfully created package 'Fretboard.1.0.0.nupkg'.
```

`check.sh` también quita aquí la carpeta: el paquete está en `Fretboard/bin/Release`.

- Sin opciones, `dotnet pack` compila en Release, no en Debug.
- La versión es 1.0.0 porque el proyecto no fija ninguna. `<Version>` en el archivo de proyecto la cambia, y el paquete toma el nombre del proyecto salvo que `<PackageId>` le dé otro ([propiedades de paquete](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#package-properties)).
- El mensaje sobre el readme es un consejo, no un error: nuget.org muestra el readme de un paquete en su página.
- Un `.nupkg` es un archivo zip. Contiene `lib/net10.0/Fretboard.dll` y `Fretboard.nuspec`, que describe el paquete y lista CsvHelper como dependencia: un proyecto que instala Fretboard recibe también CsvHelper. El ejercicio 4 mira dentro.

[`dotnet nuget push`](https://learn.microsoft.com/dotnet/core/tools/dotnet-nuget-push) publica un paquete en nuget.org, con una cuenta y una clave de API. Este curso no lo publica.

## Un primer vistazo a `async`

Leer un archivo o llamar a un servicio web lleva tiempo, y el programa no hace más que esperar. Con `await`, espera sin bloquear su hilo, que puede hacer otro trabajo mientras tanto ([programación asíncrona](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/)). Un método que devuelve un [`Task`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task) representa un trabajo que termina más tarde; `await` lo espera y da su resultado:

```csharp
using System.Diagnostics;

// await: el programa espera el archivo sin bloquear su hilo
string[] lines = await File.ReadAllLinesAsync(Path.Combine("data", "ga-projects.csv"));
Console.WriteLine($"{lines.Length - 1} projects");

// Dos esperas de medio segundo, una después de otra
var watch = Stopwatch.StartNew();
await Task.Delay(500);
await Task.Delay(500);
Console.WriteLine($"One after the other, at least 1 s: {watch.ElapsedMilliseconds >= 1000}");

// Las mismas dos esperas iniciadas a la vez: Task.WhenAll termina cuando las dos han terminado
watch.Restart();
Task first = Task.Delay(500);
Task second = Task.Delay(500);
await Task.WhenAll(first, second);
Console.WriteLine($"Together, under 0.9 s: {watch.ElapsedMilliseconds < 900}");
```

```text
12 projects
One after the other, at least 1 s: True
Together, under 0.9 s: True
```

- [`File.ReadAllLinesAsync`](https://learn.microsoft.com/dotnet/api/system.io.file.readalllinesasync) es el gemelo asíncrono del `File.ReadAllLines` de la lección 10; `await` da su `string[]`.
- [`Task.Delay(500)`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.delay) es una tarea que termina al cabo de 500 milisegundos, y [`Stopwatch`](https://learn.microsoft.com/dotnet/api/system.diagnostics.stopwatch) mide el tiempo. Dos retardos esperados uno después de otro tardan un segundo. Iniciados primero y esperados juntos con [`Task.WhenAll`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall), tardan medio segundo: las dos esperas se solapan. Cinco ejecuciones midieron de 1014 a 1023 ms, y después de 508 a 514 ms. El programa muestra `True` o `False` frente a límites fijos, porque los tiempos exactos cambian de una ejecución a otra.
- Un método que usa `await` se marca `async` y devuelve `Task`, o `Task<T>` para un resultado de tipo `T`, igual que `ProjectFile.ReadAsync` devuelve `Task<List<Project>>`. Las instrucciones de nivel superior que contienen `await` se vuelven asíncronas sin ninguna palabra clave.

La aplicación de consola espera `ReadAsync` en su comando `projects`, y xUnit ejecuta una prueba asíncrona, un método de prueba que devuelve `Task`:

```csharp
    // Una prueba asíncrona: xUnit espera el Task antes de leer el resultado
    [Fact]
    public async Task ReadAsync_GivesTheSameProjectsAsRead()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "data", "ga-projects.csv");

        List<Project> projects = await ProjectFile.ReadAsync(path);

        Assert.Equal(ProjectFile.Read(path), projects);
        Assert.Equal(12, projects.Count);
        Assert.Equal(632, projects.Sum(p => p.SourceFiles));
    }
```

**Un `await` olvidado.** Llamar a un método asíncrono lo inicia, pero sin `await` nada espera a que termine:

```csharp
Console.WriteLine("Before");
WriteLater();   // sin await: el programa sigue sin esperar
Console.WriteLine("After");

async Task WriteLater()
{
    await Task.Delay(100);
    Console.WriteLine("Later");
}
```

```text
l12_forgotten_await.cs(2,1): warning CS4014: Because this call is not awaited, execution of the current method continues before the call is completed. Consider applying the 'await' operator to the result of the call.
Before
After
```

El compilador avisa con [CS4014](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/async-await-errors). `WriteLater` se ejecuta hasta su primer `await`, y después devuelve una tarea que nadie espera. El programa muestra `After` y termina, y `Later` nunca se escribe. El ejercicio 3 lo corrige.

**Un constructor no puede esperar.** Un constructor no puede ser `async`, así que no puede contener `await`:

```csharp
var index = new VoicingIndex();

class VoicingIndex
{
    public VoicingIndex()
    {
        await Task.Delay(100);   // un constructor no puede ser async
    }
}
```

```text
l12_constructor_await.cs(7,9): error CS4033: The 'await' operator can only be used within an async method. Consider marking this method with the 'async' modifier and changing its return type to 'Task'.
```

Escribir `public async VoicingIndex()` no ayuda: el compilador lee entonces `async` como un tipo de retorno y `VoicingIndex()` como un método, e informa de CS0246 y CS0542. El remedio habitual es un método estático asíncrono que hace la espera y después llama a un constructor que no espera, como `static async Task<VoicingIndex> CreateAsync()`.

## En Guitar Alchemist

Las mediciones se hicieron en el commit `5c3a52a`, con un [script](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner/ga-probes) que lee el commit con `git`, y con compilaciones de los proyectos de GA.

**Proyectos fuera de la solución.** La solución de GA, [`AllProjects.slnx`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/AllProjects.slnx), lista 75 de los 111 archivos de proyecto del repositorio. Su CI [compila](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/ci.yml#L43) y [prueba](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/ci.yml#L103) esa solución. Un proyecto que queda fuera solo se compila si lo referencia un proyecto listado, como les pasa a 7, o si lo nombra un workflow, y sus pruebas solo se ejecutan si lo nombra un workflow. Seis proyectos de pruebas están fuera de la solución y ningún workflow los nombra; sus archivos contienen 102 líneas con un atributo de prueba. Uno de ellos, [`GA.Business.Core.Graphiti.Tests`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Graphiti.Tests/GA.Business.Core.Graphiti.Tests.csproj), no compila: sus pruebas usan el espacio de nombres `GA.Business.Graphiti`, y su archivo de proyecto no referencia ningún proyecto. La compilación se detiene con CS0234 en sus dos líneas `using GA.Business.Graphiti...`.

**Versiones de paquetes.** Cada archivo de proyecto de GA da sus propias versiones de paquetes, y 35 paquetes aparecen con dos versiones o más; `MongoDB.Driver` tiene cinco. [`Directory.Build.props`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Directory.Build.props#L32-L58) es un archivo que MSBuild importa en cada proyecto situado bajo su carpeta ([personalizar la compilación por carpeta](https://learn.microsoft.com/visualstudio/msbuild/customize-by-directory)). Bajo el comentario «Centralized package version alignment and vulnerability remediation» (alineación centralizada de las versiones de paquetes y corrección de vulnerabilidades), intenta alinear algunas versiones con líneas como `<PackageReference Update="Microsoft.Extensions.Http" Version="10.0.0"/>`. `Update` cambia un elemento que ya existe ([elementos de MSBuild](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#items)), pero `Directory.Build.props` se importa al principio de cada proyecto, antes de que existan los elementos `PackageReference` del propio proyecto: todavía no hay nada que actualizar. Una sonda restauró `GA.Business.Core.Graphiti.Tests`, cuyo archivo de proyecto pide 9.0.10, y obtuvo 9.0.10. Con la misma línea en `Directory.Build.targets`, que MSBuild importa al final, obtuvo 10.0.0. En el conjunto de los archivos de proyecto de GA, 23 declaraciones de estos paquetes dan una versión distinta de la alineada, 13 de ellas en proyectos de la solución. La [gestión centralizada de paquetes](https://learn.microsoft.com/nuget/consume-packages/central-package-management) de NuGet guarda una sola versión por paquete en un solo archivo, `Directory.Packages.props`.

**Advertencias silenciadas.** El mismo archivo [desactiva](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Directory.Build.props#L16-L17) NU1902, NU1903 y NU1904 para todos los proyectos: la advertencia del ejemplo de Newtonsoft.Json, y sus vecinas moderada y crítica. La CI tiene un [análisis de seguridad](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/ci.yml#L398-L401) que ejecuta `dotnet list AllProjects.slnx package --vulnerable --include-transitive` con `continue-on-error: true`. Incluso sin esa línea no podría fallar, porque el comando termina con 0 cuando lista un paquete vulnerable.

**La herramienta de línea de comandos.** La aplicación de consola de GA, GaCLI, tampoco está en la solución. Su propio workflow, [*Quality Check*](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/quality_check.yml#L26-L29), la compila y ejecuta `benchmark-quality --limit 50`. En su `Program.cs`, 12 de los 28 comandos lanzan `NotImplementedException`, entre ellos [`benchmark-quality`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/GaCLI/Program.cs#L179-L182) y `analyze-chord`, el primer ejemplo de su ayuda. En la ejecución [37167745677](https://github.com/GuitarAlchemist/ga/actions/runs/37167745677) de GA, sobre un commit posterior con el mismo workflow y el mismo `Program.cs`, el paso termina con una `NotImplementedException` no controlada y el código de salida 134, y la ejecución sale en verde: el paso tiene `continue-on-error: true`. El comando `sync-mongodb` [captura sus excepciones](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/GaCLI/Program.cs#L364-L368), muestra `Error during sync: Unable to resolve service for type 'GA.Data.MongoDB.Services.MusicalObjectsService'...` y termina con 0, así que un script no puede saber que falló. La lección 10 señaló que GaCLI lee `appsettings.yaml` desde el directorio actual. Iniciado desde otra carpeta, se ejecuta, y en este commit el archivo no cambia nada: solo `sync-mongodb` lee una de sus dos secciones, en unos ajustes que ningún servicio usa.

**Esperar tareas.** GA no tiene ningún método `async void`. Su código compilado se bloquea a la espera de una tarea con `.Wait()`, `.Result` o `GetAwaiter().GetResult()` en 11 sitios, 3 de ellos en constructores, que no pueden hacer `await`: [`QdrantVectorIndex`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Embeddings/QdrantVectorIndex.cs#L16-L21) llama a `InitializeCollectionAsync().Wait()`. Otros siete `.Result` leen tareas después de `await Task.WhenAll`, cuando ya han terminado, como en [`ProductionOrchestrator`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.Core.Orchestration/Services/ProductionOrchestrator.cs#L269-L273): es el patrón del ejemplo de esta lección.

La [tabla QA](../journal/#qa) y la [tabla de experimentos](../journal/#experimentos) del diario registran estas mediciones.

## Ejercicios

Las soluciones son aplicaciones basadas en archivos en `exercises`; `check.sh` las ejecuta desde la carpeta del curso.

### Ejercicio 1 — un paquete en una aplicación basada en archivos

Muestra los proyectos F# de `data/ga-projects.csv`, con sus números de archivos F# y C#, desde una aplicación basada en archivos que lea el archivo con CsvHelper.

<details>
<summary>Solución</summary>

```csharp
#:package CsvHelper@33.1.0
using System.Globalization;
using CsvHelper;

// Ejercicio 1: los proyectos F# de data/ga-projects.csv, leídos con CsvHelper en una aplicación basada en archivos
using var reader = new StreamReader(Path.Combine("data", "ga-projects.csv"));
using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);
foreach (Project project in csv.GetRecords<Project>().Where(p => p.Language == "F#"))
{
    Console.WriteLine($"{project.Name}: F# {project.FsFiles}, C# {project.CsFiles}");
}

record Project(string Name, string Language, int CsFiles, int FsFiles);
```

```text
GA.Business.Config: F# 11, C# 8
GA.Business.DSL: F# 49, C# 0
GA.Business.ProbabilisticGrammar: F# 6, C# 0
GA.Business.Core.Generated: F# 1, C# 0
```

`GetRecords` lee el archivo a demanda, un record cada vez, a medida que `foreach` los pide: las líneas `using` mantienen el archivo abierto hasta el final del programa.

</details>

### Ejercicio 2 — dos archivos a la vez

Escribe un método asíncrono que devuelva el número de líneas de un archivo. Llámalo sobre `data/ga-projects.csv` y sobre `l12-project/Fretboard/Guitar.cs`, y espera las dos llamadas juntas con `Task.WhenAll`.

<details>
<summary>Solución</summary>

```csharp
// Ejercicio 2: contar las líneas de dos archivos leídos al mismo tiempo
string csv = Path.Combine("data", "ga-projects.csv");
string guitar = Path.Combine("l12-project", "Fretboard", "Guitar.cs");

// Task.WhenAll de Task<int> da un int[], en el orden de las tareas
int[] counts = await Task.WhenAll(CountLinesAsync(csv), CountLinesAsync(guitar));
Console.WriteLine($"{Path.GetFileName(csv)}: {counts[0]} lines");
Console.WriteLine($"{Path.GetFileName(guitar)}: {counts[1]} lines");

async Task<int> CountLinesAsync(string path)
{
    string[] lines = await File.ReadAllLinesAsync(path);
    return lines.Length;
}
```

```text
ga-projects.csv: 13 lines
Guitar.cs: 36 lines
```

Las dos lecturas empiezan antes del primer `await`. Los resultados vuelven en el orden de las tareas, sea cual sea la lectura que termine primero.

</details>

### Ejercicio 3 — el `await` olvidado

Corrige el programa del `await` olvidado para que muestre `Before`, `Later` y `After`, sin ninguna advertencia.

<details>
<summary>Solución</summary>

```csharp
// Ejercicio 3: el await olvidado, corregido
Console.WriteLine("Before");
await WriteLater();   // el programa espera aquí hasta que WriteLater haya terminado
Console.WriteLine("After");

async Task WriteLater()
{
    await Task.Delay(100);
    Console.WriteLine("Later");
}
```

```text
Before
Later
After
```

Con `await`, las propias instrucciones de nivel superior se vuelven asíncronas, y el programa solo termina después de la última línea.

</details>

### Ejercicio 4 — dentro del paquete

Después de `dotnet pack Fretboard`, escribe un programa que liste los archivos de `Fretboard.1.0.0.nupkg` con [`ZipFile`](https://learn.microsoft.com/dotnet/api/system.io.compression.zipfile), y que después muestre las líneas `<dependency>` de su `.nuspec`.

<details>
<summary>Solución</summary>

```csharp
using System.IO.Compression;

// Ejercicio 4: lo que dotnet pack puso en el paquete de la biblioteca, que es un archivo zip
string package = Path.Combine("l12-project", "Fretboard", "bin", "Release", "Fretboard.1.0.0.nupkg");
using ZipArchive zip = ZipFile.OpenRead(package);
foreach (ZipArchiveEntry entry in zip.Entries)
{
    // El nombre de este archivo de metadatos es aleatorio: se muestra un marcador en su lugar
    string name = entry.FullName.EndsWith(".psmdcp") ? "package/services/metadata/core-properties/(random).psmdcp" : entry.FullName;
    Console.WriteLine(name);
}

// Los paquetes que también recibe un proyecto que instala Fretboard
using StreamReader nuspec = new StreamReader(zip.GetEntry("Fretboard.nuspec")!.Open());
foreach (string line in nuspec.ReadToEnd().Split('\n').Where(line => line.Contains("<dependency ")))
{
    Console.WriteLine(line.Trim());
}
```

```text
_rels/.rels
Fretboard.nuspec
lib/net10.0/Fretboard.dll
[Content_Types].xml
package/services/metadata/core-properties/(random).psmdcp
<dependency id="CsvHelper" version="33.1.0" exclude="Build,Analyzers" />
```

En un `.nuspec`, `version="33.1.0"` significa 33.1.0 o posterior ([intervalos de versiones](https://learn.microsoft.com/nuget/concepts/package-versioning#version-ranges)). Los demás archivos son propios del formato de empaquetado: `_rels/.rels`, `[Content_Types].xml` y los metadatos `.psmdcp`.

</details>

## Lo que debes recordar

- Una solución lista proyectos; los archivos de proyecto dicen qué proyecto referencia a cuál. `dotnet build` en la carpeta de la solución los compila todos. `dotnet test` solo compila los proyectos de pruebas y lo que referencian, así que un error de compilación en la aplicación puede esconderse detrás de pruebas que pasan.
- Una aplicación de consola lee sus argumentos en `args` e indica el éxito con el código de salida 0, y el fallo con otro código. Los errores van a `Console.Error`.
- Un paquete de NuGet viene con una versión: `#:package Name@version` en una aplicación basada en archivos, un `PackageReference` escrito por `dotnet add package` en un proyecto. La restauración avisa de las vulnerabilidades conocidas (NU1901 a NU1904).
- `dotnet pack` crea un `.nupkg`, un zip con la biblioteca compilada y un `.nuspec` que lista sus dependencias.
- `await` espera un `Task` sin bloquear el hilo; un método que lo usa es `async` y devuelve `Task` o `Task<T>`. `Task.WhenAll` espera varias tareas iniciadas a la vez.
- Sin `await`, una llamada asíncrona se ejecuta por su cuenta, y nadie ve su final ni sus excepciones; el compilador avisa con CS4014. Un constructor no puede hacer `await`.
- En `Directory.Build.props`, un `PackageReference Update` llega antes que los elementos del proyecto y no cambia nada. Un paso con `continue-on-error: true` no puede hacer fallar una ejecución de CI.

Esta es la última lección del curso. El [plan](../#plan) lista las doce. El curso [C# avanzado](../../csharp-advanced/) continúa con la memoria, el recolector de basura, [`async` por dentro](../../csharp-advanced/03-async-under-the-hood/) y el rendimiento medido.

## Fuentes

- CLI de .NET: [`dotnet sln`](https://learn.microsoft.com/dotnet/core/tools/dotnet-sln), [`dotnet build`](https://learn.microsoft.com/dotnet/core/tools/dotnet-build), [`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run), [`dotnet package add`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-add), [`dotnet package list`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-list), [`dotnet pack`](https://learn.microsoft.com/dotnet/core/tools/dotnet-pack), [`dotnet nuget push`](https://learn.microsoft.com/dotnet/core/tools/dotnet-nuget-push), [aplicaciones basadas en archivos](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps), [propiedades de paquete](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#package-properties)
- NuGet: [qué es NuGet](https://learn.microsoft.com/nuget/what-is-nuget), [carpeta global de paquetes](https://learn.microsoft.com/nuget/consume-packages/managing-the-global-packages-and-cache-folders), [auditoría de paquetes](https://learn.microsoft.com/nuget/concepts/auditing-packages), [NU1015](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1015), [NU1901–NU1904](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1901-nu1904), [intervalos de versiones](https://learn.microsoft.com/nuget/concepts/package-versioning#version-ranges), [gestión centralizada de paquetes](https://learn.microsoft.com/nuget/consume-packages/central-package-management); [CsvHelper](https://joshclose.github.io/CsvHelper/) en [nuget.org](https://www.nuget.org/packages/CsvHelper/)
- C#: [programación asíncrona](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/), [filtros de excepciones](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements#the-try-catch-statement), [protecciones de caso](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#case-guards), [`Main` y argumentos de la línea de comandos](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/main-command-line), [literales de cadena sin formato](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/raw-string), [errores y advertencias de los métodos asíncronos (CS4014, CS4033)](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/async-await-errors)
- API: [`Task`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task), [`Task.Delay`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.delay), [`Task.WhenAll`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall), [`File.ReadAllLinesAsync`](https://learn.microsoft.com/dotnet/api/system.io.file.readalllinesasync), [`Stopwatch`](https://learn.microsoft.com/dotnet/api/system.diagnostics.stopwatch), [`Console.Error`](https://learn.microsoft.com/dotnet/api/system.console.error), [`TextReader`](https://learn.microsoft.com/dotnet/api/system.io.textreader), [`ZipFile`](https://learn.microsoft.com/dotnet/api/system.io.compression.zipfile)
- MSBuild: [personalizar la compilación por carpeta](https://learn.microsoft.com/visualstudio/msbuild/customize-by-directory), [elementos de los proyectos del SDK de .NET](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#items)
