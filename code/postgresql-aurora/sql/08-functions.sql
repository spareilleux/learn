-- Lesson 8: SQL and PL/pgSQL functions, procedures and transaction control, triggers with transition tables, trusted extensions.
-- pgvector, which the official image doesn't include, is in 08-pgvector.sql.
\o /dev/null
\ir schema.sql
\o

-- A SQL function with a standard body: parsed when it is created, and its dependencies recorded
CREATE FUNCTION ga.played_pitch_classes(voicing smallint[]) RETURNS smallint[]
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
    SELECT array_agg(DISTINCT (fret + (ARRAY[4, 9, 2, 7, 11, 4])[string]) % 12 ORDER BY (fret + (ARRAY[4, 9, 2, 7, 11, 4])[string]) % 12)
    FROM unnest(voicing) WITH ORDINALITY AS v(fret, string)
    WHERE fret >= 0;
END;

SELECT name, guitar_voicing, ga.played_pitch_classes(guitar_voicing) AS played
FROM ga.iconic_chords
WHERE guitar_voicing IS NOT NULL
ORDER BY chord_id;

-- A standard body is stored parsed, with its dependencies: a column it reads can't be dropped
CREATE FUNCTION ga.voicing_of(chord text) RETURNS smallint[]
LANGUAGE sql STABLE
BEGIN ATOMIC
    SELECT guitar_voicing FROM ga.iconic_chords WHERE name = chord;
END;
ALTER TABLE ga.iconic_chords DROP COLUMN guitar_voicing;

-- PL/pgSQL: variables, loops, and an exception handler that turns a failed cast into NULL
CREATE FUNCTION ga.version_numbers(version text) RETURNS integer[]
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
    part text;
    numbers integer[] := '{}';
BEGIN
    FOREACH part IN ARRAY string_to_array(version, '.') LOOP
        numbers := numbers || part::integer;
    END LOOP;
    RETURN numbers;
EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE NOTICE 'not a numeric version: %', version;
        RETURN NULL;
END
$$;

SELECT v AS version, ga.version_numbers(v) AS numbers
FROM unnest(ARRAY['10.0.5', '9.0.4', '9.4.0-preview.1.25207.5']) AS v;

-- Lesson 3's highest version per package, with the function
SELECT package, (array_agg(version ORDER BY ga.version_numbers(version) DESC NULLS LAST))[1] AS highest
FROM ga.package_refs
WHERE package IN ('Microsoft.Extensions.Hosting', 'Microsoft.ML.Tokenizers', 'ModelContextProtocol')
GROUP BY package
ORDER BY package;

-- A procedure can commit: CALL archives failed runs in batches, one transaction per batch
CREATE TABLE ci.archived_runs (LIKE ci.runs);
CREATE PROCEDURE ci.archive_failed_runs(batch_size integer)
LANGUAGE plpgsql
AS $$
DECLARE
    moved integer;
    batches integer := 0;
BEGIN
    LOOP
        WITH batch AS (
            SELECT run_id FROM ci.runs
            WHERE conclusion = 'failure' AND run_id NOT IN (SELECT run_id FROM ci.archived_runs)
            ORDER BY run_id
            LIMIT batch_size
        )
        INSERT INTO ci.archived_runs SELECT r.* FROM ci.runs AS r JOIN batch USING (run_id);
        GET DIAGNOSTICS moved = ROW_COUNT;
        EXIT WHEN moved = 0;
        batches := batches + 1;
        COMMIT;
        RAISE NOTICE 'batch %: % runs', batches, moved;
    END LOOP;
END
$$;
CALL ci.archive_failed_runs(5);
SELECT count(*) AS archived FROM ci.archived_runs;

-- Inside an explicit transaction block, the procedure can't commit
TRUNCATE ci.archived_runs;
BEGIN;
CALL ci.archive_failed_runs(5);
ROLLBACK;

-- Triggers: package pins that must name an exact version, and an audit of every change
CREATE TABLE ga.package_pins (
    package text PRIMARY KEY,
    version text NOT NULL
);
CREATE TABLE ga.package_pins_audit (
    change_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    operation  text NOT NULL,
    package    text NOT NULL,
    old_version text,
    new_version text
);

-- A row-level BEFORE trigger can change the row or reject it
CREATE FUNCTION ga.check_pin() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.version := trim(NEW.version);
    IF ga.version_numbers(NEW.version) IS NULL THEN
        RAISE EXCEPTION 'version % of % is not an exact numeric version', NEW.version, NEW.package
            USING ERRCODE = 'check_violation', HINT = 'Pin a released version, such as 10.0.5.';
    END IF;
    RETURN NEW;
END
$$;
CREATE TRIGGER check_pin BEFORE INSERT OR UPDATE ON ga.package_pins
    FOR EACH ROW EXECUTE FUNCTION ga.check_pin();

-- A statement-level AFTER trigger sees every changed row at once, in transition tables, like inserted and deleted in T-SQL
CREATE FUNCTION ga.audit_pins() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO ga.package_pins_audit (operation, package, new_version)
        SELECT TG_OP, package, version FROM new_rows ORDER BY package;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO ga.package_pins_audit (operation, package, old_version, new_version)
        SELECT TG_OP, o.package, o.version, n.version
        FROM old_rows AS o JOIN new_rows AS n USING (package)
        WHERE o.version IS DISTINCT FROM n.version
        ORDER BY o.package;
    ELSE
        INSERT INTO ga.package_pins_audit (operation, package, old_version)
        SELECT TG_OP, package, version FROM old_rows ORDER BY package;
    END IF;
    RETURN NULL;
END
$$;
CREATE TRIGGER audit_pins_insert AFTER INSERT ON ga.package_pins
    REFERENCING NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION ga.audit_pins();
CREATE TRIGGER audit_pins_update AFTER UPDATE ON ga.package_pins
    REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows FOR EACH STATEMENT EXECUTE FUNCTION ga.audit_pins();
CREATE TRIGGER audit_pins_delete AFTER DELETE ON ga.package_pins
    REFERENCING OLD TABLE AS old_rows FOR EACH STATEMENT EXECUTE FUNCTION ga.audit_pins();

INSERT INTO ga.package_pins VALUES ('Npgsql', ' 10.0.3 '), ('MongoDB.Driver', '3.5.0'), ('OpenTelemetry', '1.12.0');
INSERT INTO ga.package_pins VALUES ('Microsoft.Extensions.AI', '9.4.0-preview.1.25207.5');
UPDATE ga.package_pins SET version = CASE package WHEN 'MongoDB.Driver' THEN '3.6.0' ELSE version END;
DELETE FROM ga.package_pins WHERE package = 'OpenTelemetry';
SELECT * FROM ga.package_pins ORDER BY package;
SELECT * FROM ga.package_pins_audit ORDER BY change_id;

-- Extensions: some are trusted, and a role with CREATE on the database can install them without being a superuser
SELECT v.name, v.version, v.trusted
FROM pg_available_extension_versions AS v
JOIN pg_available_extensions AS e ON e.name = v.name AND e.default_version = v.version
WHERE v.name IN ('pg_trgm', 'unaccent', 'pgcrypto', 'hstore', 'pageinspect', 'pg_stat_statements', 'postgres_fdw', 'plpgsql')
ORDER BY v.name;

CREATE ROLE app LOGIN;
GRANT CREATE ON DATABASE learn TO app;
SET ROLE app;
CREATE EXTENSION pg_trgm;
CREATE EXTENSION pageinspect;
RESET ROLE;
SELECT extname, extowner::regrole AS owner, extversion FROM pg_extension ORDER BY extname;
