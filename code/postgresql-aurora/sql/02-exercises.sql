-- Lesson 2, exercise solutions. The course model is loaded first, without output.
\o /dev/null
\ir schema.sql
\o

-- Exercise 1: the chords that contain both E (4) and B (11), then a pitch class out of range
SELECT name, pitch_classes, cardinality(pitch_classes) AS notes, alternate_names[1] AS first_alias
FROM ga.iconic_chords
WHERE pitch_classes @> '{4,11}'
ORDER BY name;
UPDATE ga.iconic_chords SET pitch_classes = pitch_classes || 12::smallint WHERE name = 'Power Chord';

-- Exercise 2: runs per calendar day, in UTC and on a Toronto wall clock
SELECT started_at::date AS utc_day,
       (started_at AT TIME ZONE 'America/Toronto')::date AS toronto_day,
       count(*) AS runs
FROM ci.runs
GROUP BY 1, 2
ORDER BY 1, 2;

-- Exercise 3: an index on the virtual generated column
CREATE INDEX ON ci.jobs (duration);
CREATE INDEX jobs_duration_idx ON ci.jobs ((completed_at - started_at));
EXPLAIN (COSTS OFF) SELECT job_id FROM ci.jobs WHERE completed_at - started_at > interval '4 minutes';
