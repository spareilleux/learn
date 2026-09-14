-- LadybugDB course, lesson 3: the walks of LINKS_TO*1..4, counted again with a recursive CTE in DuckDB
-- Run from code/ladybugdb: duckdb < sql/03-walks.sql
WITH RECURSIVE
  links AS (
    SELECT l."from" AS source, l."to" AS target
    FROM 'data/links.csv' l
    WHERE l."to" IN (SELECT url FROM 'data/pages.csv')
  ),
  walks(page, length) AS (
    SELECT target, 1 FROM links WHERE source = '/github-actions/'
    UNION ALL
    SELECT links.target, walks.length + 1
    FROM walks JOIN links ON links.source = walks.page
    WHERE walks.length < 4
  )
SELECT length AS links, count(*) AS walks
FROM walks
WHERE page = '/github-actions/07-security/'
GROUP BY length
ORDER BY length;
