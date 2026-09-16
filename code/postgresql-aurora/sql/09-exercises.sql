-- Lesson 9, exercises: partitions by workflow, two partitioning levels, and a retention procedure.
\o /dev/null
\ir schema.sql
\ir explain.sql
\ir history.sql
\o

-- Exercise 1: runs partitioned by workflow, with its own partition for deployments and a default for the rest,
-- and a plan that reads only the partition for 'Rust course examples'
CREATE TABLE ci.runs_by_workflow (LIKE ci.runs) PARTITION BY LIST (workflow_name);
CREATE TABLE ci.runs_deploy PARTITION OF ci.runs_by_workflow FOR VALUES IN ('Deploy to GitHub Pages');
CREATE TABLE ci.runs_examples PARTITION OF ci.runs_by_workflow
    FOR VALUES IN ('Rust course examples', 'Java course examples', 'WSL containers examples');
CREATE TABLE ci.runs_other PARTITION OF ci.runs_by_workflow DEFAULT;
INSERT INTO ci.runs_by_workflow SELECT * FROM ci.runs;
SELECT tableoid::regclass AS partition, count(*) AS runs FROM ci.runs_by_workflow GROUP BY tableoid ORDER BY tableoid::regclass::text;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.runs_by_workflow WHERE workflow_name = 'Rust course examples'
$$);

-- Exercise 2: two levels, months then conclusion, and the tree that pg_partition_tree returns
CREATE TABLE ci.step_months (LIKE ci.step_history) PARTITION BY RANGE (started_at);
CREATE TABLE ci.step_months_2026_09 PARTITION OF ci.step_months
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01') PARTITION BY LIST (conclusion);
CREATE TABLE ci.step_months_2026_09_success PARTITION OF ci.step_months_2026_09 FOR VALUES IN ('success');
CREATE TABLE ci.step_months_2026_09_other PARTITION OF ci.step_months_2026_09 DEFAULT;
INSERT INTO ci.step_months SELECT * FROM ci.step_history WHERE started_at >= '2026-09-01';
SELECT relid, parentrelid, isleaf, level FROM pg_partition_tree('ci.step_months') ORDER BY level, relid::text;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_months WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);

-- Exercise 3: a procedure that detaches and drops the monthly partitions that end before a date
CREATE TABLE ci.step_log (LIKE ci.step_history) PARTITION BY RANGE (started_at);
SELECT format('CREATE TABLE ci.step_log_%s PARTITION OF ci.step_log FOR VALUES FROM (%L) TO (%L)',
              to_char(m, 'YYYY_MM'), m, m + interval '1 month')
FROM generate_series(timestamptz '2026-02-01', '2026-09-01', interval '1 month') AS m
ORDER BY m
\gexec

CREATE PROCEDURE ci.drop_partitions_before(parent regclass, cutoff timestamptz)
LANGUAGE plpgsql AS $$
DECLARE
    part regclass;
BEGIN
    FOR part IN
        SELECT c.oid::regclass
        FROM pg_inherits AS i JOIN pg_class AS c ON c.oid = i.inhrelid
        -- the upper bound, read back from the partition's definition: FOR VALUES FROM ('…') TO ('…')
        WHERE i.inhparent = parent
          AND substring(pg_get_expr(c.relpartbound, c.oid) FROM $re$TO \('([^']+)'\)$re$)::timestamptz <= cutoff
        ORDER BY c.relname
    LOOP
        -- the name first: once the table is dropped, its regclass prints as a bare OID
        RAISE NOTICE 'dropping %', part;
        EXECUTE format('ALTER TABLE %s DETACH PARTITION %s', parent, part);
        EXECUTE format('DROP TABLE %s', part);
    END LOOP;
END
$$;

CALL ci.drop_partitions_before('ci.step_log', '2026-06-01');
SELECT relid FROM pg_partition_tree('ci.step_log') WHERE isleaf ORDER BY relid::text;
