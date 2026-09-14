// LadybugDB course, lesson 1: exercise solutions
// Run from code/ladybugdb: lbug < cypher/01-exercises.cypher
CREATE NODE TABLE Course(slug STRING PRIMARY KEY, title STRING);
CREATE NODE TABLE Lesson(url STRING PRIMARY KEY, number INT64, title STRING);
CREATE REL TABLE HAS_LESSON(FROM Course TO Lesson);
CREATE REL TABLE LINKS_TO(FROM Lesson TO Lesson);
CREATE (:Course {slug: 'duckdb', title: 'DuckDB'});
CREATE (:Lesson {url: '/duckdb/01-first-queries/', number: 1, title: 'First queries'}),
       (:Lesson {url: '/duckdb/02-friendly-sql/', number: 2, title: 'Friendly SQL'});
MATCH (c:Course {slug: 'duckdb'}), (l:Lesson) CREATE (c)-[:HAS_LESSON]->(l);

// Exercise 1: a new lesson and its course in one statement, run twice
MATCH (c:Course {slug: 'duckdb'})
MERGE (l:Lesson {url: '/duckdb/05-csharp/'}) ON CREATE SET l.number = 5, l.title = 'DuckDB from C#'
MERGE (c)-[:HAS_LESSON]->(l);
MATCH (c:Course {slug: 'duckdb'})
MERGE (l:Lesson {url: '/duckdb/05-csharp/'}) ON CREATE SET l.number = 5, l.title = 'DuckDB from C#'
MERGE (c)-[:HAS_LESSON]->(l);
MATCH (c:Course)-[:HAS_LESSON]->(l:Lesson) RETURN c.slug, count(*) AS lessons;

// Exercise 2: a relationship to a lesson that doesn't exist
MATCH (a:Lesson {number: 2}), (b:Lesson {number: 9}) CREATE (a)-[:LINKS_TO]->(b);
MATCH ()-[r:LINKS_TO]->() RETURN count(*) AS links;

// Exercise 3: CREATE instead of MERGE for the relationship
MATCH (c:Course {slug: 'duckdb'}), (l:Lesson {number: 5}) CREATE (c)-[:HAS_LESSON]->(l);
MATCH (c:Course)-[:HAS_LESSON]->(l:Lesson) RETURN l.number, count(*) AS links ORDER BY l.number;
