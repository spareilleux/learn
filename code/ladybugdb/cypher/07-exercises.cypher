// LadybugDB course, lesson 7: exercise solutions
// Run from code/ladybugdb with the 0.19.1 CLI: lbug19 < cypher/07-exercises.cypher
LOAD algo;
LOAD fts;
CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING, language STRING, sdk STRING, frameworks STRING, in_solution BOOLEAN);
CREATE REL TABLE REFERENCES(FROM Project TO Project);
COPY Project FROM 'data/ga/projects.csv' (HEADER = true);
COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL project_graph('Deps', ['Project'], ['REFERENCES']);

// Exercise 1: why GA.Core ranks above GA.Domain.Services with fewer references
// Keep the rank in a property, look at the projects that reference GA.Core, then recompute both ranks
ALTER TABLE Project ADD rank DOUBLE;
CALL page_rank('Deps') WITH node, rank SET node.rank = rank RETURN count(*) AS ranked;
MATCH (a:Project)-[:REFERENCES]->(b:Project {name: 'GA.Core'})
RETURN a.name, round(a.rank, 4) AS rank, COUNT { MATCH (a)-[:REFERENCES]->(:Project) } AS out_degree
ORDER BY rank DESC, a.name
LIMIT 3;
MATCH (p:Project)
WITH count(*) AS n
MATCH (a:Project)-[:REFERENCES]->(b:Project)
WHERE b.name IN ['GA.Core', 'GA.Domain.Services']
WITH n, b, a, COUNT { MATCH (a)-[:REFERENCES]->(:Project) } AS out_degree
// n + sum(...) in one expression fails when n is not also returned on its own: sum first, compute in the next clause
WITH n, b, count(*) AS referenced_by, sum(a.rank / out_degree) AS received
RETURN b.name, referenced_by, round(b.rank, 4) AS rank, round((1 - 0.85) / n + 0.85 * received, 4) AS recomputed
ORDER BY rank DESC;
MATCH (p:Project)
RETURN round(sum(p.rank), 4) AS total, round(min(p.rank), 6) AS lowest;

// Exercise 2: PageRank on the English pages of the site, next to the number of links they receive
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/pages.csv' (HEADER = true);
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL project_graph('Site', {'Page': 'n.locale = "en"'}, ['LINKS_TO']);
CALL page_rank('Site')
WITH node, rank
RETURN node.url, round(rank, 4) AS rank, COUNT { MATCH (:Page {locale: 'en'})-[:LINKS_TO]->(node) } AS linked_from
ORDER BY rank DESC, node.url
LIMIT 6;
// The installation page ranks high with two links: who links to it?
MATCH (a:Page)-[:LINKS_TO]->(:Page {url: '/wsl-containers/02-installation/'})
WHERE a.locale = 'en'
RETURN a.url, COUNT { MATCH (:Page {locale: 'en'})-[:LINKS_TO]->(a) } AS linked_from
ORDER BY a.url;

// Exercise 3: the English pages whose title mentions Java, by the number of links they receive
CALL CREATE_FTS_INDEX('Page', 'titles', ['title']);
CALL QUERY_FTS_INDEX('Page', 'titles', 'java')
WITH node AS p
WHERE p.locale = 'en'
RETURN p.url, p.title, COUNT { MATCH (:Page)-[:LINKS_TO]->(p) } AS linked_from
ORDER BY linked_from DESC, p.url;
