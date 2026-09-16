-- Lesson 8: pgvector, on the image that adds it to the same PostgreSQL (PG_IMAGE=pgvector/pgvector:0.8.6-pg18-trixie).
\o /dev/null
\ir schema.sql
\o

CREATE EXTENSION vector;
SELECT extversion FROM pg_extension WHERE extname = 'vector';

-- A vector is a list of float4 values with a fixed number of dimensions; <-> is the Euclidean distance,
-- <=> the cosine distance, <#> the negative inner product
SELECT '[1,0,0,1]'::vector AS v,
       '[1,0,0,1]'::vector <-> '[1,1,0,0]' AS l2,
       '[1,0,0,1]'::vector <=> '[1,1,0,0]' AS cosine,
       '[1,0,0,1]'::vector <#> '[1,1,0,0]' AS negative_inner_product;
SELECT '[1,2,3]'::vector <-> '[1,2]';

-- A chord as a 12-dimension vector: 1 for each pitch class it contains, from C (0) to B (11)
CREATE FUNCTION ga.pitch_class_vector(pitch_classes smallint[]) RETURNS vector(12)
LANGUAGE sql IMMUTABLE STRICT
BEGIN ATOMIC
    SELECT array_agg((pc = ANY(pitch_classes))::int ORDER BY pc)::vector(12)
    FROM generate_series(0, 11) AS pc;
END;

ALTER TABLE ga.iconic_chords
    ADD COLUMN profile vector(12) GENERATED ALWAYS AS (ga.pitch_class_vector(pitch_classes::smallint[])) STORED;
SELECT name, pitch_classes, profile FROM ga.iconic_chords ORDER BY chord_id LIMIT 3;

-- The chords closest to the Hendrix chord: the inner product of two such vectors counts their common notes
SELECT c.name, c.theoretical_name,
       round((c.profile <=> h.profile)::numeric, 3) AS cosine_distance,
       -(c.profile <#> h.profile) AS common_notes
FROM ga.iconic_chords AS c, ga.iconic_chords AS h
WHERE h.name = 'Hendrix Chord' AND c.chord_id <> h.chord_id
ORDER BY c.profile <=> h.profile, c.name
LIMIT 5;

-- An HNSW index on every set of pitch classes: 4,095 non-empty sets
CREATE TABLE ga.pitch_class_sets (
    set_id        integer PRIMARY KEY,
    pitch_classes smallint[] NOT NULL,
    profile       vector(12) NOT NULL
);
INSERT INTO ga.pitch_class_sets
SELECT s, p.pitch_classes, ga.pitch_class_vector(p.pitch_classes)
FROM generate_series(1, 4095) AS s,
     LATERAL (SELECT array_agg(pc::smallint ORDER BY pc) AS pitch_classes
              FROM generate_series(0, 11) AS pc WHERE s & (1 << pc) <> 0) AS p;
CREATE INDEX pitch_class_sets_profile ON ga.pitch_class_sets USING hnsw (profile vector_cosine_ops);
ANALYZE ga.pitch_class_sets;

-- ORDER BY distance LIMIT uses the index; the operator must match the index's operator class
EXPLAIN (COSTS OFF)
SELECT set_id FROM ga.pitch_class_sets ORDER BY profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]' LIMIT 5;
EXPLAIN (COSTS OFF)
SELECT set_id FROM ga.pitch_class_sets ORDER BY profile <-> '[0,0,1,0,1,0,0,1,1,0,0,1]' LIMIT 5;

-- On 4,095 rows a filtered query reads the table; without that choice, a filter applies to what the index returns:
-- the hnsw.ef_search nearest rows (40 by default), none of which is a triad here
SET enable_seqscan = off;
EXPLAIN (COSTS OFF)
SELECT set_id FROM ga.pitch_class_sets
WHERE cardinality(pitch_classes) = 3
ORDER BY profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]'
LIMIT 10;
SELECT count(*) AS triads
FROM (SELECT set_id FROM ga.pitch_class_sets
      WHERE cardinality(pitch_classes) = 3
      ORDER BY profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]'
      LIMIT 10) AS nearest;

-- Iterative index scans (pgvector 0.8) keep reading the index until enough rows pass the filter
SET hnsw.iterative_scan = strict_order;
SELECT pitch_classes, distance
FROM (SELECT pitch_classes, round((profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]')::numeric, 3) AS distance
      FROM ga.pitch_class_sets
      WHERE cardinality(pitch_classes) = 3
      ORDER BY profile <=> '[0,0,1,0,1,0,0,1,1,0,0,1]'
      LIMIT 10) AS nearest
ORDER BY distance, pitch_classes;
RESET hnsw.iterative_scan;
RESET enable_seqscan;
