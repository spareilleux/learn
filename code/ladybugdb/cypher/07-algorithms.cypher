// LadybugDB course, lesson 7: graph algorithms and full-text search, with the algo and fts extensions
// Run from code/ladybugdb with the 0.19.1 CLI: lbug19 < cypher/07-algorithms.cypher
// (the extensions published for 0.20.x don't load with the 0.20.4 CLI: see the lesson)
LOAD algo;
LOAD fts;

// The projects of GuitarAlchemist/ga, as in lessons 5 and 6
CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING, language STRING, sdk STRING, frameworks STRING, in_solution BOOLEAN);
CREATE REL TABLE REFERENCES(FROM Project TO Project);
COPY Project FROM 'data/ga/projects.csv' (HEADER = true);
COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true, IGNORE_ERRORS = true);

// Algorithms run on a projected graph: a named selection of node and relationship tables
CALL project_graph('Deps', ['Project'], ['REFERENCES']);
CALL show_projected_graphs() RETURN *;

// Strongly connected components: projects that reach each other, which a build can't order
CALL strongly_connected_components('Deps')
WITH group_id, count(*) AS projects
RETURN projects, count(*) AS components
ORDER BY projects DESC;

// Weakly connected components: the islands of the graph, ignoring the direction of the references
CALL weakly_connected_components('Deps')
WITH group_id, count(*) AS projects
RETURN projects, count(*) AS components
ORDER BY projects DESC;

// The projects alone in their component: no reference, in or out
CALL weakly_connected_components('Deps')
WITH group_id, collect(node) AS members
WHERE size(members) = 1
UNWIND members AS p
RETURN p.path AS path, p.in_solution AS in_solution
ORDER BY p.path;

// PageRank: a project is important when important projects reference it
CALL page_rank('Deps')
WITH node, rank
RETURN node.name, round(rank, 4) AS rank, COUNT { MATCH (:Project)-[:REFERENCES]->(node) } AS referenced_by
ORDER BY rank DESC, node.name
LIMIT 6;

// k-core decomposition: the largest k such that the project belongs to a subgraph where every project has k neighbours
CALL k_core_decomposition('Deps')
RETURN k_degree, count(*) AS projects
ORDER BY k_degree DESC;
CALL k_core_decomposition('Deps')
WITH node, k_degree
WHERE k_degree = 6
RETURN node.name
ORDER BY node.name;

// Louvain: communities of projects more connected to each other than to the rest
// Their sizes change from one run to the next, even on one thread: only the stable facts are compared
CALL louvain('Deps')
WITH louvain_id, count(*) AS projects
RETURN count(*) AS groups, sum(CASE WHEN louvain_id = -1 THEN projects ELSE 0 END) AS without_community;

// The same graph without the test projects: a projection defined by a Cypher query fails in 0.19.1
CALL project_graph_cypher('NoTests', 'MATCH (a:Project)-[r:REFERENCES]->(b:Project) WHERE NOT a.path STARTS WITH \'Tests/\' RETURN a, r, b');
CALL page_rank('NoTests') RETURN count(*);
// A projection with a filter on the node table works
CALL project_graph('NoTestsFiltered', {'Project': 'NOT n.path STARTS WITH "Tests/"'}, ['REFERENCES']);
CALL page_rank('NoTestsFiltered')
WITH node, rank
RETURN node.name, round(rank, 4) AS rank
ORDER BY rank DESC, node.name
LIMIT 3;
CALL show_projected_graphs() RETURN * ORDER BY name;
CALL drop_projected_graph('NoTests');
CALL drop_projected_graph('NoTestsFiltered');

// Full-text search: the page titles of the site and the commit subjects of lesson 4
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
COPY Page FROM 'data/pages.csv' (HEADER = true);
CREATE NODE TABLE Commit(sha STRING PRIMARY KEY, committed_at TIMESTAMP, subject STRING);
COPY Commit FROM 'data/commits.csv' (HEADER = true, QUOTE = '"');

CALL CREATE_FTS_INDEX('Page', 'titles', ['title']);
CALL CREATE_FTS_INDEX('Page', 'titles_exact', ['title'], stemmer := 'none');
CALL CREATE_FTS_INDEX('Page', 'titles_fr', ['title'], stemmer := 'french');
CALL CREATE_FTS_INDEX('Commit', 'subjects', ['subject']);
CALL show_indexes() RETURN table_name, index_name, index_type, index_definition;

// A search returns nodes and a BM25 score; the English stemmer finds "queries" for "query"
CALL QUERY_FTS_INDEX('Page', 'titles', 'query')
RETURN node.url, node.title, round(score, 4) AS score
ORDER BY score DESC, node.url;
// Without a stemmer, only the exact word
CALL QUERY_FTS_INDEX('Page', 'titles_exact', 'query') RETURN count(*) AS pages;
CALL QUERY_FTS_INDEX('Page', 'titles_exact', 'queries') RETURN count(*) AS pages;

// One word, two stemmers: English reduces "persistant", "persistence" and "persistance" to the same stem, French doesn't
CALL QUERY_FTS_INDEX('Page', 'titles', 'persistant')
RETURN node.url, node.title
ORDER BY node.url;
CALL QUERY_FTS_INDEX('Page', 'titles_fr', 'persistant')
RETURN node.url, node.title
ORDER BY node.url;

// Case doesn't matter, accents do; stop words are not indexed
CALL QUERY_FTS_INDEX('Page', 'titles', 'DONNÉES') RETURN count(*) AS pages;
CALL QUERY_FTS_INDEX('Page', 'titles', 'donnees') RETURN count(*) AS pages;
CALL QUERY_FTS_INDEX('Page', 'titles', 'the') RETURN count(*) AS pages;

// Any word, or all the words
CALL QUERY_FTS_INDEX('Commit', 'subjects', 'lesson exercises')
RETURN count(*) AS any_word;
CALL QUERY_FTS_INDEX('Commit', 'subjects', 'lesson exercises', conjunctive := true)
RETURN substring(node.sha, 1, 7) AS sha, node.subject, round(score, 4) AS score
ORDER BY score DESC, sha;

// The index follows the table, and a new row changes the scores of the others
CREATE (:Commit {sha: '0000000', committed_at: timestamp('2026-09-14 20:00:00'), subject: 'LadybugDB course: lesson 7 exercises'});
CALL QUERY_FTS_INDEX('Commit', 'subjects', 'lesson exercises', conjunctive := true)
RETURN substring(node.sha, 1, 7) AS sha, round(score, 4) AS score
ORDER BY score DESC, sha;

// Full-text search and a graph pattern in one query: the files most often changed by the commits about exercises
CREATE NODE TABLE File(path STRING PRIMARY KEY);
CREATE REL TABLE CHANGED(FROM Commit TO File);
COPY File FROM (LOAD FROM 'data/changes.csv' (HEADER = true) RETURN DISTINCT file);
COPY CHANGED FROM 'data/changes.csv' (HEADER = true);
CALL QUERY_FTS_INDEX('Commit', 'subjects', 'exercises')
WITH node AS c
MATCH (c)-[:CHANGED]->(f:File)
RETURN f.path, count(*) AS commits
ORDER BY commits DESC, f.path
LIMIT 5;

CALL DROP_FTS_INDEX('Page', 'titles_fr');
CALL QUERY_FTS_INDEX('Page', 'titles_fr', 'persistant') RETURN count(*);
