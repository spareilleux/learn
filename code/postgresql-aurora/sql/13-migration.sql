-- Lesson 13: the converted tables, and what behaves differently from SQL Server once the data is in PostgreSQL. The
-- notes are inserted as the C# program copies them.
SET client_min_messages = warning;
\ir mssql-target.sql
RESET client_min_messages;
INSERT INTO migrated.notes (note_id, note_guid, run_id, author, tag, body, cost, written_at, written_local) VALUES
    (1, '6f9619ff-8b86-d011-b42d-00c04fc964ff', NULL, 'Reviewer', 'Slow', 'Deploy took 2.5 minutes', 0.0125,
     '2026-09-14 14:05:00.000', '2026-09-14 16:05:00.123456+02:00'),
    (2, '00000000-0000-0000-0000-000000000001', NULL, 'reviewer ', NULL, 'Looks fine now', NULL,
     '2026-09-14 14:06:00.007', '2026-09-14 10:06:00.999999-04:00'),
    (3, '01000000-0000-0000-0000-000000000000', NULL, 'REVIEWER', 'flaky', 'Café au lait', 3.5,
     '2026-09-14 14:07:00.997', '2026-09-14 14:07:00+00:00');

-- The identity column still starts at 1: the copied rows didn't advance it. RESTART WITH continues after
-- SQL Server's IDENT_CURRENT, 6
INSERT INTO migrated.notes (note_guid, author, body, written_at, written_local)
VALUES (gen_random_uuid(), 'Reviewer', 'first note after the migration', '2026-09-16', '2026-09-16 00:00+00');
ALTER TABLE migrated.notes ALTER COLUMN note_id RESTART WITH 7;
INSERT INTO migrated.notes (note_guid, author, tag, body, written_at, written_local)
VALUES ('70000000-0000-0000-0000-000000000000', 'Reviewer', 'migrated', 'first note after the migration', '2026-09-16', '2026-09-16 00:00+00')
RETURNING note_id;

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
