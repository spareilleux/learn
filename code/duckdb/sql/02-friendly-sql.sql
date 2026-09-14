-- DuckDB course, lesson 2: dates and intervals, window functions, QUALIFY, PIVOT and other friendly SQL
CREATE TABLE runs AS FROM 'data/runs.json';

-- Subtracting two timestamps gives an interval
SELECT workflowName, count(*) AS runs, avg(updatedAt - startedAt) AS avg_took, max(updatedAt - startedAt) AS max_took
FROM runs
GROUP BY ALL
HAVING runs >= 4
ORDER BY avg_took DESC;

-- Truncating timestamps to the hour
SELECT date_trunc('hour', createdAt) AS hour, count(*) AS runs
FROM runs
GROUP BY ALL
ORDER BY hour
LIMIT 5;

-- The file's timestamps are UTC, stored without a time zone
SET TimeZone = 'Europe/Paris';
SELECT createdAt, createdAt AT TIME ZONE 'UTC' AS created_utc, hour(createdAt AT TIME ZONE 'UTC') AS hour_in_paris
FROM runs
ORDER BY createdAt
LIMIT 1;

-- Window functions: each run compared with the previous run of the same workflow
SELECT createdAt, conclusion,
       lag(conclusion) OVER w AS previous,
       createdAt - lag(createdAt) OVER w AS since_previous
FROM runs
WHERE workflowName = 'Rust course examples'
WINDOW w AS (PARTITION BY workflowName ORDER BY createdAt)
ORDER BY createdAt
LIMIT 9;

-- QUALIFY filters on a window function: workflows whose last run is not green
SELECT workflowName, conclusion, createdAt
FROM runs
QUALIFY row_number() OVER (PARTITION BY workflowName ORDER BY createdAt DESC) = 1
    AND conclusion <> 'success'
ORDER BY workflowName;

-- PIVOT turns the values of a column into columns
PIVOT (FROM runs WHERE workflowName IN ('Deploy to GitHub Pages', 'Rust course examples', 'Java course examples', 'GHA 03: triggers'))
ON conclusion
USING count(*)
GROUP BY workflowName
ORDER BY workflowName;

-- Selecting columns by exclusion, by pattern, and slicing strings
SELECT headSha[1:7] AS sha, min(COLUMNS('.*At'))
FROM runs
GROUP BY ALL
ORDER BY ALL
LIMIT 3;
