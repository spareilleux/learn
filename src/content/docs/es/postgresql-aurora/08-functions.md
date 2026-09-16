---
title: "8. Funciones y extensiones"
description: Código del lado del servidor en PostgreSQL para desarrolladores T-SQL — funciones SQL con cuerpos BEGIN ATOMIC, PL/pgSQL con manejadores de excepciones, procedimientos que confirman, triggers de fila y de instrucción con tablas de transición, llamar a rutinas desde Npgsql y pgjdbc, extensiones de confianza — y pgvector, con índices HNSW y búsquedas filtradas sobre los acordes de Guitar Alchemist.
sidebar:
  order: 8
---

Los scripts de la lección son [`sql/08-functions.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql) y [`sql/08-pgvector.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql), los ejercicios están en [`sql/08-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql) y [`sql/08-pgvector-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector-exercises.sql), y los programas en [`csharp/L08.cs`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L08.cs) y [`java/…/L08.java`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L08.java). `check.sh` compara su salida con los archivos de los mismos nombres en [`expected`](https://github.com/spareilleux/learn/tree/a5e397e/code/postgresql-aurora/expected).

| SQL Server | PostgreSQL |
|---|---|
| función escalar, función con valores de tabla en línea | función SQL que devuelve un valor, una fila, filas `SETOF` o `TABLE (…)` |
| `WITH SCHEMABINDING` | un cuerpo `BEGIN ATOMIC`, cuyas dependencias quedan registradas |
| T-SQL, `TRY … CATCH`, `THROW` | PL/pgSQL, `EXCEPTION WHEN`, `RAISE` |
| procedimiento almacenado, `EXEC`, parámetros `OUTPUT` | procedimiento, `CALL`, parámetros `OUT`; las funciones no se ejecutan con `CALL` |
| `COMMIT` dentro de un procedimiento, con las reglas de `@@TRANCOUNT` | `COMMIT` dentro de un procedimiento llamado fuera de un bloque de transacción |
| triggers `AFTER` e `INSTEAD OF`, `inserted` y `deleted` | triggers `BEFORE`, `AFTER` e `INSTEAD OF`, por fila o por instrucción, tablas de transición |
| ensamblados CLR | extensiones, en C o en lenguajes de confianza |
| tipo `vector` y `CREATE VECTOR INDEX` (preview) en SQL Server 2025 | la extensión `pgvector`, índices HNSW e IVFFlat |

## Funciones SQL

Una [función SQL](https://www.postgresql.org/docs/18/xfunc-sql.html) con un cuerpo estándar, escrito entre `BEGIN ATOMIC` y `END`. Calcula las clases de altura que toca una digitación de guitarra, la consulta del [primer ejercicio de la lección 3](../03-queries/#ejercicios) ([líneas 7-19](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L7-L19)):

```sql
-- Una función SQL con un cuerpo estándar: se analiza al crearla, y sus dependencias quedan registradas
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

[`CREATE FUNCTION`](https://www.postgresql.org/docs/18/sql-createfunction.html) declara una volatilidad: `IMMUTABLE`, el mismo resultado para los mismos argumentos para siempre, lo que permite que un índice use la función ([lección 5](../05-indexes/#índices-sobre-expresiones)); `STABLE`, el mismo resultado dentro de una instrucción; `VOLATILE`, el valor por defecto. `STRICT` devuelve `NULL` sin ejecutar el cuerpo cuando un argumento es `NULL`.

La forma más antigua escribe el cuerpo como una cadena, `AS $$ … $$`, que PostgreSQL guarda como texto y vuelve a analizar cuando se ejecuta la función. Un cuerpo `BEGIN ATOMIC` se analiza cuando se crea la función, y PostgreSQL registra de qué depende ([líneas 21-27](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L21-L27)):

```sql
-- Un cuerpo estándar se guarda analizado, con sus dependencias: una columna que lee no se puede eliminar
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

La columna no se puede eliminar mientras la función la lea, como con el `SCHEMABINDING` de SQL Server. Un cuerpo en cadena se habría aceptado, y habría fallado en su siguiente llamada.

## PL/pgSQL

[PL/pgSQL](https://www.postgresql.org/docs/18/plpgsql.html) añade variables, bucles y manejo de errores. Una función que convierte una cadena de versión en un array de números, y en `NULL` cuando no puede ([líneas 29-49](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L29-L49)):

```sql
-- PL/pgSQL: variables, bucles, y un manejador de excepciones que convierte una conversión fallida en NULL
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

- `DECLARE` enumera las variables; `:=` asigna.
- La conversión `'0-preview'::integer` lanza `invalid_text_representation`, SQLSTATE `22P02`. El bloque [`EXCEPTION`](https://www.postgresql.org/docs/18/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING) la captura por su nombre, como `BEGIN CATCH`, y devuelve `NULL`.
- `RAISE NOTICE` envía un mensaje al cliente, que `psql` imprime; Npgsql lanza su evento `Notice`. Es `PRINT` en T-SQL.

Un bloque con una cláusula `EXCEPTION` se ejecuta en una subtransacción, que cuesta más que un bloque sin ella: resérvalos para donde se espera un error.

Los arrays de enteros se comparan elemento a elemento, que es como se comparan las versiones. La [lección 3](../03-queries/) vio que el máximo textual no es la versión más alta; con la función ([líneas 51-56](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L51-L56)):

```sql
-- La versión más alta por paquete de la lección 3, con la función
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

`DESC NULLS LAST` pone las versiones que no son números simples, como `0.*`, después de las demás. Los avisos se imprimen mientras el agregado lee las filas.

## Procedimientos y transacciones

Un [procedimiento](https://www.postgresql.org/docs/18/xproc.html) se ejecuta con [`CALL`](https://www.postgresql.org/docs/18/sql-call.html), no devuelve ningún valor y, a diferencia de una función, puede confirmar. Archivar las ejecuciones fallidas en lotes de cinco, una transacción por lote ([líneas 58-84](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L58-L84)):

```sql
-- Un procedimiento puede confirmar: CALL archiva las ejecuciones fallidas por lotes, una transacción por lote
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

`GET DIAGNOSTICS moved = ROW_COUNT` es `@@ROWCOUNT`. Cada `COMMIT` termina la transacción del lote y empieza una nueva: un proceso largo que confirma sobre la marcha evita que se acumulen sus versiones de fila ([lección 6](../06-transactions/#bloat)), y un fallo solo pierde el lote en curso.

Solo funciona cuando `CALL` es el inicio de la transacción ([líneas 86-90](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L86-L90)):

```sql
-- Dentro de un bloque de transacción explícito, el procedimiento no puede confirmar
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

Dentro de `BEGIN`, el procedimiento no puede confirmar una transacción que no empezó él ([gestión de transacciones](https://www.postgresql.org/docs/18/plpgsql-transactions.html)).

## Triggers

Fijaciones de paquetes que deben indicar una versión exacta, y una tabla de auditoría ([líneas 92-119](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L92-L119)):

```sql
-- Triggers: fijaciones de paquetes que deben indicar una versión exacta, y una auditoría de cada cambio
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

-- Un trigger BEFORE a nivel de fila puede modificar la fila o rechazarla
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

Un [trigger](https://www.postgresql.org/docs/18/plpgsql-trigger.html) en PostgreSQL es una función que devuelve `trigger`, asociada a una tabla por `CREATE TRIGGER`. Un trigger `BEFORE … FOR EACH ROW` ve como `NEW` la fila que se va a escribir, puede modificarla, como hace aquí `trim`, o rechazarla con un error. SQL Server no tiene trigger `BEFORE`; lo más parecido es un trigger `INSTEAD OF` que reescribe la instrucción.

Un trigger `AFTER` a nivel de instrucción ve todas las filas modificadas a la vez, en [tablas de transición](https://www.postgresql.org/docs/18/sql-createtrigger.html) nombradas por `REFERENCING`: `inserted` y `deleted` en SQL Server ([líneas 121-154](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L121-L154)):

```sql
-- Un trigger AFTER a nivel de instrucción ve todas las filas modificadas a la vez, en tablas de transición, como inserted y deleted en T-SQL
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

- El `INSERT` de tres fijaciones pasó; `' 10.0.3 '` se guardó como `10.0.3`.
- La versión preview se rechazó con SQLSTATE `23514`, `check_violation`, y la pista.
- El `UPDATE` tocó tres filas y cambió una: la auditoría solo conserva las filas cuya versión cambió.
- Un trigger por evento: un trigger que pide tablas de transición no puede enumerar varios eventos con `OR`.

## Rutinas desde C# y Java

Los drivers llaman a funciones y procedimientos de formas distintas, y uno de ellos tropieza con `BEGIN ATOMIC` ([líneas 9-91](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L08.cs#L9-L91)):

```csharp
    // Las rutinas de este ejemplo, creadas en cada ejecución
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
        // Npgsql corta el texto de un comando sin parámetros en cada punto y coma, para enviar las instrucciones como un lote:
        // también corta CREATE FUNCTION en el punto y coma de dentro de BEGIN ATOMIC
        try
        {
            await using var create = new NpgsqlCommand(Setup[2], connection);
            await create.ExecuteNonQueryAsync();
        }
        catch (PostgresException e)
        {
            Console.WriteLine($"CREATE FUNCTION ... BEGIN ATOMIC in an NpgsqlCommand: {e.SqlState}: {e.MessageText}");
        }
        // Los comandos de un NpgsqlBatch se envían tal cual
        await using (var batch = new NpgsqlBatch(connection))
        {
            foreach (var sql in Setup)
            {
                batch.BatchCommands.Add(new NpgsqlBatchCommand(sql));
            }
            await batch.ExecuteNonQueryAsync();
            Console.WriteLine("the same statements in an NpgsqlBatch: created");
        }

        // Una función se llama en una consulta, como cualquier expresión
        await using (var command = new NpgsqlCommand("SELECT ci.failure_rate($1)", connection))
        {
            command.Parameters.Add(new() { Value = "Rust course examples" });
            Console.WriteLine($"SELECT ci.failure_rate($1): {await command.ExecuteScalarAsync()}");
        }

        // CommandType.StoredProcedure genera CALL, que solo ejecuta procedimientos
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

- El `CREATE FUNCTION` falla en un `NpgsqlCommand`. Un comando sin parámetros puede contener varias instrucciones separadas por punto y coma, y Npgsql corta su texto en cada punto y coma que no esté dentro de paréntesis, de una cadena o de un comentario, para enviar las instrucciones como un lote ([`SqlQueryParser.cs`, líneas 137-139](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/SqlQueryParser.cs#L137-L139), y [`NpgsqlCommand.cs`, líneas 931-941](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/NpgsqlCommand.cs#L931-L941)). El punto y coma después del `SELECT` en `BEGIN ATOMIC` corta la instrucción en dos, y el servidor ve que `CREATE FUNCTION … BEGIN ATOMIC SELECT …` termina sin su `END`.
- Un [`NpgsqlBatch`](https://www.npgsql.org/doc/basic-usage.html#batching) envía cada uno de sus comandos tal cual: las mismas instrucciones funcionan ahí. Poner el switch `Npgsql.EnableSqlRewriting` a `false` también detiene el corte, y con él los parámetros con nombre como `@name`.
- Una función se llama en una consulta: `SELECT ci.failure_rate($1)`.
- [`CommandType.StoredProcedure`](https://www.npgsql.org/doc/basic-usage.html#stored-functions-and-procedures) genera `CALL`, desde Npgsql 7.0: ejecuta el procedimiento, y devuelve sus parámetros `OUT`. Sobre una función, el servidor responde `42809`, «is not a procedure», con la pista de usar `SELECT`.

El analizador de pgjdbc también corta en los punto y coma, pero no en una instrucción que contiene `BEGIN ATOMIC` ([`Parser.java`, líneas 147-149](https://github.com/pgjdbc/pgjdbc/blob/3297557c6a8059d0d6e3522c79f0bd9a6f82ee07/pgjdbc/src/main/java/org/postgresql/core/Parser.java#L147-L149) y [259-265](https://github.com/pgjdbc/pgjdbc/blob/3297557c6a8059d0d6e3522c79f0bd9a6f82ee07/pgjdbc/src/main/java/org/postgresql/core/Parser.java#L259-L265)). La otra cara de esa decisión: una cadena con una función `BEGIN ATOMIC` seguida de otras instrucciones tampoco se corta, y el servidor la rechaza por tener varios comandos en una sentencia preparada. El programa Java envía cada instrucción por separado. La sintaxis de escape `{call …}` de JDBC es donde se diferencian los dos tipos de rutinas ([líneas 15-65](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L08.java#L15-L65)):

```java
    static void routines() throws SQLException {
        try (Connection connection = DriverManager.getConnection(L04.url()); Statement statement = connection.createStatement()) {
            // Una instrucción por llamada: el driver no corta una instrucción en los punto y coma de BEGIN ATOMIC,
            // y tampoco corta una cadena que contenga uno
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

            // {? = call f(?)} ejecuta una función: el driver envía SELECT
            try (CallableStatement call = connection.prepareCall("{? = call ci.failure_rate(?)}")) {
                call.registerOutParameter(1, Types.NUMERIC);
                call.setString(2, "Rust course examples");
                call.execute();
                System.out.println("{? = call ci.failure_rate(?)}: " + call.getBigDecimal(1));
            }

            // {call p(?, ?, ?)} sobre un procedimiento: con el valor por defecto escapeSyntaxCallMode=select, el driver sigue enviando SELECT
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

Con el valor por defecto [`escapeSyntaxCallMode=select`](https://jdbc.postgresql.org/documentation/use/), pgjdbc convierte cada `{call …}` en un `SELECT`, que solo ejecuta funciones. `callIfNoReturn` envía `CALL` cuando el escape no tiene valor de retorno `? =`, así que `{call ci.count_runs(?, ?, ?)}` ejecuta el procedimiento; `call` envía siempre `CALL`.

El error de un trigger llega al programa con todos sus campos ([líneas 93-131](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L08.cs#L93-L131)):

```text
23514: version 0.* of ModelContextProtocol is not an exact numeric version
hint: Pin a released version, such as 10.0.5.
where: PL/pgSQL function ga.check_pin() line 4 at RAISE
```

[`PostgresException`](https://www.npgsql.org/doc/api/Npgsql.PostgresException.html) tiene `SqlState`, `Hint` y `Where`: la aplicación puede comprobar `PostgresErrorCodes.CheckViolation` y mostrar la pista, en lugar de analizar un mensaje.

## Extensiones

Una [extensión](https://www.postgresql.org/docs/18/extend-extensions.html) empaqueta tipos, funciones, operadores y métodos de índice: `pg_trgm`, `unaccent`, `pgstattuple` y `pageinspect` en las lecciones anteriores. Algunas son *de confianza*: un rol con `CREATE` sobre la base de datos puede instalarlas sin ser superusuario ([líneas 156-169](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L156-L169)):

```sql
-- Extensiones: algunas son de confianza, y un rol con CREATE sobre la base de datos puede instalarlas sin ser superusuario
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

`pg_trgm` es de confianza, y pertenece a `app` una vez instalada. `pageinspect` lee páginas en bruto, y necesita un superusuario. [`pg_available_extension_versions`](https://www.postgresql.org/docs/18/view-pg-available-extension-versions.html) enumera lo que el servidor puede instalar, y `pg_extension` lo que tiene la base de datos. Los ensamblados CLR de SQL Server ejecutan código .NET dentro del servidor; las extensiones de PostgreSQL son sobre todo bibliotecas C instaladas en el sistema de archivos del servidor, que un servicio gestionado elige por ti.

## pgvector

[pgvector](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md) añade un tipo `vector`, operadores de distancia y dos métodos de índice aproximados. No está en la imagen oficial: [`sql/08-pgvector.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql) se ejecuta sobre `pgvector/pgvector:0.8.6-pg18-trixie`, el mismo PostgreSQL 18.6 con la extensión incluida. Detén antes el servidor del curso, ya que ambos usan el puerto 5432:

```bash
bash server.sh stop
PG_IMAGE=pgvector/pgvector:0.8.6-pg18-trixie bash server.sh start
bash check.sh pgvector
```

En Windows, ejecuta esto en Git Bash, como en la [lección 1](../01-getting-started/).

### Vectores y distancias

[Líneas 6-15](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L6-L15):

```sql
CREATE EXTENSION vector;
SELECT extversion FROM pg_extension WHERE extname = 'vector';

-- Un vector es una lista de valores float4 con un número fijo de dimensiones; <-> es la distancia euclídea,
-- <=> la distancia coseno, <#> el producto escalar negativo
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

`<->` es la distancia euclídea, `<=>` la distancia coseno, uno menos el coseno del ángulo, y `<#>` el producto escalar con el signo cambiado, para que en los tres casos menor signifique más cercano: los escaneos de índice de PostgreSQL solo devuelven filas en orden ascendente de un operador. No se pueden comparar vectores de tamaños distintos.

### Acordes como vectores

Los embeddings de un modelo de lenguaje tienen cientos de dimensiones que nadie puede leer. Un acorde tiene uno pequeño y legible: 12 dimensiones, 1 por cada clase de altura que contiene ([líneas 17-36](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L17-L36)):

```sql
-- Un acorde como vector de 12 dimensiones: 1 por cada clase de altura que contiene, de do (0) a si (11)
CREATE FUNCTION ga.pitch_class_vector(pitch_classes smallint[]) RETURNS vector(12)
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
    SELECT array_agg((pc = ANY(pitch_classes))::int ORDER BY pc)::vector(12)
    FROM generate_series(0, 11) AS pc;
END;

ALTER TABLE ga.iconic_chords
    ADD COLUMN profile vector(12) GENERATED ALWAYS AS (ga.pitch_class_vector(pitch_classes::smallint[])) STORED;
SELECT name, pitch_classes, profile FROM ga.iconic_chords ORDER BY chord_id LIMIT 3;

-- Los acordes más cercanos al acorde Hendrix: el producto escalar de dos de estos vectores cuenta sus notas comunes
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

La función es `IMMUTABLE`, así que una columna generada almacenada puede usarla. Para vectores de 0 y 1, el producto escalar cuenta las notas que comparten dos acordes, y la distancia coseno lo escala según sus tamaños: los acordes Debussy y So What comparten cuatro de las cinco notas del acorde Hendrix. `c.name` deshace los empates, que son frecuentes con vectores tan pequeños.

### HNSW

Un índice sobre todos los conjuntos de clases de altura, 4095 en total ([líneas 38-56](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L38-L56)):

```sql
-- Un índice HNSW sobre todos los conjuntos de clases de altura: 4095 conjuntos no vacíos
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

-- ORDER BY distance LIMIT usa el índice; el operador debe corresponder a la clase de operadores del índice
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

[HNSW](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md#hnsw) construye un grafo por capas donde cada vector se enlaza con sus vecinos cercanos, y una búsqueda lo recorre. Es aproximado: puede pasar por alto un vecino real. La clase de operadores elige la distancia, aquí `vector_cosine_ops`, y solo ese operador usa el índice: la consulta con `<->` ordena la tabla entera. Los planes no tienen costes ni búferes: HNSW coloca cada vector en una capa aleatoria, así que el índice es un poco distinto en cada construcción.

### Filtros y escaneos iterativos

Una búsqueda de vecinos más cercanos con un `WHERE` ([líneas 58-82](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L58-L82)):

```sql
-- Sobre 4095 filas una consulta filtrada lee la tabla; sin esa opción, un filtro se aplica a lo que devuelve el índice:
-- las hnsw.ef_search filas más cercanas (40 por defecto), ninguna de las cuales es aquí una tríada
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

-- Los escaneos de índice iterativos (pgvector 0.8) siguen leyendo el índice hasta que suficientes filas pasan el filtro
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

El índice devuelve los `hnsw.ef_search` candidatos más cercanos, 40 por defecto, y el filtro se aplica a esos, después del escaneo de índice. Los 40 conjuntos más cercanos al acorde Hendrix tienen cuatro notas o más, así que la consulta no devuelve ninguna tríada, donde se pedían diez. El README lo dice claramente: «filtering is applied *after* the index is scanned». Sobre 4095 filas el planificador prefiere de todos modos un escaneo secuencial, que da resultados exactos; `enable_seqscan = off` muestra lo que haría una tabla grande.

Los [escaneos de índice iterativos](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md#iterative-index-scans), desde pgvector 0.8.0, siguen recorriendo el índice hasta que suficientes filas pasan el filtro: `strict_order` las devuelve en orden exacto de distancia, `relaxed_order` da mejor recall con filas ligeramente desordenadas. Las diez tríadas son los diez subconjuntos de tres notas del acorde Hendrix. El `VECTOR_SEARCH` de SQL Server 2025, en preview, también aplica los predicados después de la búsqueda, y solo filtra durante la búsqueda en Azure SQL Database y Fabric ([`VECTOR_SEARCH`](https://learn.microsoft.com/sql/t-sql/functions/vector-search-transact-sql)).

## En Aurora

*Por verificar: nada de esta sección se ejecutó en AWS.* Las funciones, los procedimientos, PL/pgSQL y los triggers son los de PostgreSQL, y se comportan como en esta lección. Las extensiones son donde más difiere Aurora.

- **Sin superusuario.** El usuario maestro tiene el rol [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html), y se crea `NOSUPERUSER`; puede «add extensions that are available for use with Aurora PostgreSQL». Solo existen las extensiones de [la tabla de la versión](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html): `pageinspect`, que `app` no pudo instalar en esta lección, ni siquiera está en la tabla de Aurora PostgreSQL 18.
- **Quién puede instalar qué.** El parámetro `rds.allowed_extensions` limita qué extensiones se pueden instalar ([trabajar con extensiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.html)). La guía de RDS for PostgreSQL explica que su valor por defecto, `*`, las permite todas, y que con las extensiones de confianza «users can install many extensions if they have the `CREATE` privilege on the current database instead of requiring the `rds_superuser` role» ([extensiones en RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.FeatureSupport.Extensions.html)); que Aurora se comporte igual está *por verificar*. La [gestión delegada de extensiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora_delegated_ext.html) añade un rol `rds_extension` para los usuarios que gestionan extensiones sin `rds_superuser`.
- **Extensiones propias.** Un servicio gestionado no carga tus bibliotecas C. [Trusted Language Extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_trusted_language_extension.html), `pg_tle` 1.5.2 en 18.4, empaqueta como extensiones código escrito en lenguajes de confianza, desde Aurora PostgreSQL 14.5.
- **pgvector 0.8.2.** Las [notas de versión de Aurora PostgreSQL 18.4](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Updates.html), del 21 de agosto de 2026, actualizaron pgvector «to version 0.8.2»; esta lección se ejecutó con 0.8.6. Los escaneos iterativos datan de 0.8.0 y están disponibles; lo que llegó después de 0.8.2, no. [Aurora Optimized Reads](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.optimized.reads.html) guarda páginas en caché en almacenamiento NVMe local en las instancias R6gd, R8gd y R6id, y cita las búsquedas «across millions of vector embeddings» entre sus usos; su lista de versiones todavía no incluye la 18.
- **Llamar a AWS desde SQL.** La extensión [`aws_lambda`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL-Lambda.html), 2.1 en 18.4, invoca una función Lambda desde una consulta, «synchronously or asynchronously, depending on the `invocation_type`». Llamada de forma síncrona desde un trigger, mantiene abiertos la transacción y sus bloqueos mientras espera.

## Puntos clave

- Los cuerpos `BEGIN ATOMIC` se analizan una vez y registran sus dependencias; los cuerpos en cadena se comprueban en cada llamada.
- Declara la volatilidad: las funciones `IMMUTABLE` se pueden indexar y usar en columnas generadas.
- El `EXCEPTION` de PL/pgSQL captura los errores por su nombre, en una subtransacción.
- Los procedimientos se ejecutan con `CALL` y pueden confirmar, cuando empiezan la transacción.
- Los triggers de fila `BEFORE` modifican o rechazan filas; los triggers de instrucción con tablas de transición ven todas las filas modificadas.
- Npgsql corta un comando sin parámetros en los punto y coma, incluidos los de `BEGIN ATOMIC`: usa `NpgsqlBatch`. pgjdbc necesita `escapeSyntaxCallMode` para hacer `CALL` a un procedimiento.
- Las extensiones de confianza se instalan sin superusuario; un servicio gestionado decide qué extensiones existen.
- El índice HNSW de pgvector es aproximado, y los filtros se aplican después: los escaneos iterativos recuperan las filas que faltan.

## Ejercicios

Las soluciones están en [`sql/08-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql) y, para el último, en [`sql/08-pgvector-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector-exercises.sql).

1. Escribe una función SQL `ci.slowest_steps(workflow, n)` que devuelva los `n` pasos más lentos de un workflow, con su job y su duración. Úsala para mostrar el paso más lento de cada workflow, y quédate con los cinco más lentos.

<details>
<summary>Solución</summary>

[Líneas 6-24](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql#L6-L24):

```sql
-- Ejercicio 1: una función SQL que devuelve un conjunto de filas, llamada una vez por workflow con LATERAL
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

`RETURNS TABLE (…)` es una función con valores de tabla, y `CROSS JOIN LATERAL` la llama una vez por workflow, como hace `CROSS APPLY`. Su `ORDER BY` deshace los empates por nombre de job y de paso, así que `LIMIT n` conserva siempre las mismas filas. Los dos pasos de `GHA 09` de 87 segundos pertenecen a jobs que demuestran los tiempos límite.

</details>

2. Añade a `ga.package_pins` un trigger que se niegue a bajar una versión fijada. Prueba `Npgsql` de 10.0.3 a 9.0.4, y luego `MongoDB.Driver` de 3.5.0 a 3.10.0.

<details>
<summary>Solución</summary>

[Líneas 26-60](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql#L26-L60):

```sql
-- Ejercicio 2: un trigger que se niega a bajar una versión fijada
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

`BEFORE UPDATE OF version` solo se dispara cuando la instrucción asigna `version`, y `WHEN (…)` solo para las filas en que cambió, sin llamar a la función para las demás. La comparación de arrays de enteros acepta 3.10.0 después de 3.5.0, donde una comparación de texto la habría rechazado, ya que `'3.10.0' < '3.5.0'`.

</details>

3. Escribe un procedimiento que inserte una fila, confirme, y luego inserte una fila que viole la clave primaria. ¿Qué hay en la tabla después del error?

<details>
<summary>Solución</summary>

[Líneas 62-74](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql#L62-L74):

```sql
-- Ejercicio 3: un procedimiento que falla después de un COMMIT: lo que confirmó se queda
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

El `CALL` falla, pero la primera fila se queda: se confirmó antes del error. Solo se revierte la transacción iniciada por el `COMMIT`. Quien llama y ve un error de un procedimiento no puede suponer que no pasó nada, y un procedimiento que confirma a medio camino debería poder ejecutarse de nuevo sin riesgo.

</details>

4. En la imagen de pgvector, escribe una función que calcule el [vector de clases de intervalo](https://en.wikipedia.org/wiki/Interval_vector) de un acorde: para cada clase de intervalo de 1 (un semitono o una séptima mayor) a 6 (un tritono), el número de pares de notas que la forman. ¿Qué acordes icónicos tienen el mismo vector de clases de intervalo?

<details>
<summary>Solución</summary>

[`sql/08-pgvector-exercises.sql`, líneas 7-28](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector-exercises.sql#L7-L28):

```sql
-- Ejercicio 4: el vector de clases de intervalo, que una transposición no cambia
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

-- Acordes con los mismos intervalos: distancia 0, sea cual sea su fundamental
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

La clase de intervalo de dos clases de altura es el camino más corto alrededor del círculo de doce. Una transposición mueve cada nota el mismo intervalo, así que conserva el vector: una distancia de 0 encuentra acordes con los mismos intervalos, sea cual sea su fundamental.

- Los acordes Cowboy y Blackbird tienen las mismas notas: sol mayor, con otra disposición.
- El acorde Elektra, mi mayor y si♭ mayor juntos, es el acorde Petrushka, do mayor y fa♯ mayor, transpuesto una tercera mayor hacia arriba.
- El acorde Joni Mitchell transpuesto un tono hacia abajo da las notas del acorde Debussy, y el acorde Foxy Lady es su inversión: los mismos intervalos, del revés, que el vector no puede distinguir.

</details>

## Fuentes

- Documentación de PostgreSQL 18: [funciones SQL](https://www.postgresql.org/docs/18/xfunc-sql.html), [`CREATE FUNCTION`](https://www.postgresql.org/docs/18/sql-createfunction.html), [volatilidad de las funciones](https://www.postgresql.org/docs/18/xfunc-volatility.html), [procedimientos](https://www.postgresql.org/docs/18/xproc.html), [`CALL`](https://www.postgresql.org/docs/18/sql-call.html), [PL/pgSQL](https://www.postgresql.org/docs/18/plpgsql.html), [capturar errores](https://www.postgresql.org/docs/18/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING), [gestión de transacciones](https://www.postgresql.org/docs/18/plpgsql-transactions.html), [funciones de trigger](https://www.postgresql.org/docs/18/plpgsql-trigger.html), [`CREATE TRIGGER`](https://www.postgresql.org/docs/18/sql-createtrigger.html), [extensiones](https://www.postgresql.org/docs/18/extend-extensions.html), [`pg_available_extension_versions`](https://www.postgresql.org/docs/18/view-pg-available-extension-versions.html)
- Npgsql: [uso básico](https://www.npgsql.org/doc/basic-usage.html), código fuente en 10.0.3: [`SqlQueryParser.cs`, líneas 137-139](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/SqlQueryParser.cs#L137-L139), [`NpgsqlCommand.cs`, líneas 931-941](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/NpgsqlCommand.cs#L931-L941)
- pgjdbc: [parámetros de conexión](https://jdbc.postgresql.org/documentation/use/), código fuente en 42.7.13: [`Parser.java`, líneas 147-149 y 259-265](https://github.com/pgjdbc/pgjdbc/blob/3297557c6a8059d0d6e3522c79f0bd9a6f82ee07/pgjdbc/src/main/java/org/postgresql/core/Parser.java#L147-L149)
- pgvector 0.8.6: [README](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md)
- SQL Server: [funciones definidas por el usuario](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/user-defined-functions), [inserción en línea de UDF escalares](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/scalar-udf-inlining), [las tablas inserted y deleted](https://learn.microsoft.com/sql/relational-databases/triggers/use-the-inserted-and-deleted-tables), [integración CLR](https://learn.microsoft.com/sql/relational-databases/clr-integration/common-language-runtime-integration-overview), [el tipo de datos `vector`](https://learn.microsoft.com/sql/t-sql/data-types/vector-data-type), [`CREATE VECTOR INDEX`](https://learn.microsoft.com/sql/t-sql/statements/create-vector-index-transact-sql), [`VECTOR_SEARCH`](https://learn.microsoft.com/sql/t-sql/functions/vector-search-transact-sql)
- AWS: [el rol `rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html), [versiones de las extensiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), [trabajar con extensiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.html), [extensiones en RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.FeatureSupport.Extensions.html), [gestión delegada de extensiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora_delegated_ext.html), [Trusted Language Extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_trusted_language_extension.html), [notas de versión](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Updates.html), [Optimized Reads](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.optimized.reads.html), [`aws_lambda`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL-Lambda.html), todas consultadas el 2026-09-16
