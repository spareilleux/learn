-- Lesson 1, exercise solutions. The model of lesson 2 is loaded first, without output.
\o /dev/null
\ir schema.sql
\o
SET search_path = ci, public;

-- Exercise 1: the three workflows with the most failures, ties included (TOP (3) WITH TIES)
SELECT * FROM (
    SELECT workflow_name, count(*) AS failures
    FROM runs
    WHERE conclusion = 'failure'
    GROUP BY workflow_name
    ORDER BY failures DESC
    FETCH FIRST 3 ROWS WITH TIES
) AS top_failures
ORDER BY failures DESC, workflow_name;

-- Exercise 2: a role that reads ci, including the tables created later
CREATE ROLE reader LOGIN PASSWORD 'reader-password';
GRANT USAGE ON SCHEMA ci TO reader;
GRANT SELECT ON ALL TABLES IN SCHEMA ci TO reader;
CREATE TABLE ci.flaky_steps (step_name text PRIMARY KEY);
SET ROLE reader;
SELECT count(*) FROM ci.flaky_steps;
RESET ROLE;
ALTER DEFAULT PRIVILEGES IN SCHEMA ci GRANT SELECT ON TABLES TO reader;
CREATE TABLE ci.slow_steps (step_name text PRIMARY KEY);
SET ROLE reader;
SELECT count(*) FROM ci.slow_steps;
RESET ROLE;

-- Exercise 3: an explicit value in an identity column, then the next generated one
CREATE TABLE notes (
    note_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    body    text NOT NULL
);
INSERT INTO notes (body) VALUES ('one'), ('two');
INSERT INTO notes (note_id, body) OVERRIDING SYSTEM VALUE VALUES (3, 'imported');
INSERT INTO notes (body) VALUES ('three');
SELECT setval(pg_get_serial_sequence('ci.notes', 'note_id'), (SELECT max(note_id) FROM notes));
INSERT INTO notes (body) VALUES ('three') RETURNING note_id;
