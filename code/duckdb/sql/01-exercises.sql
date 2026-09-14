-- DuckDB course, lesson 1: solutions of the exercises
-- Exercise 1: failed manual runs
SELECT count(*) AS failed_manual_runs
FROM 'data/runs.json'
WHERE event = 'workflow_dispatch' AND conclusion = 'failure';

-- Exercise 2: exact distinct counts, to compare with approx_unique in SUMMARIZE
SELECT count(DISTINCT workflowName) AS workflows, count(DISTINCT headSha) AS commits
FROM 'data/runs.json';

-- Exercise 3: column names are case-insensitive
SELECT workflowname, count(*) AS runs
FROM 'data/runs.json'
WHERE workflowname LIKE 'GHA 0%'
GROUP BY ALL
ORDER BY workflowname
LIMIT 3;
