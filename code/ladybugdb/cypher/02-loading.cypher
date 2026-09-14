// LadybugDB course, lesson 2: LOAD FROM, COPY FROM files and subqueries, and links to missing pages
// Run from code/ladybugdb: lbug < cypher/02-loading.cypher

// Looking at a file before loading it
LOAD FROM 'data/pages.csv' (HEADER = true) RETURN * ORDER BY url LIMIT 3;
LOAD FROM 'data/pages.csv' (HEADER = true) RETURN locale, count(*) AS pages ORDER BY locale;

CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/pages.csv' (HEADER = true);

// A relationship needs both of its nodes: the first missing page stops the whole COPY
// Which page is found first depends on the threads reading the file: one thread makes the error reproducible
CALL threads = 1;
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true);
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;

// IGNORE_ERRORS skips the bad rows and keeps them as warnings
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL show_warnings() RETURN count(*) AS warnings;
CALL show_warnings() RETURN message, file_path, line_number ORDER BY line_number LIMIT 2;

// split_part skips the empty string before a leading separator: part 1 of '/es/streeling/' is 'es'
RETURN split_part('/es/streeling/', '/', 1) AS part_1, split_part('/es/streeling/', '/', 2) AS part_2;
CALL show_warnings()
WITH split_part(message, 'value ', 2) AS missing
RETURN split_part(missing, '/', 1) AS locale, split_part(missing, '/', 2) AS course, count(*) AS links
ORDER BY locale, course;

// The pages a French link points to, when only the English page exists
LOAD FROM 'data/links.csv' (HEADER = true)
WITH `from`, `to`
WHERE `to` STARTS WITH '/fr/' AND NOT EXISTS { MATCH (p:Page) WHERE p.url = `to` }
MATCH (en:Page) WHERE en.url = substring(`to`, 4, size(`to`))
RETURN DISTINCT en.url AS english_page
ORDER BY english_page;

// Node tables from a subquery: one Domain per external site, and how often each page cites it
CREATE NODE TABLE Domain(name STRING PRIMARY KEY);
CREATE REL TABLE CITES(FROM Page TO Domain, links INT64);
COPY Domain FROM (LOAD FROM 'data/external_links.csv' (HEADER = true) RETURN DISTINCT domain);

// The sniffer saw no quotes in the first lines, and read line 591 without them: say it explicitly
COPY Domain FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN DISTINCT domain);
COPY CITES FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN `from`, domain, count(*));
MATCH (d:Domain) RETURN count(*) AS domains;
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en'
RETURN d.name AS domain, count(*) AS pages, sum(c.links) AS links
ORDER BY links DESC, domain
LIMIT 8;

// A bug in 0.20.4: grouped by domain, count(DISTINCT ...) before sum(...) makes the sum NULL
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en' AND d.name IN ['duckdb.org', 'openjdk.org']
RETURN d.name AS domain, count(DISTINCT p) AS pages, sum(c.links) AS links
ORDER BY domain;
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en' AND d.name IN ['duckdb.org', 'openjdk.org']
RETURN d.name AS domain, sum(c.links) AS links, count(DISTINCT p) AS pages
ORDER BY domain;

// JSON needs the json extension: INSTALL downloads it once (check.sh does it before the scripts), LOAD loads it
LOAD FROM '../duckdb/data/runs.json' RETURN count(*);
LOAD json;
LOAD FROM '../duckdb/data/runs.json' RETURN conclusion, count(*) AS runs ORDER BY runs DESC, conclusion;
