// LadybugDB course, lesson 5: the project graph of GuitarAlchemist/ga from C#, with the LadybugDB NuGet package.
// Run from code/ladybugdb: dotnet run --project csharp/ProjectGraph -- check | timings | create <file> | open <file>
using System.Diagnostics;
using LadybugDB;

var mode = args.FirstOrDefault() ?? "check";
if (mode == "create") { CreateFile(args[1]); return; }
if (mode == "open") { OpenFile(args[1]); return; }

Section("1. Open a database");
Console.WriteLine($"LadybugDB {LadybugVersion.Version}, storage version {LadybugVersion.StorageVersion}");
// An empty path: an in-memory database, like the CLI started without a file name
using var database = new Database("");
using var connection = new Connection(database);

Section("2. Create and load");
Execute("CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING, language STRING, sdk STRING, frameworks STRING, in_solution BOOLEAN)");
Execute("CREATE NODE TABLE Package(name STRING PRIMARY KEY)");
Execute("CREATE REL TABLE REFERENCES(FROM Project TO Project)");
Execute("CREATE REL TABLE USES(FROM Project TO Package, version STRING)");
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
Execute("COPY Package FROM (LOAD FROM 'data/ga/package_refs.csv' (HEADER = true) RETURN DISTINCT package)");
Execute("COPY USES FROM 'data/ga/package_refs.csv' (HEADER = true)");

Section("3. Read rows");
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

Section("4. Parameters");
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
foreach (var (label, value) in new (string, object?)[] { ("int 2", 2), ("string \"2\"", "2"), ("decimal 2m", 2m) })
{
    try
    {
        using var result = connection.Execute(
            "MATCH (p:Project) WHERE COUNT { MATCH (p)-[:REFERENCES]->(:Project) } > $n RETURN count(*)",
            new Dictionary<string, object?> { ["n"] = value });
        Console.WriteLine($"{label}: {result.Rows().Single()[0]} projects reference more than 2 projects");
    }
    catch (Exception e)
    {
        Console.WriteLine($"{label}: {e.GetType().Name}: {e.Message}");
    }
}
Try(() => connection.Execute("MATCH (p:Project {name: $name}) RETURN p.path", new Dictionary<string, object?> { ["nom"] = "GaApi" }).Dispose());
Try(() => connection.Execute("COPY Package FROM $file (HEADER = true)", new Dictionary<string, object?> { ["file"] = "data/ga/package_refs.csv" }).Dispose());

Section("5. Nodes, relationships and paths");
using (var result = connection.Query("""
    MATCH path = (app:Project {name: 'GaApi'})-[:REFERENCES* SHORTEST 1..10]->(assets:Project {name: 'GA.Business.Assets'})
    RETURN app, path
    """))
{
    var row = result.Rows().Single();
    var app = (Node)row[0]!;
    Console.WriteLine($"{app.Label} {app.Id}: {string.Join(", ", app.Properties.Select(p => $"{p.Key}={p.Value}"))}");
    var path = (RecursiveRel)row[1]!;
    Console.WriteLine($"{path.Rels.Count} relationships: {string.Join(" -> ", path.Nodes.Select(n => n.Properties["name"]))}");
    Console.WriteLine($"first relationship: {path.Rels[0].Label} {path.Rels[0].Source} -> {path.Rels[0].Destination}");
}

Section("6. Lists and structs");
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
// The bug of lesson 4, in 0.19.1 too: an aggregate after a DISTINCT one in the same projection is wrong
using (var result = connection.Query("""
    MATCH (p:Project)-[u:USES]->(k:Package {name: 'MongoDB.Driver'})
    RETURN k.name, collect(DISTINCT u.version) AS versions, count(*) AS projects
    """))
{
    var row = result.Rows().Single();
    Console.WriteLine($"DISTINCT first: {row[0]}, {((object?[])row[1]!).Length} versions, {row[2]} projects");
}
using (var result = connection.Query("MATCH (k:Package) WITH collect(k.name) AS names RETURN names, size(names)"))
{
    var row = result.Rows().Single();
    Console.WriteLine($"{row[0]!.GetType()} of {row[1]} names");
}

Section("7. Rows as records");
foreach (var project in Query(
    "MATCH (p:Project) WHERE NOT p.in_solution RETURN p.name, p.path, p.language ORDER BY p.path LIMIT 3",
    row => new Project((string)row[0]!, (string)row[1]!, (string)row[2]!)))
{
    Console.WriteLine(project);
}
Console.WriteLine($"{Query("MATCH (p:Project) WHERE NOT p.in_solution RETURN count(*)", row => (long)row[0]!).Single()} projects are not in AllProjects.slnx");

Section("8. Dates and times");
using (var result = connection.Execute(
    "RETURN $offset AS offset, $local AS local, timestamp('2026-09-14T09:30:00-04:00') AS literal",
    new Dictionary<string, object?>
    {
        ["offset"] = new DateTimeOffset(2026, 9, 14, 9, 30, 0, TimeSpan.FromHours(-4)),
        ["local"] = new DateTime(2026, 9, 14, 9, 30, 0),
    }))
{
    var row = result.Rows().Single();
    for (var i = 0; i < row.Length; i++)
    {
        var value = row[i] switch
        {
            DateTimeOffset o => $"DateTimeOffset {o:yyyy-MM-dd HH:mm:ss zzz}",
            DateTime d => $"DateTime {d:yyyy-MM-dd HH:mm:ss}, Kind = {d.Kind}",
            var other => other?.ToString(),
        };
        Console.WriteLine($"{result.ColumnNames[i],-8} {value}");
    }
}

Section("9. Errors");
Try(() => connection.Query("MATCH (p:Projet) RETURN p").Dispose());
Try(() => connection.Query("MATCH (p:Project) RETURN p.nam").Dispose());
Try(() => connection.Query("CREATE (:Project {path: 'Common/GA.Core/GA.Core.csproj', name: 'GA.Core'})").Dispose());
using (var result = connection.Query("MATCH (p:Project) RETURN count(*); MATCH (k:Package) RETURN count(*)"))
{
    Console.WriteLine($"two statements, one result: {string.Join(", ", result.ColumnNames)} = {result.Rows().Single()[0]}");
}
connection.Query("CREATE (:Package {name: 'Test.A'}); CREATE (:Package {name: 'Test.B'})").Dispose();
Console.WriteLine($"packages created by two statements: {string.Join(", ", Query("MATCH (k:Package) WHERE k.name STARTS WITH 'Test.' RETURN k.name ORDER BY k.name", row => row[0]))}");

if (mode == "timings")
{
    Section("Timings (not compared)");
    const string walks = "MATCH (a:Project)-[:REFERENCES*1..10]->(b:Project) RETURN count(*)";
    var watch = Stopwatch.StartNew();
    using (var result = connection.Query(walks))
    {
        Console.WriteLine($"{result.Rows().Single()[0]} walks, one query: {watch.ElapsedMilliseconds} ms");
    }
    watch.Restart();
    Parallel.For(0, 4, _ => { using var result = connection.Query(walks); result.Rows().Single(); });
    Console.WriteLine($"4 queries on one connection, 4 threads: {watch.ElapsedMilliseconds} ms");
    watch.Restart();
    Parallel.For(0, 4, _ => { using var own = new Connection(database); using var result = own.Query(walks); result.Rows().Single(); });
    Console.WriteLine($"4 queries on 4 connections, 4 threads: {watch.ElapsedMilliseconds} ms");
}

void Section(string title) => Console.WriteLine($"\n== {title}");

void Execute(string cypher)
{
    using var result = connection.Query(cypher);
    foreach (var row in result.Rows())
    {
        Console.WriteLine(row[0]);
    }
}

IEnumerable<T> Query<T>(string cypher, Func<object?[], T> map)
{
    using var result = connection.Query(cypher);
    foreach (var row in result.Rows())
    {
        yield return map(row);
    }
}

static void Try(Action action)
{
    try
    {
        action();
    }
    catch (Exception e)
    {
        Console.WriteLine($"{e.GetType().Name}: {e.Message}");
    }
}

static void CreateFile(string path)
{
    using var database = new Database(path);
    using var connection = new Connection(database);
    connection.Query("CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING)").Dispose();
    connection.Query("CREATE (:Project {path: 'Common/GA.Core/GA.Core.csproj', name: 'GA.Core'})").Dispose();
    Console.WriteLine($"created {path} with LadybugDB {LadybugVersion.Version}");
}

static void OpenFile(string path)
{
    try
    {
        using var database = new Database(path);
        using var connection = new Connection(database);
        using var result = connection.Query("MATCH (p:Project) RETURN p.name");
        Console.WriteLine($"opened {path}: {result.Rows().Single()[0]}");
    }
    catch (LadybugException e)
    {
        Console.WriteLine($"{e.GetType().Name}: {e.Message}");
    }
}

record Project(string Name, string Path, string Language);
