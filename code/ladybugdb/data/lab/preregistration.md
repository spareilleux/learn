# Graph lab (lesson 9): pre-registration

Written before the fixtures below were loaded or any lab query was run. Its SHA-256 goes into the progress receipt at the moment of writing. A later change is a new dated section, never a silent edit.

## Setup

- **Runtime:** LadybugDB CLI 0.20.4, the version the course pins, run through `check.sh` in CSV mode.
- **Database:** an in-memory database per script, so every run starts empty.
- **Threads:** `CALL threads = 1` before every `COPY` whose error message is compared (lesson 2: with several threads, the reported row varies).
- **Schema:** the course's own. `Page(url STRING PRIMARY KEY, locale, course, title, lines)` and `LINKS_TO(FROM Page TO Page, anchor)`, as in lesson 2.
  - One addition: `REQUIRES(FROM Page TO Page)`, for prerequisites. It is a separate relationship table, so that prerequisite semantics never mix with navigation (`LINKS_TO`) or with translation.
  - **Translation is not an edge.** Pages are siblings when they share a content identity: the English URL, which a French or Spanish URL carries after its `/fr` or `/es` prefix. Titles are not identities.
- **Fixtures:** in `data/lab/`, each with a header row, loaded with `HEADER = true`. Every URL is invented under `/lab/`, and none of them is a real page of the site.

## Predictions

Each prediction gives literal values. **(doc)** means it follows from the documentation or from lesson 2 or 3. **(new)** means it has not been observed before in this course.

### T. Tracer: three pages, two links

| Id | Prediction |
|---|---|
| T1 | `tracer-pages.csv` copies **3** pages, and `tracer-links.csv` copies **2** links. |
| T2 | Walks from `/fr/lab/intro/` to any page with `locale = 'en'`, `LINKS_TO*1..3`: exactly **1** row, `length = 2`, with the page between the ends being `/fr/lab/paths/` and the end being `/lab/paths/`. |

### 1. Missing endpoint

After T, `links-missing.csv` holds one good row (`/fr/lab/intro/ → /lab/paths/`) and one row whose target `/es/lab/paths/` is not a page.

| Id | Prediction |
|---|---|
| M1 | A strict `COPY LINKS_TO` fails with `Copy exception: Unable to find primary key value /es/lab/paths/.` **(doc)** |
| M2 | **Observed state after the failure,** as measured in 0.20.4 and not as a transaction guarantee: still **2** links, so the good row of the failed file is not added. The key lookup `MATCH (p:Page {url: '/lab/paths/'})` still finds **1** page. **(new)** Lesson 2's index bug was seen after a failed `COPY` into a *node* table; this is a relationship table. |
| M3 | With `IGNORE_ERRORS = true`: **1** row copied and **1** warning, at `line_number` **3**, the header being line 1. Then **3** links in all. |

This is lenient loading on purpose: it tells you what was dropped, and it does not make the file correct.

### 2. Missing translation

`translations-pages.csv` has three English pages:

| English page | French sibling | Spanish sibling |
|---|---|---|
| `/lab/intro/` | yes | yes |
| `/lab/paths/` | yes | **no** |
| `/lab/cycles/` | yes | yes |

Some titles are translated and others are not: "Introduction" is the same in English and French, while "Paths" becomes "Chemins" and "Cycles" becomes "Ciclos" in Spanish.

| Id | Prediction |
|---|---|
| X1 | By content identity (a sibling URL is `'/' + locale + english_url`), exactly **1** missing sibling: `/lab/paths/`, `es`. |
| X2 | Negative control: the two complete groups, `/lab/intro/` and `/lab/cycles/`, report **0** missing siblings. |
| X3 | The title-equality version ("a sibling is a page in the other locale with the same title") reports **4** rows: `(/lab/cycles/, es)`, `(/lab/intro/, es)`, `(/lab/paths/, es)`, `(/lab/paths/, fr)`. **3** of them are false: those translations exist, with other titles. |

### 3. Prerequisite cycles

`requires-dag.csv`: `/lab/paths/ REQUIRES /lab/intro/` and `/lab/cycles/ REQUIRES /lab/paths/`. `requires-cycle.csv` adds `/lab/intro/ REQUIRES /lab/cycles/`.

`navigation-links.csv` has a navigation cycle, `/lab/intro/ ↔ /lab/paths/`, which is not a prerequisite cycle.

| Id | Prediction |
|---|---|
| C1 | DAG: closed trails `(a)-[:REQUIRES* TRAIL 1..3]->(a)`: **0** rows. Here 3 pages carry `REQUIRES` edges. Any cycle contains a simple cycle through distinct pages, so of length ≤ 3: the bound 3 is complete, and 0 rows proves this graph acyclic. |
| C2 | The same query on `LINKS_TO` finds the navigation cycle: **2** closed trails of length 2, from `/lab/intro/` and from `/lab/paths/`. **Typed traversal matters.** |
| C3 | With the cycle file: **3** closed trails, all of length **3**, one from each page. The witness from `/lab/cycles/` passes through `/lab/paths/` then `/lab/intro/`. |
| C4 | Depth bound, on `chain-pages.csv` and `requires-long.csv`: a 6-cycle `/lab/s1/ → … → /lab/s6/ → /lab/s1/`. `TRAIL 1..5` finds **0** closed trails, and `TRAIL 1..6` finds **6**, all of length 6. **0 rows under a bound smaller than the number of pages proves nothing.** |

### 4. Bounded reachability

| Id | Prediction |
|---|---|
| R1 | Prerequisites of `/lab/cycles/` in the DAG, `REQUIRES* SHORTEST 1..2`, ordered by URL: `/lab/intro/` at 2 and `/lab/paths/` at 1. |
| R2 | With `1..1`, only `/lab/paths/`: `/lab/intro/` is missing because of the bound, not because it is unreachable. |
| R3 | Pages reachable from `/lab/intro/` by navigation, `LINKS_TO* SHORTEST 1..2`: `/lab/cycles/` at 2 and `/lab/paths/` at 1. Prerequisites and navigation give different answers from the same pages. |
| R4 | From `/lab/s1/`, `REQUIRES* SHORTEST 1..3`: `/lab/s2/` at 1, `/lab/s3/` at 2 and `/lab/s4/` at 3. `/lab/s5/` and `/lab/s6/` are missing, although they are reachable at 4 and 5. |

## What this does not claim

- Nothing about transactions in other versions of LadybugDB.
- Nothing about the site's real pages.
- No platform beyond the one it ran on until the CI of `ladybugdb-examples.yml` passes.
- `CREATE NODE TABLE`, `CREATE REL TABLE`, `COPY` and `CALL` are LadybugDB statements, not openCypher. Only the `MATCH` patterns are Cypher.

## Addendum, 2026-09-27 13:30 EDT: after the first run of cases 2–4

**The first run disagreed with this file on two points. They are recorded here, not edited above.**

1. **C3, the order of the witness: refuted.** The three closed trails, their lengths (3) and their pages are as predicted, but `properties(nodes(e), 'url')` lists the pages between the ends **against the arrows**. From `/lab/cycles/`, the arrows go `/lab/cycles/ → /lab/paths/ → /lab/intro/ → /lab/cycles/`, and the list is `[/lab/intro/,/lab/paths/]`.
   - A probe on the 6-cycle, run after that first run and **before this addendum**, separates the two cases:

     | Pattern | Function | Order |
     |---|---|---|
     | open, `/lab/s1/ -[*3..3]-> /lab/s4/` | `nodes(e)` and `nodes(p)` | **with the arrows**: `[/lab/s2/,/lab/s3/]` and `[/lab/s1/,…,/lab/s4/]` |
     | closed, `(a)-[* TRAIL 6..6]->(a)` from `/lab/s1/` | `nodes(p)` | `[/lab/s1/,/lab/s6/,/lab/s5/,/lab/s4/,/lab/s3/,/lab/s2/,/lab/s1/]`, **reversed** |

   - **New predictions,** informed by that probe, for two queries added to the lab now:
     - the open path `/lab/cycles/ -[REQUIRES*2..2]->` gives `nodes(p)` = `[/lab/cycles/,/lab/paths/,/lab/intro/]`;
     - the closed trail from `/lab/cycles/`, `TRAIL 3..3`, gives `[/lab/cycles/,/lab/intro/,/lab/paths/,/lab/cycles/]`.
   - **Label:** an upstream behaviour observed in 0.20.4. It is not in the documentation read so far, and it is not reported upstream: outreach is not authorized by this brief.
   - **What still holds:** the witness is a real cycle, as a set of pages and as a length. Only its printed order is reversed.
2. **C4: a script defect, not a prediction.** `shortest` is a reserved word in 0.20.4 (`Parser exception: mismatched input 'shortest'`). The aliases become `min_length` and `max_length`. The prediction, 6 closed trails of length 6, was not tested by that run.

## Addendum, 2026-09-27 14:15 EDT: before publication, a correction to one scope line

The last line of *What this does not claim* is too broad, and it is corrected here rather than edited above:
- **`CALL` itself is openCypher's procedure-call clause.**
- What is LadybugDB's own is what this lab calls with it:
  - `CALL threads = 1`, a configuration option;
  - `show_warnings()`, a built-in function.
- `CREATE NODE TABLE`, `CREATE REL TABLE` and `COPY` remain LadybugDB statements.
- No prediction and no result changes.
