-- Lesson 9: declarative partitioning of the step history: range, list and hash, pruning, indexes, retention, attach and detach.
\o /dev/null
\ir schema.sql
\ir explain.sql
\ir history.sql
\o

-- A partitioned table has no rows of its own: each row goes to the partition whose bounds contain its key
CREATE TABLE ci.step_log (
    id            bigint NOT NULL,
    workflow_name text NOT NULL,
    job_name      text NOT NULL,
    step_name     text NOT NULL,
    conclusion    ci.conclusion,
    started_at    timestamptz NOT NULL,
    duration      interval NOT NULL,
    PRIMARY KEY (id)
) PARTITION BY RANGE (started_at);

-- A primary key must include the partition key: each partition checks uniqueness on its own rows
CREATE TABLE ci.step_log (
    id            bigint NOT NULL,
    workflow_name text NOT NULL,
    job_name      text NOT NULL,
    step_name     text NOT NULL,
    conclusion    ci.conclusion,
    started_at    timestamptz NOT NULL,
    duration      interval NOT NULL,
    PRIMARY KEY (id, started_at)
) PARTITION BY RANGE (started_at);

-- One partition per month, February to September 2026, written by a query and run by \gexec
SELECT format('CREATE TABLE ci.step_log_%s PARTITION OF ci.step_log FOR VALUES FROM (%L) TO (%L)',
              to_char(m, 'YYYY_MM'), m, m + interval '1 month')
FROM generate_series(timestamptz '2026-02-01', '2026-09-01', interval '1 month') AS m
ORDER BY m
\gexec

INSERT INTO ci.step_log
SELECT id, workflow_name, job_name, step_name, conclusion, started_at, duration FROM ci.step_history;
VACUUM ANALYZE ci.step_log;

SELECT tableoid::regclass AS partition, count(*) AS rows, min(started_at)::date AS first_day, max(started_at)::date AS last_day
FROM ci.step_log
GROUP BY tableoid
ORDER BY first_day;

-- A row outside every partition's bounds has nowhere to go
INSERT INTO ci.step_log VALUES (0, 'Deploy to GitHub Pages', 'deploy', 'Checkout', 'success', '2026-10-01 12:00+00', '2 seconds');

-- Partition pruning: a condition on the partition key leaves out the partitions that can't match
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_log WHERE started_at >= '2026-09-14'
$$);
-- Without a condition on the key, every partition is read
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_log WHERE step_name = 'Compile-fail doctests'
$$);

-- A parameter is only known at execution: the generic plan prunes then, and says how many partitions it skipped
PREPARE failures_since (timestamptz) AS
    SELECT count(*) FROM ci.step_log WHERE started_at >= $1 AND conclusion = 'failure';
SET plan_cache_mode = force_generic_plan;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF, BUFFERS OFF) EXECUTE failures_since('2026-09-01');
RESET plan_cache_mode;

-- An index created on the partitioned table is created on every partition, and on the partitions added later
CREATE INDEX step_log_step_name ON ci.step_log (step_name);
SELECT c.relname AS index, i.inhparent::regclass AS parent
FROM pg_inherits AS i JOIN pg_class AS c ON c.oid = i.inhrelid
WHERE i.inhparent = 'ci.step_log_step_name'::regclass
ORDER BY c.relname;

-- An UPDATE of the partition key moves the row to another partition
UPDATE ci.step_log SET started_at = started_at - interval '1 month'
WHERE id = (SELECT min(id) FROM ci.step_log WHERE started_at >= '2026-09-01')
RETURNING tableoid::regclass AS now_in, started_at;

-- Retention: removing a month with DELETE leaves dead rows to vacuum; dropping its partition removes a file
CREATE EXTENSION pgstattuple;
BEGIN;
DELETE FROM ci.step_log WHERE started_at < '2026-03-01';
SELECT pg_size_pretty(table_len) AS size, dead_tuple_count FROM pgstattuple('ci.step_log_2026_02');
ROLLBACK;
ALTER TABLE ci.step_log DETACH PARTITION ci.step_log_2026_02;
SELECT count(*) AS rows_left FROM ci.step_log;
DROP TABLE ci.step_log_2026_02;

-- A default partition takes the rows no other partition accepts
CREATE TABLE ci.step_log_default PARTITION OF ci.step_log DEFAULT;
INSERT INTO ci.step_log VALUES (0, 'Deploy to GitHub Pages', 'deploy', 'Checkout', 'success', '2026-10-01 12:00+00', '2 seconds');
-- ... and then blocks a new partition that its rows belong to
CREATE TABLE ci.step_log_2026_10 PARTITION OF ci.step_log FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

-- Loading a month apart, then attaching it: a CHECK constraint with the same bounds saves the scan that validates them
DELETE FROM ci.step_log_default;
CREATE TABLE ci.step_log_2026_10 (LIKE ci.step_log INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
INSERT INTO ci.step_log_2026_10
SELECT id + 1000000, workflow_name, job_name, step_name, conclusion, started_at + interval '1 month', duration
FROM ci.step_log_2026_09;
ALTER TABLE ci.step_log_2026_10 ADD CONSTRAINT in_october
    CHECK (started_at >= '2026-10-01' AND started_at < '2026-11-01');
ALTER TABLE ci.step_log ATTACH PARTITION ci.step_log_2026_10 FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
SELECT relname AS partition, pg_get_expr(relpartbound, oid) AS bounds
FROM pg_class
WHERE oid IN (SELECT inhrelid FROM pg_inherits WHERE inhparent = 'ci.step_log'::regclass)
ORDER BY relname;

-- List and hash partitioning
CREATE TABLE ci.step_outcomes (LIKE ci.step_log) PARTITION BY LIST (conclusion);
CREATE TABLE ci.step_outcomes_success PARTITION OF ci.step_outcomes FOR VALUES IN ('success');
CREATE TABLE ci.step_outcomes_other PARTITION OF ci.step_outcomes DEFAULT;
CREATE TABLE ci.step_buckets (LIKE ci.step_log) PARTITION BY HASH (job_name);
SELECT format('CREATE TABLE ci.step_buckets_%s PARTITION OF ci.step_buckets FOR VALUES WITH (MODULUS 4, REMAINDER %s)', r, r)
FROM generate_series(0, 3) AS r
ORDER BY r
\gexec
INSERT INTO ci.step_outcomes SELECT * FROM ci.step_log;
INSERT INTO ci.step_buckets SELECT * FROM ci.step_log;
SELECT tableoid::regclass AS partition, count(*) AS rows, count(DISTINCT job_name) AS jobs
FROM ci.step_outcomes GROUP BY tableoid
UNION ALL
SELECT tableoid::regclass, count(*), count(DISTINCT job_name)
FROM ci.step_buckets GROUP BY tableoid
ORDER BY 1;
