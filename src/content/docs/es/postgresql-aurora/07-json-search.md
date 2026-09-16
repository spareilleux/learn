---
title: "7. JSON y búsqueda"
description: Guardar y consultar documentos con jsonb — operadores, contención, rutas SQL/JSON, JSON_TABLE, índices GIN y jsonb_path_ops — y después búsqueda de texto completo sobre las propias páginas de este sitio en tres idiomas, con tsvector, tsquery, ranking, ts_headline, unaccent, y pg_trgm para las erratas y LIKE '%…%'; comparado con OPENJSON y los catálogos de texto completo de SQL Server.
sidebar:
  order: 7
---

El script de la lección es [`sql/07-json-search.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql), los ejercicios están en [`sql/07-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql), y `check.sh` compara su salida con [`expected/07-json-search.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/07-json-search.txt) y [`expected/07-exercises.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/07-exercises.txt).

Esta vez hay dos tipos de datos. Los documentos son los objetos job de la API de GitHub, tal como los exportó la instantánea de CI en [`jobs.json`](https://github.com/spareilleux/learn/blob/main/code/duckdb/data/jobs.json): la [lección 2](../02-types/) los aplanó en `ci.jobs` y `ci.steps`, esta lección los conserva enteros. El texto es este sitio: [`data/extract_pages.py`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/data/extract_pages.py) tomó la prosa del curso de DuckDB y de este curso, en inglés, francés y español, en el commit `a1df189`, sin bloques de código ni destinos de enlaces, y la puso en [`data/pages.json`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/data/pages.json): 48 páginas.

| SQL Server | PostgreSQL |
|---|---|
| JSON en `nvarchar(max)`, `ISJSON`; el tipo `json` (preview en SQL Server 2025) | `jsonb`, analizado y validado al entrar |
| `JSON_VALUE`, `JSON_QUERY` | `->>`, `->`, `#>>`, `jsonb_path_query` |
| `OPENJSON … WITH (…)` | `JSON_TABLE(… COLUMNS (…))`, `jsonb_to_recordset` |
| índice sobre una columna calculada con `JSON_VALUE` | GIN sobre el documento entero, o un B-tree sobre una expresión |
| catálogo e índice de texto completo, `CONTAINS`, `FREETEXT` | columna `tsvector` con un índice GIN, `@@` |
| rank de `CONTAINSTABLE` | `ts_rank`, `ts_rank_cd` |
| `LIKE '%…%'` recorre todo | índice `pg_trgm` |

## json y jsonb

[Líneas 7-9](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L7-L9):

```sql
-- json conserva el texto tal como se escribió; jsonb guarda un valor analizado: claves ordenadas, duplicados descartados, se conserva el último
SELECT '{"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"}'::json AS json,
       '{"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"}'::jsonb AS jsonb;
```

```text
                               json                               |                      jsonb
------------------------------------------------------------------+-------------------------------------------------
 {"name": "build", "labels": ["ubuntu-latest"], "name": "deploy"} | {"name": "deploy", "labels": ["ubuntu-latest"]}
(1 row)
```

[`json`](https://www.postgresql.org/docs/18/datatype-json.html) comprueba el texto y lo guarda tal como se escribió, claves duplicadas incluidas. `jsonb` guarda un árbol analizado: claves ordenadas por longitud y luego por bytes, un valor por clave, el último escrito. `jsonb` es el que hay que usar, salvo que deba volver el texto exacto.

## Operadores

Los documentos, una fila por job ([líneas 11-23](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L11-L23)):

```sql
-- Los documentos job de la API de GitHub, tal como se exportaron: un valor jsonb por job
CREATE TABLE ci.job_docs (
    doc jsonb NOT NULL
);
INSERT INTO ci.job_docs
SELECT j FROM jsonb_array_elements(pg_read_file('/course/data/jobs.json')::jsonb) AS j;

-- -> devuelve jsonb, ->> devuelve text, #>> sigue una ruta
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

- [`pg_read_file`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-GENFILE) lee un archivo en el servidor; por defecto, solo un superusuario puede llamarla. [`jsonb_array_elements`](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-JSON-PROCESSING) convierte el array en filas.
- `->` devuelve `jsonb`, `->>` devuelve `text`, `#>>` sigue una ruta dada como array de texto. Las posiciones de un array empiezan en 0 en `jsonb`, mientras que los arrays SQL empiezan en 1.
- Una comparación con un número necesita una conversión: `(doc->>'run_id')::bigint`.

Contención y existencia ([líneas 25-29](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L25-L29)):

```sql
-- Contención y existencia
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

- `@>` pregunta si el documento de la izquierda contiene al de la derecha. Para un array, contener significa «tiene un elemento que contiene»: 22 jobs tienen al menos un paso cuya conclusión es `failure`.
- `?` pregunta si una cadena es una clave, o un elemento de un array; `?|` si alguna de varias lo es, `?&` si todas lo son.

## Rutas SQL/JSON y JSON_TABLE

Una [ruta SQL/JSON](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-SQLJSON-PATH) recorre el interior de un documento, con filtros ([líneas 31-36](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L31-L36)):

```sql
-- Una ruta SQL/JSON: los pasos fallidos de cada job
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

`$.steps[*] ? (@.conclusion == "failure").name` toma cada paso, conserva aquellos cuya conclusión es `failure`, y devuelve su nombre. `jsonb_path_query` devuelve una fila por coincidencia, `@?` pregunta si hay al menos una. `#>> '{}'` convierte una cadena `jsonb` en `text`, sin sus comillas.

[`JSON_TABLE`](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-SQLJSON-TABLE), nuevo en PostgreSQL 17, es la forma estándar del `OPENJSON … WITH` de SQL Server ([líneas 38-48](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L38-L48)):

```sql
-- JSON_TABLE convierte un documento en filas y columnas con tipo, como OPENJSON ... WITH en T-SQL
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

Cada columna tiene un tipo y una ruta; las marcas de tiempo se leen como `timestamptz`, y su diferencia es un `interval`. El paso 4 de este job no existe en el documento: GitHub numeró los pasos con un hueco.

Los documentos son valores: los operadores devuelven otros nuevos ([líneas 50-54](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L50-L54)):

```sql
-- Modificar un documento: || fusiona, - elimina una clave, jsonb_set sustituye un valor en una ruta
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

`-` elimina una clave, `||` fusiona dos objetos, [`jsonb_set`](https://www.postgresql.org/docs/18/functions-json.html#FUNCTIONS-JSON-PROCESSING) sustituye el valor en una ruta. Un `UPDATE` que cambia una clave vuelve a escribir el documento entero, como una nueva versión de fila ([lección 6](../06-transactions/)): los documentos grandes que cambian a menudo deberían ir en columnas.

## GIN sobre documentos

315 documentos caben en unas pocas páginas. El script los copia 40 veces, y usa la función auxiliar de planes de la [lección 5](../05-indexes/#planes-estables-para-una-lección) ([líneas 56-69](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L56-L69)):

```sql
-- Índices GIN sobre documentos, en 40 copias de los jobs
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

Un [índice GIN sobre `jsonb`](https://www.postgresql.org/docs/18/datatype-json.html#JSON-INDEXING) existe con dos clases de operadores:

- `jsonb_ops`, la de por defecto, indexa por separado cada clave y cada valor. Sirve a `@>`, `?`, `?|`, `?&` y a las coincidencias de rutas.
- `jsonb_path_ops` indexa un hash de cada valor con la ruta de claves que lleva a él. Solo sirve a `@>` y a las coincidencias de rutas, y suele ser más pequeño. Aquí salió algo más grande, 1752 kB frente a 1688 kB, y el planificador lo eligió.

El índice devolvió 280 documentos, y la nueva comprobación en la tabla conservó 40: los 7 jobs con un paso llamado `Compile-fail doctests` y un paso fallido, 40 veces, de los cuales solo en un job falló ese paso. El índice sabe que un documento tiene ambas rutas, no que pertenecen al mismo elemento del array. 85 páginas en lugar de 1881.

Cuando las consultas leen siempre la misma clave, un B-tree sobre la expresión, como `((doc->>'run_id')::bigint)`, es más pequeño y sirve a rangos y ordenaciones, cosa que GIN no puede hacer.

## Búsqueda de texto completo

Buscar texto con `LIKE` encuentra cadenas, no palabras: `index` no coincide con `indexes`, y se lee cada fila. La [búsqueda de texto completo](https://www.postgresql.org/docs/18/textsearch-intro.html) convierte un texto en un `tsvector`, una lista ordenada de palabras normalizadas, los *lexemas*, con sus posiciones. Una [configuración de búsqueda de texto](https://www.postgresql.org/docs/18/textsearch-configuration.html) decide cómo: qué palabras omitir, y cómo reducir una palabra a su raíz ([líneas 71-92](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L71-L92)):

```sql
-- Búsqueda de texto completo: la prosa de dos cursos de este sitio, en inglés, francés y español (data/extract_pages.py)
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

-- Un tsvector contiene palabras normalizadas, lexemas, con sus posiciones; una configuración de búsqueda de texto decide cómo
SELECT to_tsvector('english', 'Indexes and plans: the planner chose a Bitmap Index Scan') AS english,
       to_tsvector('french', 'Index et plans : le planificateur a choisi un parcours d''index') AS french,
       to_tsvector('simple', 'Indexes and plans') AS simple;

-- websearch_to_tsquery lee la sintaxis de un cuadro de búsqueda: palabras, "frases", or, -excluidas
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

- `english` elimina `and` y `the`, reduce `Indexes` a `index`, y `chose` se queda en `chose`: un stemmer corta sufijos, no conoce los verbos irregulares.
- `french` reduce `planificateur` a `planif`, y conserva `a`, que no está entre sus stop words.
- `simple` solo pasa a minúsculas.
- [`websearch_to_tsquery`](https://www.postgresql.org/docs/18/textsearch-controls.html#TEXTSEARCH-PARSING-QUERIES) lee lo que la gente escribe en un cuadro de búsqueda: las palabras se unen con `&`, `-` excluye, `or` es `|`, y una frase entre comillas se convierte en `<->`, «seguido de».

`site.pages` guarda cada página con su configuración, un [`regconfig`](https://www.postgresql.org/docs/18/datatype-textsearch.html), y un `tsvector` generado almacenado que pondera el título (`A`) por encima del cuerpo (`B`). La configuración es una columna propia, fijada por el `INSERT`: una columna generada no puede referirse a otra columna generada.

```sql
INSERT INTO site.pages (course, locale, slug, title, body, config)
SELECT p.course, p.locale, p.slug, p.title, p.body,
       CASE p.locale WHEN 'fr' THEN 'french' WHEN 'es' THEN 'spanish' ELSE 'english' END::regconfig
FROM jsonb_to_recordset(pg_read_file('/course/data/pages.json')::jsonb->'pages') AS p(
    course text, locale text, slug text, title text, body text);
CREATE INDEX pages_search ON site.pages USING gin (search);
```

### Ranking

[Líneas 101-106](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L101-L106):

```sql
-- Las páginas que coinciden, las mejores primero: las coincidencias en el título pesan más que en el cuerpo
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

`@@` compara un `tsvector` con un `tsquery`, a través del índice GIN. [`ts_rank`](https://www.postgresql.org/docs/18/textsearch-controls.html#TEXTSEARCH-RANKING) puntúa la frecuencia con que aparecen las palabras, y con qué peso: la lección 4 es la página sobre los pools de conexiones. Las funciones de ranking no saben nada más de una página; un buscador que necesite más, como sinónimos, erratas en varias palabras o relevancia aprendida de los clics, es otra herramienta.

[`ts_headline`](https://www.postgresql.org/docs/18/textsearch-controls.html#TEXTSEARCH-HEADLINE) muestra las palabras encontradas en su contexto ([líneas 108-112](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L108-L112)):

```sql
-- ts_headline muestra las palabras encontradas en su contexto
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

La frase `"prepared statements"` coincidió con `pg_prepared_statements` en el diario: el analizador corta ese identificador en sus guiones bajos. `regexp_replace` solo une las líneas del extracto, para la salida.

### Acentos

[Líneas 114-129](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L114-L129):

```sql
-- La misma búsqueda en francés no encuentra nada para una palabra escrita sin su acento
SELECT count(*) FILTER (WHERE search @@ websearch_to_tsquery('french', 'modélisation')) AS with_accent,
       count(*) FILTER (WHERE search @@ websearch_to_tsquery('french', 'modelisation')) AS without_accent
FROM site.pages WHERE locale = 'fr';

-- unaccent en una configuración propia elimina los acentos antes de reducir las palabras a su raíz
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

La configuración `french` conserva los acentos, así que `modelisation`, escrito sin su acento, no encuentra ninguna de las tres páginas en francés que encuentra `modélisation`. La extensión [`unaccent`](https://www.postgresql.org/docs/18/unaccent.html) es un diccionario que elimina los acentos; una configuración propia lo ejecuta antes del stemmer francés, tanto en los documentos como en las consultas. La última consulta calcula el `tsvector` sobre la marcha, leyendo cada página en francés: una tabla real lo guardaría, o indexaría la expresión.

## pg_trgm

[`pg_trgm`](https://www.postgresql.org/docs/18/pgtrgm.html) corta una cadena en trigramas, secuencias de tres caracteres, y compara las cadenas por los trigramas que comparten ([líneas 131-137](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L131-L137)):

```sql
-- pg_trgm: similitud entre cadenas, a partir de sus secuencias de tres letras
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

Cada palabra se rellena con dos espacios delante y uno detrás, y se pasa a minúsculas. `%` es verdadero cuando la `similarity`, los trigramas compartidos sobre todos los trigramas distintos, supera `pg_trgm.similarity_threshold`, 0,3 por defecto: `mongo driver` encuentra el paquete sin su punto ni sus mayúsculas.

Un índice GIN de trigramas también sirve a `LIKE` e `ILIKE` con un comodín al principio, cosa que un B-tree no puede hacer ([líneas 139-147](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-json-search.sql#L139-L147)):

```sql
-- Un índice de trigramas sirve a LIKE e ILIKE con un comodín inicial, cosa que un B-tree no puede: los pasos de los 12 600 documentos job
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

El índice encuentra las filas cuyos nombres contienen los trigramas de `doctest`, y la nueva comprobación confirma la coincidencia: 500 páginas para 88 160 nombres de pasos. En SQL Server, `LIKE '%doctest%'` lee cada fila del índice o de la tabla.

## En Aurora

*Por verificar: nada de esta sección se ejecutó en AWS.* `jsonb`, `JSON_TABLE` y la búsqueda de texto completo forman parte del núcleo de PostgreSQL, y no encontré ninguna página de Aurora que los cambie. Las extensiones de esta lección están en la [tabla de extensiones de Aurora PostgreSQL 18](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) en las mismas versiones que en la imagen: `pg_trgm` 1.6 y `unaccent` 1.1. La tabla también tiene `fuzzystrmatch`, y `pg_bigm`, un índice de bigramas pensado para los idiomas que se escriben sin espacios entre palabras.

Dos partes de la lección no se trasladan tal cual:

- **Cargar archivos.** `pg_read_file` lee el sistema de archivos del servidor, y en Aurora «you can't access the host OS, and you can't connect using the PostgreSQL `superuser` account» ([el rol `rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html)). Los documentos y las páginas vendrían del cliente, con `COPY … FROM STDIN` como en la [lección 4](../04-csharp-java/).
- **Migrar los índices de texto completo de SQL Server.** La [guía de migración](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.fulltextsearch.html) de AWS dice que «requires a full rewrite of the code that addresses creating, managing, and querying of full-text searches», y que el motor de PostgreSQL, «significantly less comprehensive than SQL Server», es «sufficiently powerful for most common, basic full-text requirements». Su [capítulo sobre JSON](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.json.html) cubre las funciones. Ambos capítulos están escritos para SQL Server 2019.

## Puntos clave

- `jsonb`, no `json`; `->` devuelve `jsonb`, `->>` texto, y las comparaciones necesitan una conversión.
- `@>` y las rutas SQL/JSON consultan el interior de los documentos; `JSON_TABLE` los convierte en filas con tipos.
- GIN sirve a la contención sobre documentos enteros; `jsonb_path_ops` solo sirve a `@>` y a las rutas; un B-tree sobre una expresión sirve a una clave.
- La búsqueda de texto completo compara lexemas, no cadenas: la configuración elige las stop words y la reducción a la raíz, por idioma.
- `unaccent` en una configuración propia hace opcionales los acentos.
- `pg_trgm` encuentra erratas y sirve a `LIKE '%…%'` con un índice.

## Ejercicios

Las soluciones están en [`sql/07-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql).

1. Solo a partir de los documentos de los jobs, cuenta los pasos fallidos por nombre, con un único `JSON_TABLE` que solo devuelva pasos fallidos. Luego comprueba que los pasos de los documentos son exactamente los de `ci.steps`.

<details>
<summary>Solución</summary>

[Líneas 6-26](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql#L6-L26):

```sql
-- Ejercicio 1: los pasos que fallaron, directamente de los documentos job, comprobados contra la tabla aplanada ci.steps
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

La ruta de filas de `JSON_TABLE` puede filtrar: `$.steps[*] ? (@.conclusion == "failure")`. Los 22 pasos fallidos son los que da el modelo de la lección 2. `EXCEPT` en ambos sentidos no encuentra ninguna diferencia entre los documentos y la tabla: el aplanado no perdió ningún paso, ni añadió ninguno.

</details>

2. Busca en las páginas en español la frase `"planes de ejecución"`, ordenadas por ranking. ¿Por qué no funcionaría una configuración inglesa, incluso sobre estas páginas?

<details>
<summary>Solución</summary>

[Líneas 28-39](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql#L28-L39):

```sql
-- Ejercicio 2: las páginas en español sobre los planes de ejecución
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

El stemmer español reduce `planes` a `plan` y `ejecución` a `ejecu`, y descarta `de`, una stop word, recordando su posición: `<2>` significa «dos posiciones después». La configuración inglesa no sabe que `de` es una stop word ni cómo terminan los plurales en español: busca `plane`, `de` y `ejecución` seguidos, lexemas que los `tsvector` en español no contienen. La configuración de la consulta debe ser la de los documentos.

</details>

3. Un cuadro de búsqueda recibe `dependncy injection`, con una errata. Encuentra los paquetes a los que se refiere, primero con `similarity`, luego con [`word_similarity`](https://www.postgresql.org/docs/18/pgtrgm.html#PGTRGM-FUNCS-OPS). ¿Por qué difieren?

<details>
<summary>Solución</summary>

[Líneas 41-52](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/07-exercises.sql#L41-L52):

```sql
-- Ejercicio 3: un cuadro de búsqueda recibe "dependncy injection", con una errata
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

`similarity` compara las cadenas enteras: el más largo, `…DependencyInjection.Abstractions`, tiene muchos trigramas que la búsqueda no tiene, y cae por debajo de 0,3. `word_similarity` mide hasta qué punto la búsqueda coincide con la parte más parecida del nombre del paquete, y encuentra ambos a 0,60. `<%` es su operador, con su propio umbral, 0,6 por defecto.

</details>

## Fuentes

- Documentación de PostgreSQL 18: [tipos JSON](https://www.postgresql.org/docs/18/datatype-json.html), [funciones y operadores JSON](https://www.postgresql.org/docs/18/functions-json.html), [búsqueda de texto completo](https://www.postgresql.org/docs/18/textsearch.html), [tipos de búsqueda de texto](https://www.postgresql.org/docs/18/datatype-textsearch.html), [controlar la búsqueda de texto](https://www.postgresql.org/docs/18/textsearch-controls.html), [configuración](https://www.postgresql.org/docs/18/textsearch-configuration.html), [`unaccent`](https://www.postgresql.org/docs/18/unaccent.html), [`pg_trgm`](https://www.postgresql.org/docs/18/pgtrgm.html), [funciones genéricas de acceso a archivos](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-GENFILE), [columnas generadas](https://www.postgresql.org/docs/18/ddl-generated-columns.html)
- SQL Server: [`OPENJSON`](https://learn.microsoft.com/sql/t-sql/functions/openjson-transact-sql), [el tipo de datos `json`](https://learn.microsoft.com/sql/t-sql/data-types/json-data-type), [`CREATE JSON INDEX`](https://learn.microsoft.com/sql/t-sql/statements/create-json-index-transact-sql), [búsqueda de texto completo](https://learn.microsoft.com/sql/relational-databases/search/full-text-search), [catálogos de texto completo](https://learn.microsoft.com/sql/relational-databases/search/create-and-manage-full-text-catalogs), [`CONTAINS`](https://learn.microsoft.com/sql/t-sql/queries/contains-transact-sql), [`FREETEXT`](https://learn.microsoft.com/sql/t-sql/queries/freetext-transact-sql), [`EDIT_DISTANCE`](https://learn.microsoft.com/sql/t-sql/functions/edit-distance-transact-sql)
- AWS: [versiones de las extensiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), [el rol `rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.rds_superuser.html), guía de migración: [búsqueda de texto completo](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.fulltextsearch.html), [JSON](https://docs.aws.amazon.com/dms/latest/sql-server-to-aurora-postgresql-migration-playbook/chap-sql-server-aurora-pg.tsql.json.html), todas consultadas el 2026-09-16
