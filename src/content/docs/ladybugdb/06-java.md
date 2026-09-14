---
title: 6. LadybugDB from Java
description: The com.ladybugdb:lbug Maven package on the project graph of GuitarAlchemist/ga — results that don't throw, tuples that share a buffer, parameters kept between executions, nodes and paths, lists, structs and maps, dates, several statements, timeouts, and a native library left in the temporary directory.
sidebar:
  order: 6
---

The same graph as [lesson 5](../05-csharp/), from Java, with the Maven package [`com.ladybugdb:lbug`](https://central.sonatype.com/artifact/com.ladybugdb/lbug). Like the .NET package, it isn't a [JDBC](https://docs.oracle.com/javase/tutorial/jdbc/basics/index.html) driver, and it's further from JDBC than the .NET package is from ADO.NET:

| JDBC | `com.ladybugdb:lbug` 0.20.4 |
|---|---|
| `DriverManager.getConnection(url)` | `new Database(path)`, then `new Connection(database)` |
| `Statement.executeQuery(sql)` | `connection.query(cypher)` returns a `QueryResult` |
| `ResultSet.next()` and `getLong(i)` | `hasNext()`, `getNext()` returns a `FlatTuple`, `getValue(i).getValue()` |
| `PreparedStatement.setString(1, …)` | `connection.prepare(cypher)`, then `connection.execute(statement, map)` |
| an `SQLException` when the query fails | **no exception**: `result.isSuccess()` and `result.getErrorMessage()` |

The program of this lesson is [`java/src/main/java/graph/ProjectGraph.java`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java), run from `code/ladybugdb` with `mvn -q -f java/pom.xml exec:java -Dexec.args=check` and compared with [`java/expected.txt`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/java/expected.txt) on the three operating systems. The [Java page of the documentation](https://docs.ladybugdb.com/client-apis/java/) is short; the reference is the source of [`ladybug-java`](https://github.com/LadybugDB/ladybug-java), at commit [`f2fb39f`](https://github.com/LadybugDB/ladybug-java/tree/f2fb39f), the one release 0.20.4 of LadybugDB builds.

## The project

```xml
<dependency>
  <groupId>com.ladybugdb</groupId>
  <artifactId>lbug</artifactId>
  <version>0.20.4</version>
</dependency>
```

One dependency, and **the same version as the CLI**: Maven Central has the releases from 0.12.0 to 0.20.4, where NuGet stops at 0.19.1. What comes with it:

- `lbug-0.20.4.jar`, 29 MB: the Java classes and the native library for four platforms, `linux_amd64`, `linux_arm64`, `osx_arm64` and `windows_amd64`. There is none for macOS on Intel.
- 13 other jars, 7 MB: `kotlin-stdlib`, and Apache Arrow with Jackson and FlatBuffers. Arrow serves the Arrow methods of `Connection` and `QueryResult`, which this lesson doesn't use.

```java
System.out.println("LadybugDB " + Version.getVersion() + ", storage version " + Version.getStorageVersion());
// An empty path: an in-memory database, like the CLI started without a file name
try (var database = new Database(""); var conn = new Connection(database)) {
```

```text
LadybugDB 0.20.4, storage version 47
```

`Database`, `Connection`, `QueryResult`, `PreparedStatement`, `FlatTuple` and `Value` are [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html): each holds native memory, and try-with-resources frees it. Closing one twice throws `RuntimeException: Connection has been destroyed.`

## A failed query doesn't throw

[Lines 35-47](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L35-L47):

```java
run("COPY Project FROM 'data/ga/projects.csv' (HEADER = true)");
// A failed query doesn't throw: the result says it failed
try (var result = connection.query("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true)")) {
    System.out.println("isSuccess: " + result.isSuccess() + ", " + result.getErrorMessage());
}
run("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true, IGNORE_ERRORS = true)");
```

```text
111 tuples have been copied to the Project table.
isSuccess: false, Copy exception: Unable to find primary key value Experiments/React/reactapp1.client/reactapp1.client.esproj.
265 tuples have been copied to the REFERENCES table.
1 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 6
```

The error of lesson 5, but no exception: `query` returns a result whose `isSuccess()` is `false`. The JNI code only throws when the engine produces no result at all ([`lbug_java.cpp`, lines 735-748](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L735-L748)). A program that forgets to check goes on with half a graph, which is why every statement of this one goes through `run` ([lines 279-289](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L279-L289)):

```java
// Runs a statement, prints the first column of its rows, and throws when it fails
static void run(String cypher) {
    try (var result = connection.query(cypher)) {
        if (!result.isSuccess()) {
            throw new IllegalStateException(result.getErrorMessage());
        }
        while (result.hasNext()) {
            System.out.println((Object) result.getNext().getValue(0).getValue());
        }
    }
}
```

`getValue()` is declared `<T> T getValue()`: the type is whatever the caller asks for, unchecked. `println(result.getNext().getValue(0).getValue())` doesn't compile, because `println(char[])` and `println(String)` both match; the `(Object)` cast chooses.

## Rows, and tuples that share a buffer

[Lines 49-69](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L49-L69):

```java
var kept = new ArrayList<FlatTuple>();
while (result.hasNext()) {
    FlatTuple row = result.getNext();
    Object count = row.getValue(1).getValue();
    System.out.printf("%-20s %2s (%s)%n", row.getValue(0).getValue(), count, count.getClass().getName());
    kept.add(row);
}
// The tuples returned by getNext() share one buffer: the kept ones all hold the last row
System.out.println("kept rows: " + kept.stream().map(row -> (String) row.getValue(0).getValue()).toList());
result.resetIterator();
System.out.println("after resetIterator: " + result.getNext().getValue(0).getValue());
```

```text
core.name STRING, referenced_by INT64: 3 rows
GA.Domain.Core       57 (java.lang.Long)
GA.Domain.Services   48 (java.lang.Long)
GA.Core              32 (java.lang.Long)
kept rows: [GA.Core, GA.Core, GA.Core]
after resetIterator: GA.Domain.Core
```

- `getColumnDataType(i).getID()` gives the Cypher type, `getNumTuples()` the number of rows before reading them.
- **Each `getNext()` returns a new `FlatTuple` object over the same engine buffer.** The three kept tuples all read `GA.Core`, the last row. The [documentation warns about it](https://docs.ladybugdb.com/client-apis/java/): copy the values before the next call. `ResultSet` has the same rule, but there you can't keep a row object by mistake.
- `resetIterator()` goes back to the first row: unlike `Rows()` in C#, the result can be read twice.

## Parameters

[Lines 71-105](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L71-L105). The loop over four projects gives the counts of lesson 5 (`GaApi depends on 20 projects`…); then the types and the traps:

```java
try (var statement = connection.prepare(
        "MATCH (p:Project) WHERE COUNT { MATCH (p)-[:REFERENCES]->(:Project) } > $n RETURN count(*)")) {
    for (Object value : List.of(2, "2", new BigDecimal("2.5"), 2.5)) {
        try (var result = connection.execute(statement, Map.of("n", value))) {
            System.out.println(value.getClass().getSimpleName() + " " + value + ": " + result.getNext().getValue(0).getValue() + " projects");
        }
    }
    // A misspelt name is ignored, and the statement keeps the value of its previous execution
    try (var result = connection.execute(statement, Map.of("nom", 5))) {
        System.out.println("{nom=5} after {n=2.5}: " + result.getNext().getValue(0).getValue() + " projects");
    }
    var withNull = new HashMap<String, Object>();
    withNull.put("n", null);
    attempt(() -> connection.execute(statement, withNull));
}
```

```text
Integer 2: 42 projects
String 2: 42 projects
BigDecimal 2.5: 42 projects
Double 2.5: 42 projects
{nom=5} after {n=2.5}: 42 projects
IllegalArgumentException: Parameter 'n' is null; use Value.createNull() to bind SQL NULL.
{nom=5}, new statement: Parameter n not found.
prepare COPY FROM $file: false, Binder exception: Cannot find parameter file. This should not happen.
IllegalArgumentException: Parameter 't' has unsupported type java.time.LocalDateTime. Accepted types: Value, Boolean, Byte, Short, Integer, Long, BigInteger, Float, Double, BigDecimal, String, InternalID, UUID, LocalDate, Instant, Duration
```

- `execute` takes a `Map<String, ?>`, converted by `Connection.coerceParam` ([`Connection.java`, lines 156-192](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/main/java/com/lbugdb/Connection.java#L156-L192)). `BigDecimal` is accepted, unlike `decimal` in C#; `LocalDateTime` and `null` aren't, and those two throw.
- **A prepared statement remembers its parameters.** `{nom=5}` binds a parameter that the statement doesn't have, without an error, and `$n` keeps 2.5 from the previous execution: 42 projects, not the 0 that `n = 5` would give. The same map on a new statement fails with `Parameter n not found.` JDBC's `PreparedStatement` keeps its parameters too, until `clearParameters()`, but it rejects an index that doesn't exist. [Exercise 2](#exercises) closes the trap.
- A parameter can't be a file name here either, and `prepare` doesn't throw: `isSuccess()` on the statement.

## Nodes, relationships and paths

The Java package has no `Node` or `Rel` class: a node is a `Value`, read with the static methods of `ValueNodeUtil`, `ValueRelUtil` and `ValueRecursiveRelUtil` ([lines 107-134](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L107-L134)):

```java
Value app = row.getValue(0);
appId = ValueNodeUtil.getID(app);
if (paths.isEmpty()) {
    System.out.println(ValueNodeUtil.getLabelName(app) + " (" + appId.getClass().getSimpleName() + "): " + properties(app));
}
Value path = row.getValue(1);
var nodes = new LbugList(ValueRecursiveRelUtil.getNodeList(path)).toArray();
var rels = new LbugList(ValueRecursiveRelUtil.getRelList(path)).toArray();
paths.add(rels.length + " relationships: " + String.join(" -> ",
        Arrays.stream(nodes).map(node -> (String) properties(node).get("name")).toList()));
if (firstSource == null) {
    firstSource = ValueRelUtil.getSrcID(rels[0]);
    System.out.println("first relationship: " + ValueRelUtil.getLabelName(rels[0]) + ", starts at GaApi: " + firstSource.equals(appId));
}
```

```text
Project (InternalID): {path=Apps/ga-server/GaApi/GaApi.csproj, name=GaApi, language=C#, sdk=Microsoft.NET.Sdk.Web, frameworks=net10.0, in_solution=true}
first relationship: REFERENCES, starts at GaApi: true
3 relationships: GaApi -> GA.Business.AI -> GA.Data.MongoDB -> GA.Business.Assets
3 relationships: GaApi -> GA.Business.ML -> GA.Data.MongoDB -> GA.Business.Assets
```

`properties` ([lines 318-324](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L318-L324)) builds a map from `getPropertySize`, `getPropertyNameAt` and `getPropertyValueAt`. `InternalID` has `equals`, so the relationship can be matched with its node. The query is lesson 5's, with `ALL SHORTEST` and a sort, for the same reasons: while writing this lesson, `GaApi` was at offset 47 in Java on Windows, where the C# program had found it at 11 on the same machine, and `SHORTEST` chose `GA.Business.ML`.

## Lists, structs and maps

`Value.getValue()` handles numbers, strings, dates, `DECIMAL`, `UUID` and `BLOB`, but not the nested types ([lines 136-157](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L136-L157)):

```java
var versions = Arrays.stream(new LbugList(row.getValue(1)).toArray()).map(v -> (String) v.getValue()).sorted().toList();
var usage = new LbugStruct(row.getValue(2));
System.out.println(row.getValue(0).getValue() + ": " + String.join(", ", versions)
        + " (" + usage.getValueByFieldName("projects").getValue() + " projects)");
```

```text
Microsoft.Extensions.Hosting: 10.0.0, 10.0.5, 9.0.0, 9.0.10, 9.0.4 (12 projects)
MongoDB.Driver: 2.29.0, 2.30.0, 3.2.0, 3.2.1, 3.5.0 (14 projects)
Microsoft.Extensions.DependencyInjection: 10.0.0, 10.0.2, 9.0.0, 9.0.10 (12 projects)
RuntimeException: Type of value is not supported in value_get_value
RuntimeException: Type of value is not supported in value_get_value
LbugMap: projects = 12
DISTINCT first: MongoDB.Driver, 5 versions, 0 projects
```

`getValue()` on the `LIST` and on the `MAP` throws ([`lbug_java.cpp`, line 2071](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L2071)); `LbugList`, `LbugStruct` and `LbugMap` read them, one `Value` at a time. The program's `toJava` ([lines 291-316](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L291-L316)) does it recursively, with a `switch` on `getDataType().getID()`, and returns `List`, `LinkedHashMap` and the values of `getValue()`: what the C# package does for you.

The last line is the aggregate bug of lesson 5, in the 0.20.4 engine: 0 projects.

## Rows as records

With `toJava`, a helper copies the rows into lists, and a `Function` maps them ([lines 169-174](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L169-L174)):

```java
record Project(String name, String path, String language) {}
```

```java
query("MATCH (p:Project) WHERE NOT p.in_solution RETURN p.name, p.path, p.language ORDER BY p.path LIMIT 3",
        row -> new Project((String) row.get(0), (String) row.get(1), (String) row.get(2)))
        .forEach(System.out::println);
```

```text
Project[name=FloorManager, path=Apps/FloorManager/FloorManager.csproj, language=C#]
Project[name=GaChatbot, path=Apps/GaChatbot/GaChatbot.csproj, language=C#]
Project[name=InteractiveTutorial, path=Apps/InteractiveTutorial/InteractiveTutorial.csproj, language=C#]
38 projects are not in AllProjects.slnx
```

`query` reads everything before returning ([`rows`, lines 330-347](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L330-L347)): a lazy `Stream` over the result would have to keep it open, and couldn't keep the tuples.

## Dates and times

[Lines 176-191](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L176-L191) send 9:30 in New York as an [`Instant`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Instant.html) and 90 minutes as a [`Duration`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Duration.html):

```text
instant   TIMESTAMP    Instant 2026-09-14T13:30:00Z
literal   TIMESTAMP    Instant 2026-09-14T09:30:00Z
tz        TIMESTAMP_TZ Instant 2026-09-14T13:30:00Z
day       DATE         LocalDate 2026-09-14
duration  INTERVAL     Duration PT1H30M
month     INTERVAL     Duration PT768H
```

- Java has no `DateTime` with an unknown kind: an `Instant` is a point in time, stored as a `TIMESTAMP` in UTC, and `TIMESTAMP` and `TIMESTAMP_TZ` both come back as `Instant`. `LocalDate` maps to `DATE`.
- `timestamp('…-04:00')` returns 9:30, the bug of lesson 5, in 0.20.4; `CAST(… AS TIMESTAMP_TZ)` returns 13:30.
- **`interval('1 month 2 days')` comes back as 768 hours**, 32 days: the binding converts the interval to seconds, counting a month as 30 days, and builds a `Duration` ([`lbug_java.cpp`, lines 2035-2043](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L2035-L2043)). A `Duration` has no months; [`Period`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Period.html) has, but no hours. A `Duration` sent as a parameter keeps milliseconds only.

## Errors, several statements, timeouts

[Lines 193-216](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L193-L216):

```text
Binder exception: Table Projet does not exist.
RuntimeException: Binder exception: Table Projet does not exist.
Binder exception: Cannot find property nam for p.
RuntimeException: Binder exception: Cannot find property nam for p.
Runtime exception: Found duplicated primary key value Common/GA.Core/GA.Core.csproj, which violates the uniqueness constraint of the primary key column.
RuntimeException: Runtime exception: Found duplicated primary key value Common/GA.Core/GA.Core.csproj, which violates the uniqueness constraint of the primary key column.
projects = 111
packages = 136
timeout of 1 ms: Interrupted.
no timeout: 7793 walks
```

- The messages are the engine's, as in C#. Calling `getNext()` on a failed result throws a plain `RuntimeException` with the same message: the package has no exception class of its own. The documentation still mentions an `ObjectRefDestroyedException` that 0.20.4 doesn't have.
- **Several statements give several results**: `hasNextQueryResult()` and `getNextQueryResult()` read the second count, which the C# package loses.
- `connection.setQueryTimeout(1)` stops the unbounded walks of lesson 3 after a millisecond, and the result fails with `Interrupted.`; `setQueryTimeout(0)` removes the limit. `connection.interrupt()` does the same from another thread. The C# package has neither.

## Sharing a file, and a native library in the temporary directory

[`check.sh`](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/check.sh) creates a database file from Java, opens it read-write with the CLI, then from Java again:

```text
Table Project has been created.
created out/java/ga.lbdb with LadybugDB 0.20.4
-- the CLI, read-write
p.name
GA.Core
opened out/java/ga.lbdb: GA.Core
```

Same engine, same storage version: nothing to convert, unlike the C# package and the CLI in lesson 5.

`check.sh` then runs the `temp` mode, which counts the files named `liblbug_java_native…` in the temporary directory ([lines 419-428](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L419-L428)). The CI prints, after three runs of the program:

| Runner | Copies left |
|---|---|
| Windows | 3 copies, 43 MB |
| Linux | 0 |
| macOS | 0 |

When the `Native` class loads, it copies the native library of the jar to a new temporary file, loads it, and asks for the file to be deleted when the JVM exits ([`Native.java`, lines 53-59](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/main/java/com/lbugdb/Native.java#L53-L59)). On Linux and macOS, deleting a loaded library works. On Windows, a loaded DLL can't be deleted, [`deleteOnExit`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/File.html#deleteOnExit%28%29) fails without a word, and each start of the JVM leaves 14.6 MB in `%TEMP%`: 13 copies, 190 MB, on my machine after the runs of this lesson. A Windows service that restarts every day leaves 5 GB a year. The file name is random, so the copies can't be reused; delete `%TEMP%\liblbug_java_native*.so` when no Java process uses LadybugDB.

## Threads and connections

`timings` mode, from the CI run of this lesson and from my machine, in milliseconds ([lines 247-271](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L247-L271)):

| | one query | 4 queries, 1 connection, 4 threads | 4 queries, 4 connections, 4 threads |
|---|---|---|---|
| my machine (Windows, 24 threads) | 7 | 45 | 23 |
| Linux runner | 10 | 42 | 22 |
| macOS runner | 16 | 35 | 37 |
| Windows runner | 14 | 91 | 55 |

The Java `Connection` has no lock of its own, and four threads on one connection still take about four times one query: the engine locks each connection for the duration of a query ([`client_context.cpp`, lines 405-407](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/main/client_context.cpp#L405-L407)), so the lock of the C# package adds nothing to it. One connection per thread is faster, as in C#, except on the macOS runner, where both took about as long. `getQuerySummary()` separates compiling, about 0.5 ms, from executing.

## Key takeaways

- `com.ladybugdb:lbug` follows the engine's releases: 0.20.4, like the CLI. One 29 MB jar holds the native library for four platforms, not macOS on Intel.
- A failed query returns a result with `isSuccess() == false`; nothing throws until you read it. Check every result.
- `getNext()` reuses the engine's buffer: copy the values before the next call. `resetIterator()` reads the result again.
- A prepared statement keeps the parameters of its previous execution, and ignores unknown names.
- `getValue()` doesn't read lists, structs or maps: `LbugList`, `LbugStruct`, `LbugMap`, or a recursive converter.
- `Instant` and `LocalDate` for dates; an `INTERVAL` becomes a `Duration` with 30-day months.
- `getNextQueryResult()`, `setQueryTimeout()` and `interrupt()` exist in Java, not in the C# package.
- On Windows, each JVM start leaves a 14.6 MB copy of the native library in the temporary directory.

## Exercises

The solutions are in [`ProjectGraph.java`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java), and their output in `expected.txt`: CI checks them with the rest.

1. Write `List<List<Object>> rows(String cypher)`, which returns the rows of a query as Java objects that stay valid after the result is closed, and throws when the query fails.

<details>
<summary>Solution</summary>

[Lines 330-347](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L330-L347):

```java
// Exercise 1: copy every row while its tuple is current
static List<List<Object>> rows(String cypher) {
    try (var result = connection.query(cypher)) {
        if (!result.isSuccess()) {
            throw new IllegalStateException(result.getErrorMessage());
        }
        var rows = new ArrayList<List<Object>>();
        while (result.hasNext()) {
            var tuple = result.getNext();
            var row = new ArrayList<Object>();
            for (long i = 0; i < result.getNumColumns(); i++) {
                row.add(toJava(tuple.getValue(i)));
            }
            rows.add(row);
        }
        return rows;
    }
}
```

```text
[[AllProjects.AppHost, C#], [AllProjects.ServiceDefaults, C#], [FloorManager, C#]]
```

Three rules at once: check `isSuccess()`, read each tuple before the next `getNext()`, and convert every value, lists and structs included, with `toJava`, before `close()` frees the result. `String`, `Long` and the other objects of `getValue()` are Java objects, independent of the result.

</details>

2. Write a `Statement` class around `PreparedStatement` that finds the parameter names in the Cypher text and refuses an execution whose map doesn't have exactly those names.

<details>
<summary>Solution</summary>

[Lines 349-388](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L349-L388), shortened:

```java
static final class Statement implements AutoCloseable {
    private static final Pattern PARAMETER = Pattern.compile("\\$(\\w+)");
    final Set<String> names = new TreeSet<>();
    private final PreparedStatement prepared;

    Statement(String cypher) {
        PARAMETER.matcher(cypher).results().forEach(match -> names.add(match.group(1)));
        prepared = connection.prepare(cypher);
        if (!prepared.isSuccess()) {
            throw new IllegalStateException(prepared.getErrorMessage());
        }
    }

    List<List<Object>> execute(Map<String, ?> parameters) {
        if (!parameters.keySet().equals(names)) {
            throw new IllegalArgumentException("expected parameters " + names + ", got " + new TreeSet<>(parameters.keySet()));
        }
        // … execute, check isSuccess(), copy the rows as in exercise 1
    }
}
```

```text
parameters: [name]
GA.Core: 85 dependents
IllegalArgumentException: expected parameters [name], got [nom]
IllegalArgumentException: expected parameters [name], got []
```

`Set.equals` compares the names whatever the order and the kind of set. The regular expression also matches a `$` inside a string literal, such as `'US$'`: good enough for the statements of this program, not for any Cypher. 85 of the 111 projects depend on `GA.Core`, directly or not.

</details>

3. Exercise 2 of lesson 5 looked for major version conflicts in two packages. Count, for every package, the projects in such a conflict, leaving out the 14 packages that ga's `Directory.Build.props` sets to one version. Pass that list as a parameter.

<details>
<summary>Solution</summary>

[Lines 230-245](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L230-L245):

```java
try (var statement = new Statement("""
        MATCH (a:Project)-[ua:USES]->(k:Package), (a)-[:REFERENCES*1..10]->(b:Project)-[ub:USES]->(k)
        WHERE split_part(ua.version, '.', 1) <> split_part(ub.version, '.', 1) AND NOT list_contains($aligned, k.name)
        WITH DISTINCT k.name AS package, a.path AS project
        RETURN package, count(*) AS projects
        ORDER BY projects DESC, package
        """);
     var list = new LbugList(aligned.stream().map(Value::new).toArray(Value[]::new))) {
    statement.execute(Map.of("aligned", list.getValue())).forEach(row -> System.out.println(row.get(0) + ": " + row.get(1) + " projects"));
}
```

```text
Microsoft.Extensions.DependencyInjection: 5 projects
Microsoft.Extensions.Configuration: 4 projects
MongoDB.Driver: 4 projects
Microsoft.Extensions.Logging.Abstractions: 3 projects
Microsoft.Extensions.AI: 1 projects
Microsoft.ML.Tokenizers: 1 projects
NUnit3TestAdapter: 1 projects
```

A `List<String>` isn't among the accepted parameter types, but a `Value` is: `new LbugList(Value[])` builds a Cypher list, and `getValue()` returns it as a `Value`. `WITH DISTINCT k.name, a.path` counts each project once per package, however many dependencies it has in conflict, and avoids a `DISTINCT` aggregate before another one, the bug of section 6. Most conflicts mix `Microsoft.Extensions.*` 9 and 10; `Microsoft.Extensions.AI` is the `9.4.0-preview` of `GaChatbot` against 10.5.1. Whether these conflicts break the build or the run of ga is *to verify*.

</details>

## Sources

- [`com.ladybugdb:lbug` on Maven Central](https://central.sonatype.com/artifact/com.ladybugdb/lbug), and the [`ladybug-java` repository](https://github.com/LadybugDB/ladybug-java) at commit [`f2fb39f`](https://github.com/LadybugDB/ladybug-java/tree/f2fb39f)
- [Java API](https://docs.ladybugdb.com/client-apis/java/) in the LadybugDB documentation
- [Concurrency](https://docs.ladybugdb.com/concurrency/) and [data types](https://docs.ladybugdb.com/cypher/data-types/)
- [`java.time.Instant`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Instant.html), [`Duration`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Duration.html) and [`Period`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Period.html)
- [`File.deleteOnExit`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/File.html#deleteOnExit%28%29), [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html), and the [JDBC tutorial](https://docs.oracle.com/javase/tutorial/jdbc/basics/index.html)
