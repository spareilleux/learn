-- Lesson 5: B-tree, partial, expression and covering indexes, GIN, BRIN, EXPLAIN (ANALYZE, BUFFERS) and statistics.
\o /dev/null
\ir schema.sql
\ir explain.sql
\ir history.sql
\o

-- The table: 2,204 steps replayed on 200 days
SELECT count(*) AS rows, pg_size_pretty(pg_relation_size('ci.step_history')) AS size,
       min(started_at)::date AS first_day, max(started_at)::date AS last_day
FROM ci.step_history;

-- One query, no index: every page of the table is read
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);

-- A B-tree on started_at
CREATE INDEX step_history_started_at ON ci.step_history (started_at);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);

-- The same index, a range that covers a third of the table
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-07-01' AND conclusion = 'failure'
$$);

-- The latest failures, all days: equality column first, then the sort column
CREATE INDEX step_history_conclusion_started_at ON ci.step_history (conclusion, started_at);
SELECT * FROM pg_temp.plan($$
    SELECT started_at, workflow_name, step_name FROM ci.step_history
    WHERE conclusion = 'failure'
    ORDER BY started_at DESC
    LIMIT 5
$$);

-- A partial index holds only the rows its WHERE accepts
CREATE INDEX step_history_not_success ON ci.step_history (started_at) WHERE conclusion <> 'success';
SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index WHERE indrelid = 'ci.step_history'::regclass
ORDER BY pg_relation_size(indexrelid) DESC, 1;

SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE conclusion <> 'success' AND started_at >= '2026-09-01'
$$);

-- An index on an expression: the expression must be immutable
CREATE INDEX step_history_day ON ci.step_history ((started_at::date));
CREATE INDEX step_history_day ON ci.step_history (((started_at AT TIME ZONE 'UTC')::date));
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE (started_at AT TIME ZONE 'UTC')::date = '2026-09-14'
$$);

-- A covering index and index-only scans
CREATE INDEX step_history_step_name ON ci.step_history (step_name) INCLUDE (duration);
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
UPDATE ci.step_history SET duration = duration WHERE step_name = 'Compile-fail doctests' AND started_at >= '2026-09-01';
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
VACUUM ci.step_history;
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);

-- GIN on an array: which elements does a row contain?
CREATE INDEX step_history_labels ON ci.step_history USING gin (labels);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE labels @> '{macos-latest}' AND step_name = 'Toolchain'
$$);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE 'macos-latest' = ANY (labels) AND step_name = 'Toolchain'
$$);

-- BRIN: one summary per range of pages, useful when the column follows the physical order
DROP INDEX ci.step_history_started_at, ci.step_history_conclusion_started_at, ci.step_history_not_success;
CREATE INDEX step_history_started_at_brin ON ci.step_history USING brin (started_at);
SELECT pg_size_pretty(pg_relation_size('ci.step_history_started_at_brin')) AS brin_size;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
SELECT attname, round(correlation::numeric, 2) AS correlation
FROM pg_stats WHERE schemaname = 'ci' AND tablename = 'step_history' AND attname IN ('id', 'started_at', 'step_name')
ORDER BY attname;

-- Statistics: two columns that depend on each other
SELECT * FROM pg_temp.estimate($$
    SELECT * FROM ci.step_history
    WHERE workflow_name = 'Java course examples' AND job_name = 'java-for-csharp (ubuntu-latest)'
$$);
CREATE STATISTICS step_history_workflow_job (dependencies) ON workflow_name, job_name FROM ci.step_history;
ANALYZE ci.step_history;
SELECT * FROM pg_temp.estimate($$
    SELECT * FROM ci.step_history
    WHERE workflow_name = 'Java course examples' AND job_name = 'java-for-csharp (ubuntu-latest)'
$$);
SELECT dependencies FROM pg_stats_ext WHERE statistics_name = 'step_history_workflow_job';
