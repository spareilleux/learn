using Npgsql;

namespace Learn.Pg;

// Lesson 12: a failover seen from Npgsql. ops/12-cluster.sh starts node1, a primary on port 5433, and node2, its
// standby on port 5434; the program lists both hosts, as an application would list an Aurora cluster's instances.
static class L12
{
    const string Cluster = "Host=localhost:5433,localhost:5434;Username=postgres;Password=learn;Database=learn;Application Name=learn-csharp";

    static async Task<string> Describe(NpgsqlConnection connection)
    {
        await using var command = new NpgsqlCommand("SELECT inet_server_port(), pg_is_in_recovery()", connection);
        await using var reader = await command.ExecuteReaderAsync();
        await reader.ReadAsync();
        return $"port {reader.GetInt32(0)}, pg_is_in_recovery() = {reader.GetBoolean(1)}";
    }

    static async Task<string> Write(NpgsqlDataSource writer)
    {
        try
        {
            await using var connection = await writer.OpenConnectionAsync();
            await using var command = new NpgsqlCommand("INSERT INTO orders DEFAULT VALUES RETURNING written_on", connection);
            return $"order written on port {await command.ExecuteScalarAsync()}";
        }
        catch (NpgsqlException e)
        {
            return $"{e.GetType().Name}: {e.Message}";
        }
    }

    public static async Task Failover()
    {
        await using var cluster = new NpgsqlDataSourceBuilder(Cluster).BuildMultiHost();
        var writer = cluster.WithTargetSession(TargetSessionAttributes.ReadWrite);
        var standby = cluster.WithTargetSession(TargetSessionAttributes.Standby);
        await using (var connection = await standby.OpenConnectionAsync())
        {
            Console.WriteLine($"standby: {await Describe(connection)}");
        }
        Console.WriteLine($"before: {await Write(writer)}");

        // A connection opened before the failover, and node1 stopped by its own server: pg_ctl -W doesn't wait
        await using var open = await writer.OpenConnectionAsync();
        await using (var admin = await writer.OpenConnectionAsync())
        {
            await using var stop = new NpgsqlCommand("COPY (SELECT) TO PROGRAM '/usr/lib/postgresql/18/bin/pg_ctl -D /tmp/node1 -m fast -W stop'", admin);
            try
            {
                await stop.ExecuteNonQueryAsync();
            }
            catch (NpgsqlException)
            {
                // The shutdown may end this session before COPY returns
            }
        }
        while (true)
        {
            try
            {
                await using var direct = new NpgsqlConnection(Cluster.Replace("localhost:5433,localhost:5434", "localhost:5433"));
                await direct.OpenAsync();
                await Task.Delay(100);
            }
            catch (NpgsqlException)
            {
                break;
            }
        }
        Console.WriteLine("node1 stopped");
        await using var query = new NpgsqlCommand("SELECT 1", open);
        try
        {
            await query.ExecuteScalarAsync();
        }
        catch (NpgsqlException)
        {
            // The exception depends on the machine: a PostgresException 57P01 on Linux in CI, "Exception while reading
            // from stream" through Docker Desktop on Windows. The connection's state is the same on both
            Console.WriteLine($"open connection: the query fails, FullState = {open.FullState}");
        }
        Console.WriteLine($"no primary: {await Write(writer)}");

        // The promotion, which Aurora does by itself: node2 stops replaying WAL and accepts writes
        await using (var connection = await standby.OpenConnectionAsync())
        {
            await using var promote = new NpgsqlCommand("SELECT pg_promote()", connection);
            Console.WriteLine($"pg_promote() on node2: {await promote.ExecuteScalarAsync()}");
        }
        // The same data source, with the same host list, now finds its writer on node2
        Console.WriteLine($"after: {await Write(writer)}");
    }
}
