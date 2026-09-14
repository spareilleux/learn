---
title: 5. LadybugDB desde C#
description: El paquete NuGet de LadybugDB sobre el grafo de proyectos de GuitarAlchemist/ga — paquetes nativos, filas, parámetros y sentencias preparadas, nodos y caminos, listas y structs, fechas, errores, compartir un archivo con la CLI, e hilos — con un bug más en los agregados y un bug de fechas.
sidebar:
  order: 5
---

Desde C#, LadybugDB se ejecuta **en tu proceso**, como una biblioteca nativa a la que se llama a través del paquete NuGet [`LadybugDB`](https://www.nuget.org/packages/LadybugDB). El paquete no es un proveedor [ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/): no hay `DbConnection` ni `DbDataReader`, y por tanto tampoco [Dapper](https://www.nuget.org/packages/Dapper). Sus clases se les parecen, de todos modos:

| ADO.NET | `LadybugDB` 0.19.1 |
|---|---|
| una cadena de conexión | `new Database(path, config)`: la propia base de datos, en tu proceso |
| `DbConnection` | `new Connection(database)`: varias conexiones pueden compartir un mismo `Database` |
| `DbCommand.ExecuteReader()` | `connection.Query(cypher)` devuelve un `QueryResult` |
| `DbDataReader.Read()` y `GetInt64(i)` | `result.Rows()`: un `IEnumerable<object?[]>` |
| `DbParameter` | `connection.Execute(cypher, dictionary)` o `Prepare(cypher)` y luego `Bind(name, value)` |
| `DbException` | `LadybugException` y `LadybugQueryException` |

El programa de esta lección es [`csharp/ProjectGraph/Program.cs`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/csharp/ProjectGraph/Program.cs), ejecutado desde `code/ladybugdb` y comparado con [`csharp/expected.txt`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/csharp/expected.txt) en los tres sistemas operativos. El paquete no tiene página en la documentación de LadybugDB: su referencia es el [README de `ladybug-dotnet`](https://github.com/LadybugDB/ladybug-dotnet) y su código fuente.

## Un grafo nuevo: los proyectos de GuitarAlchemist/ga

Las lecciones 1 a 4 consultaban este sitio. Las lecciones 5 y 6 consultan una solución .NET: [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), una aplicación de teoría musical con 111 proyectos de C# y F#. [`data/ga/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/ga/extract.py) lee sus archivos de proyecto en el commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893) y escribe tres archivos CSV en [`data/ga`](https://github.com/spareilleux/learn/tree/main/code/ladybugdb/data/ga):

| Tabla | Tipo | Origen |
|---|---|---|
| `Project(path, name, language, sdk, frameworks, in_solution)` | nodo | `projects.csv`: cada `.csproj` y `.fsproj`, y si `AllProjects.slnx` lo incluye |
| `Package(name)` | nodo | los paquetes distintos de `package_refs.csv` |
| `REFERENCES` | relación, de `Project` a `Project` | `project_refs.csv`: los elementos `<ProjectReference>` |
| `USES(version)` | relación, de `Project` a `Package` | `package_refs.csv`: los elementos `<PackageReference>`, con su versión |

Un grafo de dependencias es lo que recorre `dotnet build`, y lo que dibujan los diagramas de dependencias de Visual Studio; aquí es un grafo que puedes consultar.

`version` es la versión escrita en cada archivo de proyecto. El [`Directory.Build.props`](https://github.com/GuitarAlchemist/ga/blob/a26a7893/Directory.Build.props) de ga cambia algunas de ellas para todos los proyectos, con elementos `<PackageReference Update="…" Version="…"/>`: `Microsoft.Extensions.Options`, `System.Numerics.Tensors` y otros doce. La extracción no los aplica; las consultas de esta lección usan paquetes que ese archivo no toca.

## El proyecto

```xml
<ItemGroup>
  <PackageReference Include="LadybugDB" Version="0.19.1" />
  <PackageReference Include="LadybugDB.Native" Version="0.19.1" />
</ItemGroup>
```

`LadybugDB` es el código administrado, que llama a la API de C del motor con P/Invoke. El motor en sí está en un [paquete nativo por identificador de runtime](https://learn.microsoft.com/dotnet/core/rid-catalog): `LadybugDB.Native.win-x64`, `linux-x64`, `linux-arm64`, `osx-x64` y `osx-arm64`. `LadybugDB.Native` referencia los cinco:

| | Tamaño |
|---|---|
| los cinco paquetes nativos en la caché de NuGet | de 25 MB (`win-x64`) a 38 MB (`linux-x64`) cada uno |
| `bin/Release/net10.0` después de `dotnet build` | 131 MB, de los cuales de 19 a 28 MB por runtime |
| `dotnet publish -r win-x64` | 20 MB |

Una aplicación para una sola plataforma puede referenciar solo `LadybugDB.Native.win-x64` en lugar del metapaquete.

**La versión va por detrás de la CLI.** 0.19.1 es la última versión en NuGet, y el README dice que los tres primeros números de la versión del paquete son los del motor: este programa ejecuta el motor 0.19.1, y la CLI de las lecciones 1 a 4 es la 0.20.4. El programa imprime las dos versiones que conoce ([líneas 10-14](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L10-L14)):

```csharp
Console.WriteLine($"LadybugDB {LadybugVersion.Version}, storage version {LadybugVersion.StorageVersion}");
// Una ruta vacía: una base de datos en memoria, como la CLI iniciada sin nombre de archivo
using var database = new Database("");
using var connection = new Connection(database);
```

```text
LadybugDB 0.19.1, storage version 43
```

La versión de almacenamiento es el formato de los archivos de base de datos. Importa cuando el programa y la CLI abren el mismo archivo, [más abajo](#compartir-un-archivo-con-la-cli).

## La carga: una referencia a un proyecto que no está

El esquema y las sentencias `COPY` son los de la lección 2, enviados uno a uno con `connection.Query` ([líneas 16-32](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L16-L32)):

```csharp
Execute("COPY Project FROM 'data/ga/projects.csv' (HEADER = true)");
try
{
    Execute("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true)");
}
catch (LadybugQueryException e)
{
    Console.WriteLine($"{e.GetType().Name}: {e.Message}");
    Execute("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true, IGNORE_ERRORS = true)");
}
```

```text
111 tuples have been copied to the Project table.
LadybugQueryException: Copy exception: Unable to find primary key value Experiments/React/reactapp1.client/reactapp1.client.esproj.
265 tuples have been copied to the REFERENCES table.
1 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 6
```

`Execute` es una función auxiliar del programa que imprime la primera columna de cada fila. `ReactApp1.Server.csproj` referencia `reactapp1.client.esproj`, un proyecto JavaScript que la extracción no conservó: el error de la [lección 2](../02-loading/), ahora como excepción de .NET. La CLI imprimía el error y seguía; en C#, el `COPY` fallido lanza una excepción y no se carga nada hasta el reintento con `IGNORE_ERRORS`.

## Filas

[Líneas 34-48](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L34-L48):

```csharp
using (var result = connection.Query("""
    MATCH (p:Project)-[:REFERENCES]->(core:Project)
    RETURN core.name, count(*) AS referenced_by
    ORDER BY referenced_by DESC, core.name
    LIMIT 3
    """))
{
    Console.WriteLine($"{string.Join(", ", result.ColumnNames)}: {result.RowCount} rows");
    foreach (var row in result.Rows())
    {
        Console.WriteLine($"{row[0],-20} {row[1],2} ({row[1]?.GetType()})");
    }
    Console.WriteLine($"a second foreach: {result.Rows().Count()} rows");
}
```

```text
core.name, referenced_by: 3 rows
GA.Domain.Core       57 (System.Int64)
GA.Domain.Services   48 (System.Int64)
GA.Core              32 (System.Int64)
a second foreach: 0 rows
```

- `RowCount` se conoce antes de la primera fila: el motor ha calculado todo el resultado.
- Cada fila es un `object?[]`, y un `INT64` llega como `long` con boxing.
- **`Rows()` solo se puede enumerar una vez**, como un `DbDataReader`, pero no lo avisa: el segundo `foreach` no encuentra ninguna fila, y no hay excepción. `Rows()` es un iterador sobre un cursor del resultado nativo ([`QueryResult.cs`, líneas 117-133](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/QueryResult.cs#L117-L133)). Llama a `.ToList()` cuando necesites las filas dos veces.
- `QueryResult` es `IDisposable`: retiene memoria nativa hasta `Dispose`.

57 de los 111 proyectos referencian `GA.Domain.Core`.

## Parámetros

Dos formas, con un diccionario o con una sentencia preparada ([líneas 51-67](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L51-L67)):

```csharp
using (var result = connection.Execute(
    "MATCH (p:Project {name: $name})-[:REFERENCES*1..10]->(d:Project) RETURN count(DISTINCT d) AS dependencies",
    new Dictionary<string, object?> { ["name"] = "GaApi" }))
{
    Console.WriteLine($"GaApi depends on {result.Rows().Single()[0]} projects");
}
using (var statement = connection.Prepare("""
    MATCH (p:Project {name: $name})-[:REFERENCES*1..10]->(d:Project)
    RETURN count(DISTINCT d) AS dependencies
    """))
{
    foreach (var name in new[] { "GaCli", "GaMcpServer", "GA.Domain.Core" })
    {
        using var result = statement.Bind("name", name).Execute();
        Console.WriteLine($"{name} depends on {result.Rows().Single()[0]} projects");
    }
}
```

```text
GaApi depends on 20 projects
GaCli depends on 7 projects
GaMcpServer depends on 13 projects
GA.Domain.Core depends on 2 projects
```

`$name` en Cypher, `"name"` sin el `$` en C#. `Execute` con un diccionario prepara la sentencia en cada llamada; `Prepare` una vez, y luego `Bind` y `Execute` para cada valor, ahorra ese trabajo, como `DbCommand.Prepare()`. `Bind` devuelve la sentencia, así que las llamadas se encadenan. La API web, `GaApi`, depende de 20 proyectos, directa o indirectamente: el patrón de longitud variable de la lección 3 los encuentra todos.

Lo que acepta el binding, y lo que informa ([líneas 68-83](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L68-L83)):

```text
int 2: 42 projects reference more than 2 projects
string "2": 42 projects reference more than 2 projects
decimal 2m: NotSupportedException: Cannot bind a parameter of type System.Decimal.
LadybugQueryException: Parameter name not found.
LadybugQueryException: Binder exception: Cannot find parameter file. This should not happen.
```

- La consulta compara `COUNT { … } > $n`. Un `int` funciona, y también la cadena `"2"`: el motor la convierte en número. SQL Server hace lo mismo con un parámetro `nvarchar` comparado con una columna `int`.
- Un `decimal` falla en el binding, antes de que el motor lo vea ([`PreparedStatement.cs`, línea 198](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/PreparedStatement.cs#L198)): pasa un `double`, o una cadena convertida en Cypher.
- Un diccionario con `nom` en lugar de `name` falla con `Parameter name not found.`, sin el nombre.
- Un parámetro no puede ser un nombre de archivo: `COPY Package FROM $file` falla al enlazar, con un mensaje que dice que eso no debería ocurrir. Escribe el nombre de archivo en la sentencia, a partir de un valor de confianza.

## Nodos, relaciones y caminos

Una consulta puede devolver un nodo entero o un camino entero ([líneas 85-104](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L85-L104)):

```csharp
using (var result = connection.Query("""
    MATCH path = (app:Project {name: 'GaApi'})-[:REFERENCES* ALL SHORTEST 1..10]->(assets:Project {name: 'GA.Business.Assets'})
    RETURN app, path
    """))
{
    var rows = result.Rows().ToList();
    var app = (Node)rows[0][0]!;
    // El ID interno (tabla:offset) depende de la carga, que difiere entre ejecuciones y máquinas: imprime solo su tipo
    Console.WriteLine($"{app.Label} ({app.Id.GetType().Name}): {string.Join(", ", app.Properties.Select(p => $"{p.Key}={p.Value}"))}");
    // Varios caminos más cortos, sin un orden particular: ordénalos antes de imprimirlos
    foreach (var path in rows.Select(row => (RecursiveRel)row[1]!)
                             .Select(path => $"{path.Rels.Count} relationships: {string.Join(" -> ", path.Nodes.Select(n => n.Properties["name"]))}")
                             .Order())
    {
        Console.WriteLine(path);
    }
    var first = ((RecursiveRel)rows[0][1]!).Rels[0];
    Console.WriteLine($"first relationship: {first.Label}, starts at GaApi: {first.Source == app.Id}");
}
```

```text
Project (InternalId): path=Apps/ga-server/GaApi/GaApi.csproj, name=GaApi, language=C#, sdk=Microsoft.NET.Sdk.Web, frameworks=net10.0, in_solution=True
3 relationships: GaApi -> GA.Business.AI -> GA.Data.MongoDB -> GA.Business.Assets
3 relationships: GaApi -> GA.Business.ML -> GA.Data.MongoDB -> GA.Business.Assets
first relationship: REFERENCES, starts at GaApi: True
```

El binding convierte los valores de grafo en registros ([`GraphTypes.cs`](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/GraphTypes.cs)): `Node(Id, Label, Properties)`, `Rel(Id, Source, Destination, Label, Properties)`, y `RecursiveRel(Nodes, Rels)` para un camino. `Properties` es un diccionario; `Source` y `Destination` son los `InternalId` de los nodos, no los nodos. Los `Nodes` de un camino con nombre incluyen ambos extremos.

La primera versión de esta sección imprimía `app.Id` y usaba `SHORTEST`, y la CI falló en los tres runners:

- el ID de `GaApi` era `0:11` en mi máquina y en el runner de Windows, y `0:47` en Linux y macOS, con el mismo archivo CSV. Un ID interno es la tabla y el offset donde se almacenó el nodo: úsalo dentro de un resultado, para conectar un `Rel` con sus nodos, nunca como una clave que conserves;
- hay dos caminos más cortos, a través de `GA.Business.AI` o de `GA.Business.ML`, y `SHORTEST` devolvió uno en mi máquina y el otro en los runners. `ALL SHORTEST` devuelve ambos, y el programa los ordena.

## Listas y structs

¿Qué paquetes se usan en varias versiones? ([líneas 106-121](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L106-L121))

```csharp
using (var result = connection.Query("""
    MATCH (p:Project)-[u:USES]->(k:Package)
    WITH k, count(*) AS projects, collect(DISTINCT u.version) AS versions
    WHERE size(versions) > 1
    RETURN k.name, versions, {projects: projects, versions: size(versions)} AS usage
    ORDER BY size(versions) DESC, k.name
    LIMIT 3
    """))
{
    foreach (var row in result.Rows())
    {
        var versions = (object?[])row[1]!;
        var usage = (Dictionary<string, object?>)row[2]!;
        Console.WriteLine($"{row[0]}: {string.Join(", ", versions.Order())} ({usage["projects"]} projects)");
    }
}
```

```text
Microsoft.Extensions.Hosting: 10.0.0, 10.0.5, 9.0.0, 9.0.10, 9.0.4 (12 projects)
MongoDB.Driver: 2.29.0, 2.30.0, 3.2.0, 3.2.1, 3.5.0 (14 projects)
Microsoft.Extensions.DependencyInjection: 10.0.0, 10.0.2, 9.0.0, 9.0.10 (12 projects)
```

Un `LIST` llega como `object?[]`, no como `string[]`: convierte cada elemento. Un `STRUCT` llega como un `Dictionary<string, object?>`. `collect` no garantiza ningún orden, así que el programa ordena; `Order()` sobre cadenas pone `10.0.0` antes de `9.0.0`.

`MongoDB.Driver` se usa en cinco versiones, de dos versiones mayores. El [ejercicio 2](#ejercicios) examina lo que eso significa para los proyectos que se referencian entre sí.

### El bug de los agregados, también en 0.19.1

`count(*)` va antes de `collect(DISTINCT …)` en la consulta anterior, y no por casualidad ([líneas 123-130](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L123-L130)):

```cypher
MATCH (p:Project)-[u:USES]->(k:Package {name: 'MongoDB.Driver'})
RETURN k.name, collect(DISTINCT u.version) AS versions, count(*) AS projects
```

```text
DISTINCT first: MongoDB.Driver, 5 versions, 0 projects
```

0 proyectos en lugar de 14. Es el bug del [diario](../journal/#2-countdistinct--antes-de-sum-deja-la-suma-en-null), en una forma más general: con una clave de agrupación, un agregado que sigue a un agregado `DISTINCT` en la misma proyección es erróneo, `NULL` para `sum` y 0 para `count`. Está tanto en el motor 0.19.1 del paquete como en la CLI 0.20.4. La solución alternativa es la misma: pon los agregados `DISTINCT` al final.

## Filas como registros

Sin Dapper, pero una función auxiliar de diez líneas convierte las filas en un registro ([líneas 138-145](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L138-L145) y [249-256](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L249-L256)):

```csharp
IEnumerable<T> Query<T>(string cypher, Func<object?[], T> map)
{
    using var result = connection.Query(cypher);
    foreach (var row in result.Rows())
    {
        yield return map(row);
    }
}
```

```csharp
foreach (var project in Query(
    "MATCH (p:Project) WHERE NOT p.in_solution RETURN p.name, p.path, p.language ORDER BY p.path LIMIT 3",
    row => new Project((string)row[0]!, (string)row[1]!, (string)row[2]!)))
{
    Console.WriteLine(project);
}
```

```text
Project { Name = FloorManager, Path = Apps/FloorManager/FloorManager.csproj, Language = C# }
Project { Name = GaChatbot, Path = Apps/GaChatbot/GaChatbot.csproj, Language = C# }
Project { Name = InteractiveTutorial, Path = Apps/InteractiveTutorial/InteractiveTutorial.csproj, Language = C# }
38 projects are not in AllProjects.slnx
```

El `using` dentro del iterador libera el resultado cuando termina el `foreach`, incluso cuando termina antes de tiempo con `break` o `Single()`. 38 de los 111 proyectos no están en `AllProjects.slnx`: una compilación de la solución no los compila.

## Fechas y horas

Las [líneas 147-167](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L147-L167) envían un `DateTimeOffset` y un `DateTime` para las 9:30 en Nueva York, y los comparan con un literal:

```csharp
using (var result = connection.Execute(
    "RETURN $offset AS offset, $local AS local, timestamp('2026-09-14T09:30:00-04:00') AS literal",
    new Dictionary<string, object?>
    {
        ["offset"] = new DateTimeOffset(2026, 9, 14, 9, 30, 0, TimeSpan.FromHours(-4)),
        ["local"] = new DateTime(2026, 9, 14, 9, 30, 0),
    }))
```

```text
offset   DateTimeOffset 2026-09-14 13:30:00 +00:00
local    DateTime 2026-09-14 09:30:00, Kind = Utc
literal  DateTime 2026-09-14 09:30:00, Kind = Utc
```

- Un `DateTimeOffset` se convierte en un `TIMESTAMP_TZ`, almacenado en UTC: vuelve como 13:30 en `+00:00`, el mismo instante.
- Un `DateTime` se convierte en un `TIMESTAMP`. Su [`Kind`](https://learn.microsoft.com/dotnet/api/system.datetime.kind) es `Unspecified` aquí, y el binding lo toma como UTC ([`PreparedStatement.cs`, líneas 168-171](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/PreparedStatement.cs#L168-L171)); uno `Local` se convierte con `ToUniversalTime()`. Vuelve con `Kind = Utc`.
- **El literal es erróneo.** `timestamp('…-04:00')` devuelve 9:30: el desfase se descarta sin convertir, mientras que el `COPY` de la lección 4 convertía el mismo texto a UTC. La CLI 0.20.4 hace lo mismo, y `CAST(… AS TIMESTAMP)` también; `CAST(… AS TIMESTAMP_TZ)` da 13:30. Un sexto bug para el [diario](../journal/).

## Errores

[Líneas 169-178](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L169-L178):

```text
LadybugQueryException: Binder exception: Table Projet does not exist.
LadybugQueryException: Binder exception: Cannot find property nam for p.
LadybugQueryException: Runtime exception: Found duplicated primary key value Common/GA.Core/GA.Core.csproj, which violates the uniqueness constraint of the primary key column.
two statements, one result: COUNT_STAR() = 111
packages created by two statements: Test.A, Test.B
```

Todo error de consulta es una `LadybugQueryException`, con el tipo al principio del mensaje: `Binder exception` para lo que el motor rechaza antes de ejecutar, `Runtime exception` para lo que falla durante la ejecución. No hay ningún código de error que comprobar, a diferencia de `SqlException.Number`.

**Varias sentencias en un solo `Query` devuelven solo el primer resultado**, y se ejecutan todas: `MATCH (p:Project) RETURN count(*); MATCH (k:Package) RETURN count(*)` da el número de proyectos, y el número de paquetes se pierde; las dos sentencias `CREATE` crearon cada una su nodo. La API de C tiene `lbug_query_result_has_next_query_result` para los resultados siguientes ([`lbug.h`, línea 771](https://github.com/LadybugDB/ladybug/blob/v0.19.1/src/include/c_api/lbug.h#L771)), y `lbug_connection_interrupt` y `lbug_connection_set_query_timeout` para detener una consulta larga (líneas 465 y 472); el binding 0.19.1 no expone ninguna de ellas. Envía una sentencia por llamada.

## Compartir un archivo con la CLI

`new Database("out/net/ga.lbdb")` crea o abre un archivo de base de datos. [`check.sh`, líneas 14-24](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/check.sh#L14-L24), crea uno desde C#, lo consulta con la CLI y luego lo vuelve a abrir desde C#, dos veces:

```text
created out/net/ga.lbdb with LadybugDB 0.19.1
-- the CLI, read-only
p.name
GA.Core
opened out/net/ga.lbdb: GA.Core
-- the CLI, read-write
p.name
GA.Core
LadybugException: Failed to open Ladybug database at 'out/net/ga.lbdb'.
```

La CLI 0.20.4 lee el archivo escrito por 0.19.1 en ambos modos. Pero, abierto en lectura y escritura, convierte el archivo a su propia versión de almacenamiento, 47 en lugar de 43 ([`storage_version_info.h`, líneas 46-49](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/storage/storage_version_info.h#L46-L49)), sin ningún mensaje: a partir de ahí, el programa de C# no puede abrirlo, y la excepción no dice por qué. Con `--read_only`, el archivo se queda como estaba. Desde C#, `new SystemConfig { ReadOnly = true }` hace lo mismo.

Mientras el paquete vaya por detrás de la CLI, abre los archivos de la aplicación con `lbug --read_only`. Varios procesos pueden abrir un archivo en solo lectura al mismo tiempo; solo uno puede abrirlo en lectura y escritura ([concurrencia](https://docs.ladybugdb.com/concurrency/)).

## Hilos y conexiones

El modo `timings` ejecuta la misma consulta, los 7.793 recorridos del grafo de proyectos de hasta 10 relaciones, de tres formas ([líneas 221-236](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L221-L236)). Tiempos en milisegundos, de la ejecución de CI de esta lección y de mi máquina; varían de una ejecución a otra, así que la CI los imprime sin compararlos:

| | una consulta | 4 consultas, 1 conexión, 4 hilos | 4 consultas, 4 conexiones, 4 hilos |
|---|---|---|---|
| mi máquina (Windows, 24 hilos) | 12 | 49 | 25 |
| runner de Linux | 9 | 49 | 20 |
| runner de macOS | 10 | 53 | 27 |
| runner de Windows | 17 | 76 | 42 |

Un `Connection` puede usarse desde varios hilos, pero toma un bloqueo en cada llamada ([`Connection.cs`, línea 40](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/Connection.cs#L40)): cuatro consultas en una conexión tardan cuatro veces lo que tarda una. Una conexión por hilo, sobre el mismo `Database`, las ejecuta en paralelo. En una aplicación ASP.NET Core, eso significa un `Database` para el proceso, un singleton, y un `Connection` por solicitud o por unidad de trabajo.

## Puntos clave

- El paquete `LadybugDB` no es ADO.NET: `Database`, `Connection`, `Query` o `Execute`, y `Rows()` como `object?[]`. Sin Dapper; un pequeño iterador convierte las filas en registros.
- `LadybugDB.Native` incluye el motor para cinco runtimes; un único `LadybugDB.Native.<rid>` o `dotnet publish -r` conserva solo uno. El paquete usa el motor 0.19.1, por detrás de la CLI 0.20.4.
- `Rows()` se puede enumerar una vez: la segunda vez está vacío, sin aviso.
- Parámetros: un diccionario, o `Prepare` y `Bind` para reutilizar la sentencia. Ni `decimal` ni nombres de archivo.
- Los valores de grafo vuelven como registros `Node`, `Rel` y `RecursiveRel`. Los ID internos y el camino elegido por `SHORTEST` pueden diferir de una máquina a otra.
- Un agregado `DISTINCT` antes de otro agregado estropea este último también en 0.19.1; `timestamp()` descarta el desfase de su argumento.
- `Query` con varias sentencias devuelve el primer resultado y las ejecuta todas.
- Abrir un archivo en lectura y escritura con una CLI más reciente lo actualiza más allá de lo que el paquete puede leer: usa `--read_only`.
- Un `Database` por proceso, un `Connection` por hilo.

## Ejercicios

Las soluciones están al final de [`Program.cs`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/csharp/ProjectGraph/Program.cs), y su salida está en `expected.txt`: la CI las comprueba con el resto.

1. Escribe `List<string> Dependents(PreparedStatement statement, string name)`, que devuelve los nombres de los proyectos que dependen de un proyecto, directa o indirectamente. Prepara la sentencia una vez y llama al método para `GA.Business.Assets`, `GA.Data.MongoDB` y `GaApi`. ¿Cuántos dependientes tiene `GA.Business.Assets`?

<details>
<summary>Solución</summary>

[Líneas 180-192](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L180-L192) y [258-262](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L258-L262):

```csharp
using (var dependents = connection.Prepare("""
    MATCH (d:Project)-[:REFERENCES*1..10]->(:Project {name: $name})
    RETURN DISTINCT d.name
    ORDER BY d.name
    """))
{
    foreach (var name in new[] { "GA.Business.Assets", "GA.Data.MongoDB", "GaApi" })
    {
        var names = Dependents(dependents, name);
        Console.WriteLine($"{name}: {names.Count} dependents{(names.Count > 0 ? $", from {names[0]} to {names[^1]}" : "")}");
    }
}
```

```csharp
static List<string> Dependents(PreparedStatement statement, string name)
{
    using var result = statement.Bind("name", name).Execute();
    return result.Rows().Select(row => (string)row[0]!).ToList();
}
```

```text
GA.Business.Assets: 31 dependents, from AllProjects.AppHost to VectorSearchBenchmark
GA.Data.MongoDB: 29 dependents, from AllProjects.AppHost to VectorSearchBenchmark
GaApi: 4 dependents, from AllProjects.AppHost to VectorSearchBenchmark
```

La flecha está invertida respecto a la sección 4: `(d)-[…]->(:Project {name: $name})`. `ToList()` lee las filas antes de que se libere el resultado, y devuelve una lista que quien llama puede enumerar tantas veces como quiera.

31 nombres, pero 32 proyectos: `count(DISTINCT d)` da 32. Dos proyectos se llaman `GaApi.Tests`, en `Tests/Apps/GaApi.Tests` y en `Tests/GaApi.Tests`, y `DISTINCT d.name` los fusiona. `name` no es la clave: `{name: $name}` puede coincidir con varios nodos, cosa que no puede ocurrir con `path`, la clave primaria.

</details>

2. Un proyecto que usa una versión mayor de un paquete y referencia, directa o indirectamente, un proyecto que usa otra versión mayor obtiene una sola versión al compilar: [NuGet elige una](https://learn.microsoft.com/nuget/concepts/dependency-resolution) para todo el grafo de dependencias del proyecto. Encuentra estos conflictos para `MongoDB.Driver` y `Microsoft.ML.Tokenizers`, con una sentencia preparada que recibe el nombre del paquete.

<details>
<summary>Solución</summary>

[Líneas 194-210](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L194-L210):

```csharp
using (var conflicts = connection.Prepare("""
    MATCH (a:Project)-[ua:USES]->(k:Package {name: $package}), (a)-[:REFERENCES*1..10]->(b:Project)-[ub:USES]->(k)
    WHERE split_part(ua.version, '.', 1) <> split_part(ub.version, '.', 1)
    RETURN DISTINCT a.name, ua.version, b.name, ub.version
    ORDER BY a.name, b.name
    """))
{
    foreach (var package in new[] { "MongoDB.Driver", "Microsoft.ML.Tokenizers" })
    {
        using var result = conflicts.Bind("package", package).Execute();
        foreach (var row in result.Rows())
        {
            Console.WriteLine($"{package}: {row[0]} {row[1]}, but {row[2]} {row[3]}");
        }
    }
}
```

```text
MongoDB.Driver: GA.Analytics.Service 3.2.0, but GA.Data.MongoDB 2.30.0
MongoDB.Driver: GA.BSP.Service 3.2.0, but GA.Data.MongoDB 2.30.0
MongoDB.Driver: GA.DocumentProcessing.Service 3.2.0, but GA.Data.MongoDB 2.30.0
MongoDB.Driver: GaApi 3.5.0, but GA.Data.MongoDB 2.30.0
Microsoft.ML.Tokenizers: GaApi 1.0.2, but GA.Business.ML 2.0.0
Microsoft.ML.Tokenizers: GaApi 1.0.2, but GA.Domain.Services 2.0.0
```

El patrón nombra `k` dos veces, así que ambas relaciones `USES` van al mismo paquete. `split_part(…, 1)` toma la versión mayor.

La regla de NuGet es que gana la referencia directa. `GaApi` obtiene `MongoDB.Driver` 3.5.0, y `GA.Data.MongoDB`, compilado contra 2.30.0, se ejecuta con 3.5.0: una nueva versión mayor puede haber eliminado lo que llama el código antiguo. Para `Microsoft.ML.Tokenizers`, la referencia directa es la más baja: `GaApi` obtiene 1.0.2 aunque dos de sus dependencias piden al menos 2.0.0. NuGet informa de esa degradación como [NU1605](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1605), un error por defecto en los proyectos SDK, pero el `Directory.Build.props` de ga suprime NU1605 para toda la solución. Si estos proyectos fallan en tiempo de ejecución, por ejemplo por un método ausente, está *por verificar*: no he compilado ni ejecutado ga para esta lección.

</details>

3. `(long)row[0]!` lee un recuento. ¿Por qué `(int)row[0]!` lanza una excepción, y cuáles son dos formas de obtener un `int`?

<details>
<summary>Solución</summary>

[Líneas 212-219](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L212-L219):

```csharp
using (var result = connection.Query("MATCH (p:Project) RETURN count(*)"))
{
    var count = result.Rows().Single()[0];
    Try(() => Console.WriteLine((int)count!));
    Console.WriteLine((int)(long)count!);
    Console.WriteLine(Convert.ToInt32(count));
}
```

```text
InvalidCastException: Unable to cast object of type 'System.Int64' to type 'System.Int32'.
111
111
```

`count(*)` es un `INT64`, y la fila contiene un `long` con boxing. El unboxing debe nombrar el tipo exacto: `(int)` sobre un `object` es un unboxing, no una [conversión numérica](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/numeric-conversions). `(int)(long)count` hace el unboxing y luego convierte; `Convert.ToInt32` hace las dos cosas, y lanza `OverflowException` si el valor no cabe. `DbDataReader.GetInt32` tiene la misma trampa con una columna `bigint`, con otra excepción.

</details>

## Fuentes

- [`LadybugDB` en NuGet](https://www.nuget.org/packages/LadybugDB), [`LadybugDB.Native`](https://www.nuget.org/packages/LadybugDB.Native), y el [repositorio `ladybug-dotnet`](https://github.com/LadybugDB/ladybug-dotnet) en el commit [`0f58f1a`](https://github.com/LadybugDB/ladybug-dotnet/tree/0f58f1a)
- [Cabecera de la API de C de LadybugDB, `lbug.h`](https://github.com/LadybugDB/ladybug/blob/v0.19.1/src/include/c_api/lbug.h)
- [Concurrencia](https://docs.ladybugdb.com/concurrency/): bases de datos de solo lectura y de lectura y escritura, conexiones
- [Tipos de datos](https://docs.ladybugdb.com/cypher/data-types/): `TIMESTAMP`, `TIMESTAMP_TZ`, `LIST`, `STRUCT`
- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/): caminos más cortos
- [Introducción a ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/), [identificadores de runtime](https://learn.microsoft.com/dotnet/core/rid-catalog), [resolución de dependencias de NuGet](https://learn.microsoft.com/nuget/concepts/dependency-resolution)
