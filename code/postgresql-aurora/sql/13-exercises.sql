-- Lesson 13, exercise solutions. The model of lesson 2 is loaded first, without output: the same runs and jobs as the
-- SQL Server database of mssql/13-source.sql.
\o /dev/null
\ir schema.sql
\o

-- Exercise 1: dbo.SlowJobs as a PostgreSQL view. DATEDIFF(second, ...) counts second boundaries crossed; the
-- difference of two timestamptz truncated to the second counts the same thing.
CREATE VIEW ci.slow_jobs AS
SELECT j.name, r.workflow_name,
       extract(epoch FROM date_trunc('second', j.completed_at) - date_trunc('second', j.started_at))::integer AS seconds
FROM ci.jobs AS j JOIN ci.runs AS r ON r.run_id = j.run_id
ORDER BY seconds DESC
FETCH FIRST 5 ROWS WITH TIES;

SELECT * FROM ci.slow_jobs ORDER BY seconds DESC, name, workflow_name;

-- Exercise 3: a month of 730 hours for a writer and one Aurora Replica, both db.r8g.large, with 100 GiB of data and
-- 300 million I/O requests, at the us-east-1 on-demand prices of the AWS Price List published on 2026-09-11
WITH price (configuration, instance_hour, gib_month, million_ios) AS (
    VALUES ('Aurora Standard', 0.276, 0.10, 0.20),
           ('Aurora I/O-Optimized', 0.359, 0.225, 0.00)
)
SELECT configuration,
       2 * 730 * instance_hour AS instances,
       100 * gib_month AS storage,
       300 * million_ios AS io,
       2 * 730 * instance_hour + 100 * gib_month + 300 * million_ios AS month
FROM price
ORDER BY month;

-- The number of million I/O requests a month from which I/O-Optimized costs less, for the same instances and data
SELECT round(((2 * 730 * 0.359 + 100 * 0.225) - (2 * 730 * 0.276 + 100 * 0.10)) / 0.20) AS million_ios;
