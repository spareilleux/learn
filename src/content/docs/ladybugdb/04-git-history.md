---
title: 4. Git history and CI runs as a graph
description: Load the commits, files and CI runs of this repository into a graph, walk the history with long paths, find the files changed together, and connect failures to the files they touched — with two more bugs of LadybugDB 0.20.4 and their workarounds.
sidebar:
  order: 4
---

A second graph, from the same repository: its Git history up to commit `cbcbb42`, and the CI runs of the DuckDB course's snapshot. Every query is in [`cypher/04-git-history.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/04-git-history.cypher).

## The model

| Table | Kind | From |
|---|---|---|
| `Commit(sha, committed_at, subject)` | node | `commits.csv` |
| `File(path)` | node | the distinct files of `changes.csv` |
| `PARENT` | relationship, `Commit` to `Commit` | `parents.csv`: each commit points to its parent |
| `CHANGED` | relationship, `Commit` to `File` | `changes.csv` |
| `Run(databaseId, workflowName, conclusion, headBranch)` | node | `code/duckdb/data/runs.json` |
| `RAN_ON` | relationship, `Run` to `Commit` | `runs.json`: the commit each run checked out |

In SQL, `PARENT` and `CHANGED` would be junction tables, and `RAN_ON` a foreign key column in the runs table. In the graph, all three are relationships, and a query can follow them in a single pattern.

The first lines of the script create and load the Git part ([lines 3-10](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L3-L10)):

```cypher
CREATE NODE TABLE Commit(sha STRING PRIMARY KEY, committed_at TIMESTAMP, subject STRING);
CREATE NODE TABLE File(path STRING PRIMARY KEY);
CREATE REL TABLE PARENT(FROM Commit TO Commit);
CREATE REL TABLE CHANGED(FROM Commit TO File);
COPY Commit FROM 'data/commits.csv' (HEADER = true, QUOTE = '"');
COPY File FROM (LOAD FROM 'data/changes.csv' (HEADER = true) RETURN DISTINCT file);
COPY PARENT FROM 'data/parents.csv' (HEADER = true);
COPY CHANGED FROM 'data/changes.csv' (HEADER = true);
```

74 commits, 710 files, 73 `PARENT` and 1,019 `CHANGED` relationships. The file has 74 lines, so the CSV sniffer of lesson 2 reads all of them and finds the quoted subjects by itself; `QUOTE = '"'` only makes it explicit, for a longer history.

## Timestamps

[Line 13](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L13):

```cypher
MATCH (c:Commit) RETURN count(*) AS commits, min(c.committed_at) AS first_commit, max(c.committed_at) AS last_commit;
```

```text
┌─────────┬─────────────────────┬─────────────────────┐
│ commits │ first_commit        │ last_commit         │
│ INT64   │ TIMESTAMP           │ TIMESTAMP           │
├─────────┼─────────────────────┼─────────────────────┤
│ 74      │ 2026-09-13 15:52:51 │ 2026-09-14 16:03:28 │
└─────────┴─────────────────────┴─────────────────────┘
```

The file has `2026-09-13T11:52:51-04:00`, the local time of the commit with its offset. [`TIMESTAMP`](https://docs.ladybugdb.com/cypher/data-types/) has no time zone: LadybugDB converted the value to UTC and dropped the offset. The whole history of the site, up to this commit, fits in a little over a day.

## A long path that returns nothing

From the last commit back to the first one: a path of `PARENT` relationships to a commit without a parent ([lines 16-22](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L16-L22)):

```cypher
MATCH (last:Commit)-[p:PARENT*1..30]->(first:Commit)
WHERE last.sha STARTS WITH 'cbcbb42' AND NOT EXISTS { MATCH (first)-[:PARENT]->(:Commit) }
RETURN first.subject, length(p) AS commits_between;
CALL var_length_extend_max_depth = 100;
MATCH (last:Commit)-[p:PARENT*1..100]->(first:Commit)
WHERE last.sha STARTS WITH 'cbcbb42' AND NOT EXISTS { MATCH (first)-[:PARENT]->(:Commit) }
RETURN first.subject, length(p) AS commits_between;
```

```text
┌───────────────┬─────────────────┐
│ first.subject │ commits_between │
│ STRING        │ INT64           │
├───────────────┼─────────────────┤
└───────────────┴─────────────────┘
┌───────────────────────────────────────────────────────────────────────┬─────────────────┐
│ first.subject                                                         │ commits_between │
│ STRING                                                                │ INT64           │
├───────────────────────────────────────────────────────────────────────┼─────────────────┤
│ Initial learn site: Starlight, bilingual en/fr, WSL containers course │ 73              │
└───────────────────────────────────────────────────────────────────────┴─────────────────┘
```

**The first query returns no row, and no error.** The first commit is 73 relationships away, beyond the 30 of `*1..30`: no path fits the pattern. With the limit raised to 100 ([lesson 3](../03-paths/#the-depth-limit)), the same pattern finds it. When a variable-length pattern finds nothing, check its upper bound before the data. This history has no branches, so there is one path: no risk of the explosion of walks of lesson 3.

`STARTS WITH 'cbcbb42'` matches the abbreviated hash, like `git show cbcbb42`.

## Parents per commit, and a bug in `COUNT` subqueries

A merge commit has two parents. Are there any? [Lines 26-27](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L26-L27):

```cypher
MATCH (c:Commit) RETURN COUNT { MATCH (c)-[:PARENT]->(:Commit) } AS parents, count(*) AS commits ORDER BY parents;
MATCH (c:Commit) OPTIONAL MATCH (c)-[:PARENT]->(p:Commit) WITH c, count(p) AS parents RETURN parents, count(*) AS commits ORDER BY parents;
```

```text
┌─────────┬─────────┐
│ parents │ commits │
│ INT64   │ INT64   │
├─────────┼─────────┤
│ 1       │ 73      │
└─────────┴─────────┘
┌─────────┬─────────┐
│ parents │ commits │
│ INT64   │ INT64   │
├─────────┼─────────┤
│ 0       │ 1       │
│ 1       │ 73      │
└─────────┴─────────┘
```

No merge commit: the history is linear. But the first query counts 73 commits out of 74. The root commit, whose `COUNT` is 0, is missing from the grouped result, although the same subquery returns 0 for that commit when the query doesn't group by it. The second query counts the same thing with `OPTIONAL MATCH` and `count(p)`, and gets both groups. Another bug of 0.20.4, silent like those of lessons 2 and 3: when a query groups by a `COUNT` subquery, check that the groups add up to the number of nodes.

## Files changed together

The files that change in the same commits as `astro.config.mjs`, where the courses are registered ([lines 30-33](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L30-L33)):

```cypher
MATCH (a:File {path: 'astro.config.mjs'})<-[:CHANGED]-(c:Commit)-[:CHANGED]->(b:File)
RETURN b.path, count(*) AS commits
ORDER BY commits DESC, b.path
LIMIT 5;
```

```text
┌───────────────────────────────┬─────────┐
│ b.path                        │ commits │
│ STRING                        │ INT64   │
├───────────────────────────────┼─────────┤
│ astro.config.mjs              │ 11      │
│ src/content/docs/fr/index.mdx │ 9       │
│ src/content/docs/index.mdx    │ 9       │
│ AGENTS.md                     │ 7       │
│ README.md                     │ 7       │
└───────────────────────────────┴─────────┘
```

The first row is the file itself. The pattern has two `CHANGED` relationships, and nothing forbids them to be the same one: with the [walk semantics](https://docs.ladybugdb.com/cypher/difference/) of lesson 3, `b` can be `a`. `WHERE b <> a` removes that row; the next ones are the home pages, which list the courses too, and `AGENTS.md`, where the course conventions live. The SQL version, a self-join of the changes table on the commit, has the same trap and the same fix (`b.file <> a.file`).

## The files changed most often

[Lines 36-39](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L36-L39):

```cypher
MATCH (c:Commit)-[:CHANGED]->(f:File)
RETURN f.path, count(*) AS commits
ORDER BY commits DESC, f.path
LIMIT 5;
```

```text
┌───────────────────────────────────────────────┬─────────┐
│ f.path                                        │ commits │
│ STRING                                        │ INT64   │
├───────────────────────────────────────────────┼─────────┤
│ src/content/docs/fr/wsl-containers/journal.md │ 16      │
│ src/content/docs/wsl-containers/journal.md    │ 15      │
│ README.md                                     │ 13      │
│ astro.config.mjs                              │ 11      │
│ src/content/docs/fr/index.mdx                 │ 9       │
└───────────────────────────────────────────────┴─────────┘
```

The WSL containers journal comes first: 16 commits changed the French one, 15 the English one.

## CI runs: a relationship to a missing commit

The runs come from JSON, so the json extension first ([lines 42-45](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L42-L45)):

```cypher
LOAD json;
CREATE NODE TABLE Run(databaseId INT64 PRIMARY KEY, workflowName STRING, conclusion STRING, headBranch STRING);
CREATE REL TABLE RAN_ON(FROM Run TO Commit);
COPY Run FROM (LOAD FROM '../duckdb/data/runs.json' RETURN databaseId, workflowName, conclusion, headBranch);
```

125 runs. Then the relationships, from the run id to the commit it ran on ([lines 48-52](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L48-L52)):

```cypher
COPY RAN_ON FROM (LOAD FROM '../duckdb/data/runs.json' RETURN databaseId, headSha);
LOAD FROM '../duckdb/data/runs.json'
WITH headBranch, headSha
WHERE NOT EXISTS { MATCH (c:Commit) WHERE c.sha = headSha }
RETURN headBranch, count(*) AS runs;
```

```text
Error: Copy exception: Unable to find primary key value bd17932fe35899909b8d983ab289e1ea4ff344a8.
┌────────────────┬───────┐
│ headBranch     │ runs  │
│ STRING         │ INT64 │
├────────────────┼───────┤
│ gha-06-invalid │ 2     │
└────────────────┴───────┘
```

Two runs ran on a commit of the branch `gha-06-invalid`, a temporary branch of the [GitHub Actions course](../../github-actions/journal/), used to test an invalid workflow without putting it on `main`: its commits aren't in this history. Lesson 2's answer would be `IGNORE_ERRORS`, but it isn't supported on a `COPY` from a subquery: the attempt fails with `bad variant access`. The obvious alternative is to keep only the runs whose commit exists.

## A bug in 0.20.4: a `MATCH` in a `COPY` subquery

That alternative, with a `MATCH` in the subquery ([lines 55-61](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L55-L61)):

```cypher
COPY RAN_ON FROM (
  LOAD FROM '../duckdb/data/runs.json'
  WITH databaseId, headSha
  MATCH (c:Commit) WHERE c.sha = headSha
  RETURN databaseId, headSha
);
MATCH (r:Run)-[:RAN_ON]->(c:Commit) RETURN count(*) AS links, count(DISTINCT r) AS runs, count(DISTINCT c) AS commits;
```

```text
┌──────────────────────────────────────────────────┐
│ result                                           │
│ STRING                                           │
├──────────────────────────────────────────────────┤
│ 123 tuples have been copied to the RAN_ON table. │
└──────────────────────────────────────────────────┘
┌───────┬───────┬─────────┐
│ links │ runs  │ commits │
│ INT64 │ INT64 │ INT64   │
├───────┼───────┼─────────┤
│ 123   │ 1     │ 64      │
└───────┴───────┴─────────┘
```

123 relationships, the right number, to the right 64 commits, but **all from the same run**. The subquery alone, run as a query, returns 123 distinct run ids; inside `COPY`, the `FROM` column of every relationship gets one of them. The same `COPY` works with a CSV file instead of JSON, and with JSON when the filter doesn't use `MATCH`. The workaround keeps JSON and filters on a column: the two missing commits are the ones on the other branch ([lines 64-71](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L64-L71)):

```cypher
MATCH ()-[x:RAN_ON]->() DELETE x;
COPY RAN_ON FROM (
  LOAD FROM '../duckdb/data/runs.json'
  WITH databaseId, headSha, headBranch
  WHERE headBranch = 'main'
  RETURN databaseId, headSha
);
MATCH (r:Run)-[:RAN_ON]->(c:Commit) RETURN count(*) AS links, count(DISTINCT r) AS runs, count(DISTINCT c) AS commits;
```

```text
┌──────────────────────────────────────────────────┐
│ result                                           │
│ STRING                                           │
├──────────────────────────────────────────────────┤
│ 123 tuples have been copied to the RAN_ON table. │
└──────────────────────────────────────────────────┘
┌───────┬───────┬─────────┐
│ links │ runs  │ commits │
│ INT64 │ INT64 │ INT64   │
├───────┼───────┼─────────┤
│ 123   │ 123   │ 64      │
└───────┴───────┴─────────┘
```

123 links from 123 runs. `MATCH ()-[x:RAN_ON]->() DELETE x` deleted the wrong relationships first: relationships can be deleted without `DETACH`. The check query is the point of this section: `count(*)` alone was right in both cases; `count(DISTINCT r)` showed the bug.

## Failures and the files they touched

The whole graph in one pattern: runs, commits, files ([lines 74-78](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L74-L78)):

```cypher
MATCH (r:Run)-[:RAN_ON]->(c:Commit)-[:CHANGED]->(f:File)
WHERE r.conclusion = 'failure'
RETURN f.path, count(DISTINCT c) AS failed_commits
ORDER BY failed_commits DESC, f.path
LIMIT 5;
```

```text
┌────────────────────────────────────────┬────────────────┐
│ f.path                                 │ failed_commits │
│ STRING                                 │ INT64          │
├────────────────────────────────────────┼────────────────┤
│ .github/workflows/gha-03-triggers.yml  │ 2              │
│ .github/workflows/gha-05-exercises.yml │ 2              │
│ astro.config.mjs                       │ 2              │
│ code/github-actions/.gitignore         │ 2              │
│ src/content/docs/fr/index.mdx          │ 2              │
└────────────────────────────────────────┴────────────────┘
```

`count(DISTINCT c)`, not `count(*)`: a commit with three failed runs counts once. The workflow files of the GitHub Actions lessons come first; the site files next to them were changed in the same commits. A graph of changes shows what failed together, not what caused the failure: for that, the run logs.

## Runs per workflow on the commits that changed the course code

[Lines 81-84](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L81-L84):

```cypher
MATCH (r:Run)-[:RAN_ON]->(c:Commit)-[:CHANGED]->(f:File)
WHERE f.path STARTS WITH 'code/github-actions/'
RETURN r.workflowName, count(DISTINCT r) AS runs
ORDER BY runs DESC, r.workflowName;
```

```text
┌─────────────────────────────────────┬───────┐
│ r.workflowName                      │ runs  │
│ STRING                              │ INT64 │
├─────────────────────────────────────┼───────┤
│ Deploy to GitHub Pages              │ 2     │
│ GHA 02: build and test              │ 2     │
│ Rust course examples                │ 2     │
│ GHA 01: hello                       │ 1     │
│ GHA 03: triggers                    │ 1     │
│ GHA 04: data between steps and jobs │ 1     │
│ GHA 05: caches and artifacts        │ 1     │
│ GHA 05: exercise checks             │ 1     │
└─────────────────────────────────────┴───────┘
```

Which workflows a change of `code/github-actions/` triggered: the GitHub Actions workflows, but also the deployment and the Rust course examples, which ran on the same commits because other files changed with them. `count(DISTINCT r)` again: a run is reached once per file of its commit.

## Key takeaways

- A Git history is a graph: commits, files and runs are nodes; parents, changes and "ran on" are relationships.
- A variable-length pattern whose upper bound is too small returns nothing, without an error.
- `TIMESTAMP` stores UTC: an offset in the file is applied, then dropped.
- In a pattern with two relationships of the same table, both can be the same relationship: exclude it with `WHERE b <> a`.
- Two more silent bugs of 0.20.4: grouping by a `COUNT` subquery drops the zero group, and a `MATCH` inside a `COPY` subquery from JSON attaches every relationship to one node. `IGNORE_ERRORS` isn't available on subqueries either. `count(DISTINCT …)` on each end is a cheap check after a load.

## Exercises

The solutions are in [`cypher/04-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/04-exercises.cypher), checked by CI. They load the same graph, with the `main` workaround for `RAN_ON`.

1. Which three commits changed the most files?

<details>
<summary>Solution</summary>

From [`04-exercises.cypher`, lines 23-26](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-exercises.cypher#L23-L26):

```cypher
MATCH (c:Commit)-[:CHANGED]->(f:File)
RETURN substring(c.sha, 1, 7) AS sha, c.subject, count(*) AS files
ORDER BY files DESC, sha
LIMIT 3;
```

```text
┌─────────┬──────────────────────────────────────────────────────────────┬───────┐
│ sha     │ c.subject                                                    │ files │
│ STRING  │ STRING                                                       │ INT64 │
├─────────┼──────────────────────────────────────────────────────────────┼───────┤
│ d32b186 │ Java lessons 5-8 and a Spanish locale for the whole site     │ 160   │
│ f43ba7e │ Import Streeling University modules from Demerzel            │ 103   │
│ 529c946 │ Java for C# developers: lessons 1-4, tested code and journal │ 80    │
└─────────┴──────────────────────────────────────────────────────────────┴───────┘
```

The commit that added the Spanish locale added 75 Spanish pages at once. `substring(c.sha, 1, 7)` is the abbreviated hash.

</details>

2. How many commits before `cbcbb42` was `AGENTS.md` last changed, and by which commit?

<details>
<summary>Solution</summary>

From [`04-exercises.cypher`, lines 29-34](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-exercises.cypher#L29-L34):

```cypher
CALL var_length_extend_max_depth = 100;
MATCH (last:Commit)-[p:PARENT* SHORTEST 1..100]->(c:Commit)-[:CHANGED]->(:File {path: 'AGENTS.md'})
WHERE last.sha STARTS WITH 'cbcbb42'
RETURN length(p) AS commits_before, substring(c.sha, 1, 7) AS sha, c.subject
ORDER BY commits_before
LIMIT 1;
```

```text
┌────────────────┬─────────┬──────────────────────────────────────────────────────────┐
│ commits_before │ sha     │ c.subject                                                │
│ INT64          │ STRING  │ STRING                                                   │
├────────────────┼─────────┼──────────────────────────────────────────────────────────┤
│ 42             │ d32b186 │ Java lessons 5-8 and a Spanish locale for the whole site │
└────────────────┴─────────┴──────────────────────────────────────────────────────────┘
```

42 commits: `git log --oneline cbcbb42` lists `d32b186` in position 43. `SHORTEST` finds one path per commit that changed `AGENTS.md`, and `ORDER BY … LIMIT 1` keeps the closest. The limit of 100 is needed again: the history is longer than 30. The lower bound 1 excludes `cbcbb42` itself, which didn't change the file anyway.

</details>

3. Which commits have no CI run? For each, how long before the next commit, and did that one have runs?

<details>
<summary>Solution</summary>

From [`04-exercises.cypher`, lines 37-45](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-exercises.cypher#L37-L45):

```cypher
MATCH (c:Commit)
WHERE NOT EXISTS { MATCH (:Run)-[:RAN_ON]->(c) }
RETURN c.committed_at, substring(c.sha, 1, 7) AS sha, c.subject
ORDER BY c.committed_at;
MATCH (c:Commit)-[:PARENT]->(p:Commit)
WHERE NOT EXISTS { MATCH (:Run)-[:RAN_ON]->(p) }
RETURN substring(p.sha, 1, 7) AS without_runs, substring(c.sha, 1, 7) AS next_commit, c.committed_at - p.committed_at AS gap,
       COUNT { MATCH (:Run)-[:RAN_ON]->(c) } AS next_commit_runs
ORDER BY without_runs;
```

```text
┌─────────────────────┬─────────┬──────────────────────────────────────────────────────────────────────────────────────┐
│ c.committed_at      │ sha     │ c.subject                                                                            │
│ TIMESTAMP           │ STRING  │ STRING                                                                               │
├─────────────────────┼─────────┼──────────────────────────────────────────────────────────────────────────────────────┤
│ 2026-09-13 17:13:23 │ 00f2ca4 │ Rust course: lessons 9-12 (lifetimes, modules, smart pointers, threads)              │
│ 2026-09-14 14:08:24 │ 3f3b219 │ DuckDB course: data snapshot of this repository's runs, lesson 1 SQL, CI on 3 OSes   │
│ 2026-09-14 14:24:14 │ 742c967 │ DuckDB course: SQL and expected output for lessons 1-4 and their exercises           │
│ 2026-09-14 14:25:34 │ 36207da │ DuckDB course: don't compare Parquet compressed sizes, they differ on macOS arm64    │
│ 2026-09-14 14:43:42 │ 3e9530f │ DuckDB course: mission, lessons 1-4 and journal (en/fr/es)                           │
│ 2026-09-14 15:13:02 │ a96fd27 │ DuckDB course: lesson 5 C# program (DuckDB.NET, Dapper) and CI on 3 OSes             │
│ 2026-09-14 15:16:11 │ 5a26d1a │ DuckDB course: lesson 6 Java program (JDBC) and CI on 3 OSes                         │
│ 2026-09-14 15:33:19 │ bdf2692 │ DuckDB course: lesson 7 scripts (plans, pushdown, row groups) and CI timings         │
│ 2026-09-14 15:48:40 │ 86e34d9 │ DuckDB course: lesson 7 exercises, lesson 8 persistence script and Java transactions │
│ 2026-09-14 16:03:28 │ cbcbb42 │ DuckDB course: lessons 5-8 (C#, Java, performance, persistence) in en/fr/es          │
└─────────────────────┴─────────┴──────────────────────────────────────────────────────────────────────────────────────┘
┌──────────────┬─────────────┬──────────┬──────────────────┐
│ without_runs │ next_commit │ gap      │ next_commit_runs │
│ STRING       │ STRING      │ INTERVAL │ INT64            │
├──────────────┼─────────────┼──────────┼──────────────────┤
│ 00f2ca4      │ 95a42da     │ 00:00:00 │ 2                │
│ 36207da      │ 3e9530f     │ 00:18:08 │ 0                │
│ 3e9530f      │ a96fd27     │ 00:29:20 │ 0                │
│ 3f3b219      │ 742c967     │ 00:15:50 │ 0                │
│ 5a26d1a      │ bdf2692     │ 00:17:08 │ 0                │
│ 742c967      │ 36207da     │ 00:01:20 │ 0                │
│ 86e34d9      │ cbcbb42     │ 00:14:48 │ 0                │
│ a96fd27      │ 5a26d1a     │ 00:03:09 │ 0                │
│ bdf2692      │ 86e34d9     │ 00:15:21 │ 0                │
└──────────────┴─────────────┴──────────┴──────────────────┘
```

Two reasons. Nine commits are later than the runs snapshot, whose last run was created at 14:01 UTC: they had runs, after the snapshot was taken. `00f2ca4` is the other case: `95a42da` followed it in the same second, they were pushed together, and GitHub Actions runs a push's workflows on its last commit only. Subtracting two `TIMESTAMP` values gives an `INTERVAL`. `cbcbb42` has no child in this history, so it's not in the second result.

</details>

## Sources

- [Data types](https://docs.ladybugdb.com/cypher/data-types/): `TIMESTAMP`, `INTERVAL`
- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/): variable-length relationships and shortest paths
- [`COPY FROM` a subquery](https://docs.ladybugdb.com/import/copy-from-subquery/) and [JSON extension](https://docs.ladybugdb.com/extensions/json/)
- [Subqueries](https://docs.ladybugdb.com/cypher/subquery/) and [`OPTIONAL MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/optional-match/)
- [Differences between LadybugDB and Neo4j](https://docs.ladybugdb.com/cypher/difference/)
- [Events that trigger workflows: `push`](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows#push)
