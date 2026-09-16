---
title: "8. Functions and extensions"
description: Server-side code in PostgreSQL for T-SQL developers — SQL functions with BEGIN ATOMIC bodies, PL/pgSQL with exception handlers, procedures that commit, row and statement triggers with transition tables, calling routines from Npgsql and pgjdbc, trusted extensions — and pgvector, with HNSW indexes and filtered searches on Guitar Alchemist's chords.
sidebar:
  order: 8
---

The lesson's scripts are [`sql/08-functions.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql) and [`sql/08-pgvector.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql), the exercises are in [`sql/08-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql) and [`sql/08-pgvector-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector-exercises.sql), and the programs in [`csharp/L08.cs`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L08.cs) and [`java/…/L08.java`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L08.java). `check.sh` compares their output with the files of the same names in [`expected`](https://github.com/spareilleux/learn/tree/a5e397e/code/postgresql-aurora/expected).

| SQL Server | PostgreSQL |
|---|---|
| scalar function, inline table-valued function | SQL function returning a value, a row, `SETOF` rows or `TABLE (…)` |
| `WITH SCHEMABINDING` | a `BEGIN ATOMIC` body, whose dependencies are recorded |
| T-SQL, `TRY … CATCH`, `THROW` | PL/pgSQL, `EXCEPTION WHEN`, `RAISE` |
| stored procedure, `EXEC`, `OUTPUT` parameters | procedure, `CALL`, `OUT` parameters; functions don't run with `CALL` |
| `COMMIT` inside a procedure, with `@@TRANCOUNT` rules | `COMMIT` inside a procedure called outside a transaction block |
| `AFTER` and `INSTEAD OF` triggers, `inserted` and `deleted` | `BEFORE`, `AFTER` and `INSTEAD OF` triggers, per row or per statement, transition tables |
| CLR assemblies | extensions, in C or in trusted languages |
| `vector` type and `CREATE VECTOR INDEX` (preview) in SQL Server 2025 | the `pgvector` extension, HNSW and IVFFlat indexes |

## SQL functions

A [SQL function](https://www.postgresql.org/docs/18/xfunc-sql.html) with a standard body, written between `BEGIN ATOMIC` and `END`. It computes the pitch classes that a guitar voicing plays, the query of [lesson 3's first exercise](../03-queries/#exercises) ([lines 7-19](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L7-L19)):

```sql
-- A SQL function with a standard body: parsed when it is created, and its dependencies recorded
CREATE FUNCTION ga.played_pitch_classes(voicing smallint[]) RETURNS smallint[]
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
    SELECT array_agg(DISTINCT (fret + (ARRAY[4, 9, 2, 7, 11, 4])[string]) % 12 ORDER BY (fret + (ARRAY[4, 9, 2, 7, 11, 4])[string]) % 12)
    FROM unnest(voicing) WITH ORDINALITY AS v(fret, string)
    WHERE fret >= 0;
END;

SELECT name, guitar_voicing, ga.played_pitch_classes(guitar_voicing) AS played
FROM ga.iconic_chords
WHERE guitar_voicing IS NOT NULL
ORDER BY chord_id;
```

```text
CREATE FUNCTION
       name       |  guitar_voicing  |   played
------------------+------------------+-------------
 Hendrix Chord    | {0,7,6,7,8,0}    | {2,4,7,8}
 James Bond Chord | {0,2,1,0,0,0}    | {3,4,7,11}
 Mu Major Chord   | {0,3,0,0,3,0}    | {0,2,4,7}
 Cowboy Chord     | {3,2,0,0,3,3}    | {2,7,11}
 Power Chord      | {3,5,5,-1,-1,-1} | {2,7}
 Blackbird Chord  | {0,0,0,0,2,0}    | {1,2,4,7,9}
(6 rows)
```

[`CREATE FUNCTION`](https://www.postgresql.org/docs/18/sql-createfunction.html) declares a volatility: `IMMUTABLE`, the same result for the same arguments forever, which lets an index use the function ([lesson 5](../05-indexes/#indexes-on-expressions)); `STABLE`, the same result within one statement; `VOLATILE`, the default. `STRICT` returns `NULL` without running the body when an argument is `NULL`.

The older form writes the body as a string, `AS $$ … $$`, which PostgreSQL stores as text and parses again when the function runs. A `BEGIN ATOMIC` body is parsed when the function is created, and PostgreSQL records what it depends on ([lines 21-27](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L21-L27)):

```sql
-- A standard body is stored parsed, with its dependencies: a column it reads can't be dropped
CREATE FUNCTION ga.voicing_of(chord text) RETURNS smallint[]
LANGUAGE sql STABLE
BEGIN ATOMIC
    SELECT guitar_voicing FROM ga.iconic_chords WHERE name = chord;
END;
ALTER TABLE ga.iconic_chords DROP COLUMN guitar_voicing;
```

```text
CREATE FUNCTION
ERROR:  cannot drop column guitar_voicing of table ga.iconic_chords because other objects depend on it
DETAIL:  function ga.voicing_of(text) depends on column guitar_voicing of table ga.iconic_chords
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
```

The column can't be dropped while the function reads it, as with SQL Server's `SCHEMABINDING`. A string body would have been accepted, and failed at its next call.

## PL/pgSQL

[PL/pgSQL](https://www.postgresql.org/docs/18/plpgsql.html) adds variables, loops and error handling. A function that turns a version string into an array of numbers, and `NULL` when it can't ([lines 29-49](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L29-L49)):

```sql
-- PL/pgSQL: variables, loops, and an exception handler that turns a failed cast into NULL
CREATE FUNCTION ga.version_numbers(version text) RETURNS integer[]
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
    part text;
    numbers integer[] := '{}';
BEGIN
    FOREACH part IN ARRAY string_to_array(version, '.') LOOP
        numbers := numbers || part::integer;
    END LOOP;
    RETURN numbers;
EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE NOTICE 'not a numeric version: %', version;
        RETURN NULL;
END
$$;

SELECT v AS version, ga.version_numbers(v) AS numbers
FROM unnest(ARRAY['10.0.5', '9.0.4', '9.4.0-preview.1.25207.5']) AS v;
```

```text
CREATE FUNCTION
NOTICE:  not a numeric version: 9.4.0-preview.1.25207.5
         version         | numbers
-------------------------+----------
 10.0.5                  | {10,0,5}
 9.0.4                   | {9,0,4}
 9.4.0-preview.1.25207.5 |
(3 rows)
```

- `DECLARE` lists the variables; `:=` assigns.
- The cast `'0-preview'::integer` raises `invalid_text_representation`, SQLSTATE `22P02`. The [`EXCEPTION`](https://www.postgresql.org/docs/18/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING) block catches it by name, like `BEGIN CATCH`, and returns `NULL`.
- `RAISE NOTICE` sends a message to the client, which `psql` prints; Npgsql raises its `Notice` event. It's `PRINT` in T-SQL.

A block with an `EXCEPTION` clause runs in a subtransaction, which costs more than a block without one: keep them where an error is expected.

Integer arrays compare element by element, which is how versions compare. [Lesson 3](../03-queries/) found that the text maximum isn't the highest version; with the function ([lines 51-56](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L51-L56)):

```sql
-- Lesson 3's highest version per package, with the function
SELECT package, (array_agg(version ORDER BY ga.version_numbers(version) DESC NULLS LAST))[1] AS highest
FROM ga.package_refs
WHERE package IN ('Microsoft.Extensions.Hosting', 'Microsoft.ML.Tokenizers', 'ModelContextProtocol')
GROUP BY package
ORDER BY package;
```

```text
NOTICE:  not a numeric version: 0.*
NOTICE:  not a numeric version: 0.1.0-preview.10
NOTICE:  not a numeric version: 0.22.0-preview.24378.1
           package            | highest
------------------------------+---------
 Microsoft.Extensions.Hosting | 10.0.5
 Microsoft.ML.Tokenizers      | 2.0.0
 ModelContextProtocol         | 1.3.0
(3 rows)
```

`DESC NULLS LAST` puts the versions that aren't plain numbers, such as `0.*`, after the others. The notices are printed while the aggregate reads the rows.

## Procedures and transactions

A [procedure](https://www.postgresql.org/docs/18/xproc.html) runs with [`CALL`](https://www.postgresql.org/docs/18/sql-call.html), returns no value, and, unlike a function, can commit. Archiving the failed runs in batches of five, one transaction per batch ([lines 58-84](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L58-L84)):

```sql
-- A procedure can commit: CALL archives failed runs in batches, one transaction per batch
CREATE TABLE ci.archived_runs (LIKE ci.runs);
CREATE PROCEDURE ci.archive_failed_runs(batch_size integer)
LANGUAGE plpgsql
AS $$
DECLARE
    moved integer;
    batches integer := 0;
BEGIN
    LOOP
        WITH batch AS (
            SELECT run_id FROM ci.runs
            WHERE conclusion = 'failure' AND run_id NOT IN (SELECT run_id FROM ci.archived_runs)
            ORDER BY run_id
            LIMIT batch_size
        )
        INSERT INTO ci.archived_runs SELECT r.* FROM ci.runs AS r JOIN batch USING (run_id);
        GET DIAGNOSTICS moved = ROW_COUNT;
        EXIT WHEN moved = 0;
        batches := batches + 1;
        COMMIT;
        RAISE NOTICE 'batch %: % runs', batches, moved;
    END LOOP;
END
$$;
CALL ci.archive_failed_runs(5);
SELECT count(*) AS archived FROM ci.archived_runs;
```

```text
CREATE TABLE
CREATE PROCEDURE
NOTICE:  batch 1: 5 runs
NOTICE:  batch 2: 5 runs
NOTICE:  batch 3: 5 runs
NOTICE:  batch 4: 1 runs
CALL
 archived
----------
       16
(1 row)
```

`GET DIAGNOSTICS moved = ROW_COUNT` is `@@ROWCOUNT`. Each `COMMIT` ends the batch's transaction and starts a new one: a long job that commits as it goes keeps its row versions from piling up ([lesson 6](../06-transactions/#bloat)), and a failure only loses the current batch.

It only works when `CALL` is the start of the transaction ([lines 86-90](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L86-L90)):

```sql
-- Inside an explicit transaction block, the procedure can't commit
TRUNCATE ci.archived_runs;
BEGIN;
CALL ci.archive_failed_runs(5);
ROLLBACK;
```

```text
TRUNCATE TABLE
BEGIN
ERROR:  invalid transaction termination
CONTEXT:  PL/pgSQL function ci.archive_failed_runs(integer) line 17 at COMMIT
ROLLBACK
```

Inside `BEGIN`, the procedure can't commit a transaction it didn't start ([transaction management](https://www.postgresql.org/docs/18/plpgsql-transactions.html)).

## Triggers

Package pins that must name an exact version, and an audit table ([lines 92-119](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L92-L119)):

```sql
-- Triggers: package pins that must name an exact version, and an audit of every change
CREATE TABLE ga.package_pins (
    package text PRIMARY KEY,
    version text NOT NULL
);
CREATE TABLE ga.package_pins_audit (
    change_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    operation  text NOT NULL,
    package    text NOT NULL,
    old_version text,
    new_version text
);

-- A row-level BEFORE trigger can change the row or reject it
CREATE FUNCTION ga.check_pin() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.version := trim(NEW.version);
    IF ga.version_numbers(NEW.version) IS NULL THEN
        RAISE EXCEPTION 'version % of % is not an exact numeric version', NEW.version, NEW.package
            USING ERRCODE = 'check_violation', HINT = 'Pin a released version, such as 10.0.5.';
    END IF;
    RETURN NEW;
END
$$;
CREATE TRIGGER check_pin BEFORE INSERT OR UPDATE ON ga.package_pins
    FOR EACH ROW EXECUTE FUNCTION ga.check_pin();
```

A [trigger](https://www.postgresql.org/docs/18/plpgsql-trigger.html) in PostgreSQL is a function that returns `trigger`, attached to a table by `CREATE TRIGGER`. A `BEFORE … FOR EACH ROW` trigger sees the row about to be written as `NEW`, can change it, as `trim` does here, or reject it with an error. SQL Server has no `BEFORE` trigger; an `INSTEAD OF` trigger that rewrites the statement comes closest.

A statement-level `AFTER` trigger sees all the changed rows at once, in [transition tables](https://www.postgresql.org/docs/18/sql-createtrigger.html) named by `REFERENCING`: `inserted` and `deleted` in SQL Server ([lines 121-154](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L121-L154)):

```sql
-- A statement-level AFTER trigger sees every changed row at once, in transition tables, like inserted and deleted in T-SQL
CREATE FUNCTION ga.audit_pins() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO ga.package_pins_audit (operation, package, new_version)
        SELECT TG_OP, package, version FROM new_rows ORDER BY package;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO ga.package_pins_audit (operation, package, old_version, new_version)
        SELECT TG_OP, o.package, o.version, n.version
        FROM old_rows AS o JOIN new_rows AS n USING (package)
        WHERE o.version IS DISTINCT FROM n.version
        ORDER BY o.package;
    ELSE
        INSERT INTO ga.package_pins_audit (operation, package, old_version)
        SELECT TG_OP, package, version FROM old_rows ORDER BY package;
    END IF;
    RETURN NULL;
END
$$;
CREATE TRIGGER audit_pins_insert AFTER INSERT ON ga.package_pins
    REFERENCING NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION ga.audit_pins();
CREATE TRIGGER audit_pins_update AFTER UPDATE ON ga.package_pins
    REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION ga.audit_pins();
CREATE TRIGGER audit_pins_delete AFTER DELETE ON ga.package_pins
    REFERENCING OLD TABLE AS old_rows FOR EACH STATEMENT EXECUTE FUNCTION ga.audit_pins();

INSERT INTO ga.package_pins VALUES ('Npgsql', ' 10.0.3 '), ('MongoDB.Driver', '3.5.0'), ('OpenTelemetry', '1.12.0');
INSERT INTO ga.package_pins VALUES ('Microsoft.Extensions.AI', '9.4.0-preview.1.25207.5');
UPDATE ga.package_pins SET version = CASE package WHEN 'MongoDB.Driver' THEN '3.6.0' ELSE version END;
DELETE FROM ga.package_pins WHERE package = 'OpenTelemetry';
SELECT * FROM ga.package_pins ORDER BY package;
SELECT * FROM ga.package_pins_audit ORDER BY change_id;
```

```text
CREATE FUNCTION
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
INSERT 0 3
NOTICE:  not a numeric version: 9.4.0-preview.1.25207.5
ERROR:  version 9.4.0-preview.1.25207.5 of Microsoft.Extensions.AI is not an exact numeric version
HINT:  Pin a released version, such as 10.0.5.
CONTEXT:  PL/pgSQL function ga.check_pin() line 5 at RAISE
UPDATE 3
DELETE 1
    package     | version
----------------+---------
 MongoDB.Driver | 3.6.0
 Npgsql         | 10.0.3
(2 rows)

 change_id | operation |    package     | old_version | new_version
-----------+-----------+----------------+-------------+-------------
         1 | INSERT    | MongoDB.Driver |             | 3.5.0
         2 | INSERT    | Npgsql         |             | 10.0.3
         3 | INSERT    | OpenTelemetry  |             | 1.12.0
         4 | UPDATE    | MongoDB.Driver | 3.5.0       | 3.6.0
         5 | DELETE    | OpenTelemetry  | 1.12.0      |
(5 rows)
```

- The `INSERT` of three pins passed; `' 10.0.3 '` was stored as `10.0.3`.
- The preview version was rejected with SQLSTATE `23514`, `check_violation`, and the hint.
- The `UPDATE` touched three rows and changed one: the audit keeps only the rows whose version changed.
- One trigger per event: a trigger that requests transition tables can't list several events with `OR`.

## Routines from C# and Java

The drivers call functions and procedures in different ways, and one of them trips on `BEGIN ATOMIC` ([lines 9-91](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L08.cs#L9-L91)):

```csharp
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
```

```text
CREATE FUNCTION ... BEGIN ATOMIC in an NpgsqlCommand: 42601: syntax error at end of input
the same statements in an NpgsqlBatch: created
SELECT ci.failure_rate($1): 0.17
StoredProcedure ci.count_runs: runs = 18, failures = 3
StoredProcedure ci.failure_rate: 42809: ci.failure_rate(text) is not a procedure (To call a function, use SELECT.)
```

- The `CREATE FUNCTION` fails in an `NpgsqlCommand`. A command without parameters may hold several statements separated by semicolons, and Npgsql splits its text at each semicolon that isn't inside parentheses, a string or a comment, to send the statements as a batch ([`SqlQueryParser.cs`, lines 137-139](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/SqlQueryParser.cs#L137-L139), and [`NpgsqlCommand.cs`, lines 931-941](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/NpgsqlCommand.cs#L931-L941)). The semicolon after the `SELECT` in `BEGIN ATOMIC` cuts the statement in two, and the server sees `CREATE FUNCTION … BEGIN ATOMIC SELECT …` end without its `END`.
- An [`NpgsqlBatch`](https://www.npgsql.org/doc/basic-usage.html#batching) sends each of its commands as it is: the same statements work there. Setting the `Npgsql.EnableSqlRewriting` switch to `false` also stops the splitting, and with it named parameters such as `@name`.
- A function is called in a query: `SELECT ci.failure_rate($1)`.
- [`CommandType.StoredProcedure`](https://www.npgsql.org/doc/basic-usage.html#stored-functions-and-procedures) generates `CALL`, since Npgsql 7.0: it runs the procedure, and returns its `OUT` parameters. On a function, the server answers `42809`, "is not a procedure", with the hint to use `SELECT`.

pgjdbc's parser also splits at semicolons, but not in a statement that contains `BEGIN ATOMIC` ([`Parser.java`, lines 147-149](https://github.com/pgjdbc/pgjdbc/blob/3297557c6a8059d0d6e3522c79f0bd9a6f82ee07/pgjdbc/src/main/java/org/postgresql/core/Parser.java#L147-L149) and [259-265](https://github.com/pgjdbc/pgjdbc/blob/3297557c6a8059d0d6e3522c79f0bd9a6f82ee07/pgjdbc/src/main/java/org/postgresql/core/Parser.java#L259-L265)). The other side of that choice: a string with a `BEGIN ATOMIC` function followed by other statements isn't split either, and the server refuses it as several commands in one prepared statement. The Java program sends each statement on its own. JDBC's escape syntax `{call …}` is where the two kinds of routines differ ([lines 15-65](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L08.java#L15-L65)):

```java
    static void routines() throws SQLException {
        try (Connection connection = DriverManager.getConnection(L04.url()); Statement statement = connection.createStatement()) {
            // One statement per call: the driver doesn't split a statement at the semicolons of BEGIN ATOMIC,
            // and doesn't split a string that contains one either
            statement.execute("DROP PROCEDURE IF EXISTS ci.count_runs");
            statement.execute("DROP FUNCTION IF EXISTS ci.failure_rate");
            statement.execute("""
                    CREATE FUNCTION ci.failure_rate(workflow text) RETURNS numeric
                    LANGUAGE sql STABLE
                    BEGIN ATOMIC
                        SELECT round(avg((conclusion = 'failure')::int), 2) FROM ci.runs WHERE workflow_name = workflow;
                    END
                    """);
            statement.execute("""
                    CREATE PROCEDURE ci.count_runs(workflow text, OUT runs bigint, OUT failures bigint)
                    LANGUAGE sql
                    BEGIN ATOMIC
                        SELECT count(*), count(*) FILTER (WHERE conclusion = 'failure') FROM ci.runs WHERE workflow_name = workflow;
                    END
                    """);

            // {? = call f(?)} runs a function: the driver sends SELECT
            try (CallableStatement call = connection.prepareCall("{? = call ci.failure_rate(?)}")) {
                call.registerOutParameter(1, Types.NUMERIC);
                call.setString(2, "Rust course examples");
                call.execute();
                System.out.println("{? = call ci.failure_rate(?)}: " + call.getBigDecimal(1));
            }

            // {call p(?, ?, ?)} on a procedure: with the default escapeSyntaxCallMode=select, the driver still sends SELECT
            try (CallableStatement call = connection.prepareCall("{call ci.count_runs(?, ?, ?)}")) {
                call.setString(1, "Rust course examples");
                call.registerOutParameter(2, Types.BIGINT);
                call.registerOutParameter(3, Types.BIGINT);
                call.execute();
            } catch (SQLException e) {
                System.out.println("{call ci.count_runs(?, ?, ?)}, escapeSyntaxCallMode=select: " + e.getSQLState() + ": "
                        + e.getMessage().lines().findFirst().orElseThrow());
            }
        }

        try (Connection connection = DriverManager.getConnection(L04.url() + "&escapeSyntaxCallMode=callIfNoReturn");
             CallableStatement call = connection.prepareCall("{call ci.count_runs(?, ?, ?)}")) {
            call.setString(1, "Rust course examples");
            call.registerOutParameter(2, Types.BIGINT);
            call.registerOutParameter(3, Types.BIGINT);
            call.execute();
            System.out.println("{call ci.count_runs(?, ?, ?)}, escapeSyntaxCallMode=callIfNoReturn: runs = " + call.getLong(2)
                    + ", failures = " + call.getLong(3));
        }
    }
```

```text
{? = call ci.failure_rate(?)}: 0.17
{call ci.count_runs(?, ?, ?)}, escapeSyntaxCallMode=select: 42809: ERROR: ci.count_runs(character varying) is a procedure
{call ci.count_runs(?, ?, ?)}, escapeSyntaxCallMode=callIfNoReturn: runs = 18, failures = 3
```

With the default [`escapeSyntaxCallMode=select`](https://jdbc.postgresql.org/documentation/use/), pgjdbc turns every `{call …}` into a `SELECT`, which runs functions only. `callIfNoReturn` sends `CALL` when the escape has no `? =` return value, so `{call ci.count_runs(?, ?, ?)}` runs the procedure; `call` always sends `CALL`.

A trigger's error reaches the program with all its fields ([lines 93-131](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L08.cs#L93-L131)):

```text
23514: version 0.* of ModelContextProtocol is not an exact numeric version
hint: Pin a released version, such as 10.0.5.
where: PL/pgSQL function ga.check_pin() line 4 at RAISE
```

[`PostgresException`](https://www.npgsql.org/doc/api/Npgsql.PostgresException.html) has `SqlState`, `Hint` and `Where`: the application can test `PostgresErrorCodes.CheckViolation` and show the hint, instead of parsing a message.

## Extensions

An [extension](https://www.postgresql.org/docs/18/extend-extensions.html) packages types, functions, operators and index methods: `pg_trgm`, `unaccent`, `pgstattuple` and `pageinspect` in the previous lessons. Some are *trusted*: a role with `CREATE` on the database can install them without being a superuser ([lines 156-169](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L156-L169)):

```sql
-- Extensions: some are trusted, and a role with CREATE on the database can install them without being a superuser
SELECT v.name, v.version, v.trusted
FROM pg_available_extension_versions AS v
JOIN pg_available_extensions AS e ON e.name = v.name AND e.default_version = v.version
WHERE v.name IN ('pg_trgm', 'unaccent', 'pgcrypto', 'hstore', 'pageinspect', 'pg_stat_statements', 'postgres_fdw', 'plpgsql')
ORDER BY v.name;

CREATE ROLE app LOGIN;
GRANT CREATE ON DATABASE learn TO app;
SET ROLE app;
CREATE EXTENSION pg_trgm;
CREATE EXTENSION pageinspect;
RESET ROLE;
SELECT extname, extowner::regrole AS owner, extversion FROM pg_extension ORDER BY extname;
```

```text
        name        | version | trusted
--------------------+---------+---------
 hstore             | 1.8     | t
 pageinspect        | 1.13    | f
 pg_stat_statements | 1.12    | f
 pg_trgm            | 1.6     | t
 pgcrypto           | 1.4     | t
 plpgsql            | 1.0     | t
 postgres_fdw       | 1.2     | f
 unaccent           | 1.1     | t
(8 rows)

CREATE ROLE
GRANT
SET
CREATE EXTENSION
ERROR:  permission denied to create extension "pageinspect"
HINT:  Must be superuser to create this extension.
RESET
  extname   |  owner   | extversion
------------+----------+------------
 btree_gist | postgres | 1.8
 pg_trgm    | app      | 1.6
 plpgsql    | postgres | 1.0
(3 rows)
```

`pg_trgm` is trusted, and belongs to `app` once installed. `pageinspect` reads raw pages, and needs a superuser. [`pg_available_extension_versions`](https://www.postgresql.org/docs/18/view-pg-available-extension-versions.html) lists what the server can install, and `pg_extension` what the database has. SQL Server's CLR assemblies run .NET code inside the server; PostgreSQL's extensions are mostly C libraries installed on the server's file system, which a managed service chooses for you.

## pgvector

[pgvector](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md) adds a `vector` type, distance operators and two approximate index methods. It isn't in the official image: [`sql/08-pgvector.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql) runs on `pgvector/pgvector:0.8.6-pg18-trixie`, the same PostgreSQL 18.6 with the extension built in. Stop the course server first, since both use port 5432:

```bash
bash server.sh stop
PG_IMAGE=pgvector/pgvector:0.8.6-pg18-trixie bash server.sh start
bash check.sh pgvector
```

On Windows, run these in Git Bash, as in [lesson 1](../01-getting-started/).

### Vectors and distances

[Lines 6-15](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L6-L15):

```sql
CREATE EXTENSION vector;
SELECT extversion FROM pg_extension WHERE extname = 'vector';

-- A vector is a list of float4 values with a fixed number of dimensions; <-> is the Euclidean distance,
-- <=> the cosine distance, <#> the negative inner product
SELECT '[1,0,0,1]'::vector AS v,
       '[1,0,0,1]'::vector <-> '[1,1,0,0]' AS l2,
       '[1,0,0,1]'::vector <=> '[1,1,0,0]' AS cosine,
       '[1,0,0,1]'::vector <#> '[1,1,0,0]' AS negative_inner_product;
SELECT '[1,2,3]'::vector <-> '[1,2]';
```

```text
CREATE EXTENSION
 extversion
------------
 0.8.6
(1 row)

     v     |         l2         | cosine | negative_inner_product
-----------+--------------------+--------+------------------------
 [1,0,0,1] | 1.4142135623730951 |    0.5 |                     -1
(1 row)

ERROR:  different vector dimensions 3 and 2
```

`<->` is the Euclidean distance, `<=>` the cosine distance, one minus the cosine of the angle, and `<#>` the inner product with its sign changed, so that smaller is closer for all three: PostgreSQL's index scans only return rows in ascending order of an operator. Vectors of different sizes can't be compared.

### Chords as vectors

Embeddings from a language model have hundreds of dimensions that no one can read. A chord has a small, readable one: 12 dimensions, 1 for each pitch class it contains ([lines 17-36](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L17-L36)):

```sql
-- A chord as a 12-dimension vector: 1 for each pitch class it contains, from C (0) to B (11)
CREATE FUNCTION ga.pitch_class_vector(pitch_classes smallint[]) RETURNS vector(12)
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
    SELECT array_agg((pc = ANY(pitch_classes))::int ORDER BY pc)::vector(12)
    FROM generate_series(0, 11) AS pc;
END;

ALTER TABLE ga.iconic_chords
    ADD COLUMN profile vector(12) GENERATED ALWAYS AS (ga.pitch_class_vector(pitch_classes::smallint[])) STORED;
SELECT name, pitch_classes, profile FROM ga.iconic_chords ORDER BY chord_id LIMIT 3;

-- The chords closest to the Hendrix chord: the inner product of two such vectors counts their common notes
SELECT c.name, c.theoretical_name,
       round((c.profile <=> h.profile)::numeric, 3) AS cosine_distance,
       -(c.profile <#> h.profile) AS common_notes
FROM ga.iconic_chords AS c, ga.iconic_chords AS h
WHERE h.name = 'Hendrix Chord' AND c.chord_id <> h.chord_id
ORDER BY c.profile <=> h.profile, c.name
LIMIT 5;
```

```text
CREATE FUNCTION
ALTER TABLE
       name       | pitch_classes |          profile
------------------+---------------+---------------------------
 Hendrix Chord    | {4,8,11,2,7}  | [0,0,1,0,1,0,0,1,1,0,0,1]
 James Bond Chord | {4,7,11,3}    | [0,0,0,1,1,0,0,1,0,0,0,1]
 Tristan Chord    | {5,11,3,8}    | [0,0,0,1,0,1,0,0,1,0,0,1]
(3 rows)

      name       | theoretical_name | cosine_distance | common_notes
-----------------+------------------+-----------------+--------------
 Debussy Chord   | Cmaj9            |           0.200 |            4
 So What Chord   | Em11             |           0.200 |            4
 Blackbird Chord | G/B              |           0.225 |            3
 Cowboy Chord    | G                |           0.225 |            3
 Elektra Chord   | E7b9#11          |           0.270 |            4
(5 rows)
```

The function is `IMMUTABLE`, so a stored generated column can use it. For vectors of 0 and 1, the inner product counts the notes two chords share, and the cosine distance scales it by their sizes: the Debussy and So What chords share four of the Hendrix chord's five notes. `c.name` breaks the ties, which are frequent with such small vectors.

### HNSW

An index on every set of pitch classes, 4,095 of them ([lines 38-56](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L38-L56)):

```sql
-- An HNSW index on every set of pitch classes: 4,095 non-empty sets
CREATE TABLE ga.pitch_class_sets (
    set_id        integer PRIMARY KEY,
    pitch_classes smallint[] NOT NULL,
    profile       vector(12) NOT NULL
);
INSERT INTO ga.pitch_class_sets
SELECT s, p.pitch_classes, ga.pitch_class_vector(p.pitch_classes)
FROM generate_series(1, 4095) AS s,
     LATERAL (SELECT array_agg(pc::smallint ORDER BY pc) AS pitch_classes
              FROM generate_series(0, 11) AS pc WHERE s & (1 << pc) <> 0) AS p;
CREATE INDEX pitch_class_sets_profile ON ga.pitch_class_sets USING hnsw (profile vector_cosine_ops);
ANALYZE ga.pitch_class_sets;

-- ORDER BY distance LIMIT uses the index; the operator must match the index's operator class
EXPLAIN (COSTS OFF)
SELECT set_id FROM ga.pitch_class_sets ORDER BY profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]' LIMIT 5;
EXPLAIN (COSTS OFF)
SELECT set_id FROM ga.pitch_class_sets ORDER BY profile <-> '[0,0,1,0,1,0,0,1,1,0,0,1]' LIMIT 5;
```

```text
CREATE TABLE
INSERT 0 4095
CREATE INDEX
ANALYZE
                             QUERY PLAN
---------------------------------------------------------------------
 Limit
   ->  Index Scan using pitch_class_sets_profile on pitch_class_sets
         Order By: (profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]'::vector)
(3 rows)

                              QUERY PLAN
-----------------------------------------------------------------------
 Limit
   ->  Sort
         Sort Key: ((profile <-> '[0,0,1,0,1,0,0,1,1,0,0,1]'::vector))
         ->  Seq Scan on pitch_class_sets
(4 rows)
```

[HNSW](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md#hnsw) builds a graph of layers where each vector links to its near neighbours, and a search walks it. It's approximate: it may miss a true neighbour. The operator class chooses the distance, `vector_cosine_ops` here, and only that operator uses the index: the query with `<->` sorts the whole table. The plans have no costs or buffers: HNSW places each vector in a random layer, so the index is a little different at each build.

### Filters and iterative scans

A nearest-neighbour search with a `WHERE` ([lines 58-82](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L58-L82)):

```sql
-- On 4,095 rows a filtered query reads the table; without that choice, a filter applies to what the index returns:
-- the hnsw.ef_search nearest rows (40 by default), none of which is a triad here
SET enable_seqscan = off;
EXPLAIN (COSTS OFF)
SELECT set_id FROM ga.pitch_class_sets
WHERE cardinality(pitch_classes) = 3
ORDER BY profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]'
LIMIT 10;
SELECT count(*) AS triads
FROM (SELECT set_id FROM ga.pitch_class_sets
      WHERE cardinality(pitch_classes) = 3
      ORDER BY profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]'
      LIMIT 10) AS nearest;

-- Iterative index scans (pgvector 0.8) keep reading the index until enough rows pass the filter
SET hnsw.iterative_scan = strict_order;
SELECT pitch_classes, distance
FROM (SELECT pitch_classes, round((profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]')::numeric, 3) AS distance
      FROM ga.pitch_class_sets
      WHERE cardinality(pitch_classes) = 3
      ORDER BY profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]'
      LIMIT 10) AS nearest
ORDER BY distance, pitch_classes;
RESET hnsw.iterative_scan;
RESET enable_seqscan;
```

```text
SET
                             QUERY PLAN
---------------------------------------------------------------------
 Limit
   ->  Index Scan using pitch_class_sets_profile on pitch_class_sets
         Order By: (profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]'::vector)
         Filter: (cardinality(pitch_classes) = 3)
(4 rows)

 triads
--------
      0
(1 row)

SET
 pitch_classes | distance
---------------+----------
 {2,4,7}       |    0.225
 {2,4,8}       |    0.225
 {2,4,11}      |    0.225
 {2,7,8}       |    0.225
 {2,7,11}      |    0.225
 {2,8,11}      |    0.225
 {4,7,8}       |    0.225
 {4,7,11}      |    0.225
 {4,8,11}      |    0.225
 {7,8,11}      |    0.225
(10 rows)

RESET
RESET
```

The index returns the `hnsw.ef_search` nearest candidates, 40 by default, and the filter applies to those, after the index scan. The 40 sets nearest to the Hendrix chord have four notes or more, so the query returns no triad at all, where ten were asked for. The README says it plainly: "filtering is applied *after* the index is scanned". On 4,095 rows the planner prefers a sequential scan anyway, which gives exact results; `enable_seqscan = off` shows what a large table would do.

[Iterative index scans](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md#iterative-index-scans), since pgvector 0.8.0, keep scanning the index until enough rows pass the filter: `strict_order` returns them in exact distance order, `relaxed_order` gives better recall with rows slightly out of order. The ten triads are the ten subsets of three notes of the Hendrix chord. SQL Server 2025's `VECTOR_SEARCH`, in preview, also applies predicates after the search, and filters during the search only in Azure SQL Database and Fabric ([`VECTOR_SEARCH`](https://learn.microsoft.com/sql/t-sql/functions/vector-search-transact-sql)).

## On Aurora

*To verify: nothing in this section ran on AWS.* Functions, procedures, PL/pgSQL and triggers are PostgreSQL's, and behave as in this lesson. Extensions are where Aurora differs most.

- **No superuser.** The master user has the [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html) role, and is created `NOSUPERUSER`; it can "add extensions that are available for use with Aurora PostgreSQL". Only the extensions in [the version's table](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) exist: `pageinspect`, which `app` couldn't install in this lesson, isn't in the table for Aurora PostgreSQL 18 at all.
- **Who may install what.** The `rds.allowed_extensions` parameter limits which extensions can be installed ([working with extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.html)). The RDS for PostgreSQL guide explains that its default, `*`, allows all of them, and that with trusted extensions "users can install many extensions if they have the `CREATE` privilege on the current database instead of requiring the `rds_superuser` role" ([extensions on RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.FeatureSupport.Extensions.html)); that Aurora behaves the same is *to verify*. [Delegated extension management](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora_delegated_ext.html) adds an `rds_extension` role for users who manage extensions without `rds_superuser`.
- **Extensions of your own.** A managed service doesn't load your C libraries. [Trusted Language Extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_trusted_language_extension.html), `pg_tle` 1.5.2 on 18.4, package code written in trusted languages as extensions, since Aurora PostgreSQL 14.5.
- **pgvector 0.8.2.** The [Aurora PostgreSQL 18.4 release notes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Updates.html), from August 21, 2026, updated pgvector "to version 0.8.2"; this lesson ran 0.8.6. Iterative scans date from 0.8.0 and are there; what came after 0.8.2 isn't. [Aurora Optimized Reads](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.optimized.reads.html) caches pages on local NVMe storage on R6gd, R8gd and R6id instances, and lists searches "across millions of vector embeddings" among its uses; its version list doesn't include 18 yet.
- **Calling AWS from SQL.** The [`aws_lambda`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL-Lambda.html) extension, 2.1 on 18.4, invokes a Lambda function from a query, "synchronously or asynchronously, depending on the `invocation_type`". Called synchronously from a trigger, it keeps the transaction and its locks open while it waits.

## Key takeaways

- `BEGIN ATOMIC` bodies are parsed once and record their dependencies; string bodies are checked at each call.
- Declare volatility: `IMMUTABLE` functions can be indexed and used in generated columns.
- PL/pgSQL's `EXCEPTION` catches errors by name, in a subtransaction.
- Procedures run with `CALL` and can commit, when they start the transaction.
- `BEFORE` row triggers change or reject rows; statement triggers with transition tables see every changed row.
- Npgsql splits a parameterless command at semicolons, including those of `BEGIN ATOMIC`: use `NpgsqlBatch`. pgjdbc needs `escapeSyntaxCallMode` to `CALL` a procedure.
- Trusted extensions install without a superuser; a managed service decides which extensions exist.
- pgvector's HNSW index is approximate, and filters apply after it: iterative scans fix the missing rows.

## Exercises

The solutions are in [`sql/08-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql) and, for the last one, [`sql/08-pgvector-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector-exercises.sql).

1. Write a SQL function `ci.slowest_steps(workflow, n)` that returns the `n` slowest steps of a workflow, with their job and duration. Use it to show the slowest step of each workflow, and keep the five slowest.

<details>
<summary>Solution</summary>

[Lines 6-24](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql#L6-L24):

```sql
-- Exercise 1: a set-returning SQL function, called once per workflow with LATERAL
CREATE FUNCTION ci.slowest_steps(workflow text, n integer)
RETURNS TABLE (job text, step text, duration interval)
LANGUAGE sql STABLE
BEGIN ATOMIC
    SELECT j.name, s.name, s.completed_at - s.started_at
    FROM ci.steps AS s
    JOIN ci.jobs AS j USING (job_id)
    JOIN ci.runs AS r USING (run_id)
    WHERE r.workflow_name = workflow
    ORDER BY s.completed_at - s.started_at DESC, j.name, s.name
    LIMIT n;
END;

SELECT w.workflow_name, slowest.*
FROM (SELECT DISTINCT workflow_name FROM ci.runs) AS w
CROSS JOIN LATERAL ci.slowest_steps(w.workflow_name, 1) AS slowest
ORDER BY slowest.duration DESC, w.workflow_name
LIMIT 5;
```

```text
CREATE FUNCTION
      workflow_name      |              job               |                    step                     | duration
-------------------------+--------------------------------+---------------------------------------------+----------
 Java course examples    | java-for-csharp (macos-latest) | Lesson 10 builds                            | 00:02:38
 GHA 09: debugging       | timeout                        | Run sleep 90                                | 00:01:27
 GHA 09: exercise checks | job-timeout                    | Run date -u +%T                             | 00:01:27
 Deploy to GitHub Pages  | deploy                         | Deploy to GitHub Pages                      | 00:01:14
 GHA 03: triggers        | show                           | Slow step (to see concurrency cancel a run) | 00:01:00
(5 rows)
```

`RETURNS TABLE (…)` is a table-valued function, and `CROSS JOIN LATERAL` calls it once per workflow, as `CROSS APPLY` does. Its `ORDER BY` breaks ties by job and step name, so `LIMIT n` always keeps the same rows. The two `GHA 09` steps of 87 seconds belong to jobs that demonstrate timeouts.

</details>

2. Add a trigger to `ga.package_pins` that refuses to lower a pinned version. Try `Npgsql` from 10.0.3 to 9.0.4, then `MongoDB.Driver` from 3.5.0 to 3.10.0.

<details>
<summary>Solution</summary>

[Lines 26-60](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql#L26-L60):

```sql
-- Exercise 2: a trigger that refuses to lower a pinned version
CREATE FUNCTION ga.version_numbers(version text) RETURNS integer[]
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
BEGIN
    RETURN string_to_array(version, '.')::integer[];
EXCEPTION
    WHEN invalid_text_representation THEN
        RETURN NULL;
END
$$;

CREATE TABLE ga.package_pins (
    package text PRIMARY KEY,
    version text NOT NULL
);

CREATE FUNCTION ga.refuse_downgrade() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF ga.version_numbers(NEW.version) < ga.version_numbers(OLD.version) THEN
        RAISE EXCEPTION '% can''t go from % down to %', NEW.package, OLD.version, NEW.version
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END
$$;
CREATE TRIGGER refuse_downgrade BEFORE UPDATE OF version ON ga.package_pins
    FOR EACH ROW WHEN (OLD.version IS DISTINCT FROM NEW.version) EXECUTE FUNCTION ga.refuse_downgrade();

INSERT INTO ga.package_pins VALUES ('Npgsql', '10.0.3'), ('MongoDB.Driver', '3.5.0');
UPDATE ga.package_pins SET version = '9.0.4' WHERE package = 'Npgsql';
UPDATE ga.package_pins SET version = '3.10.0' WHERE package = 'MongoDB.Driver';
SELECT * FROM ga.package_pins ORDER BY package;
```

```text
CREATE FUNCTION
CREATE TABLE
CREATE FUNCTION
CREATE TRIGGER
INSERT 0 2
ERROR:  Npgsql can't go from 10.0.3 down to 9.0.4
CONTEXT:  PL/pgSQL function ga.refuse_downgrade() line 4 at RAISE
UPDATE 1
    package     | version
----------------+---------
 MongoDB.Driver | 3.10.0
 Npgsql         | 10.0.3
(2 rows)
```

`BEFORE UPDATE OF version` fires only when the statement sets `version`, and `WHEN (…)` only for rows where it changed, without calling the function for the others. The comparison of integer arrays accepts 3.10.0 after 3.5.0, where a text comparison would have refused it, since `'3.10.0' < '3.5.0'`.

</details>

3. Write a procedure that inserts a row, commits, then inserts a row that violates the primary key. What's in the table after the error?

<details>
<summary>Solution</summary>

[Lines 62-74](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql#L62-L74):

```sql
-- Exercise 3: a procedure that fails after a COMMIT: what it committed stays
CREATE TABLE ci.counters (name text PRIMARY KEY, value bigint NOT NULL);
CREATE PROCEDURE ci.count_twice()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO ci.counters VALUES ('runs', (SELECT count(*) FROM ci.runs));
    COMMIT;
    INSERT INTO ci.counters VALUES ('runs', 0);
END
$$;
CALL ci.count_twice();
SELECT * FROM ci.counters ORDER BY name;
```

```text
CREATE TABLE
CREATE PROCEDURE
ERROR:  duplicate key value violates unique constraint "counters_pkey"
DETAIL:  Key (name)=(runs) already exists.
CONTEXT:  SQL statement "INSERT INTO ci.counters VALUES ('runs', 0)"
PL/pgSQL function ci.count_twice() line 5 at SQL statement
 name | value
------+-------
 runs |   125
(1 row)
```

The `CALL` fails, but the first row stays: it was committed before the error. Only the transaction started by the `COMMIT` rolls back. A caller that sees an error from a procedure can't assume that nothing happened, and a procedure that commits in the middle should be safe to run again.

</details>

4. On the pgvector image, write a function that computes a chord's [interval-class vector](https://en.wikipedia.org/wiki/Interval_vector): for each interval class from 1 (a semitone or a major seventh) to 6 (a tritone), the number of pairs of notes that form it. Which iconic chords have the same interval-class vector?

<details>
<summary>Solution</summary>

[`sql/08-pgvector-exercises.sql`, lines 7-28](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector-exercises.sql#L7-L28):

```sql
-- Exercise 4: the interval-class vector, which a transposition doesn't change
CREATE FUNCTION ga.interval_class_vector(pitch_classes smallint[]) RETURNS vector(6)
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
    SELECT array_agg((SELECT count(*)
                      FROM unnest(pitch_classes) AS a, unnest(pitch_classes) AS b
                      WHERE a < b AND least((b - a) % 12, (a - b + 12) % 12) = ic)::int ORDER BY ic)::vector(6)
    FROM generate_series(1, 6) AS ic;
END;

SELECT name, theoretical_name, ga.interval_class_vector(pitch_classes::smallint[]) AS icv
FROM ga.iconic_chords
ORDER BY chord_id;

-- Chords with the same intervals: distance 0, whatever their root
SELECT a.name, a.theoretical_name, b.name AS same_intervals_as, b.theoretical_name AS as_chord,
       a.pitch_classes = b.pitch_classes AS same_notes
FROM ga.iconic_chords AS a
JOIN ga.iconic_chords AS b
  ON a.chord_id < b.chord_id
 AND ga.interval_class_vector(a.pitch_classes::smallint[]) <-> ga.interval_class_vector(b.pitch_classes::smallint[]) = 0
ORDER BY a.chord_id, b.chord_id;
```

```text
           name           |   theoretical_name    |      icv
--------------------------+-----------------------+---------------
 Hendrix Chord            | E7#9                  | [1,1,3,2,2,1]
 James Bond Chord         | Em(maj7)              | [1,0,1,3,1,0]
 Tristan Chord            | F7#11                 | [0,1,2,1,1,1]
 Mystic Chord             | C6#11                 | [1,4,2,4,2,2]
 So What Chord            | Em11                  | [0,3,2,1,4,0]
 Mu Major Chord           | Cadd9(no3)            | [0,1,0,0,2,0]
 Elektra Chord            | E7b9#11               | [2,2,4,2,2,3]
 Petrushka Chord          | C/F# Polychord        | [2,2,4,2,2,3]
 Cowboy Chord             | G                     | [0,0,1,1,1,0]
 Power Chord              | G5                    | [0,0,0,0,1,0]
 Joni Mitchell Chord      | Dmaj7add6             | [1,2,2,2,3,0]
 Blackbird Chord          | G/B                   | [0,0,1,1,1,0]
 Evans Chord              | Dm9 (rootless)        | [1,0,1,2,2,0]
 A Hard Day's Night Chord | G7sus4add9            | [1,3,2,1,3,0]
 Foxy Lady Chord          | F#m7#9                | [1,2,2,2,3,0]
 Farben Chord             | Pentachord Op.16 No.3 | [2,0,2,4,2,0]
 Debussy Chord            | Cmaj9                 | [1,2,2,2,3,0]
(17 rows)

        name         | theoretical_name | same_intervals_as |    as_chord    | same_notes
---------------------+------------------+-------------------+----------------+------------
 Elektra Chord       | E7b9#11          | Petrushka Chord   | C/F# Polychord | f
 Cowboy Chord        | G                | Blackbird Chord   | G/B            | t
 Joni Mitchell Chord | Dmaj7add6        | Foxy Lady Chord   | F#m7#9         | f
 Joni Mitchell Chord | Dmaj7add6        | Debussy Chord     | Cmaj9          | f
 Foxy Lady Chord     | F#m7#9           | Debussy Chord     | Cmaj9          | f
(5 rows)
```

The interval class of two pitch classes is the shorter way around the circle of twelve. A transposition moves every note by the same interval, so it keeps the vector: a distance of 0 finds chords with the same intervals, whatever their root.

- The Cowboy and Blackbird chords have the same notes: G major, voiced differently.
- The Elektra chord, E and B♭ major together, is the Petrushka chord, C and F♯ major, transposed up a major third.
- The Joni Mitchell chord transposed down a whole tone gives the notes of the Debussy chord, and the Foxy Lady chord is its inversion: the same intervals, upside down, which the vector can't tell apart.

</details>

## Sources

- PostgreSQL 18 documentation: [SQL functions](https://www.postgresql.org/docs/18/xfunc-sql.html), [`CREATE FUNCTION`](https://www.postgresql.org/docs/18/sql-createfunction.html), [function volatility](https://www.postgresql.org/docs/18/xfunc-volatility.html), [procedures](https://www.postgresql.org/docs/18/xproc.html), [`CALL`](https://www.postgresql.org/docs/18/sql-call.html), [PL/pgSQL](https://www.postgresql.org/docs/18/plpgsql.html), [trapping errors](https://www.postgresql.org/docs/18/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING), [transaction management](https://www.postgresql.org/docs/18/plpgsql-transactions.html), [trigger functions](https://www.postgresql.org/docs/18/plpgsql-trigger.html), [`CREATE TRIGGER`](https://www.postgresql.org/docs/18/sql-createtrigger.html), [extensions](https://www.postgresql.org/docs/18/extend-extensions.html), [`pg_available_extension_versions`](https://www.postgresql.org/docs/18/view-pg-available-extension-versions.html)
- Npgsql: [basic usage](https://www.npgsql.org/doc/basic-usage.html), source at 10.0.3: [`SqlQueryParser.cs`, lines 137-139](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/SqlQueryParser.cs#L137-L139), [`NpgsqlCommand.cs`, lines 931-941](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/NpgsqlCommand.cs#L931-L941)
- pgjdbc: [connection parameters](https://jdbc.postgresql.org/documentation/use/), source at 42.7.13: [`Parser.java`, lines 147-149 and 259-265](https://github.com/pgjdbc/pgjdbc/blob/3297557c6a8059d0d6e3522c79f0bd9a6f82ee07/pgjdbc/src/main/java/org/postgresql/core/Parser.java#L147-L149)
- pgvector 0.8.6: [README](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md)
- SQL Server: [user-defined functions](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/user-defined-functions), [scalar UDF inlining](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/scalar-udf-inlining), [the inserted and deleted tables](https://learn.microsoft.com/sql/relational-databases/triggers/use-the-inserted-and-deleted-tables), [CLR integration](https://learn.microsoft.com/sql/relational-databases/clr-integration/common-language-runtime-integration-overview), [the `vector` data type](https://learn.microsoft.com/sql/t-sql/data-types/vector-data-type), [`CREATE VECTOR INDEX`](https://learn.microsoft.com/sql/t-sql/statements/create-vector-index-transact-sql), [`VECTOR_SEARCH`](https://learn.microsoft.com/sql/t-sql/functions/vector-search-transact-sql)
- AWS: [the `rds_superuser` role](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html), [extension versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), [working with extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.html), [extensions on RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.FeatureSupport.Extensions.html), [delegated extension management](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora_delegated_ext.html), [Trusted Language Extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_trusted_language_extension.html), [release notes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Updates.html), [Optimized Reads](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.optimized.reads.html), [`aws_lambda`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL-Lambda.html), all read on 2026-09-16
