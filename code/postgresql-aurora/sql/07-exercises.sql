-- Lesson 7, exercise solutions. The course model is loaded first, without output.
\o /dev/null
\ir schema.sql
\o

-- Exercise 1: the steps that failed, straight from the job documents, checked against the flattened ci.steps table
CREATE TABLE ci.job_docs AS
SELECT j AS doc FROM jsonb_array_elements(pg_read_file('/course/data/jobs.json')::jsonb) AS j;

SELECT s.name AS step, count(*) AS failures
FROM ci.job_docs,
     JSON_TABLE(doc, '$.steps[*] ? (@.conclusion == "failure")' COLUMNS (name text PATH '$.name')) AS s
GROUP BY s.name
ORDER BY failures DESC, step;

SELECT count(*) AS differences FROM (
    (SELECT (doc->>'id')::bigint, s.number, s.name
     FROM ci.job_docs, JSON_TABLE(doc, '$.steps[*]' COLUMNS (number smallint PATH '$.number', name text PATH '$.name')) AS s
     EXCEPT
     SELECT job_id, number, name FROM ci.steps)
    UNION ALL
    (SELECT job_id, number, name FROM ci.steps
     EXCEPT
     SELECT (doc->>'id')::bigint, s.number, s.name
     FROM ci.job_docs, JSON_TABLE(doc, '$.steps[*]' COLUMNS (number smallint PATH '$.number', name text PATH '$.name')) AS s)
) AS d;

-- Exercise 2: the Spanish pages about execution plans
CREATE TABLE site_pages AS
SELECT p.* FROM jsonb_to_recordset(pg_read_file('/course/data/pages.json')::jsonb->'pages') AS p(
    course text, locale text, slug text, title text, body text);

SELECT course, slug, round(ts_rank(to_tsvector('spanish', title || ' ' || body), query)::numeric, 3) AS rank
FROM site_pages, websearch_to_tsquery('spanish', '"planes de ejecución"') AS query
WHERE locale = 'es' AND to_tsvector('spanish', title || ' ' || body) @@ query
ORDER BY rank DESC, course, slug;

SELECT websearch_to_tsquery('spanish', '"planes de ejecución"') AS spanish,
       websearch_to_tsquery('english', '"planes de ejecución"') AS english;

-- Exercise 3: a search box receives "dependncy injection", with a typo
CREATE EXTENSION pg_trgm;
CREATE TABLE packages AS SELECT DISTINCT package FROM ga.package_refs;
SELECT package, round(similarity(package, 'dependncy injection')::numeric, 2) AS similarity
FROM packages
WHERE package % 'dependncy injection'
ORDER BY similarity DESC, package;

SELECT package, round(word_similarity('dependncy injection', package)::numeric, 2) AS word_similarity
FROM packages
WHERE 'dependncy injection' <% package
ORDER BY word_similarity DESC, package;
