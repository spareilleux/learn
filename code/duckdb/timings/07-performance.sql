-- DuckDB course, lesson 7: timings on a larger table, a remote Parquet file and a memory limit
-- Not compared by CI: run from code/duckdb with duckdb < timings/07-performance.sql
SET TimeZone = 'UTC';
.timer on

-- 11 million steps: every step of every job, shifted by 0 to 4,999 days
CREATE TABLE steps AS
SELECT j.id AS job_id, j.labels[1] AS os, s.number, s.name, s.conclusion,
       s.started_at + to_days(d.i) AS started_at, s.completed_at + to_days(d.i) AS completed_at
FROM 'data/jobs.json' j, unnest(j.steps) AS t(s), range(5000) AS d(i);
SELECT count(*) AS steps, current_setting('threads') AS threads FROM steps;

COPY steps TO 'out/steps-big.parquet';
COPY steps TO 'out/steps-big.csv';
COPY (FROM steps ORDER BY started_at) TO 'out/steps-big-sorted.parquet';
SELECT replace(filename, '\', '/') AS file, size FROM read_blob('out/steps-big*') ORDER BY file;

-- The slowest step on average: table, Parquet, CSV
SELECT os, name, avg(completed_at - started_at) AS took FROM steps GROUP BY ALL ORDER BY took DESC LIMIT 1;
SELECT os, name, avg(completed_at - started_at) AS took FROM 'out/steps-big.parquet' GROUP BY ALL ORDER BY took DESC LIMIT 1;
SELECT os, name, avg(completed_at - started_at) AS took FROM 'out/steps-big.csv' GROUP BY ALL ORDER BY took DESC LIMIT 1;

-- A selective filter: Parquet skips row groups, CSV reads everything
SELECT count(*) FROM 'out/steps-big.parquet' WHERE started_at < '2026-09-20';
SELECT count(*) FROM 'out/steps-big.csv' WHERE started_at < '2026-09-20';

-- One thread, one day in 2030: unsorted against sorted
SET threads = 1;
SELECT sum(len(name)) FROM 'out/steps-big.parquet' WHERE started_at BETWEEN '2030-01-01' AND '2030-01-02';
SELECT sum(len(name)) FROM 'out/steps-big-sorted.parquet' WHERE started_at BETWEEN '2030-01-01' AND '2030-01-02';
SELECT os, name, avg(completed_at - started_at) AS took FROM steps GROUP BY ALL ORDER BY took DESC LIMIT 1;
RESET threads;

.timer off
EXPLAIN ANALYZE
SELECT sum(len(name)) FROM 'out/steps-big-sorted.parquet' WHERE started_at BETWEEN '2030-01-01' AND '2030-01-02';
.timer on

-- A remote Parquet file: the HTTP log shows the bytes each query downloads
CALL enable_logging('HTTP', storage = 'memory');
SELECT count(*) FROM 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet';
SELECT count(*) AS requests, sum(response.headers['Content-Length']::BIGINT) AS bytes FROM duckdb_logs_parsed('HTTP') WHERE request.type = 'GET';
CALL truncate_duckdb_logs();
SELECT avg(trip_distance) FROM 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet';
SELECT count(*) AS requests, sum(response.headers['Content-Length']::BIGINT) AS bytes FROM duckdb_logs_parsed('HTTP') WHERE request.type = 'GET';
CALL truncate_duckdb_logs();
SELECT * FROM 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet' LIMIT 1;
SELECT count(*) AS requests, sum(response.headers['Content-Length']::BIGINT) AS bytes FROM duckdb_logs_parsed('HTTP') WHERE request.type = 'GET';
CALL disable_logging();

-- Sorting 11 million rows with little memory: DuckDB spills to temporary files
DROP TABLE steps;
SET temp_directory = 'out/tmp';
SET memory_limit = '500MB';
COPY (FROM 'out/steps-big.parquet' ORDER BY started_at) TO 'out/steps-big-sorted-500mb.parquet';
SET memory_limit = '100MB';
SET threads = 1;
COPY (FROM 'out/steps-big.parquet' ORDER BY started_at) TO 'out/steps-big-sorted-100mb.parquet';
SELECT count(*) FROM 'out/steps-big-sorted-100mb.parquet';
