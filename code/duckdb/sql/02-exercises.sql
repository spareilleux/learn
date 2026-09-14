-- DuckDB course, lesson 2: solutions of the exercises
CREATE TABLE runs AS FROM 'data/runs.json';

-- Exercise 1: runs per UTC day, and the share that did not succeed
SELECT createdAt::DATE AS day, count(*) AS runs,
       round(100 * count(*) FILTER (conclusion <> 'success') / count(*), 1) AS not_green_pct
FROM runs
GROUP BY ALL
ORDER BY day;

-- Exercise 2: for each failure, how long until the same workflow was green again
SELECT workflowName, createdAt AS failed_at,
       min(createdAt) FILTER (conclusion = 'success') OVER (
           PARTITION BY workflowName ORDER BY createdAt
           ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) - createdAt AS red_for
FROM runs
QUALIFY conclusion = 'failure'
ORDER BY red_for DESC NULLS FIRST, workflowName, failed_at;

-- Exercise 3: the workflows whose last run is not green, without a window function
SELECT workflowName, arg_max(conclusion, createdAt) AS last_conclusion
FROM runs
GROUP BY ALL
HAVING last_conclusion <> 'success'
ORDER BY workflowName;
