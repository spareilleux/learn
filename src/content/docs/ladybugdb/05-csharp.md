---
title: 5. LadybugDB from C#
description: The LadybugDB NuGet package on the project graph of GuitarAlchemist/ga — native packages, rows, parameters and prepared statements, nodes and paths, lists and structs, dates, errors, sharing a file with the CLI, and threads — with one more aggregate bug and a date bug.
sidebar:
  order: 5
---

From C#, LadybugDB runs **in your process**, as a native library called through the [`LadybugDB`](https://www.nuget.org/packages/LadybugDB) NuGet package. The package isn't an [ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/) provider: no `DbConnection`, no `DbDataReader`, and so no [Dapper](https://www.nuget.org/packages/Dapper). Its classes are close to them, though:

| ADO.NET | `LadybugDB` 0.19.1 |
|---|---|
| a connection string | `new Database(path, config)`: the database itself, in your process |
| `DbConnection` | `new Connection(database)`: several connections can share one `Database` |
| `DbCommand.ExecuteReader()` | `connection.Query(cypher)` returns a `QueryResult` |
| `DbDataReader.Read()` and `GetInt64(i)` | `result.Rows()`: an `IEnumerable<object?[]>` |
| `DbParameter` | `connection.Execute(cypher, dictionary)` or `Prepare(cypher)` then `Bind(name, value)` |
| `DbException` | `LadybugException` and `LadybugQueryException` |

The program of this lesson is [`csharp/ProjectGraph/Program.cs`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/csharp/ProjectGraph/Program.cs), run from `code/ladybugdb` and compared with [`csharp/expected.txt`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/csharp/expected.txt) on the three operating systems. The package has no page in the LadybugDB documentation: its reference is the [README of `ladybug-dotnet`](https://github.com/LadybugDB/ladybug-dotnet) and its source code.

## A new graph: the projects of GuitarAlchemist/ga

Lessons 1 to 4 queried this site. Lessons 5 and 6 query a .NET solution: [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), a music theory application with 111 C# and F# projects. [`data/ga/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/ga/extract.py) reads its project files at commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893) and writes three CSV files to [`data/ga`](https://github.com/spareilleux/learn/tree/main/code/ladybugdb/data/ga):

| Table | Kind | From |
|---|---|---|
| `Project(path, name, language, sdk, frameworks, in_solution)` | node | `projects.csv`: each `.csproj` and `.fsproj`, and whether `AllProjects.slnx` lists it |
| `Package(name)` | node | the distinct packages of `package_refs.csv` |
| `REFERENCES` | relationship, `Project` to `Project` | `project_refs.csv`: the `<ProjectReference>` items |
| `USES(version)` | relationship, `Project` to `Package` | `package_refs.csv`: the `<PackageReference>` items, with their version |

A dependency graph is what `dotnet build` walks, and what Visual Studio's dependency diagrams draw; here it's a graph you can query.

`version` is the version written in each project file. The [`Directory.Build.props`](https://github.com/GuitarAlchemist/ga/blob/a26a7893/Directory.Build.props) of ga changes some of them for every project, with `<PackageReference Update="…" Version="…"/>` items: `Microsoft.Extensions.Options`, `System.Numerics.Tensors` and twelve others. The extraction doesn't apply them; the queries of this lesson use packages that file doesn't touch.

## The project

```xml
<ItemGroup>
  <PackageReference Include="LadybugDB" Version="0.19.1" />
  <PackageReference Include="LadybugDB.Native" Version="0.19.1" />
</ItemGroup>
```

`LadybugDB` is the managed code, calling the C API of the engine with P/Invoke. The engine itself is in a [native package per runtime identifier](https://learn.microsoft.com/dotnet/core/rid-catalog): `LadybugDB.Native.win-x64`, `linux-x64`, `linux-arm64`, `osx-x64` and `osx-arm64`. `LadybugDB.Native` references all five:

| | Size |
|---|---|
| the five native packages in the NuGet cache | 25 MB (`win-x64`) to 38 MB (`linux-x64`) each |
| `bin/Release/net10.0` after `dotnet build` | 131 MB, of which 19 to 28 MB per runtime |
| `dotnet publish -r win-x64` | 20 MB |

An application for a single platform can reference `LadybugDB.Native.win-x64` alone instead of the meta-package.

**The version is behind the CLI.** 0.19.1 is the latest version on NuGet, and the README says the first three numbers of the package version are the engine's: this program runs the 0.19.1 engine, the CLI of lessons 1 to 4 is 0.20.4. The program prints both versions it knows ([lines 10-14](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L10-L14)):

```csharp
Console.WriteLine($"LadybugDB {LadybugVersion.Version}, storage version {LadybugVersion.StorageVersion}");
// An empty path: an in-memory database, like the CLI started without a file name
using var database = new Database("");
using var connection = new Connection(database);
```

```text
LadybugDB 0.19.1, storage version 43
```

The storage version is the format of database files. It matters when the program and the CLI open the same file, [below](#sharing-a-file-with-the-cli).

## Loading: a reference to a project that isn't there

The schema and the `COPY` statements are those of lesson 2, sent one by one with `connection.Query` ([lines 16-32](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L16-L32)):

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

`Execute` is a helper of the program that prints the first column of every row. `ReactApp1.Server.csproj` references `reactapp1.client.esproj`, a JavaScript project that the extraction didn't keep: the error of [lesson 2](../02-loading/), now a .NET exception. The CLI printed the error and went on; in C#, the failed `COPY` throws and nothing is loaded until the retry with `IGNORE_ERRORS`.

## Rows

[Lines 34-48](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L34-L48):

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

- `RowCount` is known before the first row: the engine has computed the whole result.
- Each row is an `object?[]`, and `INT64` arrives boxed as `long`.
- **`Rows()` can be enumerated only once**, like a `DbDataReader`, but it doesn't say so: the second `foreach` finds no row, and no exception. `Rows()` is an iterator over a cursor of the native result ([`QueryResult.cs`, lines 117-133](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/QueryResult.cs#L117-L133)). Call `.ToList()` when you need the rows twice.
- `QueryResult` is `IDisposable`: it holds native memory until `Dispose`.

57 of the 111 projects reference `GA.Domain.Core`.

## Parameters

Two ways, with a dictionary or with a prepared statement ([lines 51-67](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L51-L67)):

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

`$name` in Cypher, `"name"` without the `$` in C#. `Execute` with a dictionary prepares the statement on each call; `Prepare` once, then `Bind` and `Execute` for each value, saves that work, like `DbCommand.Prepare()`. `Bind` returns the statement, so the calls chain. The web API, `GaApi`, depends on 20 projects directly or not: the variable-length pattern of lesson 3 finds them all.

What the binding accepts, and what it reports ([lines 68-83](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L68-L83)):

```text
int 2: 42 projects reference more than 2 projects
string "2": 42 projects reference more than 2 projects
decimal 2m: NotSupportedException: Cannot bind a parameter of type System.Decimal.
LadybugQueryException: Parameter name not found.
LadybugQueryException: Binder exception: Cannot find parameter file. This should not happen.
```

- The query compares `COUNT { … } > $n`. An `int` works, and so does the string `"2"`: the engine casts it to a number. SQL Server does the same with an `nvarchar` parameter compared to an `int` column.
- A `decimal` fails in the binding, before the engine sees it ([`PreparedStatement.cs`, line 198](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/PreparedStatement.cs#L198)): pass a `double`, or a string cast in Cypher.
- A dictionary with `nom` instead of `name` fails with `Parameter name not found.`, without the name.
- A parameter can't be a file name: `COPY Package FROM $file` fails at bind time, with a message that says it should not happen. Build the file name into the statement, from a trusted value.

## Nodes, relationships and paths

A query can return a whole node or a whole path ([lines 85-104](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L85-L104)):

```csharp
using (var result = connection.Query("""
    MATCH path = (app:Project {name: 'GaApi'})-[:REFERENCES* ALL SHORTEST 1..10]->(assets:Project {name: 'GA.Business.Assets'})
    RETURN app, path
    """))
{
    var rows = result.Rows().ToList();
    var app = (Node)rows[0][0]!;
    // The internal ID (table:offset) depends on the load, which differs between runs and machines: print its type only
    Console.WriteLine($"{app.Label} ({app.Id.GetType().Name}): {string.Join(", ", app.Properties.Select(p => $"{p.Key}={p.Value}"))}");
    // Several shortest paths, in no particular order: sort them before printing
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

The binding maps graph values to records ([`GraphTypes.cs`](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/GraphTypes.cs)): `Node(Id, Label, Properties)`, `Rel(Id, Source, Destination, Label, Properties)`, and `RecursiveRel(Nodes, Rels)` for a path. `Properties` is a dictionary; `Source` and `Destination` are the `InternalId` of the nodes, not the nodes. The `Nodes` of a named path include both ends.

The first version of this section printed `app.Id` and used `SHORTEST`, and the CI failed on the three runners:

- the ID of `GaApi` was `0:11` on my machine and on the Windows runner, `0:47` on Linux and macOS, with the same CSV file. An internal ID is the table and the offset where the node was stored: use it within a result, to connect a `Rel` to its nodes, never as a key you keep;
- there are two shortest paths, through `GA.Business.AI` or `GA.Business.ML`, and `SHORTEST` returned one on my machine and the other on the runners. `ALL SHORTEST` returns both, sorted by the program.

## Lists and structs

Which packages are used in several versions? ([lines 106-121](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L106-L121))

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

A `LIST` arrives as `object?[]`, not `string[]`: cast each element. A `STRUCT` arrives as a `Dictionary<string, object?>`. `collect` gives no order, so the program sorts; `Order()` on strings puts `10.0.0` before `9.0.0`.

`MongoDB.Driver` is used in five versions, across two major versions. [Exercise 2](#exercises) looks at what that means for the projects that reference each other.

### The aggregate bug, in 0.19.1 too

`count(*)` comes before `collect(DISTINCT …)` in the query above, and not by chance ([lines 123-130](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L123-L130)):

```cypher
MATCH (p:Project)-[u:USES]->(k:Package {name: 'MongoDB.Driver'})
RETURN k.name, collect(DISTINCT u.version) AS versions, count(*) AS projects
```

```text
DISTINCT first: MongoDB.Driver, 5 versions, 0 projects
```

0 projects instead of 14. It's the bug of the [journal](../journal/#2-countdistinct--before-sum-makes-the-sum-null), in a more general form: with a grouping key, an aggregate that follows a `DISTINCT` aggregate in the same projection is wrong, `NULL` for `sum` and 0 for `count`. It is in the 0.19.1 engine of the package as in the 0.20.4 CLI. The workaround is the same: put the `DISTINCT` aggregates last.

## Rows as records

No Dapper, but a ten-line helper maps rows to a record ([lines 138-145](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L138-L145) and [249-256](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L249-L256)):

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

The `using` inside the iterator disposes of the result when the `foreach` ends, even when it ends early with `break` or `Single()`. 38 of the 111 projects aren't in `AllProjects.slnx`: a build of the solution doesn't compile them.

## Dates and times

[Lines 147-167](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L147-L167) send a `DateTimeOffset` and a `DateTime` for 9:30 in New York, and compare with a literal:

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

- A `DateTimeOffset` becomes a `TIMESTAMP_TZ`, stored in UTC: it comes back as 13:30 at `+00:00`, the same instant.
- A `DateTime` becomes a `TIMESTAMP`. Its [`Kind`](https://learn.microsoft.com/dotnet/api/system.datetime.kind) is `Unspecified` here, and the binding takes it as UTC ([`PreparedStatement.cs`, lines 168-171](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/PreparedStatement.cs#L168-L171)); a `Local` one is converted with `ToUniversalTime()`. It comes back with `Kind = Utc`.
- **The literal is wrong.** `timestamp('…-04:00')` returns 9:30: the offset is dropped without converting, where the `COPY` of lesson 4 converted the same text to UTC. The 0.20.4 CLI does the same, and `CAST(… AS TIMESTAMP)` too; `CAST(… AS TIMESTAMP_TZ)` gives 13:30. A sixth bug for the [journal](../journal/).

## Errors

[Lines 169-178](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L169-L178):

```text
LadybugQueryException: Binder exception: Table Projet does not exist.
LadybugQueryException: Binder exception: Cannot find property nam for p.
LadybugQueryException: Runtime exception: Found duplicated primary key value Common/GA.Core/GA.Core.csproj, which violates the uniqueness constraint of the primary key column.
two statements, one result: COUNT_STAR() = 111
packages created by two statements: Test.A, Test.B
```

Every query error is a `LadybugQueryException`, with the kind at the start of the message: `Binder exception` for what the engine rejects before running, `Runtime exception` for what fails while running. There is no error code to test, unlike `SqlException.Number`.

**Several statements in one `Query` return the first result only**, and run them all: `MATCH (p:Project) RETURN count(*); MATCH (k:Package) RETURN count(*)` gives the project count, and the package count is lost; the two `CREATE` statements both created their node. The C API has `lbug_query_result_has_next_query_result` for the next results ([`lbug.h`, line 771](https://github.com/LadybugDB/ladybug/blob/v0.19.1/src/include/c_api/lbug.h#L771)), and `lbug_connection_interrupt` and `lbug_connection_set_query_timeout` to stop a long query (lines 465 and 472); the binding 0.19.1 exposes none of them. Send one statement per call.

## Sharing a file with the CLI

`new Database("out/net/ga.lbdb")` creates or opens a database file. [`check.sh`, lines 14-24](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/check.sh#L14-L24), creates one from C#, queries it with the CLI, then opens it from C# again, twice:

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

The 0.20.4 CLI reads the file written by 0.19.1 in both modes. But opened read-write, it converts the file to its own storage version, 47 instead of 43 ([`storage_version_info.h`, lines 46-49](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/storage/storage_version_info.h#L46-L49)), without a message: after that, the C# program can't open it, and the exception doesn't say why. With `--read_only`, the file stays as it was. From C#, `new SystemConfig { ReadOnly = true }` does the same.

As long as the package lags behind the CLI, open the application's files with `lbug --read_only`. Several processes can open a file read-only at the same time; only one can open it read-write ([concurrency](https://docs.ladybugdb.com/concurrency/)).

## Threads and connections

`timings` mode runs the same query, the 7,793 walks of the project graph up to 10 relationships, three ways ([lines 221-236](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L221-L236)). Times in milliseconds, from the CI run of this lesson and from my machine; they vary from run to run, so CI prints them without comparing them:

| | one query | 4 queries, 1 connection, 4 threads | 4 queries, 4 connections, 4 threads |
|---|---|---|---|
| my machine (Windows, 24 threads) | 12 | 49 | 25 |
| Linux runner | 9 | 49 | 20 |
| macOS runner | 10 | 53 | 27 |
| Windows runner | 17 | 76 | 42 |

A `Connection` can be used from several threads, but it holds a lock for each call ([`Connection.cs`, line 40](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/Connection.cs#L40)): four queries on one connection take four times as long as one. One connection per thread, on the same `Database`, runs them side by side. In an ASP.NET Core application, that means one `Database` for the process, a singleton, and a `Connection` per request or per unit of work.

## Key takeaways

- The `LadybugDB` package isn't ADO.NET: `Database`, `Connection`, `Query` or `Execute`, and `Rows()` as `object?[]`. No Dapper; a small iterator maps rows to records.
- `LadybugDB.Native` carries the engine for five runtimes; a single `LadybugDB.Native.<rid>` or `dotnet publish -r` keeps one. The package is on engine 0.19.1, behind the 0.20.4 CLI.
- `Rows()` can be enumerated once: the second time it's empty, silently.
- Parameters: a dictionary, or `Prepare` and `Bind` to reuse the statement. No `decimal`, no file names.
- Graph values come back as `Node`, `Rel` and `RecursiveRel` records. Internal IDs and the path chosen by `SHORTEST` can differ from one machine to another.
- A `DISTINCT` aggregate before another aggregate breaks it in 0.19.1 too; `timestamp()` drops the offset of its argument.
- `Query` with several statements returns the first result and runs them all.
- A read-write open by a newer CLI upgrades the file beyond what the package can read: use `--read_only`.
- One `Database` per process, one `Connection` per thread.

## Exercises

The solutions are at the end of [`Program.cs`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/csharp/ProjectGraph/Program.cs), and their output is in `expected.txt`: CI checks them with the rest.

1. Write `List<string> Dependents(PreparedStatement statement, string name)`, which returns the names of the projects that depend on a project, directly or not. Prepare the statement once and call the method for `GA.Business.Assets`, `GA.Data.MongoDB` and `GaApi`. How many dependents does `GA.Business.Assets` have?

<details>
<summary>Solution</summary>

[Lines 180-192](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L180-L192) and [258-262](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L258-L262):

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

The arrow is reversed compared with section 4: `(d)-[…]->(:Project {name: $name})`. `ToList()` reads the rows before the result is disposed, and returns a list the caller can enumerate as often as it wants.

31 names, but 32 projects: `count(DISTINCT d)` gives 32. Two projects are called `GaApi.Tests`, in `Tests/Apps/GaApi.Tests` and in `Tests/GaApi.Tests`, and `DISTINCT d.name` merges them. `name` isn't the key: `{name: $name}` can match several nodes, which `path`, the primary key, can't.

</details>

2. A project that uses one major version of a package and references, directly or not, a project that uses another major version gets a single version at build time: [NuGet picks one](https://learn.microsoft.com/nuget/concepts/dependency-resolution) for the whole dependency graph of the project. Find these conflicts for `MongoDB.Driver` and `Microsoft.ML.Tokenizers`, with a prepared statement that takes the package name.

<details>
<summary>Solution</summary>

[Lines 194-210](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L194-L210):

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

The pattern names `k` twice, so both `USES` relationships go to the same package. `split_part(…, 1)` takes the major version.

NuGet's rule is that a direct reference wins. `GaApi` gets `MongoDB.Driver` 3.5.0, and `GA.Data.MongoDB`, compiled against 2.30.0, runs with 3.5.0 in it: a new major version may have removed what the older code calls. For `Microsoft.ML.Tokenizers`, the direct reference is the lower one: `GaApi` gets 1.0.2 although two of its dependencies ask for at least 2.0.0. NuGet reports that downgrade as [NU1605](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1605), an error by default in SDK projects, but ga's `Directory.Build.props` suppresses NU1605 for the whole solution. Whether these projects fail at run time, on a missing method for instance, is *to verify*: I haven't built or run ga for this lesson.

</details>

3. `(long)row[0]!` reads a count. Why does `(int)row[0]!` throw, and what are two ways to get an `int`?

<details>
<summary>Solution</summary>

[Lines 212-219](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L212-L219):

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

`count(*)` is an `INT64`, and the row holds a boxed `long`. Unboxing must name the exact type: `(int)` on an `object` is an unboxing, not a [numeric conversion](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/numeric-conversions). `(int)(long)count` unboxes, then converts; `Convert.ToInt32` does both, and throws `OverflowException` if the value doesn't fit. `DbDataReader.GetInt32` has the same trap on a `bigint` column, with a different exception.

</details>

## Sources

- [`LadybugDB` on NuGet](https://www.nuget.org/packages/LadybugDB), [`LadybugDB.Native`](https://www.nuget.org/packages/LadybugDB.Native), and the [`ladybug-dotnet` repository](https://github.com/LadybugDB/ladybug-dotnet) at commit [`0f58f1a`](https://github.com/LadybugDB/ladybug-dotnet/tree/0f58f1a)
- [LadybugDB C API header, `lbug.h`](https://github.com/LadybugDB/ladybug/blob/v0.19.1/src/include/c_api/lbug.h)
- [Concurrency](https://docs.ladybugdb.com/concurrency/): read-only and read-write databases, connections
- [Data types](https://docs.ladybugdb.com/cypher/data-types/): `TIMESTAMP`, `TIMESTAMP_TZ`, `LIST`, `STRUCT`
- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/): shortest paths
- [ADO.NET overview](https://learn.microsoft.com/dotnet/framework/data/adonet/), [runtime identifiers](https://learn.microsoft.com/dotnet/core/rid-catalog), [NuGet dependency resolution](https://learn.microsoft.com/nuget/concepts/dependency-resolution)
