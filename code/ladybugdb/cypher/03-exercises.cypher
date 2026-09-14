// LadybugDB course, lesson 3: exercise solutions
// Run from code/ladybugdb: lbug < cypher/03-exercises.cypher
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/pages.csv' (HEADER = true);
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true, IGNORE_ERRORS = true);

// Exercise 1: the English pages three clicks away from the home page, per course
MATCH (home:Page {url: '/'})-[e:LINKS_TO* SHORTEST 1..10]->(p:Page)
WHERE p.locale = 'en' AND length(e) = 3
RETURN p.course, count(*) AS pages
ORDER BY pages DESC, p.course;

// Exercise 2: links from one course to another, between English pages
MATCH (a:Page)-[:LINKS_TO]->(b:Page)
WHERE a.locale = 'en' AND b.locale = 'en' AND a.course <> b.course AND a.course <> '' AND b.course <> ''
RETURN a.course AS from_course, b.course AS to_course, count(*) AS links
ORDER BY links DESC, from_course, to_course;

// Exercise 3: two links away from the DuckDB index: walks, pages, and the page reached twice
MATCH (a:Page {url: '/duckdb/'})-[:LINKS_TO*2..2]->(b:Page)
RETURN count(*) AS walks, count(DISTINCT b) AS pages;
MATCH (a:Page {url: '/duckdb/'})-[e:LINKS_TO*2..2]->(b:Page)
WITH b, count(*) AS walks, collect(properties(nodes(e), 'url')[1]) AS through
WHERE walks > 1
RETURN b.url, walks, cast(list_sort(through) AS STRING) AS through;
