-- DuckDB course, lesson 3: solutions of the exercises
CREATE TABLE runs AS FROM 'data/runs.json';
CREATE TABLE jobs AS FROM 'data/jobs.json';

-- Exercise 1: jobs without any step, and what the API put in runner_name
SELECT r.workflowName, j.name AS job, j.conclusion, j.runner_name, j.runner_name IS NULL AS runner_is_null
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id
WHERE len(j.steps) = 0
ORDER BY j.id;

-- Exercise 2: a recursive unnest next to a column with the same name
SELECT name, name_1, conclusion
FROM (SELECT name, unnest(steps, recursive := true) FROM jobs WHERE id = 104004920113)
ORDER BY number
LIMIT 3;

-- Exercise 3: the slowest step on each operating system in "GHA 02: build and test"
SELECT j.labels[1] AS os, j.name AS job, s.name AS step, s.completed_at - s.started_at AS took
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id,
     unnest(j.steps) AS t(s)
WHERE r.workflowName = 'GHA 02: build and test'
QUALIFY row_number() OVER (PARTITION BY os ORDER BY took DESC, j.id, s.number) = 1
ORDER BY os;
