-- DuckDB course, lesson 4: solutions of the exercises
-- check.sh creates the out folder; this script writes the same files as the lesson, so it runs on its own
CREATE TABLE runs AS FROM 'data/runs.json';
CREATE TABLE jobs AS FROM 'data/jobs.json';
COPY (SELECT databaseId, workflowName, conclusion, createdAt FROM runs ORDER BY createdAt)
TO 'out/runs-fr.csv' (DELIMITER ';', TIMESTAMPFORMAT '%d/%m/%Y %H:%M');
COPY (SELECT *, labels[1] AS os FROM jobs) TO 'out/jobs-by-os' (FORMAT parquet, PARTITION_BY (os), OVERWRITE);

-- Exercise 1: what the spreadsheet format lost
SELECT count(*) AS runs, count(*) FILTER (c.createdAt <> r.createdAt) AS different_timestamps
FROM read_csv('out/runs-fr.csv', timestampformat = '%d/%m/%Y %H:%M') c
JOIN runs r USING (databaseId);

-- Exercise 2: failed jobs on Windows, reading one partition only
SELECT os, count(*) AS jobs, count(*) FILTER (conclusion = 'failure') AS failed
FROM read_parquet('out/jobs-by-os/*/*.parquet')
WHERE os = 'windows-latest'
GROUP BY ALL;

-- Exercise 3: a glob over two JSON files with different fields
SELECT replace(filename, '\', '/') AS file, count(*) AS rows,
       count(databaseId) AS with_databaseId, count(run_id) AS with_run_id, count(conclusion) AS with_conclusion
FROM read_json('data/*.json', filename = true)
GROUP BY ALL
ORDER BY file;
