-- DuckDB course, lesson 4: CSV sniffing, Parquet files, partitioned folders and remote files
-- check.sh creates the out folder before running the scripts
CREATE TABLE runs AS FROM 'data/runs.json';
CREATE TABLE jobs AS FROM 'data/jobs.json';

-- A CSV file the way a French spreadsheet saves it: semicolons, day before month
COPY (SELECT databaseId, workflowName, conclusion, createdAt FROM runs ORDER BY createdAt)
TO 'out/runs-fr.csv' (DELIMITER ';', TIMESTAMPFORMAT '%d/%m/%Y %H:%M');

-- What the CSV sniffer detects
SELECT Delimiter, HasHeader, c.name, c.type
FROM sniff_csv('out/runs-fr.csv'), unnest(Columns) AS t(c);

-- Telling read_csv the timestamp format
SELECT typeof(min(createdAt)) AS type, min(createdAt) AS first_run, max(createdAt) AS last_run
FROM read_csv('out/runs-fr.csv', timestampformat = '%d/%m/%Y %H:%M');

-- A Parquet file keeps the types, and stores each column separately
COPY jobs TO 'out/jobs.parquet';
SELECT path_in_schema, type, num_values, compression
FROM parquet_metadata('out/jobs.parquet')
ORDER BY column_id;

-- One folder per operating system
COPY (SELECT *, labels[1] AS os FROM jobs) TO 'out/jobs-by-os' (FORMAT parquet, PARTITION_BY (os), OVERWRITE);

-- Reading all the files with a glob; the os column comes from the folder names
SELECT replace(filename, '\', '/') AS file, os, count(*) AS jobs
FROM read_parquet('out/jobs-by-os/*/*.parquet', filename = true)
GROUP BY ALL
ORDER BY file;

-- A file over HTTPS: the copy of runs.json on GitHub
SELECT count(*) AS runs, max(createdAt) AS last_run
FROM 'https://raw.githubusercontent.com/spareilleux/learn/main/code/duckdb/data/runs.json';
