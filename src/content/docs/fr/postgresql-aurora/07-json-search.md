---
title: "7. JSON et recherche"
description: Stocker et interroger des documents avec jsonb — opérateurs, contenance, chemins SQL/JSON, JSON_TABLE, index GIN et jsonb_path_ops — puis la recherche plein texte sur les pages de ce site en trois langues, avec tsvector, tsquery, classement, ts_headline, unaccent, et pg_trgm pour les fautes de frappe et LIKE '%…%' ; comparés à OPENJSON et aux catalogues de texte intégral de SQL Server.
sidebar:
  order: 7
---

Le script de la leçon est [`sql/07-json-search.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql), les exercices sont dans [`sql/07-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql), et `check.sh` compare leur sortie à [`expected/07-json-search.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/07-json-search.txt) et [`expected/07-exercises.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/07-exercises.txt).

Deux sortes de données cette fois. Les documents sont les objets job de l'API GitHub, tels que l'instantané de CI les a exportés dans [`jobs.json`](https://github.com/spareilleux/learn/blob/main/code/duckdb/data/jobs.json) : la [leçon 2](../02-types/) les a aplatis dans `ci.jobs` et `ci.steps`, cette leçon les garde entiers. Le texte est ce site : [`data/extract_pages.py`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/data/extract_pages.py) a pris la prose du cours DuckDB et de ce cours, en anglais, français et espagnol, au commit `a1df189`, sans les blocs de code ni les cibles des liens, dans [`data/pages.json`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/data/pages.json) : 48 pages.

| SQL Server | PostgreSQL |
|---|---|
| JSON dans `nvarchar(max)`, `ISJSON` ; le type `json` (en préversion dans SQL Server 2025) | `jsonb`, analysé et validé à l'entrée |
| `JSON_VALUE`, `JSON_QUERY` | `->>`, `->`, `#>>`, `jsonb_path_query` |
| `OPENJSON … WITH (…)` | `JSON_TABLE(… COLUMNS (…))`, `jsonb_to_recordset` |
| index sur une colonne calculée à partir de `JSON_VALUE` | GIN sur tout le document, ou un B-tree sur une expression |
| catalogue et index de texte intégral, `CONTAINS`, `FREETEXT` | colonne `tsvector` avec un index GIN, `@@` |
| rang de `CONTAINSTABLE` | `ts_rank`, `ts_rank_cd` |
| `LIKE '%…%'` parcourt tout | index `pg_trgm` |

## json et jsonb

[Lignes 7-9](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L7-L9) :

```sql
-- json garde le texte tel qu'il a été écrit ; jsonb stocke une valeur analysée : clés triées, doublons écartés, le dernier gardé
SELECT '{"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"}'::json AS json,
       '{"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"}'::jsonb AS jsonb;
```

```text
                               json                               |                      jsonb
------------------------------------------------------------------+-------------------------------------------------
 {"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"} | {"name": "deploy", "labels": ["ubuntu-latest"]}
(1 row)
```

[`json`](https://www.postgresql.org/docs/18/datatype-json.html) vérifie le texte et le stocke tel qu'il a été écrit, clés en double comprises. `jsonb` stocke un arbre analysé : clés triées par longueur puis par octets, une valeur par clé, la dernière écrite. `jsonb` est celui à utiliser, sauf si le texte exact doit être restitué.

## Opérateurs

Les documents, une ligne par job ([lignes 11-23](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L11-L23)) :

```sql
-- Les documents job de l'API GitHub, tels qu'ils ont été exportés : une valeur jsonb par job
CREATE TABLE ci.job_docs (
    doc jsonb NOT NULL
);
INSERT INTO ci.job_docs
SELECT j FROM jsonb_array_elements(pg_read_file('/course/data/jobs.json')::jsonb) AS j;

-- -> renvoie du jsonb, ->> renvoie du text, #>> suit un chemin
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

- [`pg_read_file`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-GENFILE) lit un fichier sur le serveur ; par défaut, seul un superutilisateur peut l'appeler. [`jsonb_array_elements`](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-JSON-PROCESSING) transforme le tableau en lignes.
- `->` renvoie du `jsonb`, `->>` du `text`, `#>>` suit un chemin donné sous forme de tableau de textes. Les positions dans un tableau commencent à 0 en `jsonb`, là où les tableaux SQL commencent à 1.
- Une comparaison avec un nombre demande une conversion : `(doc->>'run_id')::bigint`.

Contenance et existence ([lignes 25-29](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L25-L29)) :

```sql
-- Contenance et existence
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

- `@>` demande si le document de gauche contient celui de droite. Pour un tableau, contenir signifie « a un élément qui contient » : 22 jobs ont au moins une étape dont la conclusion est `failure`.
- `?` demande si une chaîne est une clé, ou un élément d'un tableau ; `?|` si l'une de plusieurs l'est, `?&` si toutes le sont.

## Chemins SQL/JSON et JSON_TABLE

Un [chemin SQL/JSON](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-SQLJSON-PATH) parcourt l'intérieur d'un document, avec des filtres ([lignes 31-36](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L31-L36)) :

```sql
-- Un chemin SQL/JSON : les étapes en échec de chaque job
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

`$.steps[*] ? (@.conclusion == "failure").name` prend chaque étape, garde celles dont la conclusion est `failure`, et renvoie leur nom. `jsonb_path_query` renvoie une ligne par correspondance, `@?` demande s'il y en a au moins une. `#>> '{}'` transforme une chaîne `jsonb` en `text`, sans ses guillemets.

[`JSON_TABLE`](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-SQLJSON-TABLE), nouveau dans PostgreSQL 17, est la forme standard de l'`OPENJSON … WITH` de SQL Server ([lignes 38-48](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L38-L48)) :

```sql
-- JSON_TABLE transforme un document en lignes et en colonnes typées, comme OPENJSON ... WITH en T-SQL
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

Chaque colonne a un type et un chemin ; les horodatages sont lus comme `timestamptz`, et leur différence est un `interval`. L'étape 4 de ce job n'existe pas dans le document : GitHub a numéroté les étapes avec un trou.

Les documents sont des valeurs : les opérateurs en renvoient de nouvelles ([lignes 50-54](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L50-L54)) :

```sql
-- Modifier un document : || fusionne, - supprime une clé, jsonb_set remplace une valeur à un chemin
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

`-` supprime une clé, `||` fusionne deux objets, [`jsonb_set`](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-JSON-PROCESSING) remplace la valeur à un chemin. Un `UPDATE` qui change une clé réécrit tout le document, comme une nouvelle version de ligne ([leçon 6](../06-transactions/)) : les gros documents qui changent souvent ont leur place dans des colonnes.

## GIN sur des documents

315 documents tiennent en quelques pages. Le script les copie 40 fois, et utilise l'outil de plan de la [leçon 5](../05-indexes/#des-plans-stables-pour-une-leçon) ([lignes 56-69](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L56-L69)) :

```sql
-- Index GIN sur des documents, sur 40 copies des jobs
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

Un [index GIN sur `jsonb`](https://www.postgresql.org/docs/18/datatype-json.html#JSON-INDEXING) existe en deux classes d'opérateurs :

- `jsonb_ops`, par défaut, indexe chaque clé et chaque valeur séparément. Il sert `@>`, `?`, `?|`, `?&` et les correspondances de chemins.
- `jsonb_path_ops` indexe un hachage de chaque valeur avec le chemin de clés qui y mène. Il ne sert que `@>` et les correspondances de chemins, et il est généralement plus petit. Ici, il est sorti un peu plus grand, 1 752 ko contre 1 688 ko, et le planificateur l'a choisi.

L'index a renvoyé 280 documents, et la revérification sur la table en a gardé 40 : les 7 jobs qui ont une étape nommée `Compile-fail doctests` et une étape en échec, 40 fois, dont un seul job où cette étape a échoué. L'index sait qu'un document a les deux chemins, pas qu'ils appartiennent au même élément du tableau. 85 pages au lieu de 1 881.

Quand les requêtes lisent toujours la même clé, un B-tree sur l'expression, comme `((doc->>'run_id')::bigint)`, est plus petit et sert les intervalles et les tris, ce que GIN ne sait pas faire.

## Recherche plein texte

Chercher du texte avec `LIKE` trouve des chaînes, pas des mots : `index` ne correspond pas à `indexes`, et chaque ligne est lue. La [recherche plein texte](https://www.postgresql.org/docs/18/textsearch-intro.html) transforme un texte en `tsvector`, une liste triée de mots normalisés, les *lexèmes*, avec leurs positions. Une [configuration de recherche de texte](https://www.postgresql.org/docs/18/textsearch-configuration.html) décide comment : quels mots ignorer, et comment réduire un mot à sa racine ([lignes 71-92](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L71-L92)) :

```sql
-- Recherche plein texte : la prose de deux cours de ce site, en anglais, français et espagnol (data/extract_pages.py)
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

-- Un tsvector contient des mots normalisés, les lexèmes, avec leurs positions ; une configuration de recherche de texte décide comment
SELECT to_tsvector('english', 'Indexes and plans: the planner chose a Bitmap Index Scan') AS english,
       to_tsvector('french', 'Index et plans : le planificateur a choisi un parcours d''index') AS french,
       to_tsvector('simple', 'Indexes and plans') AS simple;

-- websearch_to_tsquery lit la syntaxe d'un champ de recherche : mots, "phrases", or, -exclus
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

- `english` supprime `and` et `the`, réduit `Indexes` à `index`, et `chose` reste `chose` : un racinisateur coupe les suffixes, il ne connaît pas les verbes irréguliers.
- `french` réduit `planificateur` à `planif`, et garde `a`, qui n'est pas dans ses mots vides.
- `simple` ne fait que passer en minuscules.
- [`websearch_to_tsquery`](https://www.postgresql.org/docs/18/textsearch-controls.html#TEXTSEARCH-PARSING-QUERIES) lit ce qu'on tape dans un champ de recherche : les mots sont joints par `&`, `-` exclut, `or` est `|`, et une phrase entre guillemets devient `<->`, « suivi de ».

`site.pages` stocke chaque page avec sa configuration, un [`regconfig`](https://www.postgresql.org/docs/18/datatype-textsearch.html), et un `tsvector` en colonne générée stockée qui donne au titre (`A`) plus de poids qu'au corps (`B`). La configuration est une colonne à part, remplie par l'`INSERT` : une colonne générée ne peut pas faire référence à une autre colonne générée.

```sql
INSERT INTO site.pages (course, locale, slug, title, body, config)
SELECT p.course, p.locale, p.slug, p.title, p.body,
       CASE p.locale WHEN 'fr' THEN 'french' WHEN 'es' THEN 'spanish' ELSE 'english' END::regconfig
FROM jsonb_to_recordset(pg_read_file('/course/data/pages.json')::jsonb->'pages') AS p(
    course text, locale text, slug text, title text, body text);
CREATE INDEX pages_search ON site.pages USING gin (search);
```

### Classement

[Lignes 101-106](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L101-L106) :

```sql
-- Les pages qui correspondent, les meilleures d'abord : une correspondance dans le titre pèse plus qu'une dans le corps
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

`@@` fait correspondre un `tsvector` et une `tsquery`, par l'index GIN. [`ts_rank`](https://www.postgresql.org/docs/18/textsearch-controls.html#TEXTSEARCH-RANKING) note la fréquence des mots, et leur poids : la leçon 4 est la page sur les pools de connexions. Les fonctions de classement ne savent rien d'autre d'une page ; un moteur de recherche qui a besoin de plus, comme des synonymes, des fautes de frappe dans plusieurs mots ou une pertinence apprise des clics, est un autre outil.

[`ts_headline`](https://www.postgresql.org/docs/18/textsearch-controls.html#TEXTSEARCH-HEADLINE) montre les mots trouvés dans leur contexte ([lignes 108-112](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L108-L112)) :

```sql
-- ts_headline montre les mots trouvés dans leur contexte
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

La phrase `"prepared statements"` a trouvé `pg_prepared_statements` dans le journal : l'analyseur coupe cet identifiant à ses underscores. `regexp_replace` ne fait que joindre les lignes de l'extrait, pour la sortie.

### Accents

[Lignes 114-129](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L114-L129) :

```sql
-- La même recherche en français ne trouve rien pour un mot écrit sans son accent
SELECT count(*) FILTER (WHERE search @@ websearch_to_tsquery('french', 'modélisation')) AS with_accent,
       count(*) FILTER (WHERE search @@ websearch_to_tsquery('french', 'modelisation')) AS without_accent
FROM site.pages WHERE locale = 'fr';

-- unaccent dans une configuration à nous supprime les accents avant la racinisation
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

La configuration `french` garde les accents, donc `modelisation`, tapé sans son accent, ne trouve aucune des trois pages françaises que `modélisation` trouve. L'extension [`unaccent`](https://www.postgresql.org/docs/18/unaccent.html) est un dictionnaire qui supprime les accents ; une configuration à nous l'exécute avant le racinisateur français, sur les documents comme sur les requêtes. La dernière requête calcule le `tsvector` à la volée, en lisant chaque page française : une vraie table le stockerait, ou indexerait l'expression.

## pg_trgm

[`pg_trgm`](https://www.postgresql.org/docs/18/pgtrgm.html) découpe une chaîne en trigrammes, des suites de trois caractères, et compare les chaînes d'après les trigrammes qu'elles partagent ([lignes 131-137](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L131-L137)) :

```sql
-- pg_trgm : similarité entre chaînes, d'après leurs suites de trois lettres
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

Chaque mot est complété par deux espaces avant et une après, et passé en minuscules. `%` est vrai quand la `similarity`, les trigrammes communs sur l'ensemble des trigrammes distincts, dépasse `pg_trgm.similarity_threshold`, 0,3 par défaut : `mongo driver` trouve le paquet sans son point ni ses majuscules.

Un index GIN de trigrammes sert aussi `LIKE` et `ILIKE` avec un joker au début, ce qu'un B-tree ne peut pas faire ([lignes 139-147](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L139-L147)) :

```sql
-- Un index de trigrammes sert LIKE et ILIKE avec un joker au début, ce qu'un B-tree ne peut pas faire : les étapes des 12 600 documents job
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

L'index trouve les lignes dont le nom contient les trigrammes de `doctest`, et la revérification confirme la correspondance : 500 pages pour 88 160 noms d'étapes. Dans SQL Server, `LIKE '%doctest%'` lit chaque ligne de l'index ou de la table.

## Sur Aurora

*À vérifier : rien dans cette section n'a été exécuté sur AWS.* `jsonb`, `JSON_TABLE` et la recherche plein texte font partie du cœur de PostgreSQL, et je n'ai trouvé aucune page d'Aurora qui les modifie. Les extensions de cette leçon sont dans le [tableau des extensions d'Aurora PostgreSQL 18](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) aux mêmes versions que dans l'image : `pg_trgm` 1.6 et `unaccent` 1.1. Le tableau contient aussi `fuzzystrmatch`, et `pg_bigm`, un index de bigrammes pensé pour les langues écrites sans espaces entre les mots.

Deux parties de la leçon ne se transposent pas telles quelles :

- **Charger des fichiers.** `pg_read_file` lit le système de fichiers du serveur, et sur Aurora « you can't access the host OS, and you can't connect using the PostgreSQL `superuser` account » ([le rôle `rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html)). Les documents et les pages viendraient du client, avec `COPY … FROM STDIN` comme dans la [leçon 4](../04-csharp-java/).
- **Migrer les index de texte intégral de SQL Server.** Le [guide de migration](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.fulltextsearch.html) d'AWS dit que cela « requires a full rewrite of the code that addresses creating, managing, and querying of full-text searches », et que le moteur de PostgreSQL, « significantly less comprehensive than SQL Server », est « sufficiently powerful for most common, basic full-text requirements ». Son [chapitre JSON](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.json.html) couvre les fonctions. Les deux chapitres sont écrits pour SQL Server 2019.

## À retenir

- `jsonb`, pas `json` ; `->` renvoie du `jsonb`, `->>` du texte, et les comparaisons demandent une conversion.
- `@>` et les chemins SQL/JSON interrogent l'intérieur des documents ; `JSON_TABLE` les transforme en lignes typées.
- GIN sert la contenance sur des documents entiers ; `jsonb_path_ops` ne sert que `@>` et les chemins ; un B-tree sur une expression sert une clé.
- La recherche plein texte fait correspondre des lexèmes, pas des chaînes : la configuration choisit les mots vides et la racinisation, par langue.
- `unaccent` dans une configuration personnalisée rend les accents facultatifs.
- `pg_trgm` trouve les fautes de frappe et sert `LIKE '%…%'` avec un index.

## Exercices

Les solutions sont dans [`sql/07-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql).

1. À partir des seuls documents des jobs, compte les étapes en échec par nom, avec un seul `JSON_TABLE` qui ne renvoie que les étapes en échec. Vérifie ensuite que les étapes des documents sont exactement celles de `ci.steps`.

<details>
<summary>Solution</summary>

[Lignes 6-26](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql#L6-L26) :

```sql
-- Exercice 1 : les étapes en échec, directement depuis les documents job, vérifiées contre la table aplatie ci.steps
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

Le chemin de lignes de `JSON_TABLE` peut filtrer : `$.steps[*] ? (@.conclusion == "failure")`. Les 22 étapes en échec sont celles que donne le modèle de la leçon 2. `EXCEPT` dans les deux sens ne trouve aucune différence entre les documents et la table : l'aplatissement n'a perdu aucune étape, et n'en a ajouté aucune.

</details>

2. Cherche dans les pages espagnoles la phrase `"planes de ejecución"`, avec un classement. Pourquoi une configuration anglaise ne marcherait-elle pas, même sur ces pages ?

<details>
<summary>Solution</summary>

[Lignes 28-39](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql#L28-L39) :

```sql
-- Exercice 2 : les pages espagnoles sur les plans d'exécution
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

Le racinisateur espagnol réduit `planes` à `plan` et `ejecución` à `ejecu`, et écarte `de`, un mot vide, tout en retenant sa place : `<2>` signifie « deux positions plus loin ». La configuration anglaise ne sait ni que `de` est un mot vide ni comment se terminent les pluriels espagnols : elle cherche `plane`, `de` et `ejecución` à la suite, des lexèmes que les `tsvector` espagnols ne contiennent pas. La configuration de la requête doit être celle des documents.

</details>

3. Un champ de recherche reçoit `dependncy injection`, avec une faute de frappe. Trouve les paquets visés, d'abord avec `similarity`, puis avec [`word_similarity`](https://www.postgresql.org/docs/18/pgtrgm.html#PGTRGM-FUNCS-OPS). Pourquoi diffèrent-ils ?

<details>
<summary>Solution</summary>

[Lignes 41-52](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql#L41-L52) :

```sql
-- Exercice 3 : un champ de recherche reçoit "dependncy injection", avec une faute de frappe
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

`similarity` compare les chaînes entières : le plus long `…DependencyInjection.Abstractions` a beaucoup de trigrammes que la recherche n'a pas, et passe sous 0,3. `word_similarity` mesure à quel point la recherche correspond à la partie la plus semblable du nom du paquet, et trouve les deux à 0,60. `<%` est son opérateur, avec son propre seuil, 0,6 par défaut.

</details>

## Sources

- Documentation de PostgreSQL 18 : [types JSON](https://www.postgresql.org/docs/18/datatype-json.html), [fonctions et opérateurs JSON](https://www.postgresql.org/docs/18/functions-json.html), [recherche plein texte](https://www.postgresql.org/docs/18/textsearch.html), [types de recherche de texte](https://www.postgresql.org/docs/18/datatype-textsearch.html), [contrôler la recherche de texte](https://www.postgresql.org/docs/18/textsearch-controls.html), [configuration](https://www.postgresql.org/docs/18/textsearch-configuration.html), [`unaccent`](https://www.postgresql.org/docs/18/unaccent.html), [`pg_trgm`](https://www.postgresql.org/docs/18/pgtrgm.html), [fonctions génériques d'accès aux fichiers](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-GENFILE), [colonnes générées](https://www.postgresql.org/docs/18/ddl-generated-columns.html)
- SQL Server : [`OPENJSON`](https://learn.microsoft.com/sql/t-sql/functions/openjson-transact-sql), [le type de données `json`](https://learn.microsoft.com/sql/t-sql/data-types/json-data-type), [`CREATE JSON INDEX`](https://learn.microsoft.com/sql/t-sql/statements/create-json-index-transact-sql), [recherche en texte intégral](https://learn.microsoft.com/sql/relational-databases/search/full-text-search), [catalogues de texte intégral](https://learn.microsoft.com/sql/relational-databases/search/create-and-manage-full-text-catalogs), [`CONTAINS`](https://learn.microsoft.com/sql/t-sql/queries/contains-transact-sql), [`FREETEXT`](https://learn.microsoft.com/sql/t-sql/queries/freetext-transact-sql), [`EDIT_DISTANCE`](https://learn.microsoft.com/sql/t-sql/functions/edit-distance-transact-sql)
- AWS : [versions des extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), [le rôle `rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html), guide de migration : [recherche plein texte](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.fulltextsearch.html), [JSON](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.json.html), toutes lues le 2026-09-16
