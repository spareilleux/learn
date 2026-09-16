---
title: "13. Migrer depuis SQL Server, et les coûts"
description: Une base SQL Server 2025 avec les données de CI du cours, migrée vers PostgreSQL 18 à la main, par un programme C# avec SqlClient et COPY binaire, et par pgloader — collations, espaces finaux, précision de datetime, ordre des GUID, NULL dans les contraintes d'unicité, identités et transactions comparés sur les deux serveurs — puis AWS DMS, Babelfish et le coût d'Aurora PostgreSQL d'après la documentation et la liste de prix d'AWS, lues le 2026-09-16.
sidebar:
  order: 13
---

Les leçons précédentes comparaient PostgreSQL à SQL Server une fonctionnalité à la fois. Celle-ci déplace une base. Elle part d'un vrai SQL Server : [SQL Server 2025](https://learn.microsoft.com/sql/sql-server/what-s-new-in-sql-server-2025) dans l'image de conteneur de Microsoft `mcr.microsoft.com/mssql/server:2025-CU9-ubuntu-24.04` (17.0.5005.3, digest `sha256:2b5b581621126574f3d1f75e78d3eebe8d05aedb59ad0cfdf9aa42cb0634d726`), qui contient les mêmes exécutions et jobs GitHub Actions que le reste du cours. Les données partent ensuite deux fois vers PostgreSQL 18 : avec un programme C#, et avec [pgloader](https://pgloader.io/). Les deux tournent dans le mode `mssql` de `check.sh` et en CI, où SQL Server est un conteneur de service à côté de PostgreSQL.

Le code :

- [`mssql.sh`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql.sh) démarre SQL Server et exécute [`sqlcmd`](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility) à l'intérieur ;
- [`mssql/13-source.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql) crée la base source ;
- [`sql/mssql-target.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target.sql) et [`sql/mssql-target-after.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target-after.sql) sont le schéma converti ;
- [`csharp-mssql/L13.cs`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/csharp-mssql/L13.cs) copie et valide ;
- [`sql/13-migration.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql) montre ce qui se comporte différemment une fois les données dans PostgreSQL ;
- [`sql/pgloader-check.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/pgloader-check.sql) examine ce que pgloader a créé.

Les services de migration d'AWS ne tournent pas en local, et le cours n'utilise aucun compte AWS : [AWS DMS](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html), [Babelfish for Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish.html) et les prix viennent de la documentation et de la liste de prix d'AWS, lues le 2026-09-16, et sont *à vérifier*.

| Outil SQL Server | Pour PostgreSQL et Aurora |
|---|---|
| [Data Migration Assistant](https://learn.microsoft.com/sql/dma/dma-overview), SSMA | DMS Schema Conversion ou l'AWS Schema Conversion Tool ; Babelfish Compass pour évaluer le T-SQL en vue de Babelfish |
| `bcp`, `SqlBulkCopy`, SSIS | `COPY` depuis un programme (leçon 4), pgloader, chargement complet d'AWS DMS |
| réplication transactionnelle, capture des données modifiées | réplication continue d'AWS DMS, qui lit MS-Replication ou MS-CDC de SQL Server |
| une application T-SQL déplacée telle quelle | Babelfish : Aurora PostgreSQL qui parle TDS sur le port 1433 |

## La base à migrer

`bash mssql.sh start` lance le conteneur ; SQL Server sous Linux demande « at least 2 GB of RAM » ([démarrage rapide Docker](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker)), et `mssql.sh` le plafonne à 2 048 Mo avec `MSSQL_MEMORY_LIMIT_MB`. Le schéma source est ce qu'une équipe SQL Server aurait pu écrire : des noms en PascalCase, `nvarchar`, `tinyint`, trois types de date, une colonne calculée, `rowversion`, une clé `IDENTITY`, un `uniqueidentifier`, `money` ([`mssql/13-source.sql`, lignes 12-66](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L12-L66)) :

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

-- Une ligne par label : SQL Server n'a pas de type tableau
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

-- Des notes écrites par des personnes, avec les types qu'a souvent un schéma SQL Server : une clé IDENTITY, un GUID, money, datetime
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

Les exécutions, les jobs et les étapes viennent des mêmes fichiers JSON que dans la leçon 2, lus avec [`OPENROWSET(BULK …)`](https://learn.microsoft.com/sql/t-sql/functions/openrowset-bulk-transact-sql) et [`OPENJSON`](https://learn.microsoft.com/sql/t-sql/functions/openjson-transact-sql) ; trois notes sont écrites à la main, pour contenir les valeurs qui ne survivent pas inchangées à une migration (lignes 98-104) :

```sql
INSERT INTO dbo.Notes (NoteGuid, RunId, Author, Tag, Body, Cost, WrittenAt, WrittenLocal) VALUES
    ('6F9619FF-8B86-D011-B42D-00C04FC964FF', 34852867099, N'Reviewer', 'Slow', N'Deploy took 2.5 minutes', 0.0125,
     '2026-09-14 14:05:00.001', '2026-09-14 16:05:00.1234567 +02:00'),
    ('00000000-0000-0000-0000-000000000001', 34852867099, N'reviewer ', NULL, N'Looks fine now', NULL,
     '2026-09-14 14:06:00.005', '2026-09-14 10:06:00.9999999 -04:00'),
    ('01000000-0000-0000-0000-000000000000', NULL, N'REVIEWER', 'flaky', N'Café au lait', 3.5,
     '2026-09-14 14:07:00.998', '2026-09-14 14:07:00 +00:00');
```

La sortie commence par la collation de la base et les nombres de lignes ([`expected/mssql-13-source.txt`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/mssql-13-source.txt)) :

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

`sqlcmd` s'exécute avec `-W -s '|'` : des colonnes sans espaces de remplissage, séparées par des barres. `SQL_Latin1_General_CP1_CI_AS` est la collation par défaut d'une installation en anglais américain ([collations](https://learn.microsoft.com/sql/relational-databases/collations/collation-and-unicode-support#server-level-collations)) : insensible à la casse (`CI`), sensible aux accents (`AS`).

## Sept comportements à vérifier avant de déplacer les données

Les mêmes questions, posées à SQL Server ([lignes 114-142](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L114-L142)) :

```sql
-- datetime garde le 1/300 de seconde : .001 a été stocké comme .000, .005 comme .007
SELECT NoteId, WrittenAt, WrittenLocal FROM dbo.Notes ORDER BY NoteId;

-- La collation par défaut ignore la casse, et = ignore les espaces finaux
SELECT COUNT(DISTINCT Author) AS authors, SUM(CASE WHEN Author = N'reviewer' THEN 1 ELSE 0 END) AS [= 'reviewer']
FROM dbo.Notes;
BEGIN TRY
    INSERT INTO dbo.Notes (NoteGuid, Author, Tag, Body, WrittenAt, WrittenLocal)
    VALUES (NEWID(), N'Reviewer', 'SLOW', N'again', '2026-09-14', '2026-09-14 00:00 +00:00');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS message;
END CATCH;
-- Une contrainte UNIQUE accepte un NULL, pas deux
BEGIN TRY
    INSERT INTO dbo.Notes (NoteGuid, Author, Tag, Body, WrittenAt, WrittenLocal)
    VALUES (NEWID(), N'Reviewer', NULL, N'again', '2026-09-14', '2026-09-14 00:00 +00:00');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS message;
END CATCH;

-- uniqueidentifier trie d'abord sur ses six derniers octets ; NULL vient en premier
SELECT NoteGuid, Cost FROM dbo.Notes ORDER BY NoteGuid;
SELECT NoteId, Cost FROM dbo.Notes ORDER BY Cost;

-- + avec NULL donne NULL, CONCAT l'ignore ; TOP et ISNULL
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

Et à PostgreSQL, sur la table convertie de la section suivante, avec les notes telles que le programme les copie ([`sql/13-migration.sql`, lignes 23-50](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L23-L50)). Le script ajoute d'abord une quatrième note, numéro 7, pour la section sur l'identité :

```sql
-- timestamptz garde l'instant, pas le décalage : chaque valeur revient dans le fuseau horaire de la session
SELECT note_id, written_at, written_local FROM migrated.notes ORDER BY note_id;

-- La collation ci ignore la casse, mais pas les espaces finaux : trois auteurs deviennent deux
SELECT count(DISTINCT author) AS authors, count(*) FILTER (WHERE author = 'reviewer') AS "= 'reviewer'"
FROM migrated.notes;
-- La même colonne comparée avec la collation par défaut de la base
SELECT count(DISTINCT author COLLATE "default") AS authors FROM migrated.notes;
-- rtrim là où les règles de remplissage de SQL Server comptaient
SELECT count(DISTINCT rtrim(author)) AS authors FROM migrated.notes;

-- LIKE sur une collation non déterministe : nouveau dans PostgreSQL 18
SELECT note_id, author FROM migrated.notes WHERE author LIKE 'rev%' ORDER BY note_id;

-- La contrainte d'unicité compare aussi les tags avec la collation ci, et n'accepte qu'un seul NULL
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', 'SLOW', 'again', '2026-09-14', '2026-09-14 00:00+00');
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', NULL, 'again', '2026-09-14', '2026-09-14 00:00+00');

-- uuid trie octet par octet, depuis la gauche ; NULL vient en dernier dans l'ordre croissant
SELECT note_guid, cost FROM migrated.notes ORDER BY note_guid;
SELECT note_id, cost FROM migrated.notes ORDER BY cost;
SELECT note_id, cost FROM migrated.notes ORDER BY cost NULLS FIRST;

-- || avec NULL donne NULL, concat l'ignore ; FETCH FIRST ... WITH TIES, et coalesce pour ISNULL
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

1. **`datetime` n'est pas précis à la milliseconde.** Ses valeurs sont « rounded to increments of .000, .003, or .007 seconds » ([`datetime`](https://learn.microsoft.com/sql/t-sql/data-types/datetime-transact-sql)) : `.001` a été stocké comme `.000`, `.005` comme `.007`, `.998` comme `.997`. La migration copie les valeurs arrondies ; rien ne peut retrouver les originales.
2. **`timestamptz` garde l'instant, pas le décalage.** `datetimeoffset` gardait `+02:00` et `-04:00` ; PostgreSQL rend chaque valeur dans le fuseau horaire de la session, UTC ici. La documentation de Npgsql dit la même chose : « only a UTC timestamp is stored » ([types date et heure](https://www.npgsql.org/doc/types/datetime.html)). Si le décalage de celui qui écrit compte, il lui faut sa propre colonne.
3. **La casse.** Avec la collation par défaut de la base, `Reviewer`, `reviewer ` et `REVIEWER` sont trois auteurs. La cible déclare une [collation ICU non déterministe](https://www.postgresql.org/docs/18/collation.html#COLLATION-NONDETERMINISTIC), `und-u-ks-level2`, qui compare sans tenir compte de la casse : ils deviennent deux.
4. **Les espaces finaux.** « Transact-SQL considers the strings 'abc' and 'abc ' to be equivalent for most comparison operations » ([comparaison de chaînes](https://learn.microsoft.com/sql/t-sql/language-elements/string-comparison-assignment#remarks)), donc SQL Server compte un seul auteur. Avec `varchar` et `text`, PostgreSQL garde l'espace significatif ; `rtrim` redonne le compte de SQL Server. L'extension `citext` ignore aussi la casse, mais sa [documentation](https://www.postgresql.org/docs/18/citext.html) dit maintenant : « Consider using nondeterministic collations … instead of this module. »
5. **`LIKE` sur une colonne insensible à la casse.** Il fonctionne dans PostgreSQL 18 : « Allow LIKE with nondeterministic collations » ([notes de version](https://www.postgresql.org/docs/18/release-18.html#RELEASE-18-UTILITY)). `ILIKE` « does not support nondeterministic collations » ([correspondance de motifs](https://www.postgresql.org/docs/18/functions-matching.html#FUNCTIONS-LIKE)).
6. **Contraintes d'unicité et `NULL`.** SQL Server a refusé `SLOW` à côté de `Slow`, et un second tag `NULL`. PostgreSQL traite les `NULL` comme distincts dans une contrainte d'unicité « unless NULLS NOT DISTINCT is specified » ([`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html)) : la cible le déclare, avec la collation `ci`, pour garder les deux règles.
7. **Les ordres de tri.** Pour `uniqueidentifier`, « ordering is not implemented by comparing the bit patterns of the two values » ([`uniqueidentifier`](https://learn.microsoft.com/sql/t-sql/data-types/uniqueidentifier-transact-sql#remarks)) : SQL Server compare d'abord « the last six bytes of a value » ([comparer des GUID](https://learn.microsoft.com/sql/connect/ado-net/sql/compare-guid-uniqueidentifier-values#comparing-guid-values)), le `uuid` de PostgreSQL octet par octet depuis la gauche, donc les trois notes arrivent dans un ordre différent. SQL Server trie `NULL` en premier, comme « the lowest possible values » ([`ORDER BY`](https://learn.microsoft.com/sql/t-sql/queries/select-order-by-clause-transact-sql#arguments)) ; PostgreSQL le trie en dernier dans l'ordre croissant, sauf avec `NULLS FIRST`. Une pagination par clé sur un GUID, ou un rapport qui attend les `NULL` en haut, change sans prévenir.

La dernière requête est la même des deux côtés : `+` et `||` donnent `NULL` quand un côté est `NULL`, `CONCAT` et `concat` l'ignorent ; `ISNULL` devient `coalesce`, `TOP (2)` devient `FETCH FIRST 2 ROWS ONLY`.

## Les transactions après une erreur

SQL Server et PostgreSQL ne s'accordent pas sur ce qu'une erreur fait à une transaction ([lignes 145-172](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L145-L172)) :

```sql
-- Sans SET XACT_ABORT, une instruction en échec ne termine pas la transaction : XACT_STATE() vaut toujours 1, et COMMIT garde
-- les lignes insérées autour. (L'erreur est attrapée : sqlcmd 18.6 abandonne les résultats qui suivent une erreur non attrapée.)
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

-- Avec SET XACT_ABORT ON, la même erreur condamne la transaction : XACT_STATE() vaut -1, seul un rollback est possible
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

Avec [`SET XACT_ABORT`](https://learn.microsoft.com/sql/t-sql/statements/set-xact-abort-transact-sql#remarks) à sa valeur par défaut, « OFF is the default setting in a T-SQL statement », une clé en double termine l'instruction, pas la transaction : `XACT_STATE()` vaut toujours 1 et `COMMIT` garde `self-hosted` et `linux`. Avec `XACT_ABORT ON`, la transaction ne peut plus qu'être annulée. L'erreur est attrapée avec `TRY … CATCH` parce que `sqlcmd` 18.6 abandonnait tous les résultats qui suivaient une erreur non attrapée dans un script (voir le [journal](../journal/)).

PostgreSQL se comporte comme `XACT_ABORT ON`, et plus strictement ([`sql/13-migration.sql`, lignes 52-71](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L52-L71)) :

```sql
-- Une erreur dans une transaction abandonne toute la transaction : l'instruction suivante est refusée, COMMIT annule
BEGIN;
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES ('10000000-0000-0000-0000-000000000000', 'Reviewer', 'retry', 'kept?', '2026-09-16', '2026-09-16 00:00+00');
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', 'Retry', 'duplicate tag', '2026-09-16', '2026-09-16 00:00+00');
SELECT count(*) FROM migrated.notes;
COMMIT;
SELECT count(*) AS kept FROM migrated.notes WHERE tag = 'retry';

-- Un savepoint redonne le comportement de SQL Server pour une instruction
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

Après l'erreur, chaque instruction est refusée jusqu'à la fin de la transaction, et `COMMIT` répond `ROLLBACK`. Du code qui comptait sur SQL Server pour continuer après une instruction en échec a besoin d'un [`SAVEPOINT`](https://www.postgresql.org/docs/18/sql-savepoint.html) autour de cette instruction. Un pilote qui envoie quand même l'instruction suivante reçoit le SQLSTATE `25P02`, `in_failed_sql_transaction` ([codes d'erreur](https://www.postgresql.org/docs/18/errcodes-appendix.html)).

## Convertir le schéma à la main

Le schéma cible ([`sql/mssql-target.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target.sql#L1-L68)) :

```sql
-- Leçon 13 : les tables de mssql/13-source.sql converties à la main, avant le chargement. Noms en snake_case, pour
-- se passer de guillemets ; des clés, mais pas encore de clés étrangères ni d'index secondaires (mssql-target-after.sql les ajoute).
DROP SCHEMA IF EXISTS migrated CASCADE;
CREATE SCHEMA migrated;

-- SQL_Latin1_General_CP1_CI_AS compare sans la casse ; cette collation ICU fait de même, et n'est pas déterministe :
-- deux chaînes peuvent être égales sans avoir les mêmes octets
CREATE COLLATION migrated.ci (provider = icu, locale = 'und-u-ks-level2', deterministic = false);

CREATE TABLE migrated.runs (
    run_id        bigint PRIMARY KEY,
    workflow_name varchar(100) NOT NULL,
    event         varchar(30) NOT NULL,
    conclusion    varchar(20),
    head_branch   varchar(255) NOT NULL,
    head_sha      char(40) NOT NULL,
    -- tinyint va de 0 à 255 ; PostgreSQL n'a pas d'entier sur un octet
    attempt       smallint NOT NULL CHECK (attempt BETWEEN 1 AND 255),
    -- datetime2, datetime et datetimeoffset contiennent tous des heures UTC ici : timestamptz
    created_at    timestamptz(0) NOT NULL,
    started_at    timestamptz(3) NOT NULL,
    updated_at    timestamptz NOT NULL,
    -- une colonne calculée non persistée : une colonne générée virtuelle (PostgreSQL 18)
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
    -- pas de rowversion : la colonne système xmin joue ce rôle pour la concurrence optimiste
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
    -- BY DEFAULT, pour que le chargement puisse garder les valeurs de la source
    note_id       integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    note_guid     uuid NOT NULL UNIQUE,
    run_id        bigint,
    author        varchar(50) COLLATE migrated.ci NOT NULL,
    -- NULLS NOT DISTINCT : un NULL au plus, comme dans SQL Server
    tag           varchar(20) COLLATE migrated.ci UNIQUE NULLS NOT DISTINCT,
    body          text NOT NULL,
    cost          numeric(19, 4),
    -- datetime n'a pas de fuseau horaire : timestamp, à la milliseconde
    written_at    timestamp(3) NOT NULL,
    -- datetimeoffset garde le décalage de celui qui écrit ; timestamptz ne garde que l'instant
    written_local timestamptz NOT NULL
);
```

Les décisions, type de colonne par type de colonne :

| SQL Server | PostgreSQL ici | Pourquoi |
|---|---|---|
| noms en `PascalCase` | `snake_case` | les identifiants sans guillemets passent en minuscules (leçon 1) ; `"RunId"` demanderait des guillemets partout |
| `nvarchar(n)`, `varchar(n)` | `varchar(n)`, `text` | les chaînes de PostgreSQL sont toutes en Unicode (UTF-8 ici) ; la longueur est une contrainte, pas un choix de stockage |
| `char(40)` | `char(40)` | la même sémantique de remplissage pour un hash de longueur fixe |
| `tinyint` | `smallint` avec un `CHECK` | pas d'entier sur un octet |
| colonne calculée `bit` | `boolean GENERATED ALWAYS AS (…) VIRTUAL` | une colonne générée virtuelle, nouvelle dans PostgreSQL 18 et désormais « the default kind » ([colonnes générées](https://www.postgresql.org/docs/18/ddl-generated-columns.html)) |
| `datetime2(0)`, `datetime2(7)` | `timestamptz(0)`, `timestamptz` | des valeurs UTC ; la résolution de PostgreSQL est « 1 microsecond » ([types date/heure](https://www.postgresql.org/docs/18/datatype-datetime.html)), celle de `datetime2` 100 ns |
| `datetime` | `timestamp(3)`, `timestamptz(3)` | pas de fuseau horaire dans le type : `timestamp` si les valeurs sont locales, `timestamptz` si elles sont en UTC |
| `datetimeoffset(7)` | `timestamptz` | le décalage est perdu |
| `money` | `numeric(19, 4)` | le `money` de PostgreSQL a sa « fractional precision … determined by the database's lc_monetary setting » ([types monétaires](https://www.postgresql.org/docs/18/datatype-money.html)) |
| `uniqueidentifier` | `uuid` | les mêmes 16 octets, un autre ordre de tri |
| `rowversion` | rien | pour la concurrence optimiste, le fournisseur EF Core de Npgsql utilise la colonne système `xmin` ([jetons de concurrence](https://www.npgsql.org/efcore/modeling/concurrency.html)) |
| `int IDENTITY(1, 1)` | `integer GENERATED BY DEFAULT AS IDENTITY` | `BY DEFAULT`, pour que le chargement puisse écrire les clés de la source |
| collation `CI_AS` | une collation ICU non déterministe, sur les colonnes qui en ont besoin | une collation non déterministe coûte en performances, « B-tree cannot use deduplication with indexes that use a nondeterministic collation » ([collations](https://www.postgresql.org/docs/18/collation.html#COLLATION-NONDETERMINISTIC)) |

Les clés étrangères et les index secondaires viennent après le chargement ([`sql/mssql-target-after.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target-after.sql)) :

```sql
-- Leçon 13 : ce que la cible reçoit après le chargement. Les clés étrangères sont vérifiées une fois, sur les lignes chargées ;
-- les index sont construits une fois au lieu d'être mis à jour ligne par ligne.
ALTER TABLE migrated.jobs ADD FOREIGN KEY (run_id) REFERENCES migrated.runs;
ALTER TABLE migrated.job_labels ADD FOREIGN KEY (job_id) REFERENCES migrated.jobs;
ALTER TABLE migrated.steps ADD FOREIGN KEY (job_id) REFERENCES migrated.jobs;
ALTER TABLE migrated.notes ADD FOREIGN KEY (run_id) REFERENCES migrated.runs;
-- IX_Jobs_RunId ... INCLUDE (Conclusion) a la même syntaxe
CREATE INDEX jobs_run_id ON migrated.jobs (run_id) INCLUDE (conclusion);
ANALYZE migrated.runs, migrated.jobs, migrated.job_labels, migrated.steps, migrated.notes;
```

## Copier les données avec C#

[`Microsoft.Data.SqlClient`](https://learn.microsoft.com/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace) 7.0.3 lit chaque table ; le `COPY` binaire de Npgsql (leçon 4) l'écrit. Chaque table a un `SELECT`, un `COPY` et une fonction qui écrit les colonnes d'une ligne avec des types explicites ([`L13.cs`, lignes 19-23 et 76-135](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/csharp-mssql/L13.cs#L19-L135)) :

```csharp
    // Une table à copier : le SELECT sur SQL Server, le COPY sur PostgreSQL, et comment chaque colonne est écrite
    record Table(string Name, string Select, string Copy, Action<SqlDataReader, NpgsqlBinaryImporter> Write);

    // datetime et datetime2 reviennent avec DateTimeKind.Unspecified ; Npgsql n'écrit que des DateTime UTC dans timestamptz
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
                // timestamp : pas de fuseau horaire d'un côté comme de l'autre, le DateTime est écrit tel quel
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

        // La colonne d'identité continue après la dernière valeur de SQL Server, pas après la plus grande clé copiée
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

- **`DateTime.Kind`.** SqlClient renvoie les valeurs `datetime` et `datetime2` sous forme de `DateTime` au kind non spécifié ; « Npgsql maps UTC DateTime to timestamp with time zone » ([types date et heure](https://www.npgsql.org/doc/types/datetime.html)), donc le programme déclare qu'elles sont en UTC avec `DateTime.SpecifyKind`. `datetimeoffset` devient `DateTimeOffset.UtcDateTime`.
- **Un projet séparé.** Le programme est dans `csharp-mssql`, pas avec les autres exemples : dans `csharp/`, où `InvariantGlobalization` est activé, `SqlConnection.OpenAsync` levait `System.NotSupportedException: Globalization Invariant Mode is not supported.`
- **Une table à la fois, chacune dans sa transaction.** Assez pour 2 962 lignes. Une vraie migration doit aussi gérer les écritures pendant la copie, ce à quoi sert la réplication continue de DMS.
- **L'identité.** L'`IDENT_CURRENT` de SQL Server vaut 6, pas 3 : les deux insertions qui ont échoué sur la contrainte d'unicité, et la note de la procédure supprimée ensuite, ont utilisé les valeurs 4 à 6 ([sortie de la source, lignes 62-67](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/mssql-13-source.txt#L62-L67)). Le programme redémarre `note_id` à 7.

Ce qui se passe si personne ne redémarre l'identité ([`sql/13-migration.sql`, lignes 14-21](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L14-L21)) :

```sql
-- La colonne d'identité part toujours de 1 : les lignes copiées ne l'ont pas avancée. RESTART WITH continue après
-- l'IDENT_CURRENT de SQL Server, 6
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

## Valider la copie

Un compte par table n'est pas une validation. Le programme lit chaque ligne sur les deux serveurs, dans l'ordre des clés, sous forme de texte dans un format sur lequel les deux s'accordent, puis compare les lignes et un SHA-256 de l'ensemble ([`L13.cs`, lignes 165-211](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/csharp-mssql/L13.cs#L165-L211)) :

```csharp
    // Une valeur en texte : les instants en UTC avec sept décimales, la précision de datetime2 et datetimeoffset
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

Quatre tables sont identiques. Dans `notes`, deux valeurs `datetimeoffset(7)` ont perdu leur septième décimale : `.1234567` est devenu `.123456` et `.9999999` est devenu `.999999`. Npgsql a tronqué les ticks de 100 nanosecondes aux microsecondes de PostgreSQL, ce que `timestamptz` peut contenir. La correction est une décision, pas du code : accepter les microsecondes, ou garder les ticks dans un `bigint` à côté de l'horodatage.

## Le code dans la base

La source a aussi une vue et une procédure ([lignes 175-190](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L175-L190)) :

```sql
-- Du code qui vit dans la base : une vue et une procédure, à convertir aussi
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

La procédure en fonction PL/pgSQL (leçon 8), avec [`RAISE`](https://www.postgresql.org/docs/18/plpgsql-errors-and-messages.html) pour `THROW` et `RETURNING … INTO` pour `SCOPE_IDENTITY()` ([`sql/13-migration.sql`, lignes 73-90](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L73-L90)) :

```sql
-- dbo.AddNote en fonction : RAISE pour THROW, RETURNING pour SCOPE_IDENTITY()
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

`NEWID()` devient `gen_random_uuid()`, `GETUTCDATE()` devient `now() AT TIME ZONE 'UTC'`, et le paramètre `OUTPUT` devient la valeur de retour. La vue est l'exercice 1.

## pgloader

[pgloader](https://pgloader.readthedocs.io/en/latest/ref/mssql.html) crée le schéma et copie les données en une seule commande. `check.sh` exécute l'image `ghcr.io/dimitri/pgloader` construite depuis le commit [`231ab86`](https://github.com/dimitri/pgloader/tree/231ab86778ca5ffd7de40878714760c8b4860cdf) (version `3.6.10~devel`), avec ses règles de conversion par défaut, dans une base à part :

```bash
docker run --rm --add-host=host.docker.internal:host-gateway ghcr.io/dimitri/pgloader@sha256:a1d4a78e78a64e46cd3fc7dfc57d24eb91ffb1a5520f2b1f55631815e3658d6e pgloader \
  'mssql://sa:Learn-2026!@host.docker.internal:1433/ci' \
  'postgresql://postgres:learn@host.docker.internal:5432/pgloader'
```

Il a annoncé 2 962 lignes et aucune erreur, en moins d'une seconde. Ce qu'il a créé ([`sql/pgloader-check.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/pgloader-check.sql), [`expected/13-pgloader.txt`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/13-pgloader.txt)) :

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

- **`money` a perdu deux décimales.** `0.0125` est devenu `0.01`. pgloader lit les colonnes `decimal`, `numeric`, `money` et `smallmoney` avec `convert(varchar(40), [col], 0)` ([`mssql-schema.lisp`, lignes 212-217](https://github.com/dimitri/pgloader/blob/231ab86778ca5ffd7de40878714760c8b4860cdf/src/sources/mssql/mssql-schema.lisp#L212-L217)), et pour `money`, le style 0 signifie « two digits to the right of the decimal point » ([`CAST` et `CONVERT`](https://learn.microsoft.com/sql/t-sql/functions/cast-and-convert-transact-sql#money-and-smallmoney-styles)). `SELECT CONVERT(varchar(40), CAST(0.0125 AS money), 0)` renvoie `0.01` sur ce SQL Server ; le style 2 garde quatre chiffres. Pas d'erreur, pas d'avertissement : seule une validation le trouve.
- **`datetimeoffset` a été arrondi, pas tronqué.** `.1234567` est devenu `.123457`, et `10:06:00.9999999 -04:00` est devenu `14:06:01`, la seconde suivante. Le programme C# tronquait. Les deux copies ne s'accordent ni entre elles, ni avec SQL Server.
- **Noms et types.** `RunId` est devenu `runid`, chaque chaîne un `text` sans sa longueur, `datetime` un `timestamptz`, `rowversion` un `bytea`, et la colonne calculée un simple `boolean` qui contient des valeurs copiées.
- **Contraintes.** Les clés primaires, les clés étrangères et `NOT NULL` ont suivi ; le `CHECK (Attempt >= 1)` non, et il n'y a pas de `c` parmi les types de contraintes. Les contraintes d'unicité sont devenues des index uniques, sans `NULLS NOT DISTINCT` ni collation insensible à la casse. `IX_Jobs_RunId … INCLUDE (Conclusion)` est devenu un index sur `(runid, conclusion)`, avec la colonne incluse comme clé.
- **La séquence** a été positionnée à 3, la plus grande clé, et non au 6 de SQL Server : pas de conflit ici, mais pas non plus la numérotation de la source.

pgloader est rapide pour un premier regard sur une base. Ses règles de conversion peuvent être changées dans un fichier de chargement, et son résultat a quand même besoin de la revue et de la validation des sections précédentes.

## AWS DMS

*À vérifier : rien dans cette section n'a tourné sur AWS.* [AWS Database Migration Service](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html) copie des données entre bases, depuis une instance de réplication ou avec DMS Serverless, en chargement complet, en réplication continue, ou les deux.

- **Sources.** « Microsoft SQL Server versions 2008 (supported in DMS v3.5.4), 2008R2(supported in DMS v3.5.4), 2012, 2014, 2016, 2017, 2019, and 2022 » ([sources](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Sources.html)). SQL Server 2025, la version de cette leçon, n'est pas listé. La réplication continue demande l'édition Enterprise, Developer ou Standard (2016 et plus).
- **Cibles.** « AWS DMS only supports PostgreSQL version 17.x and 18.x in versions 3.5.4 » ([cibles](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Targets.html)).
- **Réplication continue depuis SQL Server.** « The recovery model must be set to Bulk logged or Full », et « you must perform a backup before beginning to replicate data » ([source SQL Server](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html#CHAP_Source.SQLServer.Prerequisites)). Sur un serveur autogéré, DMS lit MS-Replication pour les tables qui ont une clé primaire et MS-CDC pour les autres ; « Amazon RDS for SQL Server doesn't support MS-Replication », donc là, il utilise MS-CDC pour toutes les tables ([CDC](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.CDC.html#CHAP_Source.SQLServer.CDC.Selfmanaged)).
- **Ce qu'il ne transporte pas.** « The identity property for a column isn't migrated to a target database column », « Changes to computed fields in a SQL Server aren't replicated », « AWS DMS doesn't capture truncate commands » ([limitations](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html#CHAP_Source.SQLServer.Limitations)). DMS « doesn't automatically create secondary indexes, foreign keys, user accounts, and so on » ([bonnes pratiques](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html#CHAP_SettingUp.MigrationPlanning)), et la prochaine valeur des séquences doit être fixée « after you stop the replication from the source database » ([cible PostgreSQL](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html#CHAP_Target.PostgreSQL.Limitations)) : le redémarrage d'identité de cette leçon.
- **Crée toi-même les tables cibles.** Quand DMS les crée, les tableaux de types de la [source](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html#CHAP_Source.SQLServer.DataTypes) et de la [cible](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html#CHAP_Target.PostgreSQL.DataTypes), mis bout à bout, donnent à un `datetime2` d'échelle 7 une colonne `VARCHAR (37)`, et à `datetimeoffset` et `uniqueidentifier` un `VARCHAR`. Cette lecture des deux tableaux est la mienne, pas une affirmation d'AWS.
- **Grandes valeurs.** Le mode LOB limité, par défaut, « migrates all LOB values up to a user-specified size limit (default is 32 KB) » ([LOB](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html#CHAP_BestPractices.LOBS.LimitedLOBMode)) : un `nvarchar(max)` plus long demande le mode LOB complet ou inline.
- **Validation.** « AWS DMS compares each row in the source with its corresponding row at the target … and reports any mismatches », et « requires that the table has a primary key or unique index » ([validation des données](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Validating.html)). Qu'elle signale les ticks perdus de `datetimeoffset(7)` est *à vérifier*.
- **Schéma.** [DMS Schema Conversion](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_SchemaConversion.html#how-schema-conversion-works) « builds on the AWS Schema Conversion Tool (AWS SCT) conversion engine » et, de SQL Server vers Aurora PostgreSQL, « can use generative AI to convert more » ; AWS ajoute qu'elle « may not achieve 100 percent accuracy … You must review and validate all conversion outputs » ([limitations](https://docs.aws.amazon.com/dms/latest/userguide/schema-conversion-convert.databaseobjects.html#schema-conversion-convert.databaseobjects.limitations)). L'outil de bureau [AWS SCT](https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html) est toujours publié (build 677).
- **DMS Serverless.** « The current engine version for AWS DMS Serverless is 3.5.4 » ([Serverless](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.html)) ; il « does not support views » ([limitations](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.Limitations.html)).

La [procédure pas à pas](https://docs.aws.amazon.com/dms/latest/sbs/schema-conversion-sql-server-aurora-postgresql.html) d'AWS déroule une conversion de SQL Server vers Aurora PostgreSQL dans la console ; le [playbook de migration](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.html) compare les fonctionnalités, pour SQL Server 2019.

## Babelfish

*À vérifier.* Babelfish prend l'autre chemin : l'application garde son T-SQL et son pilote SQL Server, et Aurora PostgreSQL lui répond. « SQL Server dialect (T-SQL), clients connect to port 1433. PostgreSQL dialect (PL/pgSQL), clients connect to port 5432 » ([Babelfish](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish.html)).

- **Versions.** Babelfish 6.1.0 « is provided with Aurora PostgreSQL 18.4 », publiée le 21 août 2026 ([mises à jour de Babelfish](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraBabelfish.Updates.html#AuroraBabelfish.Updates.610)).
- **Bases.** Aurora crée une base PostgreSQL nommée `babelfish_db`. En mode multi-bases, « the schema names of user databases become dbname_schemaname when accessed from PostgreSQL » ([architecture](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-architecture.html#babelfish-single_vs_multi_db)). Le mode se choisit une fois : « You must not change this parameter after creating your cluster as you could lose access to all your previously created SQL objects » ; le [tableau des paramètres](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-configuration.html#babelfish_params) dit « you can't modify this parameter's value », avec multi-db par défaut à partir d'Aurora PostgreSQL 16.
- **Collations : deux valeurs par défaut.** Le tableau des paramètres donne à `babelfishpg_tsql.server_collation_name` la valeur par défaut `bbf_unicode_general_ci_as` ; la [page des collations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-collations.html#babelfish-collations.parameters) dit « The default value is sql_latin1_general_cp1_ci_as ». Le tableau comparatif de la même page dit que PostgreSQL « Doesn't support the LIKE clause on nondeterministic collations », ce que PostgreSQL 18 a changé.
- **Les fonctionnalités non prises en charge** répondent par une erreur ou sont ignorées, selon les [escape hatches](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-strict.html#babelfish-escape_hatches) ; la [liste des fonctionnalités non prises en charge](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-compatibility.tsql.limitations-unsupported.html#babelfish-compatibility.tsql.limitations-unsupported-table) comprend les routines CLR et les curseurs modifiables. [Babelfish Compass](https://github.com/babelfish-for-postgresql/babelfish_compass) lit le DDL d'une base et signale ce que Babelfish prend en charge ; sa dernière version est [v.2026-07](https://github.com/babelfish-for-postgresql/babelfish_compass/releases/tag/v.2026-07).
- **Pas en local.** Le [Babelfish for PostgreSQL](https://babelfishpg.org/) open source demande un PostgreSQL modifié, compilé depuis les sources ; sa dernière version est [5.4.0 pour PostgreSQL 17.7](https://github.com/babelfish-for-postgresql/babelfish-for-postgresql/releases/tag/BABEL_5_4_0__PG_17_7), et le projet ne publie aucune image de conteneur. Le cours ne le compile pas.

Babelfish déplace la base sans réécrire l'application, et l'application garde les comportements SQL Server des sections précédentes, pour autant que Babelfish les émule : chacun est *à vérifier* avec les propres listes de Babelfish.

## Coûts

*À vérifier : les prix changent, et le cours n'a rien acheté.* Les chiffres sont les prix à la demande d'AWS dans US East (N. Virginia), tirés des fichiers de l'[AWS Price List](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json) publiés le 2026-09-11, que la [page des prix d'Aurora](https://aws.amazon.com/rds/aurora/pricing/) affiche aussi.

| Aurora PostgreSQL | Aurora Standard | Aurora I/O-Optimized |
|---|---|---|
| db.r8g.large ou db.r7g.large (2 vCPU, 16 Gio), par heure | 0,276 $ | 0,359 $ |
| stockage, par Go-mois | 0,10 $ | 0,225 $ |
| E/S, par million de requêtes | 0,20 $ | inclus |
| Aurora Serverless, par ACU-heure | 0,12 $ | 0,16 $ |
| stockage de sauvegarde au-delà de la taille du cluster, par Go-mois | 0,021 $ | 0,021 $ |

Pour comparaison, d'après les mêmes fichiers :

- **RDS for SQL Server Standard Edition**, licence incluse, sur une db.r6i.large Single-AZ : 1,02 $ par heure, environ 745 $ par mois pour une instance.
- **La licence elle-même** : la [grille tarifaire de SQL Server 2025](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/cloud/SQL-Server-2025-Pricing.pdf) de Microsoft liste Standard à 3 945 $ et Enterprise à 15 123 $ par pack de 2 cœurs.
- **La migration** : une instance de réplication dms.r6i.large coûte 0,176 $ par heure ; DMS Serverless, 0,0819 $ par DCU-heure, où « One DCU equals 2GB of RAM » ([prix de DMS](https://aws.amazon.com/dms/pricing/)). Babelfish « doesn't have an additional cost » ([DMS et Babelfish](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html#CHAP_Target.PostgreSQL.Babelfish)).

Les conseils prescriptifs d'AWS affirment que passer de SQL Server Enterprise sur EC2 à Aurora « can result in cost savings up to 70 percent » ([optimisation des coûts](https://docs.aws.amazon.com/prescriptive-guidance/latest/optimize-costs-microsoft-workloads/modernize-sql-server.html#modernize-sql-server-database)) : une affirmation à vérifier avec tes propres tailles d'instances, tes E/S et tes conditions de licence, dans l'[AWS Pricing Calculator](https://calculator.aws/). L'exercice 3 fait le calcul pour un cluster.

## À retenir

- Fais tourner les deux serveurs et pose-leur les mêmes questions avant de déplacer les données : collation, espaces finaux, ordre des `NULL`, ordre des GUID, `NULL` dans les contraintes d'unicité, précision des dates, erreurs dans les transactions.
- Une collation ICU non déterministe donne les comparaisons insensibles à la casse de SQL Server, `LIKE` compris à partir de PostgreSQL 18 ; les espaces finaux restent significatifs.
- `datetime2(7)` et `datetimeoffset` perdent leur septième décimale, et `datetimeoffset` son décalage ; `datetime` était déjà arrondi dans SQL Server.
- Crée toi-même le schéma cible, charge, puis ajoute les clés étrangères et les index, redémarre les identités à partir de l'`IDENT_CURRENT` de SQL Server, et lance `ANALYZE`.
- Valide des lignes, pas des comptes : le programme a trouvé les ticks perdus, et une validation aurait trouvé les valeurs `money` de pgloader coupées à deux décimales.
- PostgreSQL abandonne toute la transaction après une erreur ; SQL Server, par défaut, non.
- DMS copie et réplique les données, mais pas les identités, les index secondaires ni le code ; Babelfish garde le T-SQL, et son comportement est à vérifier avec ses listes de compatibilité.
- Le prix d'Aurora a trois parts : instances, stockage et E/S ; au-delà d'un certain volume d'E/S, I/O-Optimized coûte moins cher.

## Exercices

1. Convertis `dbo.SlowJobs` en une vue PostgreSQL sur `ci.jobs` et `ci.runs` de la leçon 2, et vérifie qu'elle renvoie les mêmes cinq lignes que SQL Server.

<details>
<summary>Solution</summary>

[`sql/13-exercises.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-exercises.sql#L7-L16) :

```sql
-- Exercice 1 : dbo.SlowJobs en vue PostgreSQL. DATEDIFF(second, ...) compte les frontières de seconde franchies ;
-- la différence de deux timestamptz tronqués à la seconde compte la même chose.
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

Les mêmes lignes que [celles de SQL Server](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/mssql-13-source.txt#L55-L61). [`DATEDIFF`](https://learn.microsoft.com/sql/t-sql/functions/datediff-transact-sql) compte les frontières franchies, donc de `10:00:00.9` à `10:00:01.1` il y a une seconde ; `date_trunc('second', …)` aux deux bouts compte de la même façon, là où `extract(epoch FROM completed_at - started_at)` donnerait 0,2. `TOP (5) WITH TIES` devient `FETCH FIRST 5 ROWS WITH TIES`, et l'`ORDER BY` d'une vue est gardé ici, mais la requête qui lit la vue trie quand même son propre résultat.

</details>

2. Avant de convertir une base SQL Server plus grande, liste, depuis le catalogue de SQL Server, les colonnes dont le type demande une décision, et les auteurs qui ne diffèrent que par la casse ou des espaces finaux.

<details>
<summary>Solution</summary>

[`mssql/13-exercises.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-exercises.sql) :

```sql
-- Leçon 13, exercice 2 : les colonnes dont le type demande une décision avant la conversion, d'après le catalogue de SQL Server
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

-- Les collations autres que celle de la base, et les chaînes qui ne diffèrent que par la casse ou des espaces finaux
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

`rowversion` apparaît comme `timestamp`, son ancien nom, et l'échelle de `datetime` apparaît comme 3 alors que ses valeurs sont arrondies au 1/300 de seconde. Aucune colonne n'a sa propre collation ici. Une collation binaire, `Latin1_General_BIN2`, fait montrer à SQL Server lui-même les trois graphies que sa collation par défaut traite comme une seule.

</details>

3. Pour un writer et une Aurora Replica en db.r8g.large, qui tournent tout le mois (730 heures), avec 100 Gio de données et 300 millions de requêtes d'E/S par mois, compare Aurora Standard et Aurora I/O-Optimized. À partir de combien de requêtes d'E/S par mois I/O-Optimized coûte-t-il moins cher ?

<details>
<summary>Solution</summary>

[`sql/13-exercises.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-exercises.sql#L18-L33) :

```sql
-- Exercice 3 : un mois de 730 heures pour un writer et une Aurora Replica, tous deux en db.r8g.large, avec 100 Gio de données
-- et 300 millions de requêtes d'E/S, aux prix à la demande de us-east-1 de l'AWS Price List publiée le 2026-09-11
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

-- Le nombre de millions de requêtes d'E/S par mois à partir duquel I/O-Optimized coûte moins cher, pour les mêmes instances et données
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

Environ 473 $ contre 547 $ : à 300 millions de requêtes d'E/S, Standard est moins cher. Sans E/S, I/O-Optimized coûte 133,68 $ de plus par mois en instances et en stockage ; à 0,20 $ par million de requêtes, les E/S de Standard atteignent ce montant vers 668 millions de requêtes par mois. La règle empirique d'AWS elle-même est d'envisager I/O-Optimized quand les E/S dépassent 25 % de la facture Aurora ([prix d'Aurora](https://aws.amazon.com/rds/aurora/pricing/)). Les sauvegardes, le transfert de données et les snapshots sont laissés de côté.

</details>

## Sources

- SQL Server, sur Microsoft Learn : [nouveautés de SQL Server 2025](https://learn.microsoft.com/sql/sql-server/what-s-new-in-sql-server-2025), [démarrage rapide Docker](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker), [`sqlcmd`](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility), [collations](https://learn.microsoft.com/sql/relational-databases/collations/collation-and-unicode-support), [`datetime`](https://learn.microsoft.com/sql/t-sql/data-types/datetime-transact-sql), [`uniqueidentifier`](https://learn.microsoft.com/sql/t-sql/data-types/uniqueidentifier-transact-sql), [comparer des GUID](https://learn.microsoft.com/sql/connect/ado-net/sql/compare-guid-uniqueidentifier-values), [comparaison de chaînes](https://learn.microsoft.com/sql/t-sql/language-elements/string-comparison-assignment), [`ORDER BY`](https://learn.microsoft.com/sql/t-sql/queries/select-order-by-clause-transact-sql), [`SET XACT_ABORT`](https://learn.microsoft.com/sql/t-sql/statements/set-xact-abort-transact-sql), [`CAST` et `CONVERT`](https://learn.microsoft.com/sql/t-sql/functions/cast-and-convert-transact-sql), [`DATEDIFF`](https://learn.microsoft.com/sql/t-sql/functions/datediff-transact-sql), [`OPENROWSET(BULK)`](https://learn.microsoft.com/sql/t-sql/functions/openrowset-bulk-transact-sql), [`OPENJSON`](https://learn.microsoft.com/sql/t-sql/functions/openjson-transact-sql), [Microsoft.Data.SqlClient](https://learn.microsoft.com/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace), [Data Migration Assistant](https://learn.microsoft.com/sql/dma/dma-overview) ; [grille tarifaire de SQL Server 2025](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/cloud/SQL-Server-2025-Pricing.pdf)
- PostgreSQL 18 : [collations](https://www.postgresql.org/docs/18/collation.html), [notes de version](https://www.postgresql.org/docs/18/release-18.html), [correspondance de motifs](https://www.postgresql.org/docs/18/functions-matching.html), [`citext`](https://www.postgresql.org/docs/18/citext.html), [`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html), [colonnes générées](https://www.postgresql.org/docs/18/ddl-generated-columns.html), [types date/heure](https://www.postgresql.org/docs/18/datatype-datetime.html), [`SAVEPOINT`](https://www.postgresql.org/docs/18/sql-savepoint.html), [erreurs et messages PL/pgSQL](https://www.postgresql.org/docs/18/plpgsql-errors-and-messages.html), [types monétaires](https://www.postgresql.org/docs/18/datatype-money.html), [codes d'erreur](https://www.postgresql.org/docs/18/errcodes-appendix.html)
- Npgsql : [types date et heure](https://www.npgsql.org/doc/types/datetime.html), [jetons de concurrence d'EF Core](https://www.npgsql.org/efcore/modeling/concurrency.html)
- pgloader : [source MS SQL](https://pgloader.readthedocs.io/en/latest/ref/mssql.html), [`mssql-schema.lisp` à `231ab86`](https://github.com/dimitri/pgloader/blob/231ab86778ca5ffd7de40878714760c8b4860cdf/src/sources/mssql/mssql-schema.lisp)
- AWS DMS, lu le 2026-09-16 : [ce qu'est DMS](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html), [sources](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Sources.html), [cibles](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Targets.html), [source SQL Server](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html), [sa CDC](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.CDC.html), [cible PostgreSQL](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html), [bonnes pratiques](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html), [validation des données](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Validating.html), [Schema Conversion](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_SchemaConversion.html), [ses limitations](https://docs.aws.amazon.com/dms/latest/userguide/schema-conversion-convert.databaseobjects.html), [AWS SCT](https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html), [DMS Serverless](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.html) et [ses limitations](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.Limitations.html), [procédure pas à pas](https://docs.aws.amazon.com/dms/latest/sbs/schema-conversion-sql-server-aurora-postgresql.html), [playbook de migration](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.html)
- Babelfish, lu le 2026-09-16 : [présentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish.html), [architecture](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-architecture.html), [paramètres](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-configuration.html), [collations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-collations.html), [escape hatches](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-strict.html), [fonctionnalités non prises en charge](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-compatibility.tsql.limitations-unsupported.html), [notes de version](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraBabelfish.Updates.html), [Babelfish Compass](https://github.com/babelfish-for-postgresql/babelfish_compass), [Babelfish for PostgreSQL](https://babelfishpg.org/)
- Prix, lus le 2026-09-16 : [index de l'AWS Price List](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json), [prix d'Aurora](https://aws.amazon.com/rds/aurora/pricing/), [prix de DMS](https://aws.amazon.com/dms/pricing/), [prix de RDS for SQL Server](https://aws.amazon.com/rds/sqlserver/pricing/), [AWS Pricing Calculator](https://calculator.aws/), [conseils prescriptifs sur les coûts de SQL Server](https://docs.aws.amazon.com/prescriptive-guidance/latest/optimize-costs-microsoft-workloads/modernize-sql-server.html)
