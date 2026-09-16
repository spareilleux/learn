-- Lesson 13: the database to migrate, as a SQL Server team might have designed it. The same GitHub Actions runs and
-- jobs as the rest of the course, loaded from the same JSON files.
SET NOCOUNT ON;
USE master;
DROP DATABASE IF EXISTS ci;
CREATE DATABASE ci;
GO
USE ci;
SELECT DATABASEPROPERTYEX('ci', 'Collation') AS collation;
GO

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
GO

DECLARE @runs nvarchar(max) = (SELECT BulkColumn FROM OPENROWSET(BULK '/course/data/runs.json', SINGLE_CLOB) AS f);
INSERT INTO dbo.Runs (RunId, WorkflowName, Event, Conclusion, HeadBranch, HeadSha, Attempt, CreatedAt, StartedAt, UpdatedAt)
SELECT RunId, WorkflowName, Event, Conclusion, HeadBranch, HeadSha, Attempt, CreatedAt, StartedAt, UpdatedAt
FROM OPENJSON(@runs) WITH (
    RunId bigint '$.databaseId', WorkflowName nvarchar(100) '$.workflowName', Event varchar(30) '$.event',
    Conclusion varchar(20) '$.conclusion', HeadBranch nvarchar(255) '$.headBranch', HeadSha char(40) '$.headSha',
    Attempt tinyint '$.attempt', CreatedAt datetimeoffset '$.createdAt', StartedAt datetimeoffset '$.startedAt',
    UpdatedAt datetimeoffset '$.updatedAt');

DECLARE @jobs nvarchar(max) = (SELECT BulkColumn FROM OPENROWSET(BULK '/course/data/jobs.json', SINGLE_CLOB) AS f);
INSERT INTO dbo.Jobs (JobId, RunId, Name, Conclusion, RunnerName, StartedAt, CompletedAt)
SELECT JobId, RunId, Name, Conclusion, RunnerName, StartedAt, CompletedAt
FROM OPENJSON(@jobs) WITH (
    JobId bigint '$.id', RunId bigint '$.run_id', Name nvarchar(200) '$.name', Conclusion varchar(20) '$.conclusion',
    RunnerName nvarchar(100) '$.runner_name', StartedAt datetimeoffset '$.started_at',
    CompletedAt datetimeoffset '$.completed_at');

INSERT INTO dbo.JobLabels (JobId, Label)
SELECT j.JobId, l.value
FROM OPENJSON(@jobs) WITH (JobId bigint '$.id', Labels nvarchar(max) '$.labels' AS JSON) AS j
CROSS APPLY OPENJSON(j.Labels) AS l;

INSERT INTO dbo.Steps (JobId, Number, Name, Conclusion, StartedAt, CompletedAt)
SELECT j.JobId, s.Number, s.Name, s.Conclusion, s.StartedAt, s.CompletedAt
FROM OPENJSON(@jobs) WITH (JobId bigint '$.id', Steps nvarchar(max) '$.steps' AS JSON) AS j
CROSS APPLY OPENJSON(j.Steps) WITH (
    Number smallint '$.number', Name nvarchar(200) '$.name', Conclusion varchar(20) '$.conclusion',
    StartedAt datetimeoffset '$.started_at', CompletedAt datetimeoffset '$.completed_at') AS s;

INSERT INTO dbo.Notes (NoteGuid, RunId, Author, Tag, Body, Cost, WrittenAt, WrittenLocal) VALUES
    ('6F9619FF-8B86-D011-B42D-00C04FC964FF', 34852867099, N'Reviewer', 'Slow', N'Deploy took 2.5 minutes', 0.0125,
     '2026-09-14 14:05:00.001', '2026-09-14 16:05:00.1234567 +02:00'),
    ('00000000-0000-0000-0000-000000000001', 34852867099, N'reviewer ', NULL, N'Looks fine now', NULL,
     '2026-09-14 14:06:00.005', '2026-09-14 10:06:00.9999999 -04:00'),
    ('01000000-0000-0000-0000-000000000000', NULL, N'REVIEWER', 'flaky', N'Café au lait', 3.5,
     '2026-09-14 14:07:00.998', '2026-09-14 14:07:00 +00:00');
GO

-- What the application sees
SELECT 'Runs' AS [table], COUNT(*) AS [rows] FROM dbo.Runs
UNION ALL SELECT 'Jobs', COUNT(*) FROM dbo.Jobs
UNION ALL SELECT 'JobLabels', COUNT(*) FROM dbo.JobLabels
UNION ALL SELECT 'Steps', COUNT(*) FROM dbo.Steps
UNION ALL SELECT 'Notes', COUNT(*) FROM dbo.Notes;

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
GO

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
GO

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
GO
SELECT * FROM dbo.SlowJobs ORDER BY Seconds DESC, Name, WorkflowName;
DECLARE @id int;
EXEC dbo.AddNote @RunId = 34852867099, @Author = N'Reviewer', @Body = N'Added by the procedure', @Tag = 'manual', @NoteId = @id OUTPUT;
SELECT @id AS NoteId;
DELETE FROM dbo.Notes WHERE NoteId = @id;
GO
-- Failed inserts used identity values too: the next NoteId won't be 4
SELECT IDENT_CURRENT('dbo.Notes') AS ident_current, MAX(NoteId) AS max_note_id FROM dbo.Notes;
GO
