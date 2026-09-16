-- Lesson 8, pgvector exercise solutions, on the pgvector image. The course model is loaded first, without output.
\o /dev/null
\ir schema.sql
\o
CREATE EXTENSION vector;

-- Exercise 4: the interval-class vector, which a transposition doesn't change
CREATE FUNCTION ga.interval_class_vector(pitch_classes smallint[]) RETURNS vector(6)
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
    SELECT array_agg((SELECT count(*)
                      FROM unnest(pitch_classes) AS a, unnest(pitch_classes) AS b
                      WHERE a < b AND least((b - a) % 12, (a - b + 12) % 12) = ic)::int ORDER BY ic)::vector(6)
    FROM generate_series(1, 6) AS ic;
END;

SELECT name, theoretical_name, ga.interval_class_vector(pitch_classes::smallint[]) AS icv
FROM ga.iconic_chords
ORDER BY chord_id;

-- Chords with the same intervals: distance 0, whatever their root
SELECT a.name, a.theoretical_name, b.name AS same_intervals_as, b.theoretical_name AS as_chord,
       a.pitch_classes = b.pitch_classes AS same_notes
FROM ga.iconic_chords AS a
JOIN ga.iconic_chords AS b
  ON a.chord_id < b.chord_id
 AND ga.interval_class_vector(a.pitch_classes::smallint[]) <-> ga.interval_class_vector(b.pitch_classes::smallint[]) = 0
ORDER BY a.chord_id, b.chord_id;
