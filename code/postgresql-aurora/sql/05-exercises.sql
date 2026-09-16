-- Lesson 5, exercise solutions. The course model and the step history are loaded first, without output.
\o /dev/null
\ir schema.sql
\ir explain.sql
\ir history.sql
\o

-- Exercise 1: the 20 latest failed steps of the Rust course's workflow, without a sort
CREATE INDEX step_history_failures ON ci.step_history (workflow_name, started_at) WHERE conclusion = 'failure';
SELECT * FROM pg_temp.plan($$
    SELECT started_at, job_name, step_name FROM ci.step_history
    WHERE conclusion = 'failure' AND workflow_name = 'Rust course examples'
    ORDER BY started_at DESC
    LIMIT 20
$$);
SELECT pg_size_pretty(pg_relation_size('ci.step_history_failures')) AS size;

-- Exercise 2: one day of steps, written two ways
CREATE INDEX step_history_started_at ON ci.step_history (started_at);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE date_trunc('day', started_at) = '2026-09-10'
$$);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE started_at >= '2026-09-10' AND started_at < '2026-09-11'
$$);

-- Exercise 3: the same rows in another physical order, and a BRIN index on started_at
CREATE TABLE ci.step_history_by_name AS SELECT * FROM ci.step_history ORDER BY step_name, started_at;
CREATE INDEX step_history_by_name_brin ON ci.step_history_by_name USING brin (started_at);
VACUUM ANALYZE ci.step_history_by_name;
SELECT attname, round(correlation::numeric, 2) AS correlation
FROM pg_stats WHERE schemaname = 'ci' AND tablename = 'step_history_by_name' AND attname = 'started_at';
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history_by_name WHERE started_at >= '2026-09-14'
$$);
