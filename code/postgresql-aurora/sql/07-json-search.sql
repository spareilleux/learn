-- Lesson 7: jsonb, its operators, SQL/JSON paths and JSON_TABLE, GIN indexes on documents, full-text search and pg_trgm.
\o /dev/null
\ir schema.sql
\ir explain.sql
\o

-- json keeps the text as it was written; jsonb stores a parsed value: keys sorted, duplicates dropped, the last one kept
SELECT '{"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"}'::json AS json,
       '{"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"}'::jsonb AS jsonb;

-- The GitHub API's job documents, as they were exported: one jsonb value per job
CREATE TABLE ci.job_docs (
    doc jsonb NOT NULL
);
INSERT INTO ci.job_docs
SELECT j FROM jsonb_array_elements(pg_read_file('/course/data/jobs.json')::jsonb) AS j;

-- -> returns jsonb, ->> returns text, #>> follows a path
SELECT doc->>'name' AS name, doc->'labels' AS labels, doc->'labels'->>0 AS first_label,
       doc#>>'{steps,0,name}' AS first_step, jsonb_array_length(doc->'steps') AS steps
FROM ci.job_docs
WHERE (doc->>'run_id')::bigint = 34852867099
ORDER BY name;

-- Containment and existence
SELECT count(*) FILTER (WHERE doc @> '{"steps": [{"conclusion": "failure"}]}') AS with_a_failed_step,
       count(*) FILTER (WHERE doc->'labels' ? 'windows-latest') AS on_windows,
       count(*) FILTER (WHERE doc->'labels' ?| '{macos-latest, windows-latest}') AS on_macos_or_windows
FROM ci.job_docs;

-- An SQL/JSON path: the failed steps of each job
SELECT doc->>'name' AS job, jsonb_path_query(doc, '$.steps[*] ? (@.conclusion == "failure").name') #>> '{}' AS failed_step
FROM ci.job_docs
WHERE doc @? '$.steps[*] ? (@.conclusion == "failure")'
ORDER BY doc->>'completed_at', 1, 2
LIMIT 5;

-- JSON_TABLE turns a document into rows and typed columns, like OPENJSON ... WITH in T-SQL
SELECT s.number, s.name, s.conclusion, s.completed_at - s.started_at AS duration
FROM ci.job_docs,
     JSON_TABLE(doc, '$.steps[*]' COLUMNS (
         number       smallint    PATH '$.number',
         name         text        PATH '$.name',
         conclusion   text        PATH '$.conclusion',
         started_at   timestamptz PATH '$.started_at',
         completed_at timestamptz PATH '$.completed_at')) AS s
WHERE (doc->>'id')::bigint = 104004920113
ORDER BY s.number;

-- Changing a document: || merges, - removes a key, jsonb_set replaces a value at a path
SELECT (doc - 'steps' - 'labels' || '{"rerun": true}') AS summary,
       jsonb_set(doc, '{labels,0}', '"ubuntu-24.04"')->'labels' AS labels
FROM ci.job_docs
WHERE (doc->>'id')::bigint = 104004920113;

-- GIN indexes on documents, on 40 copies of the jobs
INSERT INTO ci.job_docs SELECT doc FROM ci.job_docs, generate_series(2, 40);
VACUUM ANALYZE ci.job_docs;
SELECT count(*) AS documents, pg_size_pretty(pg_total_relation_size('ci.job_docs')) AS size FROM ci.job_docs;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.job_docs WHERE doc @> '{"steps": [{"name": "Compile-fail doctests", "conclusion": "failure"}]}'
$$);
CREATE INDEX job_docs_ops ON ci.job_docs USING gin (doc);
CREATE INDEX job_docs_path_ops ON ci.job_docs USING gin (doc jsonb_path_ops);
SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index WHERE indrelid = 'ci.job_docs'::regclass ORDER BY 1;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.job_docs WHERE doc @> '{"steps": [{"name": "Compile-fail doctests", "conclusion": "failure"}]}'
$$);

-- Full-text search: the prose of two courses of this site, in English, French and Spanish (data/extract_pages.py)
CREATE SCHEMA site;
CREATE TABLE site.pages (
    course text NOT NULL,
    locale text NOT NULL,
    slug   text NOT NULL,
    title  text NOT NULL,
    body   text NOT NULL,
    config regconfig NOT NULL,
    search tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector(config, title), 'A') || setweight(to_tsvector(config, body), 'B')) STORED,
    PRIMARY KEY (course, locale, slug)
);

-- A tsvector holds normalized words, lexemes, with their positions; a text search configuration decides how
SELECT to_tsvector('english', 'Indexes and plans: the planner chose a Bitmap Index Scan') AS english,
       to_tsvector('french', 'Index et plans : le planificateur a choisi un parcours d''index') AS french,
       to_tsvector('simple', 'Indexes and plans') AS simple;

-- websearch_to_tsquery reads a search box's syntax: words, "phrases", or, -excluded
SELECT websearch_to_tsquery('english', 'connection pool -aurora') AS query1,
       websearch_to_tsquery('english', '"index scan" or brin') AS query2;

INSERT INTO site.pages (course, locale, slug, title, body, config)
SELECT p.course, p.locale, p.slug, p.title, p.body,
       CASE p.locale WHEN 'fr' THEN 'french' WHEN 'es' THEN 'spanish' ELSE 'english' END::regconfig
FROM jsonb_to_recordset(pg_read_file('/course/data/pages.json')::jsonb->'pages') AS p(
    course text, locale text, slug text, title text, body text);
CREATE INDEX pages_search ON site.pages USING gin (search);

-- The pages that match, best first: title matches weigh more than body matches
SELECT course, slug, round(ts_rank(search, query)::numeric, 3) AS rank
FROM site.pages, websearch_to_tsquery('english', 'connection pool') AS query
WHERE locale = 'en' AND search @@ query
ORDER BY rank DESC, course, slug
LIMIT 5;

-- ts_headline shows the matching words in context
SELECT slug, regexp_replace(ts_headline('english', body, query, 'MaxFragments=1, MaxWords=12, MinWords=6, StartSel=[, StopSel=]'), '\s+', ' ', 'g') AS excerpt
FROM site.pages, websearch_to_tsquery('english', '"prepared statements"') AS query
WHERE locale = 'en' AND course = 'postgresql-aurora' AND search @@ query
ORDER BY slug;

-- The same search in French finds nothing for a word written without its accent
SELECT count(*) FILTER (WHERE search @@ websearch_to_tsquery('french', 'modélisation')) AS with_accent,
       count(*) FILTER (WHERE search @@ websearch_to_tsquery('french', 'modelisation')) AS without_accent
FROM site.pages WHERE locale = 'fr';

-- unaccent in a configuration of our own removes accents before stemming
CREATE EXTENSION unaccent;
CREATE TEXT SEARCH CONFIGURATION french_unaccent (COPY = french);
ALTER TEXT SEARCH CONFIGURATION french_unaccent
    ALTER MAPPING FOR hword, hword_part, word WITH unaccent, french_stem;
SELECT to_tsvector('french', 'modélisation des données') AS french,
       to_tsvector('french_unaccent', 'modélisation des données') AS french_unaccent;
SELECT count(*) AS without_accent
FROM site.pages
WHERE locale = 'fr'
  AND to_tsvector('french_unaccent', title || ' ' || body) @@ websearch_to_tsquery('french_unaccent', 'modelisation');

-- pg_trgm: similarity between strings, from their three-letter sequences
CREATE EXTENSION pg_trgm;
SELECT show_trgm('Npgsql') AS trigrams;
SELECT DISTINCT package, round(similarity(package, 'mongo driver')::numeric, 2) AS similarity
FROM ga.package_refs
WHERE package % 'mongo driver'
ORDER BY similarity DESC, package;

-- A trigram index serves LIKE and ILIKE with a leading wildcard, which a B-tree can't: the steps of the 12,600 job documents
CREATE TABLE ci.doc_steps AS
SELECT s.name, s.conclusion
FROM ci.job_docs, JSON_TABLE(doc, '$.steps[*]' COLUMNS (name text PATH '$.name', conclusion text PATH '$.conclusion')) AS s;
CREATE INDEX doc_steps_name_trgm ON ci.doc_steps USING gin (name gin_trgm_ops);
VACUUM ANALYZE ci.doc_steps;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.doc_steps WHERE name ILIKE '%doctest%'
$$);
