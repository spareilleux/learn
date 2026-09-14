---
title: 3. Paths
description: Patterns of several hops, OPTIONAL MATCH and COUNT subqueries, then variable-length relationships — walks, trails and acyclic paths — shortest paths, filters along a path and the depth limit, checked against a recursive CTE.
sidebar:
  order: 3
---

The graph of lesson 2, `Page` nodes and `LINKS_TO` relationships, loaded at the top of [`cypher/03-paths.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/03-paths.cypher) with the same `COPY` statements. This lesson asks it questions about paths: how many clicks, through which pages.

## Several hops

A pattern can chain relationships. The lessons of the DuckDB course, reached from the home page through the course index ([lines 9-12](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L9-L12)):

```cypher
MATCH (home:Page {url: '/'})-[:LINKS_TO]->(course:Page)-[:LINKS_TO]->(lesson:Page)
WHERE course.course = 'duckdb'
RETURN course.url, lesson.url
ORDER BY lesson.url;
```

```text
┌────────────┬───────────────────────────┐
│ course.url │ lesson.url                │
│ STRING     │ STRING                    │
├────────────┼───────────────────────────┤
│ /duckdb/   │ /duckdb/01-first-queries/ │
│ /duckdb/   │ /duckdb/02-friendly-sql/  │
│ /duckdb/   │ /duckdb/03-nested-data/   │
│ /duckdb/   │ /duckdb/04-files/         │
│ /duckdb/   │ /duckdb/05-csharp/        │
│ /duckdb/   │ /duckdb/06-java/          │
│ /duckdb/   │ /duckdb/07-performance/   │
│ /duckdb/   │ /duckdb/08-persistence/   │
│ /duckdb/   │ /duckdb/journal/          │
│ /duckdb/   │ /github-actions/          │
└────────────┴───────────────────────────┘
```

In SQL, two joins of the links table with itself, and two joins with the pages. The last row isn't a DuckDB lesson: the DuckDB index links to the GitHub Actions course, whose runs it queries. The filter is on the page in the middle, not on the lesson.

## `OPTIONAL MATCH`: the `LEFT JOIN`

`MATCH` drops the rows where the pattern doesn't fit. [`OPTIONAL MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/optional-match/) keeps them with `NULL`, like a `LEFT JOIN` ([lines 15-20](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L15-L20)):

```cypher
MATCH (p:Page)
WHERE p.locale = 'en' AND p.course = 'github-actions'
OPTIONAL MATCH (p)-[:LINKS_TO]->(target:Page)
RETURN p.url, count(target) AS links
ORDER BY links, p.url
LIMIT 4;
```

```text
┌────────────────────────────────────┬───────┐
│ p.url                              │ links │
│ STRING                             │ INT64 │
├────────────────────────────────────┼───────┤
│ /github-actions/journal/           │ 0     │
│ /github-actions/02-build-and-test/ │ 1     │
│ /github-actions/09-debugging/      │ 1     │
│ /github-actions/01-first-workflow/ │ 2     │
└────────────────────────────────────┴───────┘
```

`count(target)` counts the non-`NULL` values, so the journal, which links to no page of the site, gets 0. With `MATCH` instead of `OPTIONAL MATCH`, it would be missing from the result; with `count(*)`, it would count 1.

## `COUNT` subqueries

The English pages with at least five incoming links. A [`COUNT { … }` subquery](https://docs.ladybugdb.com/cypher/subquery/) counts the rows of a pattern for each page, in the filter and in the result ([lines 23-26](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L23-L26)):

```cypher
MATCH (p:Page)
WHERE p.locale = 'en' AND COUNT { MATCH (:Page)-[:LINKS_TO]->(p) } >= 5
RETURN p.url, COUNT { MATCH (:Page)-[:LINKS_TO]->(p) } AS incoming
ORDER BY incoming DESC, p.url;
```

```text
┌──────────────────────────────────────────────────────┬──────────┐
│ p.url                                                │ incoming │
│ STRING                                               │ INT64    │
├──────────────────────────────────────────────────────┼──────────┤
│ /streeling/journal/                                  │ 32       │
│ /wsl-containers/journal/                             │ 13       │
│ /streeling/music/mus-001-what-is-a-chord/            │ 8        │
│ /github-actions/01-first-workflow/                   │ 6        │
│ /github-actions/05-caches-and-artifacts/             │ 6        │
│ /github-actions/07-security/                         │ 6        │
│ /streeling/guitar-studies/gtr-001-the-fretboard-map/ │ 6        │
│ /github-actions/04-expressions-and-outputs/          │ 5        │
└──────────────────────────────────────────────────────┴──────────┘
```

It's the correlated subquery `(SELECT count(*) FROM links WHERE target = p.url)` of SQL. The Streeling journal comes first: 32 English Streeling pages link to it.

## Variable length: walks

`-[e:LINKS_TO*1..4]->` matches a chain of 1 to 4 `LINKS_TO` relationships. Every way to go from the GitHub Actions index to its lesson 7 in at most four clicks ([lines 29-31](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L29-L31)):

```cypher
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS walks
ORDER BY links;
```

```text
┌───────┬───────┐
│ links │ walks │
│ INT64 │ INT64 │
├───────┼───────┤
│ 1     │ 1     │
│ 2     │ 5     │
│ 3     │ 12    │
│ 4     │ 29    │
└───────┴───────┘
```

`e` is the whole chain, a *recursive relationship*, and [`length(e)`](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) its number of relationships.

**By default, the chain is a walk: it can go through the same page, and even the same link, several times.** Among the 29 walks of four links, some go to lesson 7, leave it for another lesson, and come back. This is the main [difference with Neo4j](https://docs.ladybugdb.com/cypher/difference/), whose patterns never repeat a relationship. It's also what makes the upper bound necessary: in a graph with cycles, the number of walks grows without end.

The same count in SQL, with a recursive CTE in DuckDB ([`sql/03-walks.sql`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/sql/03-walks.sql), compared by CI too):

```sql
WITH RECURSIVE
  links AS (
    SELECT l."from" AS source, l."to" AS target
    FROM 'data/links.csv' l
    WHERE l."to" IN (SELECT url FROM 'data/pages.csv')
  ),
  walks(page, length) AS (
    SELECT target, 1 FROM links WHERE source = '/github-actions/'
    UNION ALL
    SELECT links.target, walks.length + 1
    FROM walks JOIN links ON links.source = walks.page
    WHERE walks.length < 4
  )
SELECT length AS links, count(*) AS walks
FROM walks
WHERE page = '/github-actions/07-security/'
GROUP BY length
ORDER BY length;
```

```text
links,walks
1,1
2,5
3,12
4,29
```

The same numbers. A recursive CTE computes walks too: it doesn't remember where it has been, and the `WHERE walks.length < 4` is its upper bound. The `IN` filter drops the 64 links to missing pages, which `COPY … IGNORE_ERRORS` skipped in LadybugDB.

## Trails and acyclic paths

`TRAIL` after the star forbids repeating a relationship ([lines 34-36](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L34-L36)):

```cypher
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO* TRAIL 1..4]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS trails
ORDER BY links;
```

```text
┌───────┬────────┐
│ links │ trails │
│ INT64 │ INT64  │
├───────┼────────┤
│ 1     │ 1      │
│ 2     │ 5      │
│ 3     │ 12     │
│ 4     │ 26     │
└───────┴────────┘
```

Three walks of four links take a link twice. Index → lesson 1 → lesson 7 → lesson 1 → lesson 7 takes the link from lesson 1 to lesson 7 twice. Index → lesson 4 → lesson 7 → lesson 4 → lesson 7 does the same with the link from lesson 4 to lesson 7, and counts twice, because lesson 7 links to lesson 4 in two places: two relationships, two walks. To forbid repeating a *page*, the path function [`is_acyclic`](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) filters the whole path, named with `p =` ([lines 40-43](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L40-L43)):

```cypher
MATCH p = (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4]->(b:Page {url: '/github-actions/07-security/'})
WHERE is_acyclic(p)
RETURN length(e) AS links, count(*) AS acyclic_paths
ORDER BY links;
```

```text
┌───────┬───────────────┐
│ links │ acyclic_paths │
│ INT64 │ INT64         │
├───────┼───────────────┤
│ 1     │ 1             │
│ 2     │ 5             │
│ 3     │ 9             │
│ 4     │ 10            │
└───────┴───────────────┘
```

From 29 walks to 10 paths that never visit a page twice, both ends included. A Python script that enumerates the paths of `links.csv` finds the same 29, 26 and 10.

The [`MATCH` documentation](https://docs.ladybugdb.com/cypher/query-clauses/match/) also has an `ACYCLIC` keyword, used like `TRAIL`, which checks only the nodes between the two ends: it should find 25 paths of four links here. **It doesn't, in 0.20.4**: `LINKS_TO* ACYCLIC 1..4` returns 14 on Windows, including a path that goes through the same page twice, and 29, every walk, on Linux and macOS. That's why this lesson uses `is_acyclic`; the [journal](../journal/) has the details.

## Shortest paths

`SHORTEST` keeps, for each pair of nodes, one path of the smallest length. How many clicks from the home page to each English page ([lines 46-56](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L46-L56)):

```cypher
MATCH (home:Page {url: '/'})-[e:LINKS_TO* SHORTEST 1..10]->(p:Page)
WHERE p.locale = 'en'
RETURN length(e) AS clicks, count(*) AS pages
ORDER BY clicks;

MATCH (p:Page)
WHERE p.locale = 'en' AND p.url <> '/'
  AND NOT EXISTS { MATCH (:Page {url: '/'})-[:LINKS_TO* SHORTEST 1..10]->(p) }
RETURN p.url
ORDER BY p.url;
```

```text
┌────────┬───────┐
│ clicks │ pages │
│ INT64  │ INT64 │
├────────┼───────┤
│ 1      │ 7     │
│ 2      │ 77    │
│ 3      │ 32    │
└────────┴───────┘
┌────────┐
│ p.url  │
│ STRING │
├────────┤
└────────┘
```

7 + 77 + 32 = 116: every English page but the home page itself is at most three clicks away, and the second query, empty, confirms that none is unreachable. The same question in SQL is a recursive CTE that keeps the minimum length per page and has to be stopped by hand; in LadybugDB, it's a keyword.

Which pages are on the way? [Lines 59-63](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L59-L63):

```cypher
MATCH (a:Page {url: '/github-actions/09-debugging/'})-[e:LINKS_TO* SHORTEST 1..10]->(b:Page {url: '/github-actions/02-build-and-test/'})
RETURN length(e) AS links, size(nodes(e)) AS pages_between;
MATCH (a:Page {url: '/github-actions/09-debugging/'})-[e:LINKS_TO* ALL SHORTEST 1..10]->(b:Page {url: '/github-actions/02-build-and-test/'})
RETURN cast(properties(nodes(e), 'url') AS STRING) AS through
ORDER BY through;
```

```text
┌───────┬───────────────┐
│ links │ pages_between │
│ INT64 │ INT64         │
├───────┼───────────────┤
│ 4     │ 3             │
└───────┴───────────────┘
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ through                                                                                                                   │
│ STRING                                                                                                                    │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [/github-actions/04-expressions-and-outputs/,/github-actions/01-first-workflow/,/github-actions/05-caches-and-artifacts/] │
│ [/github-actions/04-expressions-and-outputs/,/github-actions/07-security/,/github-actions/05-caches-and-artifacts/]       │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

- `nodes(e)` returns the nodes *between* the two ends, not the ends: 3 pages for 4 links.
- `properties(nodes(e), 'url')` extracts one property from a list of nodes, as a `STRING[]`.
- `ALL SHORTEST` returns every path of the smallest length: two here, which differ by the page in the middle.
- The first query doesn't return the pages of its path: with two candidates, which one `SHORTEST` picks isn't specified, and a compared output can't rely on it. The cast to `STRING` is there because `ORDER BY` on a `STRING[]` fails in 0.20.4 (`Binder exception`).

## Direction

From a DuckDB lesson to the Rust course ([lines 66-69](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L66-L69)):

```cypher
MATCH (a:Page {url: '/duckdb/04-files/'})-[e:LINKS_TO* SHORTEST 1..10]->(b:Page {url: '/rust-for-csharp-java/'})
RETURN length(e) AS links;
MATCH (a:Page {url: '/duckdb/04-files/'})-[e:LINKS_TO* SHORTEST 1..10]-(b:Page {url: '/rust-for-csharp-java/'})
RETURN length(e) AS links;
```

```text
┌───────┐
│ links │
│ INT64 │
├───────┤
└───────┘
┌───────┐
│ links │
│ INT64 │
├───────┤
│ 3     │
└───────┘
```

Following the links, the Rust course can't be reached from that lesson: no page's Markdown links back to the home page (the site's header does, but it isn't in the data). Without the arrowhead, `-[…]-`, relationships can be followed in both directions, and three steps are enough: the lesson is linked *from* the DuckDB index, which is linked from the home page, which links to the Rust course.

## A filter on every step

A variable-length relationship can filter the relationships and nodes it goes through: `(r, n | WHERE …)`, where `r` stands for each relationship and `n` for each node in between. The two ends aren't filtered: with `n.url <> '/github-actions/'`, the query below still finds its walks. The walks of the first variable-length query, without going through lesson 4 ([lines 72-74](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L72-L74)):

```cypher
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4 (r, n | WHERE n.url <> '/github-actions/04-expressions-and-outputs/')]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS walks
ORDER BY links;
```

```text
┌───────┬───────┐
│ links │ walks │
│ INT64 │ INT64 │
├───────┼───────┤
│ 1     │ 1     │
│ 2     │ 4     │
│ 3     │ 7     │
│ 4     │ 14    │
└───────┴───────┘
```

From 29 walks of four links to 14, the count the Python script finds too.

## The depth limit

[Lines 77-78](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L77-L78):

```cypher
MATCH (a:Page {url: '/'})-[e:LINKS_TO*1..50]->(b:Page {url: '/duckdb/journal/'})
RETURN count(*);
```

```text
Error: Binder exception: Upper bound of rel e exceeds maximum: 30.
```

An upper bound above 30 is refused before the query runs, and `*` without bounds means `*1..30`. The limit is the setting `var_length_extend_max_depth` ([`client_config.h`](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/main/client_config.h#L32)), which `CALL var_length_extend_max_depth = 100;` raises for the connection ([configuration](https://docs.ladybugdb.com/cypher/configuration/)). Lesson 4 needs it: the Git history is a chain of 74 commits. Before raising the limit, ask whether you want walks or `SHORTEST`: on my machine, the walks of the first query with `*` instead of `*1..4`, so up to 30 links, were still being counted after five minutes, while `* SHORTEST` answers at once.

## Key takeaways

- `OPTIONAL MATCH` is the `LEFT JOIN`; `COUNT { MATCH … }` and `EXISTS { MATCH … }` are correlated subqueries.
- `-[:LINKS_TO*1..4]->` matches walks by default: pages and links can repeat. `TRAIL` forbids repeated relationships, `is_acyclic(p)` repeated nodes.
- `ACYCLIC` returns wrong counts in 0.20.4, and different ones on Windows and on Linux or macOS.
- `SHORTEST` and `ALL SHORTEST` compute shortest paths in the pattern; `nodes(e)` returns the nodes between the ends.
- Without an arrowhead, a pattern follows relationships both ways; `(r, n | WHERE …)` filters every step.
- The depth is limited to 30 unless `var_length_extend_max_depth` is raised.

## Exercises

The solutions are in [`cypher/03-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/03-exercises.cypher), checked by CI.

1. The 32 English pages three clicks away from the home page: which courses are they in?

<details>
<summary>Solution</summary>

From [`03-exercises.cypher`, lines 9-12](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-exercises.cypher#L9-L12):

```cypher
MATCH (home:Page {url: '/'})-[e:LINKS_TO* SHORTEST 1..10]->(p:Page)
WHERE p.locale = 'en' AND length(e) = 3
RETURN p.course, count(*) AS pages
ORDER BY pages DESC, p.course;
```

```text
┌───────────┬───────┐
│ p.course  │ pages │
│ STRING    │ INT64 │
├───────────┼───────┤
│ streeling │ 31    │
│ method    │ 1     │
└───────────┴───────┘
```

The Streeling modules (home page → Streeling index → department → module) and the Method page, which the home page doesn't link to directly. Every course lesson is two clicks away, through its course index.

</details>

2. Which English pages link to a page of another course? Count the links per pair of courses.

<details>
<summary>Solution</summary>

From [`03-exercises.cypher`, lines 15-18](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-exercises.cypher#L15-L18):

```cypher
MATCH (a:Page)-[:LINKS_TO]->(b:Page)
WHERE a.locale = 'en' AND b.locale = 'en' AND a.course <> b.course AND a.course <> '' AND b.course <> ''
RETURN a.course AS from_course, b.course AS to_course, count(*) AS links
ORDER BY links DESC, from_course, to_course;
```

```text
┌────────────────┬─────────────────┬───────┐
│ from_course    │ to_course       │ links │
│ STRING         │ STRING          │ INT64 │
├────────────────┼─────────────────┼───────┤
│ duckdb         │ github-actions  │ 2     │
│ duckdb         │ java-for-csharp │ 1     │
│ github-actions │ method          │ 1     │
└────────────────┴─────────────────┴───────┘
```

Four links, three of them from the DuckDB course, which builds on the GitHub Actions runs and refers to the Java course. The courses are islands linked by the home page: that's why the undirected path of the lesson goes through it.

</details>

3. Two links away from the DuckDB index: how many walks, how many distinct pages? Find the page reached twice, and through which pages.

<details>
<summary>Solution</summary>

From [`03-exercises.cypher`, lines 21-26](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-exercises.cypher#L21-L26):

```cypher
MATCH (a:Page {url: '/duckdb/'})-[:LINKS_TO*2..2]->(b:Page)
RETURN count(*) AS walks, count(DISTINCT b) AS pages;
MATCH (a:Page {url: '/duckdb/'})-[e:LINKS_TO*2..2]->(b:Page)
WITH b, count(*) AS walks, collect(properties(nodes(e), 'url')[1]) AS through
WHERE walks > 1
RETURN b.url, walks, cast(list_sort(through) AS STRING) AS through;
```

```text
┌───────┬───────┐
│ walks │ pages │
│ INT64 │ INT64 │
├───────┼───────┤
│ 16    │ 15    │
└───────┴───────┘
┌──────────────────────────┬───────┬────────────────────────────────────────────┐
│ b.url                    │ walks │ through                                    │
│ STRING                   │ INT64 │ STRING                                     │
├──────────────────────────┼───────┼────────────────────────────────────────────┤
│ /github-actions/journal/ │ 2     │ [/duckdb/03-nested-data/,/github-actions/] │
└──────────────────────────┴───────┴────────────────────────────────────────────┘
```

16 walks reach 15 pages: the GitHub Actions journal is reached through DuckDB lesson 3 and through the GitHub Actions index. `WITH … WHERE` filters on an aggregate, the `HAVING` of SQL. Lists are indexed from 1, so `[1]` is the only page between the two ends; `collect` gathers them into a list, and `list_sort` makes the output stable.

</details>

## Sources

- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/): variable-length relationships, path semantics, shortest paths, filters
- [`OPTIONAL MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/optional-match/) and [subqueries](https://docs.ladybugdb.com/cypher/subquery/)
- [Recursive relationship functions](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/): `length`, `nodes`, `is_trail`, `is_acyclic`
- [Differences between LadybugDB and Neo4j](https://docs.ladybugdb.com/cypher/difference/): walk semantics, default upper bound
- [Configuration](https://docs.ladybugdb.com/cypher/configuration/): `var_length_extend_max_depth`
- [DuckDB recursive CTEs](https://duckdb.org/docs/current/sql/query_syntax/with)
