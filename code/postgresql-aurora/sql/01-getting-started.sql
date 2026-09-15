-- Lesson 1: a database, a schema, the case of identifiers, the course data, identity columns and roles.
-- check.sh runs this script connected to the postgres database, after dropping learn and the course roles.
SELECT current_database(), current_user, current_setting('server_version') AS version;
CREATE DATABASE learn;
\c learn
\dn

-- Schemas and search_path
CREATE SCHEMA ci;
SHOW search_path;

-- Unquoted identifiers are folded to lower case; quoted ones keep their case
CREATE TABLE ci.Runs (
    databaseId     bigint PRIMARY KEY,
    "workflowName" text NOT NULL
);
\d ci.runs
SELECT workflowName FROM ci.runs;
SELECT count(*) FROM runs;
SET search_path = ci, public;
SELECT count(*) FROM runs;
DROP TABLE runs;

-- No TOP: LIMIT, or the standard FETCH FIRST
SELECT TOP 3 relname FROM pg_class;

-- The course data: a JSON array read by the server, one row per element
SELECT jsonb_array_length(pg_read_file('/course/data/runs.json')::jsonb) AS runs;

CREATE TABLE runs (
    run_id        bigint PRIMARY KEY,
    workflow_name text NOT NULL,
    event         text NOT NULL,
    conclusion    text,
    head_branch   text NOT NULL,
    head_sha      text NOT NULL,
    attempt       integer NOT NULL,
    created_at    timestamptz NOT NULL,
    started_at    timestamptz NOT NULL,
    updated_at    timestamptz NOT NULL
);

INSERT INTO runs
SELECT r."databaseId", r."workflowName", r.event, r.conclusion, r."headBranch", r."headSha",
       r.attempt, r."createdAt", r."startedAt", r."updatedAt"
FROM jsonb_to_recordset(pg_read_file('/course/data/runs.json')::jsonb) AS r(
    "databaseId" bigint, "workflowName" text, event text, conclusion text, "headBranch" text,
    "headSha" text, attempt integer, "createdAt" timestamptz, "startedAt" timestamptz, "updatedAt" timestamptz);

SELECT workflow_name, count(*) AS runs, count(*) FILTER (WHERE conclusion = 'failure') AS failures
FROM runs
GROUP BY workflow_name
ORDER BY runs DESC, workflow_name
FETCH FIRST 5 ROWS ONLY;

-- The unquoted column definition list: every key is looked up in lower case
SELECT r.databaseId, r.workflowName
FROM jsonb_to_recordset(pg_read_file('/course/data/runs.json')::jsonb) AS r(databaseId bigint, workflowName text)
ORDER BY r.workflowName
LIMIT 2;

-- Identity columns and sequences
CREATE TABLE notes (
    note_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_id  bigint NOT NULL REFERENCES runs,
    body    text NOT NULL
);
INSERT INTO notes (run_id, body) VALUES (34852867099, 'first deployment of the day') RETURNING note_id;
INSERT INTO notes (note_id, run_id, body) VALUES (10, 34852867099, 'explicit id');
BEGIN;
INSERT INTO notes (run_id, body) VALUES (34852867099, 'rolled back') RETURNING note_id;
ROLLBACK;
INSERT INTO notes (run_id, body) VALUES (34852867099, 'after the rollback') RETURNING note_id;
SELECT note_id, body FROM notes ORDER BY note_id;
\d notes
SELECT pg_get_serial_sequence('ci.notes', 'note_id') AS sequence;

-- Roles: a login is a role with LOGIN
CREATE ROLE app LOGIN PASSWORD 'app-password';
SET ROLE app;
SELECT count(*) FROM ci.runs;
CREATE TABLE public.scratch (a integer);
SELECT pg_read_file('/course/data/runs.json');
RESET ROLE;
GRANT USAGE ON SCHEMA ci TO app;
GRANT SELECT ON ALL TABLES IN SCHEMA ci TO app;
SET ROLE app;
SELECT count(*) FROM ci.runs;
INSERT INTO ci.notes (run_id, body) VALUES (34852867099, 'from app');
RESET ROLE;
\du
SELECT * FROM postgres.public.pg_class;
