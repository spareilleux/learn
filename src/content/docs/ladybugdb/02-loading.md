---
title: 2. Loading files
description: Look at CSV files with LOAD FROM, load nodes and relationships with COPY, keep the rows that don't fit as warnings, fill tables from a subquery, and load JSON with the json extension.
sidebar:
  order: 2
---

The site as a graph: one `Page` node per page, one `LINKS_TO` relationship per link between two pages. The data is the six CSV files described on the [Mission page](../#the-data); every query of this lesson is in [`cypher/02-loading.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/02-loading.cypher).

## Looking at a file before loading it

[`LOAD FROM`](https://docs.ladybugdb.com/cypher/query-clauses/load-from/) reads a file as rows, without creating anything, like `OPENROWSET(BULK …)` in SQL Server or `FROM 'file.csv'` in DuckDB ([lines 5-6](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L5-L6)):

```cypher
LOAD FROM 'data/pages.csv' (HEADER = true) RETURN * ORDER BY url LIMIT 3;
LOAD FROM 'data/pages.csv' (HEADER = true) RETURN locale, count(*) AS pages ORDER BY locale;
```

```text
┌─────────────┬────────┬───────────┬──────────────────┬───────┐
│ url         │ locale │ course    │ title            │ lines │
│ STRING      │ STRING │ STRING    │ STRING           │ INT64 │
├─────────────┼────────┼───────────┼──────────────────┼───────┤
│ /           │ en     │           │ learn            │ 90    │
│ /artifacts/ │ en     │ artifacts │ Artifacts        │ 32    │
│ /duckdb/    │ en     │ duckdb    │ DuckDB — Mission │ 70    │
└─────────────┴────────┴───────────┴──────────────────┴───────┘
┌────────┬───────┐
│ locale │ pages │
│ STRING │ INT64 │
├────────┼───────┤
│ en     │ 117   │
│ es     │ 101   │
│ fr     │ 101   │
└────────┴───────┘
```

`HEADER = true` says that the first line holds the column names; on this file, the automatic detection would have found it too. The types are guessed from the content: `lines` is an `INT64`. The home page `/` has no course: its `course` is empty.

## Loading nodes: `COPY FROM`

The tables, then [`COPY`](https://docs.ladybugdb.com/import/csv/), the bulk load ([lines 8-10](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L8-L10)):

```cypher
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/pages.csv' (HEADER = true);
```

```text
┌────────────────────────────────────────────────┬────────────────────────────┬───────────────────────┐
│ result                                         │ skipped_duplicate_pk_count │ skipped_duplicate_pks │
│ STRING                                         │ INT64                      │ STRING[]              │
├────────────────────────────────────────────────┼────────────────────────────┼───────────────────────┤
│ 319 tuples have been copied to the Page table. │ 0                          │ []                    │
└────────────────────────────────────────────────┴────────────────────────────┴───────────────────────┘
```

The columns of the file go to the columns of the table in order; the header names don't have to match. The last two result columns count and list the rows skipped because their key was already in the table, with the option `SKIP_DUPLICATE_PK = true` ([`constants.h`](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L111), not in the documentation). Run twice on `pages.csv` with that option, `COPY` copies 0 rows and lists the 319 URLs; without it, the second run fails, and the last section of this lesson shows what that failure does to the table.

## A relationship needs both of its nodes

In `links.csv`, each row is a link: the page it's on, the page it points to, and the anchor after `#`, if any. For a relationship table, the first two columns are the primary keys of the `FROM` and `TO` nodes; the rest fill the relationship's own columns ([lines 14-16](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L14-L16)):

```cypher
CALL threads = 1;
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true);
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
```

```text
Error: Copy exception: Unable to find primary key value /es/streeling/computer-science/cs-001-governing-agentic-loops/.
┌───────┐
│ links │
│ INT64 │
├───────┤
│ 0     │
└───────┘
```

A link points to a page that isn't in `pages.csv`, and the whole `COPY` fails: zero links loaded, not the rows before the bad one. `COPY` is all or nothing, like a `BULK INSERT` in a transaction.

Why `CALL threads = 1`? `COPY` reads the file with several threads (24 on my machine, the [default](https://docs.ladybugdb.com/cypher/configuration/) being every core), and stops at the first missing page *a thread* finds. Two runs gave two different pages in the message. With one thread, it's always the first bad row of the file, line 127, and the output can be compared in CI.

## Keeping the rows that don't fit: `IGNORE_ERRORS`

With `IGNORE_ERRORS = true`, `COPY` skips the bad rows and keeps a warning for each ([lines 19-21](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L19-L21)):

```cypher
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL show_warnings() RETURN count(*) AS warnings;
CALL show_warnings() RETURN message, file_path, line_number ORDER BY line_number LIMIT 2;
```

```text
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ result                                                                                                            │
│ STRING                                                                                                            │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 648 tuples have been copied to the LINKS_TO table.                                                                │
│ 64 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 8 │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
┌──────────┐
│ warnings │
│ INT64    │
├──────────┤
│ 64       │
└──────────┘
┌──────────────────────────────────────────────────────────────────────────────────────────────────┬────────────────┬─────────────┐
│ message                                                                                          │ file_path      │ line_number │
│ STRING                                                                                           │ STRING         │ UINT64      │
├──────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┼─────────────┤
│ Unable to find primary key value /es/streeling/computer-science/cs-001-governing-agentic-loops/. │ data/links.csv │ 127         │
│ Unable to find primary key value /es/streeling/cybernetics/cyb-001-vsm-ai-governance-mapping/.   │ data/links.csv │ 129         │
└──────────────────────────────────────────────────────────────────────────────────────────────────┴────────────────┴─────────────┘
```

648 + 64 = 712, every row of the file. `show_warnings()` also returns the query id and the skipped line itself. The warnings stay in the connection until `CALL clear_warnings()`, up to `warning_limit`, 8,192 by default.

The 64 messages hold the missing URL after `value `. To group them by locale, split the URL on `/` ([lines 24-28](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L24-L28)):

```cypher
RETURN split_part('/es/streeling/', '/', 1) AS part_1, split_part('/es/streeling/', '/', 2) AS part_2;
CALL show_warnings()
WITH split_part(message, 'value ', 2) AS missing
RETURN split_part(missing, '/', 1) AS locale, split_part(missing, '/', 2) AS course, count(*) AS links
ORDER BY locale, course;
```

```text
┌────────┬───────────┐
│ part_1 │ part_2    │
│ STRING │ STRING    │
├────────┼───────────┤
│ es     │ streeling │
└────────┴───────────┘
┌────────┬───────────┬───────┐
│ locale │ course    │ links │
│ STRING │ STRING    │ INT64 │
├────────┼───────────┼───────┤
│ es     │ streeling │ 32    │
│ fr     │ streeling │ 32    │
└────────┴───────────┴───────┘
```

**Part 1 of `/es/streeling/` is `es`**: LadybugDB's [`split_part`](https://docs.ladybugdb.com/cypher/expressions/text-functions/) ignores the empty string before the leading `/`. DuckDB and PostgreSQL return that empty string as part 1, and `es` as part 2. My first version of this query used 2 and 3, and grouped by course under a column named `locale`; the first query above is there to catch it.

`WITH` passes rows from one part of a query to the next, like a CTE: here, the `missing` URL computed once for both `split_part` calls.

All 64 missing pages are Streeling University modules in French and Spanish. [Starlight](https://starlight.astro.build/guides/i18n/#fallback-content) serves the English page at a translated URL that has no page of its own, so these links work on the site, but there is no French or Spanish file for these modules, and no node.

## Files and graph in the same query

Which English pages do those French links point to? The query reads `links.csv` again, and checks each row against the graph ([lines 31-36](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L31-L36)):

```cypher
LOAD FROM 'data/links.csv' (HEADER = true)
WITH `from`, `to`
WHERE `to` STARTS WITH '/fr/' AND NOT EXISTS { MATCH (p:Page) WHERE p.url = `to` }
MATCH (en:Page) WHERE en.url = substring(`to`, 4, size(`to`))
RETURN DISTINCT en.url AS english_page
ORDER BY english_page;
```

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ english_page                                                            │
│ STRING                                                                  │
├─────────────────────────────────────────────────────────────────────────┤
│ /streeling/computer-science/cs-001-governing-agentic-loops/             │
│ /streeling/cybernetics/cyb-001-vsm-ai-governance-mapping/               │
│ /streeling/cybernetics/cyb-002-active-dampening-cross-repo-oscillation/ │
│ /streeling/cybernetics/cyb-003-measuring-variety-ratio-quantitatively/  │
│ /streeling/guitar-alchemist-academy/gaa-002-training-your-ear/          │
│ /streeling/guitar-alchemist-academy/gaa-003-improvisation-foundations/  │
│ /streeling/information-theory/inf-001-entropy-of-governance/            │
│ /streeling/music/mus-002-beyond-tonality/                               │
│ /streeling/music/mus-003-functional-harmony/                            │
│ /streeling/music/mus-004-rhythm-and-groove/                             │
│ /streeling/music/mus-005-jazz-harmony/                                  │
│ /streeling/music/mus-006-the-scale-universe/                            │
│ /streeling/musicology/mcl-002-musical-form/                             │
│ /streeling/network-science/net-001-scale-free-tool-networks/            │
│ /streeling/psychohistory/psy-002-governance-phase-transitions/          │
│ /streeling/semiotics/sem-001-signs-in-governance/                       │
└─────────────────────────────────────────────────────────────────────────┘
```

Three things in this query:

- Backticks quote a name, like square brackets in T-SQL. `from` and `to` would work without them in this query, but they are keywords of `CREATE REL TABLE … (FROM Page TO Page)`, and quoting them avoids the question.
- `substring` counts from 1, like SQL: `substring('/fr/streeling/…', 4, …)` starts at the `/` after `fr`.
- A query can start from a file and continue in the graph: `LOAD FROM`, then `WITH … WHERE`, then `MATCH`. For each file row left after the filter, `MATCH` finds the English page.

## Node tables from a subquery

The external links, 3,712 rows of `external_links.csv` (`from`, `url`, `domain`), become a `Domain` node per site and a `CITES` relationship per page and site, with the number of links as a property. [`COPY` can read a subquery](https://docs.ladybugdb.com/import/copy-from-subquery/) instead of a file ([lines 39-41](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L39-L41)):

```cypher
CREATE NODE TABLE Domain(name STRING PRIMARY KEY);
CREATE REL TABLE CITES(FROM Page TO Domain, links INT64);
COPY Domain FROM (LOAD FROM 'data/external_links.csv' (HEADER = true) RETURN DISTINCT domain);
```

```text
Error: Copy exception: Error in file data/external_links.csv on line 591: expected 3 values per row, but got more. Line/record containing the error: '/es/java-for-csharp/02-types-and-operators/,"https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Math.html#addExact(int,int)",docs.oracle.com'
```

Line 591 is the first line of the file with quotes: Python's `csv` module only quotes the fields that need it, like this URL with a comma in `addExact(int,int)`. By default, LadybugDB detects the delimiter, the quote and the escape characters from the first 256 lines of the file ([`auto_detect` and `sample_size`](https://docs.ladybugdb.com/import/csv/), [`constants.h`](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L138-L144)). It saw no quote in those lines, read the file without one, and found four fields on line 591. Say it explicitly ([lines 44-46](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L44-L46)):

```cypher
COPY Domain FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN DISTINCT domain);
COPY CITES FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN `from`, domain, count(*));
MATCH (d:Domain) RETURN count(*) AS domains;
```

```text
┌─────────────────────────────────────────────────┬────────────────────────────┬───────────────────────┐
│ result                                          │ skipped_duplicate_pk_count │ skipped_duplicate_pks │
│ STRING                                          │ INT64                      │ STRING[]              │
├─────────────────────────────────────────────────┼────────────────────────────┼───────────────────────┤
│ 85 tuples have been copied to the Domain table. │ 0                          │ []                    │
└─────────────────────────────────────────────────┴────────────────────────────┴───────────────────────┘
┌──────────────────────────────────────────────────┐
│ result                                           │
│ STRING                                           │
├──────────────────────────────────────────────────┤
│ 1054 tuples have been copied to the CITES table. │
└──────────────────────────────────────────────────┘
┌─────────┐
│ domains │
│ INT64   │
├─────────┤
│ 85      │
└─────────┘
```

The subquery's columns play the role of the file's: `from` and `domain` are the keys of the two nodes, `count(*)` fills `links`. 1,054 pairs of a page and a site.

## Which sites the course pages cite

[Lines 47-51](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L47-L51):

```cypher
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en'
RETURN d.name AS domain, count(*) AS pages, sum(c.links) AS links
ORDER BY links DESC, domain
LIMIT 8;
```

```text
┌─────────────────────┬───────┬────────┐
│ domain              │ pages │ links  │
│ STRING              │ INT64 │ INT128 │
├─────────────────────┼───────┼────────┤
│ learn.microsoft.com │ 44    │ 198    │
│ doc.rust-lang.org   │ 16    │ 192    │
│ github.com          │ 88    │ 189    │
│ docs.oracle.com     │ 28    │ 171    │
│ duckdb.org          │ 9     │ 140    │
│ docs.github.com     │ 12    │ 51     │
│ openjdk.org         │ 15    │ 49     │
│ docs.rs             │ 5     │ 30     │
└─────────────────────┴───────┴────────┘
```

A relationship variable, `c`, gives access to the relationship's properties like a node variable. `sum` of an `INT64` returns an `INT128`, a wider type. GitHub is cited by the most pages, Microsoft Learn by the most links.

## A bug in 0.20.4: `count(DISTINCT …)` before `sum(…)`

The same aggregates, with `count(DISTINCT p)` instead of `count(*)`, for two domains ([lines 54-61](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L54-L61)):

```cypher
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en' AND d.name IN ['duckdb.org', 'openjdk.org']
RETURN d.name AS domain, count(DISTINCT p) AS pages, sum(c.links) AS links
ORDER BY domain;
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en' AND d.name IN ['duckdb.org', 'openjdk.org']
RETURN d.name AS domain, sum(c.links) AS links, count(DISTINCT p) AS pages
ORDER BY domain;
```

```text
┌─────────────┬───────┬────────┐
│ domain      │ pages │ links  │
│ STRING      │ INT64 │ INT128 │
├─────────────┼───────┼────────┤
│ duckdb.org  │ 9     │        │
│ openjdk.org │ 15    │        │
└─────────────┴───────┴────────┘
┌─────────────┬────────┬───────┐
│ domain      │ links  │ pages │
│ STRING      │ INT128 │ INT64 │
├─────────────┼────────┼───────┤
│ duckdb.org  │ 140    │ 9     │
│ openjdk.org │ 49     │ 15    │
└─────────────┴────────┴───────┘
```

The two queries differ only in the order of the columns. In the first one, `links` is `NULL` (an empty cell) for both domains; in the second, it's 140 and 49, the numbers of the previous query. There is no error and no warning: a wrong result looks like a right one. The [journal](../journal/) keeps the details. Until it's fixed, put `count(DISTINCT …)` last, or compare an aggregate with a second query when the result matters.

## JSON: the json extension

The CI runs of the DuckDB course are in a JSON file ([lines 64-66](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L64-L66)):

```cypher
LOAD FROM '../duckdb/data/runs.json' RETURN count(*);
LOAD json;
LOAD FROM '../duckdb/data/runs.json' RETURN conclusion, count(*) AS runs ORDER BY runs DESC, conclusion;
```

```text
Error: Binder exception: Cannot load from file type json. If this file type is part of a lbug extension please load the extension then try again.
┌──────────────────────────────────┐
│ result                           │
│ STRING                           │
├──────────────────────────────────┤
│ Extension: json has been loaded. │
└──────────────────────────────────┘
┌─────────────────┬───────┐
│ conclusion      │ runs  │
│ STRING          │ INT64 │
├─────────────────┼───────┤
│ success         │ 104   │
│ failure         │ 16    │
│ cancelled       │ 4     │
│ startup_failure │ 1     │
└─────────────────┴───────┘
```

JSON support is an [extension](https://docs.ladybugdb.com/extensions/json/), in two steps:

- `INSTALL json;` downloads it once per machine, from `https://extension.ladybugdb.com/`. On my machine, it landed in `~/.lbdb/extension/0.20.0/win_amd64/json/libjson.lbug_extension`. `check.sh` runs it before the scripts, because its message differs the first time (`Extension: json installed from the repo: https://extension.ladybugdb.com/.`) and the next ones (`Extension: json is already installed.`).
- `LOAD json;` loads it into the current database, every time the CLI starts.

125 runs, the same counts as in the DuckDB course. The JSON array's objects become rows, their fields columns.

## A bug in 0.20.4: a failed `COPY` empties the primary key index

A last `COPY` of a page that is already there, [lines 69-72](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L69-L72):

```cypher
COPY Page FROM (LOAD FROM 'data/pages.csv' (HEADER = true) WHERE url = '/duckdb/' RETURN *);
MATCH (p:Page) RETURN count(*) AS pages;
MATCH (p:Page {url: '/duckdb/'}) RETURN count(*) AS found_by_key;
MATCH (p:Page) WHERE lower(p.url) = '/duckdb/' RETURN count(*) AS found_by_scan;
```

```text
Error: Copy exception: Found duplicated primary key value /duckdb/, which violates the uniqueness constraint of the primary key column.
┌───────┐
│ pages │
│ INT64 │
├───────┤
│ 319   │
└───────┘
┌──────────────┐
│ found_by_key │
│ INT64        │
├──────────────┤
│ 0            │
└──────────────┘
┌───────────────┐
│ found_by_scan │
│ INT64         │
├───────────────┤
│ 1             │
└───────────────┘
```

The error is expected, and the 319 pages are still there. But the page can no longer be found by its key: `{url: '/duckdb/'}` and `WHERE p.url = '/duckdb/'` both go through the primary key index, and find nothing. `lower(p.url)` can't use the index, reads every node, and finds the page. It isn't only `/duckdb/`: after the failed `COPY`, none of the 319 keys is found, and a `CREATE` with an existing key succeeds, creating a duplicate.

In a database file, the same sequence works: the index still finds the page after the failed `COPY`, and the `CREATE` is rejected. The scripts of this course use an in-memory database, where it breaks. The [journal](../journal/) has the minimal reproduction, with three rows, and a worse variant that breaks database files too, when the nodes were created with `CREATE` rather than loaded with `COPY`. Until it's fixed, treat a failed `COPY` into a node table as the end of that table: recreate it.

## Key takeaways

- `LOAD FROM` reads a file as rows; `COPY FROM` bulk-loads a file or a subquery into a node or relationship table.
- For a relationship table, the first two columns are the keys of the nodes; a missing node fails the whole `COPY`.
- `IGNORE_ERRORS = true` keeps the bad rows as warnings, which `CALL show_warnings()` returns as rows.
- The CSV dialect is detected from the first 256 lines: pass `QUOTE`, `DELIM` and `ESCAPE` when you know them.
- `split_part` counts parts differently from SQL, `count(DISTINCT …)` before `sum(…)` returns `NULL`, and a failed `COPY` empties the key index of an in-memory table in 0.20.4: check results that matter another way.
- JSON needs `INSTALL json` once and `LOAD json` in each session.

## Exercises

The solutions are in [`cypher/02-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/02-exercises.cypher), checked by CI. They start from the `Page`, `LINKS_TO`, `Domain` and `CITES` tables, loaded as in this lesson.

1. Which English pages have no French version, per course?

<details>
<summary>Solution</summary>

From [`02-exercises.cypher`, lines 13-16](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-exercises.cypher#L13-L16):

```cypher
MATCH (en:Page)
WHERE en.locale = 'en' AND NOT EXISTS { MATCH (fr:Page) WHERE fr.url = '/fr' + en.url }
RETURN en.course, count(*) AS pages
ORDER BY pages DESC, en.course;
```

```text
┌───────────┬───────┐
│ en.course │ pages │
│ STRING    │ INT64 │
├───────────┼───────┤
│ streeling │ 16    │
└───────────┴───────┘
```

The 16 Streeling modules of the lesson, and nothing else: every course page has its French mirror. `+` concatenates strings.

</details>

2. How many links have an anchor (a `#` part)? Compare `anchor IS NULL` and `anchor = ''`.

<details>
<summary>Solution</summary>

From [`02-exercises.cypher`, lines 19-21](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-exercises.cypher#L19-L21):

```cypher
MATCH ()-[l:LINKS_TO]->()
RETURN l.anchor IS NULL AS no_anchor, l.anchor = '' AS empty_anchor, count(*) AS links
ORDER BY no_anchor;
```

```text
┌───────────┬──────────────┬───────┐
│ no_anchor │ empty_anchor │ links │
│ BOOL      │ BOOL         │ INT64 │
├───────────┼──────────────┼───────┤
│ False     │ False        │ 3     │
│ True      │              │ 645   │
└───────────┴──────────────┴───────┘
```

Three links have an anchor. For the 645 others, the empty field of the CSV file became `NULL`, not `''`: the `NULL_STRINGS` option of `COPY` defaults to the empty string. So `l.anchor = ''` is `NULL` (the empty cell), and a filter `WHERE l.anchor = ''` would find nothing. Pass `NULL_STRINGS = ['NA']`, or any value the file doesn't use, to keep empty strings.

</details>

3. Which sites are cited by the most English courses?

<details>
<summary>Solution</summary>

From [`02-exercises.cypher`, lines 24-28](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-exercises.cypher#L24-L28):

```cypher
MATCH (p:Page)-[:CITES]->(d:Domain)
WHERE p.locale = 'en'
RETURN d.name AS domain, count(DISTINCT p.course) AS courses
ORDER BY courses DESC, domain
LIMIT 5;
```

```text
┌──────────────────────┬─────────┐
│ domain               │ courses │
│ STRING               │ INT64   │
├──────────────────────┼─────────┤
│ github.com           │ 6       │
│ learn.microsoft.com  │ 5       │
│ www.nuget.org        │ 4       │
│ central.sonatype.com │ 3       │
│ docs.oracle.com      │ 3       │
└──────────────────────┴─────────┘
```

`count(DISTINCT p.course)` counts courses, not pages. Alone in the `RETURN`, it doesn't trigger the bug of this lesson, which needs a `sum` after it. The home page, the method and the artifacts page count as courses here (`''`, `method` and `artifacts`), which is why GitHub reaches 6.

</details>

## Sources

- [`LOAD FROM`](https://docs.ladybugdb.com/cypher/query-clauses/load-from/)
- [Import CSV](https://docs.ladybugdb.com/import/csv/): options, `IGNORE_ERRORS`, dialect detection
- [`COPY FROM` a subquery](https://docs.ladybugdb.com/import/copy-from-subquery/)
- [Configuration](https://docs.ladybugdb.com/cypher/configuration/): `threads`, `warning_limit`
- [Text functions](https://docs.ladybugdb.com/cypher/expressions/text-functions/) and [aggregate functions](https://docs.ladybugdb.com/cypher/expressions/aggregate-functions/)
- [JSON extension](https://docs.ladybugdb.com/extensions/json/)
- LadybugDB 0.20.4 source: [CSV constants](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L138-L144), [CSV reader errors](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/processor/operator/persistent/reader/csv/driver.cpp#L38)
