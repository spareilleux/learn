-- DuckDB course, lesson 3: lists, structs and unnest on the jobs of the GitHub Actions runs
CREATE TABLE runs AS FROM 'data/runs.json';
CREATE TABLE jobs AS FROM 'data/jobs.json';

-- Lists are indexed from 1, struct fields are read with a dot
SELECT name, labels, labels[1] AS os, labels[0] AS index_zero, len(steps) AS steps, steps[1].name AS first_step
FROM jobs
ORDER BY id
LIMIT 3;

-- unnest: one row per step
SELECT j.name AS job, s.number, s.name AS step, s.completed_at - s.started_at AS took
FROM jobs j, unnest(j.steps) AS t(s)
WHERE j.id = 104004920113
ORDER BY s.number;

-- Jobs per operating system: time in the queue, time running
SELECT labels[1] AS os, count(*) AS jobs,
       avg(started_at - created_at) AS avg_wait, avg(completed_at - started_at) AS avg_run
FROM jobs
GROUP BY ALL
ORDER BY os;

-- Lambdas on lists: the steps that failed, across all workflows
SELECT f.name AS failed_step, count(*) AS failures, list(DISTINCT r.workflowName ORDER BY r.workflowName) AS workflows
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id,
     unnest(list_filter(j.steps, lambda s: s.conclusion = 'failure')) AS t(f)
GROUP BY ALL
ORDER BY failures DESC, failed_step
LIMIT 5;

-- ANTI JOIN: runs that have no job at all
SELECT r.workflowName, r.event, r.conclusion, r.createdAt
FROM runs r
ANTI JOIN jobs j ON j.run_id = r.databaseId
ORDER BY r.createdAt;

-- Building nested values: one row per run, its jobs as a list of structs
SELECT run_id, list({'job': name, 'conclusion': conclusion} ORDER BY name) AS jobs
FROM jobs
WHERE run_id = (SELECT databaseId FROM runs WHERE workflowName = 'GHA 10: exercise checks')
GROUP BY ALL;
