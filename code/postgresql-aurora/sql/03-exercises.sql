-- Lesson 3, exercise solutions. The course model is loaded first, without output.
\o /dev/null
\ir schema.sql
\o

-- Exercise 1: do GA's guitar voicings play the pitch classes their chord declares?
-- Standard tuning, from low E to high E: E A D G B E = 4 9 2 7 11 4; -1 is a string not played.
WITH played AS (
    SELECT c.name, array_agg(DISTINCT (t.open_string + f.fret) % 12 ORDER BY (t.open_string + f.fret) % 12) AS voicing_pcs
    FROM ga.iconic_chords AS c
    CROSS JOIN LATERAL unnest(c.guitar_voicing) WITH ORDINALITY AS f(fret, string)
    JOIN unnest('{4,9,2,7,11,4}'::int[]) WITH ORDINALITY AS t(open_string, string) USING (string)
    WHERE f.fret >= 0
    GROUP BY c.name
)
SELECT p.name,
       ARRAY(SELECT unnest(c.pitch_classes) ORDER BY 1) AS declared,
       p.voicing_pcs AS played,
       ARRAY(SELECT unnest(c.pitch_classes) EXCEPT SELECT unnest(p.voicing_pcs) ORDER BY 1) AS missing,
       ARRAY(SELECT unnest(p.voicing_pcs) EXCEPT SELECT unnest(c.pitch_classes) ORDER BY 1) AS extra
FROM played AS p
JOIN ga.iconic_chords AS c USING (name)
ORDER BY p.name;

-- Exercise 2: the projects that depend on GA.Data.MongoDB, directly or not
WITH RECURSIVE dependents AS (
    SELECT from_path, 1 AS depth
    FROM ga.project_refs
    WHERE to_path = 'GA.Data.MongoDB/GA.Data.MongoDB.csproj'
    UNION
    SELECT r.from_path, d.depth + 1
    FROM dependents AS d
    JOIN ga.project_refs AS r ON r.to_path = d.from_path
)
SELECT min(depth) AS depth, from_path AS project
FROM dependents
GROUP BY from_path
ORDER BY depth, project;

-- Exercise 3: after each failed run, how long until the same workflow succeeded again
SELECT f.workflow_name, f.started_at AS failed_at, next_success.started_at - f.started_at AS time_to_green
FROM ci.runs AS f
LEFT JOIN LATERAL (
    SELECT s.started_at
    FROM ci.runs AS s
    WHERE s.workflow_name = f.workflow_name AND s.conclusion = 'success' AND s.started_at > f.started_at
    ORDER BY s.started_at
    LIMIT 1
) AS next_success ON true
WHERE f.conclusion = 'failure'
ORDER BY time_to_green DESC NULLS FIRST, f.workflow_name, f.started_at;
