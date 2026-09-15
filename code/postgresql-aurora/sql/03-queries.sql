-- Lesson 3: CTEs and recursion, window functions, LATERAL, DISTINCT ON, RETURNING, ON CONFLICT and MERGE.
\o /dev/null
\ir schema.sql
\o

-- A CTE: the failed runs, then their jobs
WITH failed_runs AS (
    SELECT run_id, workflow_name FROM ci.runs WHERE conclusion = 'failure'
)
SELECT f.workflow_name, count(DISTINCT f.run_id) AS failed_runs,
       count(j.job_id) FILTER (WHERE j.conclusion = 'failure') AS failed_jobs
FROM failed_runs AS f
LEFT JOIN ci.jobs AS j USING (run_id)
GROUP BY f.workflow_name
ORDER BY failed_runs DESC, f.workflow_name
LIMIT 5;

-- WITH RECURSIVE: every project GaApi depends on, directly or not
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth
    FROM ga.project_refs
    WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.depth + 1
    FROM deps AS d
    JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) AS paths, count(DISTINCT to_path) AS projects, max(depth) AS longest_path
FROM deps;

-- The shortest chain to each project three references away
WITH RECURSIVE deps AS (
    SELECT to_path, ARRAY[split_part(to_path, '/', -1)] AS chain
    FROM ga.project_refs
    WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.chain || split_part(r.to_path, '/', -1)
    FROM deps AS d
    JOIN ga.project_refs AS r ON r.from_path = d.to_path
),
shortest AS (
    SELECT DISTINCT ON (to_path) to_path, chain
    FROM deps
    ORDER BY to_path, cardinality(chain), chain
)
SELECT cardinality(chain) AS depth, array_to_string(chain, ' > ') AS chain
FROM shortest
WHERE cardinality(chain) >= 3
ORDER BY chain;

-- A cycle, added on purpose: without protection, the recursion never ends
INSERT INTO ga.project_refs VALUES ('Common/GA.Core/GA.Core.csproj', 'Apps/ga-server/GaApi/GaApi.csproj');
SET statement_timeout = '3s';
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION
    SELECT r.to_path, d.depth + 1 FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) FROM deps;
RESET statement_timeout;

WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.depth + 1 FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
) CYCLE to_path SET is_cycle USING path
SELECT count(*) AS paths, count(*) FILTER (WHERE is_cycle) AS cycles, max(depth) AS longest_path
FROM deps;

WITH RECURSIVE deps AS (
    SELECT to_path FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION
    SELECT r.to_path FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) AS projects FROM deps;
DELETE FROM ga.project_refs WHERE from_path = 'Common/GA.Core/GA.Core.csproj';

-- Window functions: the previous run of the same workflow, and a running count
SELECT run_id, started_at,
       updated_at - started_at AS took,
       lag(updated_at - started_at) OVER w AS previous_took,
       row_number() OVER w AS nth,
       count(*) FILTER (WHERE conclusion = 'failure') OVER w AS failures_so_far
FROM ci.runs
WHERE workflow_name = 'Rust course examples'
WINDOW w AS (PARTITION BY workflow_name ORDER BY started_at, run_id)
ORDER BY started_at, run_id
LIMIT 6;

-- A window over groups: each OS's share of the CI time
SELECT labels[1] AS os, count(*) AS jobs, sum(duration) AS total,
       round(100 * extract(epoch FROM sum(duration)) / sum(extract(epoch FROM sum(duration))) OVER (), 1) AS percent
FROM ci.jobs
GROUP BY labels[1]
ORDER BY total DESC;

-- LATERAL: the first failed step of each failed run (CROSS APPLY)
SELECT r.workflow_name, r.run_id, first_failure.job, first_failure.step
FROM ci.runs AS r
CROSS JOIN LATERAL (
    SELECT j.name AS job, s.name AS step
    FROM ci.jobs AS j
    JOIN ci.steps AS s USING (job_id)
    WHERE j.run_id = r.run_id AND s.conclusion = 'failure'
    ORDER BY s.started_at, j.job_id, s.number
    LIMIT 1
) AS first_failure
WHERE r.conclusion = 'failure'
ORDER BY r.workflow_name, r.run_id
LIMIT 6;

SELECT count(*) AS failed_runs,
       count(*) FILTER (WHERE NOT EXISTS (
           SELECT FROM ci.jobs AS j JOIN ci.steps AS s USING (job_id)
           WHERE j.run_id = r.run_id AND s.conclusion = 'failure')) AS without_failed_step
FROM ci.runs AS r
WHERE r.conclusion = 'failure';

-- Versions are text: max() compares them character by character
SELECT package, max(version) AS text_max, count(DISTINCT version) AS versions
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.Hosting%'
GROUP BY package
ORDER BY package;

-- DISTINCT ON: the highest version of each package, compared as numbers
SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.%'
ORDER BY package, string_to_array(version, '.')::int[] DESC;

SELECT version, count(*) AS refs
FROM ga.package_refs
WHERE version !~ '^\d+(\.\d+)*$'
GROUP BY version
ORDER BY version;

SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.H%' AND version ~ '^\d+(\.\d+)*$'
ORDER BY package, string_to_array(version, '.')::int[] DESC;

-- RETURNING (OUTPUT inserted.*)
CREATE TABLE ga.pinned_versions (
    package    text PRIMARY KEY,
    version    text NOT NULL CHECK (version ~ '^\d+(\.\d+)*$'),
    pinned_at  timestamptz NOT NULL DEFAULT '2026-09-14 00:00:00+00'
);
INSERT INTO ga.pinned_versions (package, version)
SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package IN ('Microsoft.Extensions.Hosting', 'MongoDB.Driver')
ORDER BY package, string_to_array(version, '.')::int[] DESC
RETURNING package, version, pinned_at;

-- ON CONFLICT: insert or update
INSERT INTO ga.pinned_versions (package, version, pinned_at)
VALUES ('MongoDB.Driver', '3.2.0', '2026-09-15 00:00:00+00'),
       ('Npgsql', '10.0.3', '2026-09-15 00:00:00+00')
ON CONFLICT (package) DO UPDATE
SET version = EXCLUDED.version, pinned_at = EXCLUDED.pinned_at
RETURNING package, old.version AS old_version, new.version AS new_version, old IS NULL AS inserted;

INSERT INTO ga.pinned_versions (package, version)
VALUES ('Dapper', '2.1.86'), ('Dapper', '2.1.72')
ON CONFLICT (package) DO UPDATE SET version = EXCLUDED.version;

INSERT INTO ga.pinned_versions (package, version)
VALUES ('Npgsql', '9.0.5')
ON CONFLICT (package) DO NOTHING
RETURNING package;

-- MERGE: pin the highest numeric version of every package used by eight projects or more
WITH changes AS (
    MERGE INTO ga.pinned_versions AS t
    USING (
        SELECT package, (array_agg(version ORDER BY string_to_array(version, '.')::int[] DESC))[1] AS version
        FROM ga.package_refs
        WHERE version ~ '^\d+(\.\d+)*$'
        GROUP BY package
        HAVING count(*) >= 8
    ) AS s
    ON t.package = s.package
    WHEN MATCHED AND t.version <> s.version THEN
        UPDATE SET version = s.version, pinned_at = '2026-09-16 00:00:00+00'
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (package, version) VALUES (s.package, s.version)
    WHEN NOT MATCHED BY SOURCE THEN
        DELETE
    RETURNING merge_action() AS action, coalesce(new.package, old.package) AS package,
              old.version AS old_version, new.version AS new_version
)
SELECT * FROM changes ORDER BY action, package;

SELECT package, version, pinned_at FROM ga.pinned_versions ORDER BY package;
