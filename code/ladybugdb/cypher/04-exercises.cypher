// LadybugDB course, lesson 4: exercise solutions
// Run from code/ladybugdb: lbug < cypher/04-exercises.cypher
CREATE NODE TABLE Commit(sha STRING PRIMARY KEY, committed_at TIMESTAMP, subject STRING);
CREATE NODE TABLE File(path STRING PRIMARY KEY);
CREATE REL TABLE PARENT(FROM Commit TO Commit);
CREATE REL TABLE CHANGED(FROM Commit TO File);
COPY Commit FROM 'data/commits.csv' (HEADER = true, QUOTE = '"');
COPY File FROM (LOAD FROM 'data/changes.csv' (HEADER = true) RETURN DISTINCT file);
COPY PARENT FROM 'data/parents.csv' (HEADER = true);
COPY CHANGED FROM 'data/changes.csv' (HEADER = true);
LOAD json;
CREATE NODE TABLE Run(databaseId INT64 PRIMARY KEY, workflowName STRING, conclusion STRING, headBranch STRING);
CREATE REL TABLE RAN_ON(FROM Run TO Commit);
COPY Run FROM (LOAD FROM '../duckdb/data/runs.json' RETURN databaseId, workflowName, conclusion, headBranch);
COPY RAN_ON FROM (
  LOAD FROM '../duckdb/data/runs.json'
  WITH databaseId, headSha, headBranch
  WHERE headBranch = 'main'
  RETURN databaseId, headSha
);

// Exercise 1: the three commits that changed the most files
MATCH (c:Commit)-[:CHANGED]->(f:File)
RETURN substring(c.sha, 1, 7) AS sha, c.subject, count(*) AS files
ORDER BY files DESC, sha
LIMIT 3;

// Exercise 2: how many commits before cbcbb42 was AGENTS.md last changed?
CALL var_length_extend_max_depth = 100;
MATCH (last:Commit)-[p:PARENT* SHORTEST 1..100]->(c:Commit)-[:CHANGED]->(:File {path: 'AGENTS.md'})
WHERE last.sha STARTS WITH 'cbcbb42'
RETURN length(p) AS commits_before, substring(c.sha, 1, 7) AS sha, c.subject
ORDER BY commits_before
LIMIT 1;

// Exercise 3: the commits no CI run ran on
MATCH (c:Commit)
WHERE NOT EXISTS { MATCH (:Run)-[:RAN_ON]->(c) }
RETURN c.committed_at, substring(c.sha, 1, 7) AS sha, c.subject
ORDER BY c.committed_at;
MATCH (c:Commit)-[:PARENT]->(p:Commit)
WHERE NOT EXISTS { MATCH (:Run)-[:RAN_ON]->(p) }
RETURN substring(p.sha, 1, 7) AS without_runs, substring(c.sha, 1, 7) AS next_commit, c.committed_at - p.committed_at AS gap,
       COUNT { MATCH (:Run)-[:RAN_ON]->(c) } AS next_commit_runs
ORDER BY without_runs;
