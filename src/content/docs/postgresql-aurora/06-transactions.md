---
title: "6. Transactions and MVCC"
description: How PostgreSQL keeps several versions of a row — xmin, xmax and ctid, dead versions, VACUUM, bloat and HOT updates — and what two sessions do to each other, shown by C# and Java programs with a fixed interleaving — isolation levels, lost updates, write skew and serializable snapshot isolation, row locks, NOWAIT, lock_timeout, deadlocks and SKIP LOCKED; compared with SQL Server's locking, RCSI and the version store.
sidebar:
  order: 6
---

The lesson's script is [`sql/06-mvcc.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql), compared with [`expected/06-mvcc.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/06-mvcc.txt). A script runs in one session, and concurrency needs two: the rest of the lesson is in [`csharp/L06.cs`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs) and [`java/…/L06.java`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L06.java), run as in [lesson 4](../04-csharp-java/#running-the-examples):

```bash
dotnet run --project csharp -c Release -- l06-isolation
java -jar java/target/pg.jar l06-lost-update
```

Each program opens two connections, A and B, and runs their statements in a fixed order. When B has to wait for A, the program can't simply wait for B's command to return, so a third connection polls [`pg_stat_activity`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW) until B is waiting for a lock ([lines 22-37](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L22-L37)):

```csharp
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
```

[`pg_blocking_pids`](https://www.postgresql.org/docs/18/functions-info.html#FUNCTIONS-INFO-SESSION) returns the sessions that hold what it waits for. With that, every output is the same at every run, and `check.sh` compares them with `expected/l06-*.txt`.

| SQL Server | PostgreSQL |
|---|---|
| `READ COMMITTED` takes shared locks, unless `READ_COMMITTED_SNAPSHOT` is on | `READ COMMITTED` reads a snapshot, always: readers never wait for writers |
| old versions in the version store (tempdb, or the database with accelerated database recovery) | old versions in the table itself, until `VACUUM` removes them |
| `READ UNCOMMITTED` reads uncommitted rows | `READ UNCOMMITTED` is `READ COMMITTED` |
| `SNAPSHOT`, update conflict error 3960 | `REPEATABLE READ`, SQLSTATE `40001` |
| `SERIALIZABLE` with key-range locks | `SERIALIZABLE` with serializable snapshot isolation, `40001` |
| `SET LOCK_TIMEOUT`, error 1222 | `lock_timeout`, SQLSTATE `55P03` |
| `READPAST` | `SKIP LOCKED` |
| deadlock victim chosen by `DEADLOCK_PRIORITY`, error 1205 | the session that detects the cycle, SQLSTATE `40P01` |
| lock escalation to the table | no escalation: row locks are written in the rows |

## Row versions

A table for the lesson: one row per workflow, with autovacuum turned off, so that the script decides when `VACUUM` runs ([lines 9-23](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L9-L23)):

```sql
-- One row per workflow, in a table autovacuum leaves alone: the script decides when VACUUM runs
CREATE TABLE ci.workflow_totals (
    workflow_name text PRIMARY KEY,
    runs          integer NOT NULL,
    failures      integer NOT NULL
) WITH (autovacuum_enabled = false);
-- Transaction IDs below are relative to this one, so that the output doesn't depend on how many transactions the server ran before
SELECT pg_current_xact_id()::text::bigint AS base \gset
INSERT INTO ci.workflow_totals
SELECT workflow_name, count(*), count(*) FILTER (WHERE conclusion = 'failure')
FROM ci.runs GROUP BY workflow_name ORDER BY workflow_name;

-- Each row version carries the transaction that created it (xmin) and the one that deleted it (xmax), and its place (ctid)
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

Every row version carries [system columns](https://www.postgresql.org/docs/18/ddl-system-columns.html) that `SELECT *` doesn't show:

- `xmin`, the transaction that created the version. The script subtracts the ID of the transaction just before the `INSERT`, saved by `psql`'s [`\gset`](https://www.postgresql.org/docs/18/app-psql.html#APP-PSQL-META-COMMAND-GSET) in the variable `base`: the absolute IDs depend on everything the server did before.
- `xmax`, the transaction that deleted or locked it; `0` if none.
- `ctid`, its physical place: page 0, item 2.

An `UPDATE` doesn't change the row in place ([lines 25-36](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L25-L36)):

```sql
-- An UPDATE writes a new version and marks the old one deleted
UPDATE ci.workflow_totals SET runs = runs + 1 WHERE workflow_name = 'GHA 01: hello';
SELECT ctid, xmin::text::bigint - :base AS xmin, xmax, workflow_name, runs
FROM ci.workflow_totals WHERE workflow_name = 'GHA 01: hello';

-- Both versions are still in the page
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

The row now lives at `(0,22)`, created by transaction 2. [`pageinspect`](https://www.postgresql.org/docs/18/pageinspect.html) reads the raw page: item 2, the old version, is still there, with `xmax` 2 and a `t_ctid` that points to the new version. A transaction that started before transaction 2 committed still reads item 2; the others follow the chain to item 22. This is [MVCC](https://www.postgresql.org/docs/18/mvcc-intro.html): each transaction sees the versions that were committed when its snapshot was taken, and nobody waits to read.

SQL Server with `READ_COMMITTED_SNAPSHOT` does the same with a different layout: the row is updated in place, and the old version is copied to the version store. PostgreSQL keeps old versions where they were, which makes a rollback instant, and leaves the cleanup for later.

## Dead versions and VACUUM

A rolled-back `UPDATE` leaves dead versions too ([lines 38-47](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L38-L47)):

```sql
-- A rolled-back UPDATE leaves a dead version too
BEGIN;
UPDATE ci.workflow_totals SET failures = 0;
ROLLBACK;
CREATE EXTENSION pgstattuple;
SELECT tuple_count, dead_tuple_count, table_len FROM pgstattuple('ci.workflow_totals');

-- VACUUM makes the dead versions' space reusable; the file keeps its size
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

[`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html) counts 22 dead versions: the old version of the first `UPDATE`, and the 21 versions of the transaction that rolled back. `ROLLBACK` wrote nothing back; the transaction is just marked aborted, and its versions are invisible to everyone.

[`VACUUM`](https://www.postgresql.org/docs/18/routine-vacuuming.html) removes the versions no transaction can see any more, and records their space as free for later inserts and updates. The file keeps its 8 kB: `VACUUM` only gives space back to the operating system when the pages at the end of the file are empty. [Autovacuum](https://www.postgresql.org/docs/18/routine-vacuuming.html#AUTOVACUUM) runs it in the background, by default when 20% of a table's rows plus 50 are dead.

## Bloat

The same thing at scale: every row of the 440,800-row step history of [lesson 5](../05-indexes/), updated once ([lines 49-65](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L49-L65)):

```sql
-- Bloat at scale: every row of the step history updated once
ALTER TABLE ci.step_history SET (autovacuum_enabled = false);
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS before;
UPDATE ci.step_history SET duration = duration + interval '1 second';
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_update,
       dead_tuple_count, round(dead_tuple_percent) AS dead_percent
FROM pgstattuple('ci.step_history');
VACUUM ci.step_history;
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_vacuum, round(free_percent) AS free_percent
FROM pgstattuple('ci.step_history');
-- The next full update reuses the free space instead of growing the file
UPDATE ci.step_history SET duration = duration - interval '1 second';
VACUUM ci.step_history;
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_second_update;
-- VACUUM FULL rewrites the table, under an ACCESS EXCLUSIVE lock
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

1. The `UPDATE` doubles the table: 440,800 new versions, and as many dead ones, 48% of the file.
2. `VACUUM` frees half the file, but the file stays at 151 MB.
3. The next full `UPDATE` writes its new versions in that free space: 151 MB, not 226.
4. [`VACUUM FULL`](https://www.postgresql.org/docs/18/sql-vacuum.html) copies the live versions into a new file: 76 MB. It holds an `ACCESS EXCLUSIVE` lock for the whole copy, so no one can even read the table meanwhile.

A table that stays twice its size after a batch job is normal, and the space is reused. A table that keeps growing means `VACUUM` can't keep up, or can't remove anything: exercise 1 shows what stops it.

## HOT updates

A new version normally needs a new entry in every index of the table. When no indexed column changes and the page has room, PostgreSQL writes a *heap-only tuple*: the new version goes to the same page, and the indexes keep pointing to the old one, which links to it ([lines 67-74](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L67-L74)):

```sql
-- HOT updates: a new version on the same page, no index change, when no indexed column changes and the page has room
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

- [`fillfactor`](https://www.postgresql.org/docs/18/sql-createtable.html#RELOPTION-FILLFACTOR) `= 70` leaves 30% of each page empty when the table is written; `VACUUM FULL` applies it to the existing rows.
- The 21 updates of `failures`, a column in no index, were all HOT.
- The 15 updates of `workflow_name`, the primary key, weren't.

[`pg_stat_user_tables`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW) counts both. The statistics are sent at the end of a transaction, at most once a second: `pg_stat_force_next_flush()` sends them at the next one, so that the count is there when the script reads it. An index on a column that changes often costs more than its own updates: it makes every update of the row a non-HOT one ([heap-only tuples](https://www.postgresql.org/docs/18/storage-hot.html)).

## Isolation levels

A reads the same row twice in one transaction, and B commits an increment between the two reads ([lines 55-79](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L55-L79)):

```csharp
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
```

```text
READ COMMITTED: A reads 65, B commits +1, A reads 66
REPEATABLE READ: A reads 66, B commits +1, A reads 66
SERIALIZABLE: A reads 67, B commits +1, A reads 67
READ UNCOMMITTED: B has not committed, A reads 68
```

- In [`READ COMMITTED`](https://www.postgresql.org/docs/18/transaction-iso.html#XACT-READ-COMMITTED), PostgreSQL's default, each statement takes a new snapshot: A's second read sees B's commit.
- In `REPEATABLE READ` and `SERIALIZABLE`, the snapshot is taken at the first statement of the transaction and kept to the end: A reads 66 twice.
- `READ UNCOMMITTED` is accepted and behaves as `READ COMMITTED`: PostgreSQL never shows an uncommitted row.
- B never waited. With SQL Server's locking `REPEATABLE READ`, A's shared lock on the row would have made B's `UPDATE` wait until A committed.

## Lost updates

Two sessions read the same counter, add one in the application, and write it back ([lines 81-127](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L81-L127)):

```csharp
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
```

```text
runs before: 65
READ COMMITTED, read then write: two increments, runs = 66
REPEATABLE READ, read then write: B gets 40001: could not serialize access due to concurrent update
runs = 67
READ COMMITTED, runs = runs + 1: B waits, blocked by A: True
runs = 69
```

- In `READ COMMITTED`, both read 65 and both write 66: one increment is lost, with no error.
- In `REPEATABLE READ`, B's `UPDATE` finds a row that changed after its snapshot, and fails with SQLSTATE [`40001`](https://www.postgresql.org/docs/18/errcodes-appendix.html), a serialization failure. The application must roll back and run the whole transaction again, reading the new value. SQL Server's `SNAPSHOT` isolation gives error 3960 in the same situation.
- `runs = runs + 1` in one statement needs no isolation level: B waits for A's row lock, then re-reads the row A committed, and adds one to 68. The [`READ COMMITTED` documentation](https://www.postgresql.org/docs/18/transaction-iso.html#XACT-READ-COMMITTED) describes this re-check of the updated row.

The same in Java, where [`setTransactionIsolation`](https://docs.oracle.com/en/java/javase/25/docs/api/java.sql/java/sql/Connection.html#setTransactionIsolation(int)) sets the level of the next transaction ([lines 30-58](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L06.java#L30-L58)):

```java
    static void lostUpdate() throws SQLException {
        try (Connection a = DriverManager.getConnection(L04.url()); Connection b = DriverManager.getConnection(L04.url())) {
            update(a, "DROP TABLE IF EXISTS ci.workflow_runs");
            update(a, "CREATE TABLE ci.workflow_runs AS SELECT workflow_name, count(*)::int AS runs FROM ci.runs GROUP BY workflow_name");
            // JDBC starts a transaction with setAutoCommit(false); the isolation level applies to the next one
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

pgjdbc's message starts with the severity, `ERROR:`; Npgsql's `MessageText` doesn't.

## Write skew and SERIALIZABLE

A rule that spans two rows: of the two runner images, at least one must stay enabled. A disables macOS and B disables Windows, each after checking that two are enabled ([lines 129-160](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L129-L160)):

```csharp
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
```

```text
REPEATABLE READ: A sees 2 enabled, B sees 2 enabled
  both commit
  enabled now: 0
SERIALIZABLE: A sees 2 enabled, B sees 2 enabled
  A commits, B's COMMIT gets 40001: could not serialize access due to read/write dependencies among transactions
  enabled now: 1
```

In `REPEATABLE READ`, A and B update different rows, so nothing conflicts, and both commit: no image is enabled. This anomaly is *write skew*, and snapshot isolation allows it, in PostgreSQL as in SQL Server's `SNAPSHOT`.

PostgreSQL's [`SERIALIZABLE`](https://www.postgresql.org/docs/18/transaction-iso.html#XACT-SERIALIZABLE) is *serializable snapshot isolation*: it still reads snapshots and takes no read locks, but it records what each transaction read, and fails one transaction when the reads and writes of committed transactions form a pattern that no serial order could produce. Here B's `COMMIT` fails with `40001`. SQL Server's `SERIALIZABLE` prevents the same anomaly with key-range locks, so the two sessions would block each other instead.

## Locks

Row locks and table locks held by one open transaction ([lines 76-91](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/06-mvcc.sql#L76-L91)):

```sql
-- Locks held by this session's open transaction
BEGIN;
SELECT runs FROM ci.workflow_totals WHERE workflow_name = 'Deploy to GitHub Pages' FOR UPDATE;
SELECT relation::regclass, mode, granted
FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'relation' AND relation::regclass::text LIKE 'ci.%'
ORDER BY 1, 2;
-- A row lock is not in pg_locks: it is written in the row version's xmax
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

- `SELECT … FOR UPDATE` takes a `ROW SHARE` lock on the table and its index, which only conflicts with `EXCLUSIVE` and `ACCESS EXCLUSIVE` ([table-level locks](https://www.postgresql.org/docs/18/explicit-locking.html#LOCKING-TABLES)).
- The row lock itself isn't in [`pg_locks`](https://www.postgresql.org/docs/18/view-pg-locks.html): it's written in the row version's `xmax`, which [`pgrowlocks`](https://www.postgresql.org/docs/18/pgrowlocks.html) reads. A million locked rows take no memory in the lock table, so PostgreSQL has no lock escalation.
- `ALTER TABLE … ADD COLUMN` takes `ACCESS EXCLUSIVE`, which conflicts with every other lock, including a plain `SELECT`'s `ACCESS SHARE`.

What a second session sees ([lines 162-206](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L162-L206)):

```csharp
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
```

```text
NOWAIT: 55P03: could not obtain lock on row in relation "workflow_runs"
lock_timeout: 55P03: canceling statement due to lock timeout
B reads without waiting: 65
B: wait_event_type=Lock, wait_event=transactionid, state=active, blocked by A: True
A commits, B's UPDATE returns: 1 row
```

- [`NOWAIT`](https://www.postgresql.org/docs/18/sql-select.html#SQL-FOR-UPDATE-SHARE) fails at once, and [`lock_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-LOCK-TIMEOUT) after 200 ms, both with `55P03`.
- A plain `SELECT` reads the committed version, without waiting.
- A waiting `UPDATE` shows `wait_event_type = Lock` and `wait_event = transactionid`: a session waiting for a row lock waits for the transaction that holds it to end.

A migration that runs `ALTER TABLE` while a long transaction reads the table waits for it, and every query that arrives after the `ALTER TABLE` waits behind it, because its `ACCESS EXCLUSIVE` request is queued first. Setting `lock_timeout` before a migration's DDL turns that outage into an error to retry.

## Deadlocks

A locks one row and B another, then each asks for the other's ([lines 208-237](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L208-L237)):

```csharp
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
```

```text
A locks Deploy to GitHub Pages, B locks Rust course examples
A waits for Rust course examples
B asks for Deploy to GitHub Pages: 40P01: deadlock detected
A's UPDATE returns 1 row
```

PostgreSQL doesn't look for deadlocks all the time. A session that has waited [`deadlock_timeout`](https://www.postgresql.org/docs/18/runtime-config-locks.html#GUC-DEADLOCK-TIMEOUT), one second by default, checks the waits for a cycle, and if it finds one, fails its own statement with `40P01`. The program gives B a shorter timeout than A, so B is always the session that checks, and fails. SQL Server's lock monitor chooses the victim itself, by `DEADLOCK_PRIORITY` and then by the cost of rolling back. In both, the fix is the same: take locks in the same order everywhere, and retry the victim.

## On Aurora

*To verify: nothing in this section ran on AWS.* Aurora PostgreSQL keeps PostgreSQL's MVCC: row versions, `VACUUM`, isolation levels and locks behave as in this lesson. What changes is that the readers are other instances, sharing the writer's storage.

- **Autovacuum is still needed.** AWS "strongly recommend[s]" it, and it's on by default ([autovacuum on Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum.html)). Adaptive autovacuum, `rds.adaptive_autovacuum`, raises its settings when the CloudWatch metric `MaximumUsedTransactionIDs` reaches `autovacuum_freeze_max_age` or 500 million, but "transaction ID wraparound is still possible", and AWS suggests a CloudWatch alarm on it. [Diagnosing table and index bloat](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.diag-table-ind-bloat.html) uses `pgstattuple`, as this lesson did.
- **A query on a replica holds back `VACUUM` on the writer.** "`hot_standby_feedback` is enabled by default and unmodifiable in Aurora PostgreSQL", and "it prevents autovacuum on the writer instance from removing dead rows that might still be needed by queries running on the reader instance" ([identifiable vacuum blockers](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum_Monitoring.Resolving_Identifiableblockers.html)). Exercise 1's open transaction can be on another instance: look for `backend_xmin` in `pg_stat_activity` on the readers too. On community PostgreSQL, `hot_standby_feedback` is off by default, and the [hot standby documentation](https://www.postgresql.org/docs/18/hot-standby.html) describes the trade-off.
- **DDL on the writer can cancel queries on the readers.** "Currently, only `ACCESS EXCLUSIVE` relation locks are replicated to reader instances", and the replay waits `max_standby_streaming_delay` before it cancels a reader query that holds a conflicting lock ([`Lock:Relation`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.lockrelation.html)). That page gives 30 seconds as the default; the parameter table for Aurora PostgreSQL 14 gives 14,000 ms: *to verify* on an 18 parameter group. The cancelled query gets "canceling statement due to conflict with recovery" ([replication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html)). The `ALTER TABLE` of the locks section would do that to a report running on a replica.
- **Extensions.** `pgstattuple` 1.5 and `pgrowlocks` 1.2 are in the [Aurora PostgreSQL 18 extension table](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html); `pageinspect` isn't, so the raw page of the row versions section can't be read there. `pg_visibility` 1.2 and `amcheck` 1.4 are.

The programs of this lesson need both sessions on the writer: through the reader endpoint, their `UPDATE`s would fail.

## Key takeaways

- An `UPDATE` writes a new row version; `xmin`, `xmax` and `ctid` show them, and `VACUUM` removes the ones no one can see.
- Bloat is space that `VACUUM` made reusable, not returned; `VACUUM FULL` returns it under an exclusive lock.
- HOT updates avoid index writes when no indexed column changes and the page has room: `fillfactor` and fewer indexes help.
- Readers never wait for writers. `READ COMMITTED` takes a snapshot per statement, `REPEATABLE READ` and `SERIALIZABLE` one per transaction.
- Read-then-write loses updates in `READ COMMITTED`; `REPEATABLE READ` and `SERIALIZABLE` fail with `40001` instead, and the application retries.
- Row locks live in the rows: no escalation, and `SKIP LOCKED` builds queues.
- `lock_timeout` before DDL, locks in a consistent order, and a retry for `40P01`.

## Exercises

1. Session A opens a `REPEATABLE READ` transaction and reads one row. Session B updates every row of the table, then runs `VACUUM`. How many dead versions are left, and why? What happens once A commits?

<details>
<summary>Solution</summary>

`l06-vacuum-horizon`, [lines 239-257](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L239-L257):

```csharp
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
```

```text
A opens a snapshot: 65 runs
B updates 21 rows
VACUUM while A is open: 21 dead row versions left
A still reads 65 runs
VACUUM after A commits: 0 dead row versions left
```

A's snapshot may still need the old versions, and it does: A still reads 65. `VACUUM` removes only the versions that are dead for the oldest snapshot of any open transaction, the *xmin horizon*, so all 21 stay. Once A commits, they go. An application that leaves a transaction open, such as a connection "idle in transaction" in a pool, stops `VACUUM` everywhere in the database; [`idle_in_transaction_session_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-IDLE-IN-TRANSACTION-SESSION-TIMEOUT) closes such sessions, and `pg_stat_activity.backend_xmin` shows who holds the horizon.

</details>

2. Rewrite the write-skew example in Java with `SERIALIZABLE`: each session disables its image only if two are enabled, and retries its whole transaction when it gets `40001`. What does B do on its second attempt?

<details>
<summary>Solution</summary>

`l06-retry`, [lines 60-114](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L06.java#L60-L114):

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
            // A's first attempt runs in the middle of B's transaction, so that both see two enabled images
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

A runs its whole transaction in the middle of B's, just before B's commit. B's first commit fails with `40001`. Its second attempt re-reads the count, finds only one enabled image, and keeps Windows. The retry must run the reads again, not only the failed statement: the decision depended on them. `40001` and `40P01` are the two SQLSTATEs worth retrying automatically.

</details>

3. The failed runs of the snapshot form a queue of reruns. Two workers each take the three first jobs that no one else is working on, in two open transactions. Which jobs does each get? Worker A deletes its jobs and commits, worker B rolls back: what's left?

<details>
<summary>Solution</summary>

`l06-skip-locked`, [lines 259-284](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/csharp/L06.cs#L259-L284):

```csharp
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
```

```text
worker A claims jobs 1, 2, 3
worker B claims jobs 4, 5, 6
A deleted its jobs, B rolled back: 13 jobs left, next claim: 4, 5, 6
```

`FOR UPDATE SKIP LOCKED` locks the rows it returns and skips the rows another transaction has locked, where a plain `FOR UPDATE` would wait: A gets jobs 1 to 3 and B jobs 4 to 6, without waiting. B's rollback releases its locks, so jobs 4 to 6 are the next ones to claim, and 13 of the 16 jobs are left. SQL Server writes this with the `READPAST` and `UPDLOCK` hints.

</details>

## Sources

- PostgreSQL 18 documentation: [concurrency control](https://www.postgresql.org/docs/18/mvcc.html), [transaction isolation](https://www.postgresql.org/docs/18/transaction-iso.html), [explicit locking](https://www.postgresql.org/docs/18/explicit-locking.html), [routine vacuuming](https://www.postgresql.org/docs/18/routine-vacuuming.html), [`VACUUM`](https://www.postgresql.org/docs/18/sql-vacuum.html), [heap-only tuples](https://www.postgresql.org/docs/18/storage-hot.html), [system columns](https://www.postgresql.org/docs/18/ddl-system-columns.html), [`pageinspect`](https://www.postgresql.org/docs/18/pageinspect.html), [`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html), [`pgrowlocks`](https://www.postgresql.org/docs/18/pgrowlocks.html), [`pg_locks`](https://www.postgresql.org/docs/18/view-pg-locks.html), [`pg_stat_activity`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW), [lock management settings](https://www.postgresql.org/docs/18/runtime-config-locks.html), [client connection defaults](https://www.postgresql.org/docs/18/runtime-config-client.html), [error codes](https://www.postgresql.org/docs/18/errcodes-appendix.html)
- Java: [`Connection`](https://docs.oracle.com/en/java/javase/25/docs/api/java.sql/java/sql/Connection.html)
- SQL Server: [transaction locking and row versioning guide](https://learn.microsoft.com/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide), [accelerated database recovery](https://learn.microsoft.com/sql/relational-databases/accelerated-database-recovery-concepts), [deadlocks guide](https://learn.microsoft.com/sql/relational-databases/sql-server-deadlocks-guide), [`SET DEADLOCK_PRIORITY`](https://learn.microsoft.com/sql/t-sql/statements/set-deadlock-priority-transact-sql), [table hints](https://learn.microsoft.com/sql/t-sql/queries/hints-transact-sql-table), [`SET LOCK_TIMEOUT`](https://learn.microsoft.com/sql/t-sql/statements/set-lock-timeout-transact-sql), [error 1222](https://learn.microsoft.com/sql/relational-databases/errors-events/mssqlserver-1222-database-engine-error)
- Amazon Aurora: [autovacuum](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum.html), [vacuum blockers](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum_Monitoring.Resolving_Identifiableblockers.html), [table and index bloat](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.diag-table-ind-bloat.html), [`Lock:Relation`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.lockrelation.html), [replication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html), [extension versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), all read on 2026-09-16
