---
title: Journal
description: Dated progress notes — data, CI runs, bugs found in LadybugDB 0.20.4 and in the 0.19.1 NuGet package, and items to verify.
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
- [x] Data: the .NET projects of GuitarAlchemist/ga at commit `a26a7893`
- [x] Lesson 5: LadybugDB from C#
- [x] Lesson 6: LadybugDB from Java
- [x] Lesson 7: graph algorithms and full-text search
- [x] Lesson 8: persistence, transactions and concurrency

## QA

LadybugDB 0.20.4 is somebody else's database, and writing eight lessons against it turned up nine findings. Six are silent bugs — no error, a wrong result — each with a reproduction that runs in an empty in-memory database; none of them had an upstream issue when the tracker was searched on 2026-09-14, and none has been reported. The last three come from the lessons themselves, and one of them was already open upstream.

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| `COPY` into a rel table from a subquery connects the nodes the `MATCH` found | It connects the wrong nodes: the keys are matched positionally rather than by the `MATCH` | `COPY … FROM (LOAD FROM … MATCH …)` | Reproduction 1 [2026-09-14](#2026-09-14--bugs-found-in-0204) | Reproduced, no upstream issue, not reported |
| `count(DISTINCT …)` beside `sum(…)` leaves the sum alone | The `sum` comes back `NULL` when a `count(DISTINCT …)` precedes it | Aggregation | Reproduction 2 [2026-09-14](#2026-09-14--bugs-found-in-0204) | Reproduced, no upstream issue, not reported |
| `ACYCLIC` drops every path that repeats a node | It keeps some of them | Recursive path patterns | Reproduction 3 [2026-09-14](#2026-09-14--bugs-found-in-0204) | Reproduced, no upstream issue, not reported |
| A `COPY` that fails leaves the node table as it was | It corrupts the table | `COPY` into a node table | Reproduction 4 [2026-09-14](#2026-09-14--bugs-found-in-0204) | Reproduced, no upstream issue, not reported |
| Grouping by a `COUNT` subquery keeps the group whose count is 0 | That group is dropped | `GROUP BY` over a subquery | Reproduction 5 [2026-09-14](#2026-09-14--bugs-found-in-0204) | Reproduced, no upstream issue, not reported |
| `timestamp()` and `CAST(… AS TIMESTAMP)` honour the offset in the literal | Both ignore it | Temporal conversion | Reproduction 6 [2026-09-14](#2026-09-14--bugs-found-in-0204) | Reproduced, no upstream issue, not reported |
| `INSTALL algo` fetches the build matching the CLI | The 0.20.4 CLI downloads the 0.20.0 build, and `LOAD algo` then fails on all three runners, with paths from LadybugDB's own build machine in the message | `algo` extension, CLI 0.20.4 | `libnetworkit.so: cannot open shared object file` on Linux, `Library not loaded: @rpath/libnetworkit.dylib` on macOS, `The specified module could not be found.` on Windows | Open upstream as [issue #857](https://github.com/LadybugDB/ladybug/issues/857), not opened by this course [2026-09-14](#2026-09-14--lesson-7-extensions-algorithms-and-full-text-search) |
| Louvain gives the same communities for the same graph and the same thread count | The sizes differ from one process to the next, with `CALL threads = 1` set | `algo` extension, Louvain | `[27,20,17,14,14]` in one process, `[25,20,18,18,11]` in the next two; three calls inside one process agree. Nodes with no relationship get `louvain_id` -1 | Reproduced, not reported [2026-09-14](#2026-09-14--lesson-7-extensions-algorithms-and-full-text-search) |
| A read-only process and a writer on one file behave as the documentation says | The [concurrency page](https://docs.ladybugdb.com/concurrency/) says the combination is not allowed, but it is what happens: a read-only process opens a writer's file on Linux and macOS and sees committed changes through the `.wal`; a writer opens and checkpoints a file a reader holds, on all three, and the reader keeps answering from the old state | [`storage_manager.cpp` 87-91](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/storage/storage_manager.cpp#L87-L91) | On Windows the writer's `LockFileEx` makes the read fail with `Error 33` instead | Reproduced; documentation and behaviour disagree [2026-09-14](#2026-09-14--lesson-8-transactions-files-and-processes) |

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

## 2026-09-14 — Lesson 5: the ga data and the C# package

- [`data/ga/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/ga/extract.py) needs only the project files: a clone with `--filter=blob:none` and a sparse checkout of `*.csproj`, `*.fsproj` and `*.slnx` downloads the project files of ga without the rest of its content. It skips the copies under `.claude` folders.
- 111 projects, 266 project references, 478 package references, 136 packages. One reference goes to `reactapp1.client.esproj`, a JavaScript project the extraction doesn't keep: the lesson loads the references with `IGNORE_ERRORS`.
- The `version` column is what each project file says. ga's `Directory.Build.props` overrides 14 packages with `PackageReference Update`, and the extraction doesn't apply them; the lesson's queries avoid those packages.
- Two projects are named `GaApi.Tests`, in `Tests/Apps/GaApi.Tests` and `Tests/GaApi.Tests`; the second isn't in `AllProjects.slnx`. 38 projects in all aren't in it.
- NuGet: `LadybugDB` has three versions, `0.17.0-alpha.1`, `0.18.2` and `0.19.1`; 0.19.1 embeds the 0.19.1 engine, storage version 43. The binding isn't ADO.NET and has no page on docs.ladybugdb.com: I read its source at commit [`0f58f1a`](https://github.com/LadybugDB/ladybug-dotnet/tree/0f58f1a).
- First CI push: the C# job failed on the three OSes. The internal ID of `GaApi` was `0:11` on Windows and `0:47` on Linux and macOS, from the same CSV; `SHORTEST` chose a path through `GA.Business.ML` on my machine and through `GA.Business.AI` on the runners, among two of the same length; and the CLI on the Linux runner printed `Warning: failed to create directory: /home/runner/.lbdb/` when opening a file read-only. The program now compares IDs instead of printing them and lists the `ALL SHORTEST` paths sorted; `check.sh` filters the warning.
- The 0.20.4 CLI, opening a 0.19.1 database file read-write, rewrites it to storage version 47 without a message; the 0.19.1 package then fails with `Failed to open Ladybug database at '…'`, without the reason. `--read_only` leaves the file readable by both.
- The binding doesn't expose `lbug_query_result_has_next_query_result`, `lbug_connection_interrupt` or `lbug_connection_set_query_timeout` of the C API: a `Query` with several statements returns the first result only, and a long query can't be stopped from C#.

## 2026-09-14 — Lesson 6: the Java package

- `com.ladybugdb:lbug` 0.20.4 on Maven Central: one jar of 29,339,834 bytes with the native library for `linux_amd64`, `linux_arm64`, `osx_arm64` and `windows_amd64`, no `osx_amd64`. It pulls 13 more jars, 7 MB: `kotlin-stdlib` 2.3.20, Apache Arrow 18.2.0, Jackson, FlatBuffers, commons-codec and SLF4J.
- The sources jar matches the [`ladybug-java`](https://github.com/LadybugDB/ladybug-java) repository at `f2fb39f`, the submodule commit of LadybugDB v0.20.4. The sources live in a `com/lbugdb` folder, but the package is `com.ladybugdb`.
- The [Java page of the documentation](https://docs.ladybugdb.com/client-apis/java/) still shows `throws ObjectRefDestroyedException`; 0.20.4 throws `RuntimeException` with messages such as `Connection has been destroyed.`
- A failed query returns a result with `isSuccess()` false; `getNext()` on it throws `RuntimeException` with the same message.
- A `PreparedStatement` keeps the values of its last execution: `execute(statement, Map.of("nom", 5))` after `Map.of("n", 2.5)` runs with `n = 2.5` and no error. On a new statement, the same map fails with `Parameter n not found.`
- `Value.getValue()` throws `Type of value is not supported in value_get_value` for `LIST` and `MAP`, and doesn't handle `STRUCT`, `NODE`, `REL` or `RECURSIVE_REL` either; the `LbugList`, `LbugStruct`, `LbugMap` and `Value…Util` classes read them.
- `interval('1 month 2 days')` comes back as `PT768H`: the JNI code converts the interval to seconds with 30-day months.
- `setQueryTimeout(1)` stops the walks of lesson 3 with `Interrupted.`, and `getNextQueryResult()` reads the second statement of a query: both missing from the .NET package.
- The native library is copied to a new temporary file at each JVM start, and `deleteOnExit` can't delete a loaded DLL on Windows: 13 copies, 190 MB, in `%TEMP%` after the runs of this lesson on my machine, 3 copies on the Windows runner after three runs, none on the Linux and macOS runners.
- The first CI push of the Java job passed on the three OSes: lesson 5 had already made the output independent of internal IDs and of the path `SHORTEST` chooses.

## 2026-09-14 — Lesson 7: extensions, algorithms and full-text search

- With the 0.20.4 CLI, `INSTALL algo` downloads the build for 0.20.0, and `LOAD algo` fails on the three CI runners: `libnetworkit.so: cannot open shared object file` on Linux, `Library not loaded: @rpath/libnetworkit.dylib` on macOS, with paths of LadybugDB's own build machine in the message, and `The specified module could not be found.` on Windows. [Issue #857](https://github.com/LadybugDB/ladybug/issues/857) is open.
- `LOAD fts` works with 0.20.4 on the three runners, but on my Windows machine the CLI exits with `0xC0000409`, without printing anything, at the first `CREATE_FTS_INDEX`, even on a table of one row. On Linux (WSL), the same script works with 0.20.4.
- The 0.19.1 CLI downloads the builds for 0.19.0; `algo` and `fts` load and give the same output on Windows, Linux and macOS. The CI installs it as `lbug19`; `check.sh` prints the result of `LOAD algo` and `LOAD fts` with 0.20.4 at each run, without comparing it.
- The Windows CLI, 0.19.1 and 0.20.4, imports `libssl-3-x64.dll` and `libcrypto-3-x64.dll`, not in the zip file; with only `C:\Windows\System32` in the `PATH`, it exits with `0xC0000135`. Git for Windows provides both DLLs. Lesson 1 now says so.
- `project_graph_cypher` isn't in the documentation. It creates a graph of type `CYPHER`, and `page_rank` and `weakly_connected_components` on it fail with `Binder exception: AA`: [`gds.cpp`, line 72](https://github.com/LadybugDB/ladybug/blob/v0.19.1/src/function/gds/gds.cpp#L72), still there in 0.20.4. The engine's test of the function only creates the graph. Minimal reproduction, with 0.19.1 on Windows:

```cypher
LOAD algo;
CREATE NODE TABLE P(id INT64 PRIMARY KEY, age INT64);
CREATE REL TABLE E(FROM P TO P);
CREATE (:P {id: 1, age: 5}), (:P {id: 2, age: 20}), (:P {id: 3, age: 7});
MATCH (a:P {id: 1}), (b:P {id: 3}) CREATE (a)-[:E]->(b);
CALL project_graph_cypher('G1', 'MATCH (n:P) WHERE n.age < 10 RETURN n');
CALL page_rank('G1') RETURN node.id, rank;
```

- Louvain on the ga graph: 5 communities of sizes `[27,20,17,14,14]` in one CLI process, `[25,20,18,18,11]` in the next two, with `CALL threads = 1`; three calls in one process give the same sizes. Nodes without any relationship get `louvain_id` -1.
- PageRank ranks sum to 0.3534 on the ga graph: the 25 projects without an outgoing reference don't pass their rank on. Exercise 1 recomputes two ranks with `(1 - 0.85) / N + 0.85 × Σ rank / out_degree`, to four decimals.
- `RETURN n + sum(x)`, with `n` from `WITH count(*) AS n`, fails with `Cannot evaluate expression with type AGGREGATE_FUNCTION.`; `RETURN n, n + sum(x)` works, and so does `RETURN 2 * sum(x)`.
- FTS: the English stemmer matches *queries* for *query* and *Persistance* for *persistant*; the French stemmer doesn't match *Persistence*. Case is folded, accents aren't (`donnees` finds nothing). The default stop words are English whatever the stemmer. After a `CREATE`, the index includes the new node and the other scores change. `DROP_FTS_INDEX` reports `Table 3_titles_fr_terms has been dropped.`, an internal table.

## 2026-09-14 — Lesson 8: transactions, files and processes

- An error inside a manual transaction rolls the whole transaction back and ends it, without a message saying so: runtime errors (a duplicate key), binder errors, catalog errors, a `BEGIN` inside a transaction and `CHECKPOINT` inside a transaction all do it. The statements that follow run in auto-commit; `ROLLBACK` and `COMMIT` then fail with `No active transaction`. The only exception found: a write inside `BEGIN TRANSACTION READ ONLY` fails, and the transaction stays open. The [transactions page](https://docs.ladybugdb.com/cypher/transaction/) promises that nothing of a failed transaction persists, and doesn't say that the statements after the error run on their own.
- A second write transaction is refused at once, `Cannot start a new write transaction in the system. Only one write transaction at a time is allowed in the system.`, even when it touches other nodes; there's no waiting and no timeout. A refused auto-commit statement leaves the connection usable.
- Java, **a refused `BEGIN TRANSACTION` breaks the connection**: the next query throws `RuntimeException: Unknown Error` on Windows, and crashes the JVM with `SIGSEGV` on Linux (`CatalogSet::traverseVersionChainsForTransactionNoLock`) and macOS (`CatalogSet::containsEntry`), exit code 134. A `BEGIN` that succeeds repairs the connection on Windows; a retried `BEGIN` doesn't crash on any of the three runners (exercise 2: 153, 155 and 24 refusals). Minimal reproduction, an in-memory `Database` and two connections: `first` runs `BEGIN TRANSACTION`, `second` runs `BEGIN TRANSACTION` (refused), `first` runs `COMMIT`, `second` runs any `MATCH`. The C# package and the other bindings weren't tested.
- The files: `.wal` appears at the first commit and disappears at the checkpoint when the database closes; no `.wal` for an uncommitted transaction. `kill -9` after a commit leaves the `.wal`, replayed by the next open; `kill -9` inside a transaction loses the transaction. Closing a Java `Database` with an open transaction rolls it back.
- A second read-write process fails with `Could not set lock on file`, followed by `(Error: 33)` on Windows and `(Error: Resource temporarily unavailable)` on Linux. The POSIX code closes the file descriptor before `F_GETLK`, so its `Lock is held by PID` message can't appear ([`local_file_system.cpp`, lines 147-172](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/common/file_system/local_file_system.cpp#L147-L172)).
- **A read-only database takes no lock** ([`storage_manager.cpp`, lines 87-91](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/storage/storage_manager.cpp#L87-L91)). A read-only process opens a file a writer holds on Linux and macOS, and sees the writer's committed changes from the `.wal`; not on Windows, where the writer's `LockFileEx` makes the read fail with `Error 33`. A writer opens, writes and checkpoints a file a read-only process holds, on the three OSes, and the reader keeps answering from the old state. The [concurrency page](https://docs.ladybugdb.com/concurrency/) says this combination isn't allowed.
- In one Java process, a second read-write `Database`, or a read-only one, on a file a read-write `Database` holds: refused on Windows, opened on Linux and macOS (`fcntl` locks belong to the process).
- `new Database(path)` throws `java.lang.Exception`, a checked exception it doesn't declare ([`lbug_java.cpp`, lines 618-636](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L618-L636)).
- `EXPORT DATABASE` in CSV writes the macros into `schema.cypher`; the [migration page](https://docs.ladybugdb.com/migrate/) lists a `macro.cypher` file that isn't created. The CSV headers are prefixed with `a.`. The order of the options in `copy.cypher` differs between Windows and Linux or macOS. `IMPORT DATABASE` into a non-empty database fails with `Project already exists in catalog.`
- 0.20.4 opened read-only leaves a 0.19.1 file as it is; opened read-write, it upgrades it from storage version 43 to 47 without a message, and the 0.19.1 CLI then says `Database file version: 47, Current build storage version: 43`.
- CI: the first run failed on the three `cypher` jobs, because `files.sh`, run under `set -e`, returned the exit code of the last 0.19.1 CLI; `check.sh` now ignores it and compares the output. The `java` jobs on Linux and macOS crashed at the refused `BEGIN`, now in a mode of its own. The second run failed on macOS only: `ls` sorted `Project.csv` after `copy.cypher`; the script sorts with `LC_ALL=C`.
- With its output redirected to a file, the CLI writes nothing until it exits: `files.sh` waits for the `.wal` file, or a fixed time, rather than for a line of output.

## 2026-09-14 — Bugs found in 0.20.4

Six silent bugs: no error, a wrong result. None had an issue on [LadybugDB's tracker](https://github.com/LadybugDB/ladybug/issues) when I searched on 2026-09-14; I haven't reported them. Each reproduction below runs in an empty in-memory database (`lbug -m csv < repro.cypher`) and was run on Windows only, unless noted.

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

Lesson 5 found a more general form, in the 0.19.1 engine of the NuGet package too: with a grouping key, an aggregate after a `DISTINCT` aggregate in the same projection is wrong. `RETURN k.name, collect(DISTINCT u.version) AS versions, count(*) AS projects` gives 0 projects for `MongoDB.Driver` instead of 14.

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

### 6. `timestamp()` and `CAST(… AS TIMESTAMP)` ignore the offset

```cypher
RETURN timestamp('2026-09-14T09:30:00-04:00') AS f, CAST('2026-09-14T09:30:00-04:00' AS TIMESTAMP) AS c, CAST('2026-09-14T09:30:00-04:00' AS TIMESTAMP_TZ) AS tz;
```

```text
f,c,tz
2026-09-14 09:30:00,2026-09-14 09:30:00,2026-09-14 13:30:00+00
```

Expected 13:30 for the first two as well: `COPY` and `LOAD FROM` convert the same text in a CSV file to 13:30 UTC (lesson 4). The offset is dropped without being applied. `timestamp(…)` in the C# package 0.19.1 returns 09:30 too (lesson 5).

## To verify

- The install script (`curl -s https://install.ladybugdb.com | bash`) and `brew install ladybug`: not run for this course.
- The minimal reproductions were run on Windows only. The course scripts that show bugs 1, 2, 4 and 5 on the site data give the same output on the three CI runners.
- Whether these bugs are already fixed on LadybugDB's main branch, after 0.20.4.
- Whether the major version conflicts of lesson 5's exercise 2 (`MongoDB.Driver` 2 and 3, `Microsoft.ML.Tokenizers` 1 and 2) break ga at run time: I haven't built or run ga.
- The C# program on `linux-arm64` and `osx-x64`, and the Java program on `linux_arm64`: the CI runners are `linux-x64`, `win-x64` and `osx-arm64`.
- Whether `CREATE_FTS_INDEX` also crashes the 0.20.4 CLI on the Windows runner: the CI runs lesson 7 with 0.19.1 only.
- Whether the two isolated projects of `Common`, `GA.Business.DSL.SourceGen` and `GA.Business.Core.Generated`, are used in ga some other way than a `ProjectReference`.
- Whether a read-only process that stays open while a writer checkpoints returns wrong data, and not only old data, when it reads pages it hadn't cached (lesson 8).
- On Linux and macOS, whether closing the second `Database` of a process releases the `fcntl` lock of the first one, as closing any descriptor of a file releases the process's locks on it, and lets another process open the file read-write.
- Whether a refused `BEGIN` also breaks a connection of the C# package and of the other bindings.
