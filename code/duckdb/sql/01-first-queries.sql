-- DuckDB course, lesson 1: query a JSON file directly, then keep the rows in a table
SELECT workflowName, count(*) AS runs, count(*) FILTER (conclusion = 'failure') AS failures
FROM 'data/runs.json'
GROUP BY ALL
ORDER BY runs DESC, workflowName
LIMIT 5;

CREATE TABLE runs AS SELECT * FROM 'data/runs.json';

SELECT event, conclusion, count(*) AS runs
FROM runs
GROUP BY ALL
ORDER BY event, conclusion;
