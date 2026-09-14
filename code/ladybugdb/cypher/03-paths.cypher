// LadybugDB course, lesson 3: patterns, OPTIONAL MATCH, subqueries, variable-length paths and shortest paths
// Run from code/ladybugdb: lbug < cypher/03-paths.cypher
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/pages.csv' (HEADER = true);
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true, IGNORE_ERRORS = true);

// Two hops: what the home page's links link to
MATCH (home:Page {url: '/'})-[:LINKS_TO]->(course:Page)-[:LINKS_TO]->(lesson:Page)
WHERE course.course = 'duckdb'
RETURN course.url, lesson.url
ORDER BY lesson.url;

// OPTIONAL MATCH keeps the pages without outgoing links, like a LEFT JOIN
MATCH (p:Page)
WHERE p.locale = 'en' AND p.course = 'github-actions'
OPTIONAL MATCH (p)-[:LINKS_TO]->(target:Page)
RETURN p.url, count(target) AS links
ORDER BY links, p.url
LIMIT 4;

// A COUNT subquery in a filter: the most linked-to English pages
MATCH (p:Page)
WHERE p.locale = 'en' AND COUNT { MATCH (:Page)-[:LINKS_TO]->(p) } >= 5
RETURN p.url, COUNT { MATCH (:Page)-[:LINKS_TO]->(p) } AS incoming
ORDER BY incoming DESC, p.url;

// Variable length: every walk of 1 to 4 links from the GitHub Actions index to lesson 7
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS walks
ORDER BY links;

// Walks may repeat pages; TRAIL forbids repeating a link, ACYCLIC forbids repeating a page
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO* TRAIL 1..4]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS trails
ORDER BY links;
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO* ACYCLIC 1..4]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS acyclic_paths
ORDER BY links;

// Shortest paths: how many clicks from the home page to each English page
MATCH (home:Page {url: '/'})-[e:LINKS_TO* SHORTEST 1..10]->(p:Page)
WHERE p.locale = 'en'
RETURN length(e) AS clicks, count(*) AS pages
ORDER BY clicks;

// The pages the home page can't reach at all
MATCH (p:Page)
WHERE p.locale = 'en' AND p.url <> '/'
  AND NOT EXISTS { MATCH (:Page {url: '/'})-[:LINKS_TO* SHORTEST 1..10]->(p) }
RETURN p.url
ORDER BY p.url;

// The pages on the way: one shortest path, then all of them
MATCH (a:Page {url: '/github-actions/09-debugging/'})-[e:LINKS_TO* SHORTEST 1..10]->(b:Page {url: '/github-actions/02-build-and-test/'})
RETURN length(e) AS links, size(nodes(e)) AS pages_between;
MATCH (a:Page {url: '/github-actions/09-debugging/'})-[e:LINKS_TO* ALL SHORTEST 1..10]->(b:Page {url: '/github-actions/02-build-and-test/'})
RETURN cast(properties(nodes(e), 'url') AS STRING) AS through
ORDER BY through;

// Following the links backwards too: no arrow in the pattern
MATCH (a:Page {url: '/duckdb/04-files/'})-[e:LINKS_TO* SHORTEST 1..10]->(b:Page {url: '/rust-for-csharp-java/'})
RETURN length(e) AS links;
MATCH (a:Page {url: '/duckdb/04-files/'})-[e:LINKS_TO* SHORTEST 1..10]-(b:Page {url: '/rust-for-csharp-java/'})
RETURN length(e) AS links;

// A filter on every page in between: walks that don't go through lesson 4
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4 (r, n | WHERE n.url <> '/github-actions/04-expressions-and-outputs/')]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS walks
ORDER BY links;

// The upper bound can't exceed 30 by default
MATCH (a:Page {url: '/'})-[e:LINKS_TO*1..50]->(b:Page {url: '/duckdb/journal/'})
RETURN count(*);
