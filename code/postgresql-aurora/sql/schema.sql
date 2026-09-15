-- The course model, built in lesson 2 and loaded by every later script:
-- schema ci, the GitHub Actions history of this site (code/duckdb/data, exported on 2026-09-14);
-- schema ga, the .NET projects of GuitarAlchemist/ga at commit a26a7893 (code/ladybugdb/data/ga).
CREATE SCHEMA ci;
CREATE SCHEMA ga;

CREATE DOMAIN ci.conclusion AS text
    CHECK (VALUE IN ('success', 'failure', 'cancelled', 'skipped', 'startup_failure'));

CREATE TABLE ci.runs (
    run_id        bigint PRIMARY KEY,
    workflow_name text NOT NULL,
    event         text NOT NULL,
    conclusion    ci.conclusion,
    head_branch   text NOT NULL,
    head_sha      text NOT NULL CHECK (head_sha ~ '^[0-9a-f]{40}$'),
    attempt       smallint NOT NULL CHECK (attempt >= 1),
    created_at    timestamptz NOT NULL,
    started_at    timestamptz NOT NULL,
    updated_at    timestamptz NOT NULL,
    CHECK (updated_at >= started_at)
);

CREATE TABLE ci.jobs (
    job_id       bigint PRIMARY KEY,
    run_id       bigint NOT NULL REFERENCES ci.runs,
    name         text NOT NULL,
    conclusion   ci.conclusion,
    labels       text[] NOT NULL,
    runner_name  text,
    started_at   timestamptz NOT NULL,
    completed_at timestamptz NOT NULL,
    duration     interval GENERATED ALWAYS AS (completed_at - started_at)
);

-- btree_gist lets a GiST index compare bigint with =, next to the && of ranges
CREATE EXTENSION btree_gist;

CREATE TABLE ci.steps (
    job_id       bigint NOT NULL REFERENCES ci.jobs,
    number       smallint NOT NULL,
    name         text NOT NULL,
    conclusion   ci.conclusion,
    started_at   timestamptz NOT NULL,
    completed_at timestamptz NOT NULL CHECK (completed_at >= started_at),
    ran          tstzrange GENERATED ALWAYS AS (tstzrange(started_at, completed_at, '[)')) STORED,
    PRIMARY KEY (job_id, number),
    -- the steps of one job never run at the same time
    EXCLUDE USING gist (job_id WITH =, ran WITH &&)
);

INSERT INTO ci.runs
SELECT r."databaseId", r."workflowName", r.event, r.conclusion, r."headBranch", r."headSha",
       r.attempt, r."createdAt", r."startedAt", r."updatedAt"
FROM jsonb_to_recordset(pg_read_file('/course/data/runs.json')::jsonb) AS r(
    "databaseId" bigint, "workflowName" text, event text, conclusion text, "headBranch" text,
    "headSha" text, attempt smallint, "createdAt" timestamptz, "startedAt" timestamptz, "updatedAt" timestamptz);

-- One JSON value per job; the steps stay in the document until the next INSERT flattens them
CREATE TEMPORARY TABLE jobs_json AS
SELECT j AS doc FROM jsonb_array_elements(pg_read_file('/course/data/jobs.json')::jsonb) AS j;

INSERT INTO ci.jobs (job_id, run_id, name, conclusion, labels, runner_name, started_at, completed_at)
SELECT (doc->>'id')::bigint, (doc->>'run_id')::bigint, doc->>'name', doc->>'conclusion',
       ARRAY(SELECT jsonb_array_elements_text(doc->'labels')), doc->>'runner_name',
       (doc->>'started_at')::timestamptz, (doc->>'completed_at')::timestamptz
FROM jobs_json;

INSERT INTO ci.steps (job_id, number, name, conclusion, started_at, completed_at)
SELECT (doc->>'id')::bigint, s.number, s.name, s.conclusion, s.started_at, s.completed_at
FROM jobs_json,
     jsonb_to_recordset(doc->'steps') AS s(number smallint, name text, conclusion text,
                                           started_at timestamptz, completed_at timestamptz);

CREATE TABLE ga.projects (
    path        text PRIMARY KEY,
    name        text NOT NULL,
    language    text NOT NULL CHECK (language IN ('C#', 'F#')),
    sdk         text NOT NULL,
    frameworks  text[] NOT NULL,
    in_solution boolean NOT NULL
);

CREATE TABLE ga.project_refs (
    from_path text REFERENCES ga.projects,
    to_path   text REFERENCES ga.projects,
    PRIMARY KEY (from_path, to_path)
);

CREATE TABLE ga.package_refs (
    project text REFERENCES ga.projects,
    package text,
    version text NOT NULL,
    PRIMARY KEY (project, package)
);

-- GA's iconic chords (Common/GA.Business.Config/IconicChords.yaml at commit 32f143c, data/iconic_chords.json)
CREATE DOMAIN ga.pitch_class AS smallint CHECK (VALUE BETWEEN 0 AND 11);

CREATE TABLE ga.iconic_chords (
    chord_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             text NOT NULL UNIQUE,
    theoretical_name text NOT NULL,
    artist           text NOT NULL,
    song             text NOT NULL,
    era              text NOT NULL,
    genre            text NOT NULL,
    pitch_classes    ga.pitch_class[] NOT NULL,
    -- one fret per string, from low E to high E; -1 for a string not played
    guitar_voicing   smallint[] CHECK (cardinality(guitar_voicing) = 6),
    alternate_names  text[] NOT NULL
);

INSERT INTO ga.iconic_chords (name, theoretical_name, artist, song, era, genre, pitch_classes, guitar_voicing, alternate_names)
SELECT c."Name", c."TheoreticalName", c."Artist", c."Song", c."Era", c."Genre", c."PitchClasses", c."GuitarVoicing", c."AlternateNames"
FROM jsonb_to_recordset(pg_read_file('/course/data/ga/iconic_chords.json')::jsonb) AS c(
    "Name" text, "TheoreticalName" text, "Artist" text, "Song" text, "Era" text, "Genre" text,
    "PitchClasses" ga.pitch_class[], "GuitarVoicing" smallint[], "AlternateNames" text[]);

-- COPY reads the CSV files on the server, into staging tables whose columns match the headers
CREATE TEMPORARY TABLE projects_csv (path text, name text, language text, sdk text, frameworks text, in_solution boolean);
COPY projects_csv FROM '/course/data/ga/projects.csv' (FORMAT csv, HEADER match);
INSERT INTO ga.projects
SELECT path, name, language, sdk, string_to_array(frameworks, ';'), in_solution FROM projects_csv;

CREATE TEMPORARY TABLE project_refs_csv ("from" text, "to" text);
COPY project_refs_csv FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER match);
-- DISTINCT: one reference is listed twice in its .csproj; the join: one points to an .esproj, not a .NET project
INSERT INTO ga.project_refs
SELECT DISTINCT r."from", r."to"
FROM project_refs_csv AS r
JOIN ga.projects AS p ON p.path = r."to";

COPY ga.package_refs FROM '/course/data/ga/package_refs.csv' (FORMAT csv, HEADER match);

DROP TABLE jobs_json, projects_csv, project_refs_csv;
ANALYZE;
