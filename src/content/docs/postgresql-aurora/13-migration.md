---
title: "13. Migrating from SQL Server, and costs"
description: A SQL Server 2025 database with the course's CI data, migrated to PostgreSQL 18 by hand, by a C# program with SqlClient and binary COPY, and by pgloader — collations, trailing spaces, datetime precision, GUID order, NULLs in unique constraints, identities and transactions compared on both servers — then AWS DMS, Babelfish and the cost of Aurora PostgreSQL from AWS's documentation and price list, read on 2026-09-16.
sidebar:
  order: 13
---

The previous lessons compared PostgreSQL with SQL Server one feature at a time. This one moves a database. It starts from a real SQL Server: [SQL Server 2025](https://learn.microsoft.com/sql/sql-server/what-s-new-in-sql-server-2025) in Microsoft's container image `mcr.microsoft.com/mssql/server:2025-CU9-ubuntu-24.04` (17.0.5005.3, digest `sha256:2b5b581621126574f3d1f75e78d3eebe8d05aedb59ad0cfdf9aa42cb0634d726`), holding the same GitHub Actions runs and jobs as the rest of the course. The data then goes to PostgreSQL 18 twice: with a C# program, and with [pgloader](https://pgloader.io/). Both run in `check.sh`'s `mssql` mode and in CI, where SQL Server is a service container next to PostgreSQL.

The code:

- [`mssql.sh`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql.sh) starts SQL Server and runs [`sqlcmd`](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility) inside it;
- [`mssql/13-source.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql) creates the source database;
- [`sql/mssql-target.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target.sql) and [`sql/mssql-target-after.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target-after.sql) are the converted schema;
- [`csharp-mssql/L13.cs`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/csharp-mssql/L13.cs) copies and validates;
- [`sql/13-migration.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql) shows what behaves differently once the data is in PostgreSQL;
- [`sql/pgloader-check.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/pgloader-check.sql) looks at what pgloader created.

AWS's migration services can't run locally, and the course uses no AWS account: [AWS DMS](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html), [Babelfish for Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish.html) and the prices come from AWS's documentation and price list, read on 2026-09-16, and are *to verify*.

| SQL Server tool | For PostgreSQL and Aurora |
|---|---|
| [Data Migration Assistant](https://learn.microsoft.com/sql/dma/dma-overview), SSMA | DMS Schema Conversion or the AWS Schema Conversion Tool; Babelfish Compass to assess T-SQL for Babelfish |
| `bcp`, `SqlBulkCopy`, SSIS | `COPY` from a program (lesson 4), pgloader, AWS DMS full load |
| transactional replication, change data capture | AWS DMS ongoing replication, which reads SQL Server's MS-Replication or MS-CDC |
| a T-SQL application moved as it is | Babelfish: Aurora PostgreSQL speaking TDS on port 1433 |

## The database to migrate

`bash mssql.sh start` runs the container; SQL Server on Linux needs "at least 2 GB of RAM" ([Docker quickstart](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker)), and `mssql.sh` caps it at 2,048 MB with `MSSQL_MEMORY_LIMIT_MB`. The source schema is what a SQL Server team could have written: PascalCase names, `nvarchar`, `tinyint`, three date types, a computed column, `rowversion`, an `IDENTITY` key, a `uniqueidentifier`, `money` ([`mssql/13-source.sql`, lines 12-66](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L12-L66)):

```sql
CREATE TABLE dbo.Runs (
    RunId        bigint            NOT NULL PRIMARY KEY,
    WorkflowName nvarchar(100)     NOT NULL,
    Event        varchar(30)       NOT NULL,
    Conclusion   varchar(20)       NULL,
    HeadBranch   nvarchar(255)     NOT NULL,
    HeadSha      char(40)          NOT NULL,
    Attempt      tinyint           NOT NULL CHECK (Attempt >= 1),
    CreatedAt    datetime2(0)      NOT NULL,
    StartedAt    datetime          NOT NULL,
    UpdatedAt    datetimeoffset(7) NOT NULL,
    IsRerun      AS CAST(CASE WHEN Attempt > 1 THEN 1 ELSE 0 END AS bit)
);

CREATE TABLE dbo.Jobs (
    JobId       bigint        NOT NULL PRIMARY KEY,
    RunId       bigint        NOT NULL REFERENCES dbo.Runs,
    Name        nvarchar(200) NOT NULL,
    Conclusion  varchar(20)   NULL,
    RunnerName  nvarchar(100) NULL,
    StartedAt   datetime2(7)  NOT NULL,
    CompletedAt datetime2(7)  NOT NULL,
    RowVer      rowversion
);

-- One row per label: SQL Server has no array type
CREATE TABLE dbo.JobLabels (
    JobId bigint        NOT NULL REFERENCES dbo.Jobs,
    Label nvarchar(100) NOT NULL,
    CONSTRAINT PK_JobLabels PRIMARY KEY (JobId, Label)
);

CREATE TABLE dbo.Steps (
    JobId       bigint        NOT NULL REFERENCES dbo.Jobs,
    Number      smallint      NOT NULL,
    Name        nvarchar(200) NOT NULL,
    Conclusion  varchar(20)   NULL,
    StartedAt   datetime2(0)  NOT NULL,
    CompletedAt datetime2(0)  NOT NULL,
    PRIMARY KEY (JobId, Number)
);

-- Notes written by people, with the types a SQL Server schema often has: an IDENTITY key, a GUID, money, datetime
CREATE TABLE dbo.Notes (
    NoteId       int IDENTITY(1, 1) PRIMARY KEY,
    NoteGuid     uniqueidentifier   NOT NULL UNIQUE,
    RunId        bigint             NULL REFERENCES dbo.Runs,
    Author       nvarchar(50)       NOT NULL,
    Tag          varchar(20)        NULL CONSTRAINT UQ_Notes_Tag UNIQUE,
    Body         nvarchar(max)      NOT NULL,
    Cost         money              NULL,
    WrittenAt    datetime           NOT NULL,
    WrittenLocal datetimeoffset(7)  NOT NULL
);
CREATE INDEX IX_Jobs_RunId ON dbo.Jobs (RunId) INCLUDE (Conclusion);
```

The runs, jobs and steps come from the same JSON files as lesson 2, read with [`OPENROWSET(BULK …)`](https://learn.microsoft.com/sql/t-sql/functions/openrowset-bulk-transact-sql) and [`OPENJSON`](https://learn.microsoft.com/sql/t-sql/functions/openjson-transact-sql); three notes are written by hand, to hold the values that don't survive a migration unchanged (lines 98-104):

```sql
INSERT INTO dbo.Notes (NoteGuid, RunId, Author, Tag, Body, Cost, WrittenAt, WrittenLocal) VALUES
    ('6F9619FF-8B86-D011-B42D-00C04FC964FF', 34852867099, N'Reviewer', 'Slow', N'Deploy took 2.5 minutes', 0.0125,
     '2026-09-14 14:05:00.001', '2026-09-14 16:05:00.1234567 +02:00'),
    ('00000000-0000-0000-0000-000000000001', 34852867099, N'reviewer ', NULL, N'Looks fine now', NULL,
     '2026-09-14 14:06:00.005', '2026-09-14 10:06:00.9999999 -04:00'),
    ('01000000-0000-0000-0000-000000000000', NULL, N'REVIEWER', 'flaky', N'Café au lait', 3.5,
     '2026-09-14 14:07:00.998', '2026-09-14 14:07:00 +00:00');
```

The output starts with the database's collation and the row counts ([`expected/mssql-13-source.txt`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/mssql-13-source.txt)):

```text
Changed database context to 'master'.
Changed database context to 'ci'.
collation
---------
SQL_Latin1_General_CP1_CI_AS
table|rows
-----|----
Runs|125
Jobs|315
JobLabels|315
Steps|2204
Notes|3
```

`sqlcmd` runs with `-W -s '|'`: trimmed columns separated by bars. `SQL_Latin1_General_CP1_CI_AS` is the default for a US English installation ([collations](https://learn.microsoft.com/sql/relational-databases/collations/collation-and-unicode-support#server-level-collations)): case-insensitive (`CI`), accent-sensitive (`AS`).

## Seven behaviours to check before moving the data

The same questions, asked of SQL Server ([lines 114-142](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L114-L142)):

```sql
-- datetime keeps 1/300 of a second: .001 was stored as .000, .005 as .007
SELECT NoteId, WrittenAt, WrittenLocal FROM dbo.Notes ORDER BY NoteId;

-- The default collation ignores case, and = ignores trailing spaces
SELECT COUNT(DISTINCT Author) AS authors, SUM(CASE WHEN Author = N'reviewer' THEN 1 ELSE 0 END) AS [= 'reviewer']
FROM dbo.Notes;
BEGIN TRY
    INSERT INTO dbo.Notes (NoteGuid, Author, Tag, Body, WrittenAt, WrittenLocal)
    VALUES (NEWID(), N'Reviewer', 'SLOW', N'again', '2026-09-14', '2026-09-14 00:00 +00:00');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS message;
END CATCH;
-- A UNIQUE constraint accepts one NULL, not two
BEGIN TRY
    INSERT INTO dbo.Notes (NoteGuid, Author, Tag, Body, WrittenAt, WrittenLocal)
    VALUES (NEWID(), N'Reviewer', NULL, N'again', '2026-09-14', '2026-09-14 00:00 +00:00');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS message;
END CATCH;

-- uniqueidentifier sorts by its last six bytes first; NULL sorts first
SELECT NoteGuid, Cost FROM dbo.Notes ORDER BY NoteGuid;
SELECT NoteId, Cost FROM dbo.Notes ORDER BY Cost;

-- + with NULL gives NULL, CONCAT ignores it; TOP and ISNULL
SELECT TOP (2) NoteId, Tag + N': ' + Body AS plus, CONCAT(Tag, N': ', Body) AS concat, ISNULL(Tag, 'none') AS tag
FROM dbo.Notes ORDER BY NoteId;
```

```text
NoteId|WrittenAt|WrittenLocal
------|---------|------------
1|2026-09-14 14:05:00.000|2026-09-14 16:05:00.1234567 +02:00
2|2026-09-14 14:06:00.007|2026-09-14 10:06:00.9999999 -04:00
3|2026-09-14 14:07:00.997|2026-09-14 14:07:00.0000000 +00:00
authors|= 'reviewer'
-------|------------
1|3
error|message
-----|-------
2627|Violation of UNIQUE KEY constraint 'UQ_Notes_Tag'. Cannot insert duplicate key in object 'dbo.Notes'. The duplicate key value is (SLOW).
error|message
-----|-------
2627|Violation of UNIQUE KEY constraint 'UQ_Notes_Tag'. Cannot insert duplicate key in object 'dbo.Notes'. The duplicate key value is (<NULL>).
NoteGuid|Cost
--------|----
01000000-0000-0000-0000-000000000000|3.5000
00000000-0000-0000-0000-000000000001|NULL
6F9619FF-8B86-D011-B42D-00C04FC964FF|.0125
NoteId|Cost
------|----
2|NULL
1|.0125
3|3.5000
NoteId|plus|concat|tag
------|----|------|---
1|Slow: Deploy took 2.5 minutes|Slow: Deploy took 2.5 minutes|Slow
2|NULL|: Looks fine now|none
```

And of PostgreSQL, on the converted table of the next section, with the notes as the program copies them ([`sql/13-migration.sql`, lines 23-50](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L23-L50)). The script adds a fourth note first, number 7, for the identity section:

```sql
-- timestamptz keeps the instant, not the offset: every value comes back in the session's time zone
SELECT note_id, written_at, written_local FROM migrated.notes ORDER BY note_id;

-- The ci collation ignores case, but not trailing spaces: three authors become two
SELECT count(DISTINCT author) AS authors, count(*) FILTER (WHERE author = 'reviewer') AS "= 'reviewer'"
FROM migrated.notes;
-- The same column compared with the default collation of the database
SELECT count(DISTINCT author COLLATE "default") AS authors FROM migrated.notes;
-- rtrim where SQL Server's padding rules mattered
SELECT count(DISTINCT rtrim(author)) AS authors FROM migrated.notes;

-- LIKE on a nondeterministic collation: new in PostgreSQL 18
SELECT note_id, author FROM migrated.notes WHERE author LIKE 'rev%' ORDER BY note_id;

-- The unique constraint compares tags with the ci collation too, and accepts a single NULL
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', 'SLOW', 'again', '2026-09-14', '2026-09-14 00:00+00');
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', NULL, 'again', '2026-09-14', '2026-09-14 00:00+00');

-- uuid sorts byte by byte, from the left; NULL sorts last in ascending order
SELECT note_guid, cost FROM migrated.notes ORDER BY note_guid;
SELECT note_id, cost FROM migrated.notes ORDER BY cost;
SELECT note_id, cost FROM migrated.notes ORDER BY cost NULLS FIRST;

-- || with NULL gives NULL, concat ignores it; FETCH FIRST ... WITH TIES, and coalesce for ISNULL
SELECT note_id, tag || ': ' || body AS plus, concat(tag, ': ', body) AS concat, coalesce(tag, 'none') AS tag
FROM migrated.notes ORDER BY note_id FETCH FIRST 2 ROWS ONLY;
```

```text
 note_id |       written_at        |         written_local
---------+-------------------------+-------------------------------
       1 | 2026-09-14 14:05:00     | 2026-09-14 14:05:00.123456+00
       2 | 2026-09-14 14:06:00.007 | 2026-09-14 14:06:00.999999+00
       3 | 2026-09-14 14:07:00.997 | 2026-09-14 14:07:00+00
       7 | 2026-09-16 00:00:00     | 2026-09-16 00:00:00+00
(4 rows)

 authors | = 'reviewer'
---------+--------------
       2 |            3
(1 row)

 authors
---------
       3
(1 row)

 authors
---------
       1
(1 row)

 note_id |  author
---------+-----------
       1 | Reviewer
       2 | reviewer
       3 | REVIEWER
       7 | Reviewer
(4 rows)

ERROR:  duplicate key value violates unique constraint "notes_tag_key"
DETAIL:  Key (tag)=(SLOW) already exists.
ERROR:  duplicate key value violates unique constraint "notes_tag_key"
DETAIL:  Key (tag)=(null) already exists.
              note_guid               |  cost
--------------------------------------+--------
 00000000-0000-0000-0000-000000000001 |
 01000000-0000-0000-0000-000000000000 | 3.5000
 6f9619ff-8b86-d011-b42d-00c04fc964ff | 0.0125
 70000000-0000-0000-0000-000000000000 |
(4 rows)

 note_id |  cost
---------+--------
       1 | 0.0125
       3 | 3.5000
       2 |
       7 |
(4 rows)

 note_id |  cost
---------+--------
       2 |
       7 |
       1 | 0.0125
       3 | 3.5000
(4 rows)

 note_id |             plus              |            concat             | tag
---------+-------------------------------+-------------------------------+------
       1 | Slow: Deploy took 2.5 minutes | Slow: Deploy took 2.5 minutes | Slow
       2 |                               | : Looks fine now              | none
(2 rows)
```

1. **`datetime` isn't precise to the millisecond.** Its values are "rounded to increments of .000, .003, or .007 seconds" ([`datetime`](https://learn.microsoft.com/sql/t-sql/data-types/datetime-transact-sql)): `.001` was stored as `.000`, `.005` as `.007`, `.998` as `.997`. The migration copies the rounded values; nothing can recover the originals.
2. **`timestamptz` keeps the instant, not the offset.** `datetimeoffset` kept `+02:00` and `-04:00`; PostgreSQL returns every value in the session's time zone, UTC here. Npgsql's documentation says the same: "only a UTC timestamp is stored" ([date and time types](https://www.npgsql.org/doc/types/datetime.html)). If the writer's offset matters, it needs its own column.
3. **Case.** With the database's default collation, `Reviewer`, `reviewer ` and `REVIEWER` are three authors. The target declares an [ICU nondeterministic collation](https://www.postgresql.org/docs/18/collation.html#COLLATION-NONDETERMINISTIC), `und-u-ks-level2`, which compares without case: they become two.
4. **Trailing spaces.** "Transact-SQL considers the strings 'abc' and 'abc ' to be equivalent for most comparison operations" ([string comparison](https://learn.microsoft.com/sql/t-sql/language-elements/string-comparison-assignment#remarks)), so SQL Server counts one author. PostgreSQL's `varchar` and `text` keep the space significant; `rtrim` gives SQL Server's count back. The `citext` extension ignores case too, but its [documentation](https://www.postgresql.org/docs/18/citext.html) now says: "Consider using nondeterministic collations … instead of this module."
5. **`LIKE` on a case-insensitive column.** It works in PostgreSQL 18: "Allow LIKE with nondeterministic collations" ([release notes](https://www.postgresql.org/docs/18/release-18.html#RELEASE-18-UTILITY)). `ILIKE` "does not support nondeterministic collations" ([pattern matching](https://www.postgresql.org/docs/18/functions-matching.html#FUNCTIONS-LIKE)).
6. **Unique constraints and `NULL`.** SQL Server refused `SLOW` next to `Slow`, and a second `NULL` tag. PostgreSQL treats `NULL`s as distinct in a unique constraint "unless NULLS NOT DISTINCT is specified" ([`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html)): the target declares it, and the `ci` collation, to keep both rules.
7. **Orders.** `uniqueidentifier` "ordering is not implemented by comparing the bit patterns of the two values" ([`uniqueidentifier`](https://learn.microsoft.com/sql/t-sql/data-types/uniqueidentifier-transact-sql#remarks)): SQL Server compares "the last six bytes of a value" first ([comparing GUIDs](https://learn.microsoft.com/sql/connect/ado-net/sql/compare-guid-uniqueidentifier-values#comparing-guid-values)), PostgreSQL's `uuid` byte by byte from the left, so the three notes come in a different order. SQL Server sorts `NULL` first, as "the lowest possible values" ([`ORDER BY`](https://learn.microsoft.com/sql/t-sql/queries/select-order-by-clause-transact-sql#arguments)); PostgreSQL sorts it last in ascending order, unless `NULLS FIRST`. A keyset pagination on a GUID, or a report that expects `NULL`s at the top, changes silently.

The last query is the same in both: `+` and `||` give `NULL` when one side is `NULL`, `CONCAT` and `concat` skip it; `ISNULL` becomes `coalesce`, `TOP (2)` becomes `FETCH FIRST 2 ROWS ONLY`.

## Transactions after an error

SQL Server and PostgreSQL disagree about what an error does to a transaction ([lines 145-172](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L145-L172)):

```sql
-- Without SET XACT_ABORT, a failed statement doesn't end the transaction: XACT_STATE() is still 1, and COMMIT keeps
-- the rows inserted around it. (The error is caught: sqlcmd 18.6 drops the results that follow an uncaught error.)
BEGIN TRANSACTION;
INSERT INTO dbo.JobLabels (JobId, Label) VALUES (104004920113, N'self-hosted');
BEGIN TRY
    INSERT INTO dbo.JobLabels (JobId, Label) VALUES (104004920113, N'ubuntu-latest');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS message, XACT_STATE() AS xact_state;
END CATCH;
INSERT INTO dbo.JobLabels (JobId, Label) VALUES (104004920113, N'linux');
COMMIT;
SELECT Label FROM dbo.JobLabels WHERE JobId = 104004920113 ORDER BY Label;
DELETE FROM dbo.JobLabels WHERE JobId = 104004920113 AND Label <> N'ubuntu-latest';

-- With SET XACT_ABORT ON, the same error dooms the transaction: XACT_STATE() is -1, only a rollback is possible
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO dbo.JobLabels (JobId, Label) VALUES (104004920113, N'self-hosted');
    INSERT INTO dbo.JobLabels (JobId, Label) VALUES (104004920113, N'ubuntu-latest');
END TRY
BEGIN CATCH
    SELECT XACT_STATE() AS xact_state;
    ROLLBACK;
END CATCH;
SET XACT_ABORT OFF;
SELECT COUNT(*) AS labels FROM dbo.JobLabels WHERE JobId = 104004920113;
```

```text
message|xact_state
-------|----------
Violation of PRIMARY KEY constraint 'PK_JobLabels'. Cannot insert duplicate key in object 'dbo.JobLabels'. The duplicate key value is (104004920113, ubuntu-latest).|1
Label
-----
linux
self-hosted
ubuntu-latest
xact_state
----------
-1
labels
------
1
```

With [`SET XACT_ABORT`](https://learn.microsoft.com/sql/t-sql/statements/set-xact-abort-transact-sql#remarks) at its default, "OFF is the default setting in a T-SQL statement", a duplicate key ends the statement, not the transaction: `XACT_STATE()` is still 1 and `COMMIT` keeps `self-hosted` and `linux`. With `XACT_ABORT ON`, the transaction can only be rolled back. The error is caught with `TRY … CATCH` because `sqlcmd` 18.6 dropped every result after an uncaught error in a script (see the [journal](../journal/)).

PostgreSQL behaves like `XACT_ABORT ON`, and more strictly ([`sql/13-migration.sql`, lines 52-71](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L52-L71)):

```sql
-- An error inside a transaction aborts the whole transaction: the next statement is refused, COMMIT rolls back
BEGIN;
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES ('10000000-0000-0000-0000-000000000000', 'Reviewer', 'retry', 'kept?', '2026-09-16', '2026-09-16 00:00+00');
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', 'Retry', 'duplicate tag', '2026-09-16', '2026-09-16 00:00+00');
SELECT count(*) FROM migrated.notes;
COMMIT;
SELECT count(*) AS kept FROM migrated.notes WHERE tag = 'retry';

-- A savepoint gives back SQL Server's behaviour for one statement
BEGIN;
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES ('10000000-0000-0000-0000-000000000000', 'Reviewer', 'retry', 'kept', '2026-09-16', '2026-09-16 00:00+00');
SAVEPOINT duplicate;
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', 'Retry', 'duplicate tag', '2026-09-16', '2026-09-16 00:00+00');
ROLLBACK TO SAVEPOINT duplicate;
COMMIT;
SELECT count(*) AS kept FROM migrated.notes WHERE tag = 'retry';
```

```text
BEGIN
INSERT 0 1
ERROR:  duplicate key value violates unique constraint "notes_tag_key"
DETAIL:  Key (tag)=(Retry) already exists.
ERROR:  current transaction is aborted, commands ignored until end of transaction block
ROLLBACK
 kept
------
    0
(1 row)

BEGIN
INSERT 0 1
SAVEPOINT
ERROR:  duplicate key value violates unique constraint "notes_tag_key"
DETAIL:  Key (tag)=(Retry) already exists.
ROLLBACK
COMMIT
 kept
------
    1
(1 row)
```

After the error, every statement is refused until the end of the transaction, and `COMMIT` answers `ROLLBACK`. Code that relied on SQL Server continuing after a failed statement needs a [`SAVEPOINT`](https://www.postgresql.org/docs/18/sql-savepoint.html) around that statement. A driver that sends the next statement anyway gets SQLSTATE `25P02`, `in_failed_sql_transaction` ([error codes](https://www.postgresql.org/docs/18/errcodes-appendix.html)).

## Converting the schema by hand

The target schema ([`sql/mssql-target.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target.sql#L1-L68)):

```sql
-- Lesson 13: the tables of mssql/13-source.sql converted by hand, before the load. Names in snake_case, so that
-- they need no quotes; keys, but no foreign keys or secondary indexes yet (mssql-target-after.sql adds them).
DROP SCHEMA IF EXISTS migrated CASCADE;
CREATE SCHEMA migrated;

-- SQL_Latin1_General_CP1_CI_AS compares without case; this ICU collation does the same, and isn't deterministic:
-- two strings can be equal without being the same bytes
CREATE COLLATION migrated.ci (provider = icu, locale = 'und-u-ks-level2', deterministic = false);

CREATE TABLE migrated.runs (
    run_id        bigint PRIMARY KEY,
    workflow_name varchar(100) NOT NULL,
    event         varchar(30) NOT NULL,
    conclusion    varchar(20),
    head_branch   varchar(255) NOT NULL,
    head_sha      char(40) NOT NULL,
    -- tinyint is 0 to 255; PostgreSQL has no one-byte integer
    attempt       smallint NOT NULL CHECK (attempt BETWEEN 1 AND 255),
    -- datetime2, datetime and datetimeoffset all hold UTC times here: timestamptz
    created_at    timestamptz(0) NOT NULL,
    started_at    timestamptz(3) NOT NULL,
    updated_at    timestamptz NOT NULL,
    -- a computed column that isn't persisted: a virtual generated column (PostgreSQL 18)
    is_rerun      boolean GENERATED ALWAYS AS (attempt > 1) VIRTUAL
);

CREATE TABLE migrated.jobs (
    job_id       bigint PRIMARY KEY,
    run_id       bigint NOT NULL,
    name         varchar(200) NOT NULL,
    conclusion   varchar(20),
    runner_name  varchar(100),
    started_at   timestamptz NOT NULL,
    completed_at timestamptz NOT NULL
    -- no rowversion: the xmin system column plays that role for optimistic concurrency
);

CREATE TABLE migrated.job_labels (
    job_id bigint NOT NULL,
    label  varchar(100) NOT NULL,
    PRIMARY KEY (job_id, label)
);

CREATE TABLE migrated.steps (
    job_id       bigint NOT NULL,
    number       smallint NOT NULL,
    name         varchar(200) NOT NULL,
    conclusion   varchar(20),
    started_at   timestamptz(0) NOT NULL,
    completed_at timestamptz(0) NOT NULL,
    PRIMARY KEY (job_id, number)
);

CREATE TABLE migrated.notes (
    -- BY DEFAULT, so that the load can keep the source's values
    note_id       integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    note_guid     uuid NOT NULL UNIQUE,
    run_id        bigint,
    author        varchar(50) COLLATE migrated.ci NOT NULL,
    -- NULLS NOT DISTINCT: one NULL at most, as in SQL Server
    tag           varchar(20) COLLATE migrated.ci UNIQUE NULLS NOT DISTINCT,
    body          text NOT NULL,
    cost          numeric(19, 4),
    -- datetime has no time zone: timestamp, to the millisecond
    written_at    timestamp(3) NOT NULL,
    -- datetimeoffset keeps the writer's offset; timestamptz keeps the instant only
    written_local timestamptz NOT NULL
);
```

The decisions, column type by column type:

| SQL Server | PostgreSQL here | Why |
|---|---|---|
| `PascalCase` names | `snake_case` | unquoted identifiers fold to lower case (lesson 1); `"RunId"` would need quotes everywhere |
| `nvarchar(n)`, `varchar(n)` | `varchar(n)`, `text` | PostgreSQL's strings are all Unicode (UTF-8 here); the length is a constraint, not a storage choice |
| `char(40)` | `char(40)` | same padding semantics for a fixed-length hash |
| `tinyint` | `smallint` with a `CHECK` | no one-byte integer |
| `bit` computed column | `boolean GENERATED ALWAYS AS (…) VIRTUAL` | a virtual generated column, new in PostgreSQL 18 and now "the default kind" ([generated columns](https://www.postgresql.org/docs/18/ddl-generated-columns.html)) |
| `datetime2(0)`, `datetime2(7)` | `timestamptz(0)`, `timestamptz` | UTC values; PostgreSQL's resolution is "1 microsecond" ([date/time types](https://www.postgresql.org/docs/18/datatype-datetime.html)), `datetime2` has 100 ns |
| `datetime` | `timestamp(3)`, `timestamptz(3)` | no time zone in the type: `timestamp` if the values are local, `timestamptz` if they are UTC |
| `datetimeoffset(7)` | `timestamptz` | the offset is lost |
| `money` | `numeric(19, 4)` | PostgreSQL's `money` has its "fractional precision … determined by the database's lc_monetary setting" ([monetary types](https://www.postgresql.org/docs/18/datatype-money.html)) |
| `uniqueidentifier` | `uuid` | the same 16 bytes, a different sort order |
| `rowversion` | nothing | for optimistic concurrency, Npgsql's EF Core provider uses the `xmin` system column ([concurrency tokens](https://www.npgsql.org/efcore/modeling/concurrency.html)) |
| `int IDENTITY(1, 1)` | `integer GENERATED BY DEFAULT AS IDENTITY` | `BY DEFAULT`, so that the load can write the source's keys |
| `CI_AS` collation | an ICU nondeterministic collation, on the columns that need it | a nondeterministic collation costs performance, "B-tree cannot use deduplication with indexes that use a nondeterministic collation" ([collations](https://www.postgresql.org/docs/18/collation.html#COLLATION-NONDETERMINISTIC)) |

Foreign keys and secondary indexes come after the load ([`sql/mssql-target-after.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target-after.sql)):

```sql
-- Lesson 13: what the target gets after the load. Foreign keys are checked once, on the loaded rows; indexes are
-- built once instead of being updated row by row.
ALTER TABLE migrated.jobs ADD FOREIGN KEY (run_id) REFERENCES migrated.runs;
ALTER TABLE migrated.job_labels ADD FOREIGN KEY (job_id) REFERENCES migrated.jobs;
ALTER TABLE migrated.steps ADD FOREIGN KEY (job_id) REFERENCES migrated.jobs;
ALTER TABLE migrated.notes ADD FOREIGN KEY (run_id) REFERENCES migrated.runs;
-- IX_Jobs_RunId ... INCLUDE (Conclusion) has the same syntax
CREATE INDEX jobs_run_id ON migrated.jobs (run_id) INCLUDE (conclusion);
ANALYZE migrated.runs, migrated.jobs, migrated.job_labels, migrated.steps, migrated.notes;
```

## Copying the data with C#

[`Microsoft.Data.SqlClient`](https://learn.microsoft.com/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace) 7.0.3 reads each table; Npgsql's binary `COPY` (lesson 4) writes it. Each table has a `SELECT`, a `COPY` and a function that writes one row's columns with explicit types ([`L13.cs`, lines 19-23 and 76-135](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/csharp-mssql/L13.cs#L19-L135)):

```csharp
    // One table to copy: the SELECT on SQL Server, the COPY on PostgreSQL, and how each column is written
    record Table(string Name, string Select, string Copy, Action<SqlDataReader, NpgsqlBinaryImporter> Write);

    // datetime and datetime2 come back with DateTimeKind.Unspecified; Npgsql writes only UTC DateTimes to timestamptz
    static DateTime Utc(SqlDataReader r, int i) => DateTime.SpecifyKind(r.GetDateTime(i), DateTimeKind.Utc);
```

```csharp
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
```

```text
runs: 125 rows copied
jobs: 315 rows copied
job_labels: 315 rows copied
steps: 2204 rows copied
notes: 3 rows copied
notes.note_id restarts with 7
```

- **`DateTime.Kind`.** SqlClient returns `datetime` and `datetime2` values as `DateTime` with an unspecified kind; "Npgsql maps UTC DateTime to timestamp with time zone" ([date and time types](https://www.npgsql.org/doc/types/datetime.html)), so the program states that these are UTC with `DateTime.SpecifyKind`. `datetimeoffset` becomes `DateTimeOffset.UtcDateTime`.
- **A separate project.** The program is in `csharp-mssql`, not with the other examples: in `csharp/`, where `InvariantGlobalization` is on, `SqlConnection.OpenAsync` threw `System.NotSupportedException: Globalization Invariant Mode is not supported.`
- **One table at a time, in one transaction each.** Enough for 2,962 rows. A real migration also has to deal with writes during the copy, which is what DMS's ongoing replication is for.
- **The identity.** SQL Server's `IDENT_CURRENT` is 6, not 3: the two inserts that failed on the unique constraint, and the procedure's note deleted later, used values 4 to 6 ([source output, lines 62-67](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/mssql-13-source.txt#L62-L67)). The program restarts `note_id` at 7.

What happens if nobody restarts the identity ([`sql/13-migration.sql`, lines 14-21](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L14-L21)):

```sql
-- The identity column still starts at 1: the copied rows didn't advance it. RESTART WITH continues after
-- SQL Server's IDENT_CURRENT, 6
INSERT INTO migrated.notes (note_guid, author, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', 'first note after the migration', '2026-09-16', '2026-09-16 00:00+00');
ALTER TABLE migrated.notes ALTER COLUMN note_id RESTART WITH 7;
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES ('70000000-0000-0000-0000-000000000000', 'Reviewer', 'migrated', 'first note after the migration', '2026-09-16', '2026-09-16 00:00+00')
RETURNING note_id;
```

```text
INSERT 0 3
ERROR:  duplicate key value violates unique constraint "notes_pkey"
DETAIL:  Key (note_id)=(1) already exists.
ALTER TABLE
 note_id
---------
       7
(1 row)

INSERT 0 1
```

## Validating the copy

A count per table isn't a validation. The program reads every row from both servers, in key order, as text in a form both agree on, then compares the rows and a SHA-256 of all of them ([`L13.cs`, lines 165-211](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/csharp-mssql/L13.cs#L165-L211)):

```csharp
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
```

```text
runs: 125 and 125 rows, SHA-256 D7C59BE754C6 and D7C59BE754C6, 0 rows differ
jobs: 315 and 315 rows, SHA-256 F0E778A31B09 and F0E778A31B09, 0 rows differ
job_labels: 315 and 315 rows, SHA-256 13A05234F3CD and 13A05234F3CD, 0 rows differ
steps: 2204 and 2204 rows, SHA-256 497D422AFAFA and 497D422AFAFA, 0 rows differ
notes: 3 and 3 rows, SHA-256 B0585EF1C97F and 6A08288C6B5E, 2 rows differ
  SQL Server: 1|6f9619ff-8b86-d011-b42d-00c04fc964ff|34852867099|Reviewer|Slow|Deploy took 2.5 minutes|0.0125|2026-09-14 14:05:00.0000000|2026-09-14 14:05:00.1234567
  PostgreSQL: 1|6f9619ff-8b86-d011-b42d-00c04fc964ff|34852867099|Reviewer|Slow|Deploy took 2.5 minutes|0.0125|2026-09-14 14:05:00.0000000|2026-09-14 14:05:00.1234560
  SQL Server: 2|00000000-0000-0000-0000-000000000001|34852867099|reviewer |NULL|Looks fine now|NULL|2026-09-14 14:06:00.0070000|2026-09-14 14:06:00.9999999
  PostgreSQL: 2|00000000-0000-0000-0000-000000000001|34852867099|reviewer |NULL|Looks fine now|NULL|2026-09-14 14:06:00.0070000|2026-09-14 14:06:00.9999990
```

Four tables are identical. In `notes`, two `datetimeoffset(7)` values lost their seventh decimal: `.1234567` became `.123456` and `.9999999` became `.999999`. Npgsql truncated the 100-nanosecond ticks to PostgreSQL's microseconds, which is what `timestamptz` can hold. The fix is a decision, not code: accept microseconds, or keep the ticks in a `bigint` next to the timestamp.

## Code in the database

The source also has a view and a procedure ([lines 175-190](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L175-L190)):

```sql
-- Code that lives in the database: a view and a procedure, to convert too
CREATE VIEW dbo.SlowJobs AS
SELECT TOP (5) WITH TIES j.Name, r.WorkflowName, DATEDIFF(second, j.StartedAt, j.CompletedAt) AS Seconds
FROM dbo.Jobs AS j JOIN dbo.Runs AS r ON r.RunId = j.RunId
ORDER BY DATEDIFF(second, j.StartedAt, j.CompletedAt) DESC;
GO
CREATE PROCEDURE dbo.AddNote @RunId bigint, @Author nvarchar(50), @Body nvarchar(max), @Tag varchar(20), @NoteId int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Runs WHERE RunId = @RunId)
        THROW 50001, 'Unknown run', 1;
    INSERT INTO dbo.Notes (NoteGuid, RunId, Author, Tag, Body, WrittenAt, WrittenLocal)
    VALUES (NEWID(), @RunId, @Author, @Tag, @Body, GETUTCDATE(), SYSDATETIMEOFFSET());
    SET @NoteId = SCOPE_IDENTITY();
END;
```

The procedure as a PL/pgSQL function (lesson 8), with [`RAISE`](https://www.postgresql.org/docs/18/plpgsql-errors-and-messages.html) for `THROW` and `RETURNING … INTO` for `SCOPE_IDENTITY()` ([`sql/13-migration.sql`, lines 73-90](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L73-L90)):

```sql
-- dbo.AddNote as a function: RAISE for THROW, RETURNING for SCOPE_IDENTITY()
CREATE FUNCTION migrated.add_note(p_run_id bigint, p_author varchar, p_body text, p_tag varchar DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_note_id integer;
BEGIN
    IF NOT EXISTS (SELECT FROM migrated.runs WHERE run_id = p_run_id) THEN
        RAISE EXCEPTION 'Unknown run' USING ERRCODE = 'P0001';
    END IF;
    INSERT INTO migrated.notes (note_guid, run_id, author, tag, body, written_at, written_local)
    VALUES (gen_random_uuid(), p_run_id, p_author, p_tag, p_body, now() AT TIME ZONE 'UTC', now())
    RETURNING note_id INTO v_note_id;
    RETURN v_note_id;
END
$$;
SELECT migrated.add_note(1, 'Reviewer', 'no such run');
```

```text
CREATE FUNCTION
ERROR:  Unknown run
CONTEXT:  PL/pgSQL function migrated.add_note(bigint,character varying,text,character varying) line 6 at RAISE
```

`NEWID()` becomes `gen_random_uuid()`, `GETUTCDATE()` becomes `now() AT TIME ZONE 'UTC'`, and the `OUTPUT` parameter becomes the return value. The view is exercise 1.

## pgloader

[pgloader](https://pgloader.readthedocs.io/en/latest/ref/mssql.html) creates the schema and copies the data in one command. `check.sh` runs the image `ghcr.io/dimitri/pgloader` built from commit [`231ab86`](https://github.com/dimitri/pgloader/tree/231ab86778ca5ffd7de40878714760c8b4860cdf) (version `3.6.10~devel`), with its default cast rules, into a database of its own:

```bash
docker run --rm --add-host=host.docker.internal:host-gateway ghcr.io/dimitri/pgloader@sha256:a1d4a78e78a64e46cd3fc7dfc57d24eb91ffb1a5520f2b1f55631815e3658d6e pgloader \
  'mssql://sa:Learn-2026!@host.docker.internal:1433/ci' \
  'postgresql://postgres:learn@host.docker.internal:5432/pgloader'
```

It reported 2,962 rows and no errors, in under a second. What it created ([`sql/pgloader-check.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/pgloader-check.sql), [`expected/13-pgloader.txt`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/13-pgloader.txt)):

```text
 table_name |                                                                                                                  columns
------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 joblabels  | jobid bigint, label text
 jobs       | jobid bigint, runid bigint, name text, conclusion text, runnername text, startedat timestamp with time zone, completedat timestamp with time zone, rowver bytea
 notes      | noteid integer default nextval('dbo.notes_noteid_seq'::regclass), noteguid uuid, runid bigint, author text, tag text, body text, cost numeric, writtenat timestamp with time zone, writtenlocal timestamp with time zone
 runs       | runid bigint, workflowname text, event text, conclusion text, headbranch text, headsha text, attempt smallint, createdat timestamp with time zone, startedat timestamp with time zone, updatedat timestamp with time zone, isrerun boolean
 steps      | jobid bigint, number smallint, name text, conclusion text, startedat timestamp with time zone, completedat timestamp with time zone
(5 rows)

 noteid |  author   | cost |         writtenat          |         writtenlocal
--------+-----------+------+----------------------------+-------------------------------
      1 | Reviewer  | 0.01 | 2026-09-14 14:05:00+00     | 2026-09-14 14:05:00.123457+00
      2 | reviewer  |      | 2026-09-14 14:06:00.007+00 | 2026-09-14 14:06:01+00
      3 | REVIEWER  | 3.50 | 2026-09-14 14:07:00.997+00 | 2026-09-14 14:07:00+00
(3 rows)

 last_value
------------
          3
(1 row)

 contype | count
---------+-------
 f       |     4
 n       |    28
 p       |     5
(3 rows)

                                    index
------------------------------------------------------------------------------
 CREATE INDEX ix_jobs_runid ON dbo.jobs USING btree (runid, conclusion)
 CREATE UNIQUE INDEX pk_joblabels ON dbo.joblabels USING btree (jobid, label)
 CREATE UNIQUE INDEX pk__jobs ON dbo.jobs USING btree (jobid)
 CREATE UNIQUE INDEX pk__notes ON dbo.notes USING btree (noteid)
 CREATE UNIQUE INDEX pk__runs ON dbo.runs USING btree (runid)
 CREATE UNIQUE INDEX pk__steps ON dbo.steps USING btree (jobid, number)
 CREATE UNIQUE INDEX uq__notes ON dbo.notes USING btree (noteguid)
 CREATE UNIQUE INDEX uq_notes_tag ON dbo.notes USING btree (tag)
(8 rows)
```

- **`money` lost two decimals.** `0.0125` became `0.01`. pgloader reads `decimal`, `numeric`, `money` and `smallmoney` columns as `convert(varchar(40), [col], 0)` ([`mssql-schema.lisp`, lines 212-217](https://github.com/dimitri/pgloader/blob/231ab86778ca5ffd7de40878714760c8b4860cdf/src/sources/mssql/mssql-schema.lisp#L212-L217)), and for `money`, style 0 means "two digits to the right of the decimal point" ([`CAST` and `CONVERT`](https://learn.microsoft.com/sql/t-sql/functions/cast-and-convert-transact-sql#money-and-smallmoney-styles)). `SELECT CONVERT(varchar(40), CAST(0.0125 AS money), 0)` returns `0.01` on this SQL Server; style 2 keeps four digits. No error, no warning: only a validation finds it.
- **`datetimeoffset` was rounded, not truncated.** `.1234567` became `.123457`, and `10:06:00.9999999 -04:00` became `14:06:01`, the next second. The C# program truncated. The two copies disagree with each other, and both with SQL Server.
- **Names and types.** `RunId` became `runid`, every string `text` without its length, `datetime` a `timestamptz`, `rowversion` a `bytea`, and the computed column a plain `boolean` holding copied values.
- **Constraints.** Primary keys, foreign keys and `NOT NULL` came over; the `CHECK (Attempt >= 1)` didn't, and there is no `c` among the constraint kinds. The unique constraints became unique indexes, without `NULLS NOT DISTINCT` or a case-insensitive collation. `IX_Jobs_RunId … INCLUDE (Conclusion)` became an index on `(runid, conclusion)`, with the included column as a key.
- **The sequence** was set to 3, the largest key, not SQL Server's 6: no conflict here, but not the source's numbering either.

pgloader is quick for a first look at a database. Its cast rules can be changed in a load file, and its result still needs the review and the validation of the previous sections.

## AWS DMS

*To verify: nothing in this section ran on AWS.* [AWS Database Migration Service](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html) copies data between databases, from a replication instance or with DMS Serverless, as a full load, as ongoing replication, or both.

- **Sources.** "Microsoft SQL Server versions 2008 (supported in DMS v3.5.4), 2008R2(supported in DMS v3.5.4), 2012, 2014, 2016, 2017, 2019, and 2022" ([sources](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Sources.html)). SQL Server 2025, this lesson's version, isn't listed. Ongoing replication needs the Enterprise, Developer or Standard (2016 and higher) edition.
- **Targets.** "AWS DMS only supports PostgreSQL version 17.x and 18.x in versions 3.5.4" ([targets](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Targets.html)).
- **Ongoing replication from SQL Server.** "The recovery model must be set to Bulk logged or Full", and "you must perform a backup before beginning to replicate data" ([SQL Server source](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html#CHAP_Source.SQLServer.Prerequisites)). On a self-managed server, DMS reads MS-Replication for tables with a primary key and MS-CDC for the others; "Amazon RDS for SQL Server doesn't support MS-Replication", so there it uses MS-CDC for every table ([CDC](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.CDC.html#CHAP_Source.SQLServer.CDC.Selfmanaged)).
- **What it doesn't carry.** "The identity property for a column isn't migrated to a target database column", "Changes to computed fields in a SQL Server aren't replicated", "AWS DMS doesn't capture truncate commands" ([limitations](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html#CHAP_Source.SQLServer.Limitations)). DMS "doesn't automatically create secondary indexes, foreign keys, user accounts, and so on" ([best practices](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html#CHAP_SettingUp.MigrationPlanning)), and sequences need their next value set "after you stop the replication from the source database" ([PostgreSQL target](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html#CHAP_Target.PostgreSQL.Limitations)): the identity restart of this lesson.
- **Create the target tables yourself.** When DMS creates them, the [source](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html#CHAP_Source.SQLServer.DataTypes) and [target](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html#CHAP_Target.PostgreSQL.DataTypes) type tables put together give `datetime2` with a scale of 7 a `VARCHAR (37)` column, `datetimeoffset` and `uniqueidentifier` a `VARCHAR`. Those two tables are my reading, not a statement of AWS's.
- **Large values.** Limited LOB mode, the default, "migrates all LOB values up to a user-specified size limit (default is 32 KB)" ([LOBs](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html#CHAP_BestPractices.LOBS.LimitedLOBMode)): a longer `nvarchar(max)` needs full or inline LOB mode.
- **Validation.** "AWS DMS compares each row in the source with its corresponding row at the target … and reports any mismatches", and "requires that the table has a primary key or unique index" ([data validation](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Validating.html)). Whether it would report the lost ticks of `datetimeoffset(7)` is *to verify*.
- **Schema.** [DMS Schema Conversion](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_SchemaConversion.html#how-schema-conversion-works) "builds on the AWS Schema Conversion Tool (AWS SCT) conversion engine" and, for SQL Server to Aurora PostgreSQL, "can use generative AI to convert more"; AWS adds that it "may not achieve 100 percent accuracy … You must review and validate all conversion outputs" ([limitations](https://docs.aws.amazon.com/dms/latest/userguide/schema-conversion-convert.databaseobjects.html#schema-conversion-convert.databaseobjects.limitations)). The [AWS SCT](https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html) desktop tool is still released (build 677).
- **DMS Serverless.** "The current engine version for AWS DMS Serverless is 3.5.4" ([Serverless](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.html)); it "does not support views" ([limitations](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.Limitations.html)).

AWS's [step-by-step walkthrough](https://docs.aws.amazon.com/dms/latest/sbs/schema-conversion-sql-server-aurora-postgresql.html) goes through a SQL Server to Aurora PostgreSQL conversion in the console; the [migration playbook](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.html) compares features, for SQL Server 2019.

## Babelfish

*To verify.* Babelfish takes the other route: the application keeps its T-SQL and its SQL Server driver, and Aurora PostgreSQL answers it. "SQL Server dialect (T-SQL), clients connect to port 1433. PostgreSQL dialect (PL/pgSQL), clients connect to port 5432" ([Babelfish](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish.html)).

- **Versions.** Babelfish 6.1.0 "is provided with Aurora PostgreSQL 18.4", released on August 21, 2026 ([Babelfish updates](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraBabelfish.Updates.html#AuroraBabelfish.Updates.610)).
- **Databases.** Aurora creates a PostgreSQL database named `babelfish_db`. In multiple-database mode, "the schema names of user databases become dbname_schemaname when accessed from PostgreSQL" ([architecture](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-architecture.html#babelfish-single_vs_multi_db)). The mode is chosen once: "You must not change this parameter after creating your cluster as you could lose access to all your previously created SQL objects"; the [parameter table](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-configuration.html#babelfish_params) says "you can't modify this parameter's value", with multi-db as the default from Aurora PostgreSQL 16.
- **Collations: two defaults.** The parameter table gives `babelfishpg_tsql.server_collation_name` a default of `bbf_unicode_general_ci_as`; the [collations page](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-collations.html#babelfish-collations.parameters) says "The default value is sql_latin1_general_cp1_ci_as". The same page's comparison table says PostgreSQL "Doesn't support the LIKE clause on nondeterministic collations", which PostgreSQL 18 changed.
- **Unsupported features** answer with an error or are ignored, depending on the [escape hatches](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-strict.html#babelfish-escape_hatches); the [unsupported list](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-compatibility.tsql.limitations-unsupported.html#babelfish-compatibility.tsql.limitations-unsupported-table) includes CLR routines and updatable cursors. [Babelfish Compass](https://github.com/babelfish-for-postgresql/babelfish_compass) reads a database's DDL and reports what Babelfish supports; its latest release is [v.2026-07](https://github.com/babelfish-for-postgresql/babelfish_compass/releases/tag/v.2026-07).
- **Not locally.** The open-source [Babelfish for PostgreSQL](https://babelfishpg.org/) needs a modified PostgreSQL built from source; its latest release is [5.4.0 for PostgreSQL 17.7](https://github.com/babelfish-for-postgresql/babelfish-for-postgresql/releases/tag/BABEL_5_4_0__PG_17_7), and the project publishes no container image. The course doesn't build it.

Babelfish moves the database without rewriting the application, and the application keeps the SQL Server behaviours of the previous sections, as long as Babelfish emulates them: each is *to verify* against Babelfish's own lists.

## Costs

*To verify: prices change, and the course bought nothing.* The numbers are AWS's on-demand prices in US East (N. Virginia), from the [AWS Price List](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json) files published on 2026-09-11, which the [Aurora pricing page](https://aws.amazon.com/rds/aurora/pricing/) shows too.

| Aurora PostgreSQL | Aurora Standard | Aurora I/O-Optimized |
|---|---|---|
| db.r8g.large or db.r7g.large (2 vCPUs, 16 GiB), per hour | $0.276 | $0.359 |
| storage, per GB-month | $0.10 | $0.225 |
| I/O, per million requests | $0.20 | included |
| Aurora Serverless, per ACU-hour | $0.12 | $0.16 |
| backup storage beyond the cluster's size, per GB-month | $0.021 | $0.021 |

For comparison, from the same files:

- **RDS for SQL Server Standard Edition**, license included, on a db.r6i.large Single-AZ: $1.02 per hour, about $745 a month for one instance.
- **The license itself**: Microsoft's [SQL Server 2025 pricing sheet](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/cloud/SQL-Server-2025-Pricing.pdf) lists Standard at $3,945 and Enterprise at $15,123 per 2-core pack.
- **The migration**: a dms.r6i.large replication instance costs $0.176 per hour; DMS Serverless $0.0819 per DCU-hour, where "One DCU equals 2GB of RAM" ([DMS pricing](https://aws.amazon.com/dms/pricing/)). Babelfish "doesn't have an additional cost" ([DMS and Babelfish](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html#CHAP_Target.PostgreSQL.Babelfish)).

AWS's prescriptive guidance claims that moving from SQL Server Enterprise on EC2 to Aurora "can result in cost savings up to 70 percent" ([cost optimization](https://docs.aws.amazon.com/prescriptive-guidance/latest/optimize-costs-microsoft-workloads/modernize-sql-server.html#modernize-sql-server-database)): a claim to check with your own instance sizes, I/O and license terms, in the [AWS Pricing Calculator](https://calculator.aws/). Exercise 3 does the arithmetic for one cluster.

## Key takeaways

- Run both servers and ask them the same questions before moving data: collation, trailing spaces, `NULL` order, GUID order, unique `NULL`s, date precision, errors in transactions.
- An ICU nondeterministic collation gives SQL Server's case-insensitive comparisons, including `LIKE` from PostgreSQL 18; trailing spaces stay significant.
- `datetime2(7)` and `datetimeoffset` lose their seventh decimal, and `datetimeoffset` its offset; `datetime` was already rounded in SQL Server.
- Create the target schema yourself, load, then add foreign keys and indexes, restart identities from SQL Server's `IDENT_CURRENT`, and `ANALYZE`.
- Validate rows, not counts: the program found the lost ticks, and a validation would have found pgloader's `money` values cut to two decimals.
- PostgreSQL aborts the whole transaction after an error; SQL Server's default doesn't.
- DMS copies and replicates data, but not identities, secondary indexes or code; Babelfish keeps T-SQL, and its behaviour is to check against its compatibility lists.
- Aurora's price has three parts: instances, storage and I/O; above a certain I/O volume, I/O-Optimized costs less.

## Exercises

1. Convert `dbo.SlowJobs` to a PostgreSQL view on lesson 2's `ci.jobs` and `ci.runs`, and check that it returns the same five rows as SQL Server.

<details>
<summary>Solution</summary>

[`sql/13-exercises.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-exercises.sql#L7-L16):

```sql
-- Exercise 1: dbo.SlowJobs as a PostgreSQL view. DATEDIFF(second, ...) counts second boundaries crossed; the
-- difference of two timestamptz truncated to the second counts the same thing.
CREATE VIEW ci.slow_jobs AS
SELECT j.name, r.workflow_name,
       extract(epoch FROM date_trunc('second', j.completed_at) - date_trunc('second', j.started_at))::integer AS seconds
FROM ci.jobs AS j JOIN ci.runs AS r ON r.run_id = j.run_id
ORDER BY seconds DESC
FETCH FIRST 5 ROWS WITH TIES;

SELECT * FROM ci.slow_jobs ORDER BY seconds DESC, name, workflow_name;
```

```text
CREATE VIEW
               name               |    workflow_name     | seconds
----------------------------------+----------------------+---------
 java-for-csharp (windows-latest) | Java course examples |     284
 java-for-csharp (macos-latest)   | Java course examples |     270
 java-for-csharp (windows-latest) | Java course examples |     270
 java-for-csharp (windows-latest) | Java course examples |     255
 java-for-csharp (windows-latest) | Java course examples |     254
```

The same rows as [SQL Server's](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/mssql-13-source.txt#L55-L61). [`DATEDIFF`](https://learn.microsoft.com/sql/t-sql/functions/datediff-transact-sql) counts boundaries crossed, so `10:00:00.9` to `10:00:01.1` is one second; `date_trunc('second', …)` on both ends counts the same way, where `extract(epoch FROM completed_at - started_at)` would give 0.2. `TOP (5) WITH TIES` becomes `FETCH FIRST 5 ROWS WITH TIES`, and a view's `ORDER BY` is kept here, but the query that reads the view still orders its own result.

</details>

2. Before converting a larger SQL Server database, list the columns whose types need a decision, from SQL Server's catalog, and the authors that differ only by case or trailing spaces.

<details>
<summary>Solution</summary>

[`mssql/13-exercises.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-exercises.sql):

```sql
-- Lesson 13, exercise 2: the columns whose type needs a decision before the conversion, from SQL Server's catalog
SET NOCOUNT ON;
USE ci;
SELECT t.name AS [table], c.name AS [column], ty.name AS type, c.scale, c.is_computed, c.is_identity
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('datetime', 'smalldatetime', 'datetime2', 'datetimeoffset', 'money', 'smallmoney', 'tinyint',
                  'uniqueidentifier', 'timestamp', 'sql_variant', 'hierarchyid', 'xml', 'image', 'text', 'ntext')
   OR c.is_computed = 1 OR c.is_identity = 1
ORDER BY t.name, c.column_id;

-- Collations other than the database's, and the strings that differ only by case or trailing spaces
SELECT t.name AS [table], c.name AS [column], c.collation_name
FROM sys.columns AS c JOIN sys.tables AS t ON t.object_id = c.object_id
WHERE c.collation_name IS NOT NULL AND c.collation_name <> CAST(DATABASEPROPERTYEX('ci', 'Collation') AS sysname)
ORDER BY t.name, c.column_id;
SELECT Author COLLATE Latin1_General_BIN2 AS author, COUNT(*) AS notes
FROM dbo.Notes
GROUP BY Author COLLATE Latin1_General_BIN2
ORDER BY author;
GO
```

```text
Changed database context to 'ci'.
table|column|type|scale|is_computed|is_identity
-----|------|----|-----|-----------|-----------
Jobs|StartedAt|datetime2|7|0|0
Jobs|CompletedAt|datetime2|7|0|0
Jobs|RowVer|timestamp|0|0|0
Notes|NoteId|int|0|0|1
Notes|NoteGuid|uniqueidentifier|0|0|0
Notes|Cost|money|4|0|0
Notes|WrittenAt|datetime|3|0|0
Notes|WrittenLocal|datetimeoffset|7|0|0
Runs|Attempt|tinyint|0|0|0
Runs|CreatedAt|datetime2|0|0|0
Runs|StartedAt|datetime|3|0|0
Runs|UpdatedAt|datetimeoffset|7|0|0
Runs|IsRerun|bit|0|1|0
Steps|StartedAt|datetime2|0|0|0
Steps|CompletedAt|datetime2|0|0|0
table|column|collation_name
-----|------|--------------
author|notes
------|-----
REVIEWER|1
Reviewer|1
reviewer |1
```

`rowversion` shows as `timestamp`, its old name, and `datetime`'s scale shows as 3 although its values are rounded to 1/300 of a second. No column has its own collation here. A binary collation, `Latin1_General_BIN2`, makes SQL Server itself show the three spellings that its default collation treats as one.

</details>

3. For a writer and one Aurora Replica on db.r8g.large, running all month (730 hours), with 100 GiB of data and 300 million I/O requests a month, compare Aurora Standard with Aurora I/O-Optimized. From how many I/O requests a month does I/O-Optimized cost less?

<details>
<summary>Solution</summary>

[`sql/13-exercises.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-exercises.sql#L18-L33):

```sql
-- Exercise 3: a month of 730 hours for a writer and one Aurora Replica, both db.r8g.large, with 100 GiB of data and
-- 300 million I/O requests, at the us-east-1 on-demand prices of the AWS Price List published on 2026-09-11
WITH price (configuration, instance_hour, gib_month, million_ios) AS (
    VALUES ('Aurora Standard', 0.276, 0.10, 0.20),
           ('Aurora I/O-Optimized', 0.359, 0.225, 0.00)
)
SELECT configuration,
       2 * 730 * instance_hour AS instances,
       100 * gib_month AS storage,
       300 * million_ios AS io,
       2 * 730 * instance_hour + 100 * gib_month + 300 * million_ios AS month
FROM price
ORDER BY month;

-- The number of million I/O requests a month from which I/O-Optimized costs less, for the same instances and data
SELECT round(((2 * 730 * 0.359 + 100 * 0.225) - (2 * 730 * 0.276 + 100 * 0.10)) / 0.20) AS million_ios;
```

```text

    configuration     | instances | storage |  io   |  month
----------------------+-----------+---------+-------+---------
 Aurora Standard      |   402.960 |   10.00 | 60.00 | 472.960
 Aurora I/O-Optimized |   524.140 |  22.500 |  0.00 | 546.640
(2 rows)

 million_ios
-------------
         668
```

About $473 against $547: at 300 million I/O requests, Standard is cheaper. Without I/O, I/O-Optimized costs $133.68 more a month in instances and storage; at $0.20 per million requests, Standard's I/O reaches that amount at about 668 million requests a month. AWS's own rule of thumb is to look at I/O-Optimized when I/O is more than 25% of the Aurora bill ([Aurora pricing](https://aws.amazon.com/rds/aurora/pricing/)). Backups, data transfer and snapshots are left out.

</details>

## Sources

- SQL Server, on Microsoft Learn: [what's new in SQL Server 2025](https://learn.microsoft.com/sql/sql-server/what-s-new-in-sql-server-2025), [Docker quickstart](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker), [`sqlcmd`](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility), [collations](https://learn.microsoft.com/sql/relational-databases/collations/collation-and-unicode-support), [`datetime`](https://learn.microsoft.com/sql/t-sql/data-types/datetime-transact-sql), [`uniqueidentifier`](https://learn.microsoft.com/sql/t-sql/data-types/uniqueidentifier-transact-sql), [comparing GUIDs](https://learn.microsoft.com/sql/connect/ado-net/sql/compare-guid-uniqueidentifier-values), [string comparison](https://learn.microsoft.com/sql/t-sql/language-elements/string-comparison-assignment), [`ORDER BY`](https://learn.microsoft.com/sql/t-sql/queries/select-order-by-clause-transact-sql), [`SET XACT_ABORT`](https://learn.microsoft.com/sql/t-sql/statements/set-xact-abort-transact-sql), [`CAST` and `CONVERT`](https://learn.microsoft.com/sql/t-sql/functions/cast-and-convert-transact-sql), [`DATEDIFF`](https://learn.microsoft.com/sql/t-sql/functions/datediff-transact-sql), [`OPENROWSET(BULK)`](https://learn.microsoft.com/sql/t-sql/functions/openrowset-bulk-transact-sql), [`OPENJSON`](https://learn.microsoft.com/sql/t-sql/functions/openjson-transact-sql), [Microsoft.Data.SqlClient](https://learn.microsoft.com/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace), [Data Migration Assistant](https://learn.microsoft.com/sql/dma/dma-overview); [SQL Server 2025 pricing sheet](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/cloud/SQL-Server-2025-Pricing.pdf)
- PostgreSQL 18: [collations](https://www.postgresql.org/docs/18/collation.html), [release notes](https://www.postgresql.org/docs/18/release-18.html), [pattern matching](https://www.postgresql.org/docs/18/functions-matching.html), [`citext`](https://www.postgresql.org/docs/18/citext.html), [`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html), [generated columns](https://www.postgresql.org/docs/18/ddl-generated-columns.html), [date/time types](https://www.postgresql.org/docs/18/datatype-datetime.html), [`SAVEPOINT`](https://www.postgresql.org/docs/18/sql-savepoint.html), [PL/pgSQL errors and messages](https://www.postgresql.org/docs/18/plpgsql-errors-and-messages.html), [monetary types](https://www.postgresql.org/docs/18/datatype-money.html), [error codes](https://www.postgresql.org/docs/18/errcodes-appendix.html)
- Npgsql: [date and time types](https://www.npgsql.org/doc/types/datetime.html), [EF Core concurrency tokens](https://www.npgsql.org/efcore/modeling/concurrency.html)
- pgloader: [MS SQL source](https://pgloader.readthedocs.io/en/latest/ref/mssql.html), [`mssql-schema.lisp` at `231ab86`](https://github.com/dimitri/pgloader/blob/231ab86778ca5ffd7de40878714760c8b4860cdf/src/sources/mssql/mssql-schema.lisp)
- AWS DMS, read on 2026-09-16: [what DMS is](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html), [sources](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Sources.html), [targets](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Targets.html), [SQL Server source](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html), [its CDC](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.CDC.html), [PostgreSQL target](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html), [best practices](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html), [data validation](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Validating.html), [Schema Conversion](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_SchemaConversion.html), [its limitations](https://docs.aws.amazon.com/dms/latest/userguide/schema-conversion-convert.databaseobjects.html), [AWS SCT](https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html), [DMS Serverless](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.html) and [its limitations](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.Limitations.html), [step-by-step walkthrough](https://docs.aws.amazon.com/dms/latest/sbs/schema-conversion-sql-server-aurora-postgresql.html), [migration playbook](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.html)
- Babelfish, read on 2026-09-16: [overview](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish.html), [architecture](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-architecture.html), [parameters](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-configuration.html), [collations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-collations.html), [escape hatches](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-strict.html), [unsupported functionality](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-compatibility.tsql.limitations-unsupported.html), [release notes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraBabelfish.Updates.html), [Babelfish Compass](https://github.com/babelfish-for-postgresql/babelfish_compass), [Babelfish for PostgreSQL](https://babelfishpg.org/)
- Prices, read on 2026-09-16: [AWS Price List index](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json), [Aurora pricing](https://aws.amazon.com/rds/aurora/pricing/), [DMS pricing](https://aws.amazon.com/dms/pricing/), [RDS for SQL Server pricing](https://aws.amazon.com/rds/sqlserver/pricing/), [AWS Pricing Calculator](https://calculator.aws/), [prescriptive guidance on SQL Server costs](https://docs.aws.amazon.com/prescriptive-guidance/latest/optimize-costs-microsoft-workloads/modernize-sql-server.html)
