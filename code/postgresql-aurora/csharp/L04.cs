// Lesson 4: PostgreSQL from C# with Npgsql, on the course model (sql/schema.sql)
using System.Diagnostics;
using Npgsql;
using NpgsqlTypes;

namespace Learn.Pg;

static class L04
{
    public static async Task Connect()
    {
        // One NpgsqlDataSource per database for the whole application: it owns the connection pool
        await using var dataSource = Db.DataSource();
        await using var command = dataSource.CreateCommand(
            "SELECT current_user, current_setting('server_version'), (SELECT count(*) FROM ci.runs)");
        await using var reader = await command.ExecuteReaderAsync();
        await reader.ReadAsync();
        Console.WriteLine($"user: {reader.GetString(0)}");
        Console.WriteLine($"server: {reader.GetString(1)}");
        Console.WriteLine($"runs: {reader.GetInt64(2)}");
    }

    public static async Task Parameters()
    {
        await using var dataSource = Db.DataSource();

        // Positional parameters: $1, $2 are what PostgreSQL itself understands
        await using (var command = dataSource.CreateCommand("""
            SELECT run_id, started_at FROM ci.runs
            WHERE workflow_name = $1 AND started_at >= $2
            ORDER BY started_at, run_id
            LIMIT 2
            """))
        {
            command.Parameters.Add(new() { Value = "Rust course examples" });
            command.Parameters.Add(new() { Value = new DateTime(2026, 9, 13, 18, 0, 0, DateTimeKind.Utc) });
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var startedAt = reader.GetDateTime(1);
                Console.WriteLine($"{reader.GetInt64(0)} {startedAt:O} Kind={startedAt.Kind}");
            }
        }

        // Named parameters: Npgsql rewrites @os into $1 before sending the query
        await using (var command = dataSource.CreateCommand("""
            SELECT count(*) FROM ci.jobs WHERE labels[1] = @os AND duration > @longer_than
            """))
        {
            command.Parameters.AddWithValue("os", "windows-latest");
            command.Parameters.AddWithValue("longer_than", TimeSpan.FromMinutes(2));
            Console.WriteLine($"windows jobs over 2 minutes: {await command.ExecuteScalarAsync()}");
        }

        // An array parameter replaces a list of values: = ANY ($1), not IN (...)
        await using (var command = dataSource.CreateCommand("""
            SELECT labels[1], count(*) FROM ci.jobs WHERE labels[1] = ANY ($1) GROUP BY 1 ORDER BY 1
            """))
        {
            command.Parameters.Add(new() { Value = new[] { "macos-latest", "windows-latest" } });
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                Console.WriteLine($"{reader.GetString(0)}: {reader.GetInt64(1)}");
            }
        }

        // DateTime.Kind decides the parameter's type: Utc is sent as timestamptz, Unspecified and Local as timestamp,
        // which the server converts to timestamptz in the session's time zone
        foreach (var options in new[] { "Timezone=UTC", "Timezone=America/Toronto" })
        {
            await using var zoned = Db.DataSource(options);
            foreach (var kind in new[] { DateTimeKind.Utc, DateTimeKind.Unspecified })
            {
                await using var command = zoned.CreateCommand("SELECT count(*) FROM ci.runs WHERE started_at >= $1");
                command.Parameters.Add(new() { Value = new DateTime(2026, 9, 14, 0, 0, 0, kind) });
                Console.WriteLine($"{options}, Kind={kind}: {await command.ExecuteScalarAsync()} runs since 2026-09-14 00:00");
            }
        }
        await using (var command = dataSource.CreateCommand("SELECT count(*) FROM ci.runs WHERE started_at >= $1"))
        {
            var toronto = new DateTimeOffset(2026, 9, 14, 0, 0, 0, TimeSpan.FromHours(-4));
            command.Parameters.Add(new() { Value = toronto });
            try
            {
                await command.ExecuteScalarAsync();
            }
            catch (ArgumentException e)
            {
                Console.WriteLine($"{e.GetType().Name}: {e.Message}");
            }
            command.Parameters[0].Value = toronto.ToUniversalTime();
            Console.WriteLine($"DateTimeOffset in UTC: {await command.ExecuteScalarAsync()} runs since 2026-09-14 00:00 in Toronto");
        }

        // A value that doesn't match the column's type is PostgreSQL's error, not Npgsql's
        await using (var command = dataSource.CreateCommand("SELECT count(*) FROM ci.runs WHERE run_id = $1"))
        {
            command.Parameters.Add(new() { Value = "34852867099" });
            try
            {
                await command.ExecuteScalarAsync();
            }
            catch (PostgresException e)
            {
                Console.WriteLine($"{e.SqlState}: {e.MessageText}");
            }
        }
    }

    public static async Task Pool()
    {
        foreach (var pooling in new[] { true, false })
        {
            await using var dataSource = Db.DataSource($"Pooling={pooling}");
            var backends = new HashSet<int>();
            for (var i = 0; i < 20; i++)
            {
                await using var connection = await dataSource.OpenConnectionAsync();
                backends.Add(connection.ProcessID);
            }
            Console.WriteLine($"Pooling={pooling}: 20 opens, {backends.Count} server process(es)");
        }

        // Five connections held at the same time are five server processes
        await using (var dataSource = Db.DataSource("Application Name=learn-pool"))
        {
            var connections = new List<NpgsqlConnection>();
            for (var i = 0; i < 5; i++)
            {
                connections.Add(await dataSource.OpenConnectionAsync());
            }
            foreach (var connection in connections)
            {
                await connection.CloseAsync();
            }
            await using var command = dataSource.CreateCommand("""
                SELECT state, count(*) FROM pg_stat_activity
                WHERE application_name = 'learn-pool' GROUP BY state ORDER BY state
                """);
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                Console.WriteLine($"after closing: {reader.GetInt64(1)} {reader.GetString(0)}");
            }
        }
        await using (var dataSource = Db.DataSource())
        {
            await using var command = dataSource.CreateCommand(
                "SELECT count(*) FROM pg_stat_activity WHERE application_name = 'learn-pool'");
            Console.WriteLine($"after disposing the data source: {await command.ExecuteScalarAsync()}");
        }
    }

    public static async Task Prepare()
    {
        // Npgsql prepares a statement only when asked, or after Auto Prepare Min Usages executions (default 5)
        // when Max Auto Prepare is above 0
        await using var dataSource = Db.DataSource("Max Auto Prepare=10");
        await using var connection = await dataSource.OpenConnectionAsync();
        await using var count = new NpgsqlCommand(
            "SELECT count(*) FROM pg_prepared_statements WHERE statement ~ 'ci\\.jobs WHERE'", connection);
        for (var i = 1; i <= 6; i++)
        {
            await using var command = new NpgsqlCommand("SELECT count(*) FROM ci.jobs WHERE run_id = $1", connection);
            command.Parameters.Add(new() { Value = 34852867099L });
            await command.ExecuteScalarAsync();
            Console.WriteLine($"after {i} execution(s): {await count.ExecuteScalarAsync()} prepared statement(s)");
        }
    }

    static IEnumerable<string[]> PackageRefs() =>
        File.ReadLines("../ladybugdb/data/ga/package_refs.csv").Skip(1).Select(line => line.Split(','));

    public static async Task Copy()
    {
        await using var dataSource = Db.DataSource();
        await using var connection = await dataSource.OpenConnectionAsync();
        await using (var create = new NpgsqlCommand("""
            DROP TABLE IF EXISTS ga.package_refs_import;
            CREATE TABLE ga.package_refs_import (LIKE ga.package_refs INCLUDING ALL);
            """, connection))
        {
            await create.ExecuteNonQueryAsync();
        }

        // COPY ... FROM STDIN in binary format: the client sends the rows, typed, in one stream
        await using (var writer = await connection.BeginBinaryImportAsync(
            "COPY ga.package_refs_import (project, package, version) FROM STDIN (FORMAT binary)"))
        {
            foreach (var fields in PackageRefs())
            {
                await writer.StartRowAsync();
                await writer.WriteAsync(fields[0], NpgsqlDbType.Text);
                await writer.WriteAsync(fields[1], NpgsqlDbType.Text);
                await writer.WriteAsync(fields[2], NpgsqlDbType.Text);
            }
            Console.WriteLine($"copied: {await writer.CompleteAsync()} rows");
        }

        await using var compare = new NpgsqlCommand("""
            SELECT (SELECT count(*) FROM (TABLE ga.package_refs EXCEPT TABLE ga.package_refs_import) AS d),
                   (SELECT count(*) FROM (TABLE ga.package_refs_import EXCEPT TABLE ga.package_refs) AS d)
            """, connection);
        await using var reader = await compare.ExecuteReaderAsync();
        await reader.ReadAsync();
        Console.WriteLine($"rows only in the server-side load: {reader.GetInt64(0)}, only in the client copy: {reader.GetInt64(1)}");
    }

    public static async Task ExerciseBatch()
    {
        await using var dataSource = Db.DataSource();
        await using var connection = await dataSource.OpenConnectionAsync();
        await using (var create = new NpgsqlCommand("""
            DROP TABLE IF EXISTS ga.package_refs_batch;
            CREATE TABLE ga.package_refs_batch (LIKE ga.package_refs INCLUDING ALL);
            """, connection))
        {
            await create.ExecuteNonQueryAsync();
        }

        // One NpgsqlBatch: every INSERT goes to the server in one round trip, in one implicit transaction
        var rows = PackageRefs().ToList();
        rows.Add(rows[0]);
        await using var batch = new NpgsqlBatch(connection);
        foreach (var fields in rows)
        {
            var command = new NpgsqlBatchCommand("INSERT INTO ga.package_refs_batch VALUES ($1, $2, $3)");
            foreach (var field in fields)
            {
                command.Parameters.Add(new() { Value = field });
            }
            batch.BatchCommands.Add(command);
        }
        try
        {
            await batch.ExecuteNonQueryAsync();
        }
        catch (PostgresException e)
        {
            Console.WriteLine($"{e.SqlState}: {e.MessageText}");
            Console.WriteLine(e.Detail);
        }
        await using var count = new NpgsqlCommand("SELECT count(*) FROM ga.package_refs_batch", connection);
        Console.WriteLine($"rows in the table: {await count.ExecuteScalarAsync()}");
    }

    // Not compared by check.sh: the timings depend on the machine. Two rounds: the first one includes the JIT.
    public static async Task Timings()
    {
        var rows = PackageRefs().ToList();
        await using var dataSource = Db.DataSource();
        await using var connection = await dataSource.OpenConnectionAsync();

        async Task Reset()
        {
            await using var command = new NpgsqlCommand("TRUNCATE ga.package_refs_import", connection);
            await command.ExecuteNonQueryAsync();
        }

        for (var round = 1; round <= 2; round++)
        {
            await Reset();
            var watch = Stopwatch.StartNew();
            foreach (var fields in rows)
            {
                await using var command = new NpgsqlCommand("INSERT INTO ga.package_refs_import VALUES ($1, $2, $3)", connection);
                foreach (var field in fields)
                {
                    command.Parameters.Add(new() { Value = field });
                }
                await command.ExecuteNonQueryAsync();
            }
            Console.WriteLine($"round {round}: {rows.Count} INSERT commands: {watch.ElapsedMilliseconds} ms");

            await Reset();
            watch.Restart();
            await using (var batch = new NpgsqlBatch(connection))
            {
                foreach (var fields in rows)
                {
                    var command = new NpgsqlBatchCommand("INSERT INTO ga.package_refs_import VALUES ($1, $2, $3)");
                    foreach (var field in fields)
                    {
                        command.Parameters.Add(new() { Value = field });
                    }
                    batch.BatchCommands.Add(command);
                }
                await batch.ExecuteNonQueryAsync();
            }
            Console.WriteLine($"round {round}: one NpgsqlBatch of {rows.Count} INSERTs: {watch.ElapsedMilliseconds} ms");

            await Reset();
            watch.Restart();
            await using (var writer = await connection.BeginBinaryImportAsync(
                "COPY ga.package_refs_import (project, package, version) FROM STDIN (FORMAT binary)"))
            {
                foreach (var fields in rows)
                {
                    await writer.WriteRowAsync(default, fields[0], fields[1], fields[2]);
                }
                await writer.CompleteAsync();
            }
            Console.WriteLine($"round {round}: binary COPY of {rows.Count} rows: {watch.ElapsedMilliseconds} ms");
        }
    }

    public static async Task TooMany()
    {
        // No pool: each Open is a new server process, until max_connections (100 by default) is reached
        await using var dataSource = Db.DataSource("Pooling=false");
        var connections = new List<NpgsqlConnection>();
        try
        {
            for (var i = 0; i < 200; i++)
            {
                connections.Add(await dataSource.OpenConnectionAsync());
            }
        }
        catch (PostgresException e)
        {
            Console.WriteLine($"{e.SqlState}: {e.MessageText}");
        }
        finally
        {
            foreach (var connection in connections)
            {
                await connection.DisposeAsync();
            }
        }
    }
}
