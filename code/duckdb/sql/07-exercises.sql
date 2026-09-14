-- DuckDB course, lesson 7: exercise solutions
SET TimeZone = 'UTC';
CREATE TABLE steps AS
SELECT j.id AS job_id, j.labels[1] AS os, s.number, s.name, s.conclusion,
       s.started_at + to_days(d.i) AS started_at, s.completed_at + to_days(d.i) AS completed_at
FROM 'data/jobs.json' j, unnest(j.steps) AS t(s), range(500) AS d(i);
COPY steps TO 'out/steps.parquet';
COPY (FROM steps ORDER BY started_at) TO 'out/steps-sorted.parquet';

-- Exercise 1: every one of these filters is pushed into the scan, which says nothing about skipping row groups
EXPLAIN SELECT count(*) FROM 'out/steps-sorted.parquet' WHERE started_at::DATE = '2026-09-14';
EXPLAIN SELECT count(*) FROM 'out/steps-sorted.parquet' WHERE date_trunc('day', started_at) = '2026-09-14';
EXPLAIN SELECT count(*) FROM 'out/steps-sorted.parquet' WHERE strftime(started_at, '%Y-%m-%d') = '2026-09-14';

-- Exercise 2: row groups a filter on os must read, depending on the sort order
COPY (FROM steps ORDER BY os, started_at) TO 'out/steps-by-os.parquet';
SELECT replace(file_name, '\', '/') AS file, count(*) AS row_groups,
       count(*) FILTER (stats_min <= 'windows-latest' AND stats_max >= 'windows-latest') AS row_groups_to_read
FROM parquet_metadata(['out/steps.parquet', 'out/steps-sorted.parquet', 'out/steps-by-os.parquet'])
WHERE path_in_schema = 'os'
GROUP BY ALL
ORDER BY file;

-- Exercise 3: the row groups of the remote file, and the size of the trip_distance column in each
SELECT row_group_id, max(row_group_num_rows) AS rows, sum(total_compressed_size) AS all_columns,
       sum(total_compressed_size) FILTER (path_in_schema = 'trip_distance') AS trip_distance
FROM parquet_metadata('https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet')
GROUP BY ALL
ORDER BY row_group_id;
