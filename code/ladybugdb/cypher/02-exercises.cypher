// LadybugDB course, lesson 2: exercise solutions
// Run from code/ladybugdb: lbug < cypher/02-exercises.cypher
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
CREATE NODE TABLE Domain(name STRING PRIMARY KEY);
CREATE REL TABLE CITES(FROM Page TO Domain, links INT64);
COPY Page FROM 'data/pages.csv' (HEADER = true);
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true, IGNORE_ERRORS = true);
COPY Domain FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN DISTINCT domain);
COPY CITES FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN `from`, domain, count(*));

// Exercise 1: English pages without a French page, per course
MATCH (en:Page)
WHERE en.locale = 'en' AND NOT EXISTS { MATCH (fr:Page) WHERE fr.url = '/fr' + en.url }
RETURN en.course, count(*) AS pages
ORDER BY pages DESC, en.course;

// Exercise 2: the links without an anchor
MATCH ()-[l:LINKS_TO]->()
RETURN l.anchor IS NULL AS no_anchor, l.anchor = '' AS empty_anchor, count(*) AS links
ORDER BY no_anchor;

// Exercise 3: the domains cited by the most English courses
MATCH (p:Page)-[:CITES]->(d:Domain)
WHERE p.locale = 'en'
RETURN d.name AS domain, count(DISTINCT p.course) AS courses
ORDER BY courses DESC, domain
LIMIT 5;
