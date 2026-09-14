// LadybugDB course, lesson 1: node and relationship tables, CREATE, MATCH, MERGE and DELETE
// Run from code/ladybugdb: lbug < cypher/01-first-graph.cypher

// The schema comes first: two node tables and two relationship tables
CREATE NODE TABLE Course(slug STRING PRIMARY KEY, title STRING);
CREATE NODE TABLE Lesson(url STRING PRIMARY KEY, number INT64, title STRING);
CREATE REL TABLE HAS_LESSON(FROM Course TO Lesson);
CREATE REL TABLE LINKS_TO(FROM Lesson TO Lesson);

// Nodes
CREATE (:Course {slug: 'duckdb', title: 'DuckDB'});
CREATE (:Lesson {url: '/duckdb/01-first-queries/', number: 1, title: 'First queries'}),
       (:Lesson {url: '/duckdb/02-friendly-sql/', number: 2, title: 'Friendly SQL'}),
       (:Lesson {url: '/duckdb/03-nested-data/', number: 3, title: 'Nested data'});

// Relationships: find the nodes, then connect them
MATCH (c:Course {slug: 'duckdb'}), (l:Lesson) CREATE (c)-[:HAS_LESSON]->(l);
MATCH (a:Lesson {number: 2}), (b:Lesson {number: 1}) CREATE (a)-[:LINKS_TO]->(b);

// Patterns
MATCH (c:Course)-[:HAS_LESSON]->(l:Lesson)
RETURN c.title, l.number, l.title
ORDER BY l.number;

MATCH (a:Lesson)-[:LINKS_TO]->(b:Lesson)
RETURN a.title AS from_lesson, b.title AS to_lesson;

// Lessons no other lesson links to
MATCH (l:Lesson)
WHERE NOT EXISTS { MATCH (l)<-[:LINKS_TO]-(:Lesson) }
RETURN l.title
ORDER BY l.title;

// The schema is enforced: a duplicate key, an unknown property, a missing key
CREATE (:Lesson {url: '/duckdb/01-first-queries/', number: 1, title: 'Again'});
CREATE (:Lesson {url: '/duckdb/04-files/', minutes: 30});
CREATE (:Lesson {number: 4});

// MERGE creates the node if the key doesn't exist, and updates it otherwise
MERGE (l:Lesson {url: '/duckdb/04-files/'}) ON CREATE SET l.number = 4, l.title = 'Files' RETURN l.*;
MERGE (l:Lesson {url: '/duckdb/04-files/'}) ON MATCH SET l.title = 'Files: CSV and Parquet' RETURN l.*;

// What the database contains
CALL show_tables() RETURN name, type ORDER BY name;
CALL table_info('Lesson') RETURN *;
MATCH (n) RETURN label(n) AS table_name, count(*) AS nodes ORDER BY table_name;

// Deleting: a node with relationships needs DETACH DELETE
MATCH (l:Lesson {number: 1}) DELETE l;
MATCH (l:Lesson {number: 1}) DETACH DELETE l;
MATCH (l:Lesson) RETURN count(*) AS lessons;
MATCH ()-[r]->() RETURN label(r) AS table_name, count(*) AS relationships ORDER BY table_name;
