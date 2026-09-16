---
title: "7. JSON and search"
description: Storing and querying documents with jsonb — operators, containment, SQL/JSON paths, JSON_TABLE, GIN indexes and jsonb_path_ops — then full-text search on this site's own pages in three languages, with tsvector, tsquery, ranking, ts_headline, unaccent, and pg_trgm for typos and LIKE '%…%'; compared with SQL Server's OPENJSON and full-text catalogs.
sidebar:
  order: 7
---

The lesson's script is [`sql/07-json-search.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql), the exercises are in [`sql/07-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql), and `check.sh` compares their output with [`expected/07-json-search.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/07-json-search.txt) and [`expected/07-exercises.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/07-exercises.txt).

Two kinds of data this time. The documents are the GitHub API's job objects, as the CI snapshot exported them in [`jobs.json`](https://github.com/spareilleux/learn/blob/main/code/duckdb/data/jobs.json): [lesson 2](../02-types/) flattened them into `ci.jobs` and `ci.steps`, this lesson keeps them whole. The text is this site: [`data/extract_pages.py`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/data/extract_pages.py) took the prose of the DuckDB course and of this course, in English, French and Spanish, at commit `a1df189`, without code blocks or link targets, into [`data/pages.json`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/data/pages.json): 48 pages.

| SQL Server | PostgreSQL |
|---|---|
| JSON in `nvarchar(max)`, `ISJSON`; the `json` type (preview in SQL Server 2025) | `jsonb`, parsed and validated on input |
| `JSON_VALUE`, `JSON_QUERY` | `->>`, `->`, `#>>`, `jsonb_path_query` |
| `OPENJSON … WITH (…)` | `JSON_TABLE(… COLUMNS (…))`, `jsonb_to_recordset` |
| index on a computed column over `JSON_VALUE` | GIN on the whole document, or a B-tree on an expression |
| full-text catalog and index, `CONTAINS`, `FREETEXT` | `tsvector` column with a GIN index, `@@` |
| `CONTAINSTABLE` rank | `ts_rank`, `ts_rank_cd` |
| `LIKE '%…%'` scans | `pg_trgm` index |

## json and jsonb

[Lines 7-9](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L7-L9):

```sql
-- json keeps the text as it was written; jsonb stores a parsed value: keys sorted, duplicates dropped, the last one kept
SELECT '{"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"}'::json AS json,
       '{"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"}'::jsonb AS jsonb;
```

```text
                               json                               |                      jsonb
------------------------------------------------------------------+-------------------------------------------------
 {"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"} | {"name": "deploy", "labels": ["ubuntu-latest"]}
(1 row)
```

[`json`](https://www.postgresql.org/docs/18/datatype-json.html) checks the text and stores it as written, duplicate keys included. `jsonb` stores a parsed tree: keys sorted by length then bytes, one value per key, the last one written. `jsonb` is the one to use, unless the exact text must come back.

## Operators

The documents, one row per job ([lines 11-23](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L11-L23)):

```sql
-- The GitHub API's job documents, as they were exported: one jsonb value per job
CREATE TABLE ci.job_docs (
    doc jsonb NOT NULL
);
INSERT INTO ci.job_docs
SELECT j FROM jsonb_array_elements(pg_read_file('/course/data/jobs.json')::jsonb) AS j;

-- -> returns jsonb, ->> returns text, #>> follows a path
SELECT doc->>'name' AS name, doc->'labels' AS labels, doc->'labels'->>0 AS first_label,
       doc#>>'{steps,0,name}' AS first_step, jsonb_array_length(doc->'steps') AS steps
FROM ci.job_docs
WHERE (doc->>'run_id')::bigint = 34852867099
ORDER BY name;
```

```text
CREATE TABLE
INSERT 0 315
  name  |      labels       |  first_label  | first_step | steps
--------+-------------------+---------------+------------+-------
 build  | ["ubuntu-latest"] | ubuntu-latest | Set up job |     6
 deploy | ["ubuntu-latest"] | ubuntu-latest | Set up job |     3
(2 rows)
```

- [`pg_read_file`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-GENFILE) reads a file on the server; by default, only a superuser may call it. [`jsonb_array_elements`](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-JSON-PROCESSING) turns the array into rows.
- `->` returns `jsonb`, `->>` returns `text`, `#>>` follows a path given as a text array. Array positions start at 0 in `jsonb`, where SQL arrays start at 1.
- A comparison with a number needs a cast: `(doc->>'run_id')::bigint`.

Containment and existence ([lines 25-29](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L25-L29)):

```sql
-- Containment and existence
SELECT count(*) FILTER (WHERE doc @> '{"steps": [{"conclusion": "failure"}]}') AS with_a_failed_step,
       count(*) FILTER (WHERE doc->'labels' ? 'windows-latest') AS on_windows,
       count(*) FILTER (WHERE doc->'labels' ?| '{macos-latest, windows-latest}') AS on_macos_or_windows
FROM ci.job_docs;
```

```text
 with_a_failed_step | on_windows | on_macos_or_windows
--------------------+------------+---------------------
                 22 |         35 |                  69
(1 row)
```

- `@>` asks whether the left document contains the right one. For an array, containment means "has an element that contains": 22 jobs have at least one step whose conclusion is `failure`.
- `?` asks whether a string is a key, or an element of an array; `?|` whether any of several is, `?&` whether all are.

## SQL/JSON paths and JSON_TABLE

A [SQL/JSON path](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-SQLJSON-PATH) walks inside a document, with filters ([lines 31-36](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L31-L36)):

```sql
-- An SQL/JSON path: the failed steps of each job
SELECT doc->>'name' AS job, jsonb_path_query(doc, '$.steps[*] ? (@.conclusion == "failure").name') #>> '{}' AS failed_step
FROM ci.job_docs
WHERE doc @? '$.steps[*] ? (@.conclusion == "failure")'
ORDER BY doc->>'completed_at', 1, 2
LIMIT 5;
```

```text
                  job                  | failed_step
---------------------------------------+-------------
 rust-for-csharp-java (ubuntu-latest)  | Formatting
 rust-for-csharp-java (macos-latest)   | Formatting
 rust-for-csharp-java (windows-latest) | Formatting
 rust-for-csharp-java (ubuntu-latest)  | Formatting
 rust-for-csharp-java (macos-latest)   | Formatting
(5 rows)
```

`$.steps[*] ? (@.conclusion == "failure").name` takes every step, keeps those whose conclusion is `failure`, and returns their name. `jsonb_path_query` returns one row per match, `@?` asks whether there is at least one. `#>> '{}'` turns a `jsonb` string into `text`, without its quotes.

[`JSON_TABLE`](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-SQLJSON-TABLE), new in PostgreSQL 17, is the standard form of SQL Server's `OPENJSON … WITH` ([lines 38-48](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L38-L48)):

```sql
-- JSON_TABLE turns a document into rows and typed columns, like OPENJSON ... WITH in T-SQL
SELECT s.number, s.name, s.conclusion, s.completed_at - s.started_at AS duration
FROM ci.job_docs,
     JSON_TABLE(doc, '$.steps[*]' COLUMNS (
         number       smallint    PATH '$.number',
         name         text        PATH '$.name',
         conclusion   text        PATH '$.conclusion',
         started_at   timestamptz PATH '$.started_at',
         completed_at timestamptz PATH '$.completed_at')) AS s
WHERE (doc->>'id')::bigint = 104004920113
ORDER BY s.number;
```

```text
 number |                 name                 | conclusion | duration
--------+--------------------------------------+------------+----------
      1 | Set up job                           | success    | 00:00:04
      2 | Checkout                             | success    | 00:00:02
      3 | Install, build, and upload site      | success    | 00:00:48
      5 | Post Install, build, and upload site | success    | 00:00:00
      6 | Post Checkout                        | success    | 00:00:01
      7 | Complete job                         | success    | 00:00:00
(6 rows)
```

Each column has a type and a path; the timestamps are read as `timestamptz`, and their difference is an `interval`. Step 4 of this job doesn't exist in the document: GitHub numbered the steps with a gap.

Documents are values: operators return new ones ([lines 50-54](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L50-L54)):

```sql
-- Changing a document: || merges, - removes a key, jsonb_set replaces a value at a path
SELECT (doc - 'steps' - 'labels' || '{"rerun": true}') AS summary,
       jsonb_set(doc, '{labels,0}', '"ubuntu-24.04"')->'labels' AS labels
FROM ci.job_docs
WHERE (doc->>'id')::bigint = 104004920113;
```

```text
                                                                                                                                           summary                                                                                                                                           |      labels
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+------------------
 {"id": 104004920113, "name": "build", "rerun": true, "run_id": 34852867099, "status": "completed", "conclusion": "success", "created_at": "2026-09-14T14:01:10Z", "started_at": "2026-09-14T14:01:14Z", "runner_name": "GitHub Actions 1000000319", "completed_at": "2026-09-14T14:02:12Z"} | ["ubuntu-24.04"]
(1 row)
```

`-` removes a key, `||` merges two objects, [`jsonb_set`](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-JSON-PROCESSING) replaces the value at a path. An `UPDATE` that changes one key writes the whole document again, as a new row version ([lesson 6](../06-transactions/)): large documents that change often belong in columns.

## GIN on documents

315 documents fit in a few pages. The script copies them 40 times, and uses the plan helper of [lesson 5](../05-indexes/#stable-plans-for-a-lesson) ([lines 56-69](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L56-L69)):

```sql
-- GIN indexes on documents, on 40 copies of the jobs
INSERT INTO ci.job_docs SELECT doc FROM ci.job_docs, generate_series(2, 40);
VACUUM ANALYZE ci.job_docs;
SELECT count(*) AS documents, pg_size_pretty(pg_total_relation_size('ci.job_docs')) AS size FROM ci.job_docs;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.job_docs WHERE doc @> '{"steps": [{"name": "Compile-fail doctests", "conclusion": "failure"}]}'
$$);
CREATE INDEX job_docs_ops ON ci.job_docs USING gin (doc);
CREATE INDEX job_docs_path_ops ON ci.job_docs USING gin (doc jsonb_path_ops);
SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index WHERE indrelid = 'ci.job_docs'::regclass ORDER BY 1;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.job_docs WHERE doc @> '{"steps": [{"name": "Compile-fail doctests", "conclusion": "failure"}]}'
$$);
```

```text
INSERT 0 12285
VACUUM
 documents | size
-----------+-------
     12600 | 15 MB
(1 row)

                                                QUERY PLAN
-----------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=1881
   ->  Seq Scan on job_docs (actual rows=40.00 loops=1)
         Filter: (doc @> '{"steps": [{"name": "Compile-fail doctests", "conclusion": "failure"}]}'::jsonb)
         Rows Removed by Filter: 12560
         Buffers: shared hit+read=1881
(6 rows)

CREATE INDEX
CREATE INDEX
        index         |  size
----------------------+---------
 ci.job_docs_ops      | 1688 kB
 ci.job_docs_path_ops | 1752 kB
(2 rows)

                                                     QUERY PLAN
---------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=85
   ->  Bitmap Heap Scan on job_docs (actual rows=40.00 loops=1)
         Recheck Cond: (doc @> '{"steps": [{"name": "Compile-fail doctests", "conclusion": "failure"}]}'::jsonb)
         Rows Removed by Index Recheck: 240
         Heap Blocks: exact=80
         Buffers: shared hit+read=85
         ->  Bitmap Index Scan on job_docs_path_ops (actual rows=280.00 loops=1)
               Index Cond: (doc @> '{"steps": [{"name": "Compile-fail doctests", "conclusion": "failure"}]}'::jsonb)
               Index Searches: 1
               Buffers: shared hit+read=5
(11 rows)
```

A [GIN index on `jsonb`](https://www.postgresql.org/docs/18/datatype-json.html#JSON-INDEXING) comes in two operator classes:

- `jsonb_ops`, the default, indexes every key and every value separately. It serves `@>`, `?`, `?|`, `?&` and path matches.
- `jsonb_path_ops` indexes a hash of each value with the path of keys that leads to it. It only serves `@>` and path matches, and is usually smaller. Here it came out slightly larger, 1,752 kB against 1,688 kB, and the planner chose it.

The index returned 280 documents, and the recheck on the table kept 40: the 7 jobs with a step named `Compile-fail doctests` and a failed step, 40 times, of which only one job had that step fail. The index knows that a document has both paths, not that they belong to the same array element. 85 pages instead of 1,881.

When queries always read the same key, a B-tree on the expression, such as `((doc->>'run_id')::bigint)`, is smaller and serves ranges and sorts, which GIN can't.

## Full-text search

Searching text with `LIKE` finds strings, not words: `index` doesn't match `indexes`, and every row is read. [Full-text search](https://www.postgresql.org/docs/18/textsearch-intro.html) turns a text into a `tsvector`, a sorted list of normalized words, *lexemes*, with their positions. A [text search configuration](https://www.postgresql.org/docs/18/textsearch-configuration.html) decides how: which words to skip, and how to reduce a word to its stem ([lines 71-92](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L71-L92)):

```sql
-- Full-text search: the prose of two courses of this site, in English, French and Spanish (data/extract_pages.py)
CREATE SCHEMA site;
CREATE TABLE site.pages (
    course text NOT NULL,
    locale text NOT NULL,
    slug   text NOT NULL,
    title  text NOT NULL,
    body   text NOT NULL,
    config regconfig NOT NULL,
    search tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector(config, title), 'A') || setweight(to_tsvector(config, body), 'B')) STORED,
    PRIMARY KEY (course, locale, slug)
);

-- A tsvector holds normalized words, lexemes, with their positions; a text search configuration decides how
SELECT to_tsvector('english', 'Indexes and plans: the planner chose a Bitmap Index Scan') AS english,
       to_tsvector('french', 'Index et plans : le planificateur a choisi un parcours d''index') AS french,
       to_tsvector('simple', 'Indexes and plans') AS simple;

-- websearch_to_tsquery reads a search box's syntax: words, "phrases", or, -excluded
SELECT websearch_to_tsquery('english', 'connection pool -aurora') AS query1,
       websearch_to_tsquery('english', '"index scan" or brin') AS query2;
```

```text
CREATE SCHEMA
CREATE TABLE
                             english                             |                            french                            |            simple
-----------------------------------------------------------------+--------------------------------------------------------------+-------------------------------
 'bitmap':8 'chose':6 'index':1,9 'plan':3 'planner':5 'scan':10 | 'a':6 'chois':7 'index':1,11 'parcour':9 'plan':3 'planif':5 | 'and':2 'indexes':1 'plans':3
(1 row)

             query1             |           query2
--------------------------------+-----------------------------
 'connect' & 'pool' & !'aurora' | 'index' <-> 'scan' | 'brin'
(1 row)
```

- `english` removes `and` and `the`, and reduces `Indexes` to `index` and `chose` stays `chose`: a stemmer cuts suffixes, it doesn't know irregular verbs.
- `french` reduces `planificateur` to `planif`, and keeps `a`, which isn't in its stop words.
- `simple` only lowercases.
- [`websearch_to_tsquery`](https://www.postgresql.org/docs/18/textsearch-controls.html#TEXTSEARCH-PARSING-QUERIES) reads what people type in a search box: words are joined by `&`, `-` excludes, `or` is `|`, and a quoted phrase becomes `<->`, "followed by".

`site.pages` stores each page with its configuration, a [`regconfig`](https://www.postgresql.org/docs/18/datatype-textsearch.html), and a stored generated `tsvector` that weighs the title (`A`) above the body (`B`). The configuration is a column of its own, set by the `INSERT`: a generated column can't refer to another generated column.

```sql
INSERT INTO site.pages (course, locale, slug, title, body, config)
SELECT p.course, p.locale, p.slug, p.title, p.body,
       CASE p.locale WHEN 'fr' THEN 'french' WHEN 'es' THEN 'spanish' ELSE 'english' END::regconfig
FROM jsonb_to_recordset(pg_read_file('/course/data/pages.json')::jsonb->'pages') AS p(
    course text, locale text, slug text, title text, body text);
CREATE INDEX pages_search ON site.pages USING gin (search);
```

### Ranking

[Lines 101-106](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L101-L106):

```sql
-- The pages that match, best first: title matches weigh more than body matches
SELECT course, slug, round(ts_rank(search, query)::numeric, 3) AS rank
FROM site.pages, websearch_to_tsquery('english', 'connection pool') AS query
WHERE locale = 'en' AND search @@ query
ORDER BY rank DESC, course, slug
LIMIT 5;
```

```text
INSERT 0 48
CREATE INDEX
      course       |      slug      | rank
-------------------+----------------+-------
 postgresql-aurora | 04-csharp-java | 1.000
 postgresql-aurora | 03-queries     | 0.625
 postgresql-aurora | index          | 0.381
(3 rows)
```

`@@` matches a `tsvector` with a `tsquery`, through the GIN index. [`ts_rank`](https://www.postgresql.org/docs/18/textsearch-controls.html#TEXTSEARCH-RANKING) scores how often the words appear, and with which weight: lesson 4 is the page about connection pools. The ranking functions don't know anything else about a page; a search engine that needs more, such as synonyms, typos in several words or relevance learned from clicks, is a different tool.

[`ts_headline`](https://www.postgresql.org/docs/18/textsearch-controls.html#TEXTSEARCH-HEADLINE) shows the matching words in their context ([lines 108-112](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L108-L112)):

```sql
-- ts_headline shows the matching words in context
SELECT slug, regexp_replace(ts_headline('english', body, query, 'MaxFragments=1, MaxWords=12, MinWords=6, StartSel=[, StopSel=]'), '\s+', ' ', 'g') AS excerpt
FROM site.pages, websearch_to_tsquery('english', '"prepared statements"') AS query
WHERE locale = 'en' AND course = 'postgresql-aurora' AND search @@ query
ORDER BY slug;
```

```text
      slug      |                                                 excerpt
----------------+---------------------------------------------------------------------------------------------------------
 04-csharp-java | beat hundreds of idle ones. ## [Prepared] [statements] A [prepared] [statement] is parsed
 index          | JDBC and HikariCP, including pools, [prepared] [statements] and `COPY`; - read a query
 journal        | hours throws `ArgumentException`. - `pg_[prepared]_[statements]` counted the counting query itself once
(3 rows)
```

The phrase `"prepared statements"` matched `pg_prepared_statements` in the journal: the parser splits that identifier at its underscores. `regexp_replace` only joins the lines of the excerpt, for the output.

### Accents

[Lines 114-129](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L114-L129):

```sql
-- The same search in French finds nothing for a word written without its accent
SELECT count(*) FILTER (WHERE search @@ websearch_to_tsquery('french', 'modélisation')) AS with_accent,
       count(*) FILTER (WHERE search @@ websearch_to_tsquery('french', 'modelisation')) AS without_accent
FROM site.pages WHERE locale = 'fr';

-- unaccent in a configuration of our own removes accents before stemming
CREATE EXTENSION unaccent;
CREATE TEXT SEARCH CONFIGURATION french_unaccent (COPY = french);
ALTER TEXT SEARCH CONFIGURATION french_unaccent
    ALTER MAPPING FOR hword, hword_part, word WITH unaccent, french_stem;
SELECT to_tsvector('french', 'modélisation des données') AS french,
       to_tsvector('french_unaccent', 'modélisation des données') AS french_unaccent;
SELECT count(*) AS without_accent
FROM site.pages
WHERE locale = 'fr'
  AND to_tsvector('french_unaccent', title || ' ' || body) @@ websearch_to_tsquery('french_unaccent', 'modelisation');
```

```text
 with_accent | without_accent
-------------+----------------
           3 |              0
(1 row)

CREATE EXTENSION
CREATE TEXT SEARCH CONFIGURATION
ALTER TEXT SEARCH CONFIGURATION
       french        |    french_unaccent
---------------------+-----------------------
 'don':3 'modélis':1 | 'donne':3 'modelis':1
(1 row)

 without_accent
----------------
              3
(1 row)
```

The `french` configuration keeps accents, so `modelisation`, typed without its accent, finds none of the three French pages that `modélisation` finds. The [`unaccent`](https://www.postgresql.org/docs/18/unaccent.html) extension is a dictionary that removes accents; a configuration of our own runs it before the French stemmer, on documents and queries alike. The last query computes the `tsvector` on the fly, reading every French page: a real table would store it, or index the expression.

## pg_trgm

[`pg_trgm`](https://www.postgresql.org/docs/18/pgtrgm.html) cuts a string into trigrams, sequences of three characters, and compares strings by the trigrams they share ([lines 131-137](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L131-L137)):

```sql
-- pg_trgm: similarity between strings, from their three-letter sequences
CREATE EXTENSION pg_trgm;
SELECT show_trgm('Npgsql') AS trigrams;
SELECT DISTINCT package, round(similarity(package, 'mongo driver')::numeric, 2) AS similarity
FROM ga.package_refs
WHERE package % 'mongo driver'
ORDER BY similarity DESC, package;
```

```text
CREATE EXTENSION
              trigrams
-------------------------------------
 {"  n"," np",gsq,npg,pgs,"ql ",sql}
(1 row)

        package        | similarity
-----------------------+------------
 MongoDB.Driver        |       0.75
 MongoDB.Driver.GridFS |       0.52
(2 rows)
```

Each word is padded with two spaces before and one after, and lowercased. `%` is true when the `similarity`, shared trigrams over all distinct trigrams, is above `pg_trgm.similarity_threshold`, 0.3 by default: `mongo driver` finds the package without its dot or capitals.

A trigram GIN index also serves `LIKE` and `ILIKE` with a wildcard at the start, which a B-tree can't ([lines 139-147](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L139-L147)):

```sql
-- A trigram index serves LIKE and ILIKE with a leading wildcard, which a B-tree can't: the steps of the 12,600 job documents
CREATE TABLE ci.doc_steps AS
SELECT s.name, s.conclusion
FROM ci.job_docs, JSON_TABLE(doc, '$.steps[*]' COLUMNS (name text PATH '$.name', conclusion text PATH '$.conclusion')) AS s;
CREATE INDEX doc_steps_name_trgm ON ci.doc_steps USING gin (name gin_trgm_ops);
VACUUM ANALYZE ci.doc_steps;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.doc_steps WHERE name ILIKE '%doctest%'
$$);
```

```text
SELECT 88160
CREATE INDEX
VACUUM
                                     QUERY PLAN
------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=500
   ->  Bitmap Heap Scan on doc_steps (actual rows=1840.00 loops=1)
         Recheck Cond: (name ~~* '%doctest%'::text)
         Heap Blocks: exact=487
         Buffers: shared hit+read=500
         ->  Bitmap Index Scan on doc_steps_name_trgm (actual rows=1840.00 loops=1)
               Index Cond: (name ~~* '%doctest%'::text)
               Index Searches: 1
               Buffers: shared hit+read=13
(10 rows)
```

The index finds the rows whose names contain the trigrams of `doctest`, and the recheck confirms the match: 500 pages for 88,160 step names. In SQL Server, `LIKE '%doctest%'` reads every row of the index or table.

## On Aurora

*To verify: nothing in this section ran on AWS.* `jsonb`, `JSON_TABLE` and full-text search are part of PostgreSQL's core, and I found no Aurora page that changes them. The extensions of this lesson are in the [Aurora PostgreSQL 18 extension table](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) at the same versions as in the image: `pg_trgm` 1.6 and `unaccent` 1.1. The table also has `fuzzystrmatch`, and `pg_bigm`, a bigram index meant for languages written without spaces between words.

Two parts of the lesson don't carry over as they are:

- **Loading files.** `pg_read_file` reads the server's file system, and on Aurora "you can't access the host OS, and you can't connect using the PostgreSQL `superuser` account" ([the `rds_superuser` role](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html)). The documents and pages would come from the client, with `COPY … FROM STDIN` as in [lesson 4](../04-csharp-java/).
- **Migrating SQL Server's full-text indexes.** AWS's [migration playbook](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.fulltextsearch.html) says that it "requires a full rewrite of the code that addresses creating, managing, and querying of full-text searches", and that PostgreSQL's engine, "significantly less comprehensive than SQL Server", is "sufficiently powerful for most common, basic full-text requirements". Its [JSON chapter](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.json.html) covers the functions. Both chapters are written for SQL Server 2019.

## Key takeaways

- `jsonb`, not `json`; `->` returns `jsonb`, `->>` text, and comparisons need a cast.
- `@>` and SQL/JSON paths query inside documents; `JSON_TABLE` turns them into typed rows.
- GIN serves containment on whole documents; `jsonb_path_ops` only serves `@>` and paths; a B-tree on an expression serves one key.
- Full-text search matches lexemes, not strings: the configuration chooses stop words and stemming, per language.
- `unaccent` in a custom configuration makes accents optional.
- `pg_trgm` finds typos and serves `LIKE '%…%'` with an index.

## Exercises

The solutions are in [`sql/07-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql).

1. From the job documents alone, count the failed steps by name, with a single `JSON_TABLE` that only returns failed steps. Then check that the steps in the documents are exactly those of `ci.steps`.

<details>
<summary>Solution</summary>

[Lines 6-26](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql#L6-L26):

```sql
-- Exercise 1: the steps that failed, straight from the job documents, checked against the flattened ci.steps table
CREATE TABLE ci.job_docs AS
SELECT j AS doc FROM jsonb_array_elements(pg_read_file('/course/data/jobs.json')::jsonb) AS j;

SELECT s.name AS step, count(*) AS failures
FROM ci.job_docs,
     JSON_TABLE(doc, '$.steps[*] ? (@.conclusion == "failure")' COLUMNS (name text PATH '$.name')) AS s
GROUP BY s.name
ORDER BY failures DESC, step;

SELECT count(*) AS differences FROM (
    (SELECT (doc->>'id')::bigint, s.number, s.name
     FROM ci.job_docs, JSON_TABLE(doc, '$.steps[*]' COLUMNS (number smallint PATH '$.number', name text PATH '$.name')) AS s
     EXCEPT
     SELECT job_id, number, name FROM ci.steps)
    UNION ALL
    (SELECT job_id, number, name FROM ci.steps
     EXCEPT
     SELECT (doc->>'id')::bigint, s.number, s.name
     FROM ci.job_docs, JSON_TABLE(doc, '$.steps[*]' COLUMNS (number smallint PATH '$.number', name text PATH '$.name')) AS s)
) AS d;
```

```text
SELECT 315
                  step                   | failures
-----------------------------------------+----------
 Formatting                              |        6
 Run actions/setup-dotnet@v6             |        3
 Run exit 3                              |        3
 Run ./.github/actions/hello-container   |        2
 Compile-fail doctests                   |        1
 Deploy to GitHub Pages                  |        1
 Fail                                    |        1
 Run date -u +%T                         |        1
 Run ./.github/actions/dotnet-restore    |        1
 Run ./.github/actions/exercise-commonjs |        1
 Run ./.github/actions/exercise-no-shell |        1
 Tests (fail on demand)                  |        1
(12 rows)

 differences
-------------
           0
(1 row)
```

The row path of `JSON_TABLE` can filter: `$.steps[*] ? (@.conclusion == "failure")`. The 22 failed steps are those that lesson 2's model gives. `EXCEPT` in both directions finds no difference between the documents and the table: the flattening lost no step, and added none.

</details>

2. Search the Spanish pages for the phrase `"planes de ejecución"`, ranked. Why wouldn't an English configuration work, even on these pages?

<details>
<summary>Solution</summary>

[Lines 28-39](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql#L28-L39):

```sql
-- Exercise 2: the Spanish pages about execution plans
CREATE TABLE site_pages AS
SELECT p.* FROM jsonb_to_recordset(pg_read_file('/course/data/pages.json')::jsonb->'pages') AS p(
    course text, locale text, slug text, title text, body text);

SELECT course, slug, round(ts_rank(to_tsvector('spanish', title || ' ' || body), query)::numeric, 3) AS rank
FROM site_pages, websearch_to_tsquery('spanish', '"planes de ejecución"') AS query
WHERE locale = 'es' AND to_tsvector('spanish', title || ' ' || body) @@ query
ORDER BY rank DESC, course, slug;

SELECT websearch_to_tsquery('spanish', '"planes de ejecución"') AS spanish,
       websearch_to_tsquery('english', '"planes de ejecución"') AS english;
```

```text
SELECT 48
      course       |      slug      | rank
-------------------+----------------+-------
 postgresql-aurora | index          | 0.197
 duckdb            | index          | 0.167
 duckdb            | 07-performance | 0.099
(3 rows)

      spanish       |             english
--------------------+----------------------------------
 'plan' <2> 'ejecu' | 'plane' <-> 'de' <-> 'ejecución'
(1 row)
```

The Spanish stemmer reduces `planes` to `plan` and `ejecución` to `ejecu`, and drops `de`, a stop word, while remembering its place: `<2>` means "two positions later". The English configuration doesn't know that `de` is a stop word nor how Spanish plurals end: it looks for `plane`, `de` and `ejecución` in sequence, lexemes that the Spanish `tsvector`s don't contain. The configuration of the query must be the one of the documents.

</details>

3. A search box receives `dependncy injection`, with a typo. Find the packages it means, first with `similarity`, then with [`word_similarity`](https://www.postgresql.org/docs/18/pgtrgm.html#PGTRGM-FUNCS-OPS). Why do they differ?

<details>
<summary>Solution</summary>

[Lines 41-52](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql#L41-L52):

```sql
-- Exercise 3: a search box receives "dependncy injection", with a typo
CREATE EXTENSION pg_trgm;
CREATE TABLE packages AS SELECT DISTINCT package FROM ga.package_refs;
SELECT package, round(similarity(package, 'dependncy injection')::numeric, 2) AS similarity
FROM packages
WHERE package % 'dependncy injection'
ORDER BY similarity DESC, package;

SELECT package, round(word_similarity('dependncy injection', package)::numeric, 2) AS word_similarity
FROM packages
WHERE 'dependncy injection' <% package
ORDER BY word_similarity DESC, package;
```

```text
CREATE EXTENSION
SELECT 136
                 package                  | similarity
------------------------------------------+------------
 Microsoft.Extensions.DependencyInjection |       0.33
(1 row)

                        package                        | word_similarity
-------------------------------------------------------+-----------------
 Microsoft.Extensions.DependencyInjection              |            0.60
 Microsoft.Extensions.DependencyInjection.Abstractions |            0.60
(2 rows)
```

`similarity` compares the whole strings: the longer `…DependencyInjection.Abstractions` has many trigrams that the search doesn't, and falls under 0.3. `word_similarity` measures how well the search matches the most similar part of the package name, and finds both at 0.60. `<%` is its operator, with its own threshold, 0.6 by default.

</details>

## Sources

- PostgreSQL 18 documentation: [JSON types](https://www.postgresql.org/docs/18/datatype-json.html), [JSON functions and operators](https://www.postgresql.org/docs/18/functions-json.html), [full-text search](https://www.postgresql.org/docs/18/textsearch.html), [text search types](https://www.postgresql.org/docs/18/datatype-textsearch.html), [controlling text search](https://www.postgresql.org/docs/18/textsearch-controls.html), [configuration](https://www.postgresql.org/docs/18/textsearch-configuration.html), [`unaccent`](https://www.postgresql.org/docs/18/unaccent.html), [`pg_trgm`](https://www.postgresql.org/docs/18/pgtrgm.html), [generic file access functions](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-GENFILE), [generated columns](https://www.postgresql.org/docs/18/ddl-generated-columns.html)
- SQL Server: [`OPENJSON`](https://learn.microsoft.com/sql/t-sql/functions/openjson-transact-sql), [the `json` data type](https://learn.microsoft.com/sql/t-sql/data-types/json-data-type), [`CREATE JSON INDEX`](https://learn.microsoft.com/sql/t-sql/statements/create-json-index-transact-sql), [full-text search](https://learn.microsoft.com/sql/relational-databases/search/full-text-search), [full-text catalogs](https://learn.microsoft.com/sql/relational-databases/search/create-and-manage-full-text-catalogs), [`CONTAINS`](https://learn.microsoft.com/sql/t-sql/queries/contains-transact-sql), [`FREETEXT`](https://learn.microsoft.com/sql/t-sql/queries/freetext-transact-sql), [`EDIT_DISTANCE`](https://learn.microsoft.com/sql/t-sql/functions/edit-distance-transact-sql)
- AWS: [extension versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), [the `rds_superuser` role](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html), migration playbook: [full-text search](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.fulltextsearch.html), [JSON](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.json.html), all read on 2026-09-16
