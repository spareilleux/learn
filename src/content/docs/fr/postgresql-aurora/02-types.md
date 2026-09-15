---
title: 2. Types et modélisation
description: Le modèle du cours, et les types natifs de PostgreSQL vus depuis SQL Server — numeric et float, text et varchar, timestamptz et ce qu'il ne stocke pas, les intervalles, uuid version 7, json et jsonb, tableaux et intervalles de valeurs — avec les contraintes CHECK, les domaines, les contraintes d'exclusion, UNIQUE et NULL, et les colonnes générées virtuelles ; et ce que les contraintes trouvent dans les références de projets de Guitar Alchemist.
sidebar:
  order: 2
---

Le modèle du cours est [`sql/schema.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql) ; chaque script, à partir de cette leçon, le charge d'abord. Le script de la leçon elle-même est [`sql/02-types.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql), les exercices sont dans [`sql/02-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql), et `check.sh` compare leur sortie à [`expected/02-types.txt`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/expected/02-types.txt) et [`expected/02-exercises.txt`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/expected/02-exercises.txt).

## Depuis les types de SQL Server

| SQL Server | PostgreSQL | Attention |
|---|---|---|
| `int`, `bigint`, `smallint` | `integer`, `bigint`, `smallint` | pas de `tinyint`, pas de types non signés |
| `bit` | `boolean` | un vrai type, avec `true`, `false` et `NULL` |
| `decimal(p,s)`, `money` | `numeric(p,s)` | le `money` de PostgreSQL existe, et dépend du paramètre `lc_monetary` |
| `float`, `real` | `double precision` (`float8`), `real` (`float4`) | |
| `nvarchar(n)`, `varchar(n)` | `text`, ou `varchar(n)` | toute chaîne est dans l'encodage de la base, ici UTF-8 : pas de préfixe `n`, pas de littéraux `N'…'` |
| `nvarchar(max)` | `text` | jusqu'à 1 Go |
| `varbinary(max)` | `bytea` | |
| `datetime2` | `timestamp` | |
| `datetimeoffset` | `timestamptz` | ne garde pas le décalage |
| `time`, `date` | `time`, `date` | |
| pas d'équivalent | `interval` | une durée |
| `uniqueidentifier` | `uuid` | trié par octets, pas dans l'ordre d'octets étrange de SQL Server |
| JSON dans un `nvarchar(max)`, ou le type `json` de SQL Server 2025 | `jsonb` | |
| paramètre table, chaîne délimitée | tableaux : `text[]`, `integer[]` | |
| pas d'équivalent | intervalles de valeurs : `tstzrange`, `int4range`, `daterange` | |
| colonne calculée, `PERSISTED` | colonne générée, virtuelle ou `STORED` | |
| type alias (`CREATE TYPE … FROM`) | domaine (`CREATE DOMAIN`) | un domaine peut porter un `CHECK` |

La suite de la leçon exécute les lignes où la différence compte. Le [chapitre sur les types de données](https://www.postgresql.org/docs/18/datatype.html) les liste tous.

## Le modèle du cours

[`sql/schema.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql) transforme les fichiers JSON et CSV du cours en tables typées, dans deux schémas. D'abord l'historique de CI ([lignes 7-50](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L7-L50)) :

```sql
CREATE DOMAIN ci.conclusion AS text
    CHECK (VALUE IN ('success', 'failure', 'cancelled', 'skipped', 'startup_failure'));

CREATE TABLE ci.runs (
    run_id        bigint PRIMARY KEY,
    workflow_name text NOT NULL,
    event         text NOT NULL,
    conclusion    ci.conclusion,
    head_branch   text NOT NULL,
    head_sha      text NOT NULL CHECK (head_sha ~ '^[0-9a-f]{40}$'),
    attempt       smallint NOT NULL CHECK (attempt >= 1),
    created_at    timestamptz NOT NULL,
    started_at    timestamptz NOT NULL,
    updated_at    timestamptz NOT NULL,
    CHECK (updated_at >= started_at)
);

CREATE TABLE ci.jobs (
    job_id       bigint PRIMARY KEY,
    run_id       bigint NOT NULL REFERENCES ci.runs,
    name         text NOT NULL,
    conclusion   ci.conclusion,
    labels       text[] NOT NULL,
    runner_name  text,
    started_at   timestamptz NOT NULL,
    completed_at timestamptz NOT NULL,
    duration     interval GENERATED ALWAYS AS (completed_at - started_at)
);

-- btree_gist permet à un index GiST de comparer des bigint avec =, à côté du && des intervalles
CREATE EXTENSION btree_gist;

CREATE TABLE ci.steps (
    job_id       bigint NOT NULL REFERENCES ci.jobs,
    number       smallint NOT NULL,
    name         text NOT NULL,
    conclusion   ci.conclusion,
    started_at   timestamptz NOT NULL,
    completed_at timestamptz NOT NULL CHECK (completed_at >= started_at),
    ran          tstzrange GENERATED ALWAYS AS (tstzrange(started_at, completed_at, '[)')) STORED,
    PRIMARY KEY (job_id, number),
    -- les étapes d'un même job ne s'exécutent jamais en même temps
    EXCLUDE USING gist (job_id WITH =, ran WITH &&)
);
```

La partie chargement ([lignes 52-73](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L52-L73)) lit `runs.json` avec `jsonb_to_recordset`, comme dans la leçon 1, et `jobs.json`, un tableau de 315 jobs avec leurs étapes imbriquées, avec l'opérateur `->>`, qui extrait un champ sous forme de texte. La leçon 7 porte sur le JSON ; ici, c'est un moyen. Les projets et références de Guitar Alchemist viennent de fichiers CSV, chargés avec [`COPY`](https://www.postgresql.org/docs/18/sql-copy.html), et ses accords iconiques de JSON ([lignes 75-134](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L75-L134)). Les sections suivantes expliquent chaque choix.

## Nombres

[Lignes 7-9](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L7-L9) :

```sql
SELECT 0.1::float8 + 0.2::float8 AS float8, 0.1 + 0.2 AS numeric, 7 / 2 AS int_division, 7 / 2.0 AS numeric_division;
SELECT 2147483647 + 1;
SELECT 1234.5::numeric(5, 2);
```

```text
       float8        | numeric | int_division |  numeric_division
---------------------+---------+--------------+--------------------
 0.30000000000000004 |     0.3 |            3 | 3.5000000000000000
(1 row)

ERROR:  integer out of range
ERROR:  numeric field overflow
DETAIL:  A field with precision 5, scale 2 must round to an absolute value less than 10^3.
```

- Un littéral avec un point décimal, comme `0.1`, est un [`numeric`](https://www.postgresql.org/docs/18/datatype-numeric.html#DATATYPE-NUMERIC-DECIMAL), exact, et `0.1 + 0.2` vaut exactement `0.3`. Dans SQL Server, le littéral serait aussi un `decimal`. `float8` montre l'erreur d'arrondi binaire, comme `double` en C#.
- La division entière tronque, comme dans SQL Server, C# et Java. `7 / 2.0` est un `numeric`, et PostgreSQL a choisi 16 chiffres après la virgule pour le résultat.
- Le dépassement est une erreur, pas un rebouclage : `int` + `int` reste `int`. SQL Server lève « Arithmetic overflow error » au même endroit.
- `numeric(5, 2)` signifie 5 chiffres au total, dont 2 après la virgule : au plus 999.99.

Utilise `numeric` pour l'argent et tout ce qui se compte en unités décimales, `bigint` pour les identifiants, et `double precision` pour les mesures.

## Texte

[Lignes 12-15](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L12-L15) :

```sql
SELECT 'windows-latest'::varchar(7) AS cast_truncates;
CREATE TABLE ci.labels (label varchar(7));
INSERT INTO ci.labels VALUES ('windows-latest');
SELECT 'ab'::char(4) || '|' AS char_concat, length('é') AS characters, octet_length('é') AS bytes;
```

```text
 cast_truncates
----------------
 windows
(1 row)

CREATE TABLE
ERROR:  value too long for type character varying(7)
 char_concat | characters | bytes
-------------+------------+-------
 ab|         |          1 |     2
(1 row)
```

- Une **conversion explicite** en `varchar(7)` tronque sans erreur, comme l'exige le standard SQL. **Stocker** une valeur plus longue est une erreur. SQL Server se comporte de la même façon : `CAST` tronque, et `INSERT` échoue avec « String or binary data would be truncated ».
- `char(4)` complète avec des espaces, et ce remplissage disparaît dès que la valeur devient du texte : `'ab'::char(4) || '|'` vaut `ab|`. La [documentation](https://www.postgresql.org/docs/18/datatype-character.html) recommande `text` ou `varchar` plutôt que `char(n)`.
- `length` compte les caractères, `octet_length` les octets : `é` fait deux octets en UTF-8.

`text` et `varchar(n)` sont stockés de la même façon et sont aussi rapides l'un que l'autre ; la documentation le dit dans une astuce de la même page. La limite de `varchar(n)` est une contrainte : l'augmenter plus tard ne réécrit pas la table, mais c'est quand même un `ALTER TABLE` pour une règle qu'un `CHECK` exprimerait mieux. Le modèle du cours utilise `text`, et un `CHECK` quand une vraie règle existe, comme pour `head_sha`.

## Horodatages : ce que stocke timestamptz

`timestamp with time zone`, `timestamptz` en abrégé, est le type à utiliser pour des instants. Son nom trompe : **il ne stocke pas de fuseau horaire**. Il stocke un instant, en UTC, convertit l'entrée en UTC à partir du décalage fourni ou du paramètre `TimeZone` de la session, et convertit la sortie dans le `TimeZone` de la session ([lignes 18-24](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L18-L24)) :

```sql
SELECT run_id, started_at FROM ci.runs ORDER BY started_at DESC, run_id LIMIT 1;
SET TimeZone = 'America/Toronto';
SELECT run_id, started_at FROM ci.runs ORDER BY started_at DESC, run_id LIMIT 1;
SELECT started_at AT TIME ZONE 'Asia/Tokyo' AS tokyo_wall_clock, pg_typeof(started_at AT TIME ZONE 'Asia/Tokyo')
FROM ci.runs ORDER BY started_at DESC, run_id LIMIT 1;
SELECT '2026-09-14 10:01:09+02'::timestamptz AS timestamptz, '2026-09-14 10:01:09+02'::timestamp AS timestamp;
RESET TimeZone;
```

```text
   run_id    |       started_at
-------------+------------------------
 34852867099 | 2026-09-14 14:01:09+00
(1 row)

SET
   run_id    |       started_at
-------------+------------------------
 34852867099 | 2026-09-14 10:01:09-04
(1 row)

  tokyo_wall_clock   |          pg_typeof
---------------------+-----------------------------
 2026-09-14 23:01:09 | timestamp without time zone
(1 row)

      timestamptz       |      timestamp
------------------------+---------------------
 2026-09-14 04:01:09-04 | 2026-09-14 10:01:09
(1 row)

RESET
```

- La même ligne, deux affichages : `14:01:09+00` en UTC, `10:01:09-04` à Toronto pendant l'heure d'été. Rien n'a été converti dans la table ; seule la sortie a changé.
- `AT TIME ZONE` sur un `timestamptz` donne l'heure murale dans ce fuseau, sous forme de `timestamp` sans fuseau horaire.
- **Le piège** : la même chaîne convertie en `timestamp` garde `10:01:09` et abandonne `+02` sans avertissement. La [documentation](https://www.postgresql.org/docs/18/datatype-datetime.html#DATATYPE-TIMEZONES) dit que PostgreSQL « will silently ignore any time zone indication » dans un littéral de `timestamp without time zone`. Convertie en `timestamptz`, la même chaîne est l'instant 08:01:09 UTC, affiché 04:01:09 à Toronto.

La différence avec le `datetimeoffset` de SQL Server : ce type garde le décalage qu'il a reçu, et rend `10:01:09 +02:00`. `timestamptz` rend l'instant dans le fuseau de celui qui lit. Si le décalage d'origine compte, par exemple l'heure locale d'un utilisateur, stocke le nom du fuseau dans une colonne à côté.

Chaque script du cours s'exécute avec `TimeZone=UTC` : `server.sh` le fixe dans `PGOPTIONS`, pour que les sorties soient les mêmes sur toutes les machines. La valeur par défaut de l'image est aussi `Etc/UTC`, mais un serveur installé sur un portable prend le fuseau du système d'exploitation. La leçon 4 montre les choix des pilotes : Npgsql et le pilote JDBC ne sont pas d'accord.

## Intervalles et colonnes générées

Un `interval` est une durée. `ci.jobs.duration` est une **colonne générée**, calculée à partir de deux autres colonnes ([lignes 27-31](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L27-L31)) :

```sql
SELECT labels[1] AS os, count(*) AS jobs, avg(duration) AS average, max(duration) AS longest
FROM ci.jobs
GROUP BY labels[1]
ORDER BY os;
UPDATE ci.jobs SET duration = interval '1 minute' WHERE job_id = 103842192310;
```

```text
       os       | jobs |     average     | longest
----------------+------+-----------------+----------
 macos-latest   |   34 | 00:00:55.676471 | 00:04:30
 ubuntu-latest  |  246 | 00:00:21.430894 | 00:03:39
 windows-latest |   35 | 00:01:36.714286 | 00:04:44
(3 rows)

ERROR:  column "duration" can only be updated to DEFAULT
DETAIL:  Column "duration" is a generated column.
```

Un job Windows de la CI de ce site dure en moyenne quatre fois et demie plus longtemps qu'un job Linux. `avg` et `max` fonctionnent directement sur des intervalles.

Depuis [PostgreSQL 18](https://www.postgresql.org/docs/18/ddl-generated-columns.html), une colonne générée est **virtuelle** par défaut : calculée à la lecture, pas stockée, comme une colonne calculée SQL Server sans `PERSISTED`. Jusqu'à PostgreSQL 17, seul `STORED` existait, et les vieux tutoriels l'écrivent partout. L'exercice 3 trouve une limite des colonnes virtuelles. `ci.steps.ran` est `STORED`, parce que la contrainte d'exclusion plus bas a besoin d'un index dessus.

## Booléens

[Ligne 34](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L34) :

```sql
SELECT 'yes'::boolean AS yes, 'off'::boolean AS off, 'maybe'::boolean;
```

```text
ERROR:  invalid input syntax for type boolean: "maybe"
LINE 1: ...ECT 'yes'::boolean AS yes, 'off'::boolean AS off, 'maybe'::b...
                                                             ^
```

L'instruction échoue en entier, donc les deux premières colonnes ne s'affichent jamais. [`boolean`](https://www.postgresql.org/docs/18/datatype-boolean.html) accepte en entrée `true`, `yes`, `on`, `1` et leurs contraires, affiche `t` et `f`, et apparaît comme `bool` dans les pilotes, là où le `bit` de SQL Server est un nombre. `WHERE is_active` est une condition complète ; pas de `= 1`.

## uuid, version 7

[`uuid`](https://www.postgresql.org/docs/18/datatype-uuid.html) est un type de 16 octets. PostgreSQL 18 a ajouté [`uuidv7()`](https://www.postgresql.org/docs/18/functions-uuid.html), qui génère des UUID de version 7 : les 48 premiers bits sont un horodatage Unix en millisecondes, donc les valeurs générées plus tard se trient plus loin, et les nouvelles lignes arrivent à la fin de l'index de la clé primaire au lieu d'endroits aléatoires ([lignes 37-49](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L37-L49)) :

```sql
CREATE TABLE ci.annotations (
    annotation_id uuid PRIMARY KEY DEFAULT uuidv7(),
    job_id        bigint NOT NULL REFERENCES ci.jobs,
    message       text NOT NULL
);
INSERT INTO ci.annotations (job_id, message)
SELECT job_id, 'slowest ' || labels[1] || ' job'
FROM (SELECT DISTINCT ON (labels[1]) job_id, labels FROM ci.jobs ORDER BY labels[1], duration DESC, job_id) AS slowest;
SELECT uuid_extract_version(annotation_id) AS version,
       uuid_extract_timestamp(annotation_id) BETWEEN now() - interval '1 minute' AND now() AS created_just_now,
       message
FROM ci.annotations
ORDER BY annotation_id;
```

```text
CREATE TABLE
INSERT 0 3
 version | created_just_now |          message
---------+------------------+----------------------------
       7 | t                | slowest macos-latest job
       7 | t                | slowest ubuntu-latest job
       7 | t                | slowest windows-latest job
(3 rows)
```

Le script n'affiche pas les UUID : ils changent à chaque exécution. Il affiche ce qui ne change pas, leur version et le fait que leur horodatage date de la dernière minute. Triées par `annotation_id`, les lignes sortent dans l'ordre d'insertion : dans une même connexion, PostgreSQL rend chaque valeur de version 7 plus grande que la précédente, même dans la même milliseconde ([`uuid.c`, lignes 563-604](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/utils/adt/uuid.c#L563-L604)). `DISTINCT ON`, qui choisit ici le job le plus lent de chaque OS, est l'affaire de la leçon 3.

`gen_random_uuid()`, ou `uuidv4()` depuis PostgreSQL 18, en génère des aléatoires. Le `NEWSEQUENTIALID()` de SQL Server a le même but que la version 7 avec une autre disposition, et SQL Server trie `uniqueidentifier` par ses derniers octets d'abord ; un `Guid` .NET envoyé à PostgreSQL se trie par ses premiers octets. .NET 9 a ajouté `Guid.CreateVersion7()`.

## json et jsonb

[Ligne 52](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L52) :

```sql
SELECT '{"b": 1, "a": [1, 2], "a": 3}'::json AS json, '{"b": 1, "a": [1, 2], "a": 3}'::jsonb AS jsonb;
```

```text
             json              |      jsonb
-------------------------------+------------------
 {"b": 1, "a": [1, 2], "a": 3} | {"a": 3, "b": 1}
(1 row)
```

[`json`](https://www.postgresql.org/docs/18/datatype-json.html) stocke le texte tel que reçu, vérifié mais pas analysé : clés en double, ordre des clés et espaces sont conservés, et chaque opération l'analyse à nouveau. `jsonb` stocke une valeur binaire, analysée : la dernière clé en double gagne, les clés sont réordonnées, et elle peut être indexée. Utilise `jsonb`, sauf si tu dois rendre exactement le document reçu. La leçon 7 couvre les opérateurs et les index.

## Tableaux

Une colonne peut contenir un [tableau](https://www.postgresql.org/docs/18/arrays.html) de n'importe quel type. `ci.jobs.labels` est un `text[]`, parce que GitHub donne à chaque job une liste de labels de runner ([lignes 55-57](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L55-L57)) :

```sql
SELECT labels, count(*) AS jobs FROM ci.jobs GROUP BY labels ORDER BY jobs DESC, labels;
SELECT count(*) AS macos_jobs FROM ci.jobs WHERE 'macos-latest' = ANY (labels);
SELECT string_to_array('0,4,7,10', ',')::int[] AS pitch_classes, string_to_array('Jimi Hendrix||Prince', '|') AS artists;
```

```text
      labels      | jobs
------------------+------
 {ubuntu-latest}  |  246
 {windows-latest} |   35
 {macos-latest}   |   34
(3 rows)

 macos_jobs
------------
         34
(1 row)

 pitch_classes |          artists
---------------+----------------------------
 {0,4,7,10}    | {"Jimi Hendrix","",Prince}
(1 row)
```

- Les tableaux s'affichent entre accolades, avec des guillemets autour des éléments qui en ont besoin. **Les indices commencent à 1** : `labels[1]` est le premier label.
- `= ANY (tableau)` teste l'appartenance. Il remplace aussi les listes `IN (…)` dans les requêtes paramétrées, comme le montre la leçon 4.
- Dans cet instantané, chaque job a exactement un label ; le type en permet quand même davantage, comme GitHub.

Guitar Alchemist a aussi des listes. Son modèle EF Core, [`MusicalKnowledgeDbContext`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Infrastructure/Persistence/EntityFramework/MusicalKnowledgeDbContext.cs#L32-L45), stocke le `List<int> PitchClasses` d'un accord sous forme de chaîne jointe par des virgules, et son `List<string> AlternateNames` joint par `|`, avec des convertisseurs de valeurs EF Core : SQLite, le fournisseur qu'il référence, n'a pas de tableaux. La dernière requête ci-dessus montre deux choses qu'une chaîne jointe ne dit pas : que les nombres sont des nombres, et qu'un nom vide entre deux séparateurs est un élément. Le convertisseur de GA lit avec `StringSplitOptions.RemoveEmptyEntries`, qui le supprime ; la leçon 4 exécute ce convertisseur contre PostgreSQL. Le modèle du cours stocke plutôt les accords dans des tableaux ([`schema.sql`, lignes 98-112](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L98-L112)) :

```sql
CREATE DOMAIN ga.pitch_class AS smallint CHECK (VALUE BETWEEN 0 AND 11);

CREATE TABLE ga.iconic_chords (
    chord_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             text NOT NULL UNIQUE,
    theoretical_name text NOT NULL,
    artist           text NOT NULL,
    song             text NOT NULL,
    era              text NOT NULL,
    genre            text NOT NULL,
    pitch_classes    ga.pitch_class[] NOT NULL,
    -- une case par corde, du mi grave au mi aigu ; -1 pour une corde non jouée
    guitar_voicing   smallint[] CHECK (cardinality(guitar_voicing) = 6),
    alternate_names  text[] NOT NULL
);
```

Un tableau d'un domaine vérifie chaque élément : l'exercice 1 essaie une classe de hauteur 12. Le coût des tableaux : pas de clé étrangère sur un élément, et une table des notes d'accord reste la bonne conception quand les éléments ont leurs propres attributs ou doivent souvent être joints. Pour une courte liste qui appartient à sa ligne, un tableau est plus simple qu'une table enfant et plus sûr qu'une chaîne jointe.

## Intervalles de valeurs et contraintes d'exclusion

Un [intervalle de valeurs](https://www.postgresql.org/docs/18/rangetypes.html) (range) est une seule valeur avec une borne inférieure et une borne supérieure, chacune incluse (`[` `]`) ou exclue (`(` `)`). `ci.steps.ran` est le `tstzrange` qui va du début d'une étape à sa fin ([lignes 60-68](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L60-L68)) :

```sql
SELECT number, name, started_at, completed_at, ran, isempty(ran) AS empty
FROM ci.steps WHERE job_id = 103842192310 ORDER BY number LIMIT 4;
SELECT count(*) FILTER (WHERE isempty(ran)) AS zero_second_steps, count(*) AS steps FROM ci.steps;
SELECT count(*) AS overlapping_if_closed
FROM ci.steps AS a
JOIN ci.steps AS b ON a.job_id = b.job_id AND a.number < b.number
WHERE tstzrange(a.started_at, a.completed_at, '[]') && tstzrange(b.started_at, b.completed_at, '[]');
INSERT INTO ci.steps (job_id, number, name, conclusion, started_at, completed_at)
VALUES (103842192310, 99, 'Overlapping step', 'success', '2026-09-14 02:50:35+00', '2026-09-14 02:50:36+00');
```

```text
 number |            name             |       started_at       |      completed_at      |                         ran                         | empty
--------+-----------------------------+------------------------+------------------------+-----------------------------------------------------+-------
      1 | Set up job                  | 2026-09-14 02:50:32+00 | 2026-09-14 02:50:33+00 | ["2026-09-14 02:50:32+00","2026-09-14 02:50:33+00") | f
      2 | Run actions/checkout@v7     | 2026-09-14 02:50:33+00 | 2026-09-14 02:50:40+00 | ["2026-09-14 02:50:33+00","2026-09-14 02:50:40+00") | f
      3 | Run actions/setup-java@v6   | 2026-09-14 02:50:40+00 | 2026-09-14 02:50:41+00 | ["2026-09-14 02:50:40+00","2026-09-14 02:50:41+00") | f
      4 | Run actions/setup-dotnet@v6 | 2026-09-14 02:50:41+00 | 2026-09-14 02:51:13+00 | ["2026-09-14 02:50:41+00","2026-09-14 02:51:13+00") | f
(4 rows)

 zero_second_steps | steps
-------------------+-------
               857 |  2204
(1 row)

 overlapping_if_closed
-----------------------
                  2798
(1 row)

ERROR:  conflicting key value violates exclusion constraint "steps_job_id_ran_excl"
DETAIL:  Key (job_id, ran)=(103842192310, ["2026-09-14 02:50:35+00","2026-09-14 02:50:36+00")) conflicts with existing key (job_id, ran)=(103842192310, ["2026-09-14 02:50:33+00","2026-09-14 02:50:40+00")).
```

Les choix du modèle, et leurs raisons :

- **Semi-ouvert, `[)`.** L'API de GitHub donne les heures à la seconde, et chaque étape commence à la seconde où la précédente se termine. Avec les deux bornes incluses, l'étape 1 `[02:50:32, 02:50:33]` et l'étape 2 `[02:50:33, 02:50:40]` partagent 02:50:33, et 2 798 paires d'étapes d'un même job se « chevaucheraient ». Avec la fin exclue, aucune.
- **Le prix de `[)`.** 857 des 2 204 étapes, 39 %, ont commencé et fini dans la même seconde, et `[t, t)` est un **intervalle vide** : il ne contient rien, et ses bornes disparaissent (`lower()` d'un intervalle vide vaut `NULL`). C'est pourquoi la table garde `started_at` et `completed_at`, et en dérive `ran`.
- **La contrainte d'exclusion.** `EXCLUDE USING gist (job_id WITH =, ran WITH &&)` refuse deux lignes dont les `job_id` sont égaux *et* dont les intervalles se chevauchent (`&&`) : une contrainte d'unicité généralisée à n'importe quel opérateur. Elle est appliquée par un index GiST, et l'extension [`btree_gist`](https://www.postgresql.org/docs/18/btree-gist.html) apprend à GiST le `=` des `bigint`. L'étape insérée, de 02:50:35 à 02:50:36, tombe dans l'étape 2, et l'erreur nomme les deux lignes. SQL Server n'a pas d'équivalent ; le contournement habituel est un déclencheur.

## Domaines et contraintes CHECK

[Lignes 71-72](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L71-L72) :

```sql
INSERT INTO ci.runs VALUES (1, 'Test', 'push', 'neutral', 'main', repeat('a', 40), 1, '2026-09-15', '2026-09-15', '2026-09-15');
INSERT INTO ci.runs VALUES (1, 'Test', 'push', 'success', 'main', 'not-a-sha', 1, '2026-09-15', '2026-09-15', '2026-09-15');
```

```text
ERROR:  value for domain ci.conclusion violates check constraint "conclusion_check"
ERROR:  new row for relation "runs" violates check constraint "runs_head_sha_check"
DETAIL:  Failing row contains (1, Test, push, success, main, not-a-sha, 1, 2026-09-15 00:00:00+00, 2026-09-15 00:00:00+00, 2026-09-15 00:00:00+00).
```

Un [domaine](https://www.postgresql.org/docs/18/domains.html) est un type avec des contraintes, défini une fois et utilisé par plusieurs colonnes : `ci.conclusion` dans trois tables. Les autres options sont un [type énuméré](https://www.postgresql.org/docs/18/datatype-enum.html), auquel on peut ajouter des valeurs mais pas en retirer sans le recréer, et une table de référence avec une clé étrangère, le bon choix quand les valeurs ont des attributs ou changent souvent. `neutral` est une vraie conclusion GitHub que cet instantané ne contient pas ; quand elle apparaîtra, `ALTER DOMAIN` remplacera la contrainte.

Un `CHECK` sur une colonne peut utiliser n'importe quelle expression de la ligne, ici une [expression régulière](https://www.postgresql.org/docs/18/functions-matching.html#FUNCTIONS-POSIX-REGEXP) avec `~`. Le `CHECK` de SQL Server n'a pas d'expressions régulières avant le `REGEXP_LIKE` de SQL Server 2025. Le `DETAIL` affiche la ligne fautive ; la leçon 4 montre que Npgsql le masque par défaut.

## UNIQUE et NULL

[Lignes 75-79](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L75-L79) :

```sql
CREATE TABLE ga.owners (project text REFERENCES ga.projects, email text UNIQUE);
INSERT INTO ga.owners VALUES ('Apps/ga-server/GaApi/GaApi.csproj', NULL), ('Common/GA.Core/GA.Core.csproj', NULL);
SELECT count(*) AS owners_without_email FROM ga.owners WHERE email IS NULL;
CREATE TABLE ga.maintainers (project text REFERENCES ga.projects, email text UNIQUE NULLS NOT DISTINCT);
INSERT INTO ga.maintainers VALUES ('Apps/ga-server/GaApi/GaApi.csproj', NULL), ('Common/GA.Core/GA.Core.csproj', NULL);
```

```text
CREATE TABLE
INSERT 0 2
 owners_without_email
----------------------
                    2
(1 row)

CREATE TABLE
ERROR:  duplicate key value violates unique constraint "maintainers_email_key"
DETAIL:  Key (email)=(null) already exists.
```

Ici, c'est l'inverse de SQL Server. Une contrainte `UNIQUE` de SQL Server autorise **un seul** `NULL`, et le contournement habituel pour « unique quand renseigné » est un index unique filtré, `WHERE email IS NOT NULL`. PostgreSQL suit le standard SQL : `NULL` n'est pas égal à `NULL`, donc une colonne `UNIQUE` accepte **autant** de `NULL` qu'on veut. [`NULLS NOT DISTINCT`](https://www.postgresql.org/docs/18/ddl-constraints.html#DDL-CONSTRAINTS-UNIQUE-CONSTRAINTS), depuis PostgreSQL 15, donne le comportement de SQL Server. Un schéma migré garde ses contraintes et change silencieusement leur sens.

## Ce que les contraintes trouvent dans Guitar Alchemist

`schema.sql` charge les références de projets de Guitar Alchemist à travers un `DISTINCT` et une jointure, et son commentaire dit pourquoi. Sans eux ([lignes 82-87](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L82-L87)) :

```sql
CREATE TABLE ga.raw_refs (LIKE ga.project_refs INCLUDING ALL);
ALTER TABLE ga.raw_refs ADD FOREIGN KEY (from_path) REFERENCES ga.projects, ADD FOREIGN KEY (to_path) REFERENCES ga.projects;
COPY ga.raw_refs FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER match);
COPY ga.raw_refs FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER true);
ALTER TABLE ga.raw_refs DROP CONSTRAINT raw_refs_pkey;
COPY ga.raw_refs FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER true);
```

```text
CREATE TABLE
ALTER TABLE
ERROR:  column name mismatch in header line field 1: got "from", expected "from_path"
CONTEXT:  COPY raw_refs, line 1: "from,to"
ERROR:  duplicate key value violates unique constraint "raw_refs_pkey"
DETAIL:  Key (from_path, to_path)=(Apps/ga-server/GA.Knowledge.Service/GA.Knowledge.Service.csproj, Common/GA.Business.Config/GA.Business.Config.fsproj) already exists.
CONTEXT:  COPY raw_refs, line 61
ALTER TABLE
ERROR:  insert or update on table "raw_refs" violates foreign key constraint "raw_refs_to_path_fkey"
DETAIL:  Key (to_path)=(Experiments/React/reactapp1.client/reactapp1.client.esproj) is not present in table "projects".
```

1. `HEADER match`, depuis PostgreSQL 15, compare l'en-tête du CSV aux colonnes de la table, et le fichier dit `from,to`. `HEADER true` se contente de sauter la première ligne.
2. La clé primaire trouve une référence listée deux fois : [`GA.Knowledge.Service.csproj`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Apps/ga-server/GA.Knowledge.Service/GA.Knowledge.Service.csproj#L26-L31) référence `GA.Business.Config.fsproj` à la ligne 26 et de nouveau à la ligne 31, toujours au commit `32f143c`. MSBuild accepte le doublon ; un modèle relationnel, non. `COPY` s'arrête à la première erreur, et aucune ligne du fichier n'est gardée : un `COPY` est une instruction, et une instruction est atomique.
3. Sans la clé primaire, la clé étrangère trouve une référence à `reactapp1.client.esproj`, un projet JavaScript du modèle React de Visual Studio, que l'extraction n'a pas compté comme projet .NET. Celui-là est une limite des données, pas un bogue.

[`LIKE … INCLUDING ALL`](https://www.postgresql.org/docs/18/sql-createtable.html) copie colonnes, valeurs par défaut, contraintes et index, mais pas les clés étrangères, que l'`ALTER TABLE` rajoute.

## Sur Aurora

*À vérifier : rien dans cette section n'a été exécuté sur AWS.* Aurora PostgreSQL exécute le moteur de PostgreSQL lui-même, donc les types, domaines, contraintes et colonnes générées de cette leçon sont ceux de PostgreSQL 18. Deux différences à vérifier avant de se fier à la leçon :

- **La version mineure.** Le 2026-09-15, la version d'Aurora la plus récente est 18.4.1, compatible avec PostgreSQL 18.4 ; le cours utilise 18.6. Les corrections de bogues entre 18.4 et 18.6 ne sont pas encore dans Aurora.
- **Les versions des extensions.** Le [tableau des extensions d'Aurora PostgreSQL 18](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) indique `btree_gist` 1.6 pour Aurora PostgreSQL 18.4, là où PostgreSQL 18.6 dans l'image propose 1.8 (`SELECT default_version FROM pg_available_extensions WHERE name = 'btree_gist'`). La contrainte d'exclusion de `ci.steps` n'a besoin que du support des `bigint` que les versions plus anciennes avaient déjà, mais une fonctionnalité plus récente de l'extension pourrait manquer. Seules les extensions de cette liste peuvent être installées.

## À retenir

- `numeric` est exact, `float8` non ; la division entière tronque et le dépassement est une erreur.
- Préfère `text` avec un `CHECK` à `varchar(n)`, et n'utilise jamais `char(n)`.
- `timestamptz` stocke un instant, pas un fuseau horaire ; une chaîne convertie en `timestamp` perd son décalage en silence.
- Les colonnes générées sont virtuelles par défaut depuis PostgreSQL 18 ; les index et les contraintes d'exclusion exigent `STORED`.
- `uuidv7()` donne des UUID ordonnés ; `jsonb` plutôt que `json`.
- Tableaux et intervalles de valeurs sont des types de colonnes : `= ANY`, `&&` et les contraintes d'exclusion remplacent tables enfants, chaînes jointes et déclencheurs quand ils conviennent.
- `UNIQUE` autorise plusieurs `NULL` sauf avec `NULLS NOT DISTINCT` : l'inverse de SQL Server.
- Les contraintes sont aussi un outil de qualité des données : elles ont trouvé un `ProjectReference` en double dans Guitar Alchemist.

## Exercices

Les solutions sont dans [`sql/02-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql).

1. Liste les accords iconiques qui contiennent à la fois mi (classe de hauteur 4) et si (classe de hauteur 11), avec leur nombre de notes et leur premier nom alternatif. Essaie ensuite d'ajouter la classe de hauteur 12 au Power Chord.

<details>
<summary>Solution</summary>

Tiré de [`sql/02-exercises.sql`, lignes 7-11](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql#L7-L11) :

```sql
SELECT name, pitch_classes, cardinality(pitch_classes) AS notes, alternate_names[1] AS first_alias
FROM ga.iconic_chords
WHERE pitch_classes @> '{4,11}'
ORDER BY name;
UPDATE ga.iconic_chords SET pitch_classes = pitch_classes || 12::smallint WHERE name = 'Power Chord';
```

```text
       name       |  pitch_classes  | notes |     first_alias
------------------+-----------------+-------+---------------------
 Debussy Chord    | {0,4,7,11,2}    |     5 | Impressionist Chord
 Elektra Chord    | {4,8,11,2,5,10} |     6 | Strauss Chord
 Hendrix Chord    | {4,8,11,2,7}    |     5 | Purple Haze Chord
 James Bond Chord | {4,7,11,3}      |     4 | Spy Chord
 So What Chord    | {4,9,2,7,11}    |     5 | Em11
(5 rows)

ERROR:  value for domain ga.pitch_class violates check constraint "pitch_class_check"
```

`@>` signifie « contient » : chaque élément du tableau de droite est dans celui de gauche, dans n'importe quel ordre. `cardinality` compte les éléments ; `array_length(a, 1)` aussi, mais renvoie `NULL` pour un tableau vide. `||` ajoute un élément, et le domaine le vérifie : la contrainte de `ga.pitch_class` s'applique à chaque élément du tableau. La leçon 7 indexe `@>` avec GIN.

</details>

2. Compte les exécutions par jour calendaire, une fois selon la date UTC et une fois selon la date d'une horloge murale à Toronto. Pourquoi y a-t-il trois lignes pour deux jours ?

<details>
<summary>Solution</summary>

Tiré de [`sql/02-exercises.sql`, lignes 14-19](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql#L14-L19) :

```sql
SELECT started_at::date AS utc_day,
       (started_at AT TIME ZONE 'America/Toronto')::date AS toronto_day,
       count(*) AS runs
FROM ci.runs
GROUP BY 1, 2
ORDER BY 1, 2;
```

```text
  utc_day   | toronto_day | runs
------------+-------------+------
 2026-09-13 | 2026-09-13  |   43
 2026-09-14 | 2026-09-13  |   23
 2026-09-14 | 2026-09-14  |   59
(3 rows)
```

23 exécutions ont commencé le 14 septembre en UTC, entre minuit et 04:00, alors qu'il était encore le 13 septembre à Toronto. `started_at::date` convertit dans le fuseau de la session, UTC dans les scripts du cours ; la même requête dans une session réglée sur `America/Toronto` donnerait les dates de Toronto dans la première colonne. Un rapport « par jour » doit dire de quel jour il s'agit, et `AT TIME ZONE` le rend explicite au lieu de dépendre de la connexion.

</details>

3. Crée un index sur `ci.jobs.duration` pour trouver les jobs longs. Que se passe-t-il ? Comment obtenir un index que la requête `WHERE completed_at - started_at > interval '4 minutes'` peut utiliser ?

<details>
<summary>Solution</summary>

Tiré de [`sql/02-exercises.sql`, lignes 22-24](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql#L22-L24) :

```sql
CREATE INDEX ON ci.jobs (duration);
CREATE INDEX jobs_duration_idx ON ci.jobs ((completed_at - started_at));
EXPLAIN (COSTS OFF) SELECT job_id FROM ci.jobs WHERE completed_at - started_at > interval '4 minutes';
```

```text
ERROR:  indexes on virtual generated columns are not supported
CREATE INDEX
                           QUERY PLAN
----------------------------------------------------------------
 Seq Scan on jobs
   Filter: ((completed_at - started_at) > '00:04:00'::interval)
(2 rows)
```

Une colonne virtuelle n'a pas de valeur sur disque à indexer. Deux corrections : déclarer la colonne `STORED`, ou créer un **index sur expression** avec la même expression, ce que fait la deuxième instruction, avec des doubles parenthèses autour de l'expression. Le plan lit quand même toute la table : avec 315 lignes dans quelques pages, un parcours séquentiel coûte moins cher que l'index, et le planificateur le sait. [`EXPLAIN`](https://www.postgresql.org/docs/18/sql-explain.html) montre le plan sans exécuter la requête ; la leçon 5 explique quand le planificateur utilise un index.

</details>

## Sources

- Documentation de PostgreSQL 18 : [types de données](https://www.postgresql.org/docs/18/datatype.html), [types numériques](https://www.postgresql.org/docs/18/datatype-numeric.html), [types caractères](https://www.postgresql.org/docs/18/datatype-character.html), [types date et heure](https://www.postgresql.org/docs/18/datatype-datetime.html), [boolean](https://www.postgresql.org/docs/18/datatype-boolean.html), [uuid](https://www.postgresql.org/docs/18/datatype-uuid.html) et [fonctions UUID](https://www.postgresql.org/docs/18/functions-uuid.html), [types JSON](https://www.postgresql.org/docs/18/datatype-json.html), [tableaux](https://www.postgresql.org/docs/18/arrays.html), [types intervalle](https://www.postgresql.org/docs/18/rangetypes.html), [`btree_gist`](https://www.postgresql.org/docs/18/btree-gist.html), [contraintes](https://www.postgresql.org/docs/18/ddl-constraints.html), [domaines](https://www.postgresql.org/docs/18/domains.html), [colonnes générées](https://www.postgresql.org/docs/18/ddl-generated-columns.html), [`COPY`](https://www.postgresql.org/docs/18/sql-copy.html), [`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html)
- [Notes de version de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html) : colonnes générées virtuelles, `uuidv7()`
- Guitar Alchemist au commit `32f143c` : [`MusicalKnowledgeDbContext.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Infrastructure/Persistence/EntityFramework/MusicalKnowledgeDbContext.cs), [`IconicChords.yaml`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Business.Config/IconicChords.yaml), [`GA.Knowledge.Service.csproj`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Apps/ga-server/GA.Knowledge.Service/GA.Knowledge.Service.csproj)
- [Extensions prises en charge par Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html)
- SQL Server : [types de données](https://learn.microsoft.com/sql/t-sql/data-types/data-types-transact-sql), [`datetimeoffset`](https://learn.microsoft.com/sql/t-sql/data-types/datetimeoffset-transact-sql), [contraintes d'unicité](https://learn.microsoft.com/sql/relational-databases/tables/unique-constraints-and-check-constraints)
