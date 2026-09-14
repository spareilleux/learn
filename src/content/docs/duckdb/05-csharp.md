---
title: 5. DuckDB from C#
description: DuckDB.NET as an ADO.NET provider — connection, data reader, parameters, the .NET types of DuckDB values, lists and structs, errors, Dapper, and bulk loading with the appender.
sidebar:
  order: 5
---

The CLI runs DuckDB in its own process. From C#, DuckDB runs **in your process**, as a native library called through [DuckDB.NET](https://duckdb.net/), an [ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/) provider: `DbConnection`, `DbCommand`, `DbDataReader`, the classes you already use with SQL Server or SQLite. The program of this lesson is [`csharp/CiQueries/Program.cs`](https://github.com/spareilleux/learn/blob/main/code/duckdb/csharp/CiQueries/Program.cs), run from `code/duckdb` and compared with [`csharp/expected.txt`](https://github.com/spareilleux/learn/blob/main/code/duckdb/csharp/expected.txt) on the three operating systems.

## The project

```xml
<ItemGroup>
  <PackageReference Include="Dapper" Version="2.1.86" />
  <PackageReference Include="DuckDB.NET.Data.Full" Version="1.5.5" />
</ItemGroup>
```

DuckDB.NET comes in [four packages](https://duckdb.net/docs/getting-started.html): the ADO.NET provider (`DuckDB.NET.Data`) or the low-level bindings, each with or without the native DuckDB library. `.Full` includes it, for every platform, and that has a cost:

| | Size |
|---|---|
| `duckdb.net.bindings.full` 1.5.5 in the NuGet cache | 420 MB |
| `bin/Debug/net10.0` after `dotnet build` | 316 MB |
| `dotnet publish -r linux-x64` | 69 MB |

A plain build copies the native library of the five runtimes: `win-x64` (37 MB), `win-arm64` (43 MB), `linux-x64` (71 MB), `linux-arm64` (63 MB) and `osx` (117 MB, one file for Intel and Apple Silicon). Publishing for one runtime identifier keeps only its own. The package version follows DuckDB's: 1.5.5 embeds DuckDB 1.5.5.

## A query with a data reader

```csharp
// An in-memory database, like the CLI started without a file name
using var connection = new DuckDBConnection("Data Source=:memory:");
connection.Open();
Console.WriteLine($"DuckDB {connection.ServerVersion}");
```

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

Nothing new for an ADO.NET user, and the SQL is the SQL of lesson 1, file name included. `Data Source=file.duckdb` opens or creates a database file instead; lesson 8 is about that.

`'data/runs.json'` is relative to the **working directory of the process**, not to the project or the executable. Run from the project folder with a `../data` path, the first version failed:

```text
Unhandled exception. DuckDB.NET.Data.DuckDBException (0x80004005): IO Error: No files found that match the pattern "../data/runs.json"
```

`../data` from `csharp/CiQueries` is `csharp/data`, which doesn't exist. An application that reads files should build absolute paths, from its configuration or `AppContext.BaseDirectory`.

## Parameters

DuckDB [accepts three syntaxes](https://duckdb.net/docs/basic-usage.html): `?`, `$1` and `$name`. With `DuckDBParameter`, the name goes without the `$`:

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

Even the file name is a parameter: `read_json($path)`, where SQL Server's `OPENROWSET(BULK …)` only takes a literal and pushes you to build the SQL string. A path that comes from a user still needs checking before it reaches `read_json`, since DuckDB can read any file the process can.

## DuckDB types as .NET types

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

- `DATE` becomes `DateOnly`, and `INTERVAL` becomes `TimeSpan`.
- `sum` of a `BIGINT` is a `HUGEINT`, a 128-bit integer, so `System.Numerics.BigInteger`, not `long`. Exercise 2 shows what that costs; `CAST(sum(…) AS BIGINT)` in the SQL avoids the question.
- A `TIMESTAMP WITH TIME ZONE` comes back as a `DateTime` holding the UTC time, but with [`Kind`](https://learn.microsoft.com/dotnet/api/system.datetime.kind) `Unspecified`, not `Utc`. `ToUniversalTime()` treats an `Unspecified` value as local time and shifts it: in a scratch program on this machine (UTC−4), `15:53:16` became `19:53:16`, four hours off. `GetFieldValue<DateTimeOffset>` returns an explicit `+00:00`. The session's `TimeZone` setting of lesson 2 doesn't change what C# receives: with `SET TimeZone = 'Europe/Paris'`, the same `15:53:16` came back.
- The dates are formatted with `CultureInfo.InvariantCulture`: the first version printed `2026-09-14 2:01:09 PM` on this machine, a format that depends on the user's regional settings and would never match the CI's expected output.

## Lists and structs

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

```csharp
// DuckDB.NET maps struct fields to settable properties with the same name, ignoring case
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

- A `LIST` of `VARCHAR` reads as `List<string>`; a `STRUCT` as a `Dictionary<string, object>`, or as a class of yours.
- The mapping is by property name, ignoring case: `Started_At` matches `started_at`. **`StartedAt` doesn't, and nothing says so**: the property keeps its default value, `0001-01-01`. In C#, the natural name is the one that silently fails. Rename in SQL (exercise 1), or check the defaults in a test.
- A positional `record Step(long Number, …)` fails at run time: `MissingMethodException: Cannot dynamically create an instance of type 'Step'. Reason: No parameterless constructor defined.` The target type needs a parameterless constructor and setters, or `init` accessors.

## Errors

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

One exception type, `DuckDBException`, with the same message as the CLI, suggestions and position included. Its `ErrorType` says `Invalid`, not `Binder`: to tell error kinds apart, the message prefix is more precise than the property. The command stays usable after the error: in a scratch program, the same `DuckDBCommand` then ran `SELECT 42` and returned `42`. Lesson 6 shows that the Java driver behaves differently.

## Dapper

[Dapper](https://github.com/DapperLib/Dapper) extends any `DbConnection`, so it works on `DuckDBConnection` without an adapter:

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

```csharp
// Dapper maps columns to constructor parameters, ignoring case
record RunSummary(long DatabaseId, string WorkflowName, DateTime CreatedAt, TimeSpan Took);
```

```text
== 6. Dapper
34772306529 Rust course examples     2026-09-13 17:40:34 00:00:40
34772373891 Rust course examples     2026-09-13 17:41:56 00:00:31
34776807003 Rust course examples     2026-09-13 19:09:08 00:01:55
```

The properties of the anonymous object become the `$conclusion` and `$event` parameters; `@event` is how C# writes a property named after a keyword. Unlike DuckDB.NET's struct mapping, Dapper fills a positional record through its constructor. The three failed pushes are the Rust course failures of lesson 2.

## Bulk loading: the appender

Loading rows one `INSERT` at a time is slow in every database. DuckDB.NET exposes DuckDB's [appender](https://duckdb.org/docs/current/data/appender), which writes rows straight into a table's storage:

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

The program's `timings` mode loads a million rows with the appender, then 10,000 rows with a parameterized `INSERT` in a transaction. The CI prints the timings without comparing them:

| Runner | Appender, 1,000,000 rows | `INSERT`, 10,000 rows |
|---|---|---|
| `ubuntu-latest` | 256 ms | 3,165 ms |
| `windows-latest` | 331 ms | 3,917 ms |
| `macos-latest` | 226 ms | 1,312 ms |
| This machine (Windows, Release) | 170 ms | 1,577 ms |

With 100 times more rows, the appender is still 6 to 12 times faster: per row, 600 to 1,200 times faster. The rows are written when the appender is disposed, hence the `using`: in a scratch program, `count(*)` on the table was `0` after appending 10 rows, and `10` after `Dispose()`. For data already in a file, `INSERT INTO … SELECT * FROM 'file.parquet'` is simpler still and doesn't cross the managed/native boundary for each value.

## Key takeaways

- DuckDB.NET is an ADO.NET provider: `DuckDBConnection`, commands, readers, transactions and Dapper work as with any other database.
- The `.Full` package embeds the native library of every platform; publish for a runtime identifier to ship one.
- Relative file paths in SQL are relative to the process's working directory.
- `DATE` → `DateOnly`, `INTERVAL` → `TimeSpan`, `HUGEINT` → `BigInteger`, `TIMESTAMPTZ` → `DateTime` with `Kind` `Unspecified`.
- Structs map to classes by property name, and an unmatched property silently keeps its default.
- For many rows, use the appender, or let DuckDB read the file.

## Exercises

1. Change the `Step` class so that `StartedAt` gets the step's start time without renaming it, by changing only the SQL.

<details>
<summary>Solution</summary>

Rebuild each struct with the names the class expects, with `list_transform` from lesson 3:

```sql
SELECT list_transform(steps, lambda s: {'number': s.number, 'name': s.name, 'startedAt': s.started_at}) AS steps
FROM 'data/jobs.json'
WHERE id = 104004920113
```

With a `Step` class that only has `Number`, `Name` and `StartedAt`, the first step reads:

```text
1 Set up job 2026-09-14 14:01:15
```

The SQL becomes the one place where the external format (the GitHub API's `snake_case`) meets the C# naming. This check was run once in a scratch program, not in the CI program.

</details>

2. `ExecuteScalar` on `SELECT sum(databaseId) FROM 'data/runs.json'` returns an `object`. What's its type, and what does `(long)command.ExecuteScalar()!` do?

<details>
<summary>Solution</summary>

`sum` of a `BIGINT` is a `HUGEINT`, read as `System.Numerics.BigInteger` (section 3 of the program). The cast throws:

```text
InvalidCastException: Unable to cast object of type 'System.Numerics.BigInteger' to type 'System.Int64'.
```

Unboxing only works to the exact boxed type. The usual escape, `Convert.ToInt64(value)`, fails too, because `BigInteger` doesn't implement `IConvertible`:

```text
InvalidCastException: Unable to cast object of type 'System.Numerics.BigInteger' to type 'System.IConvertible'.
```

What works: unbox to the real type, then convert, `(long)(BigInteger)value`, which gave `4351672497299`; or `CAST(sum(databaseId) AS BIGINT)` in SQL, so that the reader returns a `long`. Checked in a scratch program, not in the CI program.

</details>

3. Why does section 5 print `e.Message.Split('\n')[0]` rather than the whole message?

<details>
<summary>Solution</summary>

The full message has several lines, like in the CLI: the error, `Candidate bindings: "workflowName", "conclusion"`, a blank line, then the query with a `^` under the position. The first line is enough for a log and keeps the expected output short. Keep the full message where a developer reads it: the position marker is the most useful part of a syntax error in a long query.

</details>

## Sources

- [DuckDB.NET documentation](https://duckdb.net/): [getting started](https://duckdb.net/docs/getting-started.html) and [basic usage](https://duckdb.net/docs/basic-usage.html)
- [DuckDB.NET source code](https://github.com/Giorgi/DuckDB.NET)
- [`DuckDB.NET.Data.Full` on NuGet](https://www.nuget.org/packages/DuckDB.NET.Data.Full)
- [DuckDB clients overview](https://duckdb.org/docs/current/clients/overview) and [appender](https://duckdb.org/docs/current/data/appender)
- [Dapper](https://github.com/DapperLib/Dapper)
- [ADO.NET overview](https://learn.microsoft.com/dotnet/framework/data/adonet/)
