-- Lesson 2: native types, constraints, domains and generated columns, on the course model (sql/schema.sql).
\o /dev/null
\ir schema.sql
\o

-- Numbers
SELECT 0.1::float8 + 0.2::float8 AS float8, 0.1 + 0.2 AS numeric, 7 / 2 AS int_division, 7 / 2.0 AS numeric_division;
SELECT 2147483647 + 1;
SELECT 1234.5::numeric(5, 2);

-- Text
SELECT 'windows-latest'::varchar(7) AS cast_truncates;
CREATE TABLE ci.labels (label varchar(7));
INSERT INTO ci.labels VALUES ('windows-latest');
SELECT 'ab'::char(4) || '|' AS char_concat, length('é') AS characters, octet_length('é') AS bytes;

-- Timestamps: timestamptz stores an instant and displays it in the session's time zone
SELECT run_id, started_at FROM ci.runs ORDER BY started_at DESC, run_id LIMIT 1;
SET TimeZone = 'America/Toronto';
SELECT run_id, started_at FROM ci.runs ORDER BY started_at DESC, run_id LIMIT 1;
SELECT started_at AT TIME ZONE 'Asia/Tokyo' AS tokyo_wall_clock, pg_typeof(started_at AT TIME ZONE 'Asia/Tokyo')
FROM ci.runs ORDER BY started_at DESC, run_id LIMIT 1;
SELECT '2026-09-14 10:01:09+02'::timestamptz AS timestamptz, '2026-09-14 10:01:09+02'::timestamp AS timestamp;
RESET TimeZone;

-- Intervals and the virtual generated column of ci.jobs
SELECT labels[1] AS os, count(*) AS jobs, avg(duration) AS average, max(duration) AS longest
FROM ci.jobs
GROUP BY labels[1]
ORDER BY os;
UPDATE ci.jobs SET duration = interval '1 minute' WHERE job_id = 103842192310;

-- Booleans
SELECT 'yes'::boolean AS yes, 'off'::boolean AS off, 'maybe'::boolean;

-- uuid: version 7 carries its creation time
CREATE TABLE ci.annotations (
    annotation_id uuid PRIMARY KEY DEFAULT uuidv7(),
    job_id        bigint NOT NULL REFERENCES ci.jobs,
    message       text NOT NULL
);
INSERT INTO ci.annotations (job_id, message)
SELECT job_id, 'slowest ' || labels[1] || ' job'
FROM (SELECT DISTINCT ON (labels[1]) job_id, labels FROM ci.jobs ORDER BY labels[1], duration DESC, job_id) AS slowest;
SELECT uuid_extract_version(annotation_id) AS version,
       uuid_extract_timestamp(annotation_id) BETWEEN now() - interval '1 minute' AND now() AS created_just_now,
       message
FROM ci.annotations
ORDER BY annotation_id;

-- json keeps the text; jsonb stores a parsed value
SELECT '{"b": 1, "a": [1, 2], "a": 3}'::json AS json, '{"b": 1, "a": [1, 2], "a": 3}'::jsonb AS jsonb;

-- Arrays
SELECT labels, count(*) AS jobs FROM ci.jobs GROUP BY labels ORDER BY jobs DESC, labels;
SELECT count(*) AS macos_jobs FROM ci.jobs WHERE 'macos-latest' = ANY (labels);
SELECT string_to_array('0,4,7,10', ',')::int[] AS pitch_classes, string_to_array('Jimi Hendrix||Prince', '|') AS artists;

-- Ranges: the steps of a job, half-open [started_at, completed_at)
SELECT number, name, started_at, completed_at, ran, isempty(ran) AS empty
FROM ci.steps WHERE job_id = 103842192310 ORDER BY number LIMIT 4;
SELECT count(*) FILTER (WHERE isempty(ran)) AS zero_second_steps, count(*) AS steps FROM ci.steps;
SELECT count(*) AS overlapping_if_closed
FROM ci.steps AS a
JOIN ci.steps AS b ON a.job_id = b.job_id AND a.number < b.number
WHERE tstzrange(a.started_at, a.completed_at, '[]') && tstzrange(b.started_at, b.completed_at, '[]');
INSERT INTO ci.steps (job_id, number, name, conclusion, started_at, completed_at)
VALUES (103842192310, 99, 'Overlapping step', 'success', '2026-09-14 02:50:35+00', '2026-09-14 02:50:36+00');

-- Domains and CHECK constraints
INSERT INTO ci.runs VALUES (1, 'Test', 'push', 'neutral', 'main', repeat('a', 40), 1, '2026-09-15', '2026-09-15', '2026-09-15');
INSERT INTO ci.runs VALUES (1, 'Test', 'push', 'success', 'main', 'not-a-sha', 1, '2026-09-15', '2026-09-15', '2026-09-15');

-- UNIQUE and NULL
CREATE TABLE ga.owners (project text REFERENCES ga.projects, email text UNIQUE);
INSERT INTO ga.owners VALUES ('Apps/ga-server/GaApi/GaApi.csproj', NULL), ('Common/GA.Core/GA.Core.csproj', NULL);
SELECT count(*) AS owners_without_email FROM ga.owners WHERE email IS NULL;
CREATE TABLE ga.maintainers (project text REFERENCES ga.projects, email text UNIQUE NULLS NOT DISTINCT);
INSERT INTO ga.maintainers VALUES ('Apps/ga-server/GaApi/GaApi.csproj', NULL), ('Common/GA.Core/GA.Core.csproj', NULL);

-- Loading the project references without cleaning them first
CREATE TABLE ga.raw_refs (LIKE ga.project_refs INCLUDING ALL);
ALTER TABLE ga.raw_refs ADD FOREIGN KEY (from_path) REFERENCES ga.projects, ADD FOREIGN KEY (to_path) REFERENCES ga.projects;
COPY ga.raw_refs FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER match);
COPY ga.raw_refs FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER true);
ALTER TABLE ga.raw_refs DROP CONSTRAINT raw_refs_pkey;
COPY ga.raw_refs FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER true);
