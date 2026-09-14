---
title: 5. DuckDB desde C#
description: DuckDB.NET como proveedor ADO.NET — conexión, data reader, parámetros, los tipos .NET de los valores de DuckDB, listas y structs, errores, Dapper y carga masiva con el appender.
sidebar:
  order: 5
---

La CLI ejecuta DuckDB en su propio proceso. Desde C#, DuckDB se ejecuta **en tu proceso**, como una biblioteca nativa a la que se llama a través de [DuckDB.NET](https://duckdb.net/), un proveedor [ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/): `DbConnection`, `DbCommand`, `DbDataReader`, las clases que ya usas con SQL Server o SQLite. El programa de esta lección es [`csharp/CiQueries/Program.cs`](https://github.com/spareilleux/learn/blob/main/code/duckdb/csharp/CiQueries/Program.cs), ejecutado desde `code/duckdb` y comparado con [`csharp/expected.txt`](https://github.com/spareilleux/learn/blob/main/code/duckdb/csharp/expected.txt) en los tres sistemas operativos.

## El proyecto

De [`csharp/CiQueries/CiQueries.csproj`, líneas 10-13](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/CiQueries.csproj#L10-L13):

```xml
<ItemGroup>
  <PackageReference Include="Dapper" Version="2.1.86" />
  <PackageReference Include="DuckDB.NET.Data.Full" Version="1.5.5" />
</ItemGroup>
```

DuckDB.NET se distribuye en [cuatro paquetes](https://duckdb.net/docs/getting-started.html): el proveedor ADO.NET (`DuckDB.NET.Data`) o los bindings de bajo nivel, cada uno con o sin la biblioteca nativa de DuckDB. `.Full` la incluye, para todas las plataformas, y eso tiene un costo:

| | Tamaño |
|---|---|
| `duckdb.net.bindings.full` 1.5.5 en la caché de NuGet | 420 MB |
| `bin/Debug/net10.0` después de `dotnet build` | 316 MB |
| `dotnet publish -r linux-x64` | 69 MB |

Un build normal copia la biblioteca nativa de los cinco runtimes: `win-x64` (37 MB), `win-arm64` (43 MB), `linux-x64` (71 MB), `linux-arm64` (63 MB) y `osx` (117 MB, un solo archivo para Intel y Apple Silicon). Publicar para un identificador de runtime conserva solo la suya. La versión del paquete sigue a la de DuckDB: 1.5.5 incluye DuckDB 1.5.5.

## Una consulta con un data reader

De [`csharp/CiQueries/Program.cs`, líneas 11-13](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L11-L13):

```csharp
// Una base de datos en memoria, como la CLI iniciada sin nombre de archivo
using var connection = new DuckDBConnection("Data Source=:memory:");
connection.Open();
Console.WriteLine($"DuckDB {connection.ServerVersion}");
```

De [`csharp/CiQueries/Program.cs`, líneas 22-36](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L22-L36):

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = """
        SELECT workflowName, count(*) AS runs, count(*) FILTER (conclusion = 'failure') AS failures
        FROM 'data/runs.json'
        GROUP BY ALL
        ORDER BY runs DESC, workflowName
        LIMIT 3
        """;
    using var reader = command.ExecuteReader();
    while (reader.Read())
    {
        Console.WriteLine($"{reader.GetString(0),-24} {reader.GetInt64(1),3} runs {reader.GetInt64(2),2} failures");
    }
}
```

```text
DuckDB v1.5.5

== 1. A query with a data reader
Deploy to GitHub Pages    65 runs  2 failures
Rust course examples      18 runs  3 failures
Java course examples       7 runs  0 failures
```

Nada nuevo para un usuario de ADO.NET, y el SQL es el de la lección 1, nombre de archivo incluido. `Data Source=file.duckdb` abre o crea en su lugar un archivo de base de datos; de eso trata la lección 8.

`'data/runs.json'` es relativo al **directorio de trabajo del proceso**, no al proyecto ni al ejecutable. Ejecutada desde la carpeta del proyecto con una ruta `../data`, la primera versión fallaba:

```text
Unhandled exception. DuckDB.NET.Data.DuckDBException (0x80004005): IO Error: No files found that match the pattern "../data/runs.json"
```

`../data` desde `csharp/CiQueries` es `csharp/data`, que no existe. Una aplicación que lee archivos debería construir rutas absolutas, a partir de su configuración o de `AppContext.BaseDirectory`.

## Parámetros

DuckDB [acepta tres sintaxis](https://duckdb.net/docs/basic-usage.html): `?`, `$1` y `$name`. Con `DuckDBParameter`, el nombre va sin el `$` ([líneas 39-46](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L39-L46)):

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = "SELECT count(*) FROM read_json($path) WHERE workflowName = $workflow AND conclusion = $conclusion";
    command.Parameters.Add(new DuckDBParameter("path", "data/runs.json"));
    command.Parameters.Add(new DuckDBParameter("workflow", "Rust course examples"));
    command.Parameters.Add(new DuckDBParameter("conclusion", "failure"));
    Console.WriteLine($"Rust course failures: {command.ExecuteScalar()}");
}
```

```text
== 2. Parameters
Rust course failures: 3
```

Incluso el nombre de archivo es un parámetro: `read_json($path)`, mientras que `OPENROWSET(BULK …)` de SQL Server solo acepta un literal y te empuja a construir la cadena SQL. Una ruta que viene de un usuario sigue necesitando una comprobación antes de llegar a `read_json`, ya que DuckDB puede leer cualquier archivo al que tenga acceso el proceso.

## Los tipos de DuckDB como tipos .NET

De [`csharp/CiQueries/Program.cs`, líneas 49-69](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L49-L69):

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = """
        SELECT workflowName, databaseId, createdAt, createdAt::DATE AS day, updatedAt - startedAt AS took,
               createdAt AT TIME ZONE 'UTC' AS created_utc, sum(databaseId) OVER () AS total,
               [event, conclusion] AS pair, {'event': event, 'attempt': attempt} AS info
        FROM 'data/runs.json'
        ORDER BY createdAt
        LIMIT 1
        """;
    using var reader = command.ExecuteReader();
    reader.Read();
    for (var i = 0; i < reader.FieldCount; i++)
    {
        Console.WriteLine($"{reader.GetName(i),-12} {reader.GetDataTypeName(i),-12} {reader.GetFieldType(i)}");
    }
    var createdUtc = reader.GetDateTime(5);
    Console.WriteLine($"created_utc as DateTime: {createdUtc.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture)}, Kind = {createdUtc.Kind}");
    Console.WriteLine($"created_utc as DateTimeOffset: {reader.GetFieldValue<DateTimeOffset>(5).ToString("yyyy-MM-dd HH:mm:ss zzz", CultureInfo.InvariantCulture)}");
    Console.WriteLine($"took: {reader.GetFieldValue<TimeSpan>(4)}");
}
```

```text
== 3. DuckDB types as .NET types
workflowName Varchar      System.String
databaseId   BigInt       System.Int64
createdAt    Timestamp    System.DateTime
day          Date         System.DateOnly
took         Interval     System.TimeSpan
created_utc  TimestampTz  System.DateTime
total        HugeInt      System.Numerics.BigInteger
pair         List         System.Collections.Generic.List`1[System.String]
info         Struct       System.Collections.Generic.Dictionary`2[System.String,System.Object]
created_utc as DateTime: 2026-09-13 15:53:16, Kind = Unspecified
created_utc as DateTimeOffset: 2026-09-13 15:53:16 +00:00
took: 00:00:39
```

- `DATE` se convierte en `DateOnly`, e `INTERVAL` en `TimeSpan`.
- `sum` de un `BIGINT` es un `HUGEINT`, un entero de 128 bits, así que `System.Numerics.BigInteger`, no `long`. El ejercicio 2 muestra lo que eso cuesta; `CAST(sum(…) AS BIGINT)` en el SQL evita la cuestión.
- Un `TIMESTAMP WITH TIME ZONE` llega como un `DateTime` que contiene la hora UTC, pero con [`Kind`](https://learn.microsoft.com/dotnet/api/system.datetime.kind) `Unspecified`, no `Utc`. `ToUniversalTime()` trata un valor `Unspecified` como hora local y lo desplaza: en un programa de prueba en esta máquina (UTC−4), `15:53:16` se convirtió en `19:53:16`, cuatro horas de diferencia. `GetFieldValue<DateTimeOffset>` devuelve un `+00:00` explícito. La configuración `TimeZone` de la sesión, vista en la lección 2, no cambia lo que recibe C#: con `SET TimeZone = 'Europe/Paris'`, volvió el mismo `15:53:16`.
- Las fechas se formatean con `CultureInfo.InvariantCulture`: la primera versión imprimía `2026-09-14 2:01:09 PM` en esta máquina, un formato que depende de la configuración regional del usuario y que nunca coincidiría con la salida esperada por la CI.

## Listas y structs

De [`csharp/CiQueries/Program.cs`, líneas 72-88](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L72-L88):

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = "SELECT labels, steps FROM 'data/jobs.json' WHERE id = 104004920113";
    using var reader = command.ExecuteReader();
    reader.Read();
    var labels = reader.GetFieldValue<List<string>>(0);
    Console.WriteLine($"labels: {string.Join(", ", labels)}");

    var asDictionaries = reader.GetFieldValue<List<Dictionary<string, object?>>>(1);
    Console.WriteLine($"first step as a dictionary: {string.Join(", ", asDictionaries[0].Select(kv => $"{kv.Key}={Format(kv.Value)}"))}");

    var steps = reader.GetFieldValue<List<Step>>(1);
    foreach (var step in steps.Take(3))
    {
        Console.WriteLine($"step {step.Number}: {step.Name}, {step.Conclusion}, {(step.Completed_At - step.Started_At).TotalSeconds} s, StartedAt = {Format(step.StartedAt)}");
    }
}
```

De [`csharp/CiQueries/Program.cs`, líneas 174-182](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L174-L182):

```csharp
// DuckDB.NET asigna los campos de un struct a las propiedades con setter del mismo nombre, sin distinguir mayúsculas de minúsculas
class Step
{
    public long Number { get; set; }
    public string Name { get; set; } = "";
    public string Conclusion { get; set; } = "";
    public DateTime Started_At { get; set; }
    public DateTime Completed_At { get; set; }
    public DateTime StartedAt { get; set; }
}
```

```text
== 4. Lists and structs
labels: ubuntu-latest
first step as a dictionary: number=1, name=Set up job, conclusion=success, started_at=2026-09-14 14:01:15, completed_at=2026-09-14 14:01:19
step 1: Set up job, success, 4 s, StartedAt = 0001-01-01 00:00:00
step 2: Checkout, success, 2 s, StartedAt = 0001-01-01 00:00:00
step 3: Install, build, and upload site, success, 48 s, StartedAt = 0001-01-01 00:00:00
```

- Una `LIST` de `VARCHAR` se lee como `List<string>`; un `STRUCT` como un `Dictionary<string, object>`, o como una clase tuya.
- La correspondencia se hace por nombre de propiedad, sin distinguir mayúsculas de minúsculas: `Started_At` coincide con `started_at`. **`StartedAt` no, y nada lo indica**: la propiedad conserva su valor por defecto, `0001-01-01`. En C#, el nombre natural es el que falla en silencio. Renombra en el SQL (ejercicio 1), o comprueba los valores por defecto en un test.
- Un record posicional `record Step(long Number, …)` falla en tiempo de ejecución: `MissingMethodException: Cannot dynamically create an instance of type 'Step'. Reason: No parameterless constructor defined.` El tipo de destino necesita un constructor sin parámetros y setters, o accesores `init`.

## Errores

De [`csharp/CiQueries/Program.cs`, líneas 91-103](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L91-L103):

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = "SELECT workflow_name FROM 'data/runs.json'";
    try
    {
        command.ExecuteScalar();
    }
    catch (DuckDBException e)
    {
        Console.WriteLine($"{e.GetType().Name}, ErrorType = {e.ErrorType}");
        Console.WriteLine(e.Message.Split('\n')[0]);
    }
}
```

```text
== 5. Errors
DuckDBException, ErrorType = Invalid
Binder Error: Referenced column "workflow_name" not found in FROM clause!
```

Un solo tipo de excepción, `DuckDBException`, con el mismo mensaje que la CLI, sugerencias y posición incluidas. Su `ErrorType` dice `Invalid`, no `Binder`: para distinguir los tipos de error, el prefijo del mensaje es más preciso que la propiedad. El comando sigue siendo utilizable después del error: en un programa de prueba, el mismo `DuckDBCommand` ejecutó luego `SELECT 42` y devolvió `42`. La lección 6 muestra que el driver de Java se comporta de otra manera.

## Dapper

[Dapper](https://github.com/DapperLib/Dapper) extiende cualquier `DbConnection`, así que funciona con `DuckDBConnection` sin adaptador ([líneas 106-118](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L106-L118)):

```csharp
var failures = connection.Query<RunSummary>(
    """
    SELECT databaseId, workflowName, createdAt, updatedAt - startedAt AS took
    FROM 'data/runs.json'
    WHERE conclusion = $conclusion AND event = $event
    ORDER BY createdAt
    LIMIT 3
    """,
    new { conclusion = "failure", @event = "push" });
foreach (var run in failures)
{
    Console.WriteLine($"{run.DatabaseId} {run.WorkflowName,-24} {Format(run.CreatedAt)} {run.Took}");
}
```

De [`csharp/CiQueries/Program.cs`, línea 171](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L171):

```csharp
// Dapper asigna las columnas a los parámetros del constructor, sin distinguir mayúsculas de minúsculas
record RunSummary(long DatabaseId, string WorkflowName, DateTime CreatedAt, TimeSpan Took);
```

```text
== 6. Dapper
34772306529 Rust course examples     2026-09-13 17:40:34 00:00:40
34772373891 Rust course examples     2026-09-13 17:41:56 00:00:31
34776807003 Rust course examples     2026-09-13 19:09:08 00:01:55
```

Las propiedades del objeto anónimo se convierten en los parámetros `$conclusion` y `$event`; `@event` es la forma en que C# escribe una propiedad con el nombre de una palabra clave. A diferencia de la correspondencia de structs de DuckDB.NET, Dapper rellena un record posicional a través de su constructor. Los tres pushes fallidos son los fallos del curso de Rust de la lección 2.

## Carga masiva: el appender

Cargar filas con un `INSERT` por fila es lento en cualquier base de datos. DuckDB.NET expone el [appender](https://duckdb.org/docs/current/data/appender) de DuckDB, que escribe las filas directamente en el almacenamiento de una tabla ([líneas 138-146](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/csharp/CiQueries/Program.cs#L138-L146)):

```csharp
    const int appended = 1_000_000;
    var stopwatch = Stopwatch.StartNew();
    using (var appender = connection.CreateAppender("numbers"))
    {
        for (var i = 0; i < appended; i++)
        {
            appender.CreateRow().AppendValue(i).AppendValue($"n{i}").EndRow();
        }
    }
```

El modo `timings` del programa carga un millón de filas con el appender y luego 10.000 filas con un `INSERT` parametrizado dentro de una transacción. La CI imprime los tiempos sin compararlos:

| Runner | Appender, 1.000.000 filas | `INSERT`, 10.000 filas |
|---|---|---|
| `ubuntu-latest` | 256 ms | 3.165 ms |
| `windows-latest` | 331 ms | 3.917 ms |
| `macos-latest` | 226 ms | 1.312 ms |
| Esta máquina (Windows, Release) | 170 ms | 1.577 ms |

Con 100 veces más filas, el appender sigue siendo de 6 a 12 veces más rápido: por fila, de 600 a 1.200 veces más rápido. Las filas se escriben cuando se libera el appender, de ahí el `using`: en un programa de prueba, `count(*)` sobre la tabla daba `0` después de añadir 10 filas, y `10` después de `Dispose()`. Para datos que ya están en un archivo, `INSERT INTO … SELECT * FROM 'file.parquet'` es aún más simple y no cruza la frontera entre código administrado y nativo para cada valor.

## Puntos clave

- DuckDB.NET es un proveedor ADO.NET: `DuckDBConnection`, los comandos, los readers, las transacciones y Dapper funcionan como con cualquier otra base de datos.
- El paquete `.Full` incluye la biblioteca nativa de todas las plataformas; publica para un identificador de runtime para distribuir solo una.
- Las rutas de archivo relativas en el SQL son relativas al directorio de trabajo del proceso.
- `DATE` → `DateOnly`, `INTERVAL` → `TimeSpan`, `HUGEINT` → `BigInteger`, `TIMESTAMPTZ` → `DateTime` con `Kind` `Unspecified`.
- Los structs se asignan a clases por nombre de propiedad, y una propiedad sin correspondencia conserva en silencio su valor por defecto.
- Para muchas filas, usa el appender, o deja que DuckDB lea el archivo.

## Ejercicios

1. Cambia la clase `Step` para que `StartedAt` reciba la hora de inicio del step sin renombrarla, cambiando solo el SQL.

<details>
<summary>Solución</summary>

Reconstruye cada struct con los nombres que espera la clase, con `list_transform` de la lección 3:

```sql
SELECT list_transform(steps, lambda s: {'number': s.number, 'name': s.name, 'startedAt': s.started_at}) AS steps
FROM 'data/jobs.json'
WHERE id = 104004920113
```

Con una clase `Step` que solo tiene `Number`, `Name` y `StartedAt`, el primer step se lee así:

```text
1 Set up job 2026-09-14 14:01:15
```

El SQL pasa a ser el único lugar donde el formato externo (el `snake_case` de la API de GitHub) se encuentra con la nomenclatura de C#. Esta comprobación se hizo una vez en un programa de prueba, no en el programa de la CI.

</details>

2. `ExecuteScalar` sobre `SELECT sum(databaseId) FROM 'data/runs.json'` devuelve un `object`. ¿Cuál es su tipo, y qué hace `(long)command.ExecuteScalar()!`?

<details>
<summary>Solución</summary>

`sum` de un `BIGINT` es un `HUGEINT`, leído como `System.Numerics.BigInteger` (sección 3 del programa). El cast lanza una excepción:

```text
InvalidCastException: Unable to cast object of type 'System.Numerics.BigInteger' to type 'System.Int64'.
```

El unboxing solo funciona hacia el tipo exacto del valor encapsulado. La salida habitual, `Convert.ToInt64(value)`, también falla, porque `BigInteger` no implementa `IConvertible`:

```text
InvalidCastException: Unable to cast object of type 'System.Numerics.BigInteger' to type 'System.IConvertible'.
```

Lo que funciona: hacer unboxing al tipo real y luego convertir, `(long)(BigInteger)value`, que dio `4351672497299`; o `CAST(sum(databaseId) AS BIGINT)` en el SQL, para que el reader devuelva un `long`. Comprobado en un programa de prueba, no en el programa de la CI.

</details>

3. ¿Por qué la sección 5 imprime `e.Message.Split('\n')[0]` en lugar del mensaje completo?

<details>
<summary>Solución</summary>

El mensaje completo tiene varias líneas, como en la CLI: el error, `Candidate bindings: "workflowName", "conclusion"`, una línea en blanco y luego la consulta con un `^` debajo de la posición. La primera línea basta para un log y mantiene corta la salida esperada. Conserva el mensaje completo donde lo lee un desarrollador: el marcador de posición es la parte más útil de un error de sintaxis en una consulta larga.

</details>

## Fuentes

- [Documentación de DuckDB.NET](https://duckdb.net/): [primeros pasos](https://duckdb.net/docs/getting-started.html) y [uso básico](https://duckdb.net/docs/basic-usage.html)
- [Código fuente de DuckDB.NET](https://github.com/Giorgi/DuckDB.NET)
- [`DuckDB.NET.Data.Full` en NuGet](https://www.nuget.org/packages/DuckDB.NET.Data.Full)
- [Descripción general de los clientes de DuckDB](https://duckdb.org/docs/current/clients/overview) y [appender](https://duckdb.org/docs/current/data/appender)
- [Dapper](https://github.com/DapperLib/Dapper)
- [Descripción general de ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/)
