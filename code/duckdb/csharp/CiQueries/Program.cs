// DuckDB course, lesson 5: DuckDB from C# with DuckDB.NET (ADO.NET) and Dapper
// Run from code/duckdb: dotnet run --project csharp/CiQueries -- [check|timings]
using System.Diagnostics;
using System.Globalization;
using Dapper;
using DuckDB.NET.Data;

var mode = args.FirstOrDefault() ?? "check";

// An in-memory database, like the CLI started without a file name
using var connection = new DuckDBConnection("Data Source=:memory:");
connection.Open();
Console.WriteLine($"DuckDB {connection.ServerVersion}");

if (mode == "timings")
{
    Timings(connection);
    return;
}

Section("1. A query with a data reader");
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

Section("2. Parameters");
using (var command = connection.CreateCommand())
{
    command.CommandText = "SELECT count(*) FROM read_json($path) WHERE workflowName = $workflow AND conclusion = $conclusion";
    command.Parameters.Add(new DuckDBParameter("path", "data/runs.json"));
    command.Parameters.Add(new DuckDBParameter("workflow", "Rust course examples"));
    command.Parameters.Add(new DuckDBParameter("conclusion", "failure"));
    Console.WriteLine($"Rust course failures: {command.ExecuteScalar()}");
}

Section("3. DuckDB types as .NET types");
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

Section("4. Lists and structs");
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

Section("5. Errors");
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

Section("6. Dapper");
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

static void Section(string title) => Console.WriteLine($"{Environment.NewLine}== {title}");

static string Format(object? value) => value switch
{
    null => "NULL",
    DateTime d => d.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture),
    _ => Convert.ToString(value, CultureInfo.InvariantCulture) ?? "",
};

// Bulk loading: the appender against parameterized INSERT statements, timings only, not compared by CI
static void Timings(DuckDBConnection connection)
{
    using (var create = connection.CreateCommand())
    {
        create.CommandText = "CREATE TABLE numbers (i INTEGER, label VARCHAR)";
        create.ExecuteNonQuery();
    }

    const int appended = 1_000_000;
    var stopwatch = Stopwatch.StartNew();
    using (var appender = connection.CreateAppender("numbers"))
    {
        for (var i = 0; i < appended; i++)
        {
            appender.CreateRow().AppendValue(i).AppendValue($"n{i}").EndRow();
        }
    }
    Console.WriteLine($"appender: {appended:N0} rows in {stopwatch.ElapsedMilliseconds} ms");

    const int inserted = 10_000;
    stopwatch.Restart();
    using (var transaction = connection.BeginTransaction())
    using (var insert = connection.CreateCommand())
    {
        insert.CommandText = "INSERT INTO numbers VALUES ($i, $label)";
        var i = new DuckDBParameter("i", 0);
        var label = new DuckDBParameter("label", "");
        insert.Parameters.Add(i);
        insert.Parameters.Add(label);
        for (var n = 0; n < inserted; n++)
        {
            i.Value = n;
            label.Value = $"n{n}";
            insert.ExecuteNonQuery();
        }
        transaction.Commit();
    }
    Console.WriteLine($"INSERT: {inserted:N0} rows in {stopwatch.ElapsedMilliseconds} ms");
}

// Dapper maps columns to constructor parameters, ignoring case
record RunSummary(long DatabaseId, string WorkflowName, DateTime CreatedAt, TimeSpan Took);

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
