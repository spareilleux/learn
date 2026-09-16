-- Helpers for the lessons that show plans (5 and 7), loaded after schema.sql.

-- Plans and row counts that are the same at every run:
-- no parallel workers, whose share of the rows varies, and statistics computed from every row, not a sample
SET max_parallel_workers_per_gather = 0;
SET default_statistics_target = 1500;

-- EXPLAIN ANALYZE without what changes between runs: costs, timings, the planner's own buffer usage, and the split of
-- pages between shared buffers (hit) and disk (read), which depends on what earlier queries left in memory
CREATE FUNCTION pg_temp.plan(query text) RETURNS TABLE ("QUERY PLAN" text) LANGUAGE plpgsql AS $$
DECLARE
    line text;
    planning boolean := false;
    pages bigint;
BEGIN
    FOR line IN EXECUTE 'EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF) ' || query LOOP
        IF line = 'Planning:' THEN
            planning := true;
        ELSIF NOT (planning AND line LIKE ' %') THEN
            planning := false;
            IF line ~ 'Buffers: shared ' THEN
                pages := coalesce(substring(line FROM 'hit=(\d+)')::bigint, 0) + coalesce(substring(line FROM 'read=(\d+)')::bigint, 0);
                line := substring(line FROM '^\s*') || 'Buffers: shared hit+read=' || pages;
            END IF;
            "QUERY PLAN" := line;
            RETURN NEXT;
        END IF;
    END LOOP;
END
$$;

-- The planner's row estimate for the top node, next to the actual count
CREATE FUNCTION pg_temp.estimate(query text) RETURNS TABLE (estimated bigint, actual bigint) LANGUAGE plpgsql AS $$
DECLARE
    doc jsonb;
BEGIN
    EXECUTE 'EXPLAIN (ANALYZE, TIMING OFF, SUMMARY OFF, BUFFERS OFF, FORMAT JSON) ' || query INTO doc;
    estimated := (doc->0->'Plan'->>'Plan Rows')::bigint;
    actual := (doc->0->'Plan'->>'Actual Rows')::numeric::bigint;
    RETURN NEXT;
END
$$;
