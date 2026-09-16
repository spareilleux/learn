using System.Data;
using Npgsql;

namespace Learn.Pg;

// Lesson 8: calling functions and procedures from Npgsql, and the errors a trigger raises
static class L08
{
    // The routines of this example, created on each run
    static readonly string[] Setup =
    [
        "DROP PROCEDURE IF EXISTS ci.count_runs",
        "DROP FUNCTION IF EXISTS ci.failure_rate",
        """
        CREATE FUNCTION ci.failure_rate(workflow text) RETURNS numeric
        LANGUAGE sql STABLE
        BEGIN ATOMIC
            SELECT round(avg((conclusion = 'failure')::int), 2) FROM ci.runs WHERE workflow_name = workflow;
        END
        """,
        """
        CREATE PROCEDURE ci.count_runs(workflow text, OUT runs bigint, OUT failures bigint)
        LANGUAGE sql
        BEGIN ATOMIC
            SELECT count(*), count(*) FILTER (WHERE conclusion = 'failure') FROM ci.runs WHERE workflow_name = workflow;
        END
        """,
    ];

    public static async Task Routines()
    {
        await using var dataSource = Db.DataSource();
        await using var connection = await dataSource.OpenConnectionAsync();

        await using (var drop = new NpgsqlCommand(Setup[0] + ";" + Setup[1], connection))
        {
            await drop.ExecuteNonQueryAsync();
        }
        // Npgsql splits the text of a command without parameters at each semicolon, to send the statements as a batch:
        // it splits CREATE FUNCTION at the semicolon inside BEGIN ATOMIC too
        try
        {
            await using var create = new NpgsqlCommand(Setup[2], connection);
            await create.ExecuteNonQueryAsync();
        }
        catch (PostgresException e)
        {
            Console.WriteLine($"CREATE FUNCTION ... BEGIN ATOMIC in an NpgsqlCommand: {e.SqlState}: {e.MessageText}");
        }
        // The commands of an NpgsqlBatch are sent as they are
        await using (var batch = new NpgsqlBatch(connection))
        {
            foreach (var sql in Setup)
            {
                batch.BatchCommands.Add(new NpgsqlBatchCommand(sql));
            }
            await batch.ExecuteNonQueryAsync();
            Console.WriteLine("the same statements in an NpgsqlBatch: created");
        }

        // A function is called in a query, like any expression
        await using (var command = new NpgsqlCommand("SELECT ci.failure_rate($1)", connection))
        {
            command.Parameters.Add(new() { Value = "Rust course examples" });
            Console.WriteLine($"SELECT ci.failure_rate($1): {await command.ExecuteScalarAsync()}");
        }

        // CommandType.StoredProcedure generates CALL, which runs procedures only
        await using (var command = new NpgsqlCommand("ci.count_runs", connection) { CommandType = CommandType.StoredProcedure })
        {
            command.Parameters.Add(new() { Value = "Rust course examples" });
            var runs = new NpgsqlParameter { ParameterName = "runs", Direction = ParameterDirection.Output, NpgsqlDbType = NpgsqlTypes.NpgsqlDbType.Bigint };
            var failures = new NpgsqlParameter { ParameterName = "failures", Direction = ParameterDirection.Output, NpgsqlDbType = NpgsqlTypes.NpgsqlDbType.Bigint };
            command.Parameters.Add(runs);
            command.Parameters.Add(failures);
            await command.ExecuteNonQueryAsync();
            Console.WriteLine($"StoredProcedure ci.count_runs: runs = {runs.Value}, failures = {failures.Value}");
        }
        await using (var command = new NpgsqlCommand("ci.failure_rate", connection) { CommandType = CommandType.StoredProcedure })
        {
            command.Parameters.Add(new() { Value = "Rust course examples" });
            try
            {
                await command.ExecuteScalarAsync();
            }
            catch (PostgresException e)
            {
                Console.WriteLine($"StoredProcedure ci.failure_rate: {e.SqlState}: {e.MessageText} ({e.Hint})");
            }
        }
    }

    public static async Task TriggerError()
    {
        await using var dataSource = Db.DataSource();
        await using var connection = await dataSource.OpenConnectionAsync();
        await using (var setup = new NpgsqlCommand("""
            DROP TABLE IF EXISTS ga.package_pins;
            CREATE TABLE ga.package_pins (package text PRIMARY KEY, version text NOT NULL);
            CREATE OR REPLACE FUNCTION ga.check_pin() RETURNS trigger
            LANGUAGE plpgsql
            AS $$
            BEGIN
                IF NEW.version !~ '^\d+(\.\d+)*$' THEN
                    RAISE EXCEPTION 'version % of % is not an exact numeric version', NEW.version, NEW.package
                        USING ERRCODE = 'check_violation', HINT = 'Pin a released version, such as 10.0.5.';
                END IF;
                RETURN NEW;
            END
            $$;
            CREATE TRIGGER check_pin BEFORE INSERT OR UPDATE ON ga.package_pins
                FOR EACH ROW EXECUTE FUNCTION ga.check_pin();
            """, connection))
        {
            await setup.ExecuteNonQueryAsync();
        }

        await using var insert = new NpgsqlCommand("INSERT INTO ga.package_pins VALUES ($1, $2)", connection);
        insert.Parameters.Add(new() { Value = "ModelContextProtocol" });
        insert.Parameters.Add(new() { Value = "0.*" });
        try
        {
            await insert.ExecuteNonQueryAsync();
        }
        catch (PostgresException e) when (e.SqlState == PostgresErrorCodes.CheckViolation)
        {
            Console.WriteLine($"{e.SqlState}: {e.MessageText}");
            Console.WriteLine($"hint: {e.Hint}");
            Console.WriteLine($"where: {e.Where}");
        }
    }
}
