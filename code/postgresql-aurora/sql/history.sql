-- A bigger table for lessons 5 and 6: every step of the CI snapshot, replayed on each of the 200 days up to 2026-09-14,
-- in time order. 2,204 steps x 200 days = 440,800 rows. Loaded after explain.sql, whose settings make its statistics exact.
CREATE TABLE ci.step_history (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    workflow_name text NOT NULL,
    job_name      text NOT NULL,
    step_name     text NOT NULL,
    conclusion    ci.conclusion,
    labels        text[] NOT NULL,
    started_at    timestamptz NOT NULL,
    duration      interval NOT NULL
);

INSERT INTO ci.step_history (workflow_name, job_name, step_name, conclusion, labels, started_at, duration)
SELECT r.workflow_name, j.name, s.name, s.conclusion, j.labels,
       s.started_at - make_interval(days => 199 - d), s.completed_at - s.started_at
FROM generate_series(0, 199) AS d
CROSS JOIN ci.steps AS s
JOIN ci.jobs AS j USING (job_id)
JOIN ci.runs AS r USING (run_id)
ORDER BY d, s.started_at, s.job_id, s.number;

VACUUM ANALYZE ci.step_history;
