using Npgsql;

namespace Learn.Pg;

// Lesson 6: what two sessions do to each other. Each example opens two connections, A and B, and runs their
// statements in a fixed order; when B has to wait for A, a third connection watches pg_stat_activity until B is
// waiting, so that the output is the same at every run.
static class L06
{
    static async Task<int> Exec(NpgsqlConnection connection, string sql)
    {
        await using var command = new NpgsqlCommand(sql, connection);
        return await command.ExecuteNonQueryAsync();
    }

    static async Task<T> Scalar<T>(NpgsqlConnection connection, string sql)
    {
        await using var command = new NpgsqlCommand(sql, connection);
        return (T)(await command.ExecuteScalarAsync())!;
    }

    // Polls until the session with this process ID waits for a lock, and returns the sessions blocking it
    static async Task<int[]> WaitUntilBlocked(NpgsqlDataSource dataSource, int pid)
    {
        await using var observer = await dataSource.OpenConnectionAsync();
        while (true)
        {
            await using var command = new NpgsqlCommand(
                "SELECT pg_blocking_pids(pid) FROM pg_stat_activity WHERE pid = $1 AND wait_event_type = 'Lock'", observer);
            command.Parameters.Add(new() { Value = pid });
            if (await command.ExecuteScalarAsync() is int[] blockers)
            {
                return blockers;
            }
            await Task.Delay(20);
        }
    }

    // One row per workflow of the CI snapshot, with its number of runs
    static async Task<NpgsqlDataSource> Totals()
    {
        var dataSource = Db.DataSource();
        await using var setup = await dataSource.OpenConnectionAsync();
        await Exec(setup, """
            DROP TABLE IF EXISTS ci.workflow_runs;
            CREATE TABLE ci.workflow_runs AS SELECT workflow_name, count(*)::int AS runs FROM ci.runs GROUP BY workflow_name;
            ALTER TABLE ci.workflow_runs ADD PRIMARY KEY (workflow_name);
            """);
        return dataSource;
    }

    const string ReadDeploy = "SELECT runs FROM ci.workflow_runs WHERE workflow_name = 'Deploy to GitHub Pages'";
    const string IncrementDeploy = "UPDATE ci.workflow_runs SET runs = runs + 1 WHERE workflow_name = 'Deploy to GitHub Pages'";

    public static async Task Isolation()
    {
        await using var dataSource = await Totals();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();

        // A reads twice in one transaction; B commits an update in between
        foreach (var level in new[] { "READ COMMITTED", "REPEATABLE READ", "SERIALIZABLE" })
        {
            await Exec(a, $"BEGIN ISOLATION LEVEL {level}");
            var first = await Scalar<int>(a, ReadDeploy);
            await Exec(b, IncrementDeploy);
            var second = await Scalar<int>(a, ReadDeploy);
            await Exec(a, "COMMIT");
            Console.WriteLine($"{level}: A reads {first}, B commits +1, A reads {second}");
        }

        // B's update is not committed yet: A never sees it, even when it asks for READ UNCOMMITTED
        await Exec(b, "BEGIN");
        await Exec(b, IncrementDeploy);
        await Exec(a, "BEGIN ISOLATION LEVEL READ UNCOMMITTED");
        Console.WriteLine($"READ UNCOMMITTED: B has not committed, A reads {await Scalar<int>(a, ReadDeploy)}");
        await Exec(a, "COMMIT");
        await Exec(b, "ROLLBACK");
    }

    public static async Task LostUpdate()
    {
        await using var dataSource = await Totals();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        var start = await Scalar<int>(a, ReadDeploy);
        Console.WriteLine($"runs before: {start}");

        // Read, add one in the application, write back: B's write replaces A's
        await Exec(a, "BEGIN");
        await Exec(b, "BEGIN");
        var readByA = await Scalar<int>(a, ReadDeploy);
        var readByB = await Scalar<int>(b, ReadDeploy);
        await Exec(a, $"UPDATE ci.workflow_runs SET runs = {readByA + 1} WHERE workflow_name = 'Deploy to GitHub Pages'");
        await Exec(a, "COMMIT");
        await Exec(b, $"UPDATE ci.workflow_runs SET runs = {readByB + 1} WHERE workflow_name = 'Deploy to GitHub Pages'");
        await Exec(b, "COMMIT");
        Console.WriteLine($"READ COMMITTED, read then write: two increments, runs = {await Scalar<int>(a, ReadDeploy)}");

        // The same in REPEATABLE READ: B's write fails, because the row changed after B's snapshot
        await Exec(a, "BEGIN ISOLATION LEVEL REPEATABLE READ");
        await Exec(b, "BEGIN ISOLATION LEVEL REPEATABLE READ");
        readByA = await Scalar<int>(a, ReadDeploy);
        readByB = await Scalar<int>(b, ReadDeploy);
        await Exec(a, $"UPDATE ci.workflow_runs SET runs = {readByA + 1} WHERE workflow_name = 'Deploy to GitHub Pages'");
        await Exec(a, "COMMIT");
        try
        {
            await Exec(b, $"UPDATE ci.workflow_runs SET runs = {readByB + 1} WHERE workflow_name = 'Deploy to GitHub Pages'");
        }
        catch (PostgresException e)
        {
            Console.WriteLine($"REPEATABLE READ, read then write: B gets {e.SqlState}: {e.MessageText}");
            await Exec(b, "ROLLBACK");
        }
        Console.WriteLine($"runs = {await Scalar<int>(a, ReadDeploy)}");

        // runs = runs + 1 in READ COMMITTED: B waits for A's row lock, then adds one to the row A committed
        await Exec(a, "BEGIN");
        await Exec(a, IncrementDeploy);
        var waiting = Exec(b, IncrementDeploy);
        var blockers = await WaitUntilBlocked(dataSource, b.ProcessID);
        Console.WriteLine($"READ COMMITTED, runs = runs + 1: B waits, blocked by A: {blockers.SequenceEqual([a.ProcessID])}");
        await Exec(a, "COMMIT");
        await waiting;
        Console.WriteLine($"runs = {await Scalar<int>(a, ReadDeploy)}");
    }

    public static async Task WriteSkew()
    {
        await using var dataSource = Db.DataSource();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        // Two runner images; the rule: at least one stays enabled. A disables macOS, B disables Windows.
        const string Check = "SELECT count(*) FROM ci.runner_images WHERE enabled";
        foreach (var level in new[] { "REPEATABLE READ", "SERIALIZABLE" })
        {
            await Exec(a, """
                DROP TABLE IF EXISTS ci.runner_images;
                CREATE TABLE ci.runner_images (label text PRIMARY KEY, enabled boolean NOT NULL);
                INSERT INTO ci.runner_images VALUES ('macos-latest', true), ('windows-latest', true);
                """);
            await Exec(a, $"BEGIN ISOLATION LEVEL {level}");
            await Exec(b, $"BEGIN ISOLATION LEVEL {level}");
            Console.WriteLine($"{level}: A sees {await Scalar<long>(a, Check)} enabled, B sees {await Scalar<long>(b, Check)} enabled");
            await Exec(a, "UPDATE ci.runner_images SET enabled = false WHERE label = 'macos-latest'");
            await Exec(b, "UPDATE ci.runner_images SET enabled = false WHERE label = 'windows-latest'");
            await Exec(a, "COMMIT");
            try
            {
                await Exec(b, "COMMIT");
                Console.WriteLine("  both commit");
            }
            catch (PostgresException e)
            {
                Console.WriteLine($"  A commits, B's COMMIT gets {e.SqlState}: {e.MessageText}");
            }
            Console.WriteLine($"  enabled now: {await Scalar<long>(a, Check)}");
        }
    }

    public static async Task Locks()
    {
        await using var dataSource = await Totals();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        await Exec(a, "BEGIN");
        await Exec(a, ReadDeploy + " FOR UPDATE");

        // NOWAIT and lock_timeout turn a wait into an error
        try
        {
            await Exec(b, ReadDeploy + " FOR UPDATE NOWAIT");
        }
        catch (PostgresException e)
        {
            Console.WriteLine($"NOWAIT: {e.SqlState}: {e.MessageText}");
        }
        await Exec(b, "SET lock_timeout = '200ms'");
        try
        {
            await Exec(b, IncrementDeploy);
        }
        catch (PostgresException e)
        {
            Console.WriteLine($"lock_timeout: {e.SqlState}: {e.MessageText}");
        }
        await Exec(b, "RESET lock_timeout");

        // A plain read never waits for a row lock
        Console.WriteLine($"B reads without waiting: {await Scalar<int>(b, ReadDeploy)}");

        // Without a timeout, B waits as long as A keeps its transaction open
        var waiting = Exec(b, IncrementDeploy);
        var blockers = await WaitUntilBlocked(dataSource, b.ProcessID);
        await using (var observer = await dataSource.OpenConnectionAsync())
        await using (var command = new NpgsqlCommand("SELECT wait_event_type, wait_event, state FROM pg_stat_activity WHERE pid = $1", observer))
        {
            command.Parameters.Add(new() { Value = b.ProcessID });
            await using var reader = await command.ExecuteReaderAsync();
            await reader.ReadAsync();
            Console.WriteLine($"B: wait_event_type={reader.GetString(0)}, wait_event={reader.GetString(1)}, state={reader.GetString(2)}, blocked by A: {blockers.SequenceEqual([a.ProcessID])}");
        }
        await Exec(a, "COMMIT");
        Console.WriteLine($"A commits, B's UPDATE returns: {await waiting} row");
    }

    public static async Task Deadlock()
    {
        await using var dataSource = await Totals();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        // The deadlock check runs in a session that has waited deadlock_timeout (1 s by default):
        // B checks after 100 ms and A after 10 s, so B is always the one that detects the cycle and is cancelled
        await Exec(a, "SET deadlock_timeout = '10s'");
        await Exec(b, "SET deadlock_timeout = '100ms'");

        await Exec(a, "BEGIN");
        await Exec(b, "BEGIN");
        await Exec(a, "UPDATE ci.workflow_runs SET runs = runs + 1 WHERE workflow_name = 'Deploy to GitHub Pages'");
        await Exec(b, "UPDATE ci.workflow_runs SET runs = runs + 1 WHERE workflow_name = 'Rust course examples'");
        Console.WriteLine("A locks Deploy to GitHub Pages, B locks Rust course examples");
        var waiting = Exec(a, "UPDATE ci.workflow_runs SET runs = runs + 1 WHERE workflow_name = 'Rust course examples'");
        await WaitUntilBlocked(dataSource, a.ProcessID);
        Console.WriteLine("A waits for Rust course examples");
        try
        {
            await Exec(b, "UPDATE ci.workflow_runs SET runs = runs + 1 WHERE workflow_name = 'Deploy to GitHub Pages'");
        }
        catch (PostgresException e)
        {
            Console.WriteLine($"B asks for Deploy to GitHub Pages: {e.SqlState}: {e.MessageText}");
            await Exec(b, "ROLLBACK");
        }
        Console.WriteLine($"A's UPDATE returns {await waiting} row");
        await Exec(a, "COMMIT");
    }

    // Exercise 1: an open transaction keeps VACUUM from removing dead rows
    public static async Task VacuumHorizon()
    {
        await using var dataSource = await Totals();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        await Exec(b, "CREATE EXTENSION IF NOT EXISTS pgstattuple");
        const string Dead = "SELECT dead_tuple_count FROM pgstattuple('ci.workflow_runs')";

        await Exec(a, "BEGIN ISOLATION LEVEL REPEATABLE READ");
        Console.WriteLine($"A opens a snapshot: {await Scalar<int>(a, ReadDeploy)} runs");
        Console.WriteLine($"B updates {await Exec(b, "UPDATE ci.workflow_runs SET runs = runs + 1")} rows");
        await Exec(b, "VACUUM ci.workflow_runs");
        Console.WriteLine($"VACUUM while A is open: {await Scalar<long>(b, Dead)} dead row versions left");
        Console.WriteLine($"A still reads {await Scalar<int>(a, ReadDeploy)} runs");
        await Exec(a, "COMMIT");
        await Exec(b, "VACUUM ci.workflow_runs");
        Console.WriteLine($"VACUUM after A commits: {await Scalar<long>(b, Dead)} dead row versions left");
    }

    // Exercise 3: two workers take jobs from the same queue without waiting for each other
    public static async Task SkipLocked()
    {
        await using var dataSource = Db.DataSource();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        await Exec(a, """
            DROP TABLE IF EXISTS ci.rerun_queue;
            CREATE TABLE ci.rerun_queue AS
            SELECT row_number() OVER (ORDER BY started_at, run_id)::int AS id, run_id, workflow_name
            FROM ci.runs WHERE conclusion = 'failure';
            """);
        const string Claim = """
            SELECT string_agg(id::text, ', ' ORDER BY id) FROM (
                SELECT id FROM ci.rerun_queue ORDER BY id LIMIT 3 FOR UPDATE SKIP LOCKED
            ) AS claimed
            """;
        await Exec(a, "BEGIN");
        await Exec(b, "BEGIN");
        Console.WriteLine($"worker A claims jobs {await Scalar<string>(a, Claim)}");
        Console.WriteLine($"worker B claims jobs {await Scalar<string>(b, Claim)}");
        await Exec(a, "DELETE FROM ci.rerun_queue WHERE id IN (1, 2, 3)");
        await Exec(a, "COMMIT");
        await Exec(b, "ROLLBACK");
        Console.WriteLine($"A deleted its jobs, B rolled back: {await Scalar<long>(a, "SELECT count(*) FROM ci.rerun_queue")} jobs left, next claim: {await Scalar<string>(a, Claim)}");
    }
}
