// LadybugDB course, lesson 4: the Git history of this repository and its CI runs as a graph
// Run from code/ladybugdb: lbug < cypher/04-git-history.cypher
CREATE NODE TABLE Commit(sha STRING PRIMARY KEY, committed_at TIMESTAMP, subject STRING);
CREATE NODE TABLE File(path STRING PRIMARY KEY);
CREATE REL TABLE PARENT(FROM Commit TO Commit);
CREATE REL TABLE CHANGED(FROM Commit TO File);
COPY Commit FROM 'data/commits.csv' (HEADER = true, QUOTE = '"');
COPY File FROM (LOAD FROM 'data/changes.csv' (HEADER = true) RETURN DISTINCT file);
COPY PARENT FROM 'data/parents.csv' (HEADER = true);
COPY CHANGED FROM 'data/changes.csv' (HEADER = true);

// Timestamps with an offset are stored in UTC
MATCH (c:Commit) RETURN count(*) AS commits, min(c.committed_at) AS first_commit, max(c.committed_at) AS last_commit;

// The first commit, from the last one: one path of PARENT links
MATCH (last:Commit)-[p:PARENT*1..30]->(first:Commit)
WHERE last.sha STARTS WITH 'cbcbb42' AND NOT EXISTS { MATCH (first)-[:PARENT]->(:Commit) }
RETURN first.subject, length(p) AS commits_between;
CALL var_length_extend_max_depth = 100;
MATCH (last:Commit)-[p:PARENT*1..100]->(first:Commit)
WHERE last.sha STARTS WITH 'cbcbb42' AND NOT EXISTS { MATCH (first)-[:PARENT]->(:Commit) }
RETURN first.subject, length(p) AS commits_between;

// No merge commit: every commit has at most one parent
MATCH (c:Commit) RETURN COUNT { MATCH (c)-[:PARENT]->(:Commit) } AS parents, count(*) AS commits ORDER BY parents;

// Files changed together with astro.config.mjs
MATCH (a:File {path: 'astro.config.mjs'})<-[:CHANGED]-(c:Commit)-[:CHANGED]->(b:File)
RETURN b.path, count(*) AS commits
ORDER BY commits DESC, b.path
LIMIT 5;

// The files changed most often
MATCH (c:Commit)-[:CHANGED]->(f:File)
RETURN f.path, count(*) AS commits
ORDER BY commits DESC, f.path
LIMIT 5;

// CI runs, from the DuckDB course's JSON snapshot
LOAD json;
CREATE NODE TABLE Run(databaseId INT64 PRIMARY KEY, workflowName STRING, conclusion STRING, headBranch STRING);
CREATE REL TABLE RAN_ON(FROM Run TO Commit);
COPY Run FROM (LOAD FROM '../duckdb/data/runs.json' RETURN databaseId, workflowName, conclusion, headBranch);

// Two runs point to commits of a branch that isn't in this history
COPY RAN_ON FROM (LOAD FROM '../duckdb/data/runs.json' RETURN databaseId, headSha);
LOAD FROM '../duckdb/data/runs.json'
WITH headBranch, headSha
WHERE NOT EXISTS { MATCH (c:Commit) WHERE c.sha = headSha }
RETURN headBranch, count(*) AS runs;

// A bug in 0.20.4: from JSON, a MATCH in the COPY subquery attaches every relationship to the same run
COPY RAN_ON FROM (
  LOAD FROM '../duckdb/data/runs.json'
  WITH databaseId, headSha
  MATCH (c:Commit) WHERE c.sha = headSha
  RETURN databaseId, headSha
);
MATCH (r:Run)-[:RAN_ON]->(c:Commit) RETURN count(*) AS links, count(DISTINCT r) AS runs, count(DISTINCT c) AS commits;

// Workaround: filter without MATCH, then check the counts again
MATCH ()-[x:RAN_ON]->() DELETE x;
COPY RAN_ON FROM (
  LOAD FROM '../duckdb/data/runs.json'
  WITH databaseId, headSha, headBranch
  WHERE headBranch = 'main'
  RETURN databaseId, headSha
);
MATCH (r:Run)-[:RAN_ON]->(c:Commit) RETURN count(*) AS links, count(DISTINCT r) AS runs, count(DISTINCT c) AS commits;

// The files changed by the commits whose CI failed
MATCH (r:Run)-[:RAN_ON]->(c:Commit)-[:CHANGED]->(f:File)
WHERE r.conclusion = 'failure'
RETURN f.path, count(DISTINCT c) AS failed_commits
ORDER BY failed_commits DESC, f.path
LIMIT 5;

// Runs per workflow on the commits that changed the GitHub Actions course code
MATCH (r:Run)-[:RAN_ON]->(c:Commit)-[:CHANGED]->(f:File)
WHERE f.path STARTS WITH 'code/github-actions/'
RETURN r.workflowName, count(DISTINCT r) AS runs
ORDER BY runs DESC, r.workflowName;
