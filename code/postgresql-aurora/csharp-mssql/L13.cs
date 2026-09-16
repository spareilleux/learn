using System.Data;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Data.SqlClient;
using Npgsql;
using NpgsqlTypes;

namespace Learn.Pg;

// Lesson 13: a migration by program. Reads the tables of mssql/13-source.sql from SQL Server with SqlClient, writes them
// to PostgreSQL with binary COPY, then checks that both sides hold the same rows.
static class L13
{
    static string SqlServer =>
        Environment.GetEnvironmentVariable("MSSQL_CONNECTION")
        ?? "Server=localhost,1433;Database=ci;User ID=sa;Password=Learn-2026!;TrustServerCertificate=True";

    // One table to copy: the SELECT on SQL Server, the COPY on PostgreSQL, and how each column is written
    record Table(string Name, string Select, string Copy, Action<SqlDataReader, NpgsqlBinaryImporter> Write);

    // datetime and datetime2 come back with DateTimeKind.Unspecified; Npgsql writes only UTC DateTimes to timestamptz
    static DateTime Utc(SqlDataReader r, int i) => DateTime.SpecifyKind(r.GetDateTime(i), DateTimeKind.Utc);

    static readonly Table[] Tables =
    [
        new("runs",
            "SELECT RunId, WorkflowName, Event, Conclusion, HeadBranch, HeadSha, Attempt, CreatedAt, StartedAt, UpdatedAt FROM dbo.Runs",
            "COPY migrated.runs (run_id, workflow_name, event, conclusion, head_branch, head_sha, attempt, created_at, started_at, updated_at) FROM STDIN (FORMAT BINARY)",
            (r, w) =>
            {
                w.Write(r.GetInt64(0), NpgsqlDbType.Bigint);
                w.Write(r.GetString(1), NpgsqlDbType.Varchar);
                w.Write(r.GetString(2), NpgsqlDbType.Varchar);
                WriteNullable(w, r.IsDBNull(3) ? null : r.GetString(3), NpgsqlDbType.Varchar);
                w.Write(r.GetString(4), NpgsqlDbType.Varchar);
                w.Write(r.GetString(5), NpgsqlDbType.Char);
                w.Write((short)r.GetByte(6), NpgsqlDbType.Smallint);
                w.Write(Utc(r, 7), NpgsqlDbType.TimestampTz);
                w.Write(Utc(r, 8), NpgsqlDbType.TimestampTz);
                w.Write(r.GetDateTimeOffset(9).UtcDateTime, NpgsqlDbType.TimestampTz);
            }),
        new("jobs",
            "SELECT JobId, RunId, Name, Conclusion, RunnerName, StartedAt, CompletedAt FROM dbo.Jobs",
            "COPY migrated.jobs (job_id, run_id, name, conclusion, runner_name, started_at, completed_at) FROM STDIN (FORMAT BINARY)",
            (r, w) =>
            {
                w.Write(r.GetInt64(0), NpgsqlDbType.Bigint);
                w.Write(r.GetInt64(1), NpgsqlDbType.Bigint);
                w.Write(r.GetString(2), NpgsqlDbType.Varchar);
                WriteNullable(w, r.IsDBNull(3) ? null : r.GetString(3), NpgsqlDbType.Varchar);
                WriteNullable(w, r.IsDBNull(4) ? null : r.GetString(4), NpgsqlDbType.Varchar);
                w.Write(Utc(r, 5), NpgsqlDbType.TimestampTz);
                w.Write(Utc(r, 6), NpgsqlDbType.TimestampTz);
            }),
        new("job_labels",
            "SELECT JobId, Label FROM dbo.JobLabels",
            "COPY migrated.job_labels (job_id, label) FROM STDIN (FORMAT BINARY)",
            (r, w) =>
            {
                w.Write(r.GetInt64(0), NpgsqlDbType.Bigint);
                w.Write(r.GetString(1), NpgsqlDbType.Varchar);
            }),
        new("steps",
            "SELECT JobId, Number, Name, Conclusion, StartedAt, CompletedAt FROM dbo.Steps",
            "COPY migrated.steps (job_id, number, name, conclusion, started_at, completed_at) FROM STDIN (FORMAT BINARY)",
            (r, w) =>
            {
                w.Write(r.GetInt64(0), NpgsqlDbType.Bigint);
                w.Write(r.GetInt16(1), NpgsqlDbType.Smallint);
                w.Write(r.GetString(2), NpgsqlDbType.Varchar);
                WriteNullable(w, r.IsDBNull(3) ? null : r.GetString(3), NpgsqlDbType.Varchar);
                w.Write(Utc(r, 4), NpgsqlDbType.TimestampTz);
                w.Write(Utc(r, 5), NpgsqlDbType.TimestampTz);
            }),
        new("notes",
            "SELECT NoteId, NoteGuid, RunId, Author, Tag, Body, Cost, WrittenAt, WrittenLocal FROM dbo.Notes",
            "COPY migrated.notes (note_id, note_guid, run_id, author, tag, body, cost, written_at, written_local) FROM STDIN (FORMAT BINARY)",
            (r, w) =>
            {
                w.Write(r.GetInt32(0), NpgsqlDbType.Integer);
                w.Write(r.GetGuid(1), NpgsqlDbType.Uuid);
                WriteNullable(w, r.IsDBNull(2) ? null : r.GetInt64(2), NpgsqlDbType.Bigint);
                w.Write(r.GetString(3), NpgsqlDbType.Varchar);
                WriteNullable(w, r.IsDBNull(4) ? null : r.GetString(4), NpgsqlDbType.Varchar);
                w.Write(r.GetString(5), NpgsqlDbType.Text);
                WriteNullable(w, r.IsDBNull(6) ? null : r.GetDecimal(6), NpgsqlDbType.Numeric);
                // timestamp: no time zone on either side, the DateTime is written as it is
                w.Write(r.GetDateTime(7), NpgsqlDbType.Timestamp);
                w.Write(r.GetDateTimeOffset(8).UtcDateTime, NpgsqlDbType.TimestampTz);
            }),
    ];

    static void WriteNullable(NpgsqlBinaryImporter w, object? value, NpgsqlDbType type)
    {
        if (value is null)
        {
            w.WriteNull();
        }
        else
        {
            w.Write(value, type);
        }
    }

    public static async Task Migrate()
    {
        await using var source = new SqlConnection(SqlServer);
        await source.OpenAsync();
        await using var target = Db.DataSource();

        await Execute(target, await File.ReadAllTextAsync("sql/mssql-target.sql"));
        foreach (var table in Tables)
        {
            await using var connection = await target.OpenConnectionAsync();
            await using var importer = await connection.BeginBinaryImportAsync(table.Copy);
            await using var command = new SqlCommand(table.Select, source);
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                await importer.StartRowAsync();
                table.Write(reader, importer);
            }
            Console.WriteLine($"{table.Name}: {await importer.CompleteAsync()} rows copied");
        }
        await Execute(target, await File.ReadAllTextAsync("sql/mssql-target-after.sql"));

        // The identity column continues after SQL Server's last value, not after the largest key copied
        await using (var command = new SqlCommand("SELECT IDENT_CURRENT('dbo.Notes')", source))
        {
            var last = Convert.ToInt64(await command.ExecuteScalarAsync());
            await Execute(target, $"ALTER TABLE migrated.notes ALTER COLUMN note_id RESTART WITH {last + 1}");
            Console.WriteLine($"notes.note_id restarts with {last + 1}");
        }
    }

    static async Task Execute(NpgsqlDataSource target, string sql)
    {
        await using var command = target.CreateCommand(sql);
        await command.ExecuteNonQueryAsync();
    }

    // Validation: the same rows on both sides, each read as text in a form both servers agree on, in key order
    record Check(string Name, string SqlServer, string PostgreSql);

    static readonly Check[] Checks =
    [
        new("runs",
            "SELECT RunId, WorkflowName, Event, Conclusion, HeadBranch, HeadSha, Attempt, CreatedAt, StartedAt, UpdatedAt FROM dbo.Runs ORDER BY RunId",
            "SELECT run_id, workflow_name, event, conclusion, head_branch, head_sha, attempt, created_at, started_at, updated_at FROM migrated.runs ORDER BY run_id"),
        new("jobs",
            "SELECT JobId, RunId, Name, Conclusion, RunnerName, StartedAt, CompletedAt FROM dbo.Jobs ORDER BY JobId",
            "SELECT job_id, run_id, name, conclusion, runner_name, started_at, completed_at FROM migrated.jobs ORDER BY job_id"),
        new("job_labels",
            "SELECT JobId, Label FROM dbo.JobLabels ORDER BY JobId, Label",
            "SELECT job_id, label FROM migrated.job_labels ORDER BY job_id, label"),
        new("steps",
            "SELECT JobId, Number, Name, Conclusion, StartedAt, CompletedAt FROM dbo.Steps ORDER BY JobId, Number",
            "SELECT job_id, number, name, conclusion, started_at, completed_at FROM migrated.steps ORDER BY job_id, number"),
        new("notes",
            "SELECT NoteId, NoteGuid, RunId, Author, Tag, Body, Cost, WrittenAt, WrittenLocal FROM dbo.Notes ORDER BY NoteId",
            "SELECT note_id, note_guid, run_id, author, tag, body, cost, written_at, written_local FROM migrated.notes ORDER BY note_id"),
    ];

    // A value as text: instants in UTC with seven decimals, the precision of datetime2 and datetimeoffset
    static string Text(object value) => value switch
    {
        DBNull => "NULL",
        DateTimeOffset o => o.UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff", CultureInfo.InvariantCulture),
        DateTime d => d.ToString("yyyy-MM-dd HH:mm:ss.fffffff", CultureInfo.InvariantCulture),
        decimal m => m.ToString("0.0000", CultureInfo.InvariantCulture),
        IFormattable f => f.ToString(null, CultureInfo.InvariantCulture),
        _ => value.ToString()!,
    };

    static async Task<List<string>> Rows(IDataReader reader, Func<Task<bool>> read)
    {
        var rows = new List<string>();
        while (await read())
        {
            var values = new object[reader.FieldCount];
            reader.GetValues(values);
            rows.Add(string.Join('|', values.Select(Text)));
        }
        return rows;
    }

    public static async Task Validate()
    {
        await using var source = new SqlConnection(SqlServer);
        await source.OpenAsync();
        await using var target = Db.DataSource();
        foreach (var check in Checks)
        {
            await using var sqlCommand = new SqlCommand(check.SqlServer, source);
            await using var sqlReader = await sqlCommand.ExecuteReaderAsync();
            var expected = await Rows(sqlReader, () => sqlReader.ReadAsync());
            await using var pgCommand = target.CreateCommand(check.PostgreSql);
            await using var pgReader = await pgCommand.ExecuteReaderAsync();
            var actual = await Rows(pgReader, () => pgReader.ReadAsync());

            var hash = (List<string> rows) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(string.Join('\n', rows))))[..12];
            var differences = expected.Zip(actual).Where(pair => pair.First != pair.Second).ToList();
            Console.WriteLine($"{check.Name}: {expected.Count} and {actual.Count} rows, SHA-256 {hash(expected)} and {hash(actual)}, {differences.Count} rows differ");
            foreach (var (sql, pg) in differences)
            {
                Console.WriteLine($"  SQL Server: {sql}");
                Console.WriteLine($"  PostgreSQL: {pg}");
            }
        }
    }
}
