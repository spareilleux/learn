-- Lesson 6: row versions, xmin and xmax, dead tuples, VACUUM, bloat, HOT updates and locks seen from one session.
-- The programs of lesson 6 (csharp/L06.cs, java/.../L06.java) show what two sessions do to each other.
\o /dev/null
\ir schema.sql
\ir explain.sql
\ir history.sql
\o

-- One row per workflow, in a table autovacuum leaves alone: the script decides when VACUUM runs
CREATE TABLE ci.workflow_totals (
    workflow_name text PRIMARY KEY,
    runs          integer NOT NULL,
    failures      integer NOT NULL
) WITH (autovacuum_enabled = false);
-- Transaction IDs below are relative to this one, so that the output doesn't depend on how many transactions the server ran before
SELECT pg_current_xact_id()::text::bigint AS base \gset
INSERT INTO ci.workflow_totals
SELECT workflow_name, count(*), count(*) FILTER (WHERE conclusion = 'failure')
FROM ci.runs GROUP BY workflow_name ORDER BY workflow_name;

-- Each row version carries the transaction that created it (xmin) and the one that deleted it (xmax), and its place (ctid)
SELECT ctid, xmin::text::bigint - :base AS xmin, xmax, workflow_name, runs
FROM ci.workflow_totals WHERE workflow_name LIKE 'GHA 0%' ORDER BY workflow_name LIMIT 3;

-- An UPDATE writes a new version and marks the old one deleted
UPDATE ci.workflow_totals SET runs = runs + 1 WHERE workflow_name = 'GHA 01: hello';
SELECT ctid, xmin::text::bigint - :base AS xmin, xmax, workflow_name, runs
FROM ci.workflow_totals WHERE workflow_name = 'GHA 01: hello';

-- Both versions are still in the page
CREATE EXTENSION pageinspect;
SELECT lp, t_ctid, t_xmin::text::bigint - :base AS t_xmin,
       CASE WHEN t_xmax::text = '0' THEN NULL ELSE t_xmax::text::bigint - :base END AS t_xmax
FROM heap_page_items(get_raw_page('ci.workflow_totals', 0))
WHERE lp IN (2, 22)
ORDER BY lp;

-- A rolled-back UPDATE leaves a dead version too
BEGIN;
UPDATE ci.workflow_totals SET failures = 0;
ROLLBACK;
CREATE EXTENSION pgstattuple;
SELECT tuple_count, dead_tuple_count, table_len FROM pgstattuple('ci.workflow_totals');

-- VACUUM makes the dead versions' space reusable; the file keeps its size
VACUUM ci.workflow_totals;
SELECT tuple_count, dead_tuple_count, table_len, free_space > 0 AS has_free_space FROM pgstattuple('ci.workflow_totals');

-- Bloat at scale: every row of the step history updated once
ALTER TABLE ci.step_history SET (autovacuum_enabled = false);
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS before;
UPDATE ci.step_history SET duration = duration + interval '1 second';
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_update,
       dead_tuple_count, round(dead_tuple_percent) AS dead_percent
FROM pgstattuple('ci.step_history');
VACUUM ci.step_history;
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_vacuum, round(free_percent) AS free_percent
FROM pgstattuple('ci.step_history');
-- The next full update reuses the free space instead of growing the file
UPDATE ci.step_history SET duration = duration - interval '1 second';
VACUUM ci.step_history;
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_second_update;
-- VACUUM FULL rewrites the table, under an ACCESS EXCLUSIVE lock
VACUUM FULL ci.step_history;
SELECT pg_size_pretty(pg_relation_size('ci.step_history')) AS after_vacuum_full;

-- HOT updates: a new version on the same page, no index change, when no indexed column changes and the page has room
ALTER TABLE ci.workflow_totals SET (fillfactor = 70);
VACUUM FULL ci.workflow_totals;
SELECT pg_stat_reset_single_table_counters('ci.workflow_totals'::regclass) \gset
UPDATE ci.workflow_totals SET failures = failures + 1;
UPDATE ci.workflow_totals SET workflow_name = workflow_name || ' ' WHERE workflow_name LIKE 'GHA 0%';
SELECT pg_stat_force_next_flush() \gset
SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relid = 'ci.workflow_totals'::regclass;

-- Locks held by this session's open transaction
BEGIN;
SELECT runs FROM ci.workflow_totals WHERE workflow_name = 'Deploy to GitHub Pages' FOR UPDATE;
SELECT relation::regclass, mode, granted
FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'relation' AND relation::regclass::text LIKE 'ci.%'
ORDER BY 1, 2;
-- A row lock is not in pg_locks: it is written in the row version's xmax
CREATE EXTENSION pgrowlocks;
SELECT locked_row, multi, modes FROM pgrowlocks('ci.workflow_totals');
ALTER TABLE ci.workflow_totals ADD COLUMN note text;
SELECT relation::regclass, mode, granted
FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'relation' AND relation::regclass::text LIKE 'ci.%'
ORDER BY 1, 2;
ROLLBACK;
