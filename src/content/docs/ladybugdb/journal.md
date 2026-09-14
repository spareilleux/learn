---
title: Journal
description: Dated progress notes — data, CI runs, bugs found in LadybugDB 0.20.4 and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Data: the pages, links and Git history of this repository at commit `cbcbb42`, and the CI runs of the DuckDB course
- [x] CI: every lesson's Cypher compared with its expected output on three OSes, and a SQL cross-check with DuckDB
- [x] Lesson 1: a first graph
- [x] Lesson 2: loading files
- [x] Lesson 3: paths
- [x] Lesson 4: Git history and CI runs as a graph
- [ ] Lesson 5: LadybugDB from C#
- [ ] Lesson 6: LadybugDB from Java
- [ ] Lesson 7: graph algorithms and full-text search
- [ ] Lesson 8: persistence, transactions and concurrency

## 2026-09-14 — The data

- [`extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/extract.py), run with the commit `cbcbb42` as argument, reads the Markdown files and the Git history at that commit, with `git ls-tree`, `git show` and `git log`, not the working copy: the CSV files don't change when the site does.
- 319 pages, 712 internal links, 3,712 external links, 74 commits, 73 parent links and 1,019 changed files.
- The runs are the `runs.json` of the [DuckDB course](../../duckdb/journal/), 125 runs exported around 14:04 UTC, reused as they are.
- The commit dates keep their `-04:00` offset in `commits.csv`; LadybugDB stores them in UTC.

## 2026-09-14 — Installing LadybugDB

- Windows: `lbug_cli-windows-x86_64.zip` from the v0.20.4 release holds only `lbug.exe`, 14,772,736 bytes. `lbug --version` prints `Lbug 0.20.4`.
- CI: the workflow downloads the release asset of each OS (`linux-x86_64`, `windows-x86_64`, `osx-arm64`) and adds the folder to `GITHUB_PATH`. It installs DuckDB 1.5.5 the same way, for the SQL cross-check of lesson 3.
- `INSTALL json` put the extension in `~/.lbdb/extension/0.20.0/win_amd64/json/`: the folder is named after 0.20.0, not 0.20.4. The shell history is in `~/.lbdb/history.txt`.
- In a Git Bash window, `lbug.exe` doesn't find `/c/Users/…` paths, and backslashes in a Cypher string are escape characters: the scripts use paths relative to `code/ladybugdb`, and `C:/…` works when a full path is needed.

## 2026-09-14 — The CI

- The CLI exits with 0 even when a query fails, and prints the errors on standard output ([`embedded_shell.cpp`, lines 608-611](https://github.com/LadybugDB/ladybug/blob/v0.20.4/tools/shell/embedded_shell.cpp#L608-L611)): `check.sh` compares the whole output, errors included, so an unexpected error still fails the job.
- The progress bar writes escape codes even when the output goes to a pipe: `check.sh` passes `--no_progress_bar` and `--no_stats`.
- First push: failed on Linux, passed on Windows and macOS. Deleting a lesson that still had relationships gave a message naming `HAS_LESSON` on Windows and macOS and `LINKS_TO` on Linux: the executor names the first relationship table it checks ([`delete_executor.cpp`, lines 33-42](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/processor/operator/persistent/delete_executor.cpp#L33-L42)), and their order differs. Lesson 1 now deletes a lesson whose relationships are all in one table.
- Same push: `ACYCLIC` gave 14 paths on Windows and 29 on Linux and macOS (see below). Lesson 3 uses `is_acyclic(p)`, the same on all three.
- Two outputs could differ from one run to the next: a `LOAD FROM … LIMIT 3` without `ORDER BY`, and the first missing key reported by a failing `COPY`, which depends on the thread that finds it. The scripts sort, and set `CALL threads = 1` before that `COPY`.
- An unbounded `LINKS_TO*` walk on the site graph ran for more than five minutes before I stopped it; `* SHORTEST` on the same pattern answers at once.

## 2026-09-14 — Surprises while writing lessons 1-4

- `MERGE` matches the whole pattern: without the primary key it fails at bind time, and with the key and another property that differs, it tries to create the node and fails on the duplicate key.
- `:schema` prints `CREATE` statements, with `MANY_MANY` on every relationship table.
- The CSV header is detected without `HEADER = true`, and its names don't have to match the table's columns.
- `SKIP_DUPLICATE_PK = true` works on `COPY` from a file ([`constants.h`, line 111](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L111)) but isn't in the documentation, and isn't supported on `COPY` from a subquery ([`bind_copy_from.cpp`, line 149](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/binder/bind/copy/bind_copy_from.cpp#L149)).
- The CSV sniffer reads the first 256 lines ([`constants.h`, line 144](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L144)); a quoted field further down fails the `COPY` unless `QUOTE` is given.
- Empty CSV fields become `NULL` by default; `NULL_STRINGS = ['NA']` keeps them as `''`.
- `split_part('/es/streeling/', '/', 1)` returns `es`: the empty part before the leading separator is skipped. DuckDB returns `''`.
- `nodes(e)` on a relationship list returns the intermediate nodes only; lists are indexed from 1; `ORDER BY` on a `STRING[]` fails, a cast to `STRING` works.
- Variable-length patterns are walks by default, so two `CHANGED` relationships in one pattern can be the same one.
- The upper bound of a variable-length pattern is limited to 30 ([`client_config.h`, line 32](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/main/client_config.h#L32)) until `CALL var_length_extend_max_depth = …`; a pattern that needs more returns nothing, without an error.
- The 4-link path counts of lesson 3 were checked twice outside LadybugDB: a Python script over `links.csv` (walks 1, 5, 12, 29; trails 26; acyclic 1, 5, 9, 10), and a recursive CTE in DuckDB (walks 1, 5, 12, 29), which the CI runs.

## 2026-09-14 — Bugs found in 0.20.4

Five silent bugs: no error, a wrong result. None had an issue on [LadybugDB's tracker](https://github.com/LadybugDB/ladybug/issues) when I searched on 2026-09-14; I haven't reported them. Each reproduction below runs in an empty in-memory database (`lbug -m csv < repro.cypher`) and was run on Windows only, unless noted.

### 1. `COPY` from a JSON subquery with `MATCH` connects the wrong nodes

With `r.json` holding `[{"id":1,"k":"a"},{"id":2,"k":"b"},{"id":3,"k":"c"}]`:

```cypher
LOAD json;
CREATE NODE TABLE K(k STRING PRIMARY KEY);
CREATE NODE TABLE R(id INT64 PRIMARY KEY);
CREATE REL TABLE ON_K(FROM R TO K);
CREATE (:K {k: 'a'}), (:K {k: 'b'}), (:K {k: 'c'}), (:R {id: 1}), (:R {id: 2}), (:R {id: 3});
COPY ON_K FROM (LOAD FROM 'r.json' WITH id, k MATCH (x:K) WHERE x.k = k RETURN id, k);
MATCH (r:R)-[:ON_K]->(x:K) RETURN r.id, x.k ORDER BY x.k;
```

```text
3 tuples have been copied to the ON_K table.
r.id,x.k
1,a
1,b
1,c
```

Expected `1,a`, `2,b`, `3,c`, which is what the same `COPY` gives from a CSV file with the same rows. With `(IGNORE_ERRORS = true)` added, the three relationships go to `a` instead: `1,a`, `2,a`, `3,a`. Lesson 4 hit it with 123 runs: the 123 relationships all started from the same run; filtering with `WHERE` and no `MATCH` works.

`IGNORE_ERRORS = true` on a `COPY` from a subquery, when a key is missing, fails with `Error: bad variant access` instead of skipping the row.

### 2. `count(DISTINCT …)` before `sum(…)` makes the sum `NULL`

```cypher
CREATE NODE TABLE P(id INT64 PRIMARY KEY, g STRING, n INT64);
CREATE (:P {id: 1, g: 'x', n: 10}), (:P {id: 2, g: 'x', n: 20}), (:P {id: 3, g: 'y', n: 5});
MATCH (p:P) RETURN p.g, count(DISTINCT p) AS ps, sum(p.n) AS total ORDER BY p.g;
MATCH (p:P) RETURN p.g, sum(p.n) AS total, count(DISTINCT p) AS ps ORDER BY p.g;
```

```text
p.g,ps,total
x,2,""
y,1,""
p.g,total,ps
x,30,2
y,5,1
```

The same aggregates, in the other order, give the right totals.

### 3. `ACYCLIC` keeps paths that repeat a node

Three nodes, `a` and `b` linked both ways, `b` linked to `c`:

```cypher
CREATE NODE TABLE V(id STRING PRIMARY KEY);
CREATE REL TABLE E(FROM V TO V);
CREATE (:V {id: 'a'}), (:V {id: 'b'}), (:V {id: 'c'});
MATCH (x:V {id: 'a'}), (y:V {id: 'b'}) CREATE (x)-[:E]->(y), (y)-[:E]->(x);
MATCH (x:V {id: 'b'}), (y:V {id: 'c'}) CREATE (x)-[:E]->(y);
MATCH p = (x:V {id: 'a'})-[e:E* ACYCLIC 1..4]->(y:V {id: 'c'}) RETURN properties(nodes(p), 'id') AS path;
MATCH p = (x:V {id: 'a'})-[e:E*1..4]->(y:V {id: 'c'}) WHERE is_acyclic(p) RETURN properties(nodes(p), 'id') AS path;
```

```text
path
"[a,b,a,b,c]"
"[a,b,c]"
path
"[a,b,c]"
```

`[a,b,a,b,c]` goes through `b` twice. The `ACYCLIC` check is in [`output_writer.cpp`, line 280](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/function/gds/output_writer.cpp#L280); I haven't found the cause. On the site graph of lesson 3, `LINKS_TO* ACYCLIC 1..4` from the GitHub Actions index to its lesson 7 returned 14 paths on Windows, including one through the same lesson twice, and 29, every walk, on the Linux and macOS runners. A Python enumeration gives 25 paths whose intermediate nodes are distinct, and 10 with `is_acyclic`'s definition, both ends included.

### 4. A failed `COPY` into a node table corrupts it

Loaded with `COPY`, then a `COPY` that fails on a duplicate key, with `n.csv` holding the header `k` and the rows `a`, `b`, `c`:

```cypher
CREATE NODE TABLE N(k STRING PRIMARY KEY);
COPY N FROM 'n.csv' (HEADER = true);
COPY N FROM (RETURN 'a' AS k);
MATCH (n:N {k: 'b'}) RETURN count(*) AS b_by_key;
CREATE (:N {k: 'b'});
MATCH (n:N) RETURN n.k ORDER BY n.k;
```

In memory:

```text
Error: Copy exception: Found duplicated primary key value a, which violates the uniqueness constraint of the primary key column.
b_by_key
0
n.k
a
a
b
c
```

`b` is there, but its key finds nothing; the `CREATE` of an existing key succeeds, and the new node holds `a`, the key the failed `COPY` rejected, instead of `b`. In a database file (`lbug -m csv d/x.lbdb`), this sequence works: `b_by_key` is 1 and the `CREATE` fails with `Runtime exception: Found duplicated primary key value b`.

When the three nodes are created with `CREATE` instead of `COPY`, the failed `COPY` breaks a database file too: after it, `CREATE (:N {k: 'z', v: 26})` on a table `N(k STRING PRIMARY KEY, v INT64)` adds a node that reads back as `a,9`, the rejected row, in memory and on disk.

### 5. Grouping by a `COUNT` subquery drops the group of 0

```cypher
CREATE NODE TABLE C(id INT64 PRIMARY KEY);
CREATE REL TABLE PARENT(FROM C TO C);
CREATE (:C {id: 1}), (:C {id: 2}), (:C {id: 3});
MATCH (a:C {id: 2}), (b:C {id: 1}) CREATE (a)-[:PARENT]->(b);
MATCH (a:C {id: 3}), (b:C {id: 2}) CREATE (a)-[:PARENT]->(b);
MATCH (c:C) RETURN c.id, COUNT { MATCH (c)-[:PARENT]->(:C) } AS parents ORDER BY c.id;
MATCH (c:C) RETURN COUNT { MATCH (c)-[:PARENT]->(:C) } AS parents, count(*) AS cs ORDER BY parents;
```

```text
c.id,parents
1,0
2,1
3,1
parents,cs
1,2
```

The subquery returns 0 for node 1, but the grouped query has no `0,1` row. `OPTIONAL MATCH` with `count(…)` gives both groups (lesson 4).

## To verify

- The install script (`curl -s https://install.ladybugdb.com | bash`) and `brew install ladybug`: not run for this course.
- The minimal reproductions were run on Windows only. The course scripts that show bugs 1, 2, 4 and 5 on the site data give the same output on the three CI runners.
- Whether these bugs are already fixed on LadybugDB's main branch, after 0.20.4.
