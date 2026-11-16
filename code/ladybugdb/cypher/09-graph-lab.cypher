// LadybugDB course, lesson 9: a graph lab on invented pages, one case at a time
// Run from code/ladybugdb: lbug < cypher/09-graph-lab.cypher
// The predictions were written before the first run: data/lab/preregistration.md

// T. Tracer: three pages, two links, and the known path from French to English
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/lab/tracer-pages.csv' (HEADER = true);
COPY LINKS_TO FROM 'data/lab/tracer-links.csv' (HEADER = true);
MATCH (a:Page {url: '/fr/lab/intro/'})-[e:LINKS_TO*1..3]->(b:Page)
WHERE b.locale = 'en'
RETURN length(e) AS links, properties(nodes(e), 'url') AS between, b.url AS reached;

// 1. A missing endpoint: the strict COPY fails, and what is left afterwards is observed, not assumed
CALL threads = 1;
COPY LINKS_TO FROM 'data/lab/links-missing.csv' (HEADER = true);
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
MATCH (p:Page {url: '/lab/paths/'}) RETURN count(*) AS found_by_key;
// Lenient loading on purpose: the good rows go in, the bad ones become warnings
COPY LINKS_TO FROM 'data/lab/links-missing.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL show_warnings() RETURN message, line_number;
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;

// 2. Missing translations: siblings share a content identity, the English URL; titles are not identities
DROP TABLE LINKS_TO;
DROP TABLE Page;
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
CREATE REL TABLE REQUIRES(FROM Page TO Page);
COPY Page FROM 'data/lab/translations-pages.csv' (HEADER = true);
MATCH (en:Page) WHERE en.locale = 'en'
UNWIND ['es', 'fr'] AS locale
WITH en, locale WHERE NOT EXISTS { MATCH (t:Page) WHERE t.url = '/' + locale + en.url }
RETURN en.url AS english_page, locale AS missing ORDER BY english_page, missing;
// Negative control: the two complete groups report nothing
MATCH (en:Page) WHERE en.url IN ['/lab/intro/', '/lab/cycles/']
UNWIND ['es', 'fr'] AS locale
WITH en, locale WHERE NOT EXISTS { MATCH (t:Page) WHERE t.url = '/' + locale + en.url }
RETURN count(*) AS missing_in_complete_groups;
// The wrong identity: matching titles reports translations that exist under another title
MATCH (en:Page) WHERE en.locale = 'en'
UNWIND ['es', 'fr'] AS locale
WITH en, locale WHERE NOT EXISTS { MATCH (t:Page) WHERE t.locale = locale AND t.title = en.title }
RETURN en.url AS english_page, locale AS missing ORDER BY english_page, missing;

// 3. Prerequisite cycles, kept apart from navigation: REQUIRES is its own relationship table
COPY LINKS_TO FROM 'data/lab/navigation-links.csv' (HEADER = true);
COPY REQUIRES FROM 'data/lab/requires-dag.csv' (HEADER = true);
// 3 pages carry REQUIRES edges, so a bound of 3 is complete: no closed trail proves this graph acyclic
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a) RETURN count(*) AS prerequisite_cycles;
// Navigation has a cycle, which is not a prerequisite cycle
MATCH (a:Page)-[e:LINKS_TO* TRAIL 1..3]->(a) RETURN a.url AS page, length(e) AS links ORDER BY page;

// 4. Bounded reachability, typed: prerequisites and navigation answer different questions
MATCH (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* SHORTEST 1..2]->(b:Page) RETURN b.url AS prerequisite, length(e) AS depth ORDER BY prerequisite;
MATCH (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* SHORTEST 1..1]->(b:Page) RETURN b.url AS prerequisite, length(e) AS depth ORDER BY prerequisite;
MATCH (a:Page {url: '/lab/intro/'})-[e:LINKS_TO* SHORTEST 1..2]->(b:Page) RETURN b.url AS reached, length(e) AS clicks ORDER BY reached;

// 3, continued. The cycle file adds /lab/intro/ REQUIRES /lab/cycles/; each closed trail is a witness
DROP TABLE REQUIRES;
CREATE REL TABLE REQUIRES(FROM Page TO Page);
COPY REQUIRES FROM 'data/lab/requires-cycle.csv' (HEADER = true);
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a)
RETURN a.url AS page, length(e) AS length, properties(nodes(e), 'url') AS through ORDER BY page;
// In 0.20.4 a closed trail lists its pages against the arrows; an open path lists them with the arrows
MATCH p = (a:Page {url: '/lab/cycles/'})-[e:REQUIRES*2..2]->(b:Page) RETURN properties(nodes(p), 'url') AS open_path;
MATCH p = (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* TRAIL 3..3]->(a) RETURN properties(nodes(p), 'url') AS closed_path;

// A 6-cycle: a bound of 5 finds nothing, which proves nothing; a bound of 6 finds it
COPY Page FROM 'data/lab/chain-pages.csv' (HEADER = true);
COPY REQUIRES FROM 'data/lab/requires-long.csv' (HEADER = true);
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..5]->(a) WHERE a.url STARTS WITH '/lab/s' RETURN count(*) AS closed_trails;
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..6]->(a) WHERE a.url STARTS WITH '/lab/s'
RETURN count(*) AS closed_trails, min(length(e)) AS min_length, max(length(e)) AS max_length;
MATCH (a:Page {url: '/lab/s1/'})-[e:REQUIRES* SHORTEST 1..3]->(b:Page) RETURN b.url AS prerequisite, length(e) AS depth ORDER BY prerequisite;
