-- Lesson 8, exercise solutions. The course model is loaded first, without output.
\o /dev/null
\ir schema.sql
\o

-- Exercise 1: a set-returning SQL function, called once per workflow with LATERAL
CREATE FUNCTION ci.slowest_steps(workflow text, n integer)
RETURNS TABLE (job text, step text, duration interval)
LANGUAGE sql STABLE
BEGIN ATOMIC
    SELECT j.name, s.name, s.completed_at - s.started_at
    FROM ci.steps AS s
    JOIN ci.jobs AS j USING (job_id)
    JOIN ci.runs AS r USING (run_id)
    WHERE r.workflow_name = workflow
    ORDER BY s.completed_at - s.started_at DESC, j.name, s.name
    LIMIT n;
END;

SELECT w.workflow_name, slowest.*
FROM (SELECT DISTINCT workflow_name FROM ci.runs) AS w
CROSS JOIN LATERAL ci.slowest_steps(w.workflow_name, 1) AS slowest
ORDER BY slowest.duration DESC, w.workflow_name
LIMIT 5;

-- Exercise 2: a trigger that refuses to lower a pinned version
CREATE FUNCTION ga.version_numbers(version text) RETURNS integer[]
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
BEGIN
    RETURN string_to_array(version, '.')::integer[];
EXCEPTION
    WHEN invalid_text_representation THEN
        RETURN NULL;
END
$$;

CREATE TABLE ga.package_pins (
    package text PRIMARY KEY,
    version text NOT NULL
);

CREATE FUNCTION ga.refuse_downgrade() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF ga.version_numbers(NEW.version) < ga.version_numbers(OLD.version) THEN
        RAISE EXCEPTION '% can''t go from % down to %', NEW.package, OLD.version, NEW.version
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END
$$;
CREATE TRIGGER refuse_downgrade BEFORE UPDATE OF version ON ga.package_pins
    FOR EACH ROW WHEN (OLD.version IS DISTINCT FROM NEW.version) EXECUTE FUNCTION ga.refuse_downgrade();

INSERT INTO ga.package_pins VALUES ('Npgsql', '10.0.3'), ('MongoDB.Driver', '3.5.0');
UPDATE ga.package_pins SET version = '9.0.4' WHERE package = 'Npgsql';
UPDATE ga.package_pins SET version = '3.10.0' WHERE package = 'MongoDB.Driver';
SELECT * FROM ga.package_pins ORDER BY package;

-- Exercise 3: a procedure that fails after a COMMIT: what it committed stays
CREATE TABLE ci.counters (name text PRIMARY KEY, value bigint NOT NULL);
CREATE PROCEDURE ci.count_twice()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO ci.counters VALUES ('runs', (SELECT count(*) FROM ci.runs));
    COMMIT;
    INSERT INTO ci.counters VALUES ('runs', 0);
END
$$;
CALL ci.count_twice();
SELECT * FROM ci.counters ORDER BY name;
