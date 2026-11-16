---
title: 9. A graph lab — translations, prerequisite cycles, bounded reachability
description: A lab on a few invented pages, each prediction written before the run — a failed COPY and the state it leaves, missing translations found by content identity rather than title, prerequisite cycles kept apart from navigation, what a depth bound proves and what it doesn't, and a cycle witness that 0.20.4 prints backwards.
sidebar:
  order: 9
---

Lessons [2](../02-loading/) and [3](../03-paths/) ran against the site's real pages. This lab uses a dozen invented pages under `/lab/`, small enough that every expected answer can be written down **before** the query runs. The predictions are in [`data/lab/preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/lab/preregistration.md), hashed before the first run, with a dated addendum for the two places where the first run disagreed. The queries are in [`cypher/09-graph-lab.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/09-graph-lab.cypher).

The outputs below are what `lbug --no_progress_bar --no_stats --mode csv` prints, the exact command `check.sh` runs before comparing with [`cypher/expected/09-graph-lab.csv`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/expected/09-graph-lab.csv). Without the first two flags, `--mode csv` also prints an opening banner, progress bars, tuple counts and timings, and the output would no longer match. Each script runs in a new in-memory database, so each run starts empty.

The schema is the course's own. `Page` has its URL as primary key, and `LINKS_TO` holds navigation links. The lab adds one relationship table, `REQUIRES`, for prerequisites. **The three relations are kept apart:**
- navigation is `LINKS_TO`;
- prerequisites are `REQUIRES`;
- translation is not an edge at all.

A note on portability: `MATCH` patterns are [Cypher](https://opencypher.org/), but `CREATE NODE TABLE`, `CREATE REL TABLE` and `COPY` are LadybugDB's schema and import statements, not openCypher. `CALL` itself is openCypher's [procedure call](https://s3.amazonaws.com/artifacts.opencypher.org/openCypher9.pdf) clause; what is LadybugDB's own is what this lesson calls with it: `CALL threads = 1` sets a [configuration option](https://docs.ladybugdb.com/cypher/configuration/), and `show_warnings()` is one of LadybugDB's [built-in functions](https://docs.ladybugdb.com/cypher/query-clauses/call/). The [differences page](https://docs.ladybugdb.com/cypher/difference/) lists what changes from Neo4j.

## The tracer: three pages, two links

The first run checks the whole loop: two files, then one question whose answer is known.

```cypher
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/lab/tracer-pages.csv' (HEADER = true);
COPY LINKS_TO FROM 'data/lab/tracer-links.csv' (HEADER = true);
MATCH (a:Page {url: '/fr/lab/intro/'})-[e:LINKS_TO*1..3]->(b:Page)
WHERE b.locale = 'en'
RETURN length(e) AS links, properties(nodes(e), 'url') AS between, b.url AS reached;
```

```text
result,skipped_duplicate_pk_count,skipped_duplicate_pks
3 tuples have been copied to the Page table.,0,[]
result
2 tuples have been copied to the LINKS_TO table.
links,between,reached
2,[/fr/lab/paths/],/lab/paths/
```

There is one walk from the French introduction to an English page: two links, through `/fr/lab/paths/`. As in [lesson 2](../02-loading/), `HEADER = true` is explicit, and in a relationship file the first two columns are the keys of the `FROM` and `TO` pages ([Import CSV](https://docs.ladybugdb.com/import/csv/)).

## A missing endpoint, and what is left afterwards

Lesson 2 showed that one missing page fails a whole `COPY`. Here the question is narrower: **after the failure, what is in the table?** A transaction guarantee would answer that for every version; a measurement answers it for 0.20.4 only. `links-missing.csv` has one good row and one row pointing to `/es/lab/paths/`, which is not a page.

```cypher
CALL threads = 1;
COPY LINKS_TO FROM 'data/lab/links-missing.csv' (HEADER = true);
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
MATCH (p:Page {url: '/lab/paths/'}) RETURN count(*) AS found_by_key;
COPY LINKS_TO FROM 'data/lab/links-missing.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL show_warnings() RETURN message, line_number;
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
```

```text
Error: Copy exception: Unable to find primary key value /es/lab/paths/.
links
2
found_by_key
1
result
1 tuples have been copied to the LINKS_TO table.
1 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 9
message,line_number
Unable to find primary key value /es/lab/paths/.,3
links
3
```

**After the failure:**
- There are still the 2 links of the tracer: the good row of the failed file was not added.
- The page is still found by its key.

Lesson 2's [index bug](../02-loading/#a-bug-in-0204-a-failed-copy-empties-the-primary-key-index) followed a failed `COPY` into a *node* table. This one went into a relationship table, and did not break the node index.

With `IGNORE_ERRORS = true`, the good row goes in and the bad one becomes a warning, on line 3, the header being line 1. That is lenient loading on purpose: the warning says what was dropped, and it does not make the file correct.

## Missing translations: identity is the URL, not the title

`translations-pages.csv` has three English pages. `/lab/intro/` and `/lab/cycles/` have their French and Spanish pages, while `/lab/paths/` has only its French one. A French or Spanish page carries its English URL after `/fr` or `/es`, which gives each group of translations a **content identity**. The query builds the sibling URL for each locale and looks for it:

```cypher
MATCH (en:Page) WHERE en.locale = 'en'
UNWIND ['es', 'fr'] AS locale
WITH en, locale WHERE NOT EXISTS { MATCH (t:Page) WHERE t.url = '/' + locale + en.url }
RETURN en.url AS english_page, locale AS missing ORDER BY english_page, missing;
```

```text
english_page,missing
/lab/paths/,es
```

The negative control runs the same test on the two complete groups only, and finds nothing:

```text
missing_in_complete_groups
0
```

Now the tempting version: "a page has a translation if a page in the other locale has the same title".

```cypher
MATCH (en:Page) WHERE en.locale = 'en'
UNWIND ['es', 'fr'] AS locale
WITH en, locale WHERE NOT EXISTS { MATCH (t:Page) WHERE t.locale = locale AND t.title = en.title }
RETURN en.url AS english_page, locale AS missing ORDER BY english_page, missing;
```

```text
english_page,missing
/lab/cycles/,es
/lab/intro/,es
/lab/paths/,es
/lab/paths/,fr
```

Four rows, of which three are wrong: those translations exist, under translated titles ("Ciclos", "Introducción", "Chemins"). "Introduction" and "Cycles" happen to be the same word in French, so title equality even looks right for part of the data. [Lesson 2's first exercise](../02-loading/#exercises) uses the same URL identity on the real site.

## Prerequisite cycles, apart from navigation

Two files of prerequisites:
- `requires-dag.csv`: `/lab/paths/` requires `/lab/intro/`, and `/lab/cycles/` requires `/lab/paths/`;
- `requires-cycle.csv`: the same two, plus `/lab/intro/` requires `/lab/cycles/`, which closes a loop.

The navigation links go both ways between `/lab/intro/` and `/lab/paths/`, as a "next" and a "previous" link would.

A cycle is a path that comes back to where it started: `(a)-[…]->(a)`. `TRAIL` forbids repeating a relationship, as in [lesson 3](../03-paths/#trails-and-acyclic-paths). On the acyclic prerequisites first, then on navigation:

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a) RETURN count(*) AS prerequisite_cycles;
MATCH (a:Page)-[e:LINKS_TO* TRAIL 1..3]->(a) RETURN a.url AS page, length(e) AS links ORDER BY page;
```

```text
prerequisite_cycles
0
page,links
/lab/intro/,2
/lab/paths/,2
```

**Here, 0 rows is a proof, because of the bound.** Three pages carry `REQUIRES` relationships. Any cycle contains a simple cycle, one that visits distinct pages, so a cycle among three pages has a simple cycle of length at most 3. A bound of 3 is therefore complete: no closed trail up to 3 means no cycle at all. The same query on `LINKS_TO` finds the navigation loop, which is normal and must not be read as a prerequisite cycle. That is why prerequisites live in their own table.

With the cycle file, each closed trail is a **witness**: the pages you would show someone to prove the cycle is there.

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a)
RETURN a.url AS page, length(e) AS length, properties(nodes(e), 'url') AS through ORDER BY page;
```

```text
page,length,through
/lab/cycles/,3,"[/lab/intro/,/lab/paths/]"
/lab/intro/,3,"[/lab/paths/,/lab/cycles/]"
/lab/paths/,3,"[/lab/cycles/,/lab/intro/]"
```

**The three pages and the length are right, but the order is backwards.** From `/lab/cycles/`, the arrows go to `/lab/paths/`, then `/lab/intro/`, then back, yet the list says `/lab/intro/` first. I had predicted the arrows' order, and the addendum to the pre-registration records the miss. An open path, from the same page, lists its pages the right way; the closed trail lists them backwards:

```cypher
MATCH p = (a:Page {url: '/lab/cycles/'})-[e:REQUIRES*2..2]->(b:Page) RETURN properties(nodes(p), 'url') AS open_path;
MATCH p = (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* TRAIL 3..3]->(a) RETURN properties(nodes(p), 'url') AS closed_path;
```

```text
open_path
"[/lab/cycles/,/lab/paths/,/lab/intro/]"
closed_path
"[/lab/cycles/,/lab/intro/,/lab/paths/,/lab/cycles/]"
```

The [documentation of path functions](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) shows `nodes(p)` only on open patterns, in the arrows' order. So in 0.20.4, trust the pages of a closed witness, not their order: check each step against the relationship table before printing it as a chain.

## What a depth bound proves, and what it doesn't

The bound of 3 above was complete because it was at least the number of pages involved. `requires-long.csv` makes a cycle of six pages, `/lab/s1/` → … → `/lab/s6/` → `/lab/s1/`:

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..5]->(a) WHERE a.url STARTS WITH '/lab/s' RETURN count(*) AS closed_trails;
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..6]->(a) WHERE a.url STARTS WITH '/lab/s'
RETURN count(*) AS closed_trails, min(length(e)) AS min_length, max(length(e)) AS max_length;
```

```text
closed_trails
0
closed_trails,min_length,max_length
6,6,6
```

With a bound of 5, nothing is found. That proves nothing, because the only cycle is longer than 5. With a bound of 6, the cycle appears, once from each of its six pages. To prove a graph acyclic this way, the bound must be at least the number of pages that carry the relationship. Within the default limit of 30 ([lesson 3](../03-paths/#the-depth-limit)), that works only for small graphs. My first version of this query named a column `shortest`, which is a keyword in 0.20.4: the parser refused it, and the aliases became `min_length` and `max_length`.

The same holds for reachability. Here are the prerequisites of `/lab/cycles/` in the acyclic file, with `SHORTEST` giving one shortest path per page, first with a bound of 2, then with a bound of 1:

```cypher
MATCH (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* SHORTEST 1..2]->(b:Page) RETURN b.url AS prerequisite, length(e) AS depth ORDER BY prerequisite;
MATCH (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* SHORTEST 1..1]->(b:Page) RETURN b.url AS prerequisite, length(e) AS depth ORDER BY prerequisite;
MATCH (a:Page {url: '/lab/intro/'})-[e:LINKS_TO* SHORTEST 1..2]->(b:Page) RETURN b.url AS reached, length(e) AS clicks ORDER BY reached;
```

```text
prerequisite,depth
/lab/intro/,2
/lab/paths/,1
prerequisite,depth
/lab/paths/,1
reached,clicks
/lab/cycles/,2
/lab/paths/,1
```

- **With a bound of 1,** `/lab/intro/` disappears. It is still a prerequisite, only further away than the bound allows.
- **On the six-page cycle,** `SHORTEST 1..3` from `/lab/s1/` lists `/lab/s2/`, `/lab/s3/` and `/lab/s4/`, and leaves out `/lab/s5/` and `/lab/s6/`, which are 4 and 5 steps away.
- **Absent from a bounded answer means "not within the bound", not "unreachable".** The last query follows navigation from `/lab/intro/` and reaches `/lab/cycles/`, which is not one of its prerequisites. The relationship type decides what the question means.

## Key takeaways

- **Write the expected answers before the run.** A fixture small enough to reason about lets you do it, and the misses are results: here, a witness printed backwards.
- **A failed `COPY` into a relationship table** left the table and the key index as they were, in 0.20.4. That is observed, not a documented guarantee. `IGNORE_ERRORS` is deliberate leniency, with warnings to read.
- **Find translations by a content identity,** here the English URL, not by title.
- **Keep prerequisites in their own relationship table.** Navigation loops are normal; prerequisite loops are errors.
- **A closed trail up to n finds every cycle among n pages.** Below that bound, 0 rows proves nothing, and a bounded reachability answer says nothing beyond its bound.
- **In 0.20.4, `nodes()` on a closed pattern `(a)-[…]->(a)` lists the pages against the arrows.**

## Exercises

The solution is in [`cypher/09-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/09-exercises.cypher), checked by CI.

1. With `translations-pages.csv` and `requires-cycle.csv` loaded, which pages of a prerequisite cycle have no Spanish sibling?

<details>
<summary>Solution</summary>

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a)
WHERE a.locale = 'en' AND NOT EXISTS { MATCH (t:Page) WHERE t.url = '/es' + a.url }
RETURN DISTINCT a.url AS page;
```

```text
page
/lab/paths/
```

The three pages of the cycle each start a closed trail. `DISTINCT` keeps one row per page, and the content identity, `'/es' + a.url`, finds the one with no Spanish page. The bound of 3 is complete here, because three pages carry `REQUIRES` relationships.

</details>

## Sources

- [Import CSV](https://docs.ladybugdb.com/import/csv/): `HEADER`, `IGNORE_ERRORS`, relationship files whose first two columns are the node keys (read 2026-09-27)
- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/): variable-length patterns, `TRAIL`, `SHORTEST` (read 2026-09-27)
- [Path functions](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/): `nodes`, `length`, `properties` (read 2026-09-27)
- [Differences between LadybugDB and Neo4j](https://docs.ladybugdb.com/cypher/difference/) and [openCypher](https://opencypher.org/)
