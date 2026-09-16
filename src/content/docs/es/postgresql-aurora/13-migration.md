---
title: "13. Migrar desde SQL Server, y costes"
description: Una base de datos SQL Server 2025 con los datos de CI del curso, migrada a PostgreSQL 18 a mano, con un programa C# con SqlClient y COPY binario, y con pgloader — collations, espacios finales, precisión de datetime, orden de los GUID, NULL en las restricciones únicas, identidades y transacciones comparados en ambos servidores — y después AWS DMS, Babelfish y el coste de Aurora PostgreSQL según la documentación y la lista de precios de AWS, consultadas el 2026-09-16.
sidebar:
  order: 13
---

Las lecciones anteriores comparaban PostgreSQL con SQL Server funcionalidad a funcionalidad. Esta traslada una base de datos. Parte de un SQL Server real: [SQL Server 2025](https://learn.microsoft.com/sql/sql-server/what-s-new-in-sql-server-2025) en la imagen de contenedor de Microsoft `mcr.microsoft.com/mssql/server:2025-CU9-ubuntu-24.04` (17.0.5005.3, digest `sha256:2b5b581621126574f3d1f75e78d3eebe8d05aedb59ad0cfdf9aa42cb0634d726`), con las mismas ejecuciones y jobs de GitHub Actions que el resto del curso. Después los datos van dos veces a PostgreSQL 18: con un programa C#, y con [pgloader](https://pgloader.io/). Ambos se ejecutan en el modo `mssql` de `check.sh` y en la CI, donde SQL Server es un contenedor de servicio junto a PostgreSQL.

El código:

- [`mssql.sh`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql.sh) arranca SQL Server y ejecuta [`sqlcmd`](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility) dentro de él;
- [`mssql/13-source.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql) crea la base de datos de origen;
- [`sql/mssql-target.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target.sql) y [`sql/mssql-target-after.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target-after.sql) son el esquema convertido;
- [`csharp-mssql/L13.cs`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/csharp-mssql/L13.cs) copia y valida;
- [`sql/13-migration.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql) muestra lo que se comporta de otra forma una vez que los datos están en PostgreSQL;
- [`sql/pgloader-check.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/pgloader-check.sql) examina lo que creó pgloader.

Los servicios de migración de AWS no se pueden ejecutar en local, y el curso no usa ninguna cuenta de AWS: [AWS DMS](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html), [Babelfish para Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish.html) y los precios vienen de la documentación y la lista de precios de AWS, consultadas el 2026-09-16, y están *por verificar*.

| Herramienta de SQL Server | Para PostgreSQL y Aurora |
|---|---|
| [Data Migration Assistant](https://learn.microsoft.com/sql/dma/dma-overview), SSMA | DMS Schema Conversion o la AWS Schema Conversion Tool; Babelfish Compass para evaluar el T-SQL de cara a Babelfish |
| `bcp`, `SqlBulkCopy`, SSIS | `COPY` desde un programa (lección 4), pgloader, carga completa de AWS DMS |
| replicación transaccional, captura de datos modificados | replicación continua de AWS DMS, que lee MS-Replication o MS-CDC de SQL Server |
| una aplicación T-SQL trasladada tal cual | Babelfish: Aurora PostgreSQL hablando TDS en el puerto 1433 |

## La base de datos que migrar

`bash mssql.sh start` ejecuta el contenedor; SQL Server en Linux necesita «at least 2 GB of RAM» ([inicio rápido de Docker](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker)), y `mssql.sh` lo limita a 2048 MB con `MSSQL_MEMORY_LIMIT_MB`. El esquema de origen es lo que podría haber escrito un equipo de SQL Server: nombres en PascalCase, `nvarchar`, `tinyint`, tres tipos de fecha, una columna calculada, `rowversion`, una clave `IDENTITY`, un `uniqueidentifier`, `money` ([`mssql/13-source.sql`, líneas 12-66](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L12-L66)):

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

-- Una fila por etiqueta: SQL Server no tiene tipo array
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

-- Notas escritas por personas, con los tipos que suele tener un esquema SQL Server: una clave IDENTITY, un GUID, money, datetime
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

Las ejecuciones, los jobs y los pasos vienen de los mismos archivos JSON que en la lección 2, leídos con [`OPENROWSET(BULK …)`](https://learn.microsoft.com/sql/t-sql/functions/openrowset-bulk-transact-sql) y [`OPENJSON`](https://learn.microsoft.com/sql/t-sql/functions/openjson-transact-sql); tres notas se escriben a mano, para contener los valores que no sobreviven intactos a una migración (líneas 98-104):

```sql
INSERT INTO dbo.Notes (NoteGuid, RunId, Author, Tag, Body, Cost, WrittenAt, WrittenLocal) VALUES
    ('6F9619FF-8B86-D011-B42D-00C04FC964FF', 34852867099, N'Reviewer', 'Slow', N'Deploy took 2.5 minutes', 0.0125,
     '2026-09-14 14:05:00.001', '2026-09-14 16:05:00.1234567 +02:00'),
    ('00000000-0000-0000-0000-000000000001', 34852867099, N'reviewer ', NULL, N'Looks fine now', NULL,
     '2026-09-14 14:06:00.005', '2026-09-14 10:06:00.9999999 -04:00'),
    ('01000000-0000-0000-0000-000000000000', NULL, N'REVIEWER', 'flaky', N'Café au lait', 3.5,
     '2026-09-14 14:07:00.998', '2026-09-14 14:07:00 +00:00');
```

La salida empieza con la collation de la base de datos y los recuentos de filas ([`expected/mssql-13-source.txt`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/mssql-13-source.txt)):

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

`sqlcmd` se ejecuta con `-W -s '|'`: columnas recortadas separadas por barras. `SQL_Latin1_General_CP1_CI_AS` es la collation por defecto de una instalación en inglés de EE. UU. ([collations](https://learn.microsoft.com/sql/relational-databases/collations/collation-and-unicode-support#server-level-collations)): no distingue mayúsculas (`CI`) y distingue acentos (`AS`).

## Siete comportamientos que comprobar antes de trasladar los datos

Las mismas preguntas, hechas a SQL Server ([líneas 114-142](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L114-L142)):

```sql
-- datetime guarda 1/300 de segundo: .001 se guardó como .000, .005 como .007
SELECT NoteId, WrittenAt, WrittenLocal FROM dbo.Notes ORDER BY NoteId;

-- La collation por defecto ignora las mayúsculas, y = ignora los espacios finales
SELECT COUNT(DISTINCT Author) AS authors, SUM(CASE WHEN Author = N'reviewer' THEN 1 ELSE 0 END) AS [= 'reviewer']
FROM dbo.Notes;
BEGIN TRY
    INSERT INTO dbo.Notes (NoteGuid, Author, Tag, Body, WrittenAt, WrittenLocal)
    VALUES (NEWID(), N'Reviewer', 'SLOW', N'again', '2026-09-14', '2026-09-14 00:00 +00:00');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS message;
END CATCH;
-- Una restricción UNIQUE acepta un NULL, no dos
BEGIN TRY
    INSERT INTO dbo.Notes (NoteGuid, Author, Tag, Body, WrittenAt, WrittenLocal)
    VALUES (NEWID(), N'Reviewer', NULL, N'again', '2026-09-14', '2026-09-14 00:00 +00:00');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS message;
END CATCH;

-- uniqueidentifier ordena primero por sus seis últimos bytes; NULL va primero
SELECT NoteGuid, Cost FROM dbo.Notes ORDER BY NoteGuid;
SELECT NoteId, Cost FROM dbo.Notes ORDER BY Cost;

-- + con NULL da NULL, CONCAT lo ignora; TOP e ISNULL
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

Y a PostgreSQL, sobre la tabla convertida de la sección siguiente, con las notas tal como las copia el programa ([`sql/13-migration.sql`, líneas 23-50](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L23-L50)). El script añade primero una cuarta nota, la número 7, para la sección sobre la identidad:

```sql
-- timestamptz conserva el instante, no el desfase: cada valor vuelve en la zona horaria de la sesión
SELECT note_id, written_at, written_local FROM migrated.notes ORDER BY note_id;

-- La collation ci ignora las mayúsculas, pero no los espacios finales: tres autores pasan a ser dos
SELECT count(DISTINCT author) AS authors, count(*) FILTER (WHERE author = 'reviewer') AS "= 'reviewer'"
FROM migrated.notes;
-- La misma columna comparada con la collation por defecto de la base de datos
SELECT count(DISTINCT author COLLATE "default") AS authors FROM migrated.notes;
-- rtrim donde importaban las reglas de relleno de SQL Server
SELECT count(DISTINCT rtrim(author)) AS authors FROM migrated.notes;

-- LIKE sobre una collation no determinista: nuevo en PostgreSQL 18
SELECT note_id, author FROM migrated.notes WHERE author LIKE 'rev%' ORDER BY note_id;

-- La restricción única también compara las etiquetas con la collation ci, y acepta un solo NULL
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', 'SLOW', 'again', '2026-09-14', '2026-09-14 00:00+00');
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', NULL, 'again', '2026-09-14', '2026-09-14 00:00+00');

-- uuid ordena byte a byte, desde la izquierda; NULL va al final en orden ascendente
SELECT note_guid, cost FROM migrated.notes ORDER BY note_guid;
SELECT note_id, cost FROM migrated.notes ORDER BY cost;
SELECT note_id, cost FROM migrated.notes ORDER BY cost NULLS FIRST;

-- || con NULL da NULL, concat lo ignora; FETCH FIRST ... WITH TIES, y coalesce en lugar de ISNULL
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

1. **`datetime` no es preciso al milisegundo.** Sus valores están «rounded to increments of .000, .003, or .007 seconds» ([`datetime`](https://learn.microsoft.com/sql/t-sql/data-types/datetime-transact-sql)): `.001` se guardó como `.000`, `.005` como `.007`, `.998` como `.997`. La migración copia los valores redondeados; nada puede recuperar los originales.
2. **`timestamptz` conserva el instante, no el desfase.** `datetimeoffset` conservaba `+02:00` y `-04:00`; PostgreSQL devuelve cada valor en la zona horaria de la sesión, aquí UTC. La documentación de Npgsql dice lo mismo: «only a UTC timestamp is stored» ([tipos de fecha y hora](https://www.npgsql.org/doc/types/datetime.html)). Si el desfase de quien escribió importa, necesita su propia columna.
3. **Mayúsculas.** Con la collation por defecto de la base de datos, `Reviewer`, `reviewer ` y `REVIEWER` son tres autores. El destino declara una [collation ICU no determinista](https://www.postgresql.org/docs/18/collation.html#COLLATION-NONDETERMINISTIC), `und-u-ks-level2`, que compara sin distinguir mayúsculas: pasan a ser dos.
4. **Espacios finales.** «Transact-SQL considers the strings 'abc' and 'abc ' to be equivalent for most comparison operations» ([comparación de cadenas](https://learn.microsoft.com/sql/t-sql/language-elements/string-comparison-assignment#remarks)), así que SQL Server cuenta un solo autor. En `varchar` y `text` de PostgreSQL el espacio sigue siendo significativo; `rtrim` devuelve el recuento de SQL Server. La extensión `citext` también ignora las mayúsculas, pero su [documentación](https://www.postgresql.org/docs/18/citext.html) dice ahora: «Consider using nondeterministic collations … instead of this module.»
5. **`LIKE` sobre una columna que no distingue mayúsculas.** Funciona en PostgreSQL 18: «Allow LIKE with nondeterministic collations» ([notas de versión](https://www.postgresql.org/docs/18/release-18.html#RELEASE-18-UTILITY)). `ILIKE` «does not support nondeterministic collations» ([coincidencia de patrones](https://www.postgresql.org/docs/18/functions-matching.html#FUNCTIONS-LIKE)).
6. **Restricciones únicas y `NULL`.** SQL Server rechazó `SLOW` junto a `Slow`, y una segunda etiqueta `NULL`. PostgreSQL trata los `NULL` como distintos en una restricción única «unless NULLS NOT DISTINCT is specified» ([`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html)): el destino lo declara, junto con la collation `ci`, para mantener ambas reglas.
7. **Órdenes.** En `uniqueidentifier`, «ordering is not implemented by comparing the bit patterns of the two values» ([`uniqueidentifier`](https://learn.microsoft.com/sql/t-sql/data-types/uniqueidentifier-transact-sql#remarks)): SQL Server compara primero «the last six bytes of a value» ([comparar GUID](https://learn.microsoft.com/sql/connect/ado-net/sql/compare-guid-uniqueidentifier-values#comparing-guid-values)), el `uuid` de PostgreSQL byte a byte desde la izquierda, así que las tres notas salen en otro orden. SQL Server ordena `NULL` primero, como «the lowest possible values» ([`ORDER BY`](https://learn.microsoft.com/sql/t-sql/queries/select-order-by-clause-transact-sql#arguments)); PostgreSQL lo ordena al final en orden ascendente, salvo con `NULLS FIRST`. Una paginación por conjunto de claves sobre un GUID, o un informe que espera los `NULL` arriba, cambia sin avisar.

La última consulta es la misma en ambos: `+` y `||` dan `NULL` cuando un lado es `NULL`, `CONCAT` y `concat` lo omiten; `ISNULL` pasa a ser `coalesce`, `TOP (2)` pasa a ser `FETCH FIRST 2 ROWS ONLY`.

## Transacciones después de un error

SQL Server y PostgreSQL no coinciden en lo que un error le hace a una transacción ([líneas 145-172](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L145-L172)):

```sql
-- Sin SET XACT_ABORT, una instrucción fallida no termina la transacción: XACT_STATE() sigue valiendo 1, y COMMIT
-- conserva las filas insertadas alrededor. (El error se captura: sqlcmd 18.6 descarta los resultados tras un error no capturado.)
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

-- Con SET XACT_ABORT ON, el mismo error condena la transacción: XACT_STATE() vale -1, solo cabe un rollback
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

Con [`SET XACT_ABORT`](https://learn.microsoft.com/sql/t-sql/statements/set-xact-abort-transact-sql#remarks) en su valor por defecto, «OFF is the default setting in a T-SQL statement», una clave duplicada termina la instrucción, no la transacción: `XACT_STATE()` sigue valiendo 1 y `COMMIT` conserva `self-hosted` y `linux`. Con `XACT_ABORT ON`, la transacción solo puede revertirse. El error se captura con `TRY … CATCH` porque `sqlcmd` 18.6 descartaba todos los resultados posteriores a un error no capturado en un script (ver el [diario](../journal/)).

PostgreSQL se comporta como `XACT_ABORT ON`, y de forma más estricta ([`sql/13-migration.sql`, líneas 52-71](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L52-L71)):

```sql
-- Un error dentro de una transacción aborta la transacción entera: la instrucción siguiente se rechaza, COMMIT revierte
BEGIN;
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES ('10000000-0000-0000-0000-000000000000', 'Reviewer', 'retry', 'kept?', '2026-09-16', '2026-09-16 00:00+00');
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', 'Retry', 'duplicate tag', '2026-09-16', '2026-09-16 00:00+00');
SELECT count(*) FROM migrated.notes;
COMMIT;
SELECT count(*) AS kept FROM migrated.notes WHERE tag = 'retry';

-- Un savepoint devuelve el comportamiento de SQL Server para una instrucción
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

Tras el error, se rechaza cada instrucción hasta el final de la transacción, y `COMMIT` responde `ROLLBACK`. El código que contaba con que SQL Server siguiera tras una instrucción fallida necesita un [`SAVEPOINT`](https://www.postgresql.org/docs/18/sql-savepoint.html) alrededor de esa instrucción. Un driver que envía de todos modos la instrucción siguiente recibe el SQLSTATE `25P02`, `in_failed_sql_transaction` ([códigos de error](https://www.postgresql.org/docs/18/errcodes-appendix.html)).

## Convertir el esquema a mano

El esquema de destino ([`sql/mssql-target.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target.sql#L1-L68)):

```sql
-- Lección 13: las tablas de mssql/13-source.sql convertidas a mano, antes de la carga. Nombres en snake_case, para que
-- no necesiten comillas; claves, pero aún sin claves foráneas ni índices secundarios (los añade mssql-target-after.sql).
DROP SCHEMA IF EXISTS migrated CASCADE;
CREATE SCHEMA migrated;

-- SQL_Latin1_General_CP1_CI_AS compara sin distinguir mayúsculas; esta collation ICU hace lo mismo, y no es determinista:
-- dos cadenas pueden ser iguales sin tener los mismos bytes
CREATE COLLATION migrated.ci (provider = icu, locale = 'und-u-ks-level2', deterministic = false);

CREATE TABLE migrated.runs (
    run_id        bigint PRIMARY KEY,
    workflow_name varchar(100) NOT NULL,
    event         varchar(30) NOT NULL,
    conclusion    varchar(20),
    head_branch   varchar(255) NOT NULL,
    head_sha      char(40) NOT NULL,
    -- tinyint va de 0 a 255; PostgreSQL no tiene entero de un byte
    attempt       smallint NOT NULL CHECK (attempt BETWEEN 1 AND 255),
    -- datetime2, datetime y datetimeoffset contienen todos horas UTC aquí: timestamptz
    created_at    timestamptz(0) NOT NULL,
    started_at    timestamptz(3) NOT NULL,
    updated_at    timestamptz NOT NULL,
    -- una columna calculada no persistida: una columna generada virtual (PostgreSQL 18)
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
    -- sin rowversion: la columna de sistema xmin hace ese papel para la concurrencia optimista
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
    -- BY DEFAULT, para que la carga pueda conservar los valores del origen
    note_id       integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    note_guid     uuid NOT NULL UNIQUE,
    run_id        bigint,
    author        varchar(50) COLLATE migrated.ci NOT NULL,
    -- NULLS NOT DISTINCT: un NULL como máximo, como en SQL Server
    tag           varchar(20) COLLATE migrated.ci UNIQUE NULLS NOT DISTINCT,
    body          text NOT NULL,
    cost          numeric(19, 4),
    -- datetime no tiene zona horaria: timestamp, al milisegundo
    written_at    timestamp(3) NOT NULL,
    -- datetimeoffset conserva el desfase de quien escribe; timestamptz solo conserva el instante
    written_local timestamptz NOT NULL
);
```

Las decisiones, tipo de columna por tipo de columna:

| SQL Server | PostgreSQL aquí | Por qué |
|---|---|---|
| nombres `PascalCase` | `snake_case` | los identificadores sin comillas se pasan a minúsculas (lección 1); `"RunId"` necesitaría comillas en todas partes |
| `nvarchar(n)`, `varchar(n)` | `varchar(n)`, `text` | las cadenas de PostgreSQL son todas Unicode (aquí UTF-8); la longitud es una restricción, no una elección de almacenamiento |
| `char(40)` | `char(40)` | la misma semántica de relleno para un hash de longitud fija |
| `tinyint` | `smallint` con un `CHECK` | no hay entero de un byte |
| columna calculada `bit` | `boolean GENERATED ALWAYS AS (…) VIRTUAL` | una columna generada virtual, nueva en PostgreSQL 18 y ahora «the default kind» ([columnas generadas](https://www.postgresql.org/docs/18/ddl-generated-columns.html)) |
| `datetime2(0)`, `datetime2(7)` | `timestamptz(0)`, `timestamptz` | valores UTC; la resolución de PostgreSQL es «1 microsecond» ([tipos de fecha/hora](https://www.postgresql.org/docs/18/datatype-datetime.html)), la de `datetime2` es de 100 ns |
| `datetime` | `timestamp(3)`, `timestamptz(3)` | el tipo no tiene zona horaria: `timestamp` si los valores son locales, `timestamptz` si están en UTC |
| `datetimeoffset(7)` | `timestamptz` | el desfase se pierde |
| `money` | `numeric(19, 4)` | el `money` de PostgreSQL tiene su «fractional precision … determined by the database's lc_monetary setting» ([tipos monetarios](https://www.postgresql.org/docs/18/datatype-money.html)) |
| `uniqueidentifier` | `uuid` | los mismos 16 bytes, otro orden |
| `rowversion` | nada | para la concurrencia optimista, el proveedor EF Core de Npgsql usa la columna de sistema `xmin` ([tokens de concurrencia](https://www.npgsql.org/efcore/modeling/concurrency.html)) |
| `int IDENTITY(1, 1)` | `integer GENERATED BY DEFAULT AS IDENTITY` | `BY DEFAULT`, para que la carga pueda escribir las claves del origen |
| collation `CI_AS` | una collation ICU no determinista, en las columnas que la necesitan | una collation no determinista cuesta rendimiento, «B-tree cannot use deduplication with indexes that use a nondeterministic collation» ([collations](https://www.postgresql.org/docs/18/collation.html#COLLATION-NONDETERMINISTIC)) |

Las claves foráneas y los índices secundarios llegan después de la carga ([`sql/mssql-target-after.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/mssql-target-after.sql)):

```sql
-- Lección 13: lo que recibe el destino tras la carga. Las claves foráneas se comprueban una vez, sobre las filas cargadas;
-- los índices se construyen una vez, en lugar de actualizarse fila a fila.
ALTER TABLE migrated.jobs ADD FOREIGN KEY (run_id) REFERENCES migrated.runs;
ALTER TABLE migrated.job_labels ADD FOREIGN KEY (job_id) REFERENCES migrated.jobs;
ALTER TABLE migrated.steps ADD FOREIGN KEY (job_id) REFERENCES migrated.jobs;
ALTER TABLE migrated.notes ADD FOREIGN KEY (run_id) REFERENCES migrated.runs;
-- IX_Jobs_RunId ... INCLUDE (Conclusion) tiene la misma sintaxis
CREATE INDEX jobs_run_id ON migrated.jobs (run_id) INCLUDE (conclusion);
ANALYZE migrated.runs, migrated.jobs, migrated.job_labels, migrated.steps, migrated.notes;
```

## Copiar los datos con C#

[`Microsoft.Data.SqlClient`](https://learn.microsoft.com/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace) 7.0.3 lee cada tabla; el `COPY` binario de Npgsql (lección 4) la escribe. Cada tabla tiene un `SELECT`, un `COPY` y una función que escribe las columnas de una fila con tipos explícitos ([`L13.cs`, líneas 19-23 y 76-135](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/csharp-mssql/L13.cs#L19-L135)):

```csharp
    // Una tabla que copiar: el SELECT en SQL Server, el COPY en PostgreSQL, y cómo se escribe cada columna
    record Table(string Name, string Select, string Copy, Action<SqlDataReader, NpgsqlBinaryImporter> Write);

    // datetime y datetime2 vuelven con DateTimeKind.Unspecified; Npgsql solo escribe en timestamptz valores DateTime en UTC
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
                // timestamp: sin zona horaria en ningún lado, el DateTime se escribe tal cual
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

        // La columna de identidad continúa tras el último valor de SQL Server, no tras la mayor clave copiada
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

- **`DateTime.Kind`.** SqlClient devuelve los valores `datetime` y `datetime2` como `DateTime` de tipo no especificado; «Npgsql maps UTC DateTime to timestamp with time zone» ([tipos de fecha y hora](https://www.npgsql.org/doc/types/datetime.html)), así que el programa indica que están en UTC con `DateTime.SpecifyKind`. `datetimeoffset` pasa a ser `DateTimeOffset.UtcDateTime`.
- **Un proyecto aparte.** El programa está en `csharp-mssql`, no con los demás ejemplos: en `csharp/`, donde `InvariantGlobalization` está activado, `SqlConnection.OpenAsync` lanzó `System.NotSupportedException: Globalization Invariant Mode is not supported.`
- **Una tabla cada vez, en una transacción cada una.** Basta para 2962 filas. Una migración real también tiene que ocuparse de las escrituras durante la copia, que es para lo que sirve la replicación continua de DMS.
- **La identidad.** El `IDENT_CURRENT` de SQL Server es 6, no 3: los dos inserts que fallaron por la restricción única, y la nota del procedimiento borrada después, usaron los valores 4 a 6 ([salida del origen, líneas 62-67](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/mssql-13-source.txt#L62-L67)). El programa reinicia `note_id` en 7.

Qué pasa si nadie reinicia la identidad ([`sql/13-migration.sql`, líneas 14-21](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L14-L21)):

```sql
-- La columna de identidad sigue empezando en 1: las filas copiadas no la hicieron avanzar. RESTART WITH continúa tras
-- el IDENT_CURRENT de SQL Server, 6
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

## Validar la copia

Un recuento por tabla no es una validación. El programa lee cada fila de ambos servidores, en orden de clave, como texto en una forma en la que ambos coinciden, y después compara las filas y un SHA-256 de todas ellas ([`L13.cs`, líneas 165-211](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/csharp-mssql/L13.cs#L165-L211)):

```csharp
    // Un valor como texto: instantes en UTC con siete decimales, la precisión de datetime2 y datetimeoffset
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

Cuatro tablas son idénticas. En `notes`, dos valores `datetimeoffset(7)` perdieron su séptimo decimal: `.1234567` pasó a `.123456` y `.9999999` a `.999999`. Npgsql truncó los ticks de 100 nanosegundos a los microsegundos de PostgreSQL, que es lo que `timestamptz` puede contener. La solución es una decisión, no código: aceptar los microsegundos, o guardar los ticks en un `bigint` junto a la marca de tiempo.

## Código en la base de datos

El origen también tiene una vista y un procedimiento ([líneas 175-190](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-source.sql#L175-L190)):

```sql
-- Código que vive en la base de datos: una vista y un procedimiento, que también hay que convertir
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

El procedimiento como función PL/pgSQL (lección 8), con [`RAISE`](https://www.postgresql.org/docs/18/plpgsql-errors-and-messages.html) en lugar de `THROW` y `RETURNING … INTO` en lugar de `SCOPE_IDENTITY()` ([`sql/13-migration.sql`, líneas 73-90](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-migration.sql#L73-L90)):

```sql
-- dbo.AddNote como función: RAISE en lugar de THROW, RETURNING en lugar de SCOPE_IDENTITY()
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

`NEWID()` pasa a ser `gen_random_uuid()`, `GETUTCDATE()` pasa a ser `now() AT TIME ZONE 'UTC'`, y el parámetro `OUTPUT` pasa a ser el valor de retorno. La vista es el ejercicio 1.

## pgloader

[pgloader](https://pgloader.readthedocs.io/en/latest/ref/mssql.html) crea el esquema y copia los datos en un solo comando. `check.sh` ejecuta la imagen `ghcr.io/dimitri/pgloader` construida desde el commit [`231ab86`](https://github.com/dimitri/pgloader/tree/231ab86778ca5ffd7de40878714760c8b4860cdf) (versión `3.6.10~devel`), con sus reglas de conversión por defecto, en una base de datos propia:

```bash
docker run --rm --add-host=host.docker.internal:host-gateway ghcr.io/dimitri/pgloader@sha256:a1d4a78e78a64e46cd3fc7dfc57d24eb91ffb1a5520f2b1f55631815e3658d6e pgloader \
  'mssql://sa:Learn-2026!@host.docker.internal:1433/ci' \
  'postgresql://postgres:learn@host.docker.internal:5432/pgloader'
```

Informó de 2962 filas y ningún error, en menos de un segundo. Lo que creó ([`sql/pgloader-check.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/pgloader-check.sql), [`expected/13-pgloader.txt`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/13-pgloader.txt)):

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

- **`money` perdió dos decimales.** `0.0125` pasó a `0.01`. pgloader lee las columnas `decimal`, `numeric`, `money` y `smallmoney` como `convert(varchar(40), [col], 0)` ([`mssql-schema.lisp`, líneas 212-217](https://github.com/dimitri/pgloader/blob/231ab86778ca5ffd7de40878714760c8b4860cdf/src/sources/mssql/mssql-schema.lisp#L212-L217)), y para `money`, el estilo 0 significa «two digits to the right of the decimal point» ([`CAST` y `CONVERT`](https://learn.microsoft.com/sql/t-sql/functions/cast-and-convert-transact-sql#money-and-smallmoney-styles)). `SELECT CONVERT(varchar(40), CAST(0.0125 AS money), 0)` devuelve `0.01` en este SQL Server; el estilo 2 conserva cuatro dígitos. Ni error ni aviso: solo una validación lo detecta.
- **`datetimeoffset` se redondeó, no se truncó.** `.1234567` pasó a `.123457`, y `10:06:00.9999999 -04:00` pasó a `14:06:01`, el segundo siguiente. El programa C# truncó. Las dos copias no coinciden entre sí, ni ninguna de ellas con SQL Server.
- **Nombres y tipos.** `RunId` pasó a `runid`, cada cadena a `text` sin su longitud, `datetime` a `timestamptz`, `rowversion` a `bytea`, y la columna calculada a un simple `boolean` con los valores copiados.
- **Restricciones.** Las claves primarias, las claves foráneas y `NOT NULL` llegaron; el `CHECK (Attempt >= 1)` no, y no hay ninguna `c` entre los tipos de restricción. Las restricciones únicas pasaron a ser índices únicos, sin `NULLS NOT DISTINCT` ni collation que ignore las mayúsculas. `IX_Jobs_RunId … INCLUDE (Conclusion)` pasó a ser un índice sobre `(runid, conclusion)`, con la columna incluida como clave.
- **La secuencia** quedó en 3, la clave más grande, no en el 6 de SQL Server: aquí no hay conflicto, pero tampoco se respeta la numeración del origen.

pgloader es rápido para echar un primer vistazo a una base de datos. Sus reglas de conversión se pueden cambiar en un archivo de carga, y su resultado sigue necesitando la revisión y la validación de las secciones anteriores.

## AWS DMS

*Por verificar: nada de esta sección se ejecutó en AWS.* [AWS Database Migration Service](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html) copia datos entre bases de datos, desde una instancia de replicación o con DMS Serverless, como carga completa, como replicación continua, o ambas.

- **Orígenes.** «Microsoft SQL Server versions 2008 (supported in DMS v3.5.4), 2008R2(supported in DMS v3.5.4), 2012, 2014, 2016, 2017, 2019, and 2022» ([orígenes](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Sources.html)). SQL Server 2025, la versión de esta lección, no figura. La replicación continua necesita la edición Enterprise, Developer o Standard (2016 y posteriores).
- **Destinos.** «AWS DMS only supports PostgreSQL version 17.x and 18.x in versions 3.5.4» ([destinos](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Targets.html)).
- **Replicación continua desde SQL Server.** «The recovery model must be set to Bulk logged or Full», y «you must perform a backup before beginning to replicate data» ([origen SQL Server](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html#CHAP_Source.SQLServer.Prerequisites)). En un servidor autogestionado, DMS lee MS-Replication para las tablas con clave primaria y MS-CDC para las demás; «Amazon RDS for SQL Server doesn't support MS-Replication», así que allí usa MS-CDC para todas las tablas ([CDC](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.CDC.html#CHAP_Source.SQLServer.CDC.Selfmanaged)).
- **Lo que no traslada.** «The identity property for a column isn't migrated to a target database column», «Changes to computed fields in a SQL Server aren't replicated», «AWS DMS doesn't capture truncate commands» ([limitaciones](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html#CHAP_Source.SQLServer.Limitations)). DMS «doesn't automatically create secondary indexes, foreign keys, user accounts, and so on» ([prácticas recomendadas](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html#CHAP_SettingUp.MigrationPlanning)), y a las secuencias hay que fijarles el siguiente valor «after you stop the replication from the source database» ([destino PostgreSQL](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html#CHAP_Target.PostgreSQL.Limitations)): el reinicio de identidad de esta lección.
- **Crea tú mismo las tablas de destino.** Cuando las crea DMS, las tablas de tipos del [origen](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html#CHAP_Source.SQLServer.DataTypes) y del [destino](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html#CHAP_Target.PostgreSQL.DataTypes), combinadas, dan a `datetime2` con escala 7 una columna `VARCHAR (37)`, y a `datetimeoffset` y `uniqueidentifier` un `VARCHAR`. Esa combinación de las dos tablas es mi lectura, no una afirmación de AWS.
- **Valores grandes.** El modo LOB limitado, el predeterminado, «migrates all LOB values up to a user-specified size limit (default is 32 KB)» ([LOB](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html#CHAP_BestPractices.LOBS.LimitedLOBMode)): un `nvarchar(max)` más largo necesita el modo LOB completo o en línea.
- **Validación.** «AWS DMS compares each row in the source with its corresponding row at the target … and reports any mismatches», y «requires that the table has a primary key or unique index» ([validación de datos](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Validating.html)). Si informaría de los ticks perdidos de `datetimeoffset(7)` está *por verificar*.
- **Esquema.** [DMS Schema Conversion](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_SchemaConversion.html#how-schema-conversion-works) «builds on the AWS Schema Conversion Tool (AWS SCT) conversion engine» y, de SQL Server a Aurora PostgreSQL, «can use generative AI to convert more»; AWS añade que «may not achieve 100 percent accuracy … You must review and validate all conversion outputs» ([limitaciones](https://docs.aws.amazon.com/dms/latest/userguide/schema-conversion-convert.databaseobjects.html#schema-conversion-convert.databaseobjects.limitations)). La herramienta de escritorio [AWS SCT](https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html) sigue publicándose (build 677).
- **DMS Serverless.** «The current engine version for AWS DMS Serverless is 3.5.4» ([Serverless](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.html)); «does not support views» ([limitaciones](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.Limitations.html)).

El [tutorial paso a paso](https://docs.aws.amazon.com/dms/latest/sbs/schema-conversion-sql-server-aurora-postgresql.html) de AWS recorre una conversión de SQL Server a Aurora PostgreSQL en la consola; el [manual de migración](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.html) compara funcionalidades, para SQL Server 2019.

## Babelfish

*Por verificar.* Babelfish toma el otro camino: la aplicación conserva su T-SQL y su driver de SQL Server, y Aurora PostgreSQL le responde. «SQL Server dialect (T-SQL), clients connect to port 1433. PostgreSQL dialect (PL/pgSQL), clients connect to port 5432» ([Babelfish](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish.html)).

- **Versiones.** Babelfish 6.1.0 «is provided with Aurora PostgreSQL 18.4», publicada el 21 de agosto de 2026 ([actualizaciones de Babelfish](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraBabelfish.Updates.html#AuroraBabelfish.Updates.610)).
- **Bases de datos.** Aurora crea una base de datos PostgreSQL llamada `babelfish_db`. En el modo de varias bases de datos, «the schema names of user databases become dbname_schemaname when accessed from PostgreSQL» ([arquitectura](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-architecture.html#babelfish-single_vs_multi_db)). El modo se elige una sola vez: «You must not change this parameter after creating your cluster as you could lose access to all your previously created SQL objects»; la [tabla de parámetros](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-configuration.html#babelfish_params) dice «you can't modify this parameter's value», con multi-db por defecto desde Aurora PostgreSQL 16.
- **Collations: dos valores por defecto.** La tabla de parámetros da a `babelfishpg_tsql.server_collation_name` el valor por defecto `bbf_unicode_general_ci_as`; la [página de collations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-collations.html#babelfish-collations.parameters) dice «The default value is sql_latin1_general_cp1_ci_as». La tabla comparativa de la misma página dice que PostgreSQL «Doesn't support the LIKE clause on nondeterministic collations», algo que PostgreSQL 18 cambió.
- **Las funcionalidades no admitidas** responden con un error o se ignoran, según los [escape hatches](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-strict.html#babelfish-escape_hatches); la [lista de funcionalidades no admitidas](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-compatibility.tsql.limitations-unsupported.html#babelfish-compatibility.tsql.limitations-unsupported-table) incluye las rutinas CLR y los cursores actualizables. [Babelfish Compass](https://github.com/babelfish-for-postgresql/babelfish_compass) lee el DDL de una base de datos e informa de lo que Babelfish admite; su última versión es [v.2026-07](https://github.com/babelfish-for-postgresql/babelfish_compass/releases/tag/v.2026-07).
- **No en local.** El [Babelfish for PostgreSQL](https://babelfishpg.org/) de código abierto necesita un PostgreSQL modificado compilado desde el código fuente; su última versión es [5.4.0 para PostgreSQL 17.7](https://github.com/babelfish-for-postgresql/babelfish-for-postgresql/releases/tag/BABEL_5_4_0__PG_17_7), y el proyecto no publica ninguna imagen de contenedor. El curso no lo compila.

Babelfish traslada la base de datos sin reescribir la aplicación, y la aplicación conserva los comportamientos de SQL Server de las secciones anteriores, siempre que Babelfish los emule: cada uno está *por verificar* frente a las propias listas de Babelfish.

## Costes

*Por verificar: los precios cambian, y el curso no compró nada.* Las cifras son los precios bajo demanda de AWS en US East (N. Virginia), de los archivos de la [AWS Price List](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json) publicados el 2026-09-11, que también muestra la [página de precios de Aurora](https://aws.amazon.com/rds/aurora/pricing/).

| Aurora PostgreSQL | Aurora Standard | Aurora I/O-Optimized |
|---|---|---|
| db.r8g.large o db.r7g.large (2 vCPU, 16 GiB), por hora | 0,276 USD | 0,359 USD |
| almacenamiento, por GB-mes | 0,10 USD | 0,225 USD |
| E/S, por millón de solicitudes | 0,20 USD | incluida |
| Aurora Serverless, por ACU-hora | 0,12 USD | 0,16 USD |
| almacenamiento de copias de seguridad más allá del tamaño del clúster, por GB-mes | 0,021 USD | 0,021 USD |

Para comparar, de los mismos archivos:

- **RDS for SQL Server Standard Edition**, con licencia incluida, en una db.r6i.large Single-AZ: 1,02 USD por hora, unos 745 USD al mes por una instancia.
- **La licencia en sí**: la [hoja de precios de SQL Server 2025](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/cloud/SQL-Server-2025-Pricing.pdf) de Microsoft indica 3945 USD para Standard y 15 123 USD para Enterprise por paquete de 2 núcleos.
- **La migración**: una instancia de replicación dms.r6i.large cuesta 0,176 USD por hora; DMS Serverless, 0,0819 USD por DCU-hora, donde «One DCU equals 2GB of RAM» ([precios de DMS](https://aws.amazon.com/dms/pricing/)). Babelfish «doesn't have an additional cost» ([DMS y Babelfish](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html#CHAP_Target.PostgreSQL.Babelfish)).

La guía prescriptiva de AWS afirma que pasar de SQL Server Enterprise en EC2 a Aurora «can result in cost savings up to 70 percent» ([optimización de costes](https://docs.aws.amazon.com/prescriptive-guidance/latest/optimize-costs-microsoft-workloads/modernize-sql-server.html#modernize-sql-server-database)): una afirmación que conviene comprobar con tus propios tamaños de instancia, tu E/S y tus condiciones de licencia, en la [AWS Pricing Calculator](https://calculator.aws/). El ejercicio 3 hace las cuentas para un clúster.

## Puntos clave

- Ejecuta ambos servidores y hazles las mismas preguntas antes de trasladar los datos: collation, espacios finales, orden de `NULL`, orden de los GUID, `NULL` en las restricciones únicas, precisión de las fechas, errores en las transacciones.
- Una collation ICU no determinista da las comparaciones sin distinción de mayúsculas de SQL Server, incluido `LIKE` desde PostgreSQL 18; los espacios finales siguen siendo significativos.
- `datetime2(7)` y `datetimeoffset` pierden su séptimo decimal, y `datetimeoffset` su desfase; `datetime` ya estaba redondeado en SQL Server.
- Crea tú mismo el esquema de destino, carga, y después añade las claves foráneas y los índices, reinicia las identidades desde el `IDENT_CURRENT` de SQL Server, y ejecuta `ANALYZE`.
- Valida filas, no recuentos: el programa encontró los ticks perdidos, y una validación habría encontrado los valores `money` de pgloader cortados a dos decimales.
- PostgreSQL aborta la transacción entera tras un error; SQL Server, por defecto, no.
- DMS copia y replica datos, pero no identidades, índices secundarios ni código; Babelfish conserva el T-SQL, y su comportamiento hay que comprobarlo frente a sus listas de compatibilidad.
- El precio de Aurora tiene tres partes: instancias, almacenamiento y E/S; por encima de cierto volumen de E/S, I/O-Optimized cuesta menos.

## Ejercicios

1. Convierte `dbo.SlowJobs` en una vista PostgreSQL sobre `ci.jobs` y `ci.runs` de la lección 2, y comprueba que devuelve las mismas cinco filas que SQL Server.

<details>
<summary>Solución</summary>

[`sql/13-exercises.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-exercises.sql#L7-L16):

```sql
-- Ejercicio 1: dbo.SlowJobs como vista PostgreSQL. DATEDIFF(second, ...) cuenta los límites de segundo cruzados;
-- la diferencia de dos timestamptz truncados al segundo cuenta lo mismo.
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

Las mismas filas que [las de SQL Server](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/expected/mssql-13-source.txt#L55-L61). [`DATEDIFF`](https://learn.microsoft.com/sql/t-sql/functions/datediff-transact-sql) cuenta los límites cruzados, así que de `10:00:00.9` a `10:00:01.1` hay un segundo; `date_trunc('second', …)` en ambos extremos cuenta de la misma forma, donde `extract(epoch FROM completed_at - started_at)` daría 0,2. `TOP (5) WITH TIES` pasa a ser `FETCH FIRST 5 ROWS WITH TIES`, y aquí se conserva el `ORDER BY` de la vista, pero la consulta que lee la vista sigue ordenando su propio resultado.

</details>

2. Antes de convertir una base de datos SQL Server más grande, enumera las columnas cuyos tipos requieren una decisión, a partir del catálogo de SQL Server, y los autores que solo difieren en mayúsculas o en espacios finales.

<details>
<summary>Solución</summary>

[`mssql/13-exercises.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/mssql/13-exercises.sql):

```sql
-- Lección 13, ejercicio 2: las columnas cuyo tipo requiere una decisión antes de la conversión, según el catálogo de SQL Server
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

-- Collations distintas de la de la base de datos, y las cadenas que solo difieren en mayúsculas o espacios finales
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

`rowversion` aparece como `timestamp`, su antiguo nombre, y la escala de `datetime` aparece como 3 aunque sus valores se redondean a 1/300 de segundo. Aquí ninguna columna tiene su propia collation. Una collation binaria, `Latin1_General_BIN2`, hace que el propio SQL Server muestre las tres grafías que su collation por defecto trata como una sola.

</details>

3. Para un writer y una Aurora Replica en db.r8g.large, en funcionamiento todo el mes (730 horas), con 100 GiB de datos y 300 millones de solicitudes de E/S al mes, compara Aurora Standard con Aurora I/O-Optimized. ¿A partir de cuántas solicitudes de E/S al mes cuesta menos I/O-Optimized?

<details>
<summary>Solución</summary>

[`sql/13-exercises.sql`](https://github.com/spareilleux/learn/blob/9f571e529b4e930ab9284d49171b984a2fd1272b/code/postgresql-aurora/sql/13-exercises.sql#L18-L33):

```sql
-- Ejercicio 3: un mes de 730 horas para un writer y una Aurora Replica, ambos db.r8g.large, con 100 GiB de datos y
-- 300 millones de solicitudes de E/S, a los precios bajo demanda de us-east-1 de la AWS Price List publicada el 2026-09-11
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

-- El número de millones de solicitudes de E/S al mes a partir del cual I/O-Optimized cuesta menos, con las mismas instancias y datos
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

Unos 473 USD frente a 547 USD: con 300 millones de solicitudes de E/S, Standard es más barato. Sin E/S, I/O-Optimized cuesta 133,68 USD más al mes en instancias y almacenamiento; a 0,20 USD por millón de solicitudes, la E/S de Standard alcanza esa cantidad hacia los 668 millones de solicitudes al mes. La regla práctica de AWS es considerar I/O-Optimized cuando la E/S supera el 25 % de la factura de Aurora ([precios de Aurora](https://aws.amazon.com/rds/aurora/pricing/)). Quedan fuera las copias de seguridad, la transferencia de datos y las instantáneas.

</details>

## Fuentes

- SQL Server, en Microsoft Learn: [novedades de SQL Server 2025](https://learn.microsoft.com/sql/sql-server/what-s-new-in-sql-server-2025), [inicio rápido de Docker](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker), [`sqlcmd`](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility), [collations](https://learn.microsoft.com/sql/relational-databases/collations/collation-and-unicode-support), [`datetime`](https://learn.microsoft.com/sql/t-sql/data-types/datetime-transact-sql), [`uniqueidentifier`](https://learn.microsoft.com/sql/t-sql/data-types/uniqueidentifier-transact-sql), [comparar GUID](https://learn.microsoft.com/sql/connect/ado-net/sql/compare-guid-uniqueidentifier-values), [comparación de cadenas](https://learn.microsoft.com/sql/t-sql/language-elements/string-comparison-assignment), [`ORDER BY`](https://learn.microsoft.com/sql/t-sql/queries/select-order-by-clause-transact-sql), [`SET XACT_ABORT`](https://learn.microsoft.com/sql/t-sql/statements/set-xact-abort-transact-sql), [`CAST` y `CONVERT`](https://learn.microsoft.com/sql/t-sql/functions/cast-and-convert-transact-sql), [`DATEDIFF`](https://learn.microsoft.com/sql/t-sql/functions/datediff-transact-sql), [`OPENROWSET(BULK)`](https://learn.microsoft.com/sql/t-sql/functions/openrowset-bulk-transact-sql), [`OPENJSON`](https://learn.microsoft.com/sql/t-sql/functions/openjson-transact-sql), [Microsoft.Data.SqlClient](https://learn.microsoft.com/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace), [Data Migration Assistant](https://learn.microsoft.com/sql/dma/dma-overview); [hoja de precios de SQL Server 2025](https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/bade/documents/products-and-services/en-us/cloud/SQL-Server-2025-Pricing.pdf)
- PostgreSQL 18: [collations](https://www.postgresql.org/docs/18/collation.html), [notas de versión](https://www.postgresql.org/docs/18/release-18.html), [coincidencia de patrones](https://www.postgresql.org/docs/18/functions-matching.html), [`citext`](https://www.postgresql.org/docs/18/citext.html), [`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html), [columnas generadas](https://www.postgresql.org/docs/18/ddl-generated-columns.html), [tipos de fecha/hora](https://www.postgresql.org/docs/18/datatype-datetime.html), [`SAVEPOINT`](https://www.postgresql.org/docs/18/sql-savepoint.html), [errores y mensajes de PL/pgSQL](https://www.postgresql.org/docs/18/plpgsql-errors-and-messages.html), [tipos monetarios](https://www.postgresql.org/docs/18/datatype-money.html), [códigos de error](https://www.postgresql.org/docs/18/errcodes-appendix.html)
- Npgsql: [tipos de fecha y hora](https://www.npgsql.org/doc/types/datetime.html), [tokens de concurrencia de EF Core](https://www.npgsql.org/efcore/modeling/concurrency.html)
- pgloader: [origen MS SQL](https://pgloader.readthedocs.io/en/latest/ref/mssql.html), [`mssql-schema.lisp` en `231ab86`](https://github.com/dimitri/pgloader/blob/231ab86778ca5ffd7de40878714760c8b4860cdf/src/sources/mssql/mssql-schema.lisp)
- AWS DMS, consultado el 2026-09-16: [qué es DMS](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html), [orígenes](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Sources.html), [destinos](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Targets.html), [origen SQL Server](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html), [su CDC](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.CDC.html), [destino PostgreSQL](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.PostgreSQL.html), [prácticas recomendadas](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html), [validación de datos](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Validating.html), [Schema Conversion](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_SchemaConversion.html), [sus limitaciones](https://docs.aws.amazon.com/dms/latest/userguide/schema-conversion-convert.databaseobjects.html), [AWS SCT](https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html), [DMS Serverless](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.html) y [sus limitaciones](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.Limitations.html), [tutorial paso a paso](https://docs.aws.amazon.com/dms/latest/sbs/schema-conversion-sql-server-aurora-postgresql.html), [manual de migración](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.html)
- Babelfish, consultado el 2026-09-16: [descripción general](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish.html), [arquitectura](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-architecture.html), [parámetros](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-configuration.html), [collations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-collations.html), [escape hatches](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-strict.html), [funcionalidades no admitidas](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/babelfish-compatibility.tsql.limitations-unsupported.html), [notas de versión](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraBabelfish.Updates.html), [Babelfish Compass](https://github.com/babelfish-for-postgresql/babelfish_compass), [Babelfish for PostgreSQL](https://babelfishpg.org/)
- Precios, consultados el 2026-09-16: [índice de la AWS Price List](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json), [precios de Aurora](https://aws.amazon.com/rds/aurora/pricing/), [precios de DMS](https://aws.amazon.com/dms/pricing/), [precios de RDS for SQL Server](https://aws.amazon.com/rds/sqlserver/pricing/), [AWS Pricing Calculator](https://calculator.aws/), [guía prescriptiva sobre los costes de SQL Server](https://docs.aws.amazon.com/prescriptive-guidance/latest/optimize-costs-microsoft-workloads/modernize-sql-server.html)
