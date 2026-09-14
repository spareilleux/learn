-- DuckDB course, lesson 7: query plans, projection and filter pushdown, row groups and partition pruning
-- Timings are not compared: timings/07-performance.sql prints them
SET TimeZone = 'UTC';
CREATE TABLE jobs AS FROM 'data/jobs.json';

-- A bigger table: every step of every job, shifted by 0 to 499 days
CREATE TABLE steps AS
SELECT j.id AS job_id, j.labels[1] AS os, s.number, s.name, s.conclusion,
       s.started_at + to_days(d.i) AS started_at, s.completed_at + to_days(d.i) AS completed_at
FROM jobs j, unnest(j.steps) AS t(s), range(500) AS d(i);
SELECT count(*) AS steps, min(started_at) AS first_step, max(started_at) AS last_step FROM steps;

-- The same rows in two Parquet files, in insertion order and sorted by start time
COPY steps TO 'out/steps.parquet';
COPY (FROM steps ORDER BY started_at) TO 'out/steps-sorted.parquet';

-- The plan of a query on a JSON file: the reader only keeps the columns the query needs
EXPLAIN SELECT conclusion, count(*) FROM 'data/jobs.json' GROUP BY ALL;

-- On Parquet, the columns and the filter are pushed down into the scan
EXPLAIN
SELECT name, avg(completed_at - started_at) AS took
FROM 'out/steps.parquet'
WHERE started_at < '2026-09-20'
GROUP BY ALL;

-- Min and max of started_at in each row group: how many row groups the filter cannot skip
SELECT replace(file_name, '\', '/') AS file, count(*) AS row_groups, sum(row_group_num_rows) AS rows,
       count(*) FILTER (stats_min::TIMESTAMP < '2026-09-20') AS row_groups_to_read
FROM parquet_metadata(['out/steps.parquet', 'out/steps-sorted.parquet'])
WHERE path_in_schema = 'started_at'
GROUP BY ALL
ORDER BY file;

-- Both files give the same answer
SELECT count(*) AS steps, sum(len(name)) AS name_chars FROM 'out/steps.parquet' WHERE started_at < '2026-09-20';
SELECT count(*) AS steps, sum(len(name)) AS name_chars FROM 'out/steps-sorted.parquet' WHERE started_at < '2026-09-20';

-- Partition pruning: the folder names are enough to skip files
COPY (SELECT *, labels[1] AS os FROM jobs) TO 'out/jobs-by-os' (FORMAT parquet, PARTITION_BY (os), OVERWRITE);
EXPLAIN SELECT count(*) FROM read_parquet('out/jobs-by-os/*/*.parquet') WHERE os = 'windows-latest';
