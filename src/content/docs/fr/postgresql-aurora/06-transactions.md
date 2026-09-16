---
title: "6. Transactions et MVCC"
description: Comment PostgreSQL garde plusieurs versions d'une ligne — xmin, xmax et ctid, versions mortes, VACUUM, bloat et mises à jour HOT — et ce que deux sessions se font l'une à l'autre, montré par des programmes C# et Java à l'entrelacement fixe — niveaux d'isolation, mises à jour perdues, write skew et isolation par instantané sérialisable, verrous de ligne, NOWAIT, lock_timeout, deadlocks et SKIP LOCKED ; comparés aux verrous, à RCSI et au version store de SQL Server.
sidebar:
  order: 6
---

Le script de la leçon est [`sql/06-mvcc.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql), comparé à [`expected/06-mvcc.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/06-mvcc.txt). Un script s'exécute dans une seule session, et la concurrence en demande deux : le reste de la leçon est dans [`csharp/L06.cs`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs) et [`java/…/L06.java`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L06.java), exécutés comme dans la [leçon 4](../04-csharp-java/#exécuter-les-exemples) :

```bash
dotnet run --project csharp -c Release -- l06-isolation
java -jar java/target/pg.jar l06-lost-update
```

Chaque programme ouvre deux connexions, A et B, et exécute leurs instructions dans un ordre fixe. Quand B doit attendre A, le programme ne peut pas simplement attendre que la commande de B revienne, donc une troisième connexion interroge [`pg_stat_activity`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW) jusqu'à ce que B attende un verrou ([lignes 22-37](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L22-L37)) :

```csharp
    // Interroge jusqu'à ce que la session de ce processus attende un verrou, et renvoie les sessions qui la bloquent
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
```

[`pg_blocking_pids`](https://www.postgresql.org/docs/18/functions-info.html#FUNCTIONS-INFO-SESSION) renvoie les sessions qui détiennent ce qu'elle attend. Ainsi, chaque sortie est la même à chaque exécution, et `check.sh` les compare à `expected/l06-*.txt`.

| SQL Server | PostgreSQL |
|---|---|
| `READ COMMITTED` prend des verrous partagés, sauf si `READ_COMMITTED_SNAPSHOT` est activé | `READ COMMITTED` lit un instantané, toujours : les lecteurs n'attendent jamais les écrivains |
| anciennes versions dans le version store (tempdb, ou la base avec la récupération de base de données accélérée) | anciennes versions dans la table elle-même, jusqu'à ce que `VACUUM` les supprime |
| `READ UNCOMMITTED` lit les lignes non validées | `READ UNCOMMITTED` est `READ COMMITTED` |
| `SNAPSHOT`, erreur de conflit de mise à jour 3960 | `REPEATABLE READ`, SQLSTATE `40001` |
| `SERIALIZABLE` avec des verrous de plages de clés | `SERIALIZABLE` avec l'isolation par instantané sérialisable, `40001` |
| `SET LOCK_TIMEOUT`, erreur 1222 | `lock_timeout`, SQLSTATE `55P03` |
| `READPAST` | `SKIP LOCKED` |
| victime de deadlock choisie par `DEADLOCK_PRIORITY`, erreur 1205 | la session qui détecte le cycle, SQLSTATE `40P01` |
| escalade des verrous vers la table | pas d'escalade : les verrous de ligne sont écrits dans les lignes |

## Versions de lignes

Une table pour la leçon : une ligne par workflow, avec l'autovacuum désactivé, pour que le script décide quand `VACUUM` s'exécute ([lignes 9-23](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L9-L23)) :

```sql
-- Une ligne par workflow, dans une table que l'autovacuum laisse tranquille : le script décide quand VACUUM s'exécute
CREATE TABLE ci.workflow_totals (
    workflow_name text PRIMARY KEY,
    runs          integer NOT NULL,
    failures      integer NOT NULL
) WITH (autovacuum_enabled = false);
-- Les identifiants de transaction ci-dessous sont relatifs à celui-ci, pour que la sortie ne dépende pas du nombre de transactions exécutées avant par le serveur
SELECT pg_current_xact_id()::text::bigint AS base \gset
INSERT INTO ci.workflow_totals
SELECT workflow_name, count(*), count(*) FILTER (WHERE conclusion = 'failure')
FROM ci.runs GROUP BY workflow_name ORDER BY workflow_name;

-- Chaque version de ligne porte la transaction qui l'a créée (xmin) et celle qui l'a supprimée (xmax), et sa place (ctid)
SELECT ctid, xmin::text::bigint - :base AS xmin, xmax, workflow_name, runs
FROM ci.workflow_totals WHERE workflow_name LIKE 'GHA 0%' ORDER BY workflow_name LIMIT 3;
```

```text
CREATE TABLE
INSERT 0 21
 ctid  | xmin | xmax |      workflow_name      | runs
-------+------+------+-------------------------+------
 (0,2) |    1 |    0 | GHA 01: hello           |    1
 (0,3) |    1 |    0 | GHA 02: build and test  |    3
 (0,4) |    1 |    0 | GHA 02: exercise checks |    1
(3 rows)
```

Chaque version de ligne porte des [colonnes système](https://www.postgresql.org/docs/18/ddl-system-columns.html) que `SELECT *` n'affiche pas :

- `xmin`, la transaction qui a créé la version. Le script soustrait l'identifiant de la transaction juste avant l'`INSERT`, enregistré par le [`\gset`](https://www.postgresql.org/docs/18/app-psql.html#APP-PSQL-META-COMMAND-GSET) de `psql` dans la variable `base` : les identifiants absolus dépendent de tout ce que le serveur a fait avant.
- `xmax`, la transaction qui l'a supprimée ou verrouillée ; `0` s'il n'y en a pas.
- `ctid`, sa place physique : page 0, élément 2.

Un `UPDATE` ne modifie pas la ligne sur place ([lignes 25-36](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L25-L36)) :

```sql
-- Un UPDATE écrit une nouvelle version et marque l'ancienne comme supprimée
UPDATE ci.workflow_totals SET runs = runs + 1 WHERE workflow_name = 'GHA 01: hello';
SELECT ctid, xmin::text::bigint - :base AS xmin, xmax, workflow_name, runs
FROM ci.workflow_totals WHERE workflow_name = 'GHA 01: hello';

-- Les deux versions sont toujours dans la page
CREATE EXTENSION pageinspect;
SELECT lp, t_ctid, t_xmin::text::bigint - :base AS t_xmin,
       CASE WHEN t_xmax::text = '0' THEN NULL ELSE t_xmax::text::bigint - :base END AS t_xmax
FROM heap_page_items(get_raw_page('ci.workflow_totals', 0))
WHERE lp IN (2, 22)
ORDER BY lp;
```

```text
UPDATE 1
  ctid  | xmin | xmax | workflow_name | runs
--------+------+------+---------------+------
 (0,22) |    2 |    0 | GHA 01: hello |    2
(1 row)

CREATE EXTENSION
 lp | t_ctid | t_xmin | t_xmax
----+--------+--------+--------
  2 | (0,22) |      1 |      2
 22 | (0,22) |      2 |
(2 rows)
```

La ligne vit maintenant en `(0,22)`, créée par la transaction 2. [`pageinspect`](https://www.postgresql.org/docs/18/pageinspect.html) lit la page brute : l'élément 2, l'ancienne version, est toujours là, avec `xmax` 2 et un `t_ctid` qui pointe vers la nouvelle version. Une transaction qui a commencé avant la validation de la transaction 2 lit encore l'élément 2 ; les autres suivent la chaîne jusqu'à l'élément 22. C'est le [MVCC](https://www.postgresql.org/docs/18/mvcc-intro.html) : chaque transaction voit les versions qui étaient validées quand son instantané a été pris, et personne n'attend pour lire.

SQL Server avec `READ_COMMITTED_SNAPSHOT` fait la même chose avec une autre organisation : la ligne est modifiée sur place, et l'ancienne version est copiée dans le version store. PostgreSQL garde les anciennes versions là où elles étaient, ce qui rend un rollback instantané, et laisse le nettoyage pour plus tard.

## Versions mortes et VACUUM

Un `UPDATE` annulé laisse lui aussi des versions mortes ([lignes 38-47](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L38-L47)) :

```sql
-- Un UPDATE annulé laisse lui aussi une version morte
BEGIN;
UPDATE ci.workflow_totals SET failures = 0;
ROLLBACK;
CREATE EXTENSION pgstattuple;
SELECT tuple_count, dead_tuple_count, table_len FROM pgstattuple('ci.workflow_totals');

-- VACUUM rend réutilisable l'espace des versions mortes ; le fichier garde sa taille
VACUUM ci.workflow_totals;
SELECT tuple_count, dead_tuple_count, table_len, free_space > 0 AS has_free_space FROM pgstattuple('ci.workflow_totals');
```

```text
BEGIN
UPDATE 21
ROLLBACK
CREATE EXTENSION
 tuple_count | dead_tuple_count | table_len
-------------+------------------+-----------
          21 |               22 |      8192
(1 row)

VACUUM
 tuple_count | dead_tuple_count | table_len | has_free_space
-------------+------------------+-----------+----------------
          21 |                0 |      8192 | t
(1 row)
```

[`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html) compte 22 versions mortes : l'ancienne version du premier `UPDATE`, et les 21 versions de la transaction annulée. `ROLLBACK` n'a rien réécrit ; la transaction est seulement marquée comme annulée, et ses versions sont invisibles pour tout le monde.

[`VACUUM`](https://www.postgresql.org/docs/18/routine-vacuuming.html) supprime les versions qu'aucune transaction ne peut plus voir, et note leur espace comme libre pour les insertions et mises à jour suivantes. Le fichier garde ses 8 ko : `VACUUM` ne rend de l'espace au système d'exploitation que quand les pages à la fin du fichier sont vides. L'[autovacuum](https://www.postgresql.org/docs/18/routine-vacuuming.html#AUTOVACUUM) l'exécute en arrière-plan, par défaut quand 20 % des lignes d'une table plus 50 sont mortes.

## Bloat

La même chose à grande échelle : chaque ligne de l'historique de 440 800 étapes de la [leçon 5](../05-indexes/), mise à jour une fois ([lignes 49-65](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L49-L65)) :

```sql
-- Le bloat à grande échelle : chaque ligne de l'historique des étapes mise à jour une fois
ALTER TABLE ci.step_history SET (autovacuum_enabled = false);
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS before;
UPDATE ci.step_history SET duration = duration + interval '1 second';
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_update,
       dead_tuple_count, round(dead_tuple_percent) AS dead_percent
FROM pgstattuple('ci.step_history');
VACUUM ci.step_history;
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_vacuum, round(free_percent) AS free_percent
FROM pgstattuple('ci.step_history');
-- La mise à jour complète suivante réutilise l'espace libre au lieu d'agrandir le fichier
UPDATE ci.step_history SET duration = duration - interval '1 second';
VACUUM ci.step_history;
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_second_update;
-- VACUUM FULL réécrit la table, sous un verrou ACCESS EXCLUSIVE
VACUUM FULL ci.step_history;
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_vacuum_full;
```

```text
ALTER TABLE
 before
--------
 76 MB
(1 row)

UPDATE 440800
 after_update | dead_tuple_count | dead_percent
--------------+------------------+--------------
 151 MB       |           440800 |           48
(1 row)

VACUUM
 after_vacuum | free_percent
--------------+--------------
 151 MB       |           50
(1 row)

UPDATE 440800
VACUUM
 after_second_update
---------------------
 151 MB
(1 row)

VACUUM
 after_vacuum_full
-------------------
 76 MB
(1 row)
```

1. L'`UPDATE` double la table : 440 800 nouvelles versions, et autant de versions mortes, 48 % du fichier.
2. `VACUUM` libère la moitié du fichier, mais le fichier reste à 151 Mo.
3. L'`UPDATE` complet suivant écrit ses nouvelles versions dans cet espace libre : 151 Mo, pas 226.
4. [`VACUUM FULL`](https://www.postgresql.org/docs/18/sql-vacuum.html) copie les versions vivantes dans un nouveau fichier : 76 Mo. Il tient un verrou `ACCESS EXCLUSIVE` pendant toute la copie, donc personne ne peut même lire la table pendant ce temps.

Une table qui reste deux fois plus grande après un traitement par lots est normale, et l'espace est réutilisé. Une table qui ne cesse de grossir signifie que `VACUUM` ne suit pas, ou ne peut rien supprimer : l'exercice 1 montre ce qui l'en empêche.

## Mises à jour HOT

Une nouvelle version demande normalement une nouvelle entrée dans chaque index de la table. Quand aucune colonne indexée ne change et que la page a de la place, PostgreSQL écrit un *heap-only tuple* : la nouvelle version va dans la même page, et les index continuent de pointer vers l'ancienne, qui mène à elle ([lignes 67-74](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L67-L74)) :

```sql
-- Mises à jour HOT : une nouvelle version dans la même page, sans modifier les index, quand aucune colonne indexée ne change et que la page a de la place
ALTER TABLE ci.workflow_totals SET (fillfactor = 70);
VACUUM FULL ci.workflow_totals;
SELECT pg_stat_reset_single_table_counters('ci.workflow_totals'::regclass) \gset
UPDATE ci.workflow_totals SET failures = failures + 1;
UPDATE ci.workflow_totals SET workflow_name = workflow_name || ' ' WHERE workflow_name LIKE 'GHA 0%';
SELECT pg_stat_force_next_flush() \gset
SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relid = 'ci.workflow_totals'::regclass;
```

```text
ALTER TABLE
VACUUM
UPDATE 21
UPDATE 15
 n_tup_upd | n_tup_hot_upd
-----------+---------------
        36 |            21
(1 row)
```

- [`fillfactor`](https://www.postgresql.org/docs/18/sql-createtable.html#RELOPTION-FILLFACTOR) `= 70` laisse 30 % de chaque page vide quand la table est écrite ; `VACUUM FULL` l'applique aux lignes existantes.
- Les 21 mises à jour de `failures`, une colonne dans aucun index, ont toutes été HOT.
- Les 15 mises à jour de `workflow_name`, la clé primaire, ne l'ont pas été.

[`pg_stat_user_tables`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW) compte les deux. Les statistiques sont envoyées à la fin d'une transaction, au plus une fois par seconde : `pg_stat_force_next_flush()` les envoie à la prochaine, pour que le compte soit là quand le script le lit. Un index sur une colonne qui change souvent coûte plus que ses propres mises à jour : il rend non HOT chaque mise à jour de la ligne ([heap-only tuples](https://www.postgresql.org/docs/18/storage-hot.html)).

## Niveaux d'isolation

A lit deux fois la même ligne dans une transaction, et B valide un incrément entre les deux lectures ([lignes 55-79](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L55-L79)) :

```csharp
    public static async Task Isolation()
    {
        await using var dataSource = await Totals();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();

        // A lit deux fois dans une transaction ; B valide une mise à jour entre les deux
        foreach (var level in new[] { "READ COMMITTED", "REPEATABLE READ", "SERIALIZABLE" })
        {
            await Exec(a, $"BEGIN ISOLATION LEVEL {level}");
            var first = await Scalar<int>(a, ReadDeploy);
            await Exec(b, IncrementDeploy);
            var second = await Scalar<int>(a, ReadDeploy);
            await Exec(a, "COMMIT");
            Console.WriteLine($"{level}: A reads {first}, B commits +1, A reads {second}");
        }

        // La mise à jour de B n'est pas encore validée : A ne la voit jamais, même en demandant READ UNCOMMITTED
        await Exec(b, "BEGIN");
        await Exec(b, IncrementDeploy);
        await Exec(a, "BEGIN ISOLATION LEVEL READ UNCOMMITTED");
        Console.WriteLine($"READ UNCOMMITTED: B has not committed, A reads {await Scalar<int>(a, ReadDeploy)}");
        await Exec(a, "COMMIT");
        await Exec(b, "ROLLBACK");
    }
```

```text
READ COMMITTED: A reads 65, B commits +1, A reads 66
REPEATABLE READ: A reads 66, B commits +1, A reads 66
SERIALIZABLE: A reads 67, B commits +1, A reads 67
READ UNCOMMITTED: B has not committed, A reads 68
```

- En [`READ COMMITTED`](https://www.postgresql.org/docs/18/transaction-iso.html#XACT-READ-COMMITTED), le niveau par défaut de PostgreSQL, chaque instruction prend un nouvel instantané : la seconde lecture de A voit la validation de B.
- En `REPEATABLE READ` et `SERIALIZABLE`, l'instantané est pris à la première instruction de la transaction et gardé jusqu'à la fin : A lit 66 deux fois.
- `READ UNCOMMITTED` est accepté et se comporte comme `READ COMMITTED` : PostgreSQL ne montre jamais une ligne non validée.
- B n'a jamais attendu. Avec le `REPEATABLE READ` à verrous de SQL Server, le verrou partagé de A sur la ligne aurait fait attendre l'`UPDATE` de B jusqu'à la validation de A.

## Mises à jour perdues

Deux sessions lisent le même compteur, ajoutent un dans l'application, et le réécrivent ([lignes 81-127](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L81-L127)) :

```csharp
    public static async Task LostUpdate()
    {
        await using var dataSource = await Totals();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        var start = await Scalar<int>(a, ReadDeploy);
        Console.WriteLine($"runs before: {start}");

        // Lire, ajouter un dans l'application, réécrire : l'écriture de B remplace celle de A
        await Exec(a, "BEGIN");
        await Exec(b, "BEGIN");
        var readByA = await Scalar<int>(a, ReadDeploy);
        var readByB = await Scalar<int>(b, ReadDeploy);
        await Exec(a, $"UPDATE ci.workflow_runs SET runs = {readByA + 1} WHERE workflow_name = 'Deploy to GitHub Pages'");
        await Exec(a, "COMMIT");
        await Exec(b, $"UPDATE ci.workflow_runs SET runs = {readByB + 1} WHERE workflow_name = 'Deploy to GitHub Pages'");
        await Exec(b, "COMMIT");
        Console.WriteLine($"READ COMMITTED, read then write: two increments, runs = {await Scalar<int>(a, ReadDeploy)}");

        // La même chose en REPEATABLE READ : l'écriture de B échoue, parce que la ligne a changé après l'instantané de B
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

        // runs = runs + 1 en READ COMMITTED : B attend le verrou de ligne de A, puis ajoute un à la ligne validée par A
        await Exec(a, "BEGIN");
        await Exec(a, IncrementDeploy);
        var waiting = Exec(b, IncrementDeploy);
        var blockers = await WaitUntilBlocked(dataSource, b.ProcessID);
        Console.WriteLine($"READ COMMITTED, runs = runs + 1: B waits, blocked by A: {blockers.SequenceEqual([a.ProcessID])}");
        await Exec(a, "COMMIT");
        await waiting;
        Console.WriteLine($"runs = {await Scalar<int>(a, ReadDeploy)}");
    }
```

```text
runs before: 65
READ COMMITTED, read then write: two increments, runs = 66
REPEATABLE READ, read then write: B gets 40001: could not serialize access due to concurrent update
runs = 67
READ COMMITTED, runs = runs + 1: B waits, blocked by A: True
runs = 69
```

- En `READ COMMITTED`, les deux lisent 65 et les deux écrivent 66 : un incrément est perdu, sans erreur.
- En `REPEATABLE READ`, l'`UPDATE` de B trouve une ligne modifiée après son instantané, et échoue avec le SQLSTATE [`40001`](https://www.postgresql.org/docs/18/errcodes-appendix.html), un échec de sérialisation. L'application doit annuler et relancer toute la transaction, en relisant la nouvelle valeur. L'isolation `SNAPSHOT` de SQL Server donne l'erreur 3960 dans la même situation.
- `runs = runs + 1` en une instruction n'a besoin d'aucun niveau d'isolation : B attend le verrou de ligne de A, puis relit la ligne que A a validée, et ajoute un à 68. La [documentation de `READ COMMITTED`](https://www.postgresql.org/docs/18/transaction-iso.html#XACT-READ-COMMITTED) décrit cette revérification de la ligne modifiée.

La même chose en Java, où [`setTransactionIsolation`](https://docs.oracle.com/en/java/javase/25/docs/api/java.sql/java/sql/Connection.html#setTransactionIsolation(int)) règle le niveau de la transaction suivante ([lignes 30-58](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L06.java#L30-L58)) :

```java
    static void lostUpdate() throws SQLException {
        try (Connection a = DriverManager.getConnection(L04.url()); Connection b = DriverManager.getConnection(L04.url())) {
            update(a, "DROP TABLE IF EXISTS ci.workflow_runs");
            update(a, "CREATE TABLE ci.workflow_runs AS SELECT workflow_name, count(*)::int AS runs FROM ci.runs GROUP BY workflow_name");
            // JDBC commence une transaction avec setAutoCommit(false) ; le niveau d'isolation s'applique à la suivante
            int[] levels = {Connection.TRANSACTION_READ_COMMITTED, Connection.TRANSACTION_REPEATABLE_READ};
            String[] names = {"READ COMMITTED", "REPEATABLE READ"};
            for (int i = 0; i < levels.length; i++) {
                String name = names[i];
                for (Connection c : new Connection[] {a, b}) {
                    c.setAutoCommit(false);
                    c.setTransactionIsolation(levels[i]);
                }
                long readByA = scalar(a, READ_DEPLOY);
                long readByB = scalar(b, READ_DEPLOY);
                update(a, "UPDATE ci.workflow_runs SET runs = " + (readByA + 1) + " WHERE workflow_name = 'Deploy to GitHub Pages'");
                a.commit();
                try {
                    update(b, "UPDATE ci.workflow_runs SET runs = " + (readByB + 1) + " WHERE workflow_name = 'Deploy to GitHub Pages'");
                    b.commit();
                    System.out.println(name + ": A and B read " + readByA + ", both write " + (readByA + 1) + ", runs = " + scalar(a, READ_DEPLOY));
                } catch (SQLException e) {
                    b.rollback();
                    System.out.println(name + ": A and B read " + readByA + ", B's write gets " + e.getSQLState() + ": " + e.getMessage());
                }
                a.commit();
            }
        }
    }
```

```text
READ COMMITTED: A and B read 65, both write 66, runs = 66
REPEATABLE READ: A and B read 66, B's write gets 40001: ERROR: could not serialize access due to concurrent update
```

Le message de pgjdbc commence par la gravité, `ERROR:` ; le `MessageText` de Npgsql, non.

## Write skew et SERIALIZABLE

Une règle qui porte sur deux lignes : des deux images de runner, au moins une doit rester activée. A désactive macOS et B désactive Windows, chacune après avoir vérifié que deux sont activées ([lignes 129-160](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L129-L160)) :

```csharp
    public static async Task WriteSkew()
    {
        await using var dataSource = Db.DataSource();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        // Deux images de runner ; la règle : au moins une reste activée. A désactive macOS, B désactive Windows.
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
```

```text
REPEATABLE READ: A sees 2 enabled, B sees 2 enabled
  both commit
  enabled now: 0
SERIALIZABLE: A sees 2 enabled, B sees 2 enabled
  A commits, B's COMMIT gets 40001: could not serialize access due to read/write dependencies among transactions
  enabled now: 1
```

En `REPEATABLE READ`, A et B modifient des lignes différentes, donc rien n'entre en conflit, et les deux valident : aucune image n'est activée. Cette anomalie est le *write skew*, et l'isolation par instantané la permet, dans PostgreSQL comme dans le `SNAPSHOT` de SQL Server.

Le [`SERIALIZABLE`](https://www.postgresql.org/docs/18/transaction-iso.html#XACT-SERIALIZABLE) de PostgreSQL est une *isolation par instantané sérialisable* : il lit toujours des instantanés et ne prend aucun verrou de lecture, mais il note ce que chaque transaction a lu, et fait échouer une transaction quand les lectures et écritures des transactions validées forment un schéma qu'aucun ordre séquentiel ne pourrait produire. Ici, le `COMMIT` de B échoue avec `40001`. Le `SERIALIZABLE` de SQL Server empêche la même anomalie avec des verrous de plages de clés, donc les deux sessions se bloqueraient l'une l'autre à la place.

## Verrous

Les verrous de ligne et de table tenus par une transaction ouverte ([lignes 76-91](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L76-L91)) :

```sql
-- Verrous tenus par la transaction ouverte de cette session
BEGIN;
SELECT runs FROM ci.workflow_totals WHERE workflow_name = 'Deploy to GitHub Pages' FOR UPDATE;
SELECT relation::regclass, mode, granted
FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'relation' AND relation::regclass::text LIKE 'ci.%'
ORDER BY 1, 2;
-- Un verrou de ligne n'est pas dans pg_locks : il est écrit dans le xmax de la version de la ligne
CREATE EXTENSION pgrowlocks;
SELECT locked_row, multi, modes FROM pgrowlocks('ci.workflow_totals');
ALTER TABLE ci.workflow_totals ADD COLUMN note text;
SELECT relation::regclass, mode, granted
FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'relation' AND relation::regclass::text LIKE 'ci.%'
ORDER BY 1, 2;
ROLLBACK;
```

```text
BEGIN
 runs
------
   65
(1 row)

        relation         |     mode     | granted
-------------------------+--------------+---------
 ci.workflow_totals      | RowShareLock | t
 ci.workflow_totals_pkey | RowShareLock | t
(2 rows)

CREATE EXTENSION
 locked_row | multi |     modes
------------+-------+----------------
 (0,22)     | f     | {"For Update"}
(1 row)

ALTER TABLE
        relation         |        mode         | granted
-------------------------+---------------------+---------
 ci.workflow_totals      | AccessExclusiveLock | t
 ci.workflow_totals      | RowShareLock        | t
 ci.workflow_totals_pkey | RowShareLock        | t
(3 rows)

ROLLBACK
```

- `SELECT … FOR UPDATE` prend un verrou `ROW SHARE` sur la table et son index, qui n'entre en conflit qu'avec `EXCLUSIVE` et `ACCESS EXCLUSIVE` ([verrous au niveau table](https://www.postgresql.org/docs/18/explicit-locking.html#LOCKING-TABLES)).
- Le verrou de ligne lui-même n'est pas dans [`pg_locks`](https://www.postgresql.org/docs/18/view-pg-locks.html) : il est écrit dans le `xmax` de la version de la ligne, que lit [`pgrowlocks`](https://www.postgresql.org/docs/18/pgrowlocks.html). Un million de lignes verrouillées ne prennent aucune mémoire dans la table des verrous, donc PostgreSQL n'a pas d'escalade de verrous.
- `ALTER TABLE … ADD COLUMN` prend `ACCESS EXCLUSIVE`, qui entre en conflit avec tous les autres verrous, y compris l'`ACCESS SHARE` d'un simple `SELECT`.

Ce que voit une seconde session ([lignes 162-206](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L162-L206)) :

```csharp
    public static async Task Locks()
    {
        await using var dataSource = await Totals();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        await Exec(a, "BEGIN");
        await Exec(a, ReadDeploy + " FOR UPDATE");

        // NOWAIT et lock_timeout transforment une attente en erreur
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

        // Une simple lecture n'attend jamais un verrou de ligne
        Console.WriteLine($"B reads without waiting: {await Scalar<int>(b, ReadDeploy)}");

        // Sans délai maximal, B attend tant que A garde sa transaction ouverte
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
```

```text
NOWAIT: 55P03: could not obtain lock on row in relation "workflow_runs"
lock_timeout: 55P03: canceling statement due to lock timeout
B reads without waiting: 65
B: wait_event_type=Lock, wait_event=transactionid, state=active, blocked by A: True
A commits, B's UPDATE returns: 1 row
```

- [`NOWAIT`](https://www.postgresql.org/docs/18/sql-select.html#SQL-FOR-UPDATE-SHARE) échoue immédiatement, et [`lock_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-LOCK-TIMEOUT) après 200 ms, tous deux avec `55P03`.
- Un simple `SELECT` lit la version validée, sans attendre.
- Un `UPDATE` en attente montre `wait_event_type = Lock` et `wait_event = transactionid` : une session qui attend un verrou de ligne attend la fin de la transaction qui le détient.

Une migration qui exécute `ALTER TABLE` pendant qu'une longue transaction lit la table l'attend, et chaque requête qui arrive après l'`ALTER TABLE` attend derrière elle, parce que sa demande d'`ACCESS EXCLUSIVE` est dans la file en premier. Régler `lock_timeout` avant le DDL d'une migration transforme cette interruption de service en une erreur à réessayer.

## Deadlocks

A verrouille une ligne et B une autre, puis chacune demande celle de l'autre ([lignes 208-237](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L208-L237)) :

```csharp
    public static async Task Deadlock()
    {
        await using var dataSource = await Totals();
        await using var a = await dataSource.OpenConnectionAsync();
        await using var b = await dataSource.OpenConnectionAsync();
        // La détection de deadlock s'exécute dans une session qui a attendu deadlock_timeout (1 s par défaut) :
        // B vérifie après 100 ms et A après 10 s, donc c'est toujours B qui détecte le cycle et qui est annulée
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
```

```text
A locks Deploy to GitHub Pages, B locks Rust course examples
A waits for Rust course examples
B asks for Deploy to GitHub Pages: 40P01: deadlock detected
A's UPDATE returns 1 row
```

PostgreSQL ne cherche pas les deadlocks en permanence. Une session qui a attendu [`deadlock_timeout`](https://www.postgresql.org/docs/18/runtime-config-locks.html#GUC-DEADLOCK-TIMEOUT), une seconde par défaut, cherche un cycle dans les attentes, et si elle en trouve un, fait échouer sa propre instruction avec `40P01`. Le programme donne à B un délai plus court qu'à A, donc B est toujours la session qui vérifie, et qui échoue. Le moniteur de verrous de SQL Server choisit lui-même la victime, d'après `DEADLOCK_PRIORITY` puis le coût de l'annulation. Dans les deux, la solution est la même : prendre les verrous dans le même ordre partout, et réessayer la victime.

## Sur Aurora

*À vérifier : rien dans cette section n'a été exécuté sur AWS.* Aurora PostgreSQL garde le MVCC de PostgreSQL : versions de lignes, `VACUUM`, niveaux d'isolation et verrous s'y comportent comme dans cette leçon. Ce qui change, c'est que les lecteurs sont d'autres instances, qui partagent le stockage du writer.

- **L'autovacuum reste nécessaire.** AWS le recommande vivement (« strongly recommend »), et il est activé par défaut ([autovacuum sur Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum.html)). L'autovacuum adaptatif, `rds.adaptive_autovacuum`, augmente ses réglages quand la métrique CloudWatch `MaximumUsedTransactionIDs` atteint `autovacuum_freeze_max_age` ou 500 millions, mais « transaction ID wraparound is still possible », et AWS suggère une alarme CloudWatch dessus. [Diagnostiquer le bloat des tables et des index](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.diag-table-ind-bloat.html) utilise `pgstattuple`, comme cette leçon.
- **Une requête sur un réplica retient `VACUUM` sur le writer.** « `hot_standby_feedback` is enabled by default and unmodifiable in Aurora PostgreSQL », et « it prevents autovacuum on the writer instance from removing dead rows that might still be needed by queries running on the reader instance » ([bloqueurs de vacuum identifiables](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum_Monitoring.Resolving_Identifiableblockers.html)). La transaction ouverte de l'exercice 1 peut être sur une autre instance : cherche aussi `backend_xmin` dans `pg_stat_activity` sur les readers. Dans PostgreSQL communautaire, `hot_standby_feedback` est désactivé par défaut, et la [documentation du hot standby](https://www.postgresql.org/docs/18/hot-standby.html) décrit le compromis.
- **Le DDL sur le writer peut annuler des requêtes sur les readers.** « Currently, only `ACCESS EXCLUSIVE` relation locks are replicated to reader instances », et le rejeu attend `max_standby_streaming_delay` avant d'annuler une requête d'un reader qui détient un verrou en conflit ([`Lock:Relation`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.lockrelation.html)). Cette page donne 30 secondes par défaut ; le tableau des paramètres d'Aurora PostgreSQL 14 donne 14 000 ms : *à vérifier* sur un groupe de paramètres 18. La requête annulée reçoit « canceling statement due to conflict with recovery » ([réplication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html)). L'`ALTER TABLE` de la section sur les verrous ferait cela à un rapport qui tourne sur un réplica.
- **Extensions.** `pgstattuple` 1.5 et `pgrowlocks` 1.2 sont dans le [tableau des extensions d'Aurora PostgreSQL 18](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) ; `pageinspect` n'y est pas, donc la page brute de la section sur les versions de lignes ne peut pas y être lue. `pg_visibility` 1.2 et `amcheck` 1.4 y sont.

Les programmes de cette leçon ont besoin des deux sessions sur le writer : par le reader endpoint, leurs `UPDATE` échoueraient.

## À retenir

- Un `UPDATE` écrit une nouvelle version de ligne ; `xmin`, `xmax` et `ctid` les montrent, et `VACUUM` supprime celles que personne ne peut voir.
- Le bloat est de l'espace que `VACUUM` a rendu réutilisable, pas restitué ; `VACUUM FULL` le restitue sous un verrou exclusif.
- Les mises à jour HOT évitent les écritures d'index quand aucune colonne indexée ne change et que la page a de la place : `fillfactor` et moins d'index y aident.
- Les lecteurs n'attendent jamais les écrivains. `READ COMMITTED` prend un instantané par instruction, `REPEATABLE READ` et `SERIALIZABLE` un par transaction.
- Lire puis écrire perd des mises à jour en `READ COMMITTED` ; `REPEATABLE READ` et `SERIALIZABLE` échouent avec `40001` à la place, et l'application réessaie.
- Les verrous de ligne vivent dans les lignes : pas d'escalade, et `SKIP LOCKED` permet de construire des files.
- `lock_timeout` avant le DDL, des verrous pris dans un ordre cohérent, et un nouvel essai pour `40P01`.

## Exercices

1. La session A ouvre une transaction `REPEATABLE READ` et lit une ligne. La session B modifie toutes les lignes de la table, puis exécute `VACUUM`. Combien reste-t-il de versions mortes, et pourquoi ? Que se passe-t-il une fois que A valide ?

<details>
<summary>Solution</summary>

`l06-vacuum-horizon`, [lignes 239-257](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L239-L257) :

```csharp
    // Exercice 1 : une transaction ouverte empêche VACUUM de supprimer les lignes mortes
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
```

```text
A opens a snapshot: 65 runs
B updates 21 rows
VACUUM while A is open: 21 dead row versions left
A still reads 65 runs
VACUUM after A commits: 0 dead row versions left
```

L'instantané de A peut encore avoir besoin des anciennes versions, et c'est le cas : A lit toujours 65. `VACUUM` ne supprime que les versions mortes pour l'instantané le plus ancien de toutes les transactions ouvertes, l'*horizon xmin*, donc les 21 restent. Une fois que A valide, elles disparaissent. Une application qui laisse une transaction ouverte, comme une connexion « idle in transaction » dans un pool, arrête `VACUUM` partout dans la base ; [`idle_in_transaction_session_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-IDLE-IN-TRANSACTION-SESSION-TIMEOUT) ferme de telles sessions, et `pg_stat_activity.backend_xmin` montre qui retient l'horizon.

</details>

2. Réécris l'exemple de write skew en Java avec `SERIALIZABLE` : chaque session ne désactive son image que si deux sont activées, et réessaie toute sa transaction quand elle reçoit `40001`. Que fait B à sa seconde tentative ?

<details>
<summary>Solution</summary>

`l06-retry`, [lignes 60-114](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L06.java#L60-L114) :

```java
    /** Exercise 2: retry a serializable transaction that fails with 40001, re-reading the data at each attempt. */
    static void retry() throws SQLException {
        try (Connection a = DriverManager.getConnection(L04.url()); Connection b = DriverManager.getConnection(L04.url())) {
            update(a, "DROP TABLE IF EXISTS ci.runner_images");
            update(a, "CREATE TABLE ci.runner_images (label text PRIMARY KEY, enabled boolean NOT NULL)");
            update(a, "INSERT INTO ci.runner_images VALUES ('macos-latest', true), ('windows-latest', true)");
            for (Connection c : new Connection[] {a, b}) {
                c.setAutoCommit(false);
                c.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            }
            // La première tentative de A s'exécute au milieu de la transaction de B, pour que les deux voient deux images activées
            boolean[] interleave = {true};
            disableUnlessLast(b, "windows-latest", () -> {
                if (interleave[0]) {
                    interleave[0] = false;
                    disableUnlessLast(a, "macos-latest", () -> { });
                }
            });
            try (Statement statement = a.createStatement();
                 ResultSet rs = statement.executeQuery("SELECT string_agg(label, ', ' ORDER BY label) FROM ci.runner_images WHERE enabled")) {
                rs.next();
                System.out.println("enabled now: " + rs.getString(1));
            }
            a.commit();
        }
    }

    interface Step {
        void run() throws SQLException;
    }

    private static void disableUnlessLast(Connection connection, String label, Step beforeCommit) throws SQLException {
        String who = label.startsWith("windows") ? "B" : "A";
        for (int attempt = 1; ; attempt++) {
            try {
                long enabled = scalar(connection, "SELECT count(*) FROM ci.runner_images WHERE enabled");
                if (enabled < 2) {
                    connection.commit();
                    System.out.println(who + " attempt " + attempt + ": " + enabled + " enabled, keeps " + label);
                    return;
                }
                update(connection, "UPDATE ci.runner_images SET enabled = false WHERE label = '" + label + "'");
                beforeCommit.run();
                connection.commit();
                System.out.println(who + " attempt " + attempt + ": " + enabled + " enabled, disables " + label);
                return;
            } catch (SQLException e) {
                connection.rollback();
                if (!"40001".equals(e.getSQLState())) {
                    throw e;
                }
                System.out.println(who + " attempt " + attempt + ": " + e.getSQLState() + ", retrying");
            }
        }
    }
```

```text
A attempt 1: 2 enabled, disables macos-latest
B attempt 1: 40001, retrying
B attempt 2: 1 enabled, keeps windows-latest
enabled now: windows-latest
```

A exécute toute sa transaction au milieu de celle de B, juste avant la validation de B. Le premier commit de B échoue avec `40001`. Sa seconde tentative relit le compte, ne trouve qu'une image activée, et garde Windows. Le nouvel essai doit refaire les lectures, pas seulement l'instruction qui a échoué : la décision en dépendait. `40001` et `40P01` sont les deux SQLSTATE qui valent la peine d'être réessayés automatiquement.

</details>

3. Les exécutions en échec de l'instantané forment une file de relances. Deux workers prennent chacun les trois premiers jobs dont personne d'autre ne s'occupe, dans deux transactions ouvertes. Quels jobs chacun obtient-il ? Le worker A supprime ses jobs et valide, le worker B annule : que reste-t-il ?

<details>
<summary>Solution</summary>

`l06-skip-locked`, [lignes 259-284](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L259-L284) :

```csharp
    // Exercice 3 : deux workers prennent des jobs dans la même file sans s'attendre l'un l'autre
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
```

```text
worker A claims jobs 1, 2, 3
worker B claims jobs 4, 5, 6
A deleted its jobs, B rolled back: 13 jobs left, next claim: 4, 5, 6
```

`FOR UPDATE SKIP LOCKED` verrouille les lignes qu'il renvoie et saute les lignes qu'une autre transaction a verrouillées, là où un simple `FOR UPDATE` attendrait : A obtient les jobs 1 à 3 et B les jobs 4 à 6, sans attendre. L'annulation de B libère ses verrous, donc les jobs 4 à 6 sont les prochains à prendre, et il reste 13 des 16 jobs. SQL Server écrit cela avec les indicateurs `READPAST` et `UPDLOCK`.

</details>

## Sources

- Documentation de PostgreSQL 18 : [contrôle de la concurrence](https://www.postgresql.org/docs/18/mvcc.html), [isolation des transactions](https://www.postgresql.org/docs/18/transaction-iso.html), [verrouillage explicite](https://www.postgresql.org/docs/18/explicit-locking.html), [vacuum de routine](https://www.postgresql.org/docs/18/routine-vacuuming.html), [`VACUUM`](https://www.postgresql.org/docs/18/sql-vacuum.html), [heap-only tuples](https://www.postgresql.org/docs/18/storage-hot.html), [colonnes système](https://www.postgresql.org/docs/18/ddl-system-columns.html), [`pageinspect`](https://www.postgresql.org/docs/18/pageinspect.html), [`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html), [`pgrowlocks`](https://www.postgresql.org/docs/18/pgrowlocks.html), [`pg_locks`](https://www.postgresql.org/docs/18/view-pg-locks.html), [`pg_stat_activity`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW), [réglages de la gestion des verrous](https://www.postgresql.org/docs/18/runtime-config-locks.html), [valeurs par défaut des connexions clientes](https://www.postgresql.org/docs/18/runtime-config-client.html), [codes d'erreur](https://www.postgresql.org/docs/18/errcodes-appendix.html)
- Java : [`Connection`](https://docs.oracle.com/en/java/javase/25/docs/api/java.sql/java/sql/Connection.html)
- SQL Server : [guide du verrouillage des transactions et du versionnement des lignes](https://learn.microsoft.com/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide), [récupération de base de données accélérée](https://learn.microsoft.com/sql/relational-databases/accelerated-database-recovery-concepts), [guide des deadlocks](https://learn.microsoft.com/sql/relational-databases/sql-server-deadlocks-guide), [`SET DEADLOCK_PRIORITY`](https://learn.microsoft.com/sql/t-sql/statements/set-deadlock-priority-transact-sql), [indicateurs de table](https://learn.microsoft.com/sql/t-sql/queries/hints-transact-sql-table), [`SET LOCK_TIMEOUT`](https://learn.microsoft.com/sql/t-sql/statements/set-lock-timeout-transact-sql), [erreur 1222](https://learn.microsoft.com/sql/relational-databases/errors-events/mssqlserver-1222-database-engine-error)
- Amazon Aurora : [autovacuum](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum.html), [bloqueurs de vacuum](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum_Monitoring.Resolving_Identifiableblockers.html), [bloat des tables et des index](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.diag-table-ind-bloat.html), [`Lock:Relation`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.lockrelation.html), [réplication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html), [versions des extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), toutes lues le 2026-09-16
