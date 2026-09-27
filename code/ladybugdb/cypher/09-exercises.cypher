// LadybugDB course, lesson 9: exercise solutions
// Run from code/ladybugdb: lbug < cypher/09-exercises.cypher

CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE REQUIRES(FROM Page TO Page);
COPY Page FROM 'data/lab/translations-pages.csv' (HEADER = true);
COPY REQUIRES FROM 'data/lab/requires-cycle.csv' (HEADER = true);

// 1. Which pages of a prerequisite cycle have no Spanish sibling?
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a)
WHERE a.locale = 'en' AND NOT EXISTS { MATCH (t:Page) WHERE t.url = '/es' + a.url }
RETURN DISTINCT a.url AS page;
