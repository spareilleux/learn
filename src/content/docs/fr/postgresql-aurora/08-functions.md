---
title: "8. Fonctions et extensions"
description: Le code côté serveur de PostgreSQL pour les développeurs T-SQL — fonctions SQL à corps BEGIN ATOMIC, PL/pgSQL avec gestionnaires d'exceptions, procédures qui valident, triggers de ligne et d'instruction avec tables de transition, appel des routines depuis Npgsql et pgjdbc, extensions de confiance — et pgvector, avec des index HNSW et des recherches filtrées sur les accords de Guitar Alchemist.
sidebar:
  order: 8
---

Les scripts de la leçon sont [`sql/08-functions.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql) et [`sql/08-pgvector.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql), les exercices sont dans [`sql/08-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql) et [`sql/08-pgvector-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector-exercises.sql), et les programmes dans [`csharp/L08.cs`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L08.cs) et [`java/…/L08.java`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L08.java). `check.sh` compare leur sortie aux fichiers de mêmes noms dans [`expected`](https://github.com/spareilleux/learn/tree/a5e397e/code/postgresql-aurora/expected).

| SQL Server | PostgreSQL |
|---|---|
| fonction scalaire, fonction table en ligne | fonction SQL qui renvoie une valeur, une ligne, des lignes `SETOF` ou `TABLE (…)` |
| `WITH SCHEMABINDING` | un corps `BEGIN ATOMIC`, dont les dépendances sont enregistrées |
| T-SQL, `TRY … CATCH`, `THROW` | PL/pgSQL, `EXCEPTION WHEN`, `RAISE` |
| procédure stockée, `EXEC`, paramètres `OUTPUT` | procédure, `CALL`, paramètres `OUT` ; les fonctions ne s'exécutent pas avec `CALL` |
| `COMMIT` dans une procédure, avec les règles de `@@TRANCOUNT` | `COMMIT` dans une procédure appelée hors d'un bloc de transaction |
| triggers `AFTER` et `INSTEAD OF`, `inserted` et `deleted` | triggers `BEFORE`, `AFTER` et `INSTEAD OF`, par ligne ou par instruction, tables de transition |
| assemblys CLR | extensions, en C ou dans des langages de confiance |
| type `vector` et `CREATE VECTOR INDEX` (en préversion) dans SQL Server 2025 | l'extension `pgvector`, index HNSW et IVFFlat |

## Fonctions SQL

Une [fonction SQL](https://www.postgresql.org/docs/18/xfunc-sql.html) avec un corps standard, écrit entre `BEGIN ATOMIC` et `END`. Elle calcule les classes de hauteur que joue un doigté de guitare, la requête du [premier exercice de la leçon 3](../03-queries/#exercices) ([lignes 7-19](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L7-L19)) :

```sql
-- Une fonction SQL avec un corps standard : analysée à sa création, avec ses dépendances enregistrées
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

[`CREATE FUNCTION`](https://www.postgresql.org/docs/18/sql-createfunction.html) déclare une volatilité : `IMMUTABLE`, le même résultat pour les mêmes arguments pour toujours, ce qui permet à un index d'utiliser la fonction ([leçon 5](../05-indexes/#index-sur-des-expressions)) ; `STABLE`, le même résultat au sein d'une instruction ; `VOLATILE`, la valeur par défaut. `STRICT` renvoie `NULL` sans exécuter le corps quand un argument vaut `NULL`.

La forme plus ancienne écrit le corps comme une chaîne, `AS $$ … $$`, que PostgreSQL stocke comme du texte et analyse de nouveau quand la fonction s'exécute. Un corps `BEGIN ATOMIC` est analysé à la création de la fonction, et PostgreSQL enregistre ce dont il dépend ([lignes 21-27](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L21-L27)) :

```sql
-- Un corps standard est stocké analysé, avec ses dépendances : une colonne qu'il lit ne peut pas être supprimée
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

La colonne ne peut pas être supprimée tant que la fonction la lit, comme avec le `SCHEMABINDING` de SQL Server. Un corps en chaîne aurait été accepté, et aurait échoué à son appel suivant.

## PL/pgSQL

[PL/pgSQL](https://www.postgresql.org/docs/18/plpgsql.html) ajoute des variables, des boucles et la gestion des erreurs. Une fonction qui transforme une chaîne de version en tableau de nombres, et en `NULL` quand elle ne peut pas ([lignes 29-49](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L29-L49)) :

```sql
-- PL/pgSQL : variables, boucles, et un gestionnaire d'exception qui transforme une conversion ratée en NULL
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

- `DECLARE` liste les variables ; `:=` affecte.
- La conversion `'0-preview'::integer` lève `invalid_text_representation`, SQLSTATE `22P02`. Le bloc [`EXCEPTION`](https://www.postgresql.org/docs/18/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING) l'attrape par son nom, comme `BEGIN CATCH`, et renvoie `NULL`.
- `RAISE NOTICE` envoie un message au client, que `psql` affiche ; Npgsql déclenche son événement `Notice`. C'est le `PRINT` de T-SQL.

Un bloc avec une clause `EXCEPTION` s'exécute dans une sous-transaction, qui coûte plus cher qu'un bloc sans : garde-les là où une erreur est attendue.

Les tableaux d'entiers se comparent élément par élément, ce qui est la façon dont se comparent les versions. La [leçon 3](../03-queries/) a montré que le maximum textuel n'est pas la plus haute version ; avec la fonction ([lignes 51-56](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L51-L56)) :

```sql
-- La plus haute version par paquet de la leçon 3, avec la fonction
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

`DESC NULLS LAST` place les versions qui ne sont pas de simples nombres, comme `0.*`, après les autres. Les notices sont affichées pendant que l'agrégat lit les lignes.

## Procédures et transactions

Une [procédure](https://www.postgresql.org/docs/18/xproc.html) s'exécute avec [`CALL`](https://www.postgresql.org/docs/18/sql-call.html), ne renvoie pas de valeur et, contrairement à une fonction, peut valider. Archiver les exécutions en échec par lots de cinq, une transaction par lot ([lignes 58-84](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L58-L84)) :

```sql
-- Une procédure peut valider : CALL archive les exécutions en échec par lots, une transaction par lot
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

`GET DIAGNOSTICS moved = ROW_COUNT` est `@@ROWCOUNT`. Chaque `COMMIT` termine la transaction du lot et en commence une nouvelle : un long traitement qui valide au fur et à mesure empêche ses versions de lignes de s'accumuler ([leçon 6](../06-transactions/#bloat)), et un échec ne perd que le lot en cours.

Cela ne marche que quand `CALL` est le début de la transaction ([lignes 86-90](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L86-L90)) :

```sql
-- Dans un bloc de transaction explicite, la procédure ne peut pas valider
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

Dans un `BEGIN`, la procédure ne peut pas valider une transaction qu'elle n'a pas commencée ([gestion des transactions](https://www.postgresql.org/docs/18/plpgsql-transactions.html)).

## Triggers

Des épinglages de paquets qui doivent nommer une version exacte, et une table d'audit ([lignes 92-119](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L92-L119)) :

```sql
-- Triggers : des épinglages de paquets qui doivent nommer une version exacte, et un audit de chaque modification
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

-- Un trigger BEFORE au niveau ligne peut modifier la ligne ou la rejeter
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

Dans PostgreSQL, un [trigger](https://www.postgresql.org/docs/18/plpgsql-trigger.html) est une fonction qui renvoie `trigger`, attachée à une table par `CREATE TRIGGER`. Un trigger `BEFORE … FOR EACH ROW` voit la ligne sur le point d'être écrite sous le nom `NEW`, et peut la modifier, comme le fait `trim` ici, ou la rejeter avec une erreur. SQL Server n'a pas de trigger `BEFORE` ; un trigger `INSTEAD OF` qui réécrit l'instruction est ce qui s'en approche le plus.

Un trigger `AFTER` au niveau instruction voit toutes les lignes modifiées d'un coup, dans des [tables de transition](https://www.postgresql.org/docs/18/sql-createtrigger.html) nommées par `REFERENCING` : `inserted` et `deleted` dans SQL Server ([lignes 121-154](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L121-L154)) :

```sql
-- Un trigger AFTER au niveau instruction voit toutes les lignes modifiées d'un coup, dans des tables de transition, comme inserted et deleted en T-SQL
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

- L'`INSERT` de trois épinglages est passé ; `' 10.0.3 '` a été stocké comme `10.0.3`.
- La version preview a été rejetée avec le SQLSTATE `23514`, `check_violation`, et l'indice.
- L'`UPDATE` a touché trois lignes et en a changé une : l'audit ne garde que les lignes dont la version a changé.
- Un trigger par événement : un trigger qui demande des tables de transition ne peut pas lister plusieurs événements avec `OR`.

## Les routines depuis C# et Java

Les pilotes appellent les fonctions et les procédures de façons différentes, et l'un d'eux trébuche sur `BEGIN ATOMIC` ([lignes 9-91](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L08.cs#L9-L91)) :

```csharp
    // Les routines de cet exemple, créées à chaque exécution
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
        // Npgsql découpe le texte d'une commande sans paramètres à chaque point-virgule, pour envoyer les instructions en lot :
        // il découpe aussi CREATE FUNCTION au point-virgule à l'intérieur de BEGIN ATOMIC
        try
        {
            await using var create = new NpgsqlCommand(Setup[2], connection);
            await create.ExecuteNonQueryAsync();
        }
        catch (PostgresException e)
        {
            Console.WriteLine($"CREATE FUNCTION ... BEGIN ATOMIC in an NpgsqlCommand: {e.SqlState}: {e.MessageText}");
        }
        // Les commandes d'un NpgsqlBatch sont envoyées telles quelles
        await using (var batch = new NpgsqlBatch(connection))
        {
            foreach (var sql in Setup)
            {
                batch.BatchCommands.Add(new NpgsqlBatchCommand(sql));
            }
            await batch.ExecuteNonQueryAsync();
            Console.WriteLine("the same statements in an NpgsqlBatch: created");
        }

        // Une fonction s'appelle dans une requête, comme n'importe quelle expression
        await using (var command = new NpgsqlCommand("SELECT ci.failure_rate($1)", connection))
        {
            command.Parameters.Add(new() { Value = "Rust course examples" });
            Console.WriteLine($"SELECT ci.failure_rate($1): {await command.ExecuteScalarAsync()}");
        }

        // CommandType.StoredProcedure génère CALL, qui n'exécute que des procédures
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

- Le `CREATE FUNCTION` échoue dans une `NpgsqlCommand`. Une commande sans paramètres peut contenir plusieurs instructions séparées par des points-virgules, et Npgsql découpe son texte à chaque point-virgule qui n'est pas entre parenthèses, dans une chaîne ou dans un commentaire, pour envoyer les instructions en lot ([`SqlQueryParser.cs`, lignes 137-139](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/SqlQueryParser.cs#L137-L139), et [`NpgsqlCommand.cs`, lignes 931-941](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/NpgsqlCommand.cs#L931-L941)). Le point-virgule après le `SELECT` dans `BEGIN ATOMIC` coupe l'instruction en deux, et le serveur voit `CREATE FUNCTION … BEGIN ATOMIC SELECT …` se terminer sans son `END`.
- Un [`NpgsqlBatch`](https://www.npgsql.org/doc/basic-usage.html#batching) envoie chacune de ses commandes telle quelle : les mêmes instructions y fonctionnent. Mettre le commutateur `Npgsql.EnableSqlRewriting` à `false` arrête aussi le découpage, et avec lui les paramètres nommés comme `@name`.
- Une fonction s'appelle dans une requête : `SELECT ci.failure_rate($1)`.
- [`CommandType.StoredProcedure`](https://www.npgsql.org/doc/basic-usage.html#stored-functions-and-procedures) génère `CALL`, depuis Npgsql 7.0 : il exécute la procédure, et renvoie ses paramètres `OUT`. Sur une fonction, le serveur répond `42809`, « is not a procedure », avec l'indice d'utiliser `SELECT`.

L'analyseur de pgjdbc découpe aussi aux points-virgules, mais pas dans une instruction qui contient `BEGIN ATOMIC` ([`Parser.java`, lignes 147-149](https://github.com/pgjdbc/pgjdbc/blob/3297557c6a8059d0d6e3522c79f0bd9a6f82ee07/pgjdbc/src/main/java/org/postgresql/core/Parser.java#L147-L149) et [259-265](https://github.com/pgjdbc/pgjdbc/blob/3297557c6a8059d0d6e3522c79f0bd9a6f82ee07/pgjdbc/src/main/java/org/postgresql/core/Parser.java#L259-L265)). Le revers de ce choix : une chaîne avec une fonction `BEGIN ATOMIC` suivie d'autres instructions n'est pas découpée non plus, et le serveur la refuse comme plusieurs commandes dans une instruction préparée. Le programme Java envoie chaque instruction séparément. La syntaxe d'échappement `{call …}` de JDBC est l'endroit où les deux sortes de routines diffèrent ([lignes 15-65](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L08.java#L15-L65)) :

```java
    static void routines() throws SQLException {
        try (Connection connection = DriverManager.getConnection(L04.url()); Statement statement = connection.createStatement()) {
            // Une instruction par appel : le pilote ne découpe pas une instruction aux points-virgules de BEGIN ATOMIC,
            // et ne découpe pas non plus une chaîne qui en contient une
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

            // {? = call f(?)} exécute une fonction : le pilote envoie SELECT
            try (CallableStatement call = connection.prepareCall("{? = call ci.failure_rate(?)}")) {
                call.registerOutParameter(1, Types.NUMERIC);
                call.setString(2, "Rust course examples");
                call.execute();
                System.out.println("{? = call ci.failure_rate(?)}: " + call.getBigDecimal(1));
            }

            // {call p(?, ?, ?)} sur une procédure : avec la valeur par défaut escapeSyntaxCallMode=select, le pilote envoie quand même SELECT
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

Avec la valeur par défaut [`escapeSyntaxCallMode=select`](https://jdbc.postgresql.org/documentation/use/), pgjdbc transforme chaque `{call …}` en `SELECT`, qui n'exécute que des fonctions. `callIfNoReturn` envoie `CALL` quand l'échappement n'a pas de valeur de retour `? =`, donc `{call ci.count_runs(?, ?, ?)}` exécute la procédure ; `call` envoie toujours `CALL`.

L'erreur d'un trigger arrive au programme avec tous ses champs ([lignes 93-131](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L08.cs#L93-L131)) :

```text
23514: version 0.* of ModelContextProtocol is not an exact numeric version
hint: Pin a released version, such as 10.0.5.
where: PL/pgSQL function ga.check_pin() line 4 at RAISE
```

[`PostgresException`](https://www.npgsql.org/doc/api/Npgsql.PostgresException.html) a `SqlState`, `Hint` et `Where` : l'application peut tester `PostgresErrorCodes.CheckViolation` et afficher l'indice, au lieu d'analyser un message.

## Extensions

Une [extension](https://www.postgresql.org/docs/18/extend-extensions.html) regroupe des types, des fonctions, des opérateurs et des méthodes d'index : `pg_trgm`, `unaccent`, `pgstattuple` et `pageinspect` dans les leçons précédentes. Certaines sont *de confiance* (trusted) : un rôle qui a `CREATE` sur la base peut les installer sans être superutilisateur ([lignes 156-169](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-functions.sql#L156-L169)) :

```sql
-- Extensions : certaines sont de confiance, et un rôle qui a CREATE sur la base peut les installer sans être superutilisateur
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

`pg_trgm` est de confiance, et appartient à `app` une fois installée. `pageinspect` lit des pages brutes, et demande un superutilisateur. [`pg_available_extension_versions`](https://www.postgresql.org/docs/18/view-pg-available-extension-versions.html) liste ce que le serveur peut installer, et `pg_extension` ce que la base a. Les assemblys CLR de SQL Server exécutent du code .NET dans le serveur ; les extensions de PostgreSQL sont surtout des bibliothèques C installées sur le système de fichiers du serveur, qu'un service géré choisit pour toi.

## pgvector

[pgvector](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md) ajoute un type `vector`, des opérateurs de distance et deux méthodes d'index approximatives. Il n'est pas dans l'image officielle : [`sql/08-pgvector.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql) s'exécute sur `pgvector/pgvector:0.8.6-pg18-trixie`, le même PostgreSQL 18.6 avec l'extension intégrée. Arrête d'abord le serveur du cours, puisque les deux utilisent le port 5432 :

```bash
bash server.sh stop
PG_IMAGE=pgvector/pgvector:0.8.6-pg18-trixie bash server.sh start
bash check.sh pgvector
```

Sous Windows, exécute ces commandes dans Git Bash, comme dans la [leçon 1](../01-getting-started/).

### Vecteurs et distances

[Lignes 6-15](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L6-L15) :

```sql
CREATE EXTENSION vector;
SELECT extversion FROM pg_extension WHERE extname = 'vector';

-- Un vecteur est une liste de valeurs float4 avec un nombre fixe de dimensions ; <-> est la distance euclidienne,
-- <=> la distance cosinus, <#> l'opposé du produit scalaire
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

`<->` est la distance euclidienne, `<=>` la distance cosinus, un moins le cosinus de l'angle, et `<#>` le produit scalaire de signe inversé, pour que plus petit veuille dire plus proche pour les trois : les parcours d'index de PostgreSQL ne renvoient les lignes que dans l'ordre croissant d'un opérateur. Des vecteurs de tailles différentes ne peuvent pas être comparés.

### Des accords comme vecteurs

Les embeddings d'un modèle de langage ont des centaines de dimensions que personne ne peut lire. Un accord en a une représentation petite et lisible : 12 dimensions, 1 pour chaque classe de hauteur qu'il contient ([lignes 17-36](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L17-L36)) :

```sql
-- Un accord comme vecteur à 12 dimensions : 1 pour chaque classe de hauteur qu'il contient, de do (0) à si (11)
CREATE FUNCTION ga.pitch_class_vector(pitch_classes smallint[]) RETURNS vector(12)
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
    SELECT array_agg((pc = ANY(pitch_classes))::int ORDER BY pc)::vector(12)
    FROM generate_series(0, 11) AS pc;
END;

ALTER TABLE ga.iconic_chords
    ADD COLUMN profile vector(12) GENERATED ALWAYS AS (ga.pitch_class_vector(pitch_classes::smallint[])) STORED;
SELECT name, pitch_classes, profile FROM ga.iconic_chords ORDER BY chord_id LIMIT 3;

-- Les accords les plus proches de l'accord Hendrix : le produit scalaire de deux tels vecteurs compte leurs notes communes
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

La fonction est `IMMUTABLE`, donc une colonne générée stockée peut l'utiliser. Pour des vecteurs de 0 et de 1, le produit scalaire compte les notes que deux accords partagent, et la distance cosinus le rapporte à leurs tailles : les accords Debussy et So What partagent quatre des cinq notes de l'accord Hendrix. `c.name` départage les égalités, fréquentes avec des vecteurs aussi petits.

### HNSW

Un index sur tous les ensembles de classes de hauteur, au nombre de 4 095 ([lignes 38-56](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L38-L56)) :

```sql
-- Un index HNSW sur tous les ensembles de classes de hauteur : 4 095 ensembles non vides
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

-- ORDER BY distance LIMIT utilise l'index ; l'opérateur doit correspondre à la classe d'opérateurs de l'index
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

[HNSW](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md#hnsw) construit un graphe en couches où chaque vecteur est relié à ses proches voisins, et une recherche le parcourt. Il est approximatif : il peut manquer un vrai voisin. La classe d'opérateurs choisit la distance, ici `vector_cosine_ops`, et seul cet opérateur utilise l'index : la requête avec `<->` trie toute la table. Les plans n'ont ni coûts ni buffers : HNSW place chaque vecteur dans une couche aléatoire, donc l'index est un peu différent à chaque construction.

### Filtres et parcours itératifs

Une recherche des plus proches voisins avec un `WHERE` ([lignes 58-82](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector.sql#L58-L82)) :

```sql
-- Sur 4 095 lignes, une requête filtrée lit la table ; sans ce choix, un filtre s'applique à ce que renvoie l'index :
-- les hnsw.ef_search lignes les plus proches (40 par défaut), dont aucune n'est une triade ici
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

-- Les parcours d'index itératifs (pgvector 0.8) continuent de lire l'index jusqu'à ce qu'assez de lignes passent le filtre
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

L'index renvoie les `hnsw.ef_search` candidats les plus proches, 40 par défaut, et le filtre s'applique à ceux-là, après le parcours d'index. Les 40 ensembles les plus proches de l'accord Hendrix ont quatre notes ou plus, donc la requête ne renvoie aucune triade, là où dix étaient demandées. Le README le dit clairement : « filtering is applied *after* the index is scanned ». Sur 4 095 lignes, le planificateur préfère de toute façon un parcours séquentiel, qui donne des résultats exacts ; `enable_seqscan = off` montre ce que ferait une grande table.

Les [parcours d'index itératifs](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md#iterative-index-scans), depuis pgvector 0.8.0, continuent de parcourir l'index jusqu'à ce qu'assez de lignes passent le filtre : `strict_order` les renvoie dans l'ordre exact des distances, `relaxed_order` donne un meilleur rappel avec des lignes légèrement dans le désordre. Les dix triades sont les dix sous-ensembles de trois notes de l'accord Hendrix. Le `VECTOR_SEARCH` de SQL Server 2025, en préversion, applique lui aussi les prédicats après la recherche, et ne filtre pendant la recherche que dans Azure SQL Database et Fabric ([`VECTOR_SEARCH`](https://learn.microsoft.com/sql/t-sql/functions/vector-search-transact-sql)).

## Sur Aurora

*À vérifier : rien dans cette section n'a été exécuté sur AWS.* Les fonctions, procédures, PL/pgSQL et triggers sont ceux de PostgreSQL, et se comportent comme dans cette leçon. Les extensions sont là où Aurora diffère le plus.

- **Pas de superutilisateur.** L'utilisateur principal a le rôle [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html), et il est créé `NOSUPERUSER` ; il peut « add extensions that are available for use with Aurora PostgreSQL ». Seules les extensions du [tableau de la version](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) existent : `pageinspect`, que `app` n'a pas pu installer dans cette leçon, n'est pas du tout dans le tableau d'Aurora PostgreSQL 18.
- **Qui peut installer quoi.** Le paramètre `rds.allowed_extensions` limite les extensions qui peuvent être installées ([travailler avec les extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.html)). Le guide de RDS for PostgreSQL explique que sa valeur par défaut, `*`, les autorise toutes, et qu'avec les extensions de confiance « users can install many extensions if they have the `CREATE` privilege on the current database instead of requiring the `rds_superuser` role » ([extensions sur RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.FeatureSupport.Extensions.html)) ; qu'Aurora se comporte de la même façon est *à vérifier*. La [gestion déléguée des extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora_delegated_ext.html) ajoute un rôle `rds_extension` pour les utilisateurs qui gèrent les extensions sans `rds_superuser`.
- **Tes propres extensions.** Un service géré ne charge pas tes bibliothèques C. Les [Trusted Language Extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_trusted_language_extension.html), `pg_tle` 1.5.2 sur 18.4, empaquettent comme extensions du code écrit dans des langages de confiance, depuis Aurora PostgreSQL 14.5.
- **pgvector 0.8.2.** Les [notes de version d'Aurora PostgreSQL 18.4](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Updates.html), du 21 août 2026, ont mis à jour pgvector « to version 0.8.2 » ; cette leçon a tourné sur 0.8.6. Les parcours itératifs datent de 0.8.0 et y sont ; ce qui est venu après 0.8.2 n'y est pas. [Aurora Optimized Reads](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.optimized.reads.html) met des pages en cache sur un stockage NVMe local sur les instances R6gd, R8gd et R6id, et cite parmi ses usages les recherches « across millions of vector embeddings » ; sa liste de versions n'inclut pas encore 18.
- **Appeler AWS depuis SQL.** L'extension [`aws_lambda`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL-Lambda.html), 2.1 sur 18.4, invoque une fonction Lambda depuis une requête, « synchronously or asynchronously, depending on the `invocation_type` ». Appelée de façon synchrone depuis un trigger, elle garde la transaction et ses verrous ouverts pendant qu'elle attend.

## À retenir

- Les corps `BEGIN ATOMIC` sont analysés une fois et enregistrent leurs dépendances ; les corps en chaîne sont vérifiés à chaque appel.
- Déclare la volatilité : les fonctions `IMMUTABLE` peuvent être indexées et utilisées dans des colonnes générées.
- L'`EXCEPTION` de PL/pgSQL attrape les erreurs par leur nom, dans une sous-transaction.
- Les procédures s'exécutent avec `CALL` et peuvent valider, quand elles commencent la transaction.
- Les triggers de ligne `BEFORE` modifient ou rejettent des lignes ; les triggers d'instruction avec tables de transition voient chaque ligne modifiée.
- Npgsql découpe une commande sans paramètres aux points-virgules, y compris ceux de `BEGIN ATOMIC` : utilise `NpgsqlBatch`. pgjdbc a besoin d'`escapeSyntaxCallMode` pour faire un `CALL` de procédure.
- Les extensions de confiance s'installent sans superutilisateur ; un service géré décide quelles extensions existent.
- L'index HNSW de pgvector est approximatif, et les filtres s'appliquent après lui : les parcours itératifs rattrapent les lignes manquantes.

## Exercices

Les solutions sont dans [`sql/08-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql) et, pour le dernier, [`sql/08-pgvector-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector-exercises.sql).

1. Écris une fonction SQL `ci.slowest_steps(workflow, n)` qui renvoie les `n` étapes les plus lentes d'un workflow, avec leur job et leur durée. Utilise-la pour afficher l'étape la plus lente de chaque workflow, et garde les cinq plus lentes.

<details>
<summary>Solution</summary>

[Lignes 6-24](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql#L6-L24) :

```sql
-- Exercice 1 : une fonction SQL qui renvoie un ensemble de lignes, appelée une fois par workflow avec LATERAL
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

`RETURNS TABLE (…)` est une fonction table, et `CROSS JOIN LATERAL` l'appelle une fois par workflow, comme le fait `CROSS APPLY`. Son `ORDER BY` départage les égalités par nom de job et d'étape, donc `LIMIT n` garde toujours les mêmes lignes. Les deux étapes `GHA 09` de 87 secondes appartiennent à des jobs qui démontrent les délais maximaux (timeouts).

</details>

2. Ajoute à `ga.package_pins` un trigger qui refuse d'abaisser une version épinglée. Essaie `Npgsql` de 10.0.3 à 9.0.4, puis `MongoDB.Driver` de 3.5.0 à 3.10.0.

<details>
<summary>Solution</summary>

[Lignes 26-60](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql#L26-L60) :

```sql
-- Exercice 2 : un trigger qui refuse d'abaisser une version épinglée
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

`BEFORE UPDATE OF version` ne se déclenche que quand l'instruction affecte `version`, et `WHEN (…)` seulement pour les lignes où elle a changé, sans appeler la fonction pour les autres. La comparaison de tableaux d'entiers accepte 3.10.0 après 3.5.0, là où une comparaison de textes l'aurait refusé, puisque `'3.10.0' < '3.5.0'`.

</details>

3. Écris une procédure qui insère une ligne, valide, puis insère une ligne qui viole la clé primaire. Que contient la table après l'erreur ?

<details>
<summary>Solution</summary>

[Lignes 62-74](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-exercises.sql#L62-L74) :

```sql
-- Exercice 3 : une procédure qui échoue après un COMMIT : ce qu'elle a validé reste
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

Le `CALL` échoue, mais la première ligne reste : elle a été validée avant l'erreur. Seule la transaction commencée par le `COMMIT` est annulée. Un appelant qui reçoit une erreur d'une procédure ne peut pas supposer que rien ne s'est passé, et une procédure qui valide en cours de route doit pouvoir être relancée sans risque.

</details>

4. Sur l'image pgvector, écris une fonction qui calcule le [vecteur de classes d'intervalles](https://en.wikipedia.org/wiki/Interval_vector) d'un accord : pour chaque classe d'intervalle de 1 (un demi-ton ou une septième majeure) à 6 (un triton), le nombre de paires de notes qui la forment. Quels accords iconiques ont le même vecteur de classes d'intervalles ?

<details>
<summary>Solution</summary>

[`sql/08-pgvector-exercises.sql`, lignes 7-28](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/08-pgvector-exercises.sql#L7-L28) :

```sql
-- Exercice 4 : le vecteur de classes d'intervalles, qu'une transposition ne change pas
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

-- Des accords aux mêmes intervalles : distance 0, quelle que soit leur fondamentale
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

La classe d'intervalle de deux classes de hauteur est le plus court chemin autour du cercle des douze. Une transposition déplace chaque note du même intervalle, donc elle conserve le vecteur : une distance de 0 trouve les accords qui ont les mêmes intervalles, quelle que soit leur fondamentale.

- Les accords Cowboy et Blackbird ont les mêmes notes : sol majeur, disposé autrement.
- L'accord Elektra, mi majeur et si♭ majeur ensemble, est l'accord Petrushka, do majeur et fa♯ majeur, transposé d'une tierce majeure vers le haut.
- L'accord Joni Mitchell transposé d'un ton vers le bas donne les notes de l'accord Debussy, et l'accord Foxy Lady est son renversement : les mêmes intervalles, à l'envers, ce que le vecteur ne peut pas distinguer.

</details>

## Sources

- Documentation de PostgreSQL 18 : [fonctions SQL](https://www.postgresql.org/docs/18/xfunc-sql.html), [`CREATE FUNCTION`](https://www.postgresql.org/docs/18/sql-createfunction.html), [volatilité des fonctions](https://www.postgresql.org/docs/18/xfunc-volatility.html), [procédures](https://www.postgresql.org/docs/18/xproc.html), [`CALL`](https://www.postgresql.org/docs/18/sql-call.html), [PL/pgSQL](https://www.postgresql.org/docs/18/plpgsql.html), [attraper les erreurs](https://www.postgresql.org/docs/18/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING), [gestion des transactions](https://www.postgresql.org/docs/18/plpgsql-transactions.html), [fonctions trigger](https://www.postgresql.org/docs/18/plpgsql-trigger.html), [`CREATE TRIGGER`](https://www.postgresql.org/docs/18/sql-createtrigger.html), [extensions](https://www.postgresql.org/docs/18/extend-extensions.html), [`pg_available_extension_versions`](https://www.postgresql.org/docs/18/view-pg-available-extension-versions.html)
- Npgsql : [utilisation de base](https://www.npgsql.org/doc/basic-usage.html), sources à 10.0.3 : [`SqlQueryParser.cs`, lignes 137-139](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/SqlQueryParser.cs#L137-L139), [`NpgsqlCommand.cs`, lignes 931-941](https://github.com/npgsql/npgsql/blob/d3768398c17877b3a916c3c4d87e8e11698991fc/src/Npgsql/NpgsqlCommand.cs#L931-L941)
- pgjdbc : [paramètres de connexion](https://jdbc.postgresql.org/documentation/use/), sources à 42.7.13 : [`Parser.java`, lignes 147-149 et 259-265](https://github.com/pgjdbc/pgjdbc/blob/3297557c6a8059d0d6e3522c79f0bd9a6f82ee07/pgjdbc/src/main/java/org/postgresql/core/Parser.java#L147-L149)
- pgvector 0.8.6 : [README](https://github.com/pgvector/pgvector/blob/v0.8.6/README.md)
- SQL Server : [fonctions définies par l'utilisateur](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/user-defined-functions), [incorporation des UDF scalaires](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/scalar-udf-inlining), [les tables inserted et deleted](https://learn.microsoft.com/sql/relational-databases/triggers/use-the-inserted-and-deleted-tables), [intégration du CLR](https://learn.microsoft.com/sql/relational-databases/clr-integration/common-language-runtime-integration-overview), [le type de données `vector`](https://learn.microsoft.com/sql/t-sql/data-types/vector-data-type), [`CREATE VECTOR INDEX`](https://learn.microsoft.com/sql/t-sql/statements/create-vector-index-transact-sql), [`VECTOR_SEARCH`](https://learn.microsoft.com/sql/t-sql/functions/vector-search-transact-sql)
- AWS : [le rôle `rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html), [versions des extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), [travailler avec les extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.html), [extensions sur RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.FeatureSupport.Extensions.html), [gestion déléguée des extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora_delegated_ext.html), [Trusted Language Extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_trusted_language_extension.html), [notes de version](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Updates.html), [Optimized Reads](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.optimized.reads.html), [`aws_lambda`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL-Lambda.html), toutes lues le 2026-09-16
